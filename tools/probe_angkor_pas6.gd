extends Node
## GARDA PASULUI 6 PE ANGKOR (Track24, brief docs/track_briefs/angkor.md §7 pasul 6): verifica pe
## scena reala ca mecanicile montate de `tools/gen_angkor_route.py` stau unde trebuie si sunt legate.
## Statica (geometrie + noduri), fara cursa: cursa e ProbeRace `--angkor`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAngkorPas6.tscn
##   ... -- --sabotaj   (roteste perdeaua 90 de grade si muta un turn la 3 m: trebuie sa pice)
##
## Contractele, fiecare cu cifra lui:
##   (a) PERDEAUA: -Z local fata de tangenta drumului < 10 grade (memoria
##       `tscn-transform-e-pe-randuri`: la Fiordland perdelele au stat de-a curmezisul 5 zile,
##       nimeni n-a masurat unghiul); centrul la < 1 m de axa; acopera toata latimea benzii;
##       NICIUN corp de coliziune (hazard fals) — doar declansatorul Area3D.
##   (b) TURNURILE BAYONULUI: 3 corpuri `BayonTurn*`, fiecare la 0,5-1,5 m de axa (decizia V2,
##       pasul 1), iar podeaua de linie (`lane_floor_at`) >= 0,62 de la 40 m inaintea primului
##       pana dupa ultimul — altfel AI-ul intra in turn (lectia culoarului citit la indexul curent).
##   (c) BALUSTRADELE: pe calea de vest, raze laterale din axa la 0,5 m peste asfalt, din 2 in 2 m:
##       inchis pe ambele parti, cu EXACT un gol de 4-10 m pe fiecare parte (7 m cerut, probe la 2 m) (brief §2 randul A).
##   (d) MUSONUL: prima ploaie (inceputul telegrafului) la 40-60 s dupa start (cursa porneste pe
##       uscat), perioada nu e multiplu de ~75-85 s, iar fulgerul gaseste metronomul.

const ANGLE_MAX_DEG: float = 10.0

var _fails: Array[String] = []


func _ready() -> void:
	var sabotage := "--sabotaj" in OS.get_cmdline_user_args()
	# Radacina e ocupata cat ruleaza `_ready`-urile scenei principale: `add_child` acolo pica.
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track24.tscn") as PackedScene
	var track := scene.instantiate() as Track
	if sabotage:
		var cur := track.get_node("Hazarduri/PerdeaLiane") as Node3D
		cur.transform.basis = cur.transform.basis.rotated(Vector3.UP, PI * 0.5)
		var t1 := track.get_node("Obstacole/BayonTurn1") as Node3D
		t1.position.z += 1.0   # de la -1 m la axa: AI-ul nu mai are pe unde trece pe dreapta
	get_tree().root.add_child(track)
	# Ca ProbeLaneClear: pista se coace in cadrele de proces, corpurile intra in spatiu la fizica.
	for _k in 6:
		await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== ANGKOR pasul 6%s ===" % (" [SABOTAJ]" if sabotage else ""))
	_check_curtain(track)
	_check_towers(track)
	_check_balustrades(track)
	_check_monsoon(track)
	print("")
	if _fails.is_empty():
		print("VERDICT: OK")
		get_tree().quit(0)
	else:
		for f in _fails:
			print("  ✘ " + f)
		print("VERDICT: PROBLEMA (%d)" % _fails.size())
		get_tree().quit(1)


func _fail(msg: String) -> void:
	_fails.append(msg)


func _tangent(track: Track, i: int) -> Vector3:
	var n := track.baked.size()
	var d := track.baked[(i + 1) % n] - track.baked[(i - 1 + n) % n]
	d.y = 0.0
	return d.normalized()


func _check_curtain(track: Track) -> void:
	var cur := track.get_node_or_null("Hazarduri/PerdeaLiane") as Node3D
	if cur == null:
		_fail("perdeaua lipseste")
		return
	var p := cur.global_position
	var i := track.closest_index_global(p)
	var fwd := -cur.global_transform.basis.z
	fwd.y = 0.0
	var ang := rad_to_deg(fwd.normalized().angle_to(_tangent(track, i)))
	var c := track.baked[i]
	var lat := Vector2(p.x - c.x, p.z - c.z).length()
	var half := track.width_at_index(i)
	var w: float = cur.get("width")
	var bodies := 0
	for n in cur.find_children("*", "CollisionObject3D", true, false):
		if not (n is Area3D):
			bodies += 1
	print("(a) perdea: frac %.3f, unghi fata de drum %.1f grade, la %.2f m de axa, latime %.1f m "
		% [track.frac_at(i), ang, lat, w] + "pe banda de %.1f m, corpuri %d" % [half * 2.0, bodies])
	if ang > ANGLE_MAX_DEG:
		_fail("perdeaua e rotita %.1f grade fata de drum (max %.0f)" % [ang, ANGLE_MAX_DEG])
	if lat > 1.0:
		_fail("perdeaua e la %.2f m de axa" % lat)
	if w < half * 2.0 + 1.0:
		_fail("perdeaua (%.1f m) nu acopera banda (%.1f m)" % [w, half * 2.0])
	if bodies > 0:
		_fail("perdeaua are %d corpuri de coliziune — hazardul fals nu are voie" % bodies)


