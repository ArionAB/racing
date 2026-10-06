extends Node
## Sonda bolovanului care cade de pe buza (4-A, Monument Valley, 6 oct 2026):
## `RimBoulderHazard` + `Car.crush(invert_steer)`.
##
## Mod SINTETIC (implicit, dreapta sintetica, hazardul pus de sonda):
##  (0) ceasul: la t=0 nimic (nicio piatra, umbra sau praf — liniste, memoria
##      `ceasul-porneste-in-prima-faza`); perioada nu imparte turul de ~70 s;
##      doua rulari cu acelasi hazard dau aceleasi cadre de eveniment;
##  (1) telegraful: umbra apare cu >= 1.2 s inainte de impact, cu praf pe creasta;
##  (2) piatra pleaca de SUS (centrul peste inaltimea crestei, pe X la creasta) si
##      ajunge pe asfalt, citit de pe nodul pietrei (nu din functiile hazardului);
##  (3) o masina parcata pe punctul de impact e STRIVITA exact la aterizare
##      (18.35 s = perioada - HOLD - CRUMBLE, derivat de mana): crush_time,
##      factor 0.70; una parcata la 7 m lateral NU e atinsa (se poate evita);
##  (4) inversarea: roata din fata a masinii lovite (`_wheel_steer`, derivata din
##      comanda DUPA inversare) are semn opus comenzii cat tine strivirea si
##      expira la exact `crush_seconds` (+-1 cadru de fizica);
##  (5) nu ramane obstacol: hazardul n-are niciun corp solid (doar Area3D), piatra
##      se sparge (invizibila) si nu mai loveste.
##  (6) viraj REAL: o masina in miscare cu volan +1 (stanga) are viteza unghiulara
##      pozitiva inainte, NEGATIVA in strivire, pozitiva dupa expirare.
##
## Mod `--pista` (Track19 reala): bolovanul din culoarul E.
##  (a) in gorge (fractia 0.33-0.42), pe asfalt, la > 40 m de bolovanul rostogolitor;
##  (b) traiectoria (nodul pietrei, nu functia) nu intra in perete: baza pietrei
##      >= cota terenului de sub ea (raycast) pe tot parcursul caderii;
##  (c) piatra pleaca de pe creasta (teren sub ea la <= 1.5 m de cota de start);
##  (d) emitorul de praf sta pe creasta (raycast sub el).
##
## `--sabotaj=invert` (hazard fara inversare), `--sabotaj=miss` (hazard mutat 6 m
## lateral: nu mai nimereste masina parcata), `--sabotaj=pista` (hazard rotit 90
## de grade pe Track19). Sonda TREBUIE sa pice. Cod: 1 = a picat (garda armata),
## 3 = a trecut (garda moarta), 2 = n-am masurat nimic. Fara sabotaj: 0 / 1.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 res://tools/ProbeRimBoulder.tscn [-- --pista] [-- --sabotaj=invert|miss|pista]

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
## Aterizarea, derivata de mana: perioada - HOLD(0.35) - CRUMBLE(0.3).
const LANDING_EXPECT: float = 19.0 - 0.35 - 0.3
const IMPACT_X: float = 3.0
const LANE_OTHER_X: float = -4.0

class Steer extends CarController:
	var steer: float = 1.0
	var throttle: float = 0.0
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle

var _sab: String = ""
var _pista: bool = false
var _fails: int = 0
var _measured: int = 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--pista":
			_pista = true
		elif a.begins_with("--sabotaj"):
			_sab = a.trim_prefix("--sabotaj=") if "=" in a else "all"
	if _sab == "pista":
		_pista = true
	print("=== BOLOVAN DE PE BUZA%s%s ===" % [" [pista]" if _pista else "",
		" (SABOTAJ %s)" % _sab if _sab != "" else ""])
	if _pista:
		await _run_pista()
	else:
		await _run_synthetic()
	_finish()


