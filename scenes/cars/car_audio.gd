extends Node
## Vocile CONTINUE ale unei masini (docs/feel_checklist.md: engine-gears,
## toy-sound-palette, lift-pops, slip-squeal, surface-voice, turbo-event,
## sense-of-speed). Un copil al lui `Car`, creat de el; `Car._update_effects` ii
## da un tick pe cadru de fizica. Impacturile, razuirea, aterizarea si evenimentele
## de hazard NU sunt aici (le face celalalt constructor de audio).
##
## CE SE AUDE
##   - MOTOR: un tiuit electric de jucarie (RC), nu un V8. Cinci trepte inventate
##     din viteza: turatia urca in treapta, CADE la schimbare (cu o scurta taiere de
##     cuplu) si urca iar. Sarcina (gaz) face tiuitul mai tare si il acopera cu un
##     zumzet de angrenaje; la ridicarea piciorului ramane doar tiuitul, mai moale.
##     Jucatorul are DOUA straturi (tiuit + zumzet), adversarii UNUL (tiuitul).
##   - RATEURI la ridicarea gazului de la turatie mare (aleator, cu cooldown).
##   - DERAPAJ: scrasnet cu volum/pitch dupa alunecarea REALA a cauciucurilor; pe
##     sol afanat se transforma in sisait de pietris.
##   - SUPRAFATA (doar jucatorul): iarba, pietris/nisip, apa mica, cross-fade dupa
##     suprafata, volum dupa viteza; zdranganeala de bordura.
##   - TURBO (doar jucatorul): click la apasare, suvoi cat arde, sisait la capat.
##   - VANT (doar jucatorul): creste cu viteza, aproape mut sub jumatate din max.
##
## Totul trece prin bus-urile existente: `Engine` pentru motor, `SFX` pentru rest
## (volumele vin din setari). Costul pe mobil: jucator = 2 bucle de motor mereu
## pornite + cate 1 pentru fiecare efect ACTIV (cele inactive sunt oprite); fiecare
## adversar = 1 bucla de motor, restul doar cand chiar aluneca/rateaza.

enum Surface { NONE, GRASS, GRAVEL, WATER }

@export_group("Motor: trepte")
## Fractia din `max_speed` la care urca treapta 1->2, 2->3, ... (cinci trepte).
@export var gear_up_at: PackedFloat32Array = PackedFloat32Array([0.25, 0.45, 0.64, 0.82])
## Cat sub pragul de urcare trebuie sa cada viteza ca sa coboare treapta (fara
## ea, o viteza care sta pe prag ar tot schimba).
@export var gear_down_hysteresis: float = 0.035
## Turatia (0..1) imediat dupa schimbare, in treptele 2+. Cu cat mai jos, cu atat
## „caderea" de la schimbare se aude mai tare.
@export_range(0.0, 0.8, 0.01) var gear_rev_floor: float = 0.42
## Turatia pe care o ridica gazul cu masina pe loc (patinare de ambreiaj).
@export_range(0.0, 0.8, 0.01) var launch_rev: float = 0.35
## Secunde de taiere a cuplului la schimbare (sarcina cade la zero).
@export var shift_time: float = 0.14
## Cat de repede urmareste turatia tinta (1/s): in sus, in jos, si in jos in
## timpul schimbarii.
@export var rev_k_up: float = 10.0
@export var rev_k_down: float = 16.0
@export var rev_k_shift: float = 32.0

