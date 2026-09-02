extends Node3D
## Ce cade PE ECRAN, proiectat prin camera reala de masurare — nu unghiuri fata
## de tangenta, care m-au mintit deja o data (5 hornuri "la +31..+42 grade,
## 12-18 m peste ochi" nu erau in poza deloc).
##
## Reconstruieste exact camera din snapshot.gd (MEASURE_*) si foloseste
## `unproject_position` + `is_position_behind`. Memoria `masoara-inainte-nu-langa`:
## sonda trebuie sa raspunda la intrebarea pe care o pune POZA.

const FRACS := [0.56, 0.60, 0.64]
const PREFIX := ["MidChim", "MidVine", "MidRub", "TalusE", "Chimney"]


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var cam := Camera3D.new()
	add_child(cam)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 68.0
	cam.far = 400.0
	cam.current = true

	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var vp := get_viewport().get_visible_rect().size
	print("")
	print("=== ce cade pe ecran (%d x %d) ===" % [vp.x, vp.y])
	for f in FRACS:
		var idx := int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		cam.global_position = focus - dir * 7.5 + Vector3.UP * 3.2
		cam.look_at(focus + Vector3.UP * 1.2, Vector3.UP)
		await get_tree().process_frame

		var counts := {}
		var nearest := {}
		for pre in PREFIX:
			counts[pre] = 0
			nearest[pre] = 1e9
		for node in _all(track):
			var n3 := node as Node3D
			if n3 == null:
				continue
			for pre in PREFIX:
				if not String(n3.name).begins_with(pre):
					continue
				var p := n3.global_position + Vector3.UP * 1.0
				if cam.is_position_behind(p):
					continue
				var sp := cam.unproject_position(p)
				if sp.x < 0.0 or sp.y < 0.0 or sp.x > vp.x or sp.y > vp.y:
					continue
				counts[pre] += 1
				nearest[pre] = minf(nearest[pre], cam.global_position.distance_to(p))
		print("  frac %.2f:" % f)
		for pre in PREFIX:
			var d: float = nearest[pre]
			print("     %-9s pe ecran: %3d   cel mai apropiat: %s"
				% [pre, counts[pre], ("%.1f m" % d) if d < 1e8 else "-"])
	get_tree().quit()


func _all(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		out.append(c)
		for k in c.get_children():
			stack.push_back(k)
	return out
