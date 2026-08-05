extends SceneTree
## Profilul TRANSVERSAL al unei piste de insula: cat uscat are drumul in
## fiecare parte, si de unde incepe apa.
##
## De ce exista: scenografia unei piste de coasta se scrie in distante fata de
## sosea (tetrapozii la marginea apei, cheiul la mal, lanul pe platoul din
## interior), iar distantele alea nu se pot ghici din harta de referinta. Terenul
## real iese din `TrackSideSampler.ground_y` — dune, rapi, laguna sapata, banda
## de tarm — deci singura sursa cinstita pentru "unde e malul la fractia 0.09" e
## motorul, nu desenul. Fara sonda asta, primele cifre puse in `_scenography()`
## erau ghicite, si se vedea: barci pe uscat, ziduri in apa.
##
##   godot --headless --path . --script res://tools/probe_shore.gd -- --track=7
##   ... --step=0.01     rezolutia pe tur (implicit 0.02)
##   ... --max=90        cat de departe cauta malul (implicit 80 m)
##
## Coloanele: fractia, cota soselei, apoi pentru fiecare latura distanta de la
## AXA soselei pana la linia apei ("-" daca nu gaseste apa) si cota terenului la
## 15 / 30 / 50 m. Latura +1 e dreapta sensului de mers (pe Okinawa v2:
## interiorul buclei, adica laguna), -1 e exteriorul, adica largul.

const SEARCH_STEP: float = 1.0

var _path: String = ""
var _track: Node = null
var _frames: int = 0
var _step: float = 0.02
var _max: float = 80.0


func _initialize() -> void:
	var idx := 7
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--step="):
			_step = maxf(0.002, float(arg.trim_prefix("--step=")))
		elif arg.begins_with("--max="):
			_max = float(arg.trim_prefix("--max="))
	_path = "res://scenes/tracks/Track%02d.tscn" % idx
	if not ResourceLoader.exists(_path):
		push_error("probe_shore: nu exista %s" % _path)
		quit(1)


func _process(_delta: float) -> bool:
	if _track == null:
		_track = (load(_path) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false
	_frames += 1
	if _frames < 3:
		return false # lasam rebuild() sa termine
	_report()
	return true


func _report() -> void:
	var track := _track as Track
	var sampler: TrackSideSampler = track.get("_sampler")
	if sampler == null:
		push_error("probe_shore: pista nu are sampler")
		quit(1)
		return
	var sea_y: float = sampler.mean_road_y() + track.sea_level_offset
	print("=== PROFIL TRANSVERSAL: %s ===" % track.track_name)
	print("nivelul marii %.2f m · media soselei %.2f m · half_width %.1f m"
		% [sea_y, sampler.mean_road_y(), sampler.half_width()])
	print("frac   drum |  mal(+1)  y15   y30   y50 |  mal(-1)  y15   y30   y50")
	print("-".repeat(76))
	var n := sampler.point_count()
	var f := 0.0
	while f < 1.0:
		var i := int(f * float(n)) % n
		var p := sampler.baked_point(i)
		var right := sampler.side_at(i)
		var line := "%.3f %6.1f |" % [f, p.y]
		for s: float in [1.0, -1.0]:
			var out: Vector3 = right * s
			line += " %7s" % _shore_text(sampler, p, out, sea_y)
			for d: float in [15.0, 30.0, 50.0]:
				var q := p + out * d
				line += " %5.1f" % sampler.ground_y(q.x, q.z)
			line += " |"
		print(line)
		f += _step
	quit()


func _shore_text(sampler: TrackSideSampler, base: Vector3, out: Vector3,
		sea_y: float) -> String:
	var d := sampler.half_width()
	while d <= _max:
		var q := base + out * d
		if sampler.ground_y(q.x, q.z) <= sea_y:
			return "%.0f" % d
		d += SEARCH_STEP
	return "-"
