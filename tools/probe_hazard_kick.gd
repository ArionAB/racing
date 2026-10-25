extends Node
## Hazardele mobile vorbesc prin camera (feel: hazards-speak, partea fara sunet):
## un SlidingHazard REAL te matura peste un jucator stationar, si jucatorul trebuie
## sa primeasca kick de camera in sensul in care e impins.
##
## Masoara pe corpul real al hazardului (AnimatableBody3D): daca semnalul `impact`
## nu ajunge (impingerea vine doar din `apply_sweep`, fara contact), jucatorul e
## azvarlit in tacere — exact defectul din checklist ("te imping pe tacute").
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHazardKick.tscn

const ImpactFeelScript := preload("res://scenes/race/impact_feel.gd")

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(600, 1, 600)
	cs.shape = sh
	ground.add_child(cs)
	ground.position = Vector3(0, -0.5, 0)
	add_child(ground)

	var hz := SlidingHazard.new()
	hz.road_half_width = 14.0
	hz.max_sweep_speed = 12.0
	add_child(hz)
	hz.center = Vector3.ZERO
	hz.travel = Vector3.RIGHT * 8.0
	hz.global_position = Vector3.ZERO

	# Jucatorul sta pe traseul pendulului, la +X, cu botul spre -Z.
	var car := Car.new()
	add_child(car)
	car.global_position = Vector3(6.5, 0.7, 0)
	car.race_active = true
	car.is_player = true
	var cam := ChaseCamera.new()
	add_child(cam)
	cam.target = car
	cam.snap_behind()
	var feel := ImpactFeelScript.new()
	add_child(feel)
	feel.setup(car, [car], cam, null)

	var impacts: Array[Dictionary] = []
	car.impact.connect(func(_c: Car, kind: StringName, strength: float, normal: Vector3,
			_p: Vector3, other: Node) -> void:
		impacts.append({"kind": kind, "strength": strength, "normal": normal,
			"other": other, "tick": Engine.get_physics_frames()}))
	var sweeps: Array[int] = [] # tick-uri cu salt de viteza orizontala > 2.5 m/s
	var prev_v := Vector3.ZERO
	var peak_kick := 0.0
	var kick_dir := Vector3.ZERO
	var min_scale := 1.0

	await get_tree().physics_frame
	print("")
	print("=== Hazard mobil -> kick de camera ===")
	for _t in 60 * 6:
		await get_tree().physics_frame
		min_scale = minf(min_scale, Engine.time_scale)
		var v := Vector3(car.linear_velocity.x, 0.0, car.linear_velocity.z)
		if (v - prev_v).length() > 2.5 and Engine.get_physics_frames() > 5:
			sweeps.append(Engine.get_physics_frames())
		prev_v = v
		var k := cam.kick_offset().length()
		if k > peak_kick:
			peak_kick = k
			kick_dir = cam.kick_offset().normalized()

	print("  ticks cu salt de viteza: ", sweeps)
	var from_hz := impacts.filter(func(e: Dictionary) -> bool: return e.other == hz)
	print("  impact total %d, de la hazard %d, salturi de viteza >2.5 m/s: %d"
		% [impacts.size(), from_hz.size(), sweeps.size()])
	for e in impacts:
		var n: Vector3 = e.normal
		print("    tick %d: %s forta %.1f normala (%.2f, %.2f) hazard=%s"
			% [e.tick, str(e.kind), e.strength, n.x, n.z, str(e.other == hz)])
	print("  kick maxim %.2f m, directie (%.2f, %.2f), pozitie masina x=%.1f"
		% [peak_kick, kick_dir.x, kick_dir.z, car.global_position.x])
	_check(not sweeps.is_empty(), "hazardul a impins masina (salt de viteza)")
	_check(not from_hz.is_empty(), "impingerea ajunge ca `impact` (corpul hazardului)")
	# Fiecare salt de viteza trebuie sa aiba un impact in jurul lui (cooldown-ul peretelui e 0.2 s = 12 tick-uri).
	var silent := 0
	for s in sweeps:
		var near := false
		for e in impacts:
			if absi(int(e.tick) - s) <= 12:
				near = true
		if not near:
			silent += 1
	_check(silent == 0, "nicio impingere in tacere (%d din %d fara impact)"
		% [silent, sweeps.size()])
	_check(peak_kick > 0.15, "camera primeste kick (>0.15 m)")
	_check(min_scale == 1.0 and not feel.last_player_attacker,
		"maturat de hazard cat stai: fara hit-stop, jucatorul nu e atacator")
	if not from_hz.is_empty():
		var n0: Vector3 = from_hz[0].normal
		_check(n0.x > 0.5, "normala dinspre hazard spre masina (+X, hazardul vine din stanga)")
	await _drive_into_parked_body(car, cam, feel)
	await _bus_from_behind(car, cam, feel)
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	Engine.time_scale = 1.0
	get_tree().quit(1 if _failed else 0)


