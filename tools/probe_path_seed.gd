extends Node
## Sonda conversiei "pista din cod -> curba editabila".
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePathSeed.tscn
##
## Ca SCENA, nu cu --script: pistele se construiesc in _ready si au nevoie de
## autoload-uri (vezi antetul probe_layout.gd).
##
## Ce garanteaza: cand o pista definita in cod (Okinawa, Alpii) isi
## materializeaza nodul "Path" din _code_points() — ce se intampla la prima
## bifare de Regenerate in editor — geometria NU se schimba cu nimic.
## Aceleasi puncte, acelasi Catmull-Rom, deci baked identic PE OCTET; orice
## abatere ar insemna ca fractiile masurate (parapeti, rape, hazarde) nu mai
## cad unde au fost tunate.

const TRACKS := [
	"res://scenes/tracks/Track08.tscn",
	"res://scenes/tracks/Track09.tscn",
]


func _ready() -> void:
	await get_tree().process_frame
	var failed := false
	for path in TRACKS:
		var scene := load(path) as PackedScene
		var track := scene.instantiate() as Track
		get_tree().root.add_child(track)
		await get_tree().process_frame

		var before := PackedVector3Array()
		for p in track.baked:
			before.append(p)

		track._ensure_path_from_code()
		if track.get_node_or_null("Path") == null:
			print("%s: PROBLEMA — nodul Path nu s-a creat" % path)
			failed = true
			track.queue_free()
			continue
		track.rebuild()

		var worst := 0.0
		if before.size() != track.baked.size():
			worst = INF
		else:
			for i in before.size():
				worst = maxf(worst, before[i].distance_to(track.baked[i]))
		print("%s: %d puncte coapte, abatere maxima dupa seed %.6f m %s" % [
			path, before.size(), worst,
			"" if worst == 0.0 else "— PROBLEMA"])
		if worst > 0.0:
			failed = true

		track.queue_free()
		await get_tree().process_frame

	print("VERDICT: %s" % ("PROBLEMA" if failed else "OK"))
	get_tree().quit(1 if failed else 0)
