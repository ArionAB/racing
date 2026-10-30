extends Node
## Sonda montajului valului 1 al kitului Carrara pe Track23 (indexul 15).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCarraraMontaj.tscn -- <mod>
##
## Moduri (se pot combina):
##   --scan=f0,f1,df,lat0,lat1,dlat
##        grila de teren: pentru fiecare fractie (pe INDEX) si fiecare decalaj lateral
##        (m, + = DREAPTA sensului de mers) tipareste cota primului corp lovit de o raza
##        verticala si numele lui. Corpurile din DecorManual si cele ale hazardelor
##        montate se SAR (se masoara terenul, nu piesa pusa peste el).
##   --crane   derrick-ul (CraneHazard): turnul fata de axa, traseul sarcinii pe o
##             perioada intreaga (cat din latimea drumului matura, la ce cota trece
##             talpa sarcinii peste asfalt), colizorul picioarelor din spate.
##   --sled    sania (RockfallHazard cu `roll_model` stins): un ciclu intreg, abaterea
##             de la jgheab (traseul Path3D), golul sub talpi pe teren, trecerea
##             peste drum, perioada si rotatia acumulata.
##   --decor   fiecare piesa din DecorManual: cota terenului sub amprenta (min/medie/max
##             pe 9 puncte), cat pluteste / cat e ingropata, distanta pana la marginea
##             drumului (in plan, pe AABB-ul piesei).
##   --under   (cu --scan) sare si soseaua: terenul de sub pod.
##   --portals fiecare portal GLB: terenul sub stalpi (ce pluteste) si unde e fata ramei de beton
##             din cod fata de planul fetei GLB-ului (raza pe axa, la cota tavanului + 0,4).
##   --deck    viaductul: pe axa si pe +-4 m, cota asfaltului fata de cea mai inalta
##             fata a viaductului (nimic nu are voie sa iasa peste drum).
##
## Iese cu 1 daca un verdict pica sau daca un mod cerut n-a masurat nimic.

const TRACK_INDEX: int = 15

var _track: Track = null
var _space: PhysicsDirectSpaceState3D = null
var _fails: int = 0
## --under: scanul sare si soseaua (RoadTop/Shoulders/Parapet), ca sa vada terenul de SUB pod.
var _skip_road: bool = false


func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	var scene := load(GameState.TRACK_SCENES[TRACK_INDEX]) as PackedScene
	_track = scene.instantiate() as Track
	get_tree().root.add_child(_track)
	for i in 4:
		await get_tree().physics_frame
	_space = _track.get_world_3d().direct_space_state
	print("=== %s ===" % GameState.track_label(TRACK_INDEX))
	_skip_road = "--under" in args
	for a in args:
		if a.begins_with("--scan="):
			_scan(a.trim_prefix("--scan="))
	if "--deck" in args:
		_deck()
	if "--decor" in args:
		_decor()
	if "--portals" in args:
		_portals()
	if "--crane" in args:
		await _crane()
	if "--sled" in args:
		await _sled()
	print("")
	print("VERDICT: %s" % ("OK" if _fails == 0 else "PROBLEMA (%d)" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)


func _verdict(ok: bool, msg: String) -> void:
	print("    [%s] %s" % ["OK" if ok else "PICA", msg])
	if not ok:
		_fails += 1


# ------------------------------------------------------------- utilitare

func _route() -> TrackRoute:
	return _track.routes[0]


func _idx_at(frac: float) -> int:
	var n := _route().baked.size()
	return int(round(frac * float(n))) % n


## Un corp care NU e teren: decorul montat, hazardele (sarcina, sania, turnul).
func _skip_body(o: Object) -> bool:
	var n := o as Node
	if _skip_road and n != null and String(n.name) in ["RoadTop", "Shoulders", "Parapet", "RoadSkirt"]:
		return true
	while n != null and n != _track:
		if n.name == &"DecorManual" or n is CraneHazard or n is RockfallHazard:
			return true
		n = n.get_parent()
	return false


## Prima suprafata de sub punct care nu e decor/hazard: [y, nume] sau [NAN, ""].
func _ground(p: Vector3, up: float = 60.0, down: float = 120.0) -> Array:
	var ex: Array[RID] = []
	var from := Vector3(p.x, p.y + up, p.z)
	var to := Vector3(p.x, p.y - down, p.z)
	for k in 12:
		var q := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, ex)
		q.collide_with_areas = false
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return [NAN, ""]
		if _skip_body(hit.collider):
			ex.append(hit.rid)
			continue
		return [float(hit.position.y), String((hit.collider as Node).name)]
	return [NAN, ""]


