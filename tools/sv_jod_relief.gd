extends Node
## Sonda de relief pentru Track17 (Jodhpur): kickerul Devkund (G2) si
## fantana in trepte (C). Masoara pe SUPRAFATA RANDATA (_terrain_mesh_y), nu pe
## camp: pragurile de pe marginea asfaltului vin din coarda grilei de 7.9 m.
##
##   godot --headless --path . res://tools/SvJodRelief.tscn
##
## Tipareste: canalul rezolvat (gol, buze, apa), apa din rape (celule, cota),
## pragul maxim al terenului peste asfalt pe fantana si pe Devkund, distanta
## de la marginea asfaltului pana la piciorul si buza peretelui exterior,
## profil transversal pe fantana si zonele de repunere / camera.

const SCENE := "res://scenes/tracks/Track17.tscn"

var tr: Track
var n: int


func _ready() -> void:
	var ps := load(SCENE) as PackedScene
	tr = ps.instantiate() as Track
	add_child(tr)
	for k in 4:
		await get_tree().process_frame
	n = tr.baked.size()
	_channels()
	_water()
	_prag(0.125, 0.275, "fantana")
	_prag(0.84, 0.92, "devkund")
	_walls()
	_zones()
	get_tree().quit(0)


func _fl(i: int) -> float:
	var d: PackedFloat32Array = tr.get("_dists")
	return d[i] / d[n]


func _channels() -> void:
	print("\n--- canale ---")
	for ch in tr.get("_channels"):
		var o: Vector3 = ch["origin"]
		var a: Vector3 = ch["near_point"]
		var b: Vector3 = ch["far_point"]
		print("  %s: idx %.4f (lung %.4f) gol %.1f m (cerut %.1f) | buza lansare (%.1f, %+.2f, %.1f) idx %.4f | buza aterizare (%.1f, %+.2f, %.1f) idx %.4f | apa y %+.2f | jump %s" % [
			ch["label"], float(ch["index"]) / n, _fl(ch["index"]), ch["gap"], ch["gap_requested"],
			a.x, a.y, a.z, float(ch["near"]) / n, b.x, b.y, b.z, float(ch["far"]) / n,
			o.y - float(ch.get("water_y_drop", 0.0)), str(ch["jump"])])


func _water() -> void:
	print("\n--- apa din rape ---")
	var wet: Dictionary = tr.get("_ravine_wet")
	var by_y := {}
	for k in wet:
		var y: float = wet[k]
		by_y[y] = int(by_y.get(y, 0)) + 1
	for y in by_y:
		print("  cota %+.2f: %d celule" % [y, by_y[y]])
	for c in tr.get_children():
		if c is RespawnZone:
			print("  RespawnZone %s: %d cutii, backoff %.0f" % [c.name, c.get_child_count(), (c as RespawnZone).backoff_m])


## Pragul maxim al TERENULUI RANDAT peste fata asfaltului, pe latime, pe un
## interval de fractii (pe index).
func _prag(f0: float, f1: float, tag: String) -> void:
	var worst := -INF
	var worst_at := ""
	var edge_worst := -INF
	var edge_at := ""
	for i in range(int(f0 * n), int(f1 * n)):
		var p: Vector3 = tr.baked[i]
		var s: Vector3 = tr.call("_side_at", i)
		var hw: float = tr.width_at_index(i)
		for k in range(-10, 11):
			var off := hw * float(k) / 10.0
			var y: float = tr.call("_terrain_mesh_y", p.x + s.x * off, p.z + s.z * off)
			if y - p.y > worst:
				worst = y - p.y
				worst_at = "idx %.3f off %+.1f" % [float(i) / n, off]
		for side in [-1.0, 1.0]:
			for extra in [0.5, 1.0]:
				var off: float = side * (hw + extra)
				var y: float = tr.call("_terrain_mesh_y", p.x + s.x * off, p.z + s.z * off)
				if y - p.y > edge_worst:
					edge_worst = y - p.y
					edge_at = "idx %.3f off %+.1f" % [float(i) / n, off]
	print("\n--- %s %.3f-%.3f: teren peste asfalt max %+.2f m (%s); la 0.5-1 m in afara asfaltului max %+.2f m (%s)" % [
		tag, f0, f1, worst, worst_at, edge_worst, edge_at])


## Peretele exterior al fantanii (dreapta): la ce distanta de marginea
## asfaltului terenul trece de +1 m si de 90% din inaltimea pana la buza.
func _walls() -> void:
	print("\n--- fantana: profil transversal pe suprafata randata (y teren - y drum), st = negativ ---")
	var offs := [-20.0, -14.0, -10.0, -7.0, -5.5, -4.5, 4.5, 5.5, 7.0, 10.0, 14.0, 20.0, 25.0, 30.0]
	var hdr := "                              "
	for o in offs:
		hdr += "%6.1f" % o
	print(hdr + "   perete dr: +1m / 90% (de la margine)")
	for f in [0.136, 0.145, 0.155, 0.17, 0.185, 0.195, 0.198, 0.202, 0.21, 0.23, 0.245, 0.255, 0.262]:
		var i := int(f * n)
		var p: Vector3 = tr.baked[i]
		var s: Vector3 = tr.call("_side_at", i)
		var hw: float = tr.width_at_index(i)
		var out := "  idx %.3f y%+5.1f hw %.1f " % [f, p.y, hw]
		for o in offs:
			var y: float = tr.call("_terrain_mesh_y", p.x + s.x * o, p.z + s.z * o)
			out += "%+6.1f" % (y - p.y)
		var d1 := -1.0
		var d9 := -1.0
		var rise := 0.0 - p.y
		var d := 0.0
		while d < 45.0:
			var o2 := hw + d
			var y2: float = tr.call("_terrain_mesh_y", p.x + s.x * o2, p.z + s.z * o2)
			if d1 < 0.0 and y2 - p.y > 1.0:
				d1 = d
			if d9 < 0.0 and rise > 1.0 and y2 - p.y > 0.9 * rise:
				d9 = d
			d += 0.5
		out += "   %5.1f / %5.1f" % [d1, d9]
		print(out)


func _zones() -> void:
	print("\n--- zone de camera ---")
	for c in _all(tr):
		if c is CameraZone:
			var z := c as CameraZone
			print("  %s: frac %.3f-%.3f height %.1f look %.2f fov+%.1f ceiling %.1f" % [
				z.name, z.frac_from, z.frac_to, z.height, z.look_height, z.fov_bonus, z.ceiling])


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in node.get_children():
		out.append(c)
		out.append_array(_all(c))
	return out