@export_group("Motor: pitch si volum")
## pitch_scale al tiuitului la turatie 0 si 1.
@export var whine_pitch: Vector2 = Vector2(0.62, 1.95)
## pitch_scale al zumzetului la turatie 0 si 1.
@export var whirr_pitch: Vector2 = Vector2(0.70, 1.70)
## Volumul tiuitului (dB) la turatie 0 si 1, fara sarcina.
@export var whine_db: Vector2 = Vector2(-20.0, -15.0)
## Cat adauga sarcina plina peste tiuit (dB).
@export var load_boost_db: float = 4.0
## Zumzetul la sarcina plina si turatie 1 (dB); la sarcina 0 e mut.
@export var whirr_full_db: float = -15.0
## Adversarii: mai incet cu atat, ca un grup de AI sa nu acopere jucatorul.
@export var ai_engine_offset_db: float = -4.0
## Cat de repede urmareste sarcina gazul (1/s): la apasare, la ridicare.
@export var load_k_up: float = 12.0
@export var load_k_down: float = 6.0

@export_group("Rateuri (lift-pops)")
## Gazul trebuie sa fi fost peste prima valoare si sa cada sub a doua.
@export var pop_lift_from: float = 0.6
@export var pop_lift_to: float = 0.2
## De la ce fractie din viteza maxima poate sa rateze.
@export_range(0.3, 1.0, 0.01) var pop_min_speed_frac: float = 0.7
## Sansa ca o ridicare eligibila sa rateze, si secunde minime pana la urmatorul
## (inmultite cu un factor 1.0..1.8 aleator, ca sa nu iasa un tipar).
@export_range(0.0, 1.0, 0.01) var pop_chance: float = 0.55
@export var pop_cooldown: float = 1.5
## Sansa unui al doilea rateu, la 70-160 ms dupa primul.
@export_range(0.0, 1.0, 0.01) var pop_double_chance: float = 0.45
## Volumul (dB): jucator, adversar apropiat.
@export var pop_db_player: float = -8.0
@export var pop_db_ai: float = -14.0
## Un adversar rateaza doar daca e la mai putin de atat de camera (m).
@export var pop_ai_range: float = 30.0

@export_group("Derapaj (slip-squeal)")
## Sub viteza asta (m/s) cauciucurile nu scrasnesc.
@export var slip_min_speed: float = 4.0
## Viteza laterala (m/s) la care incepe soapta si la care e scrasnet plin.
@export var slip_lat_lo: float = 2.0
@export var slip_lat_hi: float = 13.0
## Unghiul de derapaj (grade) la care incepe si la care e plin.
@export var slip_angle_lo: float = 6.0
@export var slip_angle_hi: float = 40.0
## Franare tare: decelerare (m/s^2) de la care scrasneste roata blocata, si
## nivelul (0..1) la decelerare mica / mare.
@export var brake_decel_min: float = 12.0
@export var brake_squeal_lo: float = 0.25
@export var brake_squeal_hi: float = 0.7
## Volum (dB) la alunecare ~0 si la alunecare plina; scrasnetul de asfalt si
## sisaitul de pietris.
@export var squeal_db: Vector2 = Vector2(-32.0, -8.0)
@export var squeal_pitch: Vector2 = Vector2(0.85, 1.40)
@export var hiss_db: Vector2 = Vector2(-32.0, -10.0)
@export var hiss_pitch: Vector2 = Vector2(0.90, 1.25)
## Adversarii scrasnesc mai incet (dB).
@export var ai_slip_offset_db: float = -4.0

@export_group("Suprafete")
## Volum (dB) al rularii la viteza mica si la 60% din max (si peste).
@export var roll_db: Vector2 = Vector2(-36.0, -13.0)
@export var roll_water_bonus_db: float = 2.0
@export var roll_pitch: Vector2 = Vector2(0.80, 1.30)
## Zdranganeala de bordura (dB / pitch dupa viteza).
@export var kerb_db: Vector2 = Vector2(-28.0, -9.0)
@export var kerb_pitch: Vector2 = Vector2(0.80, 1.50)

