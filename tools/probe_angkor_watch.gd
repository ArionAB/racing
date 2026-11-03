extends Node
## Observatorul sondelor Angkor (brief docs/track_briefs/angkor.md §7 pasul 1), pornit din
## ProbeRace cu `--angkor`. No-op pe orice alta pista: numara doar ce se intampla pe ea.
##
## Ce numara, per masina:
##   - STRIVIRILE (semnalul `crushed`): ruta (0 = principala, 1 = galeria) si fractia —
##     dominoul din galerie e singurul hazard cu strivire de pe pista-sonda;
##   - TRECERILE prin galerie (ruta 1 aparuta), ca rata de strivire sa aiba numitor;
##   - ZBORURILE: fiecare interval continuu fara `is_on_floor()` mai lung de 0,25 s, cu
##     fractia de plecare si durata (saritura Regelui Lepros + radacina-rampa);
##   - OPRIRILE in piata elefantului: secunde sub 3 m/s in fereastra de fractie data.
##
## Fractiile ferestrelor vin din argumente (`--angkor-elephant=a,b`, `--angkor-crest=a,b`),
## scrise de `tools/gen_angkor_sonda.py` (ramura `angkor/sonde`), nu ghicite aici.

const MIN_AIR_S: float = 0.25
const STOP_V: float = 3.0

var _race: Node
var _crush: Array = []       # [t, car, route, frac]
var _air: Array = []         # [car, frac_start, durata, route]
var _branch_passes: Array[int] = []
var _was_branch: Array[bool] = []
var _air_t: Array[float] = []
var _air_f: Array[float] = []
var _stop_s: Array[float] = []
var _t: float = 0.0
var elephant_win := Vector2(-1, -1)
var crest_win := Vector2(-1, -1)


func setup(race: Node) -> void:
	_race = race
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--angkor-elephant="):
			var p := arg.trim_prefix("--angkor-elephant=").split(",")
			elephant_win = Vector2(float(p[0]), float(p[1]))
		elif arg.begins_with("--angkor-crest="):
			var q := arg.trim_prefix("--angkor-crest=").split(",")
			crest_win = Vector2(float(q[0]), float(q[1]))
	var cars: Array[Car] = race.cars
	for i in cars.size():
		_branch_passes.append(0)
		_was_branch.append(false)
		_air_t.append(0.0)
		_air_f.append(0.0)
		_stop_s.append(0.0)
		cars[i].crushed.connect(func(c: Car, _sev: float) -> void:
			_crush.append([_t, i, c.route, _frac(c)]))


func _frac(c: Car) -> float:
	return _race.track.frac_at(c.road_index, c.route)


func _physics_process(delta: float) -> void:
	if _race == null:
		return
	_t += delta
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var c := cars[i]
		var on_b := c.route == 1
		if on_b and not _was_branch[i]:
			_branch_passes[i] += 1
		_was_branch[i] = on_b
		if c.is_on_floor():
			if _air_t[i] >= MIN_AIR_S:
				_air.append([i, _air_f[i], _air_t[i], c.route])
			_air_t[i] = 0.0
		else:
			if _air_t[i] == 0.0:
				_air_f[i] = _frac(c)
			_air_t[i] += delta
		if elephant_win.x >= 0.0 and c.route == 0:
			var f := _frac(c)
			if f >= elephant_win.x and f <= elephant_win.y and c.horizontal_speed() < STOP_V:
				_stop_s[i] += delta


func report() -> void:
	var cars: Array[Car] = _race.cars
	var passes := 0
	for p in _branch_passes:
		passes += p
	var crush_b := 0
	var crush_main := 0
	for e in _crush:
		if int(e[2]) == 1:
			crush_b += 1
		else:
			crush_main += 1
	print("=== ANGKOR galerie: treceri=%d striviri_galerie=%d striviri_principal=%d" % [
		passes, crush_b, crush_main])
	for e in _crush:
		print("    [strivire] t=%5.1fs %-18s ruta=%d frac=%.3f" % [
			float(e[0]), cars[int(e[1])].pilot_name, int(e[2]), float(e[3])])
	var crest_n := 0
	var crest_sum := 0.0
	var crest_max := 0.0
	for a in _air:
		var f: float = a[1]
		var in_crest := crest_win.x >= 0.0 and f >= crest_win.x and f <= crest_win.y \
				and int(a[3]) == 0
		if in_crest:
			crest_n += 1
			crest_sum += float(a[2])
			crest_max = maxf(crest_max, float(a[2]))
	print("=== ANGKOR creasta: zboruri=%d airtime_med=%.2fs airtime_max=%.2fs" % [
		crest_n, crest_sum / maxf(1.0, float(crest_n)), crest_max])
	for a in _air:
		print("    [zbor] %-18s ruta=%d frac=%.3f %.2fs" % [
			cars[int(a[0])].pilot_name, int(a[3]), float(a[1]), float(a[2])])
	var stop_tot := 0.0
	for s in _stop_s:
		stop_tot += s
	print("=== ANGKOR elefant: secunde_oprit_in_piata=%.1f (sub %.0f m/s, toate masinile)" % [
		stop_tot, STOP_V])
