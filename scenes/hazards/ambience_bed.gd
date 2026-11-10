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

var bed_player: AudioStreamPlayer = null
var rain_player: AudioStreamPlayer = null

var _rain: RainCycle = null
var _bed_gain: float = 0.0
var _rain_gain: float = 0.0


func _ready() -> void:
	bed_player = _make_player(bed_stream)
	rain_player = _make_player(rain_stream)
	if bed_player != null:
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
		_bed_gain = minf(_bed_gain + step, 1.0)
		bed_player.volume_db = bed_db + linear_to_db(maxf(_bed_gain, 0.0001))
	if rain_player != null:
		var want: float = _rain.rain_factor if _rain != null else 0.0
		_rain_gain = move_toward(_rain_gain, want, step)
		if _rain_gain > 0.001:
			if not rain_player.playing:
				rain_player.play()
			rain_player.volume_db = rain_db + linear_to_db(_rain_gain)
		elif rain_player.playing:
			rain_player.stop()
