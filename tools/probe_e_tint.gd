extends Node3D
## Ce culoare de VERTEX are terenul pe con (y ~ 40) fata de langa drum (y ~ 17).
## Verifica direct daca `rock_band_tint` ajunge la geometrie — capturile au dat
## cifre identice si trebuie stiut daca vina e in tema sau in randare.
func _ready() -> void:
	var track := get_parent().get_node_or_null("Track13")
	await get_tree().process_frame
	print("rock_band_tint = %s" % str(track.call("theme_flag", "rock_band_tint", null)))
	print("rock_line      = %s" % str(track.call("theme_flag", "rock_line", -999)))
	print("rock_fade      = %s" % str(track.call("theme_flag", "rock_fade", -999)))
	var lo := 0
	var hi := 0
	var lo_c := Color(0, 0, 0)
	var hi_c := Color(0, 0, 0)
	for mi in _meshes(track):
		var mesh: Mesh = mi.mesh
		if mesh == null:
			continue
		for si in mesh.get_surface_count():
			var arr: Array = mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var col = arr[Mesh.ARRAY_COLOR]
			if col == null or v.size() == 0:
				continue
			for k in range(v.size()):
				if v[k].y > 38.0 and v[k].y < 46.0:
					hi += 1
					hi_c += Color(col[k].r, col[k].g, col[k].b)
				elif v[k].y > 14.0 and v[k].y < 20.0:
					lo += 1
					lo_c += Color(col[k].r, col[k].g, col[k].b)
	if lo > 0:
		print("vertecsi y 14-20 : %5d  culoare medie (%.3f, %.3f, %.3f)" % [
			lo, lo_c.r / lo, lo_c.g / lo, lo_c.b / lo])
	if hi > 0:
		print("vertecsi y 38-46 : %5d  culoare medie (%.3f, %.3f, %.3f)" % [
			hi, hi_c.r / hi, hi_c.g / hi, hi_c.b / hi])
	get_tree().quit()

func _meshes(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D:
		o.append(n)
	for c in n.get_children():
		o.append_array(_meshes(c))
	return o
