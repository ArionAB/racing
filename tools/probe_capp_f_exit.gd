extends Node
## Cat de departe e gura de iesire fata de camera, pe fractiile de captura.
##
## Intrebarea concreta: la frac 0.74 lumina de afara ocupa 1.8x luminanta
## peretelui apropiat. E defect (o gaura in tavan) sau e chiar iesirea salii,
## vazuta legitim din interior? Raspunsul schimba complet ce e de facut.


func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(13)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var at := func(f: float) -> Vector3:
		return r.baked[int(round(f * float(n))) % n]
	# Sala 2 se termina la 0.753 (vezi gen_decor_capp_f.gd).
	var exit_pos: Vector3 = at.call(0.753)
	for f: float in [0.68, 0.72, 0.74]:
		var p: Vector3 = at.call(f)
		print("frac %.3f -> pana la gura (0.753): %.1f m" % [f, p.distance_to(exit_pos)])
	get_tree().quit()
