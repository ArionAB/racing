extends Node
## Garda pentru `custom_dirt_ranges`: drum de pamant pe FRACTII dintr-o bucla cu
## asfalt (Monument Valley: asfalt pe A, B, H, pamant pe C-G).
##
## Masoara MECANISMUL, nu o constanta. Fiecare afirmatie se verifica de doua ori:
## pe pista cu intervalul declarat (trebuie sa treaca) si pe o pista IDENTICA fara
## interval (SABOTAJ: trebuie sa pice). Cifra care nu se misca la oprirea
## mecanismului ar masura altceva — vezi memoria `sonda-masura-alt-obiect`.
##
## Ce se verifica, pe Track01 cu intervalul (0.2, 0.4):
##   (a) materialul de sub un punct de pe sosea, citit din GEOMETRIE (care mesh
##       are un triunghi sub punctul ala), la frac 0.3 = pamant, la 0.6 = asfalt;
##       si ca materialul de pamant e ACELASI cu al unei piste cu
##       `custom_road_surface = "dirt"` (shader, texturi, culoare, rugozitate);
##   (b) interogarile pe fractie (`is_dirt_at`, `road_is_loose_at`, `is_loose_at`
##       — aceasta din urma e calea de grip) dau true/false cum trebuie, inclusiv
##       pe un interval care trece peste linia de start;
##   (c) numarul de materiale distincte creste cu EXACT 1 fata de aceeasi pista
##       fara interval;
##   (d) linia de mijloc, bordurile si urmele coapte lipsesc din interval si
##       exista inafara lui (un mesh golit cu totul n-ar dovedi nimic);
##   (e) masina: `Car._on_loose_ground` si praful/fumul de drift urmaresc
##       fractia — pamant pe interval, nimic pe asfalt;
##   (f) o pista FARA interval nu primeste nodul `DirtRoad`.
##
## Ruleaza CA SCENA (Car cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDirtRanges.tscn
## Iese cu cod 1 la orice verdict picat, la orice sabotaj care NU pica si la
## orice masuratoare care n-a gasit ce cauta (zero masuratori nu e succes).

const TRACK_SCENE: String = "res://scenes/tracks/Track01.tscn"
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const RANGES: Array[Vector2] = [Vector2(0.2, 0.4)]
## Pe Track01 nu exista urme coapte in (0.2, 0.4) — doar de la 0.4 incolo —, deci
## pentru ele un al doilea interval, unde exista (vezi histograma tiparita).
const MARKS_RANGE: Vector2 = Vector2(0.7, 0.8)
const F_DIRT: float = 0.3
const F_ASPHALT: float = 0.6
## Culoarea liniei de mijloc (Track._build_center_line), singurul mesh de pe pista
## care o foloseste: asa il gasim fara sa-i dam nume (nume nou = alt recensamant).
const CENTER_LINE_COLOR: Color = Color(0.92, 0.9, 0.78)

var _fails: int = 0
## Cate afirmatii au fost EVALUATE (nu doar trecute): zero = sonda n-a masurat.
var _evaluated: int = 0


