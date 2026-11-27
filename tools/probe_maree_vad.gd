extends Node
## PRIN APA (Ha Long, Track22): mareea te tine in loc, si te prinde EXACT pe
## banda pe care o vezi inundata.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMareeVad.tscn
##   ... -- --sabotaj    # wade_speed_factor = 1.0: garda 2 TREBUIE sa pice
##
## Cererea dezvoltatorului (26 nov 2026): „80% din viteza cat conduci prin apa".
## Cu digul imprejmuit (#760), alunecarea singura nu mai costa nimic — gardul
## te tine pe banda — deci banda inundata devenise aproape gratis.
##
##  1. [b]ZONA E PE BANDA[/b]: puncte pe toata latimea benzii inundate (axa si
##     ±(hw-0.5) m) cad in zona mareei; puncte pe soseaua principala, langa
##     furci, NU. Cutia veche de pe coarda lasa capetele benzii pe dinafara;
##  2. [b]PRIN APA MERGI CU ~80%[/b]: aceeasi masina (taxi), acelasi sofer,
##     aceeasi banda, odata la apa JOS (uscat) si odata la apa SUS, lansata la
##     plafonul ei. Se compara viteza REALA medie pe mijlocul benzii, nu
##     plafoanele: pe digul uscat masina nu-si atinge plafonul nominal, deci
##     `wade_speed_factor` (0.70) e mai mic decat raportul cerut (vezi antetul
##     lui in `tide_hazard.gd`). Fereastra 0.72..0.88.
##
## Reglaj: `--car=nume`, `--factor=` (suprascrie plafonul), `--grip=` (cat
## citeste soferul curba; 0 = gaz tinut).

const TRACK := "res://scenes/tracks/Track22.tscn"
const CAR_SCENE := "res://scenes/cars/Car.tscn"
const CAR_DATA := "res://scenes/cars/data/taxi.tres"
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")

const COVER_MIN: float = 0.95
const RATIO_MIN: float = 0.72
const RATIO_MAX: float = 0.88

var _failed: bool = false
var _track: Node3D
var _tide: TideHazard
## `--grip=` aderenta cu care soferul de sonda citeste curba (0 = gaz tinut).
var _grip: float = 14.0
## `--car=nume` presetarea (implicit taxi); `--factor=` suprascrie plafonul (tunare).
var _car: String = CAR_DATA
var _factor: float = -1.0


func _ready() -> void:
	var sabotaj := "--sabotaj" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--grip="):
			_grip = float(arg.trim_prefix("--grip="))
		elif arg.begins_with("--car="):
			_car = "res://scenes/cars/data/%s.tres" % arg.trim_prefix("--car=")
		elif arg.begins_with("--factor="):
			_factor = float(arg.trim_prefix("--factor="))
	_track = (load(TRACK) as PackedScene).instantiate() as Node3D
	add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	_tide = _track.get_node("Maree") as TideHazard
	if _factor > 0.0:
		_tide.wade_speed_factor = _factor
	if sabotaj:
		_tide.wade_speed_factor = 1.0
	print("=== ProbeMareeVad%s ===" % (" (SABOTAJ: wade_speed_factor = 1.0)"
		if sabotaj else ""))
	await _check_zone()
	await _check_speed()
	print("")
	print("REZULTAT FINAL: %s" % ("PICAT" if _failed else "TRECUT"))
	get_tree().quit(1 if _failed else 0)


## Punctele benzii pe care sta apa: aceleasi pe care le pastreaza
## `TideHazard.fit_to_route` (departe de soseaua principala).
func _wet_indices() -> Array[int]:
	var routes: Array = _track.get("routes")
	var r = routes[_tide.branch_index]
	var main = routes[0]
	var out: Array[int] = []
	for i in r.count():
		var mi: int = main.closest_index_global(r.baked[i])
		if main.lateral_distance(mi, r.baked[i]) > float(_track.call(
				"width_at_index", mi)) + r.half_width * 0.5 \
				+ TideHazard.ROUTE_ROAD_CLEAR:
			out.append(i)
	return out


