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
## RUNDA 2 (verdict critic orb: lipsesc masele dense de molid intunecat):
##   - MOLIZII devin masa dominanta pe dreapta: ~12 grupuri neregulate de 5-12
##     (peste 100 de arbori), 4 marimi (Pine_A/B/C/D), pe ~60% din lungime,
##     densitate crescand spre drum; FlockProp pe 2 felii, ace pe
##     `tri_class tf_jneapan`, trunchiuri pe atlas.
##   - FAGII scad la 3 palcuri-accent; AFLORIMENTELE devin 3 grupuri de 2-3 lame
##     mari (peretele de sist) + 2 pe capul din stanga; BUJORUL 4 petice mici.
## RUNDA 3 (ultima): FASIA APROPIATA 3,5-9 m de margine, 0.160-0.240 pe dreapta
##   si pe taluzul din viraj (stanga, de la 0.2395): jneapan culcat, afin, lame
##   mici de sist si grohotis mic, toate FlockProp fara coliziune (0 material nou).
##   Molizii pe 3 randuri in adancime (13 / 26 / 42 m), cu goluri.
##
## STARE LA OPRIRE (runda 3): decorul acopera fasia apropiata, trei randuri de
## molizi (~160), 8 fagi, 11 aflorimente si petice mici de bujor. Ramane diferit
## de bara: iarba rasa intre grupuri, molizii vechi din scatter (oliv-galbui)
## amestecati cu ai nostri, acele cu mediana B~20 fata de 43 tinta, lacul-mare si
## groapa din stanga de la 0.24 (relief/apa, nu decor). Material de ignorat la
## integrare: tf_jneapan, tf_beech, tf_bloom sunt cele 3 clase aduse de zona.
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
	"jneapan_a": ["c_jneapan_a", "res://assets/models/transfagarasan/plants/jneapan_a.glb"],
	"jneapan_b": ["c_jneapan_b", "res://assets/models/transfagarasan/plants/jneapan_b.glb"],
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
const PINES := ["Pine_A", "Pine_B", "Pine_C", "Pine_D"]
const PINE_SCALE := {"Pine_A": [1.0, 1.5], "Pine_B": [0.9, 1.3], "Pine_C": [0.8, 1.15], "Pine_D": [1.0, 1.6]}
var _pine_pos: Dictionary = {"Pine_A": [], "Pine_B": [], "Pine_C": [], "Pine_D": []}
var _pine_yaw: Dictionary = {"Pine_A": [], "Pine_B": [], "Pine_C": [], "Pine_D": []}
var _pine_sl: Dictionary = {"Pine_A": [], "Pine_B": [], "Pine_C": [], "Pine_D": []}
var _bujor_pos: Array = []
var _bujor_yaw: Array = []
var _afin_pos: Array = []
var _afin_yaw: Array = []
var _patch_slice: Array = []
var _afin_slice: Array = []
var _rock_pos: Array = []   # aflorimente (noduri), ca spruces sa nu intre in ele
# Fasia apropiata (runda 3): cheie -> {pos, yaw, sl}
var _strip: Dictionary = {}


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
	_near_strip()
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
		[0.1630, 15.0, 3], [0.1895, 20.0, 3], [0.2150, 14.0, 2],
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
		["outcrop_a", 0.1650, 24.0, 0.6, 1.5], ["outcrop_c", 0.1685, 29.0, 1.9, 1.4],
		["outcrop_b", 0.1660, 33.0, 2.8, 1.5],
		["outcrop_b", 0.1960, 28.0, 2.4, 1.6], ["outcrop_c", 0.1995, 33.0, 0.8, 1.4],
		["outcrop_a", 0.1975, 38.0, 4.1, 1.5],
		["outcrop_c", 0.2115, 25.0, 1.1, 1.4], ["outcrop_a", 0.2145, 30.0, 5.0, 1.5],
		["outcrop_b", 0.2130, 36.0, 0.3, 1.5],
		["outcrop_a", 0.2250, -30.0, 3.7, 1.35],
		["outcrop_c", 0.2335, -26.0, 5.2, 1.3],
	]
	for s: Array in specs:
		var q := _pt(float(s[1]), float(s[2]), 0.0)
		if is_nan(q.y):
			continue
		_node(String(s[0]), "Aflorimentul", q, float(s[3]), float(s[4]), 0.3)
		_rock_pos.append(q)
	# Grohotis la piciorul aflorimentelor b si c: latura plata (+Z local) spre
	# stanca; yaw = atan2(d.x, d.z) cu d = directia grohotis -> stanca.
	for sc: Array in [[0.1960, 28.0, 7.5], [0.2115, 25.0, 6.5]]:
		var rock := _pt(float(sc[0]), float(sc[1]), 0.0)
		var road := _pt(float(sc[0]), float(sc[1]) - 10.0, 0.0)
		var d := road - rock
		d.y = 0.0
		d = d.normalized()
		var center := rock + d * float(sc[2])
		center.y = _sol(center.x, center.z)
		var to_rock := -d
		_node("scree", "Grohotis", center, atan2(to_rock.x, to_rock.z), 1.0, 0.25, "none")


