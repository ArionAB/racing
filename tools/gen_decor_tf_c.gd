extends Node
## Generator de decor MANUAL pentru POI C — MALUL LACULUI SI URSUL
## (Track21 Transfagarasan, frac 0.1535-0.252, semi 7,0). Nu e sonda: CALCULEAZA
## blocurile `.tscn` care se lipesc in `Track21.tscn` sub `DecorManual/ZonaC`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorTfC.tscn -- --out=<fisier>
##
## ----------------------------------------------------------------------------
## LISTA DE ELEMENTE (runda 1) — din decupajele `C.png` si `C_urs.png`
## ----------------------------------------------------------------------------
## Ce spune decupajul (materia, nu layoutul):
##   (1) lacul verde-inchis pe STANGA, cu pinteni de sist cenusiu-verzui in lame
##       inclinate, iarba pe creasta lor si molizi pe pinteni;
##   (2) pe DREAPTA, drumul intra in padure: molizi verde-negru (coloane inguste,
##       in palcuri de 3-4) amestecati cu fagi rotunzi, verde cald; pe sol iarba
##       cu petice de piatra si grohotis la picior de stanca;
##   (3) ursul brun ridicat la marginea padurii, pe un colt de iarba/stanca,
##       indicatorul cu pictograma (deja montat, `Semn_urs`);
##   (4) padurea e DENSA langa drum si se rareste spre deal.
##
## Cifre (legate de piesa din kit sau din kitul refolosit):
##   A. FAGI ........ ~39 `beech_tree_a/b`           (kit)  noduri, `trunk`
##        - ~29 in primul rand, in 11 grupuri de 2-3, la 9-24 m de MARGINEA
##          asfaltului pe dreapta (densitate care CRESTE spre drum: grupuri de
##          3 la 10-13 m, de 2 la 20+ m);
##        - ~10 in al doilea rand, la 28-55 m (adancime, nu perete).
##        Noduri, nu MultiMesh: sunt sub pragul de ~1000 de piese, iar trunchiul
##        cere coliziune + remapare de slot (29 -> VOLCANIC_BLACK) pe care un
##        FlockProp nu le primeste.
##   B. AFLORIMENTE . 5  `schist_outcrop_a/b/c`      (kit)  noduri, `hull`
##        - 3 pe dreapta (pinteni la 26-31 m: a la 0.1665, b la 0.1975,
##          c la 0.2125);
##        - 2 pe capul de teren din stanga (0.225-0.234, terenul urca +5 m la
##          25-40 m de margine): pintenul de sist de pe lac din decupaj.
##   C. GROHOTIS .... 2  `scree_cone`                (kit)  noduri, fantoma
##        la piciorul a doua aflorimente, cu latura plata spre stanca.
##   D. MOLIZI ...... 12 `alpine_pines` Pine_B/Pine_C (refolosit) FlockProp
##        in 4 palcuri de 3. Varianta se alege cu `mesh_name`, trunchiul = alt
##        stol cu aceleasi pozitii (GLB-ul are 4 variante; nu se stinge niciuna).
##   E. FLORI ....... 8 petice de bujor (`bujor_de_munte`, 6 plante/petic) + afin
##        (`afin`, 3/petic) — FlockProp, 2 felii de cate 4 petice. Bujorul e
##        accentul magenta, DOAR in petice.
##   F. Indicator urs: se foloseste cel montat; 0 in plus.
## Densitate pe benzi (de la marginea asfaltului): 0-10 m iarba si tufe (nimic
## solid), 10-30 m fagi + molizi + aflorimente, 30-60 m padurea si pintenii.
## STANGA: nimic la < 3 m de malul lacului; nimic care sa acopere lacul.
## Culoarul ursului (0.185-0.205): nimic cu coliziune la < 8 m de axa.

const TRACK := "res://scenes/tracks/Track21.tscn"
const ZONE := "DecorManual/ZonaC"

