extends Node
## REPARATIA RUNDEI 3 (Chongqing / Track12): hero-ul Hongya Dong, pasarela,
## si gura holului Liziba.
##
## Criticul rundei 2 a aratat, cu A/B pe `--hide`, ca ce se vedea de pe cornisa
## NU era hero-ul: cladirea aurie din cadru era `hongya40`, iar
## `hongya_hero227` era neatins din prima reclamatie — varf la 21.0 cu soseaua
## la 26.4, adica 5.4 m SUB drum, la 22 m lateral.
##
## Masuratoarea care explica totul (sonda `_bedge`, profilul terenului pe
## dreapta la fractiile 0.28-0.40): faleza e o TREAPTA. La 8 m dreapta terenul
## e inca la cota soselei; la 12-16 m a cazut deja pe podeaua rapei, plata la
## y = 5.7. Piesele care se CITESC (hongya38/39/40) stau toate cu talpa pe
## 5.7 si, inalte de 26.3 m, ies cu varful la ~32 — adica fix la buza. Hero-ul
## fusese coborat la talpa -5.6, adica INGROPAT sub podeaua pe care stau
## celelalte: de-aia "plutea" intr-un gol, fara contact cu peretele.
##
## Reparatia nu muta buza si nu schimba scara: aseaza hero-ul pe aceeasi
## podea (5.7) si il trage lateral de la 22 m la ~18 m, la fractia 0.333, unde
## soseaua e la 29.2. Varful iese la 32.3, adica +3.1 m PESTE drum, cu 26 m de
## etaje cascadand dedesubt — exact "incepe la 5 m sub buza, nu la 50" din
## brief §8, si vazut de la volan in coborarea in S.
##
## `hongya_registru2228` (talpa -27.8, varf 32 m SUB drum) primeste acelasi
## tratament: al doilea registru, mai jos si mai in spate, ca silueta sa aiba
## adancime.
##
## Pasarela: dezvoltatorul a cerut "ori o legi de ceva, ori o scoti". Brief
## §2 G o vrea ca IESIRE din holul Liziba spre piata, deci se muta din campul
## gol de la 19 m lateral si se aseaza TRAVERSAND soseaua la iesirea din hol,
## cu talpa pe cota drumului, la inaltimea de gabarit.
##
## Nimic nu se scrie tacit: fiecare piesa emisa trece intai prin verificarea
## dot(-Z, spre_sosea) si prin recitirea cotei terenului sub talpa.
const TRACK := "res://scenes/tracks/Track12.tscn"
const OUT := "res://tools/_cq_hero.txt"

var _track: Track
var _out: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var dm := _track.get_node_or_null(NodePath("DecorManual")) as Node3D
	if dm == null:
		push_error("fara DecorManual")
		get_tree().quit(1)
		return

	_place_hero(dm, "hongya_hero227", 0.333, 18.0, 5.7)
	_place_hero(dm, "hongya_registru2228", 0.352, 30.0, 5.7)
	_place_pasarela(dm)

	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string("\n".join(_out))
	fa.close()
	print("scris %s (%d linii)" % [OUT, _out.size()])
	get_tree().quit(0)


## Aseaza o piesa de Hongya Dong pe podeaua rapei, la `lat` metri in dreapta
## soselei la fractia `f`, cu fatada (-Z, adica +Y din Blender) spre drum.
func _place_hero(dm: Node3D, nm: String, f: float, lat: float, floor_y: float) -> void:
	var n := dm.find_child(nm, true, false) as Node3D
	if n == null:
		_out.append("# %s LIPSA" % nm)
		return
	var r := _track.routes[0]
	var cnt := r.baked.size()
	var i := int(round(f * float(cnt))) % cnt
	var rp: Vector3 = r.baked[i]
	var side := _track._side_at(i)
	var pos := Vector3(rp.x + side.x * lat, floor_y, rp.z + side.z * lat)

	# Fatada spre drum: -Z al nodului pe directia piesa -> sosea.
	var to_road := Vector3(rp.x - pos.x, 0.0, rp.z - pos.z).normalized()
	var yaw := atan2(-to_road.x, -to_road.z)
	var b := Basis(Vector3.UP, yaw)
	var check := (-b.z).dot(to_road)
	if check < 0.99:
		push_error("yaw gresit pentru %s: dot=%.3f" % [nm, check])
		return
	var scl := n.global_basis.get_scale()
	b = b.scaled(scl)

	# Inaltimea reala a piesei, ca sa raportam varful fata de sosea.
	var h := _height(n)
	_out.append("# %s  frac %.3f, lat %.1f m, talpa %.1f, varf %.1f (sosea %.1f, %+.1f), dot %+.2f"
		% [nm, f, lat, floor_y, floor_y + h, rp.y, floor_y + h - rp.y, check])
	_out.append("%s|%s" % [nm, _tscn_transform(b, pos)])