func _road_y(i: int) -> float:
	return _route().baked[i].y


## Pozitia unui punct fata de axa: [index, lateral (+ dreapta), dist. in lungul axei].
func _road_frame(p: Vector3) -> Array:
	var r := _route()
	var i := r.closest_index_global(p)
	var b := r.baked[i]
	var side := r.side_at(i)
	var d := p - b
	d.y = 0.0
	var fwd := side.cross(Vector3.DOWN) # dreapta x jos = inainte
	return [i, d.dot(side), d.dot(fwd)]


# ----------------------------------------------------------------- scan

func _scan(spec: String) -> void:
	var v := spec.split_floats(",")
	if v.size() < 6:
		push_error("--scan cere f0,f1,df,lat0,lat1,dlat")
		_fails += 1
		return
	var r := _route()
	print("--- scan teren: frac %.3f..%.3f pas %.3f, lateral %.1f..%.1f pas %.1f (+ = dreapta)" % [
		v[0], v[1], v[2], v[3], v[4], v[5]])
	var lats: Array[float] = []
	var l := v[3]
	while l <= v[4] + 0.001:
		lats.append(l)
		l += v[5]
	var head := "  frac   x       z      drum  |"
	for la in lats:
		head += " %6.1f" % la
	print(head)
	var f := v[0]
	while f <= v[1] + 0.0001:
		var i := _idx_at(f)
		var b := r.baked[i]
		var side := r.side_at(i)
		var line := "  %.3f %7.1f %7.1f %5.1f |" % [f, b.x, b.z, b.y]
		var names := {}
		for la in lats:
			var g := _ground(b + side * la)
			line += " %6.1f" % float(g[0])
			names[g[1]] = true
		print(line + "   " + ",".join(names.keys()))
		f += v[2]


# ----------------------------------------------------------------- viaduct

func _deck() -> void:
	print("--- viaductul: asfaltul fata de fata de sus a viaductului (raza in jos, viaductul NU e sarit)")
	var via := _find_model("ponti_di_vara")
	if via == null:
		_verdict(false, "nu exista ponti_di_vara in DecorManual")
		return
	var r := _route()
	var worst := -INF
	var n_s := 0
	var n_road := 0
	for i in r.baked.size():
		var b := r.baked[i]
		var loc := via.global_transform.affine_inverse() * b
		if absf(loc.z) > 18.0 or absf(loc.x) > 6.0:
			continue
		var side := r.side_at(i)
		for la: float in [-4.0, -2.0, 0.0, 2.0, 4.0]:
			var p := b + side * la
			# Cea mai inalta fata a viaductului sub/peste punct: raza doar pe corpul lui.
			var top := _hit_only(p + Vector3.UP * 5.0, p + Vector3.DOWN * 30.0, "ponti_di_vara")
			var road := _ground(p, 3.0, 3.0)
			n_s += 1
			if is_nan(top):
				continue
			n_road += 1
			worst = maxf(worst, top - float(road[0]))
	print("    %d puncte pe drum peste viaduct, %d cu viaductul dedesubt; cea mai inalta fata a viaductului fata de asfalt: %+.3f m" % [
		n_s, n_road, worst])
	_verdict(n_road > 0, "viaductul e sub drum (%d puncte)" % n_road)
	_verdict(worst <= 0.0, "nimic din viaduct nu iese peste asfalt (max %+.3f m)" % worst)


