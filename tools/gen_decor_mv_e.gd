extends Node
## Generator de decor MANUAL pentru POI E — TRECATOAREA DINTRE MESE (Track19,
## Monument Valley, frac 0.260-0.434, fara cercul r 30 m al arcului).
## Nu e sonda: CALCULEAZA transformarile care se lipesc in Track19.tscn sub
## `DecorManual/ZonaE`, pe teren real (raycast pe TerrainBody).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvE.tscn -- \
##       --out=<fisier> [--survey]
##
## `--survey` scrie profilul traseului pe E si amprentele falezelor TrackCliffs
## si nu genereaza nimic.
##
## ---- Compozitia (runda 1) ------------------------------------------------
## `mesa_wall_module` (kit): rock x -4.45..4.35 (fata pe +X la x=3, contraforturi
## pana la 4.35), grohotis spre +X pana la x=9.51 (inalt 0.4-0.9 la margine, 2.9
## langa perete), 12 m pe Z cu capete plane, 14 m inalt. Cu hull per mesh, grohotisul
## de 9,5 m ar intra in banda libera, deci modulul se SUBTIAZA pe X (SX): perete,
## contraforturi si grohotis se strang la jumatate (capetele, plane, raman la fel,
## deci lantul se inlantuie), iar modulul se INFIGE cu SINK ca marginea grohotisului
## (0,93 m inalta) sa iasa din pamant sub 0,3 m (prag de treapta).
##
## Defileul TrackCliffs (0.329-0.419) are fata la ~7,3 m de axa si spatele la
## ~14,7 (amprente masurate cu --survey): lantul de acolo e A DOUA LINIE, in spate.

const TRACK := "res://scenes/tracks/Track19.tscn"
const ZONE := "DecorManual/ZonaE"
const FRAC_A := 0.260
const FRAC_B := 0.434

const SX := 0.5
const SINK := 0.7
const TOE_GAP := 2.6            # muchia asfaltului -> marginea grohotisului (regula 2,5)
const TOE_LEN := 9.51 * SX
const MOD_LEN := 12.0
const STEP := 11.6              # 0,4 m suprapunere
## Distanta ORIGINE-modul -> axa: semilatimea maxima 7,0 + toe.
const LO_OPEN := 7.0 + TOE_GAP + TOE_LEN
## In defileu lantul se retrage in spatele falezelor.
const LO_GORGE := 17.5
const F_GORGE_IN := 0.3225
const F_GORGE_OUT := 0.3330
const FLARE_LEN := 20.0         # intrarea: de la 30 m de fata pana la fata de lucru
const FLARE_EXTRA := 18.0
## Culoarul bolovanului E: nimic cu centrul in x 56..88 (liber 62..82).
const ROCK_X0 := 56.0
const ROCK_X1 := 88.0
const END_X := -31.0            # cercul arcului: centrul (-68,3, 444,6) r 30

