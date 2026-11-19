extends Node
## Garda decorului lovibil de pe marginea drumului (decor lovibil, valul 3): fisierele
## `res://scenes/tracks/roadside/TrackNN.tres` (`RoadsideSet`), asezate de `RoadsideProps`.
##
## Pe fiecare pista care are fisier, incarcata singura (fara cursa):
##   1. fiecare grup si-a asezat TOATE piesele — niciuna fara loc bun (mal, stanca, carosabil);
##   2. la 3 s, fara niciun contact: toate dorm si nicio piesa nu s-a miscat peste 5 cm
##      (stivele stau, nimic nu aluneca la vale, nimic nu e impins afara din alt colizor);
##   3. nicio piesa nu sta pe vreun carosabil (bucla sau scurtatura);
##   4. pista ramane sub plafonul de corpuri (`BumpProp.MAX_PER_TRACK`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRoadside.tscn -- --track=Track19
##   ... -- --all                 toate pistele cu fisier
##   ... -- --track=Track01 --sabotage=onroad   primul grup mutat PE drum   -> pica 1
##   ... -- --track=Track01 --sabotage=awake    o piesa trezita si impinsa   -> pica 2

var _fail: int = 0
var _sabotage: String = ""


func _check(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["OK " if ok else "PICAT", what])
	if not ok:
		_fail += 1


func _ready() -> void:
	var stems: Array[String] = []
	var all := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			var a := arg.trim_prefix("--track=")
			var idx := GameState.resolve_track_arg(a)
			if idx < 0:
				push_error("ProbeRoadside: pista invalida '%s'" % a)
				get_tree().quit(2)
				return
			stems.append(String(GameState.TRACK_SCENES[idx]).get_file().get_basename())
		elif arg == "--all":
			all = true
		elif arg.begins_with("--sabotage="):
			_sabotage = arg.trim_prefix("--sabotage=")
	if all:
		for scene in GameState.TRACK_SCENES:
			var stem := String(scene).get_file().get_basename()
			if ResourceLoader.exists(RoadsideProps.SET_DIR + stem + ".tres"):
				stems.append(stem)
	print("")
	print("=== DECOR LOVIBIL PE MARGINEA DRUMULUI: %d piste%s ===" % [stems.size(),
		"" if _sabotage.is_empty() else "  [sabotaj: %s]" % _sabotage])
	if stems.is_empty():
		_check(false, "nicio pista de verificat")
	await get_tree().process_frame
	for stem in stems:
		await _probe(stem)
	print("VERDICT: %s" % ("OK" if _fail == 0 else "PICAT (%d)" % _fail))
	get_tree().quit(0 if _fail == 0 else 1)


func _probe(stem: String) -> void:
	var path := "res://scenes/tracks/%s.tscn" % stem
	var track := (load(path) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().physics_frame
	var props := track.get_node_or_null(^"RoadsideProps") as RoadsideProps
	if props == null:
		_check(false, "%s: are fisier, dar pista nu l-a incarcat" % stem)
		track.queue_free()
		return
	if _sabotage == "onroad":
		# Acelasi fisier, cu primul grup tras PE carosabil: piesele lui n-au voie sa apara.
		var bad := props.data.duplicate(true) as RoadsideSet
		var g0: Dictionary = bad.groups[0].duplicate(true)
		g0["gap"] = -4.0
		bad.groups[0] = g0
		track.remove_child(props)
		props.free()
		props = RoadsideProps.new()
		props.name = "RoadsideProps"
		props.track = track
		props.data = bad
		track.add_child(props)
	await props.placed
	for k in 3:
		await get_tree().physics_frame
	var bodies: Array[BumpProp] = []
	var start: Dictionary = {}
	for c in props.get_children():
		if c is BumpProp:
			bodies.append(c as BumpProp)
			start[c] = (c as BumpProp).global_position
	if _sabotage == "awake" and not bodies.is_empty():
		bodies[0].sleeping = false
		bodies[0].linear_velocity = Vector3(3.0, 1.0, 0.0)
	for k in 180:
		await get_tree().physics_frame
	var want := 0
	var short: PackedStringArray = []
	for g: Dictionary in props.report:
		want += int(g["want"])
		if int(g["built"]) < int(g["want"]):
			short.append("%.4f %s %d/%d" % [float(g["frac"]), String(g["pattern"]),
				int(g["built"]), int(g["want"])])
	var awake := 0
	var moved := 0
	var on_road := 0
	for b in bodies:
		if not is_instance_valid(b):
			moved += 1
			continue
		if not b.sleeping:
			awake += 1
		if b.global_position.distance_to(start[b]) > 0.05:
			moved += 1
			var gi := int(b.get_meta(&"roadside_group", -1))
			print("    %s (grupul %d, %s la %.4f): mutata %.2f m" % [b.name, gi,
				String(props.report[gi]["pattern"]) if gi >= 0 else "?",
				float(props.report[gi]["frac"]) if gi >= 0 else -1.0,
				b.global_position.distance_to(start[b])])
		if props.on_any_road(b.global_position, 0.0):
			on_road += 1
	var total := get_tree().get_nodes_in_group(&"bump_props").size()
	print("%s: %d grupuri, %d piese din %d cerute; %d corpuri lovibile pe pista (plafon %d)" % [
		stem, props.report.size(), props.built, want, total, BumpProp.MAX_PER_TRACK])
	_check(short.is_empty() and props.built > 0,
		"%s: toate piesele au loc bun%s" % [stem,
		"" if short.is_empty() else " — lipsesc la: " + ", ".join(short)])
	_check(awake == 0 and moved == 0,
		"%s: la 3 s fara contact, %d treze, %d mutate peste 5 cm" % [stem, awake, moved])
	_check(on_road == 0, "%s: %d piese pe carosabil" % [stem, on_road])
	_check(total < BumpProp.MAX_PER_TRACK, "%s: sub plafonul de corpuri (%d)" % [stem, total])
	track.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
