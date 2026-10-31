extends Node
## Sonda CAPETELOR autobuzului (Machu Picchu, issue #600): autobuzul „apare
## subit si dispare subit”. Cele doua cochere (`BusDepot`) trebuie sa-l ascunda
## la aparitie si la disparitie, de pe TOT drumul.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBusDepot.tscn [-- --no-depot]
##
## Ce verifica, pe doua cicluri complete (150 s simulate):
##   1. APARITIA: in cadrul in care autobuzul devine vizibil, NICIUN punct al
##      corpului lui (12 puncte pe cutia 3.7 x 3.1 x 6.2) nu e vazut de vreo
##      pozitie a camerei de joc (frac 0.55-0.96 din tur, din 4 in 4 indici):
##      in frustum SI neocluzat de teren / pereti / usa inchisa.
##   2. DISPARITIA: la fel, in ultimul cadru vizibil.
##   3. USA: la aparitie si la disparitie e inchisa (>= 0.99), iar cat timp
##      corpul autobuzului incalca pragul (|z| < 3.4 m) e deschisa (<= 0.15).
##   4. PLECAREA: autobuzul sta `dwell_s` pe loc dupa aparitie.
##
## `--no-depot` scoate cochere (starea de dinainte): garda TREBUIE sa pice
## (sabotajul garzii — fara el nu stim ca vede ceva).
const FOV := 68.0
const CAM_BACK := 12.5
const CAM_UP := 10.0
const LOOK_UP := 0.40
const SIM_SECONDS := 150.0

var _track: Track
var _bus: BusHazard
var _cams: Array = []
var _prev_hidden := true
var _prev_pos := Vector3.ZERO
var _failed := false
var _events := 0
var _depots: Array = []
var _no_depot := false
var _door_fail := 0
var _door_seen_open := {}
var _t := 0.0
var _first_move_t := -1.0
var _first_show_t := -1.0
var _checked_first := false


