extends Node
## Se vede MARGINEA vaii din masina, sau podeaua se intinde pana la ceata?
##
## Critica dezvoltatorului avea doua straturi: podeaua goala (rezolvat, PR #393)
## si LIPSA MALURILOR — "valea e reala si masurata, dar de pe drum nu se
## citeste ca prapastie: vezi padure mai jos, nu o margine de care sa-ti fie
## frica".
##
## Camera de JOC reala (scenes/race/chase_camera.gd), nu o aproximare:
## 10 m sus, 12,5 m in spate, fov 68 vertical, LOOK_HEIGHT 0,40.
## (Memoria verifica-cu-parametrii-lui: un ochi la 2,6 m da verdict fals.)
const TRACK := "res://scenes/tracks/Track15.tscn"
const OCHI_H := 10.0
const OCHI_SPATE := 12.5
const FOV_V := 68.0
const LOOK_H := 0.40

func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8: await get_tree().process_frame
	var n := t.baked.size()
	var sp := t.get_world_3d().direct_space_state
	print("Unde se termina podeaua vaii in cadru? (jos = muchia de jos a pozei)")
	print("frac | adanc | pana unde vezi podeaua | malul opus se vede?")
	for f: float in [0.10, 0.15, 0.28, 0.45, 0.62, 0.86]:
		var i := int(round(f * float(n))) % n
		var bp: Vector3 = t.baked[i]
		var nx: Vector3 = t.baked[(i + 1) % n]
		var d := (nx - bp); d.y = 0.0; d = d.normalized()
		var lat := Vector3(-d.z, 0.0, d.x)
		var w := t.width_at_index(i)
		var ochi := bp - d * OCHI_SPATE + Vector3.UP * OCHI_H
		# unghiul muchiei de jos a cadrului, sub orizontala
		var jos_deg := FOV_V * 0.5 - rad_to_deg(atan(LOOK_H))
		var adanc := 0.0
		var ultim_vazut := 0.0
		var mal := "nu"
		for off: float in [20.0, 40.0, 60.0, 90.0, 130.0, 180.0, 250.0]:
			for sgn: float in [1.0, -1.0]:
				var p := bp + lat * ((w + off) * sgn)
				var qs := PhysicsRayQueryParameters3D.create(
					Vector3(p.x, bp.y + 250.0, p.z), Vector3(p.x, -500.0, p.z))
				var rs := sp.intersect_ray(qs)
				if rs.is_empty(): continue
				var g: float = float((rs["position"] as Vector3).y)
				var dy := bp.y - g
				if dy < 12.0: continue
				adanc = maxf(adanc, dy)
				# e in cadru? unghiul sub orizontala din ochi
				var oriz := Vector2(p.x - ochi.x, p.z - ochi.z).length()
				var ang := rad_to_deg(atan((ochi.y - g) / maxf(oriz, 0.1)))
				if ang > jos_deg: continue  # sub poza
				var q := PhysicsRayQueryParameters3D.create(ochi, Vector3(p.x, g + 0.3, p.z))
				q.collide_with_areas = false
				if sp.intersect_ray(q).is_empty():
					ultim_vazut = maxf(ultim_vazut, off)
					# malul opus: teren care URCA inapoi peste cota drumului
					if off >= 90.0 and g > bp.y - 6.0: mal = "DA la %.0f m" % off
		print("%.2f | %5.1f | %6.0f m | %s" % [f, adanc, ultim_vazut, mal])
	get_tree().quit(0)