@export_group("Turbo si vant")
## Suvoiul turbo-ului (dB, la plin) si pitch dupa viteza.
@export var whoosh_db: float = -9.0
@export var whoosh_pitch: Vector2 = Vector2(0.90, 1.25)
## Cat trebuie sa fi ars turbo-ul (s) ca sa auzi sisaitul de la capat.
@export var release_min_burn: float = 0.25
## Vantul: fractia din max_speed la care incepe sa se aude si la care e plin;
## volumul (dB) la mut si la plin.
@export var wind_start_frac: float = 0.30
@export var wind_full_frac: float = 1.15
@export var wind_db: Vector2 = Vector2(-58.0, -12.0)
@export var wind_pitch: Vector2 = Vector2(0.85, 1.35)
## Cat creste vantul (0..1 din scara de volum) in aspiratia altei masini, la
## `draft` = 1; doar peste ~jumatate din viteza maxima.
@export_range(0.0, 0.5, 0.01) var wind_draft_swell: float = 0.15

# --- Stare publica (o citesc sondele) ---
var car: Car
## Treapta curenta (1..5) si de cate ori s-a urcat treapta de la creare.
var gear: int = 1
var shifts: int = 0
## Turatia (0..1, putin peste cu turbo) si sarcina (0..1), netezite.
var rev: float = 0.0
var load_amount: float = 0.0
## Cat de tare aluneca (0..1, netezit) si cat din el e pe sol afanat.
var slip_amount: float = 0.0
var loose_blend: float = 0.0
## Contoare pentru sonde: rateuri redate, clickuri/sisaituri de turbo.
var pops_fired: int = 0
var turbo_clicks: int = 0
var release_hisses: int = 0
## Suprafata sub roti in ultimul tick.
var surface: Surface = Surface.NONE
## Bordura: vezi `set_on_kerb`.
var on_kerb: bool = false

## Cusaturi pentru sonde (pista lipseste in teste): -1 = automat.
var override_loose: int = -1
var override_surface: int = -1
## Generatorul rateurilor: o sonda ii pune o samanta.
var rng := RandomNumberGenerator.new()

# --- Playere (create la nevoie) ---
var whine: AudioStreamPlayer3D
var whirr: AudioStreamPlayer3D
var squeal: AudioStreamPlayer3D
var hiss: AudioStreamPlayer3D
var kerb: AudioStreamPlayer3D
var wind: AudioStreamPlayer
var whoosh: AudioStreamPlayer
var roll: Dictionary = {} # Surface -> AudioStreamPlayer3D
var pops: Array[AudioStreamPlayer3D] = []

var _shift_left: float = 0.0
var _idle_t: float = 0.0
var _prev_thr: float = 0.0
var _prev_fwd: float = 0.0
var _decel: float = 0.0
var _pop_cd: float = 0.0
var _pop_second_left: float = -1.0
var _roll_w: Dictionary = {Surface.GRASS: 0.0, Surface.GRAVEL: 0.0, Surface.WATER: 0.0}
var _kerb_w: float = 0.0
var _wind_gain: float = 0.0
var _whoosh_fade: float = 0.0
var _was_boosting: bool = false
var _boost_time: float = 0.0
var _grass_cache: int = -1 # -1 necalculat, 0 nisip/piatra, 1 iarba
var _grass_track: Track = null


func setup(owner_car: Car) -> void:
	car = owner_car
	rng.randomize()
	whine = _make_3d(&"engine_whine", &"Engine", -20.0, 60.0)
	whine.pitch_scale = whine_pitch.x
	whine.play()
	car.boost_started.connect(_on_boost_started)


