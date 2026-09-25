extends Node
## Regenerare transform WaterfallBowen: acum pe malul EXTERIOR al bazinului
## (sgn=-1, partea rapei 2), nu pe iarba plata de pe dreapta. Baza perdelei
## trebuie sa cada in apa bazinului (dy ~ -4..-7 fata de drum), deci marker-ul
## se aseaza pe panta care urca dinspre fundul bazinului spre malul indepartat.
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
	var f := 0.855
	var i := int(round(f * float(n))) % n
	var i0 := route.wrap_index(i - 4)
	var i1 := route.wrap_index(i + 4)
	var bp: Vector3 = _t.baked[i]
	var fwd: Vector3 = (_t.baked[i1] - _t.baked[i0]).normalized()
	var side: Vector3 = route.side_at(i)
	print("frac=%.4f idx=%d road=%s fwd=%s side=%s" % [f, i, bp, fwd, side])

	# Malul exterior al bazinului: sgn=-1 (stanga), la offset care sa puna
	# BAZA perdelei in apa (dy negativ, spre -4..-7) - offset ales dupa scanul
	# fin (sv_fiord_bowen_bank): la f=0.855 (interpolat intre 0.850 si 0.8581)
	# panta urca de la fund (-30..-34) spre mal (-46..-50).
	var lateral_offset := -40.0
	var space := get_tree().root.get_world_3d().direct_space_state
	var wp_probe: Vector3 = bp + side * lateral_offset
	var from := wp_probe + Vector3(0, 150, 0)
	var to := wp_probe + Vector3(0, -150, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var hit := space.intersect_ray(q)
	var ground_y: float = hit.position.y if not hit.is_empty() else bp.y
	print("ground at offset %.1f: y=%.2f (dy_vs_road=%.2f)" % [lateral_offset, ground_y, ground_y - bp.y])

	var bz := -fwd
	var by := Vector3.UP
	var bx := by.cross(bz).normalized()
	by = bz.cross(bx).normalized()

	var pos := Vector3(wp_probe.x, ground_y, wp_probe.z)
	print("pos = %s" % [pos])
	print("\nTransform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)" % [
		bx.x, by.x, bz.x,
		bx.y, by.y, bz.y,
		bx.z, by.z, bz.z,
		pos.x, pos.y, pos.z])

	# Verifica distanta laterala fata de axa (trebuie in afara +/-7m de zbor,
	# usor - suntem la -40) si fata de carosabil (hw ~6).
	print("lateral fata de axa = %.1f m (zbor 0.85-0.875 e +/-7m; carosabil ~6m)" % lateral_offset)
	get_tree().quit(0)