## Cota primei fete a corpului de coliziune al piesei `stem` pe segmentul a-b.
func _hit_only(a: Vector3, b: Vector3, stem: String) -> float:
	var ex: Array[RID] = []
	for k in 16:
		var q := PhysicsRayQueryParameters3D.create(a, b, 0xFFFFFFFF, ex)
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var n := hit.collider as Node
		if n != null and String(n.name).begins_with(_find_model(stem).name):
			return float(hit.position.y)
		ex.append(hit.rid)
	return NAN


func _find_model(stem: String) -> Node3D:
	var dm := _track.get_node_or_null("DecorManual")
	if dm == null:
		return null
	for n in dm.find_children("*", "Node3D", true, false):
		if (n as Node3D).scene_file_path.get_file().get_basename() == stem:
			return n
	return null


# ----------------------------------------------------------------- decor

func _decor() -> void:
	var dm := _track.get_node_or_null("DecorManual")
	if dm == null:
		_verdict(false, "pista n-are DecorManual")
		return
	print("--- decor: cota terenului sub amprenta (9 puncte pe AABB-ul de lume), fata de baza piesei")
	print("    %-26s %-20s %7s %7s %7s %7s %7s %6s %7s" % ["nod", "model", "baza", "t_min", "t_med", "t_max", "pluteste", "ingrop", "margine"])
	print("    (pluteste = baza - terenul minim de sub amprenta; ingrop = (terenul maxim - baza) / inaltimea piesei)")
	var count := 0
	for n in dm.find_children("*", "Node3D", true, false):
		var m := n as Node3D
		if m.scene_file_path.is_empty():
			continue
		var stem := m.scene_file_path.get_file().get_basename()
		var box := _world_aabb(m)
		if box.size == Vector3.ZERO:
			continue
		count += 1
		var ys: Array[float] = []
		for u: float in [0.1, 0.5, 0.9]:
			for w: float in [0.1, 0.5, 0.9]:
				var p := Vector3(box.position.x + box.size.x * u, box.position.y + box.size.y, box.position.z + box.size.z * w)
				var g := _ground(p, 2.0, box.size.y + 80.0)
				if not is_nan(float(g[0])):
					ys.append(float(g[0]))
		var base := box.position.y
		var tmin: float = float(ys.min()) if not ys.is_empty() else NAN
		var tmax: float = float(ys.max()) if not ys.is_empty() else NAN
		var tmed := 0.0
		for y in ys:
			tmed += y
		tmed = tmed / maxf(ys.size(), 1)
		# Pluteste = baza peste terenul cel mai inalt de sub ea (nicio parte nu atinge);
		# ingropat = cat din inaltimea piesei e sub terenul MEDIU.
		# Pluteste = cat sta baza peste terenul cel mai JOS de sub amprenta (un colt in aer);
		# ingropat = cat din inaltimea piesei e sub terenul cel mai INALT (latura din deal).
		var floats: float = base - tmin
		var sunk: float = (tmax - base) / maxf(box.size.y, 0.01)
		var edge := _edge_gap(box)
		print("    %-26s %-20s %7.2f %7.2f %7.2f %7.2f %+7.2f %5.0f%% %7.2f" % [
			String(m.name).left(26), stem.left(20), base, tmin, tmed, tmax, floats, sunk * 100.0, edge])
	_verdict(count > 0, "%d piese masurate" % count)


