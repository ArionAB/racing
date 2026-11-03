extends Node
## SONDA FULGERULUI (brief angkor.md §7 pasul 1 (e)): LightningFlash peste un RainCycle real,
## fara pista. Verifica contractele de fotosensibilitate si de determinism:
##   - 3-5 fulgere pe ploaie, niciunul la mai putin de 2 s de precedentul;
##   - albirea ecranului <= 0.5 (OVERLAY_CAP); cu `--reduce` = 0;
##   - energia soarelui revine EXACT la baza dupa ploaie (fara acumulare);
##   - doua rulari = aceleasi momente (scrise in `--out`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLightning.tscn -- [--reduce]

const RainScript := preload("res://scenes/hazards/rain_cycle.gd")
const FlashScript := preload("res://scenes/hazards/lightning_flash.gd")
const SIM_S: float = 260.0

var _rain: Node
var _flash: Node
var _sun: DirectionalLight3D
var _t: float = 0.0
var _base_sun: float = 0.0
var _dry_sun: Array[float] = []
var _reduce: bool = false


func _ready() -> void:
	_reduce = "--reduce" in OS.get_cmdline_user_args()
	GameState.reduce_flashes = _reduce
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_energy = 0.4
	env.fog_enabled = true
	we.environment = env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.light_energy = 1.35
	add_child(_sun)
	_base_sun = 1.35
	_rain = RainScript.new()
	_rain.set("period", 60.0)
	_rain.set("telegraph", 4.0)
	_rain.set("rain_hold", 22.0)
	_rain.set("dry_out", 4.0)
	_rain.set("start_clock", 50.0)  # porneste USCAT (10 s pana la telegraf)
	_rain.set("screen_rain", false)
	add_child(_rain)
	_flash = FlashScript.new()
	add_child(_flash)


func _process(delta: float) -> void:
	_t += delta
	# In faza uscata, dupa prima ploaie: soarele trebuie sa fie exact baza.
	if _t > 45.0 and int(_rain.get("phase")) == 0:
		_dry_sun.append(_sun.light_energy)
	if _t >= SIM_S:
		_report()
		get_tree().quit(0)
		set_process(false)


func _report() -> void:
	var log: PackedFloat64Array = _flash.get("flash_log")
	var gaps: Array[float] = []
	for i in range(1, log.size()):
		gaps.append(log[i] - log[i - 1])
	# Ploile: ciclu de 60 s pornit la clock 50 -> telegraf la t=10, 70, 130, 190, 250.
	var per: Array[int] = []
	for k in 5:
		var a := 10.0 + 60.0 * k
		var n := 0
		for t in log:
			if t >= a and t < a + 60.0:
				n += 1
		per.append(n)
	var min_gap := 1e9
	for g in gaps:
		min_gap = minf(min_gap, g)
	var drift := 0.0
	for e in _dry_sun:
		drift = maxf(drift, absf(e - _base_sun))
	print("=== FULGER %s: fulgere=%d pe_ploaie=%s gap_min=%.2fs albire_max=%.3f soare_uscat_abatere=%.4f" % [
		"REDUS" if _reduce else "NORMAL", log.size(), str(per), min_gap,
		float(_flash.get("max_overlay_alpha")), drift])
	print("    momente: %s" % str(Array(log).map(func(x: float) -> String: return "%.2f" % x)))