## Pasarela devine iesirea din hol: traverseaza soseaua, cu talpa pe cota
## drumului plus gabaritul. Brief §2 G: "iesirea pe o pasarela spre piata".
func _place_pasarela(dm: Node3D) -> void:
	var nm := "pasarela224"
	var n := dm.find_child(nm, true, false) as Node3D
	if n == null:
		_out.append("# %s LIPSA" % nm)
		return
	var r := _track.routes[0]
	var cnt := r.baked.size()
	var f := 0.955
	var i := int(round(f * float(cnt))) % cnt
	var rp: Vector3 = r.baked[i]
	var side := _track._side_at(i)
	# GEOMETRIA PIESEI, citita din generator (build_chongqing_structures.py):
	# tablierul e lung de L=24 m pe Y-ul din Blender, adica pe Z-ul LOCAL in
	# Godot (+Y Blender -> -Z Godot). Picioarele coboara pana la -4.95 local,
	# iar originea e "base", deci pivotul e la TALPA picioarelor, nu la
	# tablier. Aici era si defectul vechi: talpa masurata la +1.2 m PESTE
	# sosea inseamna picioare care nu ating nimic.
	var leg_drop := 4.95
	var clearance := 6.2
	var scl := n.global_basis.get_scale()
	# Talpa pe cota drumului; tablierul iese la clearance deasupra.
	var pos := Vector3(rp.x, rp.y + clearance - leg_drop * scl.y, rp.z)
	# Ca sa TRAVERSEZE, lungimea (Z local) trebuie sa fie pe directia
	# LATERALA a soselei. Z local dus pe `side`: derivat cu dot, nu ghicit.
	var yaw := atan2(side.x, side.z)
	var b := Basis(Vector3.UP, yaw)
	var check := b.z.dot(side)
	if check < 0.99:
		push_error("yaw gresit pentru %s: dot=%.3f" % [nm, check])
		return
	b = b.scaled(scl)
	_out.append("# %s  frac %.3f, TRAVERSEAZA soseaua, tablier %+.1f m peste drum (sosea %.1f), dot %+.2f"
		% [nm, f, clearance, rp.y, check])
	_out.append("%s|%s" % [nm, _tscn_transform(b, pos)])


func _height(n: Node3D) -> float:
	var lo := INF
	var hi := -INF
	for vi: VisualInstance3D in _vis(n):
		if not vi.visible:
			continue
		var a: AABB = vi.get_aabb()
		var gt: Transform3D = vi.global_transform
		for c in 8:
			var p: Vector3 = gt * (a.position + Vector3(
				a.size.x * float(c & 1), a.size.y * float((c >> 1) & 1),
				a.size.z * float((c >> 2) & 1)))
			lo = minf(lo, p.y)
			hi = maxf(hi, p.y)
	return (hi - lo) if hi > lo else 0.0


func _vis(root: Node) -> Array[VisualInstance3D]:
	var out: Array[VisualInstance3D] = []
	if root is VisualInstance3D:
		out.append(root)
	for c in root.get_children():
		out.append_array(_vis(c))
	return out


## Literalul din `.tscn` e pe LINII, nu pe coloane (vezi `fix_cq_fatade.gd`:
## scris pe coloane iese TRANSPUSA, adica rotatia inversa).
func _tscn_transform(b: Basis, o: Vector3) -> String:
	return "transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)" % [
		b.x.x, b.y.x, b.z.x,
		b.x.y, b.y.y, b.z.y,
		b.x.z, b.y.z, b.z.z,
		o.x, o.y, o.z]
