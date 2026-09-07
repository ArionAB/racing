extends Node
## POI D, runda 3 — PETELE DE SOARE PE CAROSABIL.
## Criticul rundei 2 a cerut exact aceasta masuratoare: pe felia 0.22-0.30 a
## padurii, mediana luminantei carosabilului >= 90 SI cel putin 3 pete
## luminate DISTINCTE (componente conexe cu luminanta > 120) — a doua conditie
## e garda contra platirii tintei prin ridicarea uniforma a expunerii
## (memoria `tinta-pe-o-axa-se-atinge-pe-axa-aia`).
##
##   godot --headless --path . res://tools/ProbePete.tscn -- --track=7
##
## Metoda: pentru fiecare fractie de esantion asez camera EXACT ca ChaseCamera
## (10 m sus, 12.5 m in spate, FOV 68, priveste inainte) si rasterizez cu
## `intersect_ray` un evantai de raze prin pixelii unei imagini de 96x54.
## Pixelii care lovesc TerrainBody/RoadBody in interiorul benzii (distanta la
## ax <= half) sunt „carosabil". Luminanta nu vine dintr-un randare (headless
## n-are cadru), ci din MODELUL de lumina al scenei: soare * (n·l) * vizibil +
## ambient, unde `vizibil` e o a doua raza catre soare (umbra reala aruncata
## de coroane). Asta masoara EXACT ce se plange criticul — cine blocheaza
## soarele — si nu depinde de captura.
const CAM_H := 10.0
const CAM_B := 12.5
const FOV := 68.0
const W := 96
const H := 54

var _track: Node3D
var _sun_dir: Vector3
var _sun_e: float
var _amb: float

func _ready() -> void:
	await get_tree().process_frame
	var ti := 7
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			ti = GameState.resolve_track_index(int(a.split("=")[1]))
	var scn := load(GameState.TRACK_SCENES[ti]) as PackedScene
	_track = scn.instantiate()
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var sun: DirectionalLight3D = _track.find_child("Sun", true, false) as DirectionalLight3D
	if sun == null:
		for c in _track.find_children("*", "DirectionalLight3D", true, false):
			sun = c as DirectionalLight3D
			break
	_sun_dir = -sun.global_transform.basis.z
	_sun_e = sun.light_energy
	var env: WorldEnvironment = null
	for c in _track.find_children("*", "WorldEnvironment", true, false):
		env = c as WorldEnvironment
	_amb = env.environment.ambient_light_energy if env else 0.2
	_collect_crowns()
	print("soare dir=%.3f,%.3f,%.3f energie=%.2f ambient=%.2f" % [
		_sun_dir.x, _sun_dir.y, _sun_dir.z, _sun_e, _amb])
	# VERDICTUL E PE FIECARE FRACTIE, NU PE GRAMADA. Prima varianta aduna toti
	# pixelii si scotea mediana 116 „OK" pe o stare in care trei fractii din
	# sase erau la 25.9 (adica DOAR ambient — tunel inchis) si trei complet
	# insorite. Media peste o alternanta de tunel si poiana nu descrie nici
	# tunelul nici poiana (memoria `impartirea-pe-jumatati-ascunde-umbrirea`).
	# Contractul referintei e ca pe ORICE bucata de drum cade si soare si
	# umbra: deci pe fiecare fractie cer o fractiune insorita intre 25% si 85%
	# (sub 25% = tunel, peste 85% = poiana fara baldachin) si cel putin 2 pete
	# distincte, plus mediana globala >= 90 si >= 3 pete pe felie.
	var lums: PackedFloat32Array = PackedFloat32Array()
	var spots := 0
	var bad: Array[String] = []
	for f in [0.212, 0.224, 0.240, 0.253, 0.268, 0.287, 0.300, 0.315]:
		var r := _shot(f)
		var px: PackedFloat32Array = r[0]
		var lit := 0
		for v in px:
			lums.append(v)
			if v > 120.0:
				lit += 1
		var share := float(lit) / maxf(1.0, float(px.size()))
		spots += int(r[1])
		var ok := share >= 0.25 and share <= 0.85 and int(r[1]) >= 2
		if not ok:
			bad.append("%.3f (insorit %.0f%%, pete %d)" % [f, share * 100.0, int(r[1])])
		print("frac %.3f: pixeli %d, mediana %.1f, insorit %.0f%%, pete %d %s" % [
			f, px.size(), _med(px), share * 100.0, int(r[1]), "" if ok else "<-- PICA"])
	var m := _med(lums)
	print("TOTAL mediana luminantei carosabilului = %.1f (cere >= 90)" % m)
	print("TOTAL pete distincte (lum > 120) = %d (cere >= 3)" % spots)
	print("FRACTII care pica: %d %s" % [bad.size(), ", ".join(bad)])
	print("VERDICT %s" % ("OK" if m >= 90.0 and spots >= 3 and bad.is_empty() else "PICA"))
	get_tree().quit()


func _med(a: PackedFloat32Array) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return b[b.size() / 2]


