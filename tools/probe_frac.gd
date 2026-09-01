extends Node
## UNDE E, PE TRASEU? Traduce pozitii de lume in fractii de tur, si invers.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFrac.tscn -- \
##       --track=13 --at=-244.07,13.65,-168.32
##   ... --track=13 --frac=0.74
##
## De ce exista. Brief-ul Cappadocia spunea ca orasul subteran e la frac
## 0.66-0.82. Sectiunea reala e 0.658-0.727. O captura facuta la 0.74, adica
## exact "in mijlocul" intervalului din brief, prindea canionul de IESIRE — si
## era gata sa plece o runda intreaga de lucru impotriva pozei gresite.
##
## Brief-ul e scris inainte de traseu; traseul se muta. Cifra din brief e o
## intentie, pozitia nodului din .tscn e adevarul. Cand cele doua nu sunt de
## acord, asta le impaca.


func _ready() -> void:
	await get_tree().process_frame
	var only := -1
	var at := Vector3.INF
	var frac := -1.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--at="):
			var p := arg.trim_prefix("--at=").split(",")
			if p.size() == 3:
				at = Vector3(float(p[0]), float(p[1]), float(p[2]))
		elif arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
	if only < 0:
		push_error("ProbeFrac: cere --track=N")
		get_tree().quit(1)
		return

	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	print("=== %s · %d puncte ===" % [GameState.track_label(only), n])

	if frac >= 0.0:
		var i := int(frac * float(n)) % n
		var p: Vector3 = r.baked[i]
		print("frac %.3f -> (%.2f, %.2f, %.2f)" % [frac, p.x, p.y, p.z])

	if at != Vector3.INF:
		var best := -1
		var bd := 1e18
		for i in n:
			var d: float = (r.baked[i] as Vector3).distance_squared_to(at)
			if d < bd:
				bd = d
				best = i
		var p: Vector3 = r.baked[best]
		print("(%.2f, %.2f, %.2f) -> frac %.3f  (la %.1f m de ax, cota drum %.1f)"
			% [at.x, at.y, at.z, float(best) / float(n), sqrt(bd), p.y])

	get_tree().quit(0)
