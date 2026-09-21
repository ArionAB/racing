extends Node
## Sonda ad-hoc (Mitre Peak, Track16): scrie ground_y pe o grila de 10 m si
## punctele coapte cu fractia lor in CSV-uri, ca sa fie desenate cu PIL
## (tools/fiord_varf_map.py). Doar citire din pista; scrie in --out=DIR.
const TRACK := "res://scenes/tracks/Track16.tscn"


func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4:
		await get_tree().process_frame
	var out_dir := "user://"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	var sea_y: float = t._sampler.mean_road_y() + t.custom_sea_level_offset
	var lo := Vector3(INF, 0, INF)
	var hi := Vector3(-INF, 0, -INF)
	for p in t.baked:
		lo = lo.min(p)
		hi = hi.max(p)
	lo -= Vector3(320, 0, 320)
	hi += Vector3(320, 0, 320)
	var cell := 10.0
	var f := FileAccess.open(out_dir.path_join("grid.csv"), FileAccess.WRITE)
	f.store_line("# sea_y=%.2f x0=%.0f z0=%.0f cell=%.0f" % [sea_y, lo.x, lo.z, cell])
	var z := lo.z
	while z <= hi.z:
		var row := PackedStringArray()
		var x := lo.x
		while x <= hi.x:
			row.append("%.1f" % t._sampler.ground_y(x, z))
			x += cell
		f.store_line(",".join(row))
		z += cell
	f.close()
	var g := FileAccess.open(out_dir.path_join("baked.csv"), FileAccess.WRITE)
	var n := t.baked.size()
	for i in n:
		var p: Vector3 = t.baked[i]
		g.store_line("%.4f,%.2f,%.2f,%.2f" % [float(i) / float(n), p.x, p.y, p.z])
	g.close()
	print("scris grid+baked in %s (sea_y=%.2f, n=%d)" % [out_dir, sea_y, n])
	get_tree().quit(0)