## Un „cadru": raze prin 96x54 pixeli, din pozitia camerei de joc.
func _shot(frac: float) -> Array:
	var n: int = _track.baked.size()
	var i: int = int(frac * float(n)) % n
	var p: Vector3 = _track.baked[i]
	var pf: Vector3 = _track.baked[(i + 6) % n]
	var fwd := (pf - p)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var eye := p - fwd * CAM_B + Vector3(0, CAM_H, 0)
	var aim := p + fwd * 8.0
	var zf := (eye - aim).normalized()
	var xf := Vector3.UP.cross(zf).normalized()
	var yf := zf.cross(xf)
	var space := _track.get_world_3d().direct_space_state
	var th := tan(deg_to_rad(FOV) * 0.5)
	var asp := 16.0 / 9.0
	var lums := PackedFloat32Array()
	var lit: Array[Vector2i] = []
	for py in H:
		for px in W:
			var sx := (float(px) + 0.5) / float(W) * 2.0 - 1.0
			var sy := 1.0 - (float(py) + 0.5) / float(H) * 2.0
			var dir := (xf * sx * th * asp + yf * sy * th - zf).normalized()
			var q := PhysicsRayQueryParameters3D.create(eye, eye + dir * 120.0)
			q.collide_with_areas = false
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				continue
			var hp: Vector3 = hit["position"]
			# e pe banda? distanta la axul cel mai apropiat
			var j := _closest(hp)
			var half: float = _track.width_at_index(j)
			if (hp - _track.baked[j]).length() > half:
				continue
			if absf(hp.y - _track.baked[j].y) > 2.0:
				continue
			var nrm: Vector3 = hit["normal"]
			# UMBRA NU SE MASOARA CU intersect_ray. Coroanele au
			# `metadata/coliziune = "trunk"`, deci corpul fizic al copacului e
			# doar trunchiul: o raza spre soare trece PRIN frunzis si intoarce
			# „insorit" pe un drum care in randare e negru (memoria
			# `coliziune-none-e-fantoma-nu-stearsa`). Prima versiune a sondei a
			# dat mediana 120.6 acolo unde captura masoara 24.
			# Deci umbra se calculeaza GEOMETRIC: fiecare coroana e o sfera
			# (centru = trunchiul la `crown_y`, raza CROWN_R * scara), si
			# punctul e la umbra daca segmentul spre soare taie o sfera.
			var occl := _shaded(hp)
			var ndl: float = maxf(0.0, nrm.dot(-_sun_dir))
			# albedo lateritic ~ (0.62,0.36,0.22) -> luminanta relativa 0.42
			var alb := 0.42
			var l := alb * (_sun_e * ndl * (0.0 if occl else 1.0) + _amb) * 255.0 * 1.10
			lums.append(l)
			if l > 120.0:
				lit.append(Vector2i(px, py))
	return [lums, _components(lit)]


## Coroanele din scena, ca sfere: (centru, raza).
var _crowns: Array[PackedFloat32Array] = []

## Numele modelelor cu coroana si raza/inaltimea de coroana la scara 1
## (aceleasi cifre ca in generator: BASE_R/CROWN_R/HEIGHT din
## tools/gen_decor_ser_d.gd).
const CROWN_R := {"fig_tree": 5.6, "fever_tree": 4.4, "acacia_umbrella_a": 5.0}
const CROWN_Y := {"fig_tree": 0.72, "fever_tree": 0.78, "acacia_umbrella_a": 0.85}
const MODEL_H := {"fig_tree": 13.0, "fever_tree": 10.12, "acacia_umbrella_a": 7.0}


func _collect_crowns() -> void:
	var zone := _track.find_child("ZoneD_PadureaDeCeata", true, false)
	if zone == null:
		print("ATENTIE: nu gasesc ZoneD_PadureaDeCeata")
		return
	for c in zone.get_children():
		var n := str(c.name)
		var mdl := ""
		if n.begins_with("smochin"):
			mdl = "fig_tree"
		elif n.begins_with("febra"):
			mdl = "fever_tree"
		elif n.begins_with("acacie"):
			mdl = "acacia_umbrella_a"
		else:
			continue
		var t: Transform3D = (c as Node3D).global_transform
		var scl: float = t.basis.get_scale().y
		var r: float = float(CROWN_R[mdl]) * scl
		var cy: float = t.origin.y + float(MODEL_H[mdl]) * float(CROWN_Y[mdl]) * scl
		_crowns.append(PackedFloat32Array([t.origin.x, cy, t.origin.z, r]))
	print("coroane in ZoneD: %d" % _crowns.size())


## E punctul la umbra? Segment de la punct spre soare, taiat de vreo sfera.
func _shaded(hp: Vector3) -> bool:
	var d := -_sun_dir # spre soare
	for cr in _crowns:
		var c := Vector3(cr[0], cr[1], cr[2])
		var r: float = cr[3]
		var oc := c - hp
		var tca := oc.dot(d)
		if tca <= 0.0:
			continue
		var d2 := oc.length_squared() - tca * tca
		if d2 <= r * r:
			return true
	return false


func _closest(hp: Vector3) -> int:
	var n: int = _track.baked.size()
	var best := 0
	var bd := 1e20
	for k in n:
		var d: float = (_track.baked[k] - hp).length_squared()
		if d < bd:
			bd = d
			best = k
	return best


## Componente conexe pe grila de pixeli (8-vecini), ignorand petele minuscule.
func _components(lit: Array[Vector2i]) -> int:
	var setp := {}
	for v in lit:
		setp[v] = true
	var cnt := 0
	while not setp.is_empty():
		var start: Vector2i = setp.keys()[0]
		var stack: Array[Vector2i] = [start]
		setp.erase(start)
		var size := 0
		while not stack.is_empty():
			var c: Vector2i = stack.pop_back()
			size += 1
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nb := c + Vector2i(dx, dy)
					if setp.has(nb):
						setp.erase(nb)
						stack.append(nb)
		if size >= 12:
			cnt += 1
	return cnt
