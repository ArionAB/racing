extends Node3D
## Unde cade banda goala din cadrul de ansamblu, in coordonate de lume.
##
## Camera de ansamblu (--eye=170,95,255 --look=-10,0,40) vede terenul; sonda
## trage raze prin randurile cadrului si raporteaza punctul de lume lovit,
## distanta fata de ochi si ce corp a fost atins. Asa stim CE interval de
## distante trebuie populat, nu ghicim "peste 150 m".

const EYE := Vector3(170, 95, 255)
const LOOK := Vector3(-10, 0, 40)
const FOV := 60.0
const W := 1280
const H := 720

func _ready() -> void:
	var scene: PackedScene = load("res://scenes/tracks/Track14.tscn")
	var track: Node3D = scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame

	var space := get_world_3d().direct_space_state
	var fwd := (LOOK - EYE).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var tan_half := tan(deg_to_rad(FOV) * 0.5)
	var aspect := float(W) / float(H)

	print("=== banda goala in coordonate de lume (camera de ansamblu) ===")
	print("  frac_y   dist_m    punct(x,y,z)            corp")
	for fy: float in [0.28, 0.30, 0.32, 0.34, 0.36, 0.40, 0.45, 0.50, 0.60, 0.75, 0.90]:
		var ndc_y := 1.0 - 2.0 * fy
		var dirs: Array[Vector3] = []
		for fx: float in [0.2, 0.5, 0.8]:
			var ndc_x := 2.0 * fx - 1.0
			dirs.append((fwd + right * (ndc_x * tan_half * aspect)
				+ up * (ndc_y * tan_half)).normalized())
		var line := "  %.2f  " % fy
		for d: Vector3 in dirs:
			var q := PhysicsRayQueryParameters3D.create(EYE, EYE + d * 900.0)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				line += "   (cer)              "
			else:
				var p: Vector3 = hit["position"]
				line += " %6.0fm (%5.0f,%4.0f,%5.0f)" % [EYE.distance_to(p), p.x, p.y, p.z]
		print(line)

	# Ce prop-uri exista dincolo de 150 m fata de ochi
	var far_count := 0
	var near_count := 0
	var dm := track.get_node_or_null("DecorManual")
	if dm != null:
		for z in dm.get_children():
			for n in z.get_children():
				if n is Node3D:
					var d := EYE.distance_to((n as Node3D).global_position)
					if d > 150.0:
						far_count += 1
					else:
						near_count += 1
	print("prop-uri DecorManual: %d sub 150 m de ochi, %d peste" % [near_count, far_count])
	get_tree().quit()