## Un tick pe cadru de fizica. `on_road`/`loose` vin din `Car._update_effects`
## (suprafata se afla o data pe cadru, de acolo).
func tick(delta: float, on_road: bool, loose: bool) -> void:
	if car == null or whine == null:
		return
	var dt := minf(delta, 0.05)
	var rel := car.linear_velocity - car.ground_velocity()
	rel.y = 0.0
	var speed := rel.length()
	var basis := car.global_transform.basis
	var fwd_h := Vector3(-basis.z.x, 0.0, -basis.z.z).normalized()
	var fwd_speed := rel.dot(fwd_h)
	var thr := car.throttle_input
	if car.is_player:
		_ensure_player_layers()
	_update_engine(dt, speed, thr)
	_update_pops(dt, speed, thr)
	var is_loose := loose if override_loose < 0 else override_loose == 1
	_update_slip(dt, rel, fwd_h, fwd_speed, speed, is_loose)
	_prev_fwd = fwd_speed
	_prev_thr = thr
	if car.is_player:
		surface = _surface_kind(on_road, is_loose)
		_update_roll(dt, speed)
		# TODO(feel/handling-2): cand `Car.on_kerb` ajunge in aceasta ramura, inlocuieste
		# linia de mai jos cu `set_on_kerb(car.on_kerb)`. Pana atunci proprietatea lipseste:
		# garda `in` o sare, iar bordura o comanda cine apeleaza `set_on_kerb` (sondele).
		if &"on_kerb" in car:
			set_on_kerb(car.get(&"on_kerb") == true)
		_update_kerb(dt, speed)
		_update_wind(dt, speed)
		_update_turbo(dt, speed)


## Bordura sub roti? Porneste/opreste zdranganeala (volumul si pitch-ul urmeaza
## viteza). Apelabil de oriunde: azi il hraneste `tick`, din `Car.on_kerb`.
func set_on_kerb(on: bool) -> void:
	on_kerb = on


# ---------------------------------------------------------------- motorul

func _update_engine(dt: float, speed: float, thr: float) -> void:
	var gears := gear_up_at.size() + 1
	var x := speed / maxf(car.max_speed, 1.0)
	var g := gear
	while g < gears and x > gear_up_at[g - 1]:
		g += 1
	while g > 1 and x < gear_up_at[g - 2] - gear_down_hysteresis:
		g -= 1
	if g > gear:
		shifts += g - gear
		_shift_left = shift_time
	gear = g
	_shift_left = maxf(_shift_left - dt, 0.0)

	var lo := 0.0 if gear == 1 else gear_up_at[gear - 2]
	var hi := 1.0 if gear == gears else gear_up_at[gear - 1]
	var t := clampf((x - lo) / maxf(hi - lo, 0.01), 0.0, 1.25)
	var target := lerpf(0.0 if gear == 1 else gear_rev_floor, 1.0, t)
	if gear == 1:
		target = maxf(target, launch_rev * clampf(thr, 0.0, 1.0))
	if car.is_boosting:
		target += 0.10
	# Rotile in aer + gaz: motorul scapa de sarcina si urla.
	if car.wheels_on_ground == 0 and thr > 0.1:
		target += 0.25
	target = clampf(target, 0.0, 1.15)
	var k := rev_k_up if target > rev else rev_k_down
	if _shift_left > 0.0 and target < rev:
		k = rev_k_shift
	rev = lerpf(rev, target, 1.0 - exp(-k * dt))

	# Sarcina: gazul, taiat la schimbare; turbo-ul e sarcina plina.
	var load_target := clampf(thr, 0.0, 1.0)
	if car.is_boosting:
		load_target = 1.0
	if _shift_left > 0.0:
		load_target = 0.0
	var lk := load_k_up if load_target > load_amount else load_k_down
	load_amount = lerpf(load_amount, load_target, 1.0 - exp(-lk * dt))

	# Mersul in gol are o usoara unduire, ca sa nu fie un ton mort.
	_idle_t += dt
	var wobble := 0.012 * sin(_idle_t * 9.0) * (1.0 - clampf(rev * 2.0, 0.0, 1.0))
	var offset := 0.0 if car.is_player else ai_engine_offset_db
	whine.pitch_scale = maxf(lerpf(whine_pitch.x, whine_pitch.y, rev) + wobble, 0.05)
	whine.volume_db = lerpf(whine_db.x, whine_db.y, clampf(rev, 0.0, 1.0)) \
		+ load_boost_db * load_amount + offset
	if whirr != null:
		whirr.pitch_scale = maxf(lerpf(whirr_pitch.x, whirr_pitch.y, rev), 0.05)
		var gl := load_amount * (0.3 + 0.7 * clampf(rev, 0.0, 1.0))
		whirr.volume_db = whirr_full_db + linear_to_db(maxf(gl, 0.001))


