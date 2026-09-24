extends Node
## Garda traiectoriei de teren a avalansei: dovada ca masa CHIAR aluneca pe
## versant si nu pluteste deasupra lui / nu se ingroapa in el.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAvalancheTerrain.tscn -- <index_pista> [--dbg]
##
## `index_pista`: acceptat ca in restul uneltelor, prin `GameState.resolve_track_index`
## — pozitie in `TRACK_SCENES` SAU numarul din numele scenei (16 → Track16,
## adica Fiordland e si pozitia 9 si numarul 16, ambele rezolva la fel; vezi
## nota din `game_state.gd` despre cele doua conventii). Implicit 9 (Fiordland,
## pozitia ei in TRACK_SCENES).
##
## Ruleaza CA SCENA (nu --script): incarca pista reala din `res://scenes/tracks`,
## are nevoie de autoload-uri.
##
## ############################################################################
## CE VERIFICA
##
## Gasesc avalansa pe pista, o las sa parcurga cateva cicluri complete (fara
## masina — nu ne intereseaza impactul aici, doar traiectoria masei), si la
## fiecare cadru fizic din faza SWEEP masor diferenta dintre cota centrului
## gramezii (`_mass.position.y`) si cota terenului chiar sub el + inaltimea de
## asezare (`_sample_ground(x) + radius*0.72`, aceeasi formula din
## `_phase_sweep`). Pe portiunea de panta (nu langa axa drumului, unde cota
## tinde spre 0 oricum), un gap mare inseamna ca masa fie pluteste in aer, fie
## e ingropata — exact bug-ul raportat pe Fiordland/Alpi inainte de fix.
##
## Raportez: gap maxim absolut pe toata traversarea, X-ul de start ales, si
## inaltimea reala de start fata de sosea (`start.y`).
## ############################################################################

var _track: Track
var _av: AvalancheHazard
var _dbg := false
var _max_gap := 0.0
var _max_gap_x := 0.0
var _samples := 0
var _time := 0.0
var _watch_cycles := 0
const WATCH_CYCLES: int = 2


func _ready() -> void:
	_dbg = "--dbg" in OS.get_cmdline_user_args()
	var args := OS.get_cmdline_user_args()
	var n := 9 # Fiordland implicit
	for a in args:
		if a != "--dbg":
			n = a.to_int()
			break

	var idx := GameState.resolve_track_index(n)
	if idx < 0:
		print("PICAT: nu am gasit pista pentru '%d'" % n)
		get_tree().quit(1)
		return
	print("pista rezolvata: %s" % GameState.track_label(idx))

	_track = (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(_track)
	for i in 30:
		await get_tree().physics_frame

	for child in _track.find_children("*", "AvalancheHazard", true, false):
		_av = child
	if _av == null:
		print("PICAT: pista '%s' nu are AvalancheHazard" % GameState.track_label(idx))
		get_tree().quit(1)
		return

	print("pista=%s frac(idx)=%.3f hw=%.1f period=%.1f" % [
		GameState.track_label(idx),
		_track.frac_at(_track.closest_index_global(_av.global_position)),
		_av.road_half_width, _av.period])

	# Fortam faza SWEEP acum, ca sa nu asteptam un ciclu intreg de TELEGRAPH.
	_av._time = _av.TELEGRAPH
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if _av == null:
		return
	_time += delta
	var hw := _av.road_half_width if _av.road_half_width > 0.0 else 10.0
	var phase := _av._last_phase
	if phase == 1 and _av._mass != null:
		var x: float = _av.to_local(_av._mass.global_position).x
		# Aceeasi formula ca in `_phase_sweep`: cota terenului + inaltimea de
		# asezare a centrului gramezii.
		var expected: float = _av._sample_ground(x) + _av._radius * 0.72
		var actual: float = _av._mass.position.y
		var gap := absf(actual - expected)
		_samples += 1
		if gap > _max_gap:
			_max_gap = gap
			_max_gap_x = x
		if _dbg and _samples % 10 == 0:
			print("x=%6.2f  actual=%7.2f  expected=%7.2f  gap=%.2f" % [x, actual, expected, gap])
	if phase == 2:
		_watch_cycles += 1
		if _watch_cycles >= WATCH_CYCLES:
			_report()
			return
		_av._time = _av.TELEGRAPH # sarim direct la urmatorul SWEEP


func _report() -> void:
	set_physics_process(false)
	var hw := _av.road_half_width if _av.road_half_width > 0.0 else 10.0
	var start: Vector3 = _av._start_point(hw)
	print("")
	print("=== Sonda AvalancheHazard: traiectorie pe teren ===")
	print("esantioane in SWEEP: %d" % _samples)
	print("start local = %s (x=%.1f, inaltime fata de sosea=%.2f m)" % [
		str(start), start.x, start.y])
	print("gap maxim |masa - (teren+baza)| = %.2f m (la x=%.1f)" % [_max_gap, _max_gap_x])
	print("")
	print("VERDICT: ", "OK" if _samples > 0 else "PROBLEME (nicio proba)")
	get_tree().quit(0 if _samples > 0 else 1)