## Corp cinematic PARCAT (aceeasi clasa de corp ca hazardul): jucatorul se izbeste
## de el cu 20 m/s => atacator, cu hit-stop (e un perete pentru el).
func _drive_into_parked_body(car: Car, cam: ChaseCamera, feel: Node) -> void:
	print("")
	print("-- jucatorul intra intr-un corp cinematic parcat --")
	var body := AnimatableBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(10, 3, 1)
	cs.shape = sh
	body.add_child(cs)
	body.position = Vector3(100, 1.5, -40)
	add_child(body)
	car.global_position = Vector3(100, 0.7, -20)
	car.rotation = Vector3.ZERO
	car.linear_velocity = Vector3.ZERO
	cam.snap_behind()
	await get_tree().create_timer(1.0).timeout
	feel.hit_stop._cool = 0.0
	car.linear_velocity = Vector3(0, 0, -22)
	var frozen := 0
	var kick := 0.0
	for _t in 80:
		await get_tree().process_frame
		if Engine.time_scale < 0.999:
			frozen += 1
		kick = maxf(kick, cam.kick_offset().length())
	print("  kick %.2f m, inghet %d cadre, atacator=%s, cota %.2f"
		% [kick, frozen, str(feel.last_player_attacker), feel.last_share])
	_check(feel.last_player_attacker and frozen > 0 and kick > 0.3,
		"izbit de un corp parcat: atacator, hit-stop si kick plin")


## Autobuzul (BusHazard, alt tip de corp cinematic) te prinde din spate cat stai.
func _bus_from_behind(car: Car, cam: ChaseCamera, feel: Node) -> void:
	print("")
	print("-- autobuzul te prinde din spate --")
	var bus := BusHazard.new()
	bus.points = PackedVector3Array([Vector3(200, 0, 140), Vector3(200, 0, -140)])
	bus.speed = 14.0
	bus.stick_to_ground = false
	bus.apex_outer_m = 0.0
	add_child(bus)
	car.global_position = Vector3(200, 0.7, 0)
	car.rotation = Vector3.ZERO
	car.linear_velocity = Vector3.ZERO
	cam.snap_behind()
	feel.hit_stop._cool = 0.0
	var hits: Array[Dictionary] = []
	car.impact.connect(func(_c: Car, kind: StringName, strength: float, normal: Vector3,
			_p: Vector3, other: Node) -> void:
		hits.append({"kind": kind, "strength": strength, "normal": normal, "other": other}))
	var kick := 0.0
	var min_scale := 1.0
	for _t in 60 * 25:
		await get_tree().physics_frame
		kick = maxf(kick, cam.kick_offset().length())
		min_scale = minf(min_scale, Engine.time_scale)
	var from_bus := hits.filter(func(e: Dictionary) -> bool:
		return e.other != null and bus.body() != null and e.other == bus.body())
	print("  impact total %d, de la corpul autobuzului %d, kick maxim %.2f m, time_scale minim %.2f"
		% [hits.size(), from_bus.size(), kick, min_scale])
	for e in hits:
		print("    %s forta %.1f normala (%.2f, %.2f)"
			% [str(e.kind), e.strength, (e.normal as Vector3).x, (e.normal as Vector3).z])
	_check(not from_bus.is_empty(), "autobuzul te loveste prin `impact`")
	_check(kick > 0.15, "camera primeste kick de la autobuz")
	_check(min_scale == 1.0, "fara hit-stop cand te loveste autobuzul")
	bus.queue_free()