# ---------------------------------------------------------------- rateuri

func _update_pops(dt: float, speed: float, thr: float) -> void:
	_pop_cd = maxf(_pop_cd - dt, 0.0)
	if _pop_second_left >= 0.0:
		_pop_second_left -= dt
		if _pop_second_left < 0.0:
			_play_pop(0.9)
	var lifted := _prev_thr > pop_lift_from and thr < pop_lift_to
	if not lifted or _pop_cd > 0.0:
		return
	if not car.race_active or car.finished or car.wheels_on_ground == 0:
		return
	if speed < car.max_speed * pop_min_speed_frac:
		return
	if rng.randf() >= pop_chance:
		return
	if not car.is_player and not _near_camera(pop_ai_range):
		return
	_pop_cd = pop_cooldown * rng.randf_range(1.0, 1.8)
	_play_pop(1.0)
	if rng.randf() < pop_double_chance:
		_pop_second_left = rng.randf_range(0.07, 0.16)


func _play_pop(gain: float) -> void:
	var p: AudioStreamPlayer3D = null
	for q in pops:
		if not q.playing:
			p = q
			break
	if p == null:
		if pops.size() >= 2:
			p = pops[0]
		else:
			p = _make_3d(&"backfire", &"SFX", pop_db_player, 40.0)
			pops.append(p)
	p.pitch_scale = rng.randf_range(0.88, 1.22)
	p.volume_db = (pop_db_player if car.is_player else pop_db_ai) + linear_to_db(gain)
	p.play()
	pops_fired += 1


func _near_camera(range_m: float) -> bool:
	var vp := get_viewport()
	var cam := vp.get_camera_3d() if vp != null else null
	return cam != null and cam.global_position.distance_to(car.global_position) <= range_m


# ---------------------------------------------------------------- derapaj

func _update_slip(dt: float, rel: Vector3, fwd_h: Vector3, fwd_speed: float,
		speed: float, is_loose: bool) -> void:
	var s := 0.0
	var decel_raw := (_prev_fwd - fwd_speed) / maxf(dt, 0.0001)
	_decel = lerpf(_decel, decel_raw, 1.0 - exp(-15.0 * dt))
	if car.wheels_on_ground >= 2 and speed > slip_min_speed:
		var b := car.global_transform.basis
		var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
		var lat := absf(rel.dot(right))
		var along := absf(rel.dot(fwd_h))
		var ang := rad_to_deg(atan2(lat, along))
		var s_lat := smoothstep(slip_lat_lo, slip_lat_hi, lat)
		var s_ang := smoothstep(slip_angle_lo, slip_angle_hi, ang) \
			* clampf((speed - 3.0) / 12.0, 0.0, 1.0)
		s = maxf(s_lat, s_ang)
		# Roata blocata la franare tare (marsarierul nu conteaza: fwd_speed > 8).
		if car.throttle_input < 0.0 and fwd_speed > 8.0 and _decel > brake_decel_min:
			var kb := clampf((_decel - brake_decel_min) / 14.0, 0.0, 1.0)
			s = maxf(s, lerpf(brake_squeal_lo, brake_squeal_hi, kb))
	var sk := 16.0 if s > slip_amount else 8.0
	slip_amount = lerpf(slip_amount, s, 1.0 - exp(-sk * dt))
	loose_blend = lerpf(loose_blend, 1.0 if is_loose else 0.0, 1.0 - exp(-10.0 * dt))
	var offset := 0.0 if car.is_player else ai_slip_offset_db
	var squeal_amt := slip_amount * (1.0 - loose_blend)
	var hiss_amt := slip_amount * loose_blend
	squeal = _drive_loop(squeal, AudioManager.SKID_LOOP, squeal_amt, squeal_db, squeal_pitch, offset, 45.0)
	hiss = _drive_loop(hiss, AudioManager.stream(&"skid_gravel"), hiss_amt, hiss_db, hiss_pitch, offset, 45.0)


