extends Node
## Sonda ad-hoc, de folosinta unica: pozitia/orientarea/latimea la portalul de
## est al tunelului Homer (frac 0.612, brief §2 POI E) si la portalul de vest
## (frac 0.690), plus pozitiile celor 3 nise (37/74/111 m dupa linia de
## oprire). Doar citire — nu construieste, nu scrie nimic.
const TRACK := "res://scenes/tracks/Track16.tscn"
const STOP_FRAC := 0.612
const WEST_FRAC := 0.690
var _t: Track

func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	var route := _t.routes[0]
	var n := _t.baked.size()
	print("baked n=%d  total_len=%.1f" % [n, _t.curve.get_baked_length()])

	for label in [["EST (linie oprire)", STOP_FRAC], ["VEST (iesire tunel)", WEST_FRAC]]:
		var frac: float = label[1]
		var idx := int(round(frac * float(n))) % n
		var p: Vector3 = _t.baked[idx]
		var dir: Vector3 = (_t.baked[route.wrap_index(idx + 1)] - p).normalized()
		var side: Vector3 = dir.cross(Vector3.UP).normalized()
		var hw := _t.width_at_index(idx)
		var yaw := atan2(dir.x, dir.z)
		print("\n--- %s (frac=%.4f idx=%d) ---" % [label[0], frac, idx])
		print("  pos=(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z])
		print("  dir=(%.3f, %.3f, %.3f)  side=(%.3f, %.3f, %.3f)  half_width=%.2f"
			% [dir.x, dir.y, dir.z, side.x, side.y, side.z, hw])
		print("  yaw_y_rad=%.4f (deg=%.1f)" % [yaw, rad_to_deg(yaw)])
		# Basis care aliniaza -Z local cu `dir` (looking_at implicit).
		var basis := Basis.looking_at(dir, Vector3.UP)
		print("  looking_at(dir) -> local -Z e dir? verificare: basis*(0,0,-1)=%s (ar trebui ~= dir=%s)"
			% [basis * Vector3(0, 0, -1), dir])
		print("  basis_x=(%.4f,%.4f,%.4f) basis_y=(%.4f,%.4f,%.4f) basis_z=(%.4f,%.4f,%.4f)"
			% [basis.x.x, basis.x.y, basis.x.z, basis.y.x, basis.y.y, basis.y.z,
				basis.z.x, basis.z.y, basis.z.z])
		# Vrem local +Z = dir (TunnelSignalHazard: ai_decision_point() e la
		# local (0,0,-AI_STOP_BACK_M), adica INAINTEA liniei pe partea de
		# apropiere -- deci +Z e spre tunel). Basis.looking_at da -Z = dir, deci
		# rotim 180 grade in plus in jurul lui Y.
		var basis2 := Basis.looking_at(-dir, Vector3.UP)
		print("  basis PENTRU +Z=dir (rotit 180): local_z=%s (ar trebui ~= dir=%s)"
			% [basis2 * Vector3(0, 0, 1), dir])
		print("  basis2_x=(%.4f,%.4f,%.4f) basis2_y=(%.4f,%.4f,%.4f) basis2_z=(%.4f,%.4f,%.4f)"
			% [basis2.x.x, basis2.x.y, basis2.x.z, basis2.y.x, basis2.y.y, basis2.y.z,
				basis2.z.x, basis2.z.y, basis2.z.z])
		var t2 := Transform3D(basis2, p)
		print("  TRANSFORM3D pentru .tscn: Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)"
			% [basis2.x.x, basis2.x.y, basis2.x.z, basis2.y.x, basis2.y.y, basis2.y.z,
				basis2.z.x, basis2.z.y, basis2.z.z, p.x, p.y, p.z])

	print("\n--- nise (45/82/119 m dupa linia de oprire, pe DREAPTA soselei) ---")
	var stop_idx := int(round(STOP_FRAC * float(n))) % n
	var stop_p: Vector3 = _t.baked[stop_idx]
	var bake_interval: float = _t.curve.bake_interval
	const NICHE_WIDTH_M := 2.5
	const NICHE_DEPTH_M := 4.0
	# Buffer intre marginea nominala a soselei (hw) si INCEPUTUL cutiei nisei:
	# banda de coridor (0.657 * hw) plus jumatate din latimea unei masini late
	# (~1.3m) ajunge aproape de hw insusi -- fara buffer, cutia nisei devine
	# perete in calea traficului normal, nu refugiu optional. 1.6m clearance.
	const NICHE_CLEARANCE_M := 1.6
	for dist in [45.0, 82.0, 119.0]:
		var steps := int(round(dist / bake_interval))
		var idx := route.wrap_index(stop_idx + steps)
		var p: Vector3 = _t.baked[idx]
		var dir: Vector3 = (_t.baked[route.wrap_index(idx + 1)] - p).normalized()
		var side: Vector3 = dir.cross(Vector3.UP).normalized()
		var hw := _t.width_at_index(idx)
		var frac := _t.frac_at(idx)
		var yaw := atan2(dir.x, dir.z)
		# Centrul cutiei nisei: dincolo de hw + clearance, apoi jumatate din adancime.
		var floor_center := p + side * (hw + NICHE_CLEARANCE_M + NICHE_DEPTH_M * 0.5)
		print("  dist=%.0fm frac=%.4f pos=(%.2f,%.2f,%.2f) side=(%.2f,%.2f,%.2f) half_width=%.2f  yaw_deg=%.2f  floor_center=(%.2f,%.2f,%.2f)"
			% [dist, frac, p.x, p.y, p.z, side.x, side.y, side.z, hw, rad_to_deg(yaw),
				floor_center.x, floor_center.y, floor_center.z])

	print("\n--- scanare fina latime intre linia de oprire si +170m ---")
	var d := 0.0
	while d <= 170.0:
		var steps2 := int(round(d / bake_interval))
		var idx2 := route.wrap_index(stop_idx + steps2)
		print("  dist=%6.1fm  half_width=%.2f  frac=%.4f" % [d, _t.width_at_index(idx2), _t.frac_at(idx2)])
		d += 5.0

	# Distanta reala pe drum (nu pe frac) intre linia de oprire si portalul de
	# vest, mergand pas cu pas pe indecsi (nu presupunand bake_interval*steps).
	var west_idx := int(round(WEST_FRAC * float(n))) % n
	var acc := 0.0
	var i2 := stop_idx
	while i2 != west_idx:
		var ni := route.wrap_index(i2 + 1)
		acc += _t.baked[i2].distance_to(_t.baked[ni])
		i2 = ni
	print("\ndistanta reala LINIE->PORTAL VEST pe traseu: %.1f m" % acc)

	print("\n--- verificare custom_wet_ranges/width_segments deja pe pista ---")
	print("  wet_ranges=%s" % [_t.custom_wet_ranges])
	print("  width_segments=%s" % [_t.custom_width_segments])
	print("  lane_corridors=%s" % [_t.custom_lane_corridors])
	get_tree().quit(0)
