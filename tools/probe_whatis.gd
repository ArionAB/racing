extends Node
## CE obiect ocupa un punct anume din cadrul judecat.
##
## Sonda asta exista fiindca „panza plata din dreapta-jos" a fost reparata o data
## fara ca poza sa se schimbe: adaugasem volum panzelor aterizate, dar lespedea
## din cadru putea fi cu totul alt obiect. Se trage o raza prin pixelul cerut si
## se tipareste pe ce cade, cu nume de nod si gabarit.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var i := int(0.28 * float(n)) % n
	var p := s.baked_point(i)
	var ahead := s.baked_point((i + 12) % n)
	var dir := (ahead - p).normalized()
	var eye := p - dir * ChaseCamera.DEFAULT_DISTANCE \
		+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	var cam := Camera3D.new()
	add_child(cam)
	cam.global_transform = Transform3D().looking_at(dir, Vector3.UP)
	cam.global_position = eye
	cam.current = true
	await get_tree().process_frame
	# pixelii ceruti, in fractii de ecran (lespedea sta in stanga-mijloc
	# al decupajului, adica ~0.60 x ~0.44 din cadru intreg)
	var size := Vector2(1280, 720)
	for uv: Vector2 in [Vector2(0.60, 0.44), Vector2(0.62, 0.45),
			Vector2(0.58, 0.43), Vector2(0.64, 0.46)]:
		var sp := uv * size
		var from := cam.project_ray_origin(sp)
		var dd := cam.project_ray_normal(sp)
		var best_name := "(nimic)"
		var best_d := 1e9
		var best_ab := AABB()
		var mis: Array[Node] = []
		_walk(t, mis)
		for m in mis:
			var mi := m as MeshInstance3D
			var ab: AABB = mi.global_transform * mi.get_aabb()
			var hit: Variant = ab.intersects_ray(from, dd)
			if hit == null:
				continue
			var d := from.distance_to(hit as Vector3)
			if d < best_d:
				best_d = d
				best_name = str(mi.get_path()).replace(
					"/root/ProbeWhatIs/Track13/", "")
				best_ab = ab
		print("pixel (%.2f, %.2f) -> %s  la %.0f m  gabarit %.1f x %.1f x %.1f"
			% [uv.x, uv.y, best_name, best_d,
			best_ab.size.x, best_ab.size.y, best_ab.size.z])
	get_tree().quit()


func _walk(n: Node, out: Array[Node]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_walk(c, out)