## Porneste/opreste o bucla pozitionala dupa `amount` (0..1) si ii pune volumul si
## pitch-ul. Creeaza playerul la prima nevoie; il opreste sub un prag, ca sa nu
## mixeze liniste.
func _drive_loop(p: AudioStreamPlayer3D, stream: AudioStream, amount: float,
		db: Vector2, pitch: Vector2, offset_db: float, max_dist: float) -> AudioStreamPlayer3D:
	if amount < 0.012:
		if p != null and p.playing:
			p.stop()
		return p
	if p == null:
		p = _make_3d_stream(stream, &"SFX", db.x, max_dist)
	if not p.playing:
		p.play()
	p.volume_db = lerpf(db.x, db.y, pow(amount, 0.8)) + offset_db
	p.pitch_scale = lerpf(pitch.x, pitch.y, amount)
	return p


# --------------------------------------------------------------- suprafete

func _surface_kind(on_road: bool, is_loose: bool) -> Surface:
	if override_surface >= 0:
		return override_surface as Surface
	if car.wheels_on_ground == 0:
		return Surface.NONE
	if car.in_water:
		return Surface.WATER
	if not is_loose:
		return Surface.NONE
	if on_road:
		return Surface.GRAVEL # drum de pamant/pietris
	return Surface.GRASS if _ground_is_grass() else Surface.GRAVEL


## Terenul de langa drum e iarba (verde) sau nisip/piatra/zapada? Din culoarea
## temei, ca sa nu tinem o lista de teme aici.
func _ground_is_grass() -> bool:
	var tr: Track = car.track
	if tr == null:
		return true
	if tr != _grass_track:
		_grass_track = tr
		var c := tr.theme_ground_tint
		_grass_cache = 1 if (c.g > c.r * 1.05 and c.g > c.b * 1.1) else 0
	return _grass_cache == 1


func _update_roll(dt: float, speed: float) -> void:
	var speed_k := smoothstep(1.0, car.max_speed * 0.6, speed)
	for s in [Surface.GRASS, Surface.GRAVEL, Surface.WATER]:
		var want := 1.0 if surface == s else 0.0
		var w: float = _roll_w[s]
		w = lerpf(w, want, 1.0 - exp(-9.0 * dt))
		_roll_w[s] = w
		var amount := w * (0.15 + 0.85 * speed_k) if speed > 1.0 else 0.0
		var p: AudioStreamPlayer3D = roll.get(s)
		if amount < 0.01:
			if p != null and p.playing:
				p.stop()
			continue
		if p == null:
			var nm: StringName = &"roll_grass"
			if s == Surface.GRAVEL:
				nm = &"roll_gravel"
			elif s == Surface.WATER:
				nm = &"roll_water"
			p = _make_3d(nm, &"SFX", roll_db.x, 45.0)
			roll[s] = p
		if not p.playing:
			p.play()
		p.volume_db = lerpf(roll_db.x, roll_db.y, speed_k) + linear_to_db(w) \
			+ (roll_water_bonus_db if s == Surface.WATER else 0.0)
		p.pitch_scale = lerpf(roll_pitch.x, roll_pitch.y, speed_k)


func _update_kerb(dt: float, speed: float) -> void:
	var want := 1.0 if on_kerb and speed > 2.0 else 0.0
	_kerb_w = lerpf(_kerb_w, want, 1.0 - exp(-30.0 * dt))
	if _kerb_w < 0.02:
		if kerb != null and kerb.playing:
			kerb.stop()
		return
	if kerb == null:
		kerb = _make_3d(&"kerb_rattle", &"SFX", kerb_db.x, 45.0)
	if not kerb.playing:
		kerb.play()
	var speed_k := smoothstep(2.0, car.max_speed * 0.8, speed)
	kerb.volume_db = lerpf(kerb_db.x, kerb_db.y, speed_k) + linear_to_db(_kerb_w)
	kerb.pitch_scale = lerpf(kerb_pitch.x, kerb_pitch.y, speed_k)