const RES := {
	"beech_a": ["c_beech_a", "res://assets/models/transfagarasan/plants/beech_tree_a.glb"],
	"beech_b": ["c_beech_b", "res://assets/models/transfagarasan/plants/beech_tree_b.glb"],
	"outcrop_a": ["c_outcrop_a", "res://assets/models/transfagarasan/rocks/schist_outcrop_a.glb"],
	"outcrop_b": ["c_outcrop_b", "res://assets/models/transfagarasan/rocks/schist_outcrop_b.glb"],
	"outcrop_c": ["c_outcrop_c", "res://assets/models/transfagarasan/rocks/schist_outcrop_c.glb"],
	"scree": ["c_scree", "res://assets/models/transfagarasan/rocks/scree_cone.glb"],
	"pines": ["c_pines", "res://assets/models/trees/alpine_pines.glb"],
	"bujor": ["c_bujor", "res://assets/models/transfagarasan/plants/bujor_de_munte.glb"],
	"afin": ["c_afin", "res://assets/models/transfagarasan/plants/afin.glb"],
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid := RID()
var _rng := RandomNumberGenerator.new()
var _out: Array[String] = []
var _n := 0
var _log: Array[String] = []
var _out_path := ""

# Pozitiile stolurilor (lume), emise la sfarsit.
var _pine_pos: Dictionary = {"Pine_B": [], "Pine_C": []}
var _pine_yaw: Dictionary = {"Pine_B": [], "Pine_C": []}
var _bujor_pos: Array = []
var _bujor_yaw: Array = []
var _afin_pos: Array = []
var _afin_yaw: Array = []
var _patch_slice: Array = []
var _afin_slice: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	_rng.seed = 150421

	_beeches()
	_outcrops_and_scree()
	_spruces()
	_flowers()
	_write()
	get_tree().quit(0)


func _idx(frac: float) -> int:
	return int(frac * float(_track.baked.size())) % _track.baked.size()


## Punct de lume: `off` metri de la MARGINEA asfaltului (semn: + dreapta, - stanga),
## `along` metri pe directia de mers.
func _pt(frac: float, off: float, along: float) -> Vector3:
	var i := _idx(frac)
	var n := _track.baked.size()
	var p: Vector3 = _track.baked[i]
	var half: float = _track.width_at_index(i)
	var s := _track._side_at(i)
	var dir := (_track.baked[(i + 1) % n] - p).normalized()
	var lat := signf(off) * (half + absf(off))
	var q := p + s * lat + dir * along
	q.y = _sol(q.x, q.z)
	return q


## Distanta minima de la axa (in plan), pe fereastra data.
func _axis_dist(q: Vector3, f0: float, f1: float) -> float:
	var best := 1e9
	for i in range(_idx(f0), _idx(f1)):
		var p: Vector3 = _track.baked[i]
		best = minf(best, Vector2(p.x - q.x, p.z - q.z).length())
	return best


func _node(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		sink: float, mode: String = "") -> void:
	_n += 1
	var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * scl),
		Vector3(pos.x, pos.y - sink, pos.z))
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model][0]])
	_out.append("transform = %s" % var_to_str(xf))
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")
	_log.append("; %s%d axa=%.1f m ursul=%.1f m y=%.2f" % [base, _n,
		_axis_dist(pos, 0.150, 0.256), _axis_dist(pos, 0.185, 0.205), pos.y])


## A. FAGII. Grupuri de 2-3 pe dreapta, cu densitate care creste spre drum.
func _beeches() -> void:
	# [frac, offset de la margine, nr. in grup]
	var groups := [
		[0.1585, 11.0, 3], [0.1630, 19.0, 3], [0.1680, 14.0, 2],
		[0.1725, 24.0, 3], [0.1850, 12.0, 3], [0.1895, 20.0, 3],
		[0.2000, 16.0, 2], [0.2050, 10.0, 2], [0.2150, 14.0, 3],
		[0.2260, 17.0, 3], [0.2340, 12.0, 2],
	]
	var total := 0
	for g: Array in groups:
		for k in int(g[2]):
			var off: float = float(g[1]) + _rng.randf_range(-2.5, 2.5) + float(k) * 2.2
			var along := _rng.randf_range(-6.0, 6.0) + float(k) * 3.0
			var q := _pt(float(g[0]), maxf(off, 9.0), along)
			if not _ok_tree(q):
				continue
			var near := clampf(1.0 - (off - 9.0) / 18.0, 0.0, 1.0)
			var scl := _rng.randf_range(0.72, 1.0) if off < 16.0 else _rng.randf_range(0.85, 1.2)
			scl *= 0.95 + 0.1 * near
			var m := "beech_a" if _rng.randf() < 0.5 else "beech_b"
			_node(m, "Fag", q, _rng.randf_range(0.0, TAU), scl, 0.1)
			total += 1
	# al doilea rand: adancime
	var f := 0.1600
	while f < 0.2250:
		if _rng.randf() < 0.55:
			var q := _pt(f + _rng.randf_range(-0.003, 0.003), _rng.randf_range(28.0, 55.0), 0.0)
			if _ok_tree(q):
				var m2 := "beech_a" if _rng.randf() < 0.5 else "beech_b"
				_node(m2, "FagFund", q, _rng.randf_range(0.0, TAU), _rng.randf_range(0.95, 1.3), 0.1)
				total += 1
		f += 0.0075
	_log.append("; fagi: %d" % total)