func _check_towers(track: Track) -> void:
	var towers := track.get_node("Obstacole").get_children()
	if towers.size() != 3:
		_fail("turnuri Bayon: %d, nu 3" % towers.size())
	var idx: Array[int] = []
	for t in towers:
		var p := (t as Node3D).global_position
		var i := track.closest_index_global(p)
		idx.append(i)
		var c := track.baked[i]
		var off := Vector2(p.x - c.x, p.z - c.z).dot(Vector2(track._side_at(i).x, track._side_at(i).z))
		print("(b) %s: frac %.3f, offset %+.2f m, podea de linie %.2f, semilatime %.1f m" % [
			t.name, track.frac_at(i), off, track.lane_floor_at(i), track.width_at_index(i)])
		if absf(off) < 0.5 or absf(off) > 1.5:
			_fail("%s la %+.2f m de axa (V2 cere 0,5-1,5)" % [t.name, off])
	if idx.is_empty():
		return
	idx.sort()
	# Podeaua de linie de la 40 m inaintea primului turn pana dupa ultimul.
	var n := track.baked.size()
	var i0 := idx[0]
	var back := 0.0
	while back < 40.0:
		var j := (i0 - 1 + n) % n
		back += track.baked[i0].distance_to(track.baked[j])
		i0 = j
	var i := i0
	var low := 0
	var probes := 0
	while i != (idx[idx.size() - 1] + 1) % n:
		probes += 1
		if track.lane_floor_at(i) < 0.62 - 1e-3:
			low += 1
		i = (i + 1) % n
	print("(b) podea de linie >= 0,62 pe %d / %d puncte (de la 40 m inaintea primului turn)"
		% [probes - low, probes])
	if low > 0:
		_fail("podeaua de linie lipseste pe %d puncte din sectorul turnurilor" % low)


func _check_balustrades(track: Track) -> void:
	var space := track.get_world_3d().direct_space_state
	# Calea de vest: de la x=-190 la x=-74 (harta), pe axa y=0 (Godot z=0), spre +X.
	for side in [1.0, -1.0]:
		var closed := 0
		var gaps: Array[Vector2] = []
		var gap_start := INF
		var x := -190.0   # capatul de vest al balustradei cade la ~-198..-194 (rezolutia hartii de fractii)
		while x <= -74.0:
			var i := track.closest_index_global(Vector3(x, 0.0, 0.0))
			var c := track.baked[i]
			var s: Vector3 = track._side_at(i) * float(side)
			var from := c + Vector3.UP * 0.5
			var to: Vector3 = from + s * (track.width_at_index(i) + 4.0)   # + capatul desfacut (2,5 m)
			var q := PhysicsRayQueryParameters3D.create(from, to)
			var hit := space.intersect_ray(q)
			var is_wall: bool = not hit.is_empty() and str((hit["collider"] as Node).name).begins_with("Parapet")
			if is_wall:
				closed += 1
				if gap_start < INF:
					gaps.append(Vector2(gap_start, x))
					gap_start = INF
			elif gap_start == INF:
				gap_start = x
			x += 2.0
		if gap_start < INF:
			gaps.append(Vector2(gap_start, x))
		var desc := []
		for g in gaps:
			desc.append("x %.0f..%.0f (%.0f m)" % [g.x, g.y, g.y - g.x])
		print("(c) balustrada latura %+d: %d probe inchise, goluri: %s" % [int(side), closed, desc])
		if gaps.size() != 1:
			_fail("latura %+d a caii de vest are %d goluri, nu 1" % [int(side), gaps.size()])
		else:
			var gl: float = gaps[0].y - gaps[0].x
			if gl < 4.0 or gl > 10.0:
				_fail("golul de pe latura %+d are %.0f m (4-10)" % [int(side), gl])


func _check_monsoon(track: Track) -> void:
	var rain := track.get_node_or_null("Hazarduri/Muson")
	var flash := track.get_node_or_null("Hazarduri/Fulger")
	if rain == null or flash == null:
		_fail("musonul sau fulgerul lipsesc")
		return
	var period: float = rain.get("period")
	var first: float = period - float(rain.get("start_clock"))
	var mult := period / 80.0
	print("(d) muson: perioada %.0f s (%.2f tururi de ~80 s), prima ploaie la %.0f s, fulger legat: %s"
		% [period, mult, first, flash.get("_rain") != null])
	if first < 40.0 or first > 60.0:
		_fail("prima ploaie la %.0f s (40-60)" % first)
	if absf(mult - roundf(mult)) < 0.1:
		_fail("perioada ploii (%.0f s) imparte turul" % period)
	if flash.get("_rain") == null:
		_fail("fulgerul n-a gasit RainCycle")
