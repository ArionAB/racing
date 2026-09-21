extends Node
## ADANCIMEA DE SILUETA: cate straturi de geometrie se suprapun pe aceeasi
## directie de privire?
##
## Doua cai pe FATA piesei au esuat (normal map, benzi de asiza). Captura a
## aratat de ce: zidurile au deja blocuri cu rosturi, dar sunt PLACI NETEDE
## LATE — in referinta terasele se decupeaza una peste alta, in adancime.
##
## Sonda trage raze din ochiul soferului si numara CATE corpuri distincte
## loveste pana la fundal. 1 strat = perete plat; 3+ = terase suprapuse.
## Camera de JOC reala: 10 m sus, 12,5 m in spate (chase_camera.gd).
const TRACK := "res://scenes/tracks/Track15.tscn"
const OCHI_H := 10.0
const OCHI_SPATE := 12.5
const FOV_V := 68.0

func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8: await get_tree().process_frame
	var n := t.baked.size()
	var sp := t.get_world_3d().direct_space_state
	print("frac | raze | straturi medii | max | %% raze cu 3+ straturi")
	for f: float in [0.00, 0.02, 0.45, 0.49, 0.97]:
		var i := int(round(f * float(n))) % n
		var bp: Vector3 = t.baked[i]
		var nx: Vector3 = t.baked[(i + 1) % n]
		var d := (nx - bp); d.y = 0.0; d = d.normalized()
		var lat := Vector3(-d.z, 0.0, d.x)
		var ochi := bp - d * OCHI_SPATE + Vector3.UP * OCHI_H
		var tot := 0
		var sum_str := 0
		var maxi := 0
		var bogate := 0
		# grila de raze in conul de vedere
		for yaw_i in range(-7, 8):
			for pitch_i in range(-4, 3):
				var yaw := deg_to_rad(float(yaw_i) * 6.0)
				var pitch := deg_to_rad(float(pitch_i) * 5.0)
				var dir := (d.rotated(Vector3.UP, yaw)).normalized()
				dir.y = tan(pitch) - 0.18
				dir = dir.normalized()
				var straturi := _numara(sp, ochi, dir, 320.0)
				tot += 1
				sum_str += straturi
				maxi = maxi if maxi > straturi else straturi
				if straturi >= 3: bogate += 1
		if tot == 0: continue
		print("%.2f | %4d | %14.2f | %3d | %5.1f%%" % [
			f, tot, float(sum_str) / float(tot), maxi,
			float(bogate) / float(tot) * 100.0])
	get_tree().quit(0)

## Cate corpuri distincte loveste o raza pana la `raza_max`.
func _numara(sp: PhysicsDirectSpaceState3D, de_la: Vector3, dir: Vector3,
		raza_max: float) -> int:
	var excl: Array[RID] = []
	var p := de_la
	var n := 0
	for pas in 8:
		var q := PhysicsRayQueryParameters3D.create(p, de_la + dir * raza_max)
		q.exclude = excl
		q.collide_with_areas = false
		var r := sp.intersect_ray(q)
		if r.is_empty(): break
		n += 1
		excl.append(r["rid"])
		p = (r["position"] as Vector3) + dir * 0.05
	return n
