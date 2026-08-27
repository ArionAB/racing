extends Node
## Unde cade linia de vedere pe hero. Camera de cursa la frac F: ochiul, si
## unghiul sub care se vede coama / talpa fiecarei stive.
const TRACK := "res://scenes/tracks/Track12.tscn"
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 4: await get_tree().physics_frame
	var sampler = track._sampler
	var path = TrackScenography._Path.new(sampler)
	var dm := track.get_node("DecorManual")
	var sec := dm.get_node("4) Cornisa Hongya Dong")
	# ochiul: ~2.2 m peste sosea (ChaseCamera sta in spate si sus, dar unghiul
	# de 63° in jos se masoara de la cota ochiului)
	for f in [0.28, 0.30, 0.33]:
		var st = path.at(path.total * f)
		var road: Vector3 = st["pos"]
		var eye := Vector3(road.x, road.y + 2.2, road.z)
		print("--- frac %.2f  ochi_y=%.1f ---" % [f, eye.y])
		var shown := 0
		for piece in sec.get_children():
			var n3 := piece as Node3D
			if n3 == null or not String(n3.name).begins_with("hongya_hero"): continue
			var d := Vector2(n3.global_position.x - eye.x, n3.global_position.z - eye.z).length()
			if d > 70.0: continue
			var top: float = n3.global_position.y + 47.74
			var bot: float = n3.global_position.y
			# unghi sub orizontala (pozitiv = sub ochi)
			var a_top := rad_to_deg(atan2(eye.y - top, d))
			var a_bot := rad_to_deg(atan2(eye.y - bot, d))
			shown += 1
			if shown <= 4:
				print("  %-18s d=%5.1f  coama %+6.1f m (%+5.1f°)  talpa %+6.1f m (%+5.1f°)" % [
					n3.name, d, top - eye.y, -a_top, bot - eye.y, -a_bot])
		print("  (camera vede intre +5° si -63°)")
	get_tree().quit(0)