func _in_zone(space: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
	var q := PhysicsPointQueryParameters3D.new()
	q.position = p
	q.collide_with_areas = true
	q.collide_with_bodies = false
	for hit in space.intersect_point(q, 32):
		if hit["collider"] == _tide._zone:
			return true
	return false


func _check_zone() -> void:
	print("")
	print("-- 1. zona mareei sta pe banda inundata, nu pe coarda --")
	var routes: Array = _track.get("routes")
	var r = routes[_tide.branch_index]
	var main = routes[0]
	var space := get_viewport().world_3d.direct_space_state
	var wet := _wet_indices()
	var total := 0
	var inside := 0
	var misses: Array[String] = []
	var next := -1.0
	for i: int in wet:
		if r.dists[i] < next:
			continue
		next = r.dists[i] + 3.0
		var c: Vector3 = _track.to_global(r.baked[i])
		var side: Vector3 = (_track.global_transform.basis * r.side_at(i)).normalized()
		for lat: float in [-(r.half_width - 0.5), 0.0, r.half_width - 0.5]:
			var p := c + side * lat + Vector3.UP * 0.6
			total += 1
			if _in_zone(space, p):
				inside += 1
			elif misses.size() < 6:
				misses.append("d %.0f lat %+.1f" % [r.dists[i], lat])
	var cover := float(inside) / maxf(float(total), 1.0)
	print("  banda inundata: %d/%d puncte in zona (%.0f%%, prag %.0f%%)%s" % [
		inside, total, cover * 100.0, COVER_MIN * 100.0,
		"" if misses.is_empty() else "  ratate: " + ", ".join(misses)])
	# Soseaua principala in jurul celor doua furci: niciun punct in zona.
	var leaks := 0
	var probed := 0
	for end_i: int in [0, r.count() - 1]:
		var g: Vector3 = _track.to_global(r.baked[end_i])
		var mi: int = main.closest_index_global(r.baked[end_i])
		for k in range(-12, 13, 2):
			var j: int = posmod(mi + k, main.count())
			var c: Vector3 = _track.to_global(main.baked[j])
			if c.distance_to(g) > 45.0:
				continue
			probed += 1
			if _in_zone(space, c + Vector3.UP * 0.6):
				leaks += 1
	print("  soseaua principala langa furci: %d/%d puncte in zona (asteptat 0)"
		% [leaks, probed])
	var ok := cover >= COVER_MIN and leaks == 0 and probed > 0
	print("  %s" % ("[OK]" if ok else "[PICAT]"))
	if not ok:
		_failed = true


## Ora din ciclu la mijlocul unei faze (s).
func _clock_in(ph: TideHazard.Phase) -> float:
	var sum := _tide.low_frac + _tide.rise_frac + _tide.high_frac + _tide.fall_frac
	var u := 0.0
	match ph:
		TideHazard.Phase.SUS:
			u = _tide.rise_frac + _tide.high_frac * 0.5
		TideHazard.Phase.JOS:
			u = _tide.rise_frac + _tide.high_frac + _tide.fall_frac \
				+ _tide.low_frac * 0.5
	return (u / sum - _tide.phase) * _tide.period


func _check_speed() -> void:
	print("")
	print("-- 2. prin apa, plafonul de viteza e %.0f%% din cel uscat --"
		% (_tide.wade_speed_factor * 100.0))
	var dry := await _run(TideHazard.Phase.JOS)
	var wet := await _run(TideHazard.Phase.SUS)
	print("  plafon uscat %.2f m/s, plafon in apa %.2f m/s (%.0f%%)" % [
		dry.vmax, wet.cap, 100.0 * float(wet.cap) / maxf(float(dry.vmax), 0.1)])
	print("  uscat (JOS): %.2f m/s medie pe mijlocul benzii, max %.2f" % [dry.mean, dry.top])
	print("  apa   (SUS): %.2f m/s medie pe mijlocul benzii, max %.2f, timp in apa %.1f s"
		% [wet.mean, wet.top, wet.wade_s])
	var ratio: float = wet.mean / maxf(dry.mean, 0.1)
	var ok := ratio >= RATIO_MIN and ratio <= RATIO_MAX and float(dry.wade_s) == 0.0
	print("  raport %.3f (fereastra %.2f..%.2f), apa pe uscat %.1f s (asteptat 0)  %s" % [
		ratio, RATIO_MIN, RATIO_MAX, dry.wade_s, "[OK]" if ok else "[PICAT]"])
	if not ok:
		_failed = true


## O trecere pe toata banda, cu mareea tinuta in faza data.
func _run(ph: TideHazard.Phase) -> Dictionary:
	var routes: Array = _track.get("routes")
	var r = routes[_tide.branch_index]
	var wet := _wet_indices()
	var d0: float = r.dists[wet[0]]
	var d1: float = r.dists[wet[wet.size() - 1]]
	# Mijlocul benzii inundate: dupa ce ambele treceri s-au asezat pe plafon.
	var m0 := lerpf(d0, d1, 0.4)
	var m1 := lerpf(d0, d1, 0.9)
	var pts: Array[Vector3] = []
	var next := 0.0
	for i in r.count():
		if r.dists[i] >= next:
			pts.append(_track.to_global(r.baked[i]))
			next = r.dists[i] + 6.0
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	_track.add_child(car)
	car.apply_data(load(_car) as CarData)
	var drv := WaypointDriver.new()
	drv.waypoints = pts
	drv.target_speed = 60.0
	drv.corner_grip = _grip
	drv.reach = 6.0
	car.set_controller(drv)
	car.race_active = true
	var a: Vector3 = pts[0]
	var b: Vector3 = pts[2]
	var fwd := b - a
	fwd.y = 0.0
	car.global_transform = Transform3D(
		Basis.looking_at(fwd.normalized(), Vector3.UP), a + Vector3.UP * 0.7)
	# Lansata la plafonul ei uscat: de pe loc, pe 155 m masina nu-si atinge
	# viteza maxima nici pe uscat, si raportul ar masura acceleratia, nu apa.
	await get_tree().physics_frame
	var vmax_dry: float = car._current_max_speed()
	car.velocity = Basis.looking_at(fwd.normalized(), Vector3.UP) 		* Vector3.FORWARD * vmax_dry
	var cap_wet := 0.0
	var clock := _clock_in(ph)
	var sum := 0.0
	var n := 0
	var top := 0.0
	var wade_s := 0.0
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	for _f in 60 * 25:
		_tide.set_clock(clock)
		await get_tree().physics_frame
		var li: int = r.closest_index_global(car.global_position)
		var d: float = r.dists[li]
		var v := Vector2(car.velocity.x, car.velocity.z).length()
		if car.wade_time > 0.0:
			wade_s += dt
			cap_wet = car._current_max_speed()
		if d >= m0 and d <= m1:
			sum += v
			n += 1
			top = maxf(top, v)
		if d > m1 + 5.0 or drv.done():
			break
	car.queue_free()
	await get_tree().physics_frame
	return {"mean": sum / maxf(float(n), 1.0), "top": top, "wade_s": wade_s,
		"vmax": vmax_dry, "cap": cap_wet}