## D. MOLIZII. Grupuri neregulate de 5-12 pe dreapta; densitate spre drum.
func _spruces() -> void:
	# Runda 3: 3 randuri in adancime (aproape / mijloc / fund), centre la ~0.0072,
	# decalate intre randuri, cu goluri ca acoperirea sa nu fie uniforma.
	# [offset centru, nr. pe grup, decalaj frac, prob. grup]
	var rows := [[13.0, 5, 0.0, 0.85], [26.0, 7, 0.0036, 0.8], [42.0, 7, 0.0018, 0.7]]
	var clusters: Array = []
	for r: Array in rows:
		var f: float = 0.1560 + float(r[2])
		while f < 0.2420:
			if _rng.randf() < float(r[3]):
				clusters.append([f, float(r[0]) + _rng.randf_range(-3.0, 3.0), int(r[1]) + _rng.randi_range(-1, 2)])
			f += 0.0072
	clusters.append([0.2290, -32.0, 5])
	var total := 0
	for c: Array in clusters:
		for k in int(c[2]):
			var sgn := signf(float(c[1]))
			var off: float = float(c[1]) + sgn * _rng.randf_range(-5.0, 5.0)
			if absf(off) < 9.0:
				off = 9.0 * sgn
			var fr: float = float(c[0]) + _rng.randf_range(-0.0035, 0.0035)
			var q := _pt(fr, off, 0.0)
			if is_nan(q.y) or _axis_dist(q, 0.185, 0.205) < 10.0:
				continue
			var si := _idx(0.1777)
			var sg: Vector3 = _track.baked[si] + _track._side_at(si) * 9.2
			if Vector2(sg.x - q.x, sg.z - q.z).length() < 6.0:
				continue
			var blocked := false
			for rp: Vector3 in _rock_pos:
				if Vector2(rp.x - q.x, rp.z - q.z).length() < 5.5:
					blocked = true
					break
			if blocked:
				continue
			var r := _rng.randf()
			var nm := "Pine_A" if r < 0.25 else ("Pine_B" if r < 0.6 else ("Pine_C" if r < 0.85 else "Pine_D"))
			(_pine_pos[nm] as Array).append(Vector3(q.x, q.y - 0.15, q.z))
			(_pine_yaw[nm] as Array).append(_rng.randf_range(0.0, TAU))
			(_pine_sl[nm] as Array).append(0 if fr < 0.2 else 1)
			total += 1
	_log.append("; molizi: %d" % total)


func _acc(key: String, q: Vector3, fr: float) -> void:
	if not _strip.has(key):
		_strip[key] = {"pos": [], "yaw": [], "sl": []}
	(_strip[key].pos as Array).append(q)
	(_strip[key].yaw as Array).append(_rng.randf_range(0.0, TAU))
	(_strip[key].sl as Array).append(0 if fr < 0.2 else 1)


## FASIA APROPIATA (runda 3): de la 3,5 m la ~9 m de margine, pe toata lungimea
## 0.160-0.240 pe dreapta si pe taluzul din viraj (stanga, 0.2395-0.252). Doar
## piese joase si fara coliziune (MultiMesh): jneapan culcat, afin, lame mici de
## sist, grohotis mic. Camera nu are ce taia, banda libera ramane libera.
func _near_strip() -> void:
	var si := _idx(0.1777)
	var sg: Vector3 = _track.baked[si] + _track._side_at(si) * 9.2
	var n := 0
	var f := 0.1600
	while f < 0.2520:
		var left := f >= 0.2395
		var sgn := -1.0 if left else 1.0
		# 1-2 piese de jneapan pe statie, la 3,5-9 m; la stanga doar pe taluz.
		for k in _rng.randi_range(1, 2):
			var off := _rng.randf_range(3.5, 9.0)
			var q := _pt(f + _rng.randf_range(-0.002, 0.002), off * sgn, _rng.randf_range(-3.0, 3.0))
			if is_nan(q.y) or Vector2(sg.x - q.x, sg.z - q.z).length() < 3.0:
				continue
			if left and absf(_sol(q.x, q.z) - _track.baked[_idx(f)].y) > 6.0:
				continue
			_acc("jneapan_a" if _rng.randf() < 0.5 else "jneapan_b", q, f)
			n += 1
		# afin: pâlc de 2-3 la baza lor
		if _rng.randf() < 0.75:
			var c := _pt(f, _rng.randf_range(4.0, 9.0) * sgn, 0.0)
			if not is_nan(c.y) and Vector2(sg.x - c.x, sg.z - c.z).length() > 3.0:
				for j in _rng.randi_range(2, 3):
					var q2 := c + Vector3(_rng.randf_range(-1.6, 1.6), 0.0, _rng.randf_range(-1.6, 1.6))
					q2.y = _sol(q2.x, q2.z)
					if not is_nan(q2.y):
						_acc("afin", q2, f)
						n += 1
		# roca mica: lama de sist (b) la scara mica si, rar, grohotis mic
		if _rng.randf() < 0.45:
			var q3 := _pt(f, _rng.randf_range(4.5, 9.0) * sgn, _rng.randf_range(-3.0, 3.0))
			if not is_nan(q3.y):
				_acc("rock", Vector3(q3.x, q3.y - 0.12, q3.z), f)
				n += 1
		if _rng.randf() < 0.12:
			var q4 := _pt(f, _rng.randf_range(6.0, 9.0) * sgn, 0.0)
			if not is_nan(q4.y):
				_acc("scree", Vector3(q4.x, q4.y - 0.1, q4.z), f)
				n += 1
		f += 0.0014
	_log.append("; fasie apropiata: %d piese" % n)


