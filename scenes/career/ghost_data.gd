class_name GhostData
extends RefCounted
## Fantoma unui contratimp: traiectoria mașinii jucătorului, eșantionată la
## `rate_hz`. Doar date — înregistrarea e în GhostRecorder, redarea în GhostCar.
##
## Format pe disc (StreamPeerBuffer, little-endian), ales în loc de
## `store_var` fiindcă are antet fix: se poate citi versiunea ÎNAINTE de orice
## altceva și se poate verifica lungimea exactă a șirului de eșantioane
## (un fișier trunchiat se respinge, nu se redă pe jumătate):
##   i32 version | utf8 string track_id | i32 car_index | i32 laps |
##   i32 rate_hz | i32 total_ms | i32 sample_count | sample_count * 7 * f32
## Un eșantion = origin.xyz + quaternion.xyzw.

const VERSION: int = 1
const FLOATS_PER_SAMPLE: int = 7

var version: int = VERSION
var track_id: StringName = &""
## Indexul în GameState.CAR_DATA: redarea folosește modelul acelei mașini.
var car_index: int = 0
var laps: int = 1
var rate_hz: int = 20
var total_ms: int = 0
var samples: PackedFloat32Array = PackedFloat32Array()


func sample_count() -> int:
	return samples.size() / FLOATS_PER_SAMPLE


func to_bytes() -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.put_32(version)
	buf.put_utf8_string(String(track_id))
	buf.put_32(car_index)
	buf.put_32(laps)
	buf.put_32(rate_hz)
	buf.put_32(total_ms)
	buf.put_32(sample_count())
	buf.put_data(samples.to_byte_array())
	return buf.data_array


## Versiunea din antet (primul i32), sau -1 daca fisierul e prea scurt.
## Separata de `from_bytes` ca apelantul sa deosebeasca "mai noua decat stiu"
## (nu se incarca, NU se suprascrie) de "stricata".
static func file_version(bytes: PackedByteArray) -> int:
	if bytes.size() < 4:
		return -1
	return bytes.decode_s32(0)


## Null daca versiunea nu e cea cunoscuta sau fisierul e corupt/trunchiat.
static func from_bytes(bytes: PackedByteArray) -> GhostData:
	if file_version(bytes) != VERSION:
		return null
	var buf := StreamPeerBuffer.new()
	buf.data_array = bytes
	buf.get_32()
	var data := GhostData.new()
	var id_res := buf.get_utf8_string()
	data.track_id = StringName(id_res)
	if buf.get_available_bytes() < 5 * 4:
		return null
	data.car_index = buf.get_32()
	data.laps = buf.get_32()
	data.rate_hz = buf.get_32()
	data.total_ms = buf.get_32()
	var count := buf.get_32()
	var byte_len := count * FLOATS_PER_SAMPLE * 4
	if count < 0 or data.rate_hz <= 0 or buf.get_available_bytes() != byte_len:
		return null
	if count > 0:
		data.samples = buf.get_data(byte_len)[1].to_float32_array()
	return data


func _origin_at(i: int) -> Vector3:
	var o := i * FLOATS_PER_SAMPLE
	return Vector3(samples[o], samples[o + 1], samples[o + 2])


func _rotation_at(i: int) -> Quaternion:
	var o := i * FLOATS_PER_SAMPLE
	return Quaternion(samples[o + 3], samples[o + 4], samples[o + 5], samples[o + 6])


## Pozitia fantomei la `ms` de la GO: liniar pe origin, slerp pe rotatie intre
## cele doua esantioane vecine. Inainte de primul = primul, dupa ultimul =
## ultimul (fantoma ramane pe linia de sosire, nu dispare).
func transform_at(ms: float) -> Transform3D:
	var n := sample_count()
	if n == 0:
		return Transform3D.IDENTITY
	var f := ms * float(rate_hz) / 1000.0
	if f <= 0.0:
		return Transform3D(Basis(_rotation_at(0)), _origin_at(0))
	if f >= float(n - 1):
		return Transform3D(Basis(_rotation_at(n - 1)), _origin_at(n - 1))
	var i := int(f)
	var t := f - float(i)
	var q := _rotation_at(i).slerp(_rotation_at(i + 1), t)
	return Transform3D(Basis(q), _origin_at(i).lerp(_origin_at(i + 1), t))
