extends Node
## Garda pentru peticele de ceata joasa (MistPatch, POI D Serengeti):
## masoara pentru FIECARE panza din FIECARE petic
##   - raportul latime/inaltime al gabaritului ei in LUME (cere >= 4),
##   - cota marginii de sus fata de teren (cere <= 2.5 m).
## Necesara fiindca probe_manual testeaza doar ORIGINEA nodului fata de un
## raycast: un petic cu originea pe sol trece garda si cu doua treimi din el
## suspendate printre coroane (memoria `garzile-se-uitau-doar-la-carosabil`).
##   godot --headless --fixed-fps 60 --path . --script res://tools/probe_mist.gd -- --track=7

const RATIO_MIN := 4.0
const TOP_MAX := 2.5




func _ready() -> void:
	var idx := 7
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			idx = int(a.trim_prefix("--track="))
	var path: String = GameState.TRACK_SCENES[idx]
	var tr := (load(path) as PackedScene).instantiate() as Track
	get_tree().root.add_child(tr)
	await get_tree().process_frame
	await get_tree().process_frame
	var patches: Array[Node] = []
	_collect(tr, patches)
	if patches.size() > 0:
		print("primul: %s" % str((patches[0] as Node).get_path()))
	print("petice MistPatch: %d" % patches.size())
	var bad_ratio := 0
	var bad_top := 0
	var worst_ratio := INF
	var worst_top := -INF
	var n_quads := 0
	for node in patches:
		var mp := node as MistPatch
		var gx := mp.transform
		# Scena Track14 nu se poate adauga in arbore in afara unei curse, deci
		# peticele nu-si construiesc MultiMesh-ul. Reconstruim panzele din
		# ACEEASI functie pe care o foloseste `_rebuild` (MistPatch.quad_transform),
		# ca sa masuram geometria desenata, nu o reimplementare a ei.
		var rng := RandomNumberGenerator.new()
		rng.seed = mp.seed
		var tmax := deg_to_rad(mp.tilt_deg)
		for i in mp.count:
			n_quads += 1
			var t: Transform3D = gx * MistPatch.quad_transform(
				rng, mp.footprint, mp.size, mp.height, tmax)
			rng.randf_range(0.7, 1.0) # aceeasi consumare ca in _rebuild (alpha)
			var lo := Vector3(INF, INF, INF)
			var hi := Vector3(-INF, -INF, -INF)
			for sx in [-0.5, 0.5]:
				for sy in [-0.5, 0.5]:
					var w: Vector3 = t * Vector3(sx, sy, 0.0)
					lo = lo.min(w)
					hi = hi.max(w)
			var h: float = maxf(hi.y - lo.y, 0.001)
			var w_span: float = maxf(hi.x - lo.x, hi.z - lo.z)
			var ratio: float = w_span / h
			worst_ratio = minf(worst_ratio, ratio)
			if ratio < RATIO_MIN:
				bad_ratio += 1
				if bad_ratio <= 5:
					print("  ! %s[%d]: raport %.2f (latime %.1f, inaltime %.1f)"
						% [mp.name, i, ratio, w_span, h])
			# Cota de referinta e ORIGINEA peticului: generatorul o pune pe
			# solul real prin raycast, iar probe_manual verifica separat ca
			# originile nu plutesc. Aici masuram cat URCA panza peste ea.
			var top := hi.y - gx.origin.y
			worst_top = maxf(worst_top, top)
			if top > TOP_MAX:
				bad_top += 1
				if bad_top <= 5:
					print("  ! %s[%d]: y_top - origine = %.2f m" % [mp.name, i, top])
	print("panze: %d" % n_quads)
	print("raport minim: %.2f (cere >= %.1f) — sub prag: %d" % [worst_ratio, RATIO_MIN, bad_ratio])
	print("y_top-teren maxim: %.2f m (cere <= %.1f) — peste prag: %d" % [worst_top, TOP_MAX, bad_top])
	if bad_ratio == 0 and bad_top == 0:
		print("VERDICT OK")
		get_tree().quit(0)
	else:
		print("VERDICT ESEC")
		get_tree().quit(1)


func _collect(n: Node, out: Array[Node]) -> void:
	if n is MistPatch:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)