## Reguli de loc: teren valid, nu in culoarul ursului, nu peste semn.
func _ok_tree(q: Vector3) -> bool:
	if is_nan(q.y):
		return false
	if _axis_dist(q, 0.185, 0.205) < 10.0:
		return false
	var si := _idx(0.1777)
	var sg: Vector3 = _track.baked[si] + _track._side_at(si) * 9.2
	if Vector2(sg.x - q.x, sg.z - q.z).length() < 7.0:
		return false
	return true


## B+C. AFLORIMENTELE si grohotisul de la picior.
func _outcrops_and_scree() -> void:
	# [model, frac, off, yaw, scara]
	var specs := [
		["outcrop_a", 0.1665, 27.0, 0.6, 1.25],
		["outcrop_b", 0.1975, 31.0, 2.4, 1.3],
		["outcrop_c", 0.2125, 26.0, 1.1, 1.2],
		["outcrop_a", 0.2250, -30.0, 3.7, 1.35],
		["outcrop_c", 0.2335, -26.0, 5.2, 1.3],
	]
	for s: Array in specs:
		var q := _pt(float(s[1]), float(s[2]), 0.0)
		if is_nan(q.y):
			continue
		_node(String(s[0]), "Aflorimentul", q, float(s[3]), float(s[4]), 0.3)
	# Grohotis la piciorul aflorimentelor b si c: latura plata (+Z local) spre
	# stanca; yaw = atan2(d.x, d.z) cu d = directia grohotis -> stanca.
	for sc: Array in [[0.1975, 31.0, 7.5], [0.2125, 26.0, 6.5]]:
		var rock := _pt(float(sc[0]), float(sc[1]), 0.0)
		var road := _pt(float(sc[0]), float(sc[1]) - 10.0, 0.0)
		var d := road - rock
		d.y = 0.0
		d = d.normalized()
		var center := rock + d * float(sc[2])
		center.y = _sol(center.x, center.z)
		var to_rock := -d
		_node("scree", "Grohotis", center, atan2(to_rock.x, to_rock.z), 1.0, 0.25, "none")


## D. MOLIZII. 4 palcuri x 3; stolurile se emit la sfarsit.
func _spruces() -> void:
	# [frac, off, nr]
	var clusters := [
		[0.1700, 36.0, 3], [0.2055, 38.0, 3], [0.2290, -32.0, 3], [0.2385, 21.0, 3],
	]
	for c: Array in clusters:
		for k in int(c[2]):
			var off: float = float(c[1]) + _rng.randf_range(-3.5, 3.5)
			var q := _pt(float(c[0]) + _rng.randf_range(-0.002, 0.002), off, _rng.randf_range(-3.0, 3.0))
			if is_nan(q.y) or _axis_dist(q, 0.185, 0.205) < 10.0:
				continue
			var nm := "Pine_C" if k == 0 else "Pine_B"
			(_pine_pos[nm] as Array).append(Vector3(q.x, q.y - 0.15, q.z))
			(_pine_yaw[nm] as Array).append(_rng.randf_range(0.0, TAU))


## E. FLORILE. Petice neregulate de bujor cu afin pe margine.
func _flowers() -> void:
	var fr := [0.1600, 0.1660, 0.1830, 0.1900, 0.2040, 0.2130, 0.2300, 0.2370]
	var k := 0
	for f: float in fr:
		var off := _rng.randf_range(7.0, 15.0)
		var center := _pt(f, off, 0.0)
		if is_nan(center.y) or _axis_dist(center, 0.185, 0.205) < 8.0:
			k += 1
			continue
		var sl := 0 if k < 4 else 1
		for j in 6:
			var a := _rng.randf_range(0.0, TAU)
			var r := sqrt(_rng.randf()) * 2.4
			var q := center + Vector3(cos(a) * r, 0.0, sin(a) * r)
			q.y = _sol(q.x, q.z) + 0.02
			_bujor_pos.append(q)
			_bujor_yaw.append(_rng.randf_range(0.0, TAU))
			_patch_slice.append(sl)
		for j in 3:
			var a2 := _rng.randf_range(0.0, TAU)
			var r2 := 2.2 + _rng.randf() * 1.6
			var q2 := center + Vector3(cos(a2) * r2, 0.0, sin(a2) * r2)
			q2.y = _sol(q2.x, q2.z) + 0.02
			_afin_pos.append(q2)
			_afin_yaw.append(_rng.randf_range(0.0, TAU))
			_afin_slice.append(sl)
		k += 1


