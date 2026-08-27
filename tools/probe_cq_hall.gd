extends Node
## Trece masina prin holul blocului Liziba? (Chongqing, brief §2 POI G)
##
## Sonda NU numara noduri si nu se uita la AABB-uri: plimba GABARITUL masinii
## (colizorul real, luat din Car.tscn) prin holul blocului, pas cu pas de-a
## lungul soselei, si raporteaza fiecare pozitie in care se atinge de ceva.
## Motivul e din memorie (`decor-manual-coliziune`): un bloc prin care „ar
## trebui" sa treaca drumul are patru nuclee de scara si o gura de fatada, iar
## un AABB spune ca totul e plin. Ce conteaza e daca INCAPE.
##
## Trei benzi se testeaza, nu doar axa: o masina care ia virajul pe interior
## sau iese pe exterior trebuie sa treaca si ea. Latimea benzii testate e
## semilatimea soselei minus jumatate din gabaritul masinii.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCqHall.tscn
##   ... -- --from=0.865 --to=0.910

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

## Cate benzi se plimba prin hol (impare, ca una sa fie axa).
const LANES: int = 5
## Pasul pe lungime (m). Sub jumatate de lungime de masina, ca sa nu sara
## peste un stalp de 1 m.
const STEP: float = 0.5
## Cat spatiu se cere IN PLUS peste gabarit, de fiecare parte (m).
const MARGIN: float = 0.15

var _fails: int = 0


func _ready() -> void:
	await get_tree().process_frame
	var f0 := 0.860
	var f1 := 0.915
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			f0 = float(arg.trim_prefix("--from="))
		if arg.begins_with("--to="):
			f1 = float(arg.trim_prefix("--to="))
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var box := _car_box()
	print("=== HOLUL LIZIBA: incape masina? ===")
	print("gabarit masina %.2f x %.2f x %.2f (+%.2f marja pe fiecare parte)" % [
		box.x, box.y, box.z, MARGIN])

	var space := get_viewport().world_3d.direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(box.x + MARGIN * 2.0, box.y, box.z)
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collide_with_areas = false
	params.collide_with_bodies = true

	var r := track.routes[0]
	var n := r.count()
	var hits: Array[String] = []
	var tested := 0
	var f := f0
	while f <= f1:
		var i := int(round(f * float(n))) % n
		var p := r.baked[i]
		var side := track._side_at(i)
		var fwd := (r.baked[(i + 1) % n] - p).normalized()
		var yaw := atan2(fwd.x, fwd.z)
		var w := track.width_at_index(i)
		var lane_reach := maxf(w - box.x * 0.5 - MARGIN, 0.0)
		for k in LANES:
			var t := (float(k) / float(LANES - 1)) * 2.0 - 1.0
			# Talpa masinii pe asfalt: cutia se ridica cu jumatate din inaltime.
			var q := p + side * (lane_reach * t) + Vector3.UP * (box.y * 0.5 + 0.05)
			params.transform = Transform3D(Basis(Vector3.UP, yaw), q)
			var res := space.intersect_shape(params, 4)
			tested += 1
			for hit: Dictionary in res:
				var col := hit.get("collider") as Node
				if col == null:
					continue
				var owner_name := _prop_name(col)
				# Soseaua, terenul si umerii nu sunt obstacol: cutia sta PE ele,
				# si corpul lor se numeste tot „root". Ne intereseaza numai ce a
				# fost ASEZAT — decorul manual si geometria hazardelor.
				# Grinda monorailului NU e obstacol: e o dala de 22 cm cu umeri in
				# panta, peste care se trece ca peste o sina de tramvai (vezi
				# antetul lui MonorailHazard). Cutia masinii o atinge fiindca sta
				# la 5 cm de asfalt — asta e corect, nu e blocaj.
				if owner_name.find("/DecorManual/") < 0:
					continue
				# Unde anume: pozitia cutiei si, pentru un prop, coordonatele
				# ei in spatiul MODELULUI — acolo se citeste ce a atins.
				var loc := Vector3.ZERO
				if col is Node3D:
					var host := col.get_parent()
					if host is Node3D:
						loc = (host as Node3D).global_transform.affine_inverse() * q
				hits.append("  frac %.4f banda %+.2f  cutie(%.1f,%.1f,%.1f) local(%.2f,%.2f,%.2f) -> %s" % [
					r.frac_at(i), t, q.x, q.y, q.z, loc.x, loc.y, loc.z, owner_name])
		f += STEP / r.length()

	print("pozitii testate: %d" % tested)
	if hits.is_empty():
		print("  [OK] gabaritul trece pe toate cele %d benzi, %.3f..%.3f" % [LANES, f0, f1])
	else:
		_fails += 1
		print("  [PICAT] %d atingeri:" % hits.size())
		var shown := 0
		for h in hits:
			print(h)
			shown += 1
			if shown >= 40:
				print("  ... si inca %d" % (hits.size() - shown))
				break
	print("")
	print("VERDICT: %s" % ("PROBLEMA" if _fails > 0 else "OK"))
	get_tree().quit(1 if _fails > 0 else 0)


## Numele prop-ului din care face parte un colizor (corpurile automate ale lui
## WorldProp sunt copii ai instantei GLB).
func _prop_name(col: Node) -> String:
	# Calea completa in scena spune si CINE e obstacolul, si din ce zona vine.
	# Numele corpului singur nu ajuta: corpurile automate ale lui `WorldProp`
	# se numesc toate „root", la fel ca cel al soselei.
	var parts: Array[String] = []
	var cur := col
	for _k in 10:
		if cur == null:
			break
		parts.push_front(str(cur.name))
		if str(cur.name) == "Track12":
			break
		cur = cur.get_parent()
	return "/".join(parts)


## Gabaritul colizorului masinii, citit din Car.tscn.
func _car_box() -> Vector3:
	var car := (load(CAR_SCENE) as PackedScene).instantiate()
	add_child(car)
	var out := Vector3(2.0, 1.1, 4.0)
	for child in car.get_children():
		if child is CollisionShape3D:
			var sh := (child as CollisionShape3D).shape
			if sh is BoxShape3D:
				out = (sh as BoxShape3D).size
	car.queue_free()
	return out
