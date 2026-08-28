extends Node
## REPARATIA DE ORIENTARE SI SPRIJIN, runda 2 (Chongqing / Track12).
##
## Criticul a numarat, dupa runda 1, 33 de pravalii cu SPATELE la drum in
## sectiunea 6 (nodul), 17 din 19 scari Shibati tot cu spatele, si 11 din 15
## `restaurant_front` intoarse pe dos in aleea hot-pot. Cauza e in generator,
## nu in asezare: `gen_decor_cq_f.gd` calcula yaw-ul din DIRECTIA DE MERS
## (`yaw ± PI/2`), adica din tangenta, in loc sa-l calculeze din directia
## SPRE SOSEA. Cele doua coincid doar cand piesa sta exact pe normala; pe
## viraje (si nodul e tot un viraj) diverg cu zeci de grade, iar semnul se si
## inverseaza cand piesa e de partea cealalta.
##
## Aici nu se regenereaza decor. Se citeste scena vie, se masoara pentru
## FIECARE piesa din kiturile de fatada:
##   * directia orizontala de la piesa spre cel mai apropiat punct al soselei;
##   * yaw-ul care duce -Z al piesei EXACT pe directia aia (`dot`, nu ghicit);
##   * cota terenului sub talpa, ca piesa sa nu ramana in aer.
## si se tipareste noul `transform` per nod, in forma in care se lipeste peste
## cel vechi din `.tscn` (`tools/_cq_fatade.txt`).
##
## De ce `dot` si nu unghiuri: memoria `rotatii-in-builder-semnul` — semnul
## rotatiei se deriva din produsul scalar cu directia dorita, nu se presupune.
## Fiecare piesa scrisa aici trece prin verificarea `dot(-Z, spre_sosea) > 0.7`
## INAINTE sa fie emisa; ce nu trece se raporteaza, nu se scrie tacut.
const TRACK := "res://scenes/tracks/Track12.tscn"
const OUT := "res://tools/_cq_fatade.txt"

## Kiturile care AU o fata. Restul decorului (felinare, rufe, containere) e
## simetric sau nu se citeste directional, deci nu se atinge.
const FACADE_KITS := {
	"shophouse_a.glb": true,
	"shophouse_b.glb": true,
	"shophouse_c.glb": true,
	"restaurant_front.glb": true,
	"stone_stairway.glb": true,
}
## Cat de departe de sosea inca merita intoarsa o piesa. Peste atat piesa e
## fundal: orientarea ei nu se mai citeste, iar rotirea ar strica siruri
## asezate deliberat de-a lungul malului.
const MAX_LAT := 45.0

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _ex: Array[RID] = []
var _out: Array[String] = []
var _stats := {}


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	for _i in 8:
		await get_tree().physics_frame
	_space = _track.get_world_3d().direct_space_state
	_collect_excluded()
	var root := _track.get_node_or_null(NodePath("DecorManual"))
	if root == null:
		push_error("fara DecorManual")
		get_tree().quit(1)
		return
	_walk(root)
	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string("\n".join(_out))
	fa.close()
	print("")
	print("=== BILANT ===")
	for k in _stats:
		var d: Dictionary = _stats[k]
		print("  %-24s intoarse=%d deja_ok=%d prea_departe=%d ridicate=%d"
			% [k, d["turned"], d["ok"], d["far"], d["lifted"]])
	print("scris %s (%d linii)" % [OUT, _out.size()])
	get_tree().quit(0)


func _collect_excluded() -> void:
	for root_name in ["DecorManual", "Decor"]:
		var r := _track.get_node_or_null(NodePath(root_name))
		if r == null:
			continue
		var st: Array[Node] = [r]
		while not st.is_empty():
			var x: Node = st.pop_back()
			for c in x.get_children():
				st.append(c)
			var b := x as CollisionObject3D
			if b != null:
				_ex.append(b.get_rid())


func _walk(root: Node) -> void:
	var st: Array[Node] = [root]
	while not st.is_empty():
		var x: Node = st.pop_back()
		for c in x.get_children():
			st.append(c)
		var n3 := x as Node3D
		if n3 == null or n3 == root:
			continue
		var kit := _kit_of(n3)
		if kit == "":
			continue
		_consider(n3, kit)