# -------------------------------------------------------------- vant, turbo

func _update_wind(dt: float, speed: float) -> void:
	var f := speed / maxf(car.max_speed, 1.0)
	var want := smoothstep(wind_start_frac, wind_full_frac, f)
	# Aspiratia (slipstream): `Car.draft` (0..1) vine din feel/handling-2; pana
	# ajunge in aceasta ramura `get` intoarce null si vantul ramane neschimbat.
	var dv: Variant = car.get(&"draft")
	var draft_amt := clampf(float(dv), 0.0, 1.0) if dv != null else 0.0
	want = minf(want + wind_draft_swell * draft_amt * smoothstep(0.4, 0.8, f), 1.0)
	_wind_gain = lerpf(_wind_gain, want, 1.0 - exp(-4.0 * dt))
	if _wind_gain < 0.01:
		if wind.playing:
			wind.stop()
		return
	if not wind.playing:
		wind.play()
	wind.volume_db = lerpf(wind_db.x, wind_db.y, pow(_wind_gain, 1.3))
	wind.pitch_scale = lerpf(wind_pitch.x, wind_pitch.y, clampf(f, 0.0, 1.2))


func _on_boost_started(_c: Car) -> void:
	if not car.is_player:
		return
	turbo_clicks += 1
	AudioManager.play_sfx(&"turbo_click", 1.0, -10.0)


func _update_turbo(dt: float, speed: float) -> void:
	var boosting := car.is_boosting
	if boosting:
		_boost_time += dt
	if _was_boosting and not boosting:
		if _boost_time >= release_min_burn:
			release_hisses += 1
			AudioManager.play_sfx(&"turbo_release", 1.0, -8.0)
		_boost_time = 0.0
	_was_boosting = boosting
	var k := 12.0 if boosting else 7.0
	_whoosh_fade = lerpf(_whoosh_fade, 1.0 if boosting else 0.0, 1.0 - exp(-k * dt))
	if _whoosh_fade < 0.01:
		if whoosh.playing:
			whoosh.stop()
		return
	if not whoosh.playing:
		whoosh.play()
	whoosh.volume_db = whoosh_db + linear_to_db(_whoosh_fade)
	whoosh.pitch_scale = lerpf(whoosh_pitch.x, whoosh_pitch.y,
		clampf(speed / maxf(car.max_speed * 1.2, 1.0), 0.0, 1.0))


# ------------------------------------------------------------------ unelte

## Straturile care exista doar la jucator: zumzetul motorului, vantul, suvoiul.
func _ensure_player_layers() -> void:
	if whirr != null:
		return
	whirr = _make_3d(&"engine_whirr", &"Engine", -40.0, 60.0)
	whirr.pitch_scale = whirr_pitch.x
	whirr.play()
	# Vantul si suvoiul sunt in capul jucatorului, nu in lume: playere 2D.
	wind = _make_2d(&"wind_loop", &"SFX", wind_db.x)
	whoosh = _make_2d(&"turbo_whoosh", &"SFX", whoosh_db)


func _make_3d(stream_name: StringName, bus: StringName, db: float,
		max_dist: float) -> AudioStreamPlayer3D:
	return _make_3d_stream(AudioManager.stream(stream_name), bus, db, max_dist)


func _make_3d_stream(stream: AudioStream, bus: StringName, db: float,
		max_dist: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = db
	p.max_distance = max_dist
	add_child(p)
	return p


func _make_2d(stream_name: StringName, bus: StringName, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = AudioManager.stream(stream_name)
	p.bus = bus
	p.volume_db = db
	add_child(p)
	return p