func _verdict(ok: bool, text: String) -> void:
	_measured += 1
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _finish() -> void:
	if _measured == 0:
		print("PICAT: n-am masurat nimic")
		get_tree().quit(2)
		return
	if _sab != "":
		if _fails > 0:
			print("SABOTAJ: garda a PICAT (%d verdicte) -> armata" % _fails)
			get_tree().quit(1)
		else:
			print("SABOTAJ: garda a TRECUT -> MOARTA")
			get_tree().quit(3)
		return
	print("VERDICT: ", "OK" if _fails == 0 else "PROBLEME (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)


# ------------------------------------------------------------------ sintetic

func _make_track() -> TrackFromPath:
	var track := TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	track.add_child(path)
	track.custom_name = "ProbeRimBoulder"
	track.custom_theme = "forest"
	track.custom_half_width = 10.0
	add_child(track)
	return track


func _car(track: Track, at: Vector3, steer: float, throttle: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = track
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.route = 0
	car.road_index = track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	var ctl := Steer.new()
	ctl.steer = steer
	ctl.throttle = throttle
	car.set_controller(ctl)
	return car


func _hazard(at: Vector3) -> RimBoulderHazard:
	var hz := RimBoulderHazard.new()
	hz.position = at
	if _sab == "invert" or _sab == "all":
		hz.invert_steer = false
	add_child(hz)
	return hz


## Ruleaza un ciclu complet si intoarce evenimentele (secunde de la start).
func _cycle(track: Track) -> Dictionary:
	var shift := 6.0 if (_sab == "miss" or _sab == "all") else 0.0
	var hz := _hazard(Vector3(IMPACT_X + shift, 0.0, 0.0))
	var hit_car := _car(track, Vector3(IMPACT_X, 0.7, 0.0), 1.0, 0.0)
	var other := _car(track, Vector3(LANE_OTHER_X, 0.7, 0.0), 1.0, 0.0)
	var ev := {"shadow": -1.0, "rock": -1.0, "hit": -1.0, "hit_other": -1.0,
		"inv_end": -1.0, "dust_t": -1.0}
	var steer_before := 0.0
	var steer_during := 0.0
	var steer_after := 0.0
	var rock_y_start := 0.0
	var rock_x_start := 0.0
	var rock_y_land := INF
	var start_shadow := hz._shadow.visible
	var start_rock := hz._rock.visible
	var start_dust := hz._rim_dust.emitting
	var max_inv := 0.0
	var crush_factor_seen := 1.0
	var frames := int(19.0 * 60.0) + 120
	for i in frames:
		await get_tree().physics_frame
		var t := float(i + 1) / 60.0
		if ev["shadow"] < 0.0 and hz._shadow.visible:
			ev["shadow"] = t
		if ev["dust_t"] < 0.0 and hz._rim_dust.emitting:
			ev["dust_t"] = t
		if ev["rock"] < 0.0 and hz._rock.visible:
			ev["rock"] = t
			rock_y_start = hz._rock.position.y
			rock_x_start = hz._rock.position.x
		if hz._rock.visible and hz._rock.position.y < rock_y_land:
			rock_y_land = hz._rock.position.y
		if ev["hit"] < 0.0 and hit_car.crush_time > 0.0:
			ev["hit"] = t
			crush_factor_seen = hit_car.crush_factor
		if ev["hit_other"] < 0.0 and other.crush_time > 0.0:
			ev["hit_other"] = t
		var ws: float = hit_car._wheel_steer
		if ev["hit"] < 0.0:
			steer_before = ws
		elif hit_car.steer_invert_left > 0.0:
			steer_during = ws
			max_inv = maxf(max_inv, hit_car.steer_invert_left)
		else:
			if ev["inv_end"] < 0.0:
				ev["inv_end"] = t
			steer_after = ws
	ev["steer_before"] = steer_before
	ev["steer_during"] = steer_during
	ev["steer_after"] = steer_after
	ev["rock_y_start"] = rock_y_start
	ev["rock_x_start"] = rock_x_start
	ev["rock_y_land"] = rock_y_land
	ev["start"] = [start_shadow, start_rock, start_dust]
	ev["factor"] = crush_factor_seen
	ev["max_inv"] = max_inv
	ev["hits"] = hz.hits
	var bodies := 0
	for c in hz.get_children():
		if c is PhysicsBody3D:
			bodies += 1
	ev["bodies"] = bodies
	ev["rock_hidden_end"] = not hz._rock.visible
	hit_car.queue_free()
	other.queue_free()
	hz.queue_free()
	await get_tree().physics_frame
	return ev


func _run_synthetic() -> void:
	var track := _make_track()
	await get_tree().process_frame
	await get_tree().physics_frame
	var a := await _cycle(track)
	var b := await _cycle(track)
	print("  evenimente (s): umbra %.2f | praf %.2f | piatra vizibila %.2f | lovitura %.2f | masina laterala %.2f | inversare expirata %.2f"
		% [a["shadow"], a["dust_t"], a["rock"], a["hit"], a["hit_other"], a["inv_end"]])

	print("--- (0) ceas")
	var st: Array = a["start"]
	_verdict(not st[0] and not st[1] and not st[2],
		"la t=0 nicio umbra, piatra sau praf (liniste la start)")
	_verdict(fmod(70.0, 19.0) > 1.0 and fmod(70.0, 19.0) < 18.0,
		"perioada 19 s nu imparte turul de ~70 s (70 mod 19 = %.1f)" % fmod(70.0, 19.0))
	_verdict(a["hit"] == b["hit"] and a["shadow"] == b["shadow"] and a["rock"] == b["rock"],
		"doua rulari, aceleasi cadre de eveniment (lovitura %.3f / %.3f)" % [a["hit"], b["hit"]])

	print("--- (1) telegraf")
	var lead: float = a["hit"] - a["shadow"]
	_verdict(a["shadow"] > 0.0 and lead >= 1.2,
		"umbra vizibila cu %.2f s inainte de impact (>= 1.2)" % lead)
	_verdict(a["dust_t"] > 0.0 and a["dust_t"] <= a["shadow"] + 0.05,
		"praful de pe creasta porneste odata cu umbra (%.2f vs %.2f)" % [a["dust_t"], a["shadow"]])

	print("--- (2) cade de sus")
	_verdict(a["rock_y_start"] >= 10.3 and a["rock_x_start"] >= 6.0,
		"piatra apare pe creasta (y %.1f >= 10.3, x %.1f >= 6.0)" % [a["rock_y_start"], a["rock_x_start"]])
	_verdict(a["rock_y_land"] < 1.6, "ajunge pe asfalt (centrul coboara la y %.2f)" % a["rock_y_land"])
	var fall_t: float = a["hit"] - a["rock"]
	var fall_expect := sqrt(2.0 * (float(a["rock_y_start"]) - 1.25) / 22.0)
	_verdict(absf(fall_t - fall_expect) < 0.25,
		"cadere libera: %.2f s masurat vs %.2f s din inaltimea masurata" % [fall_t, fall_expect])

	print("--- (3) strivire")
	_verdict(a["hit"] > 0.0 and absf(float(a["hit"]) - LANDING_EXPECT) <= 0.2,
		"masina de pe punctul de impact lovita la %.2f s (asteptat %.2f +-0.2)" % [a["hit"], LANDING_EXPECT])
	_verdict(absf(float(a["factor"]) - 0.70) < 0.01, "plafon strivit %.2f (cerut 0.70)" % a["factor"])
	_verdict(a["hit_other"] < 0.0, "masina parcata la 7 m lateral NU e lovita (se poate evita)")

	print("--- (4) inversare")
	_verdict(float(a["steer_before"]) > 0.1, "inainte de lovitura roata fata are semnul comenzii (%.2f)" % a["steer_before"])
	_verdict(float(a["steer_during"]) < -0.1, "in strivire semnul e INVERSAT (%.2f)" % a["steer_during"])
	_verdict(float(a["steer_after"]) > 0.1, "dupa expirare semnul revine (%.2f)" % a["steer_after"])
	var inv_dur: float = a["inv_end"] - a["hit"]
	_verdict(a["inv_end"] > 0.0 and absf(inv_dur - 1.75) <= 1.5 / 60.0 + 0.001,
		"inversarea dureaza %.3f s (crush_seconds 1.75, +-1 cadru)" % inv_dur)

	print("--- (5) nu ramane obstacol")
	_verdict(a["bodies"] == 0, "hazardul n-are corp solid (PhysicsBody3D: %d)" % a["bodies"])
	_verdict(a["rock_hidden_end"], "dupa spargere piatra e ascunsa")
	_verdict(a["hits"] == 1, "o singura lovitura pe ciclu (%d)" % a["hits"])

	print("--- (6) viraj real, masina in miscare")
	await _steer_real(track)


## Masina cu volan +1 in miscare: semnul vitezei unghiulare, inainte / in strivire / dupa.
func _steer_real(track: Track) -> void:
	var car := _car(track, Vector3(0.0, 0.7, 130.0), 1.0, 0.6)
	car.velocity = Vector3(0, 0, -14.0)
	for _i in 60:
		await get_tree().physics_frame
	var w_before := 0.0
	for _i in 20:
		await get_tree().physics_frame
		w_before += car.angular_velocity.y
	w_before /= 20.0
	car.crush(1.75, 1.0, Vector3(1.2, 0.6, 1.2), 1.0, false,
		not (_sab == "invert" or _sab == "all"))
	for _i in 30: # lasam masina sa raspunda
		await get_tree().physics_frame
	var w_during := 0.0
	for _i in 30:
		await get_tree().physics_frame
		w_during += car.angular_velocity.y
	w_during /= 30.0
	for _i in 70:
		await get_tree().physics_frame
	var w_after := 0.0
	for _i in 30:
		await get_tree().physics_frame
		w_after += car.angular_velocity.y
	w_after /= 30.0
	print("  viteza unghiulara medie: inainte %.2f | in strivire %.2f | dupa %.2f rad/s" % [w_before, w_during, w_after])
	_verdict(w_before > 0.05, "inainte: volan stanga vireaza la stanga (%.2f)" % w_before)
	_verdict(w_during < -0.02, "in strivire: aceeasi comanda vireaza la dreapta (%.2f)" % w_during)
	_verdict(w_after > 0.05, "dupa expirare: revine la stanga (%.2f)" % w_after)
	car.queue_free()


# --------------------------------------------------------------------- pista

func _run_pista() -> void:
	var idx := GameState.resolve_track_index(19)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 5:
		await get_tree().physics_frame
	var found := track.find_children("*", "RimBoulderHazard", true, false)
	if found.is_empty():
		print("PICAT: Track19 n-are RimBoulderHazard")
		get_tree().quit(2)
		return
	var hz := found[0] as RimBoulderHazard
	if _sab == "pista":
		hz.rotate_y(PI * 0.5)
		print("  sabotaj: hazard rotit 90 grade")
	hz.force_clock = 0.0
	await get_tree().physics_frame
	var space := track.get_world_3d().direct_space_state
	var gp := hz.global_position
	var i0 := track.closest_index_global(gp, 0)
	var frac := track.frac_at(i0, 0)
	var half := track.width_at(frac)
	var lat := absf(track.lateral_distance(i0, gp, 0))
	print("  hazard la (%.1f, %.1f, %.1f), fractia %.3f, lateral %.2f, semilatime %.2f"
		% [gp.x, gp.y, gp.z, frac, lat, half])
	_verdict(frac >= 0.33 and frac <= 0.42, "in gorge E (fractia %.3f in 0.33-0.42)" % frac)
	_verdict(lat <= half, "punctul de impact e pe asfalt (lateral %.2f <= %.2f)" % [lat, half])
	var rolling_d := INF
	for n in track.find_children("*", "RockfallHazard", true, false):
		rolling_d = minf(rolling_d, (n as Node3D).global_position.distance_to(gp))
	_verdict(rolling_d > 40.0, "la %.0f m de bolovanul rostogolitor din E (> 40)" % rolling_d)

	# Traiectoria, citita de pe nodul pietrei la ceasul fortat.
	var tl := hz.landing_time()
	var tf := hz.fall_time()
	var worst := INF
	var start_gap := INF
	var worst_k := -1
	for k in 41:
		var t := tl - tf + tf * float(k) / 40.0
		hz.force_clock = t
		await get_tree().physics_frame
		var rp := hz._rock.global_position
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(
			rp + Vector3.UP * 40.0, rp + Vector3.DOWN * 60.0))
		if hit.is_empty():
			continue
		var gy: float = hit["position"].y
		if rp.y - hz._radius * 0.9 - gy < worst:
			worst = rp.y - hz._radius * 0.9 - gy
			worst_k = k
		if k == 0:
			start_gap = rp.y - hz._radius - gy
	_verdict(worst >= -0.05, "traiectoria nu intra in perete/sol (baza pietrei peste teren cu min %.2f m la pasul %d/40)" % [worst, worst_k])
	_verdict(start_gap <= 1.5 and start_gap >= -0.2,
		"piatra porneste de pe creasta (%.2f m deasupra terenului de sub ea)" % start_gap)
	var dp := hz._rim_dust.global_position
	var dh := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		dp + Vector3.UP * 5.0, dp + Vector3.DOWN * 30.0))
	var dgap: float = dp.y - float(dh["position"].y) if not dh.is_empty() else INF
	_verdict(dgap >= -0.3 and dgap <= 1.0, "praful sta pe creasta (%.2f m deasupra terenului)" % dgap)