func _flock(name_: String, model: String, mesh_name: String, pos: Array, yaw: Array,
		smin: float, smax: float, tri_class: String, seed_: int) -> void:
	if pos.is_empty():
		return
	var ps: Array[String] = []
	var ys: Array[String] = []
	for i in pos.size():
		var p: Vector3 = pos[i]
		ps.append("%.3f, %.3f, %.3f" % [p.x, p.y, p.z])
		ys.append("%.3f" % float(yaw[i]))
	_out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [name_, ZONE])
	_out.append('script = ExtResource("c_flock")')
	_out.append('model = ExtResource("%s")' % RES[model][0])
	if mesh_name != "":
		_out.append('mesh_name = "%s"' % mesh_name)
	if tri_class != "":
		_out.append('tri_class = "%s"' % tri_class)
	_out.append("scale_min = %.2f" % smin)
	_out.append("scale_max = %.2f" % smax)
	_out.append("seed_value = %d" % seed_)
	_out.append("snap_to_ground = false")
	_out.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
	_out.append("yaws = PackedFloat32Array(%s)" % ", ".join(ys))
	_out.append("")


func _slice(pos: Array, yaw: Array, sl: Array, which: int) -> Array:
	var p: Array = []
	var y: Array = []
	for i in pos.size():
		if int(sl[i]) == which:
			p.append(pos[i])
			y.append(yaw[i])
	return [p, y]


func _write() -> void:
	# molizi: foliajul + trunchiul fiecarei variante (acelasi seed => aceeasi scara)
	for nm: String in ["Pine_B", "Pine_C"]:
		var tr := nm.replace("Pine_", "Trunk_")
		var sd := 5101 + nm.length() + (7 if nm == "Pine_C" else 0)
		_flock("C_%s" % nm, "pines", nm, _pine_pos[nm], _pine_yaw[nm], 0.9, 1.15, "", sd)
		_flock("C_%s" % tr, "pines", tr, _pine_pos[nm], _pine_yaw[nm], 0.9, 1.15, "", sd)
	for sl in 2:
		var b := _slice(_bujor_pos, _bujor_yaw, _patch_slice, sl)
		_flock("C_BujorFloare_S%d" % sl, "bujor", "Bujor_Bloom", b[0], b[1], 1.5, 2.1, "atint:tf_bloom", 6201 + sl)
		_flock("C_BujorFrunze_S%d" % sl, "bujor", "Bujor_Leaves", b[0], b[1], 1.5, 2.1, "", 6201 + sl)
		var a := _slice(_afin_pos, _afin_yaw, _afin_slice, sl)
		_flock("C_AfinFrunze_S%d" % sl, "afin", "Afin_Leaves", a[0], a[1], 1.4, 1.9, "", 6301 + sl)
		_flock("C_AfinBoabe_S%d" % sl, "afin", "Afin_Berry", a[0], a[1], 1.4, 1.9, "", 6301 + sl)
	print("; noduri %d, molizi B=%d C=%d, bujor %d, afin %d" % [_n,
		(_pine_pos["Pine_B"] as Array).size(), (_pine_pos["Pine_C"] as Array).size(),
		_bujor_pos.size(), _afin_pos.size()])
	for l in _log:
		print(l)
	var ext: Array[String] = []
	ext.append('[ext_resource type="Script" path="res://scenes/props/flock.gd" id="c_flock"]')
	for k: String in RES:
		ext.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % [RES[k][1], RES[k][0]])
	if _out_path.is_empty():
		for l in ext:
			print(l)
		for l in _out:
			print(l)
		return
	var fa := FileAccess.open(_out_path + ".ext", FileAccess.WRITE)
	for l in ext:
		fa.store_line(l)
	fa.close()
	var fb := FileAccess.open(_out_path, FileAccess.WRITE)
	for l in _out:
		fb.store_line(l)
	fb.close()
	print("; scris %s" % _out_path)


## Cota SOLULUI din coliziunea reala (memoria `terrain-mesh-y-extrapoleaza`).
func _sol(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 400.0, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 40:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	if not hit.is_empty() and hit["rid"] == _terrain_rid:
		return float(hit["position"].y)
	return NAN
