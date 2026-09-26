extends Node
## Genereaza transformul (randuri, ca la StirlingFalls) pentru WaterfallBowen:
## local -Z aliniat cu directia drumului (ca la StirlingFalls/RainFall*),
## pozitionat pe partea DREAPTA (sgn=+1, convenita empiric cu sv_fiord_stirling_wall.gd)
## la un offset lateral care sa puna perdeaua LANGA perete, in afara benzii de
## zbor (0.85-0.875, +/-7m de axa, memoria gauntlet §G) si in afara carosabilului
## (half_width ~6).
const TRACK := "res://scenes/tracks/Track16.tscn"
var _t: Track

func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var route := _t.routes[0]
	var n := _t.baked.size()
	var f := 0.846
	var i := int(round(f * float(n))) % n
	var i0 := route.wrap_index(i - 4)
	var i1 := route.wrap_index(i + 4)
	var bp: Vector3 = _t.baked[i]
	var fwd: Vector3 = (_t.baked[i1] - _t.baked[i0]).normalized()
	var side: Vector3 = route.side_at(i)
	var hw: float = _t.width_at_index(i)
	print("frac=%.4f idx=%d road=%s fwd=%s side=%s hw=%.2f" % [f, i, bp, fwd, side, hw])

	# Basis pentru local -Z = fwd (acelasi tipar ca StirlingFalls/RainFall*):
	# basis.z = -fwd (Node3D "priveste" spre -Z local), basis.x = side (dreapta),
	# basis.y = up (aproximam cu UP, ca la celelalte perdele care au usoara
	# inclinare din panta - aici o las simpla, verific cu sv_hazard_orient dupa).
	var bz := -fwd
	var by := Vector3.UP
	var bx := by.cross(bz).normalized()
	by = bz.cross(bx).normalized()
	print("basis check: bx=%s by=%s bz=%s (bx x by . bz ar trebui ~1: %.3f)"
		% [bx, by, bz, bx.cross(by).dot(bz)])

	var lateral_offset := hw + 8.0 # in afara asfaltului (hw~6) + marja pana la perete
	var pos := bp + side * lateral_offset
	print("pos (drum + side*%.1f) = %s" % [lateral_offset, pos])

	# .tscn scrie RANDURILE bazei (memoria tscn-transform-e-pe-randuri):
	# Transform3D(bx.x,by.x,bz.x, bx.y,by.y,bz.y, bx.z,by.z,bz.z, ox,oy,oz)
	print("\nTransform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)" % [
		bx.x, by.x, bz.x,
		bx.y, by.y, bz.y,
		bx.z, by.z, bz.z,
		pos.x, pos.y, pos.z])
	get_tree().quit(0)