func _ready() -> void:
	# Un cadru inainte de orice add_child: root e ocupat cu propriul _ready.
	await get_tree().process_frame

	print("=== ProbeDirtRanges: %s, interval %s ===" % [TRACK_SCENE, RANGES])
	# Referinta de materiale: aceeasi pista, fara interval, DOUA constructii —
	# a doua e subiectul sabotajului si, comparata cu prima, arata ca numaratoarea
	# e stabila de la o constructie la alta (altfel "+1" n-ar insemna nimic).
	var base := await _build([], "asphalt")
	var base_count := _count_materials(base)
	var base_marks := _furniture_counts(base, RANGES[0])
	var sab := await _build([], "asphalt")
	var dirt_ref := await _build([], "dirt")
	var real := await _build(RANGES, "asphalt")

	print("materiale: fara interval=%d (a doua constructie: %d), cu interval=%d" % [
		base_count, _count_materials(sab), _count_materials(real)])
	print("mobilier in interval, pista FARA interval (referinta): linie %d, borduri %d, urme %d" % [
		base_marks["center"][0], base_marks["kerbs"][0], base_marks["marks"][0]])
	print("urme coapte pe pista de referinta, varfuri pe zecimi de tur: %s" % [_marks_histogram(base)])
	_expect("determinism: doua constructii fara interval au acelasi numar de materiale",
		_count_materials(sab) == base_count)
	_expect("(f) fara interval nu exista nodul DirtRoad", sab.get_node_or_null("DirtRoad") == null)
	_expect("(f) cu interval exista exact un nod DirtRoad", real.get_node_or_null("DirtRoad") != null)

	print("--- pista CU interval (toate trebuie sa treaca) ---")
	var real_fails := _check(real, base_count, dirt_ref)
	print("--- SABOTAJ: aceeasi pista cu intervalul GOL (toate afirmatiile despre %.1f trebuie sa pice) ---" % F_DIRT)
	var sab_fails := _check(sab, base_count, dirt_ref)

	# Verdictul real: nicio afirmatie picata pe pista cu interval.
	_expect("pista cu interval: zero afirmatii picate (au picat %d: %s)" % [
		real_fails.size(), real_fails], real_fails.is_empty())
	# Verdictul sabotajului: fiecare afirmatie care depinde de interval TREBUIE sa
	# pice cand intervalul lipseste. Cele ramase pe verde ar masura altceva.
	var must_fail: Array[String] = [
		"(a) material la %.1f = pamant" % F_DIRT,
		"(b) is_dirt_at(%.1f)" % F_DIRT,
		"(b) is_loose_at(%.1f) (calea de grip)" % F_DIRT,
		"(b) road_is_loose_at(%.1f)" % F_DIRT,
		"(c) materiale = referinta + 1",
		"(d) linia de mijloc lipseste din interval",
		"(e) _on_loose_ground la %.1f" % F_DIRT,
		"(e) praf pornit la %.1f" % F_DIRT,
		"(e) praful are culoarea pamantului",
		"(e) fumul de drift e al pamantului pe interval",
	]
	for name in must_fail:
		_expect("SABOTAJ: \"%s\" pica fara interval" % name, sab_fails.has(name))
	# Bordurile: daca referinta n-are niciuna in interval, afirmatia n-ar dovedi
	# nimic (nu ar putea pica la sabotaj) — se raporteaza VACUU, nu trecut.
	if int(base_marks["kerbs"][0]) == 0:
		print("  VACUU: nicio bordura in intervalul %s nici pe pista de referinta" % [RANGES[0]])
		_fails += 1
	else:
		_expect("SABOTAJ: \"(d) kerbs lipsesc din interval\" pica fara interval",
			sab_fails.has("(d) kerbs lipsesc din interval"))

	# Urmele coapte, pe al doilea interval (unde exista in referinta). Sabotajul
	# e pista fara interval: aceleasi varfuri trebuie sa fie ACOLO.
	var marks_ranges: Array[Vector2] = [MARKS_RANGE]
	var real_m := await _build(marks_ranges, "asphalt")
	var m_with: Array = _furniture_counts(real_m, MARKS_RANGE)["marks"]
	var m_without: Array = _furniture_counts(base, MARKS_RANGE)["marks"]
	print("urme coapte in %s: fara interval %d in / %d afara, cu interval %d in / %d afara" % [
		MARKS_RANGE, m_without[0], m_without[1], m_with[0], m_with[1]])
	_expect("(d) urme coapte: pista FARA interval are urme in %s (sabotaj: mecanismul le scoate)" % [MARKS_RANGE],
		int(m_without[0]) > 0)
	_expect("(d) urme coapte: pista CU interval n-are nicio urma in %s si le pastreaza afara" % [MARKS_RANGE],
		int(m_with[0]) == 0 and int(m_with[1]) > 0)

	# Interval care trece peste linia de start: doar interogarile (nu reconstruim).
	var wrap_ranges: Array[Vector2] = [Vector2(0.9, 0.1)]
	real.custom_dirt_ranges = wrap_ranges
	_expect("(b) interval cu trecere peste start: 0.95 si 0.05 pe pamant, 0.5 nu",
		real.is_dirt_at(0.95) and real.is_dirt_at(0.05) and not real.is_dirt_at(0.5))
	real.custom_dirt_ranges = RANGES

	if _evaluated < 30:
		print("EROARE: doar %d afirmatii evaluate — sonda n-a masurat ce trebuia" % _evaluated)
		_fails += 1
	print("=== %s (%d afirmatii evaluate, %d picate) ===" % [
		"VERDICT: OK" if _fails == 0 else "VERDICT: PICAT", _evaluated, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


## Construieste o pista cu intervalul si suprafata ceruta si o lasa sa se
## termine de construit (rebuild() ruleaza in _ready, copiii intra dupa).
func _build(ranges: Array[Vector2], surface: String) -> Track:
	var scene := load(TRACK_SCENE) as PackedScene
	var t := scene.instantiate() as Track
	t.set("custom_dirt_ranges", ranges)
	t.set("custom_road_surface", surface)
	add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	return t


## Toate afirmatiile pe o pista. Intoarce NUMELE celor picate (si le tipareste).
## Folosita si pe pista reala, si pe sabotaj: aceleasi afirmatii, alt subiect.
func _check(t: Track, base_count: int, dirt_ref: Track) -> Array[String]:
	var failed: Array[String] = []

	# (a) materialul de sub punct, din geometrie.
	var m_dirt := _road_material_at(t, F_DIRT)
	var m_asph := _road_material_at(t, F_ASPHALT)
	_verdict(failed, "(a) material la %.1f = pamant" % F_DIRT,
		m_dirt != null and _micro_path(m_dirt).contains("surface_sand"),
		"micro=%s" % (_micro_path(m_dirt) if m_dirt != null else "<nimic sub punct>"))
	_verdict(failed, "(a) material la %.1f = asfalt" % F_ASPHALT,
		m_asph != null and _micro_path(m_asph).contains("surface_asphalt"),
		"micro=%s" % (_micro_path(m_asph) if m_asph != null else "<nimic sub punct>"))
	# Pamantul de pe interval e ACELASI material ca la o pista de pamant intreaga.
	var ref_mat := _road_material_at(dirt_ref, F_DIRT)
	_verdict(failed, "(a) pamantul e materialul existent (= pista cu road_surface dirt)",
		m_dirt != null and ref_mat != null and _same_look(m_dirt, ref_mat),
		_describe(m_dirt) + " vs " + _describe(ref_mat))

	# (b) interogarile pe fractie.
	_verdict(failed, "(b) is_dirt_at(%.1f)" % F_DIRT, t.is_dirt_at(F_DIRT))
	_verdict(failed, "(b) !is_dirt_at(%.1f)" % F_ASPHALT, not t.is_dirt_at(F_ASPHALT))
	_verdict(failed, "(b) is_loose_at(%.1f) (calea de grip)" % F_DIRT, t.is_loose_at(F_DIRT))
	_verdict(failed, "(b) !is_loose_at(%.1f)" % F_ASPHALT, not t.is_loose_at(F_ASPHALT))
	_verdict(failed, "(b) road_is_loose_at(%.1f)" % F_DIRT, t.road_is_loose_at(F_DIRT))
	_verdict(failed, "(b) !road_is_loose_at(%.1f)" % F_ASPHALT, not t.road_is_loose_at(F_ASPHALT))

	# (c) numarul de materiale.
	var count := _count_materials(t)
	_verdict(failed, "(c) materiale = referinta + 1", count == base_count + 1,
		"%d vs referinta %d" % [count, base_count])

	# (d) mobilierul.
	var marks := _furniture_counts(t, RANGES[0])
	var cen: Array = marks["center"]
	_verdict(failed, "(d) linia de mijloc lipseste din interval",
		int(cen[0]) == 0 and int(cen[1]) > 0,
		"in interval %d, inafara %d" % [cen[0], cen[1]])
	var kerbs: Array = marks["kerbs"]
	_verdict(failed, "(d) kerbs lipsesc din interval",
		int(kerbs[0]) == 0 and int(kerbs[1]) > 0,
		"in interval %d, inafara %d" % [kerbs[0], kerbs[1]])

	# (e) masina.
	var car_res := _car_checks(t)
	_verdict(failed, "(e) _on_loose_ground la %.1f" % F_DIRT, car_res["loose_dirt"])
	_verdict(failed, "(e) !_on_loose_ground la %.1f" % F_ASPHALT, not car_res["loose_asphalt"])
	_verdict(failed, "(e) praf pornit la %.1f" % F_DIRT, car_res["dust_dirt"])
	_verdict(failed, "(e) praf oprit la %.1f" % F_ASPHALT, not car_res["dust_asphalt"])
	_verdict(failed, "(e) praful are culoarea pamantului", car_res["dust_color_ok"],
		"%s vs asteptat %s" % [car_res["dust_color"], car_res["dust_color_want"]])
	_verdict(failed, "(e) fumul de drift e al pamantului pe interval", car_res["drift_dirt_ok"])
	_verdict(failed, "(e) fumul de drift revine la gri pe asfalt", car_res["drift_reset"])
	return failed


## Un Car real pus la sol (fara fizica) pe fractia ceruta: intreaba suprafata si
## porneste praful exact cum o face _update_effects.
func _car_checks(t: Track) -> Dictionary:
	var out := {}
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.set_physics_process(false)
	car.freeze = true
	car.track = t
	car.route = 0
	car.wheels_on_ground = 4
	car.velocity = Vector3(0.0, 0.0, -20.0)

	car.road_index = _index_at_frac(t, F_DIRT)
	var on_dirt := car._on_loose_ground(true)
	car._update_dust(true, on_dirt, false)
	out["loose_dirt"] = on_dirt
	out["dust_dirt"] = car._dust_particles.emitting
	out["dust_color"] = car._dust_particles.color
	out["dust_color_want"] = t.road_dust_color().lightened(0.18)
	# Pe interval praful e al DRUMULUI de pamant, nu al asfaltului (gri inchis).
	out["dust_color_ok"] = on_dirt and (out["dust_color"] as Color).is_equal_approx(
		t.dirt_road_color().lightened(0.18))
	# Fumul de drift ia culoarea prafului pe pamant (nu gri de cauciuc).
	out["drift_dirt_ok"] = on_dirt and (car._drift_particles.color as Color).is_equal_approx(
		out["dust_color"] as Color)

	car.road_index = _index_at_frac(t, F_ASPHALT)
	var on_asph := car._on_loose_ground(true)
	car._update_dust(true, on_asph, false)
	out["loose_asphalt"] = on_asph
	out["dust_asphalt"] = car._dust_particles.emitting
	out["drift_reset"] = (car._drift_particles.color as Color).is_equal_approx(
		Car.DRIFT_SMOKE_COLOR)
	car.queue_free()
	return out


# --- masuratori ----------------------------------------------------------


## Indexul de punct copt cu fractia cea mai apropiata de `f`.
func _index_at_frac(t: Track, f: float) -> int:
	var best := 0
	var best_d := 1e9
	for i in t.baked.size():
		var d := absf(t.frac_at(i) - f)
		if d < best_d:
			best_d = d
			best = i
	return best


## Materialul soselei de sub punctul de la fractia `f`, citit din GEOMETRIE:
## primul mesh de sosea (RoadTop / DirtRoad) care are un triunghi deasupra
## punctului (in XZ, la aceeasi inaltime). Null daca nu-l acopera niciunul.
func _road_material_at(t: Track, f: float) -> Material:
	var p := t.baked[_index_at_frac(t, f)]
	# Mesh-ul soselei NU se numeste RoadTop (asa se numeste doar corpul de
	# coliziune): il recunoastem dupa shaderul de carosabil, la fel pentru asfalt
	# si pentru DirtRoad.
	for n in t.get_children():
		var inst := n as MeshInstance3D
		if inst == null or inst.mesh == null:
			continue
		var sm := inst.material_override as ShaderMaterial
		if sm == null or sm.shader == null 				or not sm.shader.resource_path.ends_with("road_detail_fade.gdshader"):
			continue
		if _mesh_covers(inst.mesh, p):
			return inst.material_override
	return null


func _mesh_covers(mesh: Mesh, p: Vector3) -> bool:
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var idx := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
		var tri_count := idx.size() / 3 if idx.size() > 0 else verts.size() / 3
		for k in tri_count:
			var a: Vector3
			var b: Vector3
			var c: Vector3
			if idx.size() > 0:
				a = verts[idx[k * 3]]
				b = verts[idx[k * 3 + 1]]
				c = verts[idx[k * 3 + 2]]
			else:
				a = verts[k * 3]
				b = verts[k * 3 + 1]
				c = verts[k * 3 + 2]
			if absf(a.y - p.y) > 1.0:
				continue
			if _in_tri_xz(p, a, b, c):
				return true
	return false


func _in_tri_xz(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> bool:
	var d1 := (p.x - b.x) * (a.z - b.z) - (a.x - b.x) * (p.z - b.z)
	var d2 := (p.x - c.x) * (b.z - c.z) - (b.x - c.x) * (p.z - c.z)
	var d3 := (p.x - a.x) * (c.z - a.z) - (c.x - a.x) * (p.z - a.z)
	var neg := d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var pos := d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (neg and pos)


func _micro_path(m: Material) -> String:
	var sm := m as ShaderMaterial
	if sm == null:
		return "<nu e ShaderMaterial>"
	var tex := sm.get_shader_parameter("micro_tex") as Texture2D
	return tex.resource_path if tex != null else "<fara micro_tex>"


## Doua materiale de sosea arata la fel: acelasi shader, aceleasi texturi si
## aceiasi parametri numerici.
func _same_look(a: Material, b: Material) -> bool:
	var sa := a as ShaderMaterial
	var sb := b as ShaderMaterial
	if sa == null or sb == null or sa.shader != sb.shader:
		return false
	for key in ["micro_tex", "macro_tex"]:
		var ta := sa.get_shader_parameter(key) as Texture2D
		var tb := sb.get_shader_parameter(key) as Texture2D
		if ta == null or tb == null or ta.resource_path != tb.resource_path:
			return false
	var ca := sa.get_shader_parameter("base_color") as Color
	var cb := sb.get_shader_parameter("base_color") as Color
	return ca.is_equal_approx(cb) \
		and is_equal_approx(float(sa.get_shader_parameter("roughness_v")),
			float(sb.get_shader_parameter("roughness_v"))) \
		and is_equal_approx(float(sa.get_shader_parameter("specular_v")),
			float(sb.get_shader_parameter("specular_v")))


func _describe(m: Material) -> String:
	var sm := m as ShaderMaterial
	if sm == null:
		return "<nimic>"
	return "{%s base=%s}" % [_micro_path(m).get_file(),
		(sm.get_shader_parameter("base_color") as Color).to_html(false)]


## Materialele DISTINCTE (dupa instanta) randate de pista: material_override,
## materialele pe suprafete si overlay-ul, pe MeshInstance3D si MultiMeshInstance3D
## VIZIBILE. Ca garda de materiale din probe_decor, fara atribuirea pe surse.
func _count_materials(t: Track) -> int:
	var seen := {}
	for n in t.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if not gi.visible:
			continue
		var anc := gi.get_parent()
		var hidden := false
		while anc != null and anc != t:
			if anc is Node3D and not (anc as Node3D).visible:
				hidden = true
				break
			anc = anc.get_parent()
		if hidden:
			continue
		if gi.material_override != null:
			seen[gi.material_override.get_instance_id()] = true
		if gi.material_overlay != null:
			seen[gi.material_overlay.get_instance_id()] = true
		var mesh: Mesh = null
		if gi is MeshInstance3D:
			mesh = (gi as MeshInstance3D).mesh
		elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh != null:
			mesh = (gi as MultiMeshInstance3D).multimesh.mesh
		if mesh != null:
			for s in mesh.get_surface_count():
				var sm := mesh.surface_get_material(s)
				if sm != null:
					seen[sm.get_instance_id()] = true
	return seen.size()


## Pentru linia de mijloc, borduri si urme coapte: cate varfuri cad IN interval
## (cu o margine de 1% la capete, ca segmentul de tranzitie sa nu conteze) si
## cate INAFARA lui. Returneaza {nume: [inauntru, inafara]}.
func _furniture_counts(t: Track, r: Vector2) -> Dictionary:
	var margin := 0.01
	var out := {"center": [0, 0], "kerbs": [0, 0], "marks": [0, 0]}
	for n in t.get_children():
		var inst := n as MeshInstance3D
		if inst == null or inst.mesh == null:
			continue
		var key := ""
		if inst.name == &"Kerbs":
			key = "kerbs"
		elif inst.name == &"TireMarks":
			key = "marks"
		else:
			var sm := inst.material_override as StandardMaterial3D
			if sm != null and sm.albedo_color.is_equal_approx(CENTER_LINE_COLOR) \
					and sm.albedo_texture == null:
				key = "center"
		if key == "":
			continue
		for s in inst.mesh.get_surface_count():
			var verts := inst.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array
			# Un varf din trei: indeajuns pentru numarat, si de 3x mai ieftin.
			for k in range(0, verts.size(), 3):
				var f := t.frac_at(t.closest_index_global(verts[k], 0))
				if f > r.x + margin and f < r.y - margin:
					out[key][0] += 1
				elif f < r.x - margin or f > r.y + margin:
					out[key][1] += 1
	return out


## Varfurile urmelor coapte, pe zecimi de tur: arata unde exista urme de
## acoperit cu un interval de pamant.
func _marks_histogram(t: Track) -> Array:
	var bins := []
	bins.resize(10)
	bins.fill(0)
	var inst := t.get_node_or_null("TireMarks") as MeshInstance3D
	if inst == null or inst.mesh == null:
		return bins
	for s in inst.mesh.get_surface_count():
		var verts := inst.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array
		for k in range(0, verts.size(), 3):
			var f := t.frac_at(t.closest_index_global(verts[k], 0))
			bins[clampi(int(f * 10.0), 0, 9)] += 1
	return bins


# --- raportare -------------------------------------------------------------


## Inregistreaza o afirmatie evaluata pe o pista; o tipareste cu detaliu.
func _verdict(failed: Array[String], name: String, ok: bool, detail: String = "") -> void:
	_evaluated += 1
	print("  %s %s%s" % ["ok   " if ok else "PICAT", name,
		("  [" + detail + "]") if detail != "" else ""])
	if not ok:
		failed.append(name)


## Afirmatie de nivel sonda (nu pe o pista anume): picata = esec al probei.
func _expect(name: String, ok: bool) -> void:
	_evaluated += 1
	print("%s %s" % ["OK   " if ok else "ESEC ", name])
	if not ok:
		_fails += 1
