extends Node
## GOLUL DE SUB ORIZONT. Din pozitia camerei de la frac 0.05, se trag raze pe
## azimuturi din cadru, sub linia orizontului, si se intreaba ce lovesc. O raza
## care pleaca IN JOS si nu loveste nimic = cer vizibil sub orizont, adica exact
## "the horizon visibly drops below the far chimneys showing void".
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var i := int(0.05 * n)
	var p: Vector3 = r.baked[i]
	var a: Vector3 = r.baked[(i + 6) % n]
	var dir: Vector3 = (a - p).normalized()
	var eye: Vector3 = p - dir * 12.5 + Vector3.UP * 10.0
	var space := get_tree().root.world_3d.direct_space_state
	var right := dir.cross(Vector3.UP).normalized()
	print("eye y = %.1f" % eye.y)
	print("yaw | pitch | ce loveste | dist | y_hit")
	var goluri := 0
	var total := 0
	for yaw_i in range(-17, 18, 2):
		for pitch_i in [-1, -2, -3, -5]:
			var yaw := deg_to_rad(float(yaw_i) * 2.0)
			var pitch := deg_to_rad(float(pitch_i))
			var d := (dir * cos(yaw) + right * sin(yaw)).normalized()
			d = (d + Vector3.UP * tan(pitch)).normalized()
			var q := PhysicsRayQueryParameters3D.create(eye, eye + d * 380.0)
			var hit := space.intersect_ray(q)
			total += 1
			if hit.is_empty():
				goluri += 1
				if pitch_i == -1:
					# cat de departe merge terenul pe azimutul asta, si unde se
					# termina: se coboara pana gaseste ceva
					var last := 0.0
					for pi in range(-2, -40, -2):
						var d2 := (dir * cos(yaw) + right * sin(yaw)).normalized()
						d2 = (d2 + Vector3.UP * tan(deg_to_rad(float(pi)))).normalized()
						var q2 := PhysicsRayQueryParameters3D.create(eye, eye + d2 * 380.0)
						var h2 := space.intersect_ray(q2)
						if not h2.is_empty():
							last = eye.distance_to(h2["position"])
							print("%4d | %3d | GOL; terenul se termina la %.0f m (sub %d deg), y=%.1f" % [
								yaw_i * 2, pitch_i, last, pi, h2["position"].y])
							break
					if last == 0.0:
						print("%4d | %3d | GOL TOTAL pe azimut" % [yaw_i * 2, pitch_i])
	print("--- raze in jos fara lovitura: %d din %d (%.0f%%)" % [
		goluri, total, 100.0 * goluri / total])
	get_tree().quit(0)
