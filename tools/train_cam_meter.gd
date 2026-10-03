extends Node
## MASURATOR: cat din timp se vede trenul Sagano (Kyoto, POI G2) din camera
## REALA a jucatorului (ChaseCamera), pe tur. Nu numara instante: proiecteaza
## cutia trenului in camera la fiecare cadru fizic (memoria
## `efecte-invizibile-nu-se-numara`), cu ocluzie prin raycast spre centru/acoperis.
##
## Atasat de ProbeRace cu `--train-cam` (hook-ul e in `_setup_kyoto`):
##   ... -- --mode=race --track=11 --ai=0 --seed=S --seconds=260 --train-cam
##
## Metrici pe tur (un tur = o trecere a jucatorului peste frac 0):
##   in_cadru  = secunde cu cutia (macar un colt) in frustum
##   vizibil   = in cadru SI neocluzat (un raycast spre centru/acoperis ajunge)
##   citit     = vizibil SI inaltimea pe ecran >= READ_H (fractie din inaltimea ecranului)
## `faza@0.78` = pozitia trenului pe bucla (0..1) cand jucatorul trece de 0,78.

const READ_H: float = 0.06
const TRAIN_PATH := "DecorManual/ZoneG_Bambus/gTren96"

var race: Node
var mover: PathMover
var cam: Camera3D
var _local_box: AABB
var _model: Node3D
var _prev_frac: float = 0.0
var _lap: int = 0
var _laps: Array[Dictionary] = []
var _exclude: Array[RID] = []
var _crossed: Dictionary = {}
var _cue: TrainCue = null
var _seen_rel: int = 0
var _trace: bool = false


func setup(race_node: Node) -> void:
	race = race_node
	mover = race.track.get_node_or_null(TRAIN_PATH) as PathMover
	_new_lap()
	var cue := race.track.get_node_or_null("DecorManual/ZoneG_Bambus/TrenLaChemare") as TrainCue
	if cue != null and not OS.get_environment("TRAIN_LEAD").is_empty():
		cue.lead_m = float(OS.get_environment("TRAIN_LEAD"))
	_cue = cue
	if cue != null and OS.get_environment("TRAIN_CUE_OFF") == "1":
		cue.enabled = false # baseline: trenul liber pe bucla, ca inainte
		print("TRENCAM: TrainCue oprit (baseline)")
	for c in race.cars:
		_exclude.append((c as Car).get_rid())


func _new_lap() -> void:
	_laps.append({"in": 0.0, "vis": 0.0, "read": 0.0, "max_h": 0.0, "faza78": -1.0,
		"faza80": -1.0, "on_via": 0.0})
	_crossed.clear()


func _physics_process(delta: float) -> void:
	if mover == null or mover.body() == null:
		return
	cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	if _model == null:
		var piv := mover.body().get_child(0) as Node3D
		if piv == null or piv.get_child_count() == 0:
			return
		_model = piv.get_child(0) as Node3D
		_local_box = Track.model_aabb(_model)
		print("TRENCAM: cutie locala %s" % _local_box)
	var car: Car = race.player
	if _cue != null and _cue.releases != _seen_rel:
		_seen_rel = _cue.releases
		print("TRENCAM lansare #%d: t=%.1f dc=%.0f v_est=%.1f v_real=%.1f d_cross=%.0f" % [_seen_rel, _cue.last_release.x, _cue.last_release.y, _cue.last_release.z, car.horizontal_speed(), _cue.cross_dist()])
	var f: float = race.track.frac_at(car.road_index, car.route)
	if _prev_frac > 0.9 and f < 0.1:
		_lap += 1
		_new_lap()
	_prev_frac = f
	var st := _laps[_lap]
	var phase := fposmod(mover._dist / maxf(mover.curve.get_baked_length(), 1.0), 1.0)
	if f >= 0.78 and not _crossed.has("78"):
		_crossed["78"] = true
		st.faza78 = phase
	if f >= 0.80 and not _crossed.has("80"):
		_crossed["80"] = true
		st.faza80 = phase
	var xf := _model.global_transform
	var corners: Array[Vector3] = []
	for k in 8:
		var p := _local_box.position + Vector3(
			_local_box.size.x * float(k & 1), _local_box.size.y * float((k >> 1) & 1),
			_local_box.size.z * float((k >> 2) & 1))
		corners.append(xf * p)
	var center := xf * (_local_box.position + _local_box.size * 0.5)
	var top := xf * (_local_box.position + Vector3(_local_box.size.x * 0.5,
		_local_box.size.y, _local_box.size.z * 0.5))
	var vp := cam.get_viewport().get_visible_rect().size
	var in_front := 0
	var any_frustum := false
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for c in corners:
		if not cam.is_position_behind(c):
			in_front += 1
			var sp := cam.unproject_position(c)
			mn = Vector2(minf(mn.x, sp.x), minf(mn.y, sp.y))
			mx = Vector2(maxf(mx.x, sp.x), maxf(mx.y, sp.y))
		if cam.is_position_in_frustum(c):
			any_frustum = true
	var in_frame := any_frustum
	if not in_frame and in_front == 8:
		in_frame = mx.x > 0.0 and mn.x < vp.x and mx.y > 0.0 and mn.y < vp.y
	if not in_frame:
		return
	st["in"] += delta
	if center.y > 8.0:
		st.on_via += delta
	# Ocluzie: raycast din camera spre centru si spre acoperis.
	var space := cam.get_world_3d().direct_space_state
	var seen := false
	for target in [center, top]:
		var q := PhysicsRayQueryParameters3D.create(cam.global_position, target)
		q.exclude = _exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty() or (hit["position"] as Vector3).distance_to(target) < 2.5:
			seen = true
			break
	if OS.get_environment("TRAIN_TRACE") == "1" and _lap == 2 and Engine.get_physics_frames() % 10 == 0:
		print("TRACE f=%.4f cam_dist=%.0f seen=%s train=(%.0f,%.1f,%.0f)" % [f, cam.global_position.distance_to(center), seen, center.x, center.y, center.z])
	if not seen:
		return
	st.vis += delta
	var h := 0.0
	if in_front == 8:
		h = (minf(mx.y, vp.y) - maxf(mn.y, 0.0)) / vp.y
	st.max_h = maxf(st.max_h, h)
	if h >= READ_H:
		st.read += delta


func report() -> void:
	print("\n--- TREN din camera jucatorului (cutie %s, prag citit h>=%.0f%%) ---" % [
		_local_box.size, READ_H * 100.0])
	var tot_in := 0.0
	var tot_vis := 0.0
	var tot_read := 0.0
	var n := 0
	for i in _laps.size():
		var s := _laps[i]
		if i == 0 or (i == _laps.size() - 1 and s.faza78 < 0.0):
			continue # tur 0 = grila de start (jucatorul porneste la frac ~0,99); ultimul, neajuns la G
		n += 1
		tot_in += s["in"]
		tot_vis += s.vis
		tot_read += s.read
		print("TRENCAM tur %d: in_cadru %.1fs vizibil %.1fs citit %.1fs pe_viaduct_in_cadru %.1fs h_max %.0f%% faza@0.78=%.2f faza@0.80=%.2f" % [
			i, s["in"], s.vis, s.read, s.on_via, s.max_h * 100.0, s.faza78, s.faza80])
	print("TRENCAM total %d ture: in_cadru %.1fs vizibil %.1fs citit %.1fs (medie/tur %.1f / %.1f / %.1f)" % [
		n, tot_in, tot_vis, tot_read, tot_in / maxf(n, 1), tot_vis / maxf(n, 1),
		tot_read / maxf(n, 1)])
