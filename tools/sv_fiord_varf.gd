extends Node
## Sonda ad-hoc (Mitre Peak, Track16): harta ASCII a APEI (ground_y < sea_y)
## in jurul buclei, cota terenului pe raza de la cateva puncte ale soselei spre
## un centru dat, si cota maxima reala a domului. Doar citire.
##   godot --headless --path . res://tools/SvFiordVarf.tscn -- --peak=x,z [--r=55]
const TRACK := "res://scenes/tracks/Track16.tscn"
var _t: Track


func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	for i in 4:
		await get_tree().process_frame
	var peak := Vector2(-311.13, -64.8)
	var rad := 55.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--peak="):
			var s := a.trim_prefix("--peak=").split(",")
			peak = Vector2(float(s[0]), float(s[1]))
		elif a.begins_with("--r="):
			rad = float(a.trim_prefix("--r="))
	var sea_y: float = _t._sampler.mean_road_y() + _t.custom_sea_level_offset
	print("mean_road_y=%.2f sea_y=%.2f" % [_t._sampler.mean_road_y(), sea_y])
	var n := _t.baked.size()
	# Harta: celule de 20 m, x pe coloane, z pe randuri. '~' apa, '.' uscat,
	# '#' sosea (< 8 m de un punct copt), 'M' > sea_y + 40 (masiv), '^' > 80.
	var lo := Vector3(INF, 0, INF)
	var hi := Vector3(-INF, 0, -INF)
	for p in _t.baked:
		lo = lo.min(p)
		hi = hi.max(p)
	lo -= Vector3(260, 0, 260)
	hi += Vector3(260, 0, 260)
	var cell := 20.0
	print("harta %d..%d x %d..%d (celula %.0f m)" % [lo.x, hi.x, lo.z, hi.z, cell])
	var z := lo.z
	while z <= hi.z:
		var line := "%6.0f " % z
		var x := lo.x
		while x <= hi.x:
			var ch := "."
			var y := _t._sampler.ground_y(x, z)
			var dmin := INF
			for i in range(0, n, 3):
				var q: Vector3 = _t.baked[i]
				dmin = minf(dmin, Vector2(q.x - x, q.z - z).length())
			if Vector2(x - peak.x, z - peak.y).length() < 6.0:
				ch = "X"
			elif dmin < 8.0:
				ch = "#"
			elif y > 80.0:
				ch = "^"
			elif y > sea_y + 40.0:
				ch = "M"
			elif y < sea_y:
				ch = "~"
			line += ch
			x += cell
		print(line)
		z += cell
	# Cota maxima reala a domului si baza in apa: esantion pe disc.
	var ymax := -INF
	var at := Vector2.ZERO
	var wet := 0
	var tot := 0
	var rr := -rad
	while rr <= rad:
		var cc := -rad
		while cc <= rad:
			if Vector2(rr, cc).length() <= rad:
				var y := _t._sampler.ground_y(peak.x + rr, peak.y + cc)
				tot += 1
				if y < sea_y:
					wet += 1
				if y > ymax:
					ymax = y
					at = Vector2(peak.x + rr, peak.y + cc)
			cc += 4.0
		rr += 4.0
	print("dom la (%.1f, %.1f) r=%.0f: ymax=%.1f la (%.1f, %.1f); %d/%d celule sub sea_y"
		% [peak.x, peak.y, rad, ymax, at.x, at.y, wet, tot])
	# Profil pe raza de la 3 fractii spre centru.
	for f: float in [0.02, 0.17, 0.63, 0.70]:
		var i := int(round(f * float(n))) % n
		var p: Vector3 = _t.baked[i]
		var dir := (peak - Vector2(p.x, p.z))
		var dist := dir.length()
		dir = dir.normalized()
		var s := "frac %.2f (drum y=%.1f, d=%.0f): " % [f, p.y, dist]
		var d := 10.0
		while d <= dist + rad:
			var y := _t._sampler.ground_y(p.x + dir.x * d, p.z + dir.y * d)
			s += "%.0f:%.0f " % [d, y]
			d += 10.0
		print(s)
	get_tree().quit(0)