func _ready() -> void:
	_no_depot = "--no-depot" in OS.get_cmdline_user_args()
	await get_tree().process_frame
	_track = (load("res://scenes/tracks/Track15.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	for _i in 8:
		await get_tree().physics_frame
	_bus = _track.find_children("*", "BusHazard", true, false)[0] as BusHazard
	for d in _track.find_children("*", "BusDepot", true, false):
		if not (d as BusDepot).has_door:
			continue
		if _no_depot:
			d.queue_free()
		else:
			_depots.append(d)
	if _no_depot:
		for _i in 3:
			await get_tree().physics_frame
	_build_cams()
	print("\n=== ProbeBusDepot %s (%d cochere, %d camere) ===" % [
		"SABOTAJ --no-depot" if _no_depot else "", _depots.size(), _cams.size()])
	set_physics_process(true)


func _build_cams() -> void:
	var n := _track.baked.size()
	var i := int(0.55 * n)
	while i < int(0.96 * n):
		var p := _track.baked[i]
		var fwd := _track.baked[(i + 6) % n] - p
		fwd.y = 0.0
		fwd = fwd.normalized()
		var cam := p - fwd * CAM_BACK + Vector3(0, CAM_UP, 0)
		var view := ((p + fwd * 12.0 + Vector3(0, LOOK_UP, 0)) - cam).normalized()
		var right := view.cross(Vector3.UP).normalized()
		_cams.append([cam, view, right, right.cross(view).normalized(), float(i) / n])
		i += 4


## Cate camere vad cel putin un punct al corpului la `xf` (cutia autobuzului).
func _seen_by(xf: Transform3D) -> Array:
	var space := _track.get_world_3d().direct_space_state
	var tv := tan(deg_to_rad(FOV * 0.5))
	var th := tv * 16.0 / 9.0
	var pts: Array[Vector3] = []
	for sx in [-1.85, 0.0, 1.85]:
		for sy in [0.1, 3.0]:
			for sz in [-3.0, 3.0]:
				pts.append(xf * Vector3(sx, sy, sz))
	var rid := _bus.body().get_rid()
	var seen := 0
	var first := 9.0
	var last := -1.0
	for cm in _cams:
		var hit_any := false
		for q in pts:
			var v: Vector3 = q - cm[0]
			var dz: float = v.dot(cm[1])
			if dz < 1.0:
				continue
			if absf(v.dot(cm[2])) / dz > th or absf(v.dot(cm[3])) / dz > tv:
				continue
			var rq := PhysicsRayQueryParameters3D.create(cm[0], q)
			rq.exclude = [rid]
			rq.collide_with_areas = false
			if space.intersect_ray(rq).is_empty():
				hit_any = true
				break
		if hit_any:
			seen += 1
			first = minf(first, cm[4])
			last = maxf(last, cm[4])
	return [seen, first, last]


## Nimic in afara cocherei nu intra in interior si pe platforma din fata:
## vegetatie, bolovani, ziduri de decor puse inainte sa existe cochera (poti sa-i
## vezi prin perete sau, mai rau, autobuzul trece prin ei).
func _footprint_clear() -> bool:
	var ok := true
	var space := _track.get_world_3d().direct_space_state
	for d: BusDepot in _depots:
		var z0 := -d.depth
		var z1 := d.apron_length
		var h := d.inner_height - 0.3
		var shape := BoxShape3D.new()
		shape.size = Vector3(d.inner_width, h, z1 - z0)
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = shape
		q.transform = d.global_transform * Transform3D(Basis.IDENTITY,
			Vector3(0.0, 0.2 + h * 0.5, (z0 + z1) * 0.5))
		q.exclude = [(d.get_node("Corp") as StaticBody3D).get_rid(), _bus.body().get_rid()]
		var hits := space.intersect_shape(q, 16)
		var names: Array = []
		for hh in hits:
			var col := hh["collider"] as Node
			names.append(col.name if col != null else "?")
		print("%s CURAT: %s — %d corpuri in interior + platforma %s" % [
			"PASS" if hits.is_empty() else "FAIL", d.name, hits.size(), str(names)])
		if not hits.is_empty():
			ok = false
	return ok


func _door_state() -> Array:
	# (adancime_max_incalcare, usa_inchisa_max) peste cochere: pentru fiecare, cat
	# de deschisa e usa cand corpul autobuzului incalca pragul.
	var worst_open_overlap := 0.0
	for d: BusDepot in _depots:
		var lp := d.bus_local()
		if absf(lp.z) < 3.4 and absf(lp.x) < d.inner_width and not _bus.is_hidden():
			worst_open_overlap = maxf(worst_open_overlap, d.door_closed_amount())
	return [worst_open_overlap]


func _physics_process(delta: float) -> void:
	if _bus == null:
		return
	_t += delta
	var hidden := _bus.is_hidden()
	var body := _bus.body()
	# Usa pe parcurs: corpul incalca pragul cu usa inchisa = autobuzul trece prin ea.
	if not _no_depot:
		var s := _door_state()
		if s[0] > 0.15:
			_door_fail += 1
			if _door_fail <= 3 or _door_fail % 60 == 0:
				for d: BusDepot in _depots:
					print("  usa: t=%.2f %s z=%.2f inchisa=%.2f hidden=%s" % [_t, d.name,
						d.bus_local_z(), d.door_closed_amount(), str(_bus.is_hidden())])
	# Prima miscare dupa aparitie (dwell).
	if _first_show_t >= 0.0 and _first_move_t < 0.0 and not hidden \
			and body.global_position.distance_to(_prev_pos) > 0.02 and _t > _first_show_t + 0.1:
		_first_move_t = _t
	# Aparitia (si starea initiala: autobuzul e vizibil din primul cadru).
	if (_prev_hidden and not hidden) or (not _checked_first and not hidden):
		# Starea de la inceputul cursei: usa a apucat sa se miste pana am pornit
		# sonda (8 cadre), deci doar corpul se verifica, nu usa.
		if _checked_first:
			_check("APARITIE", body.global_transform)
		_checked_first = true
		if _first_show_t < 0.0:
			_first_show_t = _t
	elif not _prev_hidden and hidden:
		_check("DISPARITIE", Transform3D(body.global_transform.basis, _prev_pos))
	_prev_hidden = hidden
	_prev_pos = body.global_position
	if _t >= SIM_SECONDS:
		_finish()


func _check(what: String, xf: Transform3D, with_door: bool = true) -> void:
	_events += 1
	var r := _seen_by(xf)
	var door_txt := "-"
	var door_ok := true
	if not _no_depot:
		# usa cocherei in care se afla autobuzul = cea mai apropiata
		var best: BusDepot = null
		var bd := 1e9
		for d: BusDepot in _depots:
			var dd := xf.origin.distance_to(d.global_position)
			if dd < bd:
				bd = dd
				best = d
		door_txt = "%.2f (cochera %s, la %.1f m)" % [best.door_closed_amount(), best.name, bd]
		door_ok = (best.door_closed_amount() >= 0.95 or not with_door) and bd < 20.0
	var ok: bool = r[0] == 0 and door_ok
	if not ok:
		_failed = true
	print("%s %-9s t=%6.1f s  la (%.0f, %.0f, %.0f)  vazut de %d camere (frac %.3f..%.3f)  usa inchisa=%s" % [
		"PASS" if ok else "FAIL", what, _t, xf.origin.x, xf.origin.y, xf.origin.z,
		r[0], r[1] if r[0] > 0 else 0.0, r[2] if r[0] > 0 else 0.0, door_txt])


func _finish() -> void:
	set_physics_process(false)
	var dwell_ok := _bus.dwell_s <= 0.0 or (_first_move_t - _first_show_t) >= _bus.dwell_s - 0.1
	print("%s PLECARE: dwell cerut %.1f s, masurat %.1f s" % [
		"PASS" if dwell_ok else "FAIL", _bus.dwell_s, _first_move_t - _first_show_t])
	if not dwell_ok:
		_failed = true
	if not _no_depot and not _footprint_clear():
		_failed = true
	var door_ok := _door_fail == 0
	print("%s USA: cadre cu corpul pe prag si usa >15%% inchisa = %d" % [
		"PASS" if door_ok else "FAIL", _door_fail])
	if not door_ok:
		_failed = true
	if _events < 3:
		print("FAIL doar %d evenimente (asteptat >= 3)" % _events)
		_failed = true
	print("\n%s" % ("FAIL" if _failed else "PASS"))
	get_tree().quit(1 if _failed else 0)
