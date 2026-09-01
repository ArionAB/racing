extends Node
## CAT DE LATA E FANTA? Plimba gabaritul masinii pe TOATA latimea benzii si
## deseneaza harta a ce e liber, fractie cu fractie.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLaneGap.tscn -- --track=6
##   ... --from=0.02 --to=0.04 --step=0.002   (implicit: toata pista la 0.005,
##                                              tiparind doar feliile blocate)
##
## Complement la `ProbeLaneClear`, si a fost nevoie de el fiindca aceea testeaza
## doar TREI fire (axa si ±1/3 din semilatime). Pe un blocaj proiectat sa lase o
## fanta pe margine — teancurile de oale din piata Goreme, Cappadocia POI A —
## toate cele trei fire cad in zid, deci `ProbeLaneClear` iese rosu si peste un
## drum care CHIAR se poate trece. Aici se vede diferenta dintre „inchis" si
## „ingust": la frac 0.030 harta arata zid de la -9.0 la +5.6 si 3.50 m de
## pozitii de centru libere in dreapta.
##
## Cifra raportata e in pozitii de CENTRU al masinii, nu in asfalt liber: la o
## caroserie de 2.2 m, „gol maxim 3.50 m" inseamna 5.7 m de drum descoperit.
##
## Corpurile de rulare (carosabil, umeri, tablier, rampe) se ignora dupa nume,
## ca in `ProbeLaneClear`.

const CAR_SIZE := Vector3(2.2, 1.4, 4.2)
const LIFT: float = 1.0

func _ready() -> void:
	await get_tree().process_frame
	var only := -1
	var f0 := -1.0
	var f1 := -1.0
	var step := 0.002
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--from="):
			f0 = float(arg.trim_prefix("--from="))
		elif arg.begins_with("--to="):
			f1 = float(arg.trim_prefix("--to="))
		elif arg.begins_with("--step="):
			step = float(arg.trim_prefix("--step="))
	if only < 0:
		push_error("ProbeLaneGap: cere --track=N")
		get_tree().quit(1)
		return
	if f0 >= 0.0 and f1 < 0.0:
		f1 = f0
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := track.get_world_3d().direct_space_state
	var n := track.baked.size()
	var shape := BoxShape3D.new()
	shape.size = CAR_SIZE
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_areas = false

	var fracs: Array[float] = []
	if f0 >= 0.0:
		var f := f0
		while f <= f1 + 1e-6:
			fracs.append(f)
			f += step
	else:
		# Fara interval: toata pista la pas de 0.005, dar se tiparesc doar
		# feliile care CHIAR au ceva pe banda — altfel ies 200 de randuri goale.
		var f := 0.0
		while f < 1.0:
			fracs.append(f)
			f += 0.005
	for frac in fracs:
		var i := int(frac * float(n)) % n
		var p: Vector3 = track.baked[i]
		var fwd := (track.baked[(i + 1) % n] - p).normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var half: float = track.width_at_index(i)
		var line := ""
		var free_run := 0.0
		var best := 0.0
		var best_c := 0.0
		var run_start := 0.0
		var lat := -half
		while lat <= half + 0.001:
			var basis := Basis(side, Vector3.UP, -fwd)
			q.transform = Transform3D(basis, p + Vector3.UP * LIFT + side * lat)
			var res := space.intersect_shape(q, 8)
			var blocked := false
			for hit in res:
				var body := hit.get("collider") as Node
				if body == null:
					continue
				var nm := String(body.name)
				if nm.begins_with("Road") or nm.begins_with("Shoulders") or nm.begins_with("Branch") or nm == "Ramp" or nm.begins_with("Channel") or nm.begins_with("Flyoff") or nm.begins_with("Tunnel") or nm.begins_with("Hummock"):
					continue
				blocked = true
			if blocked:
				line += "#"
				free_run = 0.0
			else:
				if free_run == 0.0:
					run_start = lat
				line += "."
				free_run += 0.25
				if free_run > best:
					best = free_run
					best_c = (run_start + lat) * 0.5
			lat += 0.25
		# In baleiajul pe toata pista se tiparesc doar feliile STRAMTATE de
		# ceva: altfel ies 200 de randuri in care scrie ca drumul e liber. Cu
		# interval explicit (`--from`) se tipareste tot, ca sa se vada si
		# martorii liberi de dinainte si de dupa blocaj.
		if f0 < 0.0 and best >= 2.0 * half - 0.6:
			continue
		print("frac %.3f half=%.2f  gol maxim %.2f m centrat la lat %+.2f" % [frac, half, best, best_c])
		print("   [-%.1f .. +%.1f] %s" % [half, half, line])
	get_tree().quit(0)
