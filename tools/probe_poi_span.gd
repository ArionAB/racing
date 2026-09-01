extends Node
## CE INTERVAL DE TUR OCUPA FIECARE POI, masurat din pozitiile decorului.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePoiSpan.tscn -- --track=13
##
## De ce. Cifrele de frac din brief sunt INTENTII, scrise inainte de traseu.
## Traseul se muta dupa. Pe Cappadocia, brief-ul dadea orasul subteran la
## 0.66-0.82; masurat, e 0.658-0.727, iar o captura la 0.74 prinde canionul de
## IESIRE. Fractia adevarata se citeste din unde stau nodurile, nu din doc.
##
## Pentru fiecare grup din DecorManual raporteaza intervalul de fractii acoperit
## de prop-urile lui. Un tur e ciclic, deci grupul care trece peste linia de
## start (frac 0 = frac 1) se raporteaza ca interval infasurat.


func _ready() -> void:
	await get_tree().process_frame
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	if only < 0:
		push_error("ProbePoiSpan: cere --track=N")
		get_tree().quit(1)
		return

	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var decor := track.get_node_or_null("DecorManual")
	if decor == null:
		print("(fara DecorManual)")
		get_tree().quit(0)
		return

	print("=== %s ===" % GameState.track_label(only))
	for grp in decor.get_children():
		var fr: PackedFloat32Array = PackedFloat32Array()
		_collect(grp, r, n, fr)
		if fr.is_empty():
			continue
		var a := Array(fr)
		a.sort()
		# gaura cea mai mare intre fractii consecutive: intervalul real e
		# complementul ei (asa se prinde grupul care trece peste linia de start)
		var gap := 0.0
		var gi := 0
		for i in a.size():
			var d: float = (a[(i + 1) % a.size()] as float) - (a[i] as float)
			if i == a.size() - 1:
				d += 1.0
			if d > gap:
				gap = d
				gi = i
		var start: float = a[(gi + 1) % a.size()]
		var stop: float = a[gi]
		print("  %-28s %4d prop  frac %.3f -> %.3f%s"
			% [String(grp.name), fr.size(), start, stop,
			"  (peste linia de start)" if start > stop else ""])
	get_tree().quit(0)


func _collect(node: Node, r: TrackRoute, n: int,
		out: PackedFloat32Array) -> void:
	if node is Node3D and node != null:
		var p: Vector3 = (node as Node3D).global_position
		if p.length_squared() > 0.01:
			var best := 0
			var bd := 1e18
			for i in n:
				var d: float = (r.baked[i] as Vector3).distance_squared_to(p)
				if d < bd:
					bd = d
					best = i
			out.append(float(best) / float(n))
	for ch in node.get_children():
		_collect(ch, r, n, out)
