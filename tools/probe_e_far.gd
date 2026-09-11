extends Node
## Ce e banda palida de la departare in cadrul hero (POI E, frac 0.40)?
##
## Runda 4. Criticul: "malul opus se randeaza la aceeasi luminanta ca
## prim-planul, bolul nu se inchide". Sondele anterioare masurau PIXELI; asta
## intreaba GEOMETRIA: pe razele reale ale camerei de joc, ce nod e lovit si
## la ce distanta. Daca banda palida e teren la 300+ m, e problema de ceata /
## de cota; daca e SeaFar, e alt obiect.

const CAM_DIST: float = 12.5
const CAM_HEIGHT: float = 10.0
const CAM_FOV: float = 68.0

func _ready() -> void:
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var i := int(0.40 * float(n)) % n
	var p: Vector3 = r.baked[i]
	var pf: Vector3 = r.baked[(i + 12) % n]
	var fwd := (pf - p)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var eye := p - fwd * CAM_DIST + Vector3(0, CAM_HEIGHT, 0)
	var look := p + fwd * 14.0 + Vector3(0, 1.2, 0)
	print("EYE %s LOOK %s" % [str(eye), str(look)])
	var cam := Camera3D.new()
	get_tree().root.add_child(cam)
	cam.fov = CAM_FOV
	cam.global_position = eye
	cam.look_at(look, Vector3.UP)
	var space := track.get_world_3d().direct_space_state
	var W := 1280
	var H := 720
	# grid de raze pe cadru
	for ry in [0.16, 0.22, 0.28, 0.34, 0.40, 0.50]:
		var line := "rand %.2f:" % ry
		for rx in [0.55, 0.65, 0.75, 0.85, 0.95]:
			var sp := Vector2(rx * W, ry * H)
			var o := cam.project_ray_origin(sp)
			var d := cam.project_ray_normal(sp)
			var q := PhysicsRayQueryParameters3D.create(o, o + d * 1200.0)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				line += "  x%.2f:CER" % rx
			else:
				var col := hit.collider as Node
				var dist := o.distance_to(hit.position)
				line += "  x%.2f:%s@%.0fm,y=%.1f" % [rx, col.name, dist, float(hit.position.y)]
		print(line)
	get_tree().quit(0)