const RES := {
	"mesa": "s_mesa_wall_module", "butte_a": "s_butte_small_a",
	"talus_a": "s_talus_boulders_a", "talus_b": "s_talus_boulders_b",
	"rabbit": "s_rabbitbrush",
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _survey := false
var _out_path := ""
var _out: Array[String] = []
var _n := 0
var _nmesa := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	_sampler = _track._sampler
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 120.0
	_rng.seed = 190501
	if _survey:
		_do_survey()
		_survey_cliffs()
	else:
		_chain(1.0)
		_chain(-1.0)
		_talus()
		_buttes()
		_rabbit()
		if _out_path != "":
			var f := FileAccess.open(_out_path, FileAccess.WRITE)
			for line in _out:
				f.store_line(line)
			f.close()
			print("; scris %s" % _out_path)
		print("; asezate %d piese (din care %d module mesa)" % [_n, _nmesa])
	get_tree().quit(0)


func _smooth(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Distanta origine-modul -> axa la fractia f, `s` metri de la inceputul lantului.
func _lo(f: float, s: float) -> float:
	var lo := lerpf(LO_OPEN, LO_GORGE, _smooth(F_GORGE_IN, F_GORGE_OUT, f))
	if s < FLARE_LEN:
		lo += FLARE_EXTRA * (1.0 - _smooth(0.0, FLARE_LEN, s))
	return lo


## Un lant continuu de module pe o latura, pe o polilinie decalata de axa.
func _chain(sg: float) -> void:
	var n := _track.baked.size()
	var i0 := int(ceil(FRAC_A * float(n)))
	var pts: Array[Vector3] = []
	var cum: Array[float] = []
	var total := 0.0
	var s_axis := 0.0
	var i := i0
	while i < n:
		var p := _track.baked[i]
		if p.x < END_X:
			break
		var f := float(i) / float(n)
		if i > i0:
			s_axis += (p - _track.baked[i - 1]).length()
		var q := p + _track._side_at(i) * sg * _lo(f, s_axis)
		if not pts.is_empty():
			total += Vector2(q.x - pts[pts.size() - 1].x, q.z - pts[pts.size() - 1].z).length()
		pts.append(q)
		cum.append(total)
		i += 1
	var k := 0
	var skipped := 0
	var c := MOD_LEN * 0.5
	while c < total - MOD_LEN * 0.5:
		var ctr := _at(pts, cum, c)
		var a := _at(pts, cum, c - MOD_LEN * 0.5)
		var b := _at(pts, cum, c + MOD_LEN * 0.5)
		var chord := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
		var j := 0
		while j < cum.size() - 1 and cum[j + 1] < c:
			j += 1
		var side: Vector3 = _track._side_at(i0 + j) * sg
		# +X-ul modulului spre drum: perpendiculara pe coarda, pe partea axei.
		var toward := Vector3(-chord.z, 0.0, chord.x)
		if toward.dot(side) > 0.0:
			toward = -toward
		var yaw := atan2(-toward.z, toward.x)
		c += STEP
		if ctr.z < 415.5 and ctr.x > 230.0:
			skipped += 1 # zona lui D (z < 415)
			continue
		if ctr.x > ROCK_X0 and ctr.x < ROCK_X1:
			skipped += 1
			continue
		# jitter doar spre EXTERIOR (nu strange banda), +-1,5 grade pe yaw
		var out := -toward * _rng.randf_range(0.0, 0.5)
		var yaw_j := yaw + deg_to_rad(_rng.randf_range(-1.5, 1.5))
		var pos := Vector3(ctr.x + out.x, 0.0, ctr.z + out.z)
		pos.y = _sol_real(pos.x, pos.z, true) - SINK
		var sy := _rng.randf_range(0.9, 1.1)
		var mir := 1.0 if _rng.randf() < 0.5 else -1.0
		_emit("mesa", "Mesa%s" % ("N" if sg > 0.0 else "S"), pos, yaw_j, Vector3(SX, sy, mir))
		_nmesa += 1
		k += 1
	print("; lant %s: %d module, %d sarite (culoarul bolovanului), polilinie %.0f m"
		% ["+" if sg > 0.0 else "-", k, skipped, total])


func _at(pts: Array[Vector3], cum: Array[float], d: float) -> Vector3:
	var j := 0
	while j < cum.size() - 2 and cum[j + 1] < d:
		j += 1
	var seg := cum[j + 1] - cum[j]
	var t := 0.0 if seg < 0.0001 else clampf((d - cum[j]) / seg, 0.0, 1.0)
	return pts[j].lerp(pts[j + 1], t)


## Latimea efectiva (max pe +-8 puncte): intre 0.305 si 0.317 semilatimea sare la 7,0.
func _hw_eff(i: int) -> float:
	var n := _track.baked.size()
	var h := 0.0
	for d in range(-8, 9):
		h = maxf(h, _track.width_at_index((i + d + n) % n))
	return h


## Grupuri de talus pe valea deschisa, la 3-4,6 m de MARGINE (hull, regula 2,5 m).
func _talus() -> void:
	var n := _track.baked.size()
	var made := 0
	for sg in [1.0, -1.0]:
		var f0 := 0.2665 if sg > 0.0 else 0.2700
		var pitch := 0.0095
		for k in 6:
			var f := f0 + float(k) * pitch + _rng.randf_range(-0.0035, 0.0035)
			if f > 0.3255:
				continue
			var i := int(f * float(n))
			var model := "talus_a" if _rng.randf() < 0.5 else "talus_b"
			var scl := _rng.randf_range(0.9, 1.3)
			var r := (2.2 if model == "talus_a" else 2.9) * scl
			var gap := _rng.randf_range(3.0, 4.6)
			var d := _hw_eff(i) + gap + r
			var q: Vector3 = _track.baked[i] + _track._side_at(i) * sg * d
			q.y = _sol_real(q.x, q.z, true) - 0.15
			_emit(model, "Talus", q, _rng.randf_range(0.0, TAU), Vector3.ONE * scl)
			made += 1
	print("; talus: %d grupuri" % made)


## Butte-ul din coltul de intrare: pe EXTERIORUL virajului (sud), la 30-60 m.
func _buttes() -> void:
	var n := _track.baked.size()
	var i := int(0.272 * float(n))
	var p := _track.baked[i]
	var s: Vector3 = _track._side_at(i)
	if s.z < 0.0:
		s = -s
	var q := p + s * (_hw_eff(i) + 38.0)
	q.y = _sol_real(q.x, q.z, true) - 0.2
	_emit("butte_a", "ButteIntrare", q, 0.7, Vector3.ONE * 1.1)
	var dir := (_track.baked[(i + 1) % n] - p).normalized()
	var q2 := p + s * (_hw_eff(i) + 56.0) - dir * 24.0
	q2.y = _sol_real(q2.x, q2.z, true) - 0.2
	_emit("butte_a", "ButteIntrare", q2, 2.6, Vector3.ONE * 0.8)
	print("; butte: 2 (colt intrare)")


## Petice de rabbitbrush (accentul galben): 4 petice x 4-6 tufe, la 1,8-5 m de margine.
func _rabbit() -> void:
	var n := _track.baked.size()
	var patches := [[0.2735, 1.0], [0.2905, -1.0], [0.3085, 1.0], [0.3195, -1.0]]
	var made := 0
	for pt in patches:
		var f0: float = float(pt[0]) + _rng.randf_range(-0.002, 0.002)
		var sg: float = float(pt[1])
		var cnt := _rng.randi_range(4, 6)
		for b in cnt:
			var f := f0 + _rng.randf_range(-0.0016, 0.0016)
			var i := int(f * float(n))
			var d := _hw_eff(i) + _rng.randf_range(1.8, 5.0)
			var q: Vector3 = _track.baked[i] + _track._side_at(i) * sg * d
			q.y = _sol_real(q.x, q.z, true) - 0.05
			_emit("rabbit", "Rabbitbrush", q, _rng.randf_range(0.0, TAU),
				Vector3.ONE * _rng.randf_range(1.4, 2.0), "none")
			made += 1
	print("; rabbitbrush: %d tufe in 4 petice" % made)


func _emit(model: String, base: String, pos: Vector3, yaw: float, scl: Vector3,
		mode: String = "") -> void:
	_n += 1
	var t := Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(scl), pos)
	_out.append('[node name="E_%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	_out.append("transform = %s" % var_to_str(t))
	if mode != "" and mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


# ------------------------------------------------------------------ masuratori

func _do_survey() -> void:
	var n := _track.baked.size()
	print("; n=%d  total=%.1f" % [n, _sampler.total_length()])
	var lats := [-60.0, -40.0, -25.0, -15.0, -10.0, -8.0, 8.0, 10.0, 15.0, 25.0, 40.0, 60.0]
	var f := 0.255
	while f <= 0.44:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s: Vector3 = _track._side_at(i)
		var dir := (_track.baked[(i + 1) % n] - p).normalized()
		var row := "; %.3f i=%d p=(%.1f,%.1f,%.1f) hw=%.1f dir=(%.2f,%.2f) side=(%.2f,%.2f) |" % [
			f, i, p.x, p.y, p.z, _track.width_at_index(i), dir.x, dir.z, s.x, s.z]
		for l in lats:
			var q := p + s * float(l)
			row += " %+.0f:%+.1f" % [float(l), _sol_real(q.x, q.z, true) - p.y]
		print(row)
		f += 0.005


func _survey_cliffs() -> void:
	var cl: Node = null
	for c in _track.get_children():
		if str(c.name) == "Cliffs":
			cl = c
	if cl == null:
		print("; fara Cliffs")
		return
	var fps: Array = cl.get_meta(TrackCliffs.FOOTPRINT_META, [])
	print("; %d amprente de faleze" % fps.size())
	var n := _track.baked.size()
	for fp in fps:
		var pos: Vector3 = fp["pos"]
		var bi := -1
		var bd := 1e9
		for i in n:
			var d := Vector2(_track.baked[i].x - pos.x, _track.baked[i].z - pos.z).length()
			if d < bd:
				bd = d
				bi = i
		var f := float(bi) / float(n)
		if f < 0.25 or f > 0.44:
			continue
		var fwd: Vector3 = fp["fwd"]
		print(";   cliff f=%.4f pos=(%.1f,%.1f) d_ax=%.1f hx=%.1f hz=%.1f fwd=(%.2f,%.2f)"
			% [f, pos.x, pos.z, bd, fp["hx"], fp["hz"], fwd.x, fwd.z])


func _sol_real(x: float, z: float, quiet: bool = false) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 900.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	if not quiet:
		print("; ATENTIE fara sol la (%.1f, %.1f)" % [x, z])
	return _sampler.ground_y(x, z)
