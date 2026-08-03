extends Node
## Sonda pentru #29: praful de sub roti si leganatul vegetatiei.
##
## Nici una din cele doua nu se vede in `--mode=race`: AI-ul nu iese de pe
## sosea (offroad 0.0%), iar o captura statica nu poate arata o miscare.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLife.tscn

const RACE_SCENE: String = "res://scenes/race/Race.tscn"

var _race: Node = null
var _frames: int = 0
var _car: Car = null
var _seen_dust: bool = false
var _sway_span: float = 0.0
var _sway_first: float = INF
var _sway_last: float = 0.0
var _sway: SwayDriver = null


func _ready() -> void:
	GameState.selected_track = 0
	GameState.selected_car = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)


func _physics_process(delta: float) -> void:
	_frames += 1
	if _frames == 5:
		_car = _race.player as Car
		_sway = _race.track.find_child("Sway", true, false) as SwayDriver
		return
	if _car == null:
		return
	# Tinem masina in afara soselei si la viteza. Fara asta, conditia de praf
	# (roti pe sol + offroad + peste 6 m/s) nu se atinge niciodata: AI-ul din
	# --mode=race sta pe asfalt tot turul, offroad 0.0%.
	var track := _race.track as Track
	if _frames > 5 and _frames < 180:
		var p: Vector3 = track.baked[_car.road_index]
		var dir := -_car.global_basis.z
		var out := dir.cross(Vector3.UP).normalized()
		_car.global_position = p + out * (track.half_width + 6.0) \
			+ Vector3.UP * 0.35
		_car.velocity = dir * 22.0
	if _frames > 20 and _frames < 200:
		var dust := _find_dust(_car)
		if dust != null and dust.emitting:
			_seen_dust = true
	if _sway != null and _frames > 5:
		var yaw := _sway_sample()
		_sway_first = minf(_sway_first, yaw)
		_sway_last = maxf(_sway_last, yaw)
	if _frames >= 240:
		_report()


## Prima tufa INREGISTRATA, nu "prima cu yaw nenul": tufele au deja o rotatie
## aleatoare de baza, iar clusterele si cactusii din aceleasi benzi la fel, deci
## cautarea dupa yaw nenul intorcea alt obiect la fiecare cadru.
func _sway_sample() -> float:
	if _sway._items.is_empty():
		return 0.0
	# Leganarea e INCLINARE (X/Z), nu rotatie pe Y — vezi SwayDriver.
	return (_sway._items[0] as Node3D).rotation.x


func _find_dust(node: Node) -> CPUParticles3D:
	for c in node.get_children():
		var p := c as CPUParticles3D
		# Praful e singurul cu color_ramp; fumul si flacara n-au.
		if p != null and p.color_ramp != null:
			return p
	return null


func _report() -> void:
	print("=== #29 praf si miscare ===")
	print("  praf off-road emis        : %s" % ("DA" if _seen_dust else "NU"))
	var span := _sway_last - _sway_first
	print("  vegetatie, amplitudine tilt: %.4f rad (%.2f grade)"
		% [span, rad_to_deg(span)])
	print("  tufe inregistrate         : %d" % (_sway._items.size()
		if _sway != null else -1))
	var ok := _seen_dust and span > 0.02 and _sway != null \
		and _sway._items.size() > 0
	print("VERDICT: %s" % ("OK" if ok else "PROBLEME"))
	get_tree().quit(0 if ok else 1)