## E. FLORILE. Petice neregulate de bujor cu afin pe margine.
func _flowers() -> void:
	var fr := [0.1600, 0.1830, 0.2130, 0.2300]
	var k := 0
	for f: float in fr:
		var off := _rng.randf_range(7.0, 15.0)
		var center := _pt(f, off, 0.0)
		if is_nan(center.y) or _axis_dist(center, 0.185, 0.205) < 8.0:
			k += 1
			continue
		var sl := 0 if k < 2 else 1
		for j in 5:
			var a := _rng.randf_range(0.0, TAU)
			var r := sqrt(_rng.randf()) * 1.8
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
	for nm: String in PINES:
		var tr := nm.replace("Pine_", "Trunk_")
		var sc: Array = PINE_SCALE[nm]
		for sl in 2:
			var pp := _slice(_pine_pos[nm], _pine_yaw[nm], _pine_sl[nm], sl)
			var sd := 5100 + PINES.find(nm) * 10 + sl
			_flock("C_%s_S%d" % [nm, sl], "pines", nm, pp[0], pp[1], sc[0], sc[1], "tf_jneapan", sd)
			_flock("C_%s_S%d" % [tr, sl], "pines", tr, pp[0], pp[1], sc[0], sc[1], "", sd)
	for sl in 2:
		var b := _slice(_bujor_pos, _bujor_yaw, _patch_slice, sl)
		_flock("C_BujorFloare_S%d" % sl, "bujor", "Bujor_Bloom", b[0], b[1], 1.0, 1.4, "atint:tf_bloom", 6201 + sl)
		_flock("C_BujorFrunze_S%d" % sl, "bujor", "Bujor_Leaves", b[0], b[1], 1.0, 1.4, "", 6201 + sl)
		var a := _slice(_afin_pos, _afin_yaw, _afin_slice, sl)
		_flock("C_AfinFrunze_S%d" % sl, "afin", "Afin_Leaves", a[0], a[1], 1.4, 1.9, "", 6301 + sl)
		_flock("C_AfinBoabe_S%d" % sl, "afin", "Afin_Berry", a[0], a[1], 1.4, 1.9, "", 6301 + sl)
	# fasia apropiata: stoluri pe felii
	var spec := {
		"jneapan_a": [["jneapan_a", "Jneapan_Needles", "tf_jneapan"], ["jneapan_a", "Jneapan_Bark", ""]],
		"jneapan_b": [["jneapan_b", "Jneapan_Needles", "tf_jneapan"], ["jneapan_b", "Jneapan_Bark", ""]],
		"afin": [["afin", "Afin_Leaves", ""], ["afin", "Afin_Berry", ""]],
	}
	var scl := {"jneapan_a": [0.7, 1.0], "jneapan_b": [0.8, 1.1], "afin": [1.3, 1.8]}
	for key: String in spec:
		if not _strip.has(key):
			continue
		for sl in 2:
			var pp := _slice(_strip[key].pos, _strip[key].yaw, _strip[key].sl, sl)
			for e: Array in spec[key]:
				var nm := "C_F_%s_%s_S%d" % [key, String(e[1]).get_slice("_", 1), sl]
				_flock(nm, String(e[0]), String(e[1]), pp[0], pp[1], scl[key][0], scl[key][1], String(e[2]), 7000 + sl)
	for key2: String in ["rock", "scree"]:
		if not _strip.has(key2):
			continue
		for sl in 2:
			var pp2 := _slice(_strip[key2].pos, _strip[key2].yaw, _strip[key2].sl, sl)
			if key2 == "rock":
				_flock("C_F_Roca_S%d" % sl, "outcrop_b", "Schist_Schist", pp2[0], pp2[1], 0.28, 0.5, "tf_schist", 7100 + sl)
			else:
				_flock("C_F_Grohotis_S%d" % sl, "scree", "Scree_Schist", pp2[0], pp2[1], 0.28, 0.4, "tf_schist", 7200 + sl)
	print("; noduri %d, bujor %d, afin %d" % [_n,
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