## Din ce GLB vine piesa. Numele nodului nu spune nimic (memoria
## `nume-noduri-nu-sunt-unice`); adevarul e in `scene_file_path`.
func _kit_of(n: Node3D) -> String:
	var p := n.scene_file_path
	if p == "":
		return ""
	var base := p.get_file()
	return base if FACADE_KITS.has(base) else ""


func _bump(kit: String, key: String) -> void:
	if not _stats.has(kit):
		_stats[kit] = {"turned": 0, "ok": 0, "far": 0, "lifted": 0}
	_stats[kit][key] += 1


func _consider(n: Node3D, kit: String) -> void:
	var pos := n.global_position
	var road := _nearest_road(pos)
	var to_road := Vector3(road.x - pos.x, 0.0, road.z - pos.z)
	var lat := to_road.length()
	if lat < 0.5 or lat > MAX_LAT:
		_bump(kit, "far")
		return
	to_road /= lat
	# -Z al nodului, in plan. Asta e "fata" modelului (conventia kitului).
	var face := -n.global_basis.z
	face.y = 0.0
	if face.length_squared() < 1e-6:
		_bump(kit, "far")
		return
	var d := face.normalized().dot(to_road)
	# Cota: piesa trebuie sa aiba podea sub talpa. Se masoara sub ORIGINE
	# (originile kitului Chongqing sunt pe pivot/talpa, memoria
	# `chongqing-assets-kit`), cu decorul exclus ca sa nu gaseasca vecinul.
	var g := _ground(pos.x, pos.z, road.y)
	var drop := pos.y - g
	var new_y := pos.y
	var lifted := false
	# Peste 0.6 m in aer se aseaza pe teren; sub -1.5 m e ingropata si iese.
	if drop > 0.6 or drop < -1.5:
		new_y = g
		lifted = true
	if d > 0.7 and not lifted:
		_bump(kit, "ok")
		return
	var yaw := atan2(-to_road.x, -to_road.z)
	# VERIFICARE, nu presupunere: reconstruim baza si masuram din nou dot-ul.
	var b := Basis(Vector3.UP, yaw)
	var check := (-b.z).dot(to_road)
	if check < 0.99:
		push_error("yaw gresit pentru %s: dot=%.3f" % [n.name, check])
		return
	# Scara are un sens si pe verticala: urca dinspre drum spre mal. Modelul
	# e simetric fata de asta, deci doar yaw-ul conteaza.
	var scl := n.global_basis.get_scale()
	b = b.scaled(scl)
	_out.append("# %s  (kit %s, lat %.1f m, dot %+.2f -> %+.2f%s)"
		% [n.name, kit, lat, d, check, ", ridicat %+.2f m" % (new_y - pos.y) if lifted else ""])
	# ORIGINEA NU E CENTRUL. `stone_stairway` are corpul intins 6.11 m pe -Z
	# fata de pivot (masurat, `probe_cq_r2r`): e o scara ancorata in capatul de
	# sus. O rotatie in jurul pivotului ei nu intoarce piesa pe loc, o
	# PLIMBA — si prima versiune a reparatiei a plimbat 12 scari fix pe
	# carosabil, unde sonda de cursa le-a gasit imediat (22 de repuneri pe
	# seed 2, toate intre fractiile 0.039 si 0.078; pe origin/main, zero).
	#
	# Deci se roteste in jurul CENTRULUI amprentei, nu al originii: dupa
	# rotatie originea se muta cu cat s-a deplasat centrul, si corpul ramane
	# unde era. Pentru piesele centrate (shophouse, restaurant) corectia iese
	# zero singura, deci regula ramane una pentru toate kiturile.
	var off := _footprint_offset(n)
	var origin := Vector3(pos.x, new_y, pos.z)
	if off.length_squared() > 1e-6:
		var old_c := n.global_basis * off
		var new_c := b * off
		origin -= Vector3(new_c.x - old_c.x, 0.0, new_c.z - old_c.z)
	_out.append("%s|%s" % [n.name, _tscn_transform(b, origin)])
	_bump(kit, "lifted" if lifted else "turned")


