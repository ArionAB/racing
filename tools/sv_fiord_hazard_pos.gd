extends Node
## Sonda ad-hoc, folosinta unica: deriva pozitii/orientari pentru hazardele
## ramase pe Track16 (Stirling, cascadele de ploaie, avalansa, kickerul Bowen)
## din `baked`/`_side_at`, la fel ca `sv_fiord_signal_pos.gd` pentru semafor.
## Doar citire — nu construieste, nu scrie nimic pe disc.
const TRACK := "res://scenes/tracks/Track16.tscn"
var _t: Track


func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	var route := _t.routes[0]
	var n := _t.baked.size()
	print("baked n=%d total_len=%.2f" % [n, _t.curve.get_baked_length()])

	var points := {
		"Stirling_start": 0.273,
		"Stirling_mid": 0.298,
		"Stirling_end": 0.323,
		"RainB_1": 0.10,
		"RainB_2": 0.17,
		"RainChasm": 0.40,
		"RainF_1": 0.72,
		"RainF_2": 0.79,
		"Avalanche": 0.75,
		"Avalanche_declive_start": 0.690,
		"Avalanche_declive_end": 0.818,
		"Bowen_start": 0.846,
		"Bowen_mid": 0.857,
		"Bowen_end": 0.868,
	}
	for label in points.keys():
		var frac: float = points[label]
		var idx := int(round(frac * float(n))) % n
		var p: Vector3 = _t.baked[idx]
		var dir: Vector3 = (_t.baked[route.wrap_index(idx + 1)] - p).normalized()
		var side: Vector3 = dir.cross(Vector3.UP).normalized()
		var hw := _t.width_at_index(idx)
		var basis2 := Basis.looking_at(-dir, Vector3.UP) # local +Z = dir (conventia semaforului)
		var basis_fwd := Basis.looking_at(dir, Vector3.UP) # local -Z = dir (conventia hazardelor mobile: train/avalanche)
		print("\n--- %s (frac=%.4f idx=%d) ---" % [label, frac, idx])
		print("  pos=(%.2f, %.2f, %.2f)  dir=(%.3f,%.3f,%.3f)  side=(%.3f,%.3f,%.3f)  half_width=%.2f"
			% [p.x, p.y, p.z, dir.x, dir.y, dir.z, side.x, side.y, side.z, hw])
		print("  TRANSFORM3D (fwd, local -Z = dir): Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)"
			% [basis_fwd.x.x, basis_fwd.x.y, basis_fwd.x.z, basis_fwd.y.x, basis_fwd.y.y, basis_fwd.y.z,
				basis_fwd.z.x, basis_fwd.z.y, basis_fwd.z.z, p.x, p.y, p.z])

	# Lungimea segmentului Stirling (0.273-0.323), pe traseu real, pentru
	# WaterfallHazard.length.
	var i0 := int(round(0.273 * float(n))) % n
	var i1 := int(round(0.323 * float(n))) % n
	var acc := 0.0
	var i := i0
	while i != i1:
		var ni := route.wrap_index(i + 1)
		acc += _t.baked[i].distance_to(_t.baked[ni])
		i = ni
	print("\nStirling: distanta reala 0.273->0.323 = %.1f m" % acc)

	print("\ncustom_ravines=%s" % [_t.custom_ravines])
	print("custom_width_segments=%s" % [_t.custom_width_segments])
	print("custom_sea_level_offset=%s" % [_t.custom_sea_level_offset])
	get_tree().quit(0)