## AABB-ul de lume al tuturor mesh-urilor vizibile ale modelului.
func _world_aabb(m: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for c in m.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if not mi.is_visible_in_tree() or mi.mesh == null:
			continue
		var bb := mi.global_transform * mi.mesh.get_aabb()
		if first:
			out = bb
			first = false
		else:
			out = out.merge(bb)
	return out


## Cea mai mica distanta in plan de la colturile/centrul AABB-ului la marginea drumului
## (negativ = in carosabil).
func _edge_gap(box: AABB) -> float:
	var r := _route()
	var best := INF
	for u: float in [0.0, 0.5, 1.0]:
		for w: float in [0.0, 0.5, 1.0]:
			var p := Vector3(box.position.x + box.size.x * u, box.position.y, box.position.z + box.size.z * w)
			var i := r.closest_index_global(p)
			var b := r.baked[i]
			var d := Vector2(p.x - b.x, p.z - b.z).length()
			best = minf(best, d - _track.width_at_index(i))
	return best


# ----------------------------------------------------------------- derrick

func _crane() -> void:
	var cranes := _track.find_children("*", "CraneHazard", true, false)
	if cranes.is_empty():
		_verdict(false, "niciun CraneHazard pe pista")
		return
	for c in cranes:
		var hz := c as CraneHazard
		print("--- derrick %s: period %.1f, phase %.2f, model_scale %.4f, hook_radius %.2f (raza %.2f m), turn %+d x %.1f, road_half_width %.2f" % [
			hz.name, hz.period, hz.phase, hz.model_scale, hz.hook_radius,
			hz.hook_radius * hz.model_scale, hz.tower_side, hz.tower_offset, hz.road_half_width])
		var mast := hz.get_node("Mast") as Node3D
		var mf := _road_frame(mast.global_position)
		var hw := _track.width_at_index(int(mf[0]))
		print("    turnul: lateral %+.2f m fata de axa (semilatimea drumului acolo %.2f), frac %.4f; baza turnului y %.2f, drumul %.2f, terenul sub turn %.2f" % [
			mf[1], hw, _route().frac_at(int(mf[0])), mast.global_position.y,
			_road_y(int(mf[0])), float(_ground(mast.global_position + Vector3.UP * 0.5, 2.0, 30.0)[0])])
		_verdict(float(mf[1]) < -hw - 1.0, "turnul e pe STANGA, in afara drumului (lateral %+.2f < -%.2f)" % [mf[1], hw + 1.0])
		# Axa nodului fata de tangenta drumului.
		var fwd := -hz.global_transform.basis.z
		var tang := _route().side_at(int(mf[0])).cross(Vector3.DOWN)
		var ang := rad_to_deg(acos(clampf(fwd.dot(tang), -1.0, 1.0)))
		print("    -Z al nodului fata de sensul de mers: %.1f grade" % ang)
		_verdict(ang < 8.0 or ang > 172.0, "nodul e aliniat cu drumul (%.1f grade)" % ang)
		# Picioarele din spate: colizorul pus pe instanta.
		var legs := hz.get_node_or_null("PicioareSpate") as StaticBody3D
		if legs == null:
			print("    (fara colizor pe picioarele din spate)")
		else:
			for s in legs.get_children():
				var cs := s as CollisionShape3D
				if cs == null:
					continue
				var bx := (cs.shape as BoxShape3D).size
				var gp := cs.global_position
				var lf := _road_frame(gp)
				print("    colizor %s: centru lateral %+.2f, de-a lungul %+.2f, cutie %.2f x %.2f x %.2f, marginea dinspre drum la %.2f m de axa" % [
					cs.name, lf[1], lf[2], bx.x, bx.y, bx.z, absf(float(lf[1])) - bx.x * 0.5])
		# O perioada intreaga, cadru cu cadru.
		var frames := int(hz.period * 60.0) + 30
		var lat_min := INF
		var lat_max := -INF
		var clear_min := INF
		var clear_max := -INF
		var over_road := 0
		var along: Array[float] = []
		var was_over := false
		for k in frames:
			await get_tree().physics_frame
			var lp := hz.load_body().global_position
			var lfr := _road_frame(lp)
			var lat := float(lfr[1])
			var on := absf(lat) <= _track.width_at_index(int(lfr[0]))
			if on:
				over_road += 1
				lat_min = minf(lat_min, lat)
				lat_max = maxf(lat_max, lat)
				var road := float(_ground(Vector3(lp.x, _road_y(int(lfr[0])) + 1.0, lp.z), 2.0, 6.0)[0])
				var clr := hz.load_bottom() - road
				clear_min = minf(clear_min, clr)
				clear_max = maxf(clear_max, clr)
				if not was_over:
					along.append(float(lfr[2]) + (_route().dists[int(lfr[0])] if _route().dists.size() > int(lfr[0]) else 0.0))
			was_over = on
		print("    sarcina peste drum: %d cadre din %d (%.1f s); lateral %+.2f .. %+.2f m; talpa sarcinii peste asfalt %.2f .. %.2f m; %d intrari peste drum" % [
			over_road, frames, over_road / 60.0, lat_min, lat_max, clear_min, clear_max, along.size()])
		_verdict(lat_min < -hw + 0.5 and lat_max > hw - 0.5, "sarcina matura AMBELE benzi (%+.2f .. %+.2f, semilatime %.2f)" % [lat_min, lat_max, hw])
		_verdict(clear_min > 0.35 and clear_max < 1.2, "talpa sarcinii la %.2f..%.2f m peste asfalt (contract ~0,6)" % [clear_min, clear_max])
		_verdict(along.size() == 2, "doua treceri pe perioada (%d)" % along.size())


# ----------------------------------------------------------------- sania

## Talpa de contact a saniei din kit (coordonate de MODEL; vezi probe_carrara_sled.gd).
const SLED_CONTACT: Array[Vector3] = [Vector3(-1.01, 0.0, 1.20), Vector3(1.01, 0.0, 1.20),
	Vector3(-1.01, 0.0, -0.70), Vector3(1.01, 0.0, -0.70)]


func _sled() -> void:
	var rocks := _track.find_children("*", "RockfallHazard", true, false)
	if rocks.is_empty():
		_verdict(false, "niciun RockfallHazard pe pista")
		return
	for rn in rocks:
		var hz := rn as RockfallHazard
		print("--- sania %s: roll_model %s, period %.2f s (traseu %.1f m, %.2f s de mers, pauza %.2f s), route_speed %.1f, cross_time %.2f s, raza %.3f" % [
			hz.name, str(hz.roll_model), hz.period, hz._route_len, hz._route_travel,
			hz.route_pause, hz.route_speed, hz.cross_time(), hz._radius])
		_verdict(not hz.roll_model, "roll_model stins (sania aluneca)")
		_verdict(absf(hz.period - 41.0) < 1.5, "ciclul ~41 s (%.2f)" % hz.period)
		var route := hz._route_local
		var frames := int(hz.period * 60.0) + 60
		var dev_max := 0.0
		var gap_max := -INF
		var gap_min := INF
		var on_road_t := 0
		var lat_min := INF
		var lat_max := -INF
		var visible_frames := 0
		var rot_acc := 0.0
		var prev_basis := Basis()
		var have_prev := false
		var road_heading_ang: Array[float] = []
		var bins := {}
		var bad_frames := 0
		var bad_lat_min := INF
		var bad_lat_max := -INF
		for k in frames:
			await get_tree().physics_frame
			var body := hz._rock
			if body == null or not body.visible or hz._model == null or not hz._model.is_visible_in_tree():
				have_prev = false
				continue
			visible_frames += 1
			var gp := body.global_position
			# Abaterea de la jgheab, in plan.
			var lp := hz.to_local(gp)
			var cp := route.get_closest_point(lp)
			dev_max = maxf(dev_max, Vector2(lp.x - cp.x, lp.z - cp.z).length())
			# Golul sub talpi.
			var mx := hz._model.global_transform
			var fr := _road_frame(gp)
			var frame_bad := false
			for c in SLED_CONTACT:
				var wp := mx * c
				var g := _ground(wp, 1.5, 20.0)
				if is_nan(float(g[0])):
					continue
				var gap := wp.y - float(g[0])
				gap_max = maxf(gap_max, gap)
				gap_min = minf(gap_min, gap)
				if absf(gap) > 0.15:
					frame_bad = true
			var lb := int(floor(float(fr[1]) / 2.0))
			var worst_c := 0.0
			for c in SLED_CONTACT:
				var wp2 := mx * c
				var g2 := _ground(wp2, 1.5, 20.0)
				if not is_nan(float(g2[0])) and absf(wp2.y - float(g2[0])) > absf(worst_c):
					worst_c = wp2.y - float(g2[0])
			if not bins.has(lb) or absf(worst_c) > absf(float(bins[lb])):
				bins[lb] = worst_c
			if frame_bad:
				bad_frames += 1
				bad_lat_min = minf(bad_lat_min, float(fr[1]))
				bad_lat_max = maxf(bad_lat_max, float(fr[1]))
			var hw := _track.width_at_index(int(fr[0]))
			if absf(float(fr[1])) <= hw:
				on_road_t += 1
				lat_min = minf(lat_min, float(fr[1]))
				lat_max = maxf(lat_max, float(fr[1]))
				if road_heading_ang.is_empty() and hz._move_dir.length() > 0.1:
					var tang := _route().side_at(int(fr[0])).cross(Vector3.DOWN)
					road_heading_ang.append(rad_to_deg(acos(clampf(absf(hz._move_dir.normalized().dot(tang)), 0.0, 1.0))))
			if have_prev:
				var dq := (prev_basis.inverse() * mx.basis.orthonormalized()).get_rotation_quaternion()
				rot_acc += rad_to_deg(dq.get_angle())
			prev_basis = mx.basis.orthonormalized()
			have_prev = true
		print("    vizibila %d cadre (%.1f s); abaterea max de la jgheab %.2f m; golul sub talpi %+.2f .. %+.2f m; peste drum %.2f s, lateral %+.2f .. %+.2f; unghiul fata de axa la intrarea pe drum %s grade; rotatie acumulata %.0f grade" % [
			visible_frames, visible_frames / 60.0, dev_max, gap_min, gap_max, on_road_t / 60.0,
			lat_min, lat_max, str(road_heading_ang), rot_acc])
		print("    cadre cu un colt al talpii la > 0,15 m de suprafata: %d din %d (%.0f%%), centrul la lateral %+.2f .. %+.2f" % [
			bad_frames, visible_frames, 100.0 * bad_frames / maxf(visible_frames, 1), bad_lat_min, bad_lat_max])
		var keys := bins.keys()
		keys.sort()
		var hist := "    cel mai mare gol (+ in aer / - in suprafata) pe benzi laterale de 2 m:"
		for k in keys:
			hist += "  [%+d..%+d] %+.2f" % [k * 2, k * 2 + 2, float(bins[k])]
		print(hist)
		_verdict(visible_frames > 60, "sania a mers (%d cadre)" % visible_frames)
		_verdict(dev_max < 0.6, "sta pe jgheab (abatere max %.2f m)" % dev_max)
		# Marginea drumului e o TREAPTA de ~0,3 m (asfaltul sta peste umar): o talpa rigida de 2,4 m care o
		# trece are un colt in aer sau in asfalt cateva cadre, oricum. Verdictul se da in afara benzii de
		# margine (|lateral| intre semilatime - 2 si semilatime + 3,5 m); banda se raporteaza separat.
		var hw0 := _track.width_at_index(_route().closest_index_global(hz.global_position))
		var off_edge := 0.0
		var on_edge := 0.0
		for k in bins.keys():
			var mid := absf(float(k) * 2.0 + 1.0)
			if mid > hw0 - 2.0 and mid < hw0 + 3.5:
				on_edge = maxf(on_edge, absf(float(bins[k])))
			else:
				off_edge = maxf(off_edge, absf(float(bins[k])))
		print("    golul maxim: %.2f m in afara benzii de margine, %.2f m pe banda de margine a drumului (treapta asfaltului)" % [off_edge, on_edge])
		_verdict(off_edge < 0.25, "in afara marginii drumului nici nu pluteste, nici nu se ingroapa (|gol| max %.2f m)" % off_edge)
		_verdict(on_road_t > 0 and lat_min < -2.0 and lat_max > 2.0, "traverseaza drumul pe toata latimea (%+.2f .. %+.2f)" % [lat_min, lat_max])


# ----------------------------------------------------------------- portaluri

func _portals() -> void:
	var dm := _track.get_node_or_null("DecorManual/Portaluri")
	if dm == null:
		_verdict(false, "lipseste DecorManual/Portaluri")
		return
	print("--- portaluri: terenul sub stalpi si rama de beton a codului fata de fata GLB-ului")
	for c in dm.get_children():
		var p := c as Node3D
		if p == null or p.scene_file_path.is_empty():
			continue # corpurile de coliziune ale lui world_prop (`*_col`) sunt frati
		var gallery := p.scene_file_path.ends_with("gallery_portal.glb")
		var gap_half := 5.15 if gallery else 5.10
		var half := 9.0 if gallery else 7.0
		var ceil_h := 9.0 if gallery else 7.0
		var xf := p.global_transform
		var lows: Array[float] = []
		var highs: Array[float] = []
		for sgn: float in [-1.0, 1.0]:
			var g_min := INF
			var g_max := -INF
			var x0 := gap_half + 0.2
			while x0 <= half - 0.2:
				for z: float in [0.1, 0.6, 1.0]:
					var wp := xf * Vector3(sgn * x0, 0.0, z)
					var g := _ground(wp + Vector3.UP * 0.5, 0.5, 12.0)
					if not is_nan(float(g[0])):
						g_min = minf(g_min, float(g[0]))
						g_max = maxf(g_max, float(g[0]))
				x0 += 0.5
			lows.append(g_min)
			highs.append(g_max)
		var base := xf.origin.y
		# Rama codului: raza pe axa, de afara spre tunel, la cota tavanului + 0.4 (inelul de sus al ramei).
		var out_dir := -xf.basis.z.normalized()
		var from := xf.origin + out_dir * 8.0 + Vector3.UP * (ceil_h + 0.4)
		var to := xf.origin - out_dir * 6.0 + Vector3.UP * (ceil_h + 0.4)
		var frame_d := NAN
		var frame_name := ""
		var ex: Array[RID] = []
		for k in 8:
			var q := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, ex)
			var hit := _space.intersect_ray(q)
			if hit.is_empty():
				break
			if _skip_body(hit.collider):
				ex.append(hit.rid)
				continue
			frame_d = (hit.position - xf.origin).dot(out_dir)
			frame_name = String((hit.collider as Node).name)
			break
		print("    %-18s baza %.2f | teren sub stalpul stang %.2f..%.2f, drept %.2f..%.2f -> pluteste max %+.2f | prima fata a codului pe axa la %+.2f m in fata planului GLB (%s)" % [
			p.name, base, lows[0], highs[0], lows[1], highs[1], base - minf(lows[0], lows[1]), frame_d, frame_name])
		_verdict(base - minf(lows[0], lows[1]) < 0.10, "%s: stalpii nu plutesc (%+.2f)" % [p.name, base - minf(lows[0], lows[1])])
		_verdict(not is_nan(frame_d) and absf(frame_d) < 0.35, "%s: fata GLB-ului pe fata ramei din cod (%+.2f m)" % [p.name, frame_d])
