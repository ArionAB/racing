extends Node
## Pe ce parte cade panza fiecarui CliffFace cu far_wall, si intre ce cote.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	for nd in t.get_node("Faleze").get_children():
		var f := 0.5 * (float(nd.get("frac_start")) + float(nd.get("frac_end")))
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var side_r: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
		var sgn := signf(float(nd.get("side")))
		# side_at al sampler-ului vs dreapta geometrica
		var dirn: Vector3 = side_r * sgn
		var toward := "DREAPTA(vale)" if dirn.dot(side_r) > 0.0 else "STANGA(mal)"
		print("%-24s side=%+.0f -> %s  far_wall=%s far_bank=%s offset=%s" % [
			nd.name, sgn, toward, str(nd.get("far_wall")),
			str(nd.get("far_bank")), str(nd.get("far_offset_m"))])
	get_tree().quit(0)
