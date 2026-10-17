class_name GhostRecorder
extends Node
## Inregistreaza traiectoria jucatorului in contratimp, la 20 Hz, din clipa GO.
## Copil al lui Race. Esantionarea e pe acumulator de `delta` in
## `_physics_process`, nu pe cadre: cu 60 fps fizici un esantion iese la fiecare
## 3 tick-uri, iar pe un device care scapa cadre ceasul ramane corect.

const RATE_HZ: int = 20

var target: Node3D
var _active: bool = false
var _accum: float = 0.0
var _samples: PackedFloat32Array = PackedFloat32Array()


func start() -> void:
	_samples = PackedFloat32Array()
	_accum = 0.0
	_active = true
	_sample() # eșantionul 0 = linia de start, la t = 0


func stop() -> void:
	_active = false


func sample_count() -> int:
	return _samples.size() / GhostData.FLOATS_PER_SAMPLE


func _physics_process(delta: float) -> void:
	if not _active or target == null:
		return
	_accum += delta
	var step := 1.0 / float(RATE_HZ)
	# `while`, nu `if`: un delta mare (cadru scapat) nu pierde esantioane.
	while _accum >= step:
		_accum -= step
		_sample()


func _sample() -> void:
	var t := target.global_transform
	var q := t.basis.get_rotation_quaternion()
	_samples.append_array(PackedFloat32Array([
		t.origin.x, t.origin.y, t.origin.z, q.x, q.y, q.z, q.w]))


## Datele gata de salvat; `total_ms` e timpul cursei (cronometrul Race).
func build_data(track_id: StringName, car_index: int, laps: int,
		total_ms: int) -> GhostData:
	var data := GhostData.new()
	data.track_id = track_id
	data.car_index = car_index
	data.laps = laps
	data.rate_hz = RATE_HZ
	data.total_ms = total_ms
	data.samples = _samples.duplicate()
	return data


func to_bytes() -> PackedByteArray:
	return build_data(&"", 0, 1, 0).to_bytes()


static func from_bytes(bytes: PackedByteArray) -> GhostData:
	return GhostData.from_bytes(bytes)
