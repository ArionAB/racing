extends SceneTree
## Sonda de COMPOZITIE: cat de plin e cadrul soferului, felie cu felie de pista.
##
## Exista fiindca „lumea pare goala" era pana acum o parere, iar parerile nu se
## pot compara intre doua build-uri. probe_decor numara triunghiuri si
## materiale — adica pretul; asta masoara ce primesti pe el.
##
## Metrica NU e numarul de piese: o stanca de 12 m si o pietricica de 1 m
## conteaza la fel intr-o numaratoare, dar nu si pe ecran. Se masoara
## ACOPERIREA UNGHIULARA — conul de vedere se imparte in coloane de 2°, si
## fiecare piesa marcheaza coloanele peste care se intinde silueta ei. Iese
## „ce procent din latimea cadrului are ceva in el", adica exact ce deosebeste
## panoul BEFORE (EMPTY) de AFTER (IMMERSIVE) din conceptul de referinta.
##
## Stanga si dreapta se raporteaza SEPARAT, si asta a fost descoperirea din
## #147: pe Dunele falezele stau pe exteriorul virajelor, deci media pe cadru
## ascundea ca o latura statea la 97% si cealalta la 85%, cu felii intregi sub
## 30%. O medie pe tot cadrul n-ar fi aratat niciodata problema.
##
## Ce NU e o problema si nu trebuie „reparat": feliile de 0% dintr-o rapa
## declarata. TrackDecor sare peste ele intentionat (`_allowed`: is_ravine),
## fiindca o prapastie cu decor in fata nu se mai citeste de departe.
##
##   godot --headless --path . --script res://tools/probe_midground.gd
##   ... -- --track=1

const SAMPLES := 40
const NEAR := 18.0
const FAR := 110.0
const HALF_FOV := 38.0
const COLS := 38          # o coloana = 2 grade
## Sub atat, piesa e prea joasa ca sa rupa linia orizontului de la 40 m+.
const MIN_H := 0.8

var _frames := 0
var _track: Node = null


func _process(_delta: float) -> bool:
	if _track == null:
		var idx := 1
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--track="):
				idx = int(a.trim_prefix("--track="))
		var path := "res://scenes/tracks/Track%02d.tscn" % idx
		if not ResourceLoader.exists(path):
			push_error("probe_midground: nu exista %s" % path)
			quit(1)
			return true
		print("=== %s ===" % path)
		_track = (load(path) as PackedScene).instantiate()
		root.add_child(_track)
		return false
	_frames += 1
	if _frames < 3:
		return false
	_measure()
	quit(0)
	return true


func _measure() -> void:
	var t: Node3D = _track
	var baked: PackedVector3Array = t.baked
	var n := baked.size()
	var pieces: Array[Dictionary] = []
	_collect(t, pieces)
	print("piese masurabile (h >= %.1f m): %d" % [MIN_H, pieces.size()])
	print("frac    stanga dreapta  harta coloanelor (. = gol)")

	var worst: Array[String] = []
	var sum_l := 0.0
	var sum_r := 0.0
	for s in SAMPLES:
		var frac := float(s) / float(SAMPLES)
		var i := int(frac * float(n)) % n
		var here := baked[i]
		var dir := baked[(i + 4) % n] - here
		dir.y = 0.0
		if dir.length_squared() < 1e-6:
			continue
		dir = dir.normalized()
		var eye := here - dir * 8.0 + Vector3.UP * 3.0
		var filled := []
		filled.resize(COLS)
		filled.fill(false)
		for p in pieces:
			var ctr: Vector3 = p["c"]
			var v := ctr - eye
			v.y = 0.0
			var d := v.length()
			if d < NEAR or d > FAR:
				continue
			# Unghiul semnat fata de directia de mers: + dreapta, - stanga.
			var right := dir.cross(Vector3.UP).normalized()
			var ang := rad_to_deg(atan2(v.dot(right), v.dot(dir)))
			var half := rad_to_deg(atan2(float(p["r"]), d))
			var a0 := ang - half
			var a1 := ang + half
			if a1 < -HALF_FOV or a0 > HALF_FOV:
				continue
			var c0 := int(floor((maxf(a0, -HALF_FOV) + HALF_FOV) / (2.0 * HALF_FOV) * COLS))
			var c1 := int(floor((minf(a1, HALF_FOV) + HALF_FOV) / (2.0 * HALF_FOV) * COLS))
			for c in range(maxi(c0, 0), mini(c1 + 1, COLS)):
				filled[c] = true
		var half_cols := COLS / 2
		var left := 0
		var right_n := 0
		var map := ""
		for c in COLS:
			if filled[c]:
				map += "#"
				if c < half_cols:
					left += 1
				else:
					right_n += 1
			else:
				map += "."
		var pl := float(left) / float(half_cols) * 100.0
		var pr := float(right_n) / float(COLS - half_cols) * 100.0
		sum_l += pl
		sum_r += pr
		print("%.3f   %3.0f%%   %3.0f%%   %s" % [frac, pl, pr, map])
		if minf(pl, pr) < 40.0:
			worst.append("%.3f (S %.0f%% / D %.0f%%)" % [frac, pl, pr])

	print("--- medie: stanga %.0f%%, dreapta %.0f%%" % [
		sum_l / float(SAMPLES), sum_r / float(SAMPLES)])
	print("--- felii cu o latura sub 40%% acoperire: %d" % worst.size())
	for w in worst:
		print("      %s" % w)


func _collect(node: Node, out: Array[Dictionary]) -> void:
	for c in node.get_children():
		if c.is_queued_for_deletion():
			continue
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var aabb := mi.global_transform * mi.get_aabb()
			if aabb.size.y >= MIN_H:
				out.append({"c": aabb.get_center(),
					"r": maxf(aabb.size.x, aabb.size.z) * 0.5})
		_collect(c, out)
