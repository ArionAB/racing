extends Node
## Cat de mult citeste zidul ca un PIEPTENE de fini, si nu ca o fata continua.
##
## Nu masoara rostul (runda 8 l-a dus la 0) si nici saltul de yaw (runda 9c l-a
## dus sub prag). Masoara ce se VEDE: pentru fiecare piesa de creasta, cat din
## fata ei EXTERIOARA e acoperita de vecina de dinainte. Daca fata exterioara e
## descoperita pe toata lungimea, dar capetele piesei ies in afara conturului
## vecinei, ochiul citeste fiecare piesa separat — fin — oricat de lipite ar fi
## capetele pe axa lor.
##
## Cifra decisiva: PROIECTIA capatului piesei pe normala liniei. Cand doua piese
## consecutive stau pe aceeasi coarda, capetele lor coincid si proiectia e 0.
## Cand piesa k+1 e rotita fata de k, capatul comun se despica si unul din
## colturi iese cu (L/2)*sin(dtheta) in afara fetei celeilalte: ala e PRAGUL
## vizibil, si el e ce face umbra verticala dintre doi fini.
const TRACK := "res://scenes/tracks/Track15.tscn"
const THICK := 0.86

var _track: Track


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var zone := _track.get_node_or_null("DecorManual/ZoneG_Serpentine")
	# Se iau doar piesele de CREASTA (cursul 0, cu coliziune hull) — cursurile
	# de sub ele au acelasi centru si acelasi yaw, deci nu adauga informatie.
	var pieces: Array = []
	for c in zone.get_children():
		var nm := str(c.name)
		if not nm.begins_with("zidSprijin") or nm.ends_with("_col"):
			continue
		var t: Node3D = c as Node3D
		var meta: String = str(t.get_meta("coliziune")) if t.has_meta("coliziune") else "hull"
		if meta != "hull":
			continue
		pieces.append({
			"pos": t.global_position,
			"x": t.global_transform.basis.x.normalized(),
			"len": t.global_transform.basis.x.length() * _model_len(t),
		})
	print("; piese de creasta: %d" % pieces.size())
	# Ordoneaza-le pe lantul lor: vecina = cea mai apropiata care nu s-a folosit.
	var prags: Array[float] = []
	var goluri: Array[float] = []
	for k in range(pieces.size() - 1):
		var a: Dictionary = pieces[k]
		var b: Dictionary = pieces[k + 1]
		var d: Vector3 = b["pos"] - a["pos"]
		d.y = 0.0
		if d.length() > 8.0:
			continue          # rupere de lant (salt de mal)
		# Capatul comun: coada lui a, capul lui b.
		var ea: Vector3 = a["pos"] + a["x"] * (float(a["len"]) * 0.5)
		var eb: Vector3 = b["pos"] - b["x"] * (float(b["len"]) * 0.5)
		# Normala exterioara a piesei a (perpendiculara pe axa ei, in plan).
		var na := Vector3(a["x"].z, 0.0, -a["x"].x).normalized()
		# Cat iese capatul lui b in afara/inauntru fata de FATA lui a.
		var off: float = absf((eb - ea).dot(na))
		prags.append(off)
		goluri.append(Vector3(eb.x - ea.x, 0.0, eb.z - ea.z).length())
	prags.sort()
	goluri.sort()
	_rap("prag lateral la imbinare (m)", prags)
	_rap("distanta cap-coada (m)", goluri)
	var peste := 0
	for p in prags:
		if p > 0.15:
			peste += 1
	print("; imbinari cu prag peste 0,15 m (vizibil ca fin): %d din %d" % [peste, prags.size()])
	get_tree().quit(0)


func _model_len(t: Node3D) -> float:
	var sc := t.scene_file_path
	if sc.contains("inca_wall_b"):
		return 6.0
	if sc.contains("inca_wall_a"):
		return 4.0
	return 2.0


func _rap(tit: String, v: Array[float]) -> void:
	if v.is_empty():
		print("; %s: niciun esantion" % tit)
		return
	print("; %s: median %.3f  p75 %.3f  p90 %.3f  max %.3f" % [
		tit, v[v.size() / 2], v[3 * v.size() / 4], v[int(0.9 * float(v.size()))],
		v[v.size() - 1]])
