class_name AIController
extends CarController
## Creier AI: urmareste centrul soselei cu doua puncte de tintire (aproape =
## directie, departe = anticiparea virajului), cu linie laterala proprie.
## Foloseste ACELASI sistem de drift CTR ca jucatorul — elibereaza inainte
## de backfire (banca de obicei nivelul 2; jucatorii buni il bat cu 3).

const LOOKAHEAD_NEAR: float = 24.0
const LOOKAHEAD_FAR: float = 55.0

var track: Track
var line_offset: float = 0.0

var _steer: float = 0.0
var _throttle: float = 1.0
var _drift: bool = false
var _stuck_time: float = 0.0
var _reverse_time: float = 0.0

func configure(race_track: Track, rng: RandomNumberGenerator) -> void:
	track = race_track
	line_offset = rng.randf_range(-0.35, 0.35)

func update(delta: float) -> void:
	if track == null or car == null:
		return
	var speed := car.horizontal_speed()

	# Anti-blocaj: mars inapoi scurt daca stam pe loc.
	if _reverse_time > 0.0:
		_reverse_time -= delta
		_throttle = -1.0
		_steer = 0.0
		_drift = false
		return
	if speed < 2.0:
		_stuck_time += delta
		if _stuck_time > 1.2:
			_reverse_time = 0.9
			_stuck_time = 0.0
	else:
		_stuck_time = 0.0

	var near := track.lookahead_point(car.road_index, LOOKAHEAD_NEAR, line_offset)
	var far := track.lookahead_point(car.road_index, LOOKAHEAD_FAR, line_offset)
	var fwd := -car.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var to_near := near - car.global_position
	to_near.y = 0.0
	var to_far := far - car.global_position
	to_far.y = 0.0
	# unghi cu semn fata de UP: pozitiv = tinta e la stanga = steer pozitiv
	var a_near := fwd.signed_angle_to(to_near.normalized(), Vector3.UP)
	var a_far := fwd.signed_angle_to(to_far.normalized(), Vector3.UP)

	_steer = clampf(a_near * 2.0, -1.0, 1.0)
	_throttle = 1.0
	if absf(a_far) > 0.9 and speed > car.max_speed * 0.5:
		_throttle = 0.2

	# Drift CTR: intra pe viraje sustinute, elibereaza cand virajul s-a
	# terminat SAU cand se apropie de backfire (banca nivelul atins).
	if not _drift:
		if absf(a_far) > 0.55 and speed > car.drift_min_speed * 1.2:
			_drift = true
	else:
		var turn_done := absf(a_far) < 0.18
		var near_backfire := car.drift_charge > car.drift_level_times[1] + 0.4
		if turn_done or near_backfire or speed < car.drift_min_speed * 0.7:
			_drift = false

func get_steer() -> float:
	return _steer

func get_throttle() -> float:
	return _throttle

func is_drift_pressed() -> bool:
	return _drift
