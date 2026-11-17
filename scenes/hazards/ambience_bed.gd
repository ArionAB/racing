class_name AmbienceBed
extends Node
## Strat de ambianta al pistei: o bucla discreta de fundal (Angkor: cicade si
## pasari) si, optional, un al doilea strat care urmeaza ploaia (`RainCycle.rain_factor`).
##
## E un nod mic pus de generatorul pistei, nu un sistem: pistele fara el raman
## cum erau. Ambele playere merg pe bus-ul `SFX`, deci volumul din setari se aplica,
## si sunt NEpozitionale (ambianta nu are o sursa). Nivelurile sunt mici ca sa nu
## acopere tonul motorului pe difuzorul unui telefon; bucla de zgomot are varful
## la ~0.5 din scala, iar `bed_db` o aduce si mai jos.

## Bucla de fundal (`AudioStreamWAV`; daca nu e deja in bucla, nodul o seteaza).
@export var bed_stream: AudioStream = null
## Nivelul buclei de fundal (dB).
@export var bed_db: float = -17.0
## Bucla de ploaie, audibila doar cat ploua (gol = fara strat de ploaie).
@export var rain_stream: AudioStream = null
## Nivelul ploii la `rain_factor` 1 (dB).
@export var rain_db: float = -16.0
## Cat dureaza intrarea / iesirea unui strat (s).
@export var fade_seconds: float = 1.5
## ZONA (optionala, San Francisco: zumzetul cablului pe strada tramvaiului): o polilinie in
## lume. Goala = bucla se aude peste tot, ca pana acum (Angkor neatins). Cu puncte, nivelul
## buclei de fundal urmeaza distanta ORIZONTALA a urechii (camera activa) pana la linie:
## plin pana la `zone_full_m`, mut de la `zone_silent_m`, liniar intre ele; cat e mut,
## playerul e oprit (nu se mixeaza degeaba pe telefon).
@export var zone_line: PackedVector3Array = PackedVector3Array()
@export var zone_full_m: float = 14.0
@export var zone_silent_m: float = 45.0
## Urechea, pentru sonde; gol = camera activa a viewport-ului.
var ear: Node3D = null
## Ultimul factor de zona (0..1), pentru sonde.
var zone_factor: float = 1.0

var bed_player: AudioStreamPlayer = null
var rain_player: AudioStreamPlayer = null

var _rain: RainCycle = null
var _bed_gain: float = 0.0
var _rain_gain: float = 0.0


func _ready() -> void:
	bed_player = _make_player(bed_stream)
	rain_player = _make_player(rain_stream)
	if bed_player != null and zone_line.is_empty():
		bed_player.play()
	_hook.call_deferred()


func _make_player(stream: AudioStream) -> AudioStreamPlayer:
	if stream == null:
		return null
	var wav := stream as AudioStreamWAV
	if wav != null and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		@warning_ignore("integer_division")
		wav.loop_end = wav.data.size() / 2 # cadre (16-bit mono)
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = &"SFX" if AudioServer.get_bus_index(&"SFX") >= 0 else &"Master"
	p.volume_db = -80.0
	add_child(p)
	return p


func _hook() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(&"rain_cycle"):
		if n is RainCycle:
			_rain = n as RainCycle
			break


func _process(delta: float) -> void:
	var step := delta / maxf(fade_seconds, 0.05)
	if bed_player != null:
		if zone_line.is_empty():
			_bed_gain = minf(_bed_gain + step, 1.0)
			bed_player.volume_db = bed_db + linear_to_db(maxf(_bed_gain, 0.0001))
		else:
			zone_factor = _zone_factor()
			_bed_gain = move_toward(_bed_gain, zone_factor, step)
			if _bed_gain > 0.001:
				if not bed_player.playing:
					bed_player.play()
				bed_player.volume_db = bed_db + linear_to_db(_bed_gain)
			elif bed_player.playing:
				bed_player.stop()
				bed_player.volume_db = -80.0
	if rain_player != null:
		var want: float = _rain.rain_factor if _rain != null else 0.0
		_rain_gain = move_toward(_rain_gain, want, step)
		if _rain_gain > 0.001:
			if not rain_player.playing:
				rain_player.play()
			rain_player.volume_db = rain_db + linear_to_db(_rain_gain)
		elif rain_player.playing:
			rain_player.stop()


## Factorul zonei: 1 pana la `zone_full_m` de linie, 0 de la `zone_silent_m` (pe orizontala).
## Fara ureche (nicio camera): 0.
func _zone_factor() -> float:
	var e := ear
	if e == null or not is_instance_valid(e):
		var vp := get_viewport()
		e = vp.get_camera_3d() if vp != null else null
	if e == null:
		return 0.0
	var p := Vector2(e.global_position.x, e.global_position.z)
	var best := INF
	for i in zone_line.size() - 1:
		var a := Vector2(zone_line[i].x, zone_line[i].z)
		var b := Vector2(zone_line[i + 1].x, zone_line[i + 1].z)
		var ab := b - a
		var k := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * k))
	if zone_line.size() == 1:
		best = p.distance_to(Vector2(zone_line[0].x, zone_line[0].z))
	return clampf(inverse_lerp(zone_silent_m, zone_full_m, best), 0.0, 1.0)