## Cel mai apropiat punct al soselei — dar NU cel mai apropiat in 3D.
##
## Pe Chongqing bucla trece pe deasupra ei insesi (memoria `pista-peste-pista`),
## deci pentru o casa prinsa intre doua etaje `closest_index_global` sare de la
## un etaj la altul de la un metru la altul: prima rulare a intors casele spre
## soseaua de DEDESUBT, a doua le-a gasit alt vecin si a cerut sa fie intoarse
## iar. O reparatie care nu converge nu e o reparatie.
##
## Aici se cere ETAJUL: dintre punctele soselei aflate la cel mult
## `LEVEL_BAND` metri pe verticala de piesa se ia cel mai apropiat in plan.
## Daca niciunul nu e la cota (piesa e pe mal, sub viaduct), se cade inapoi pe
## cel mai apropiat in plan, si asta se si scrie in raport.
const LEVEL_BAND := 9.0

func _nearest_road(pos: Vector3) -> Vector3:
	var r := _track.routes[0]
	var best := Vector3.ZERO
	var best_d := INF
	var best_any := Vector3.ZERO
	var best_any_d := INF
	for i in r.baked.size():
		var b: Vector3 = r.baked[i]
		var d := Vector2(b.x - pos.x, b.z - pos.z).length_squared()
		if d < best_any_d:
			best_any_d = d
			best_any = b
		if absf(b.y - pos.y) > LEVEL_BAND:
			continue
		if d < best_d:
			best_d = d
			best = b
	return best if best_d < INF else best_any


func _ground(wx: float, wz: float, hint: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(wx, hint + 60.0, wz), Vector3(wx, hint - 400.0, wz))
	q.exclude = _ex
	var hit := _space.intersect_ray(q)
	if hit.is_empty():
		return _track._sampler.ground_y(wx, wz)
	return (hit["position"] as Vector3).y


## Literalul `transform = Transform3D(...)` din `.tscn`, in ordinea corecta.
##
## [b]Capcana care a costat doua runde.[/b] Cele 12 numere din `.tscn` sunt pe
## LINII, nu pe coloane: Godot citeste `basis.x = (a0, a3, a6)`. Scrise pe
## coloane (`b.x.x, b.x.y, b.x.z, ...`) iese TRANSPUSA, iar pentru o rotatie
## pura in jurul lui Y transpusa e chiar rotatia INVERSA — adica piesa se
## intoarce fix in partea cealalta. De-aia raportul spunea "intors, dot +1.00"
## si masuratoarea urmatoare gasea aceleasi case cu spatele: fisierul primea
## unghiul cu semn schimbat. Verificat citind inapoi nodul din PackedScene.
func _tscn_transform(b: Basis, o: Vector3) -> String:
	return "transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)" % [
		b.x.x, b.y.x, b.z.x,
		b.x.y, b.y.y, b.z.y,
		b.x.z, b.y.z, b.z.z,
		o.x, o.y, o.z]


## Centrul amprentei unei piese, in spatiul ei local (doar X si Z).
##
## Se citeste din mesh-uri o singura data per kit: piesele aceluiasi GLB au
## aceeasi geometrie, iar altfel parcurgerea ar costa pe fiecare din cele
## ~250 de piese.
var _footprints := {}

func _footprint_offset(n: Node3D) -> Vector3:
	var kit := _kit_of(n)
	if _footprints.has(kit):
		return _footprints[kit]
	var got := false
	var a := AABB()
	var st: Array[Node] = [n]
	while not st.is_empty():
		var x: Node = st.pop_back()
		for c in x.get_children():
			st.append(c)
		var mi := x as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var rel := n.global_transform.affine_inverse() * mi.global_transform
		var b := rel * mi.mesh.get_aabb()
		a = b if not got else a.merge(b)
		got = true
	var c2 := Vector3.ZERO
	if got:
		c2 = Vector3(a.get_center().x, 0.0, a.get_center().z)
	_footprints[kit] = c2
	return c2
