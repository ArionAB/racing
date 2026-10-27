extends Node
## Praful de aterizare (feel_checklist: jump-skill, partea de praf).
##
## Verifica, pe Car real:
##   1. o cadere reala de pe ~4 m aprinde `LandDust` o singura data, la roti,
##      si rafala se termina singura (one_shot);
##   2. un salt mic (cadere sub prag) nu ridica nimic;
##   3. culoarea e a SUPRAFETEI, aceeasi alegere ca la praful de rulare:
##      pe pista Track01 cu un interval de pamant — pamant pe interval (exact
##      culoarea pe care o ia `Dust` acolo), gri-deschis pe asfalt, culoarea
##      terenului in afara soselei;
##   4. mai multa cadere = nor mai iute si mai mare; bugetul e 16 particule.
## Un emitator care porneste nu dovedeste ca se vede un nor: vezi capturile
## din raport.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLandingDust.tscn

const STEP: float = 1.0 / 60.0
const TRACK_SCENE: String = "res://scenes/tracks/Track01.tscn"
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const F_DIRT: float = 0.3
const F_ASPHALT: float = 0.6

var _failed: bool = false


func _ready() -> void:
	await get_tree().process_frame
	add_child(_box(Vector3(1200, 1, 1200), Vector3(2000, -0.5, 0)))
	await get_tree().physics_frame
	print("")
	print("=== Praf de aterizare ===")
	await _test_real_fall()
	await _test_surface_tint()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	b.position = pos
	return b


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _test_real_fall() -> void:
	print("")
	print("-- 1+2. cadere reala de la 4 m, apoi un salt mic --")
	var car := Car.new()
	add_child(car)
	car.global_position = Vector3(2000, 4.0, 0)
	car.race_active = true
	var falls: Array[float] = []
	car.landed.connect(func(_c, v: float) -> void: falls.append(v))
	var dust: CPUParticles3D = car._land_dust
	var seen_on := 0
	var starts := 0
	var prev := false
	var near := 99.0
	var ended_at := -1.0
	for f in int(2.5 / STEP):
		await get_tree().physics_frame
		if dust.emitting:
			seen_on += 1
			near = minf(near, dust.global_position.distance_to(
				Vector3(car.global_position.x, 0.1, car.global_position.z)))
		if dust.emitting and not prev:
			starts += 1
		if prev and not dust.emitting and ended_at < 0.0:
			ended_at = f * STEP
		prev = dust.emitting
	print("  caderi semnalate: %s; praf pornit de %d ori, activ %d cadre, se termina la %.2f s, emitator la %.2f m de masina, %d particule"
		% [falls, starts, seen_on, ended_at, near, dust.amount])
	_check(falls.size() >= 1 and falls[0] > 8.0, "aterizarea a emis `landed` cu viteza de cadere")
	_check(starts == 1, "praful porneste O SINGURA data")
	_check(near < 1.0, "nor la roti (emitatorul e sub masina)")
	_check(ended_at > 0.0 and ended_at < 1.6, "rafala se termina singura (one_shot)")
	_check(dust.amount <= 16, "buget: 16 particule pe masina")

	# Salt mic: sub pragul de 5 m/s nu se ridica nimic. `landed` nu se emite sub
	# 6 m/s, deci apelam direct handler-ul cu 4 m/s (garda de prag).
	dust.emitting = false
	car._on_landed_visual(car, 4.0)
	_check(not dust.emitting, "cadere de 4 m/s: fara praf")
	car._on_landed_visual(car, 7.0)
	_check(dust.emitting, "cadere de 7 m/s: praf")
	# Mai multa cadere = nor mai mare si mai iute.
	car._on_landed_visual(car, 7.0)
	var small_v := dust.initial_velocity_max
	var small_s := dust.scale_amount_max
	car._on_landed_visual(car, 22.0)
	print("  7 m/s: viteza %.2f marime %.2f; 22 m/s: viteza %.2f marime %.2f"
		% [small_v, small_s, dust.initial_velocity_max, dust.scale_amount_max])
	_check(dust.initial_velocity_max > small_v and dust.scale_amount_max > small_s,
		"nor mai iute si mai mare la cadere mai lunga")
	car.queue_free()
	await get_tree().physics_frame


func _index_at_frac(t: Track, f: float) -> int:
	var best := 0
	var best_d := 1e9
	for i in t.baked.size():
		var d := absf(t.frac_at(i) - f)
		if d < best_d:
			best_d = d
			best = i
	return best


func _test_surface_tint() -> void:
	print("")
	print("-- 3. culoarea dupa suprafata (Track01, pamant pe 0.2-0.4) --")
	var scene := load(TRACK_SCENE) as PackedScene
	var t := scene.instantiate() as Track
	var ranges: Array[Vector2] = [Vector2(0.2, 0.4)]
	t.set("custom_dirt_ranges", ranges)
	add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.set_physics_process(false)
	car.freeze = true
	car.track = t
	car.route = 0
	car.wheels_on_ground = 4
	var dust: CPUParticles3D = car._land_dust

	# Pamant pe interval.
	car.road_index = _index_at_frac(t, F_DIRT)
	car.global_position = t.baked[car.road_index]
	car._on_landed_visual(car, 14.0)
	var on_dirt: Color = dust.color
	# Praful de rulare pe acelasi loc, cum il alege `_update_dust`.
	car.velocity = Vector3(0.0, 0.0, -20.0)
	car._update_dust(true, car._on_loose_ground(true), false)
	var run_dust: Color = car._dust_particles.color
	print("  pamant: aterizare %s, praf de rulare %s" % [on_dirt, run_dust])
	_check(on_dirt.is_equal_approx(run_dust), "pe pamant: exact culoarea prafului de rulare de acolo")

	# Asfalt.
	car.road_index = _index_at_frac(t, F_ASPHALT)
	car.global_position = t.baked[car.road_index]
	car._on_landed_visual(car, 14.0)
	var on_asph: Color = dust.color
	print("  asfalt: %s (asteptat %s)" % [on_asph, Car.DRIFT_SMOKE_COLOR.darkened(0.12)])
	_check(on_asph.is_equal_approx(Car.DRIFT_SMOKE_COLOR.darkened(0.12)), "pe asfalt: gri-deschis neutru")
	_check(not on_asph.is_equal_approx(on_dirt), "asfaltul si pamantul dau culori diferite")

	# Teren, in afara soselei.
	car.global_position = t.baked[car.road_index] + Vector3(60.0, 0.0, 0.0)
	var off_road := not t.is_on_road(car.road_index, car.global_position)
	car._on_landed_visual(car, 14.0)
	var on_ground: Color = dust.color
	print("  in afara soselei (pe drum=%s): %s (asteptat %s)" % [not off_road, on_ground,
		t.theme_ground_tint.darkened(0.12)])
	_check(off_road, "(control) punctul de proba chiar e in afara soselei")
	_check(on_ground.is_equal_approx(t.theme_ground_tint.darkened(0.12)),
		"in afara soselei: culoarea terenului temei")
	car.queue_free()
	t.queue_free()
	await get_tree().process_frame
