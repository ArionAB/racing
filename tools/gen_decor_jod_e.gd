extends Node
## Generator de decor MANUAL pentru POI E — PORTILE FORTULUI (Track17, Jodhpur,
## frac 0.474-0.588: Jai Pol, Fateh Pol, Loha Pol pe zigzagul de pe stanca).
##
## Nu e sonda: CALCULEAZA transformarile care se lipesc in Track17.tscn sub
## `DecorManual/ZoneE_Porti` (tiparul gen_decor_fiord_e.gd).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorJodE.tscn -- \
##       --out=C:/cale/zoneE.part [--survey] [--mesh]
##
## `--survey` scrie profilul traseului pe E (raza, panta, semilatime, bratele
## vecine pe fiecare parte si cota lor) si nu genereaza nimic. `--mesh` scrie
## structura pieselor de fort (crenelurile zidului, pragul portii).
##
## ------------------------------------------------------------------------
## CONTRACTUL (jodhpur_poi_gauntlet.md, sectiunea E; decizia dezvoltatorului
## 29 sep 2026: DOP DE 7 M)
##
## - Portile la scara 1,0 (gol 7,16 m, cheia 9,35 m), axa X pe tangenta,
##   originea pe axul golului, pe axa drumului. Drumul se ingusteaza la
##   semilatimea 3,5 pe +-6 m in jurul fiecarei porti (Track17
##   `custom_width_pinches`), deci usciorii (+-3,58) stau in linie cu muchia.
## - Zidurile: `fort_wall_segment` (12 m pe Z, 3,6 grosime pe X, 13,98 inalt,
##   capete plane — se inlantuie). Intre doua brate ale zigzagului zidul e UNUL:
##   parapet crenelat pentru bratul de SUS (varful la +PARAPET_TOP peste drum)
##   si zid de sprijin pentru bratul de JOS (se vede de acolo ~6 m de piatra).
##   Pe partea fara brat vecin: spre stanca = zidul inalt intreg, spre oras =
##   parapet. Turnurile rotunde (`fort_wall_turret`) pe exteriorul acelor.
## - `langur` pe parapet (coliziune none), `rhyolite_boulder_*` la piciorul
##   zidului inalt.
## - Granita cu F: nimic dupa frac 0.588, nimic cu baza peste +38 m.

const TRACK := "res://scenes/tracks/Track17.tscn"
const ZONE := "DecorManual/ZoneE_Porti"

const F_IN := 0.474
const F_OUT := 0.588
const Y_MAX := 38.0

## Portile: (model, frac). Fractiile vin din survey (drepte dupa ace), vezi
## antetul de masuratori din raport.
const GATES := [
	["fort_gate_jai", 0.50834],
	["fort_gate_fateh", 0.55152],
	["fort_gate_loha", 0.57409],
]
## Jumatatea adancimii portii pe X (8,64 / 2): zidurile se opresc in fata
## turnurilor (si intra in ele cu depasirea capatului).
const GATE_HALF_DEPTH := 4.32

const RES := {
	"fort_gate_jai": "s_fort_gate_jai",
	"fort_gate_fateh": "s_fort_gate_fateh",
	"fort_gate_loha": "s_fort_gate_loha",
	"fort_wall_segment": "s_fort_wall_segment",
	"fort_wall_turret": "s_fort_wall_turret",
	"langur": "s_langur",
	"marigold_garland": "s_marigold_garland",
	"rhyolite_boulder_a": "s_rhyolite_boulder_a",
	"rhyolite_boulder_b": "s_rhyolite_boulder_b",
	"rhyolite_boulder_c": "s_rhyolite_boulder_c",
}

const WALL_H := 13.98
const WALL_LEN := 12.0
const WALL_HALF_T := 1.8
## Varful crenelurilor parapetului (partea caderii) peste cota drumului:
## crenelurile au ~1,2 m (vertecsii zidului: goluri la 12,75, merloni la 14,0),
## deci 2,4 lasa 1,2 m de zid plin sub ele.
const PARAPET_TOP := 2.4
## Varful zidului de pe partea de sus (spre stanca si bratul urmator): 9 m,
## sub ochiul camerei (10 m) - zid de fort din masina, dar de pe bratul de
## deasupra (+4,5 m) doar o linie de creneluri la 30-40 m, nu un paravan
## peste oras.
const UPHILL_TOP := 9.0
## Turnurile rotunde de pe exteriorul acelor.
const TURRET_TOP := 10.5
## Degajarea muchie de asfalt -> fata zidului (parapet / zidul de sus, unde
## intra bolovanii la picior).
const WALL_GAP := 2.0
## Coarda minima si abaterea maxima a zidului de la linia lui pe curba.
const WALL_MIN_LEN := 4.0
const SAG_MAX := 0.35
const LANGUR_P := 0.3
## RUNDA 2 (criticul: „linia drumului se deseneaza in puncte de lumina").
## Varfurile merloanelor lui `fort_wall_segment`, masurate pe GLB: z = -4,8 /
## -2,4 / 0 / 2,4 / 4,8, varful la y 13,98, pe x 0,8..1,5.
const MERLON_TIP_Y := 13.98
const MERLON_X := 1.15
## RUNDA 3 (criticul, pe scena integrata: „diyas mici si dese, cate una pe
## fiecare merlon", ca silueta crenelata sa se citeasca drept linie de
## lumini). O diya pe FIECARE din cei 5 merloni ai fiecarei bucati (pas 2,4 m
## in bucata, 1,2..2,4 peste imbinare), pe parapet si pe zidul inalt.
## Runda 2 avea globuri de 0,28 m pe 3 din 5 merloni — „4-5 globuri mari".
const MERLON_Z := [-4.8, -2.4, 0.0, 2.4, 4.8]
const DIYA_R := 0.13
## Felinarele din nisele fetei goale a zidului inalt (fata dinspre drum), la
## ~2,5 m peste drum (y local 7,5 = varful 13,98 minus 6,5; varful zidului inalt
## e la +9 peste drum). Doua pe bucata intreaga.
const NICHE_Z := [-3.6, 3.6]
const NICHE_Y := 7.5
const NICHE_R := 0.2
const NICHE_STRETCH := 1.4
## Portile: sirul de pe muchia de sus. Varfurile merloanelor peretelui dintre
## turnuri si coroanele celor doua turnuri, luate din GLB (sloturile *_Glow
## de sub fiecare merlon dau z-ul; varful pietrei da y-ul): z pe peretele
## central si (x, z) pe coroanele turnurilor, y = varful merlonului.
const GATE_TOP := {
	"fort_gate_jai": {"wall_y": 13.28, "tower_y": 16.28,
		"wall_z": [-7.3, -5.8, -4.4, -2.9, -1.5, 0.0, 1.5, 2.9, 4.4, 5.8, 7.3]},
	"fort_gate_fateh": {"wall_y": 13.2, "tower_y": 15.2,
		"wall_z": [-7.4, -6.2, -4.9, -3.7, -2.5, 2.5, 3.7, 4.9, 6.2, 7.4]},
	"fort_gate_loha": {"wall_y": 12.13, "tower_y": 14.19,
		"wall_z": [-7.3, -5.8, -4.4, -2.9, -1.5, 0.0, 1.5, 2.9, 4.4, 5.8, 7.3]},
}
const GATE_WALL_X := 1.1
## Coroana unui turn de poarta (centrul la z +-12), in jumatatea lui: (x, dz).
const GATE_TOWER_RIM := [Vector2(4.0, 0.85), Vector2(4.0, -0.85),
	Vector2(3.4, 2.2), Vector2(3.4, -2.2), Vector2(2.3, 3.4), Vector2(2.3, -3.4),
	Vector2(0.8, 4.0), Vector2(0.8, -4.0), Vector2(-0.8, 4.0), Vector2(-0.8, -4.0),
	Vector2(-2.3, 3.4), Vector2(-2.3, -3.4), Vector2(-3.4, 2.2), Vector2(-3.4, -2.2),
	Vector2(-4.0, 0.85), Vector2(-4.0, -0.85)]
## Turnul rotund de zid: coroana din `Turret_Glow` (16 puncte la raza ~3,4).
const TURRET_RIM := [Vector2(3.4, 0.0), Vector2(3.4, 1.5), Vector2(3.4, -1.5),
	Vector2(-3.4, 0.0), Vector2(-3.4, 1.5), Vector2(-3.4, -1.5),
	Vector2(0.0, 3.4), Vector2(1.5, 3.4), Vector2(-1.5, 3.4),
	Vector2(0.0, -3.4), Vector2(1.5, -3.4), Vector2(-1.5, -3.4),
	Vector2(2.9, 2.8), Vector2(2.9, -2.8), Vector2(-2.9, 2.8), Vector2(-2.9, -2.8)]
## Tortele portilor: DOUA, pe fata dinspre care vii (x -4,6; fata portii e la
## x -4,32), la stalpii arcului (golul se termina la +-3,58), deasupra
## acoperisului oricarei masini. Runda 2: si pe fata de iesire erau doua, dar
## camera trece la 2-3 m de ele dupa poarta si ieseau romburi de 1,3 m in
## prim-plan (captura 0.555).
const TORCH_LOCAL := [Vector3(-4.6, 4.4, 4.7), Vector3(-4.6, 4.4, -4.7)]
const TORCH_R := 0.3
const TORCH_STRETCH := 1.6
## Turnurile rotunde: merlonii de pe coroana, la raza ~3,05, varful 16,98.
const TURRET_TIP_Y := 16.98
## Pana unde (lateral, de la ax) se cauta un brat vecin.
const NEIGHBOR_REACH := 40.0

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
## Lampile (runda 2): pozitie in lume, raza, alungire. Le deseneaza FortLamps.
var _lamp_pos := PackedVector3Array()
var _lamp_r := PackedFloat32Array()
var _lamp_s := PackedFloat32Array()
var _n := 0
var _tri := 0
var _skipped := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _mesh_only := false
var _total_len := 1.0
var _rock := Vector3(135.0, 0.0, -275.0)
var _space: PhysicsDirectSpaceState3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
		elif a == "--mesh":
			_mesh_only = true
	await get_tree().process_frame
	if _mesh_only:
		_mesh_report()
		get_tree().quit(0)
		return
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte" % [_total_len, nd])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 290926
	_survey()
	if not _survey_only:
		_gates()
		_walls()
		_turrets()
		_lamps_node()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ geometrie

func _idx(frac: float) -> int:
	var n := _track.baked.size()
	return int(round(fposmod(frac, 1.0) * float(n))) % n


func _tangent(i: int) -> Vector3:
	var n := _track.baked.size()
	var d := _track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n]
	d.y = 0.0
	return d.normalized()


## Stanga orizontala (tangenta x UP da dreapta, ca `Track._side_at`).
func _left(i: int) -> Vector3:
	var t := _tangent(i)
	return Vector3(t.z, 0.0, -t.x)


func _radius(i: int) -> float:
	var n := _track.baked.size()
	var a := _track.baked[(i - 4 + n) % n]
	var b := _track.baked[i]
	var c := _track.baked[(i + 4) % n]
	var A := Vector2(a.x, a.z)
	var B := Vector2(b.x, b.z)
	var C := Vector2(c.x, c.z)
	var cross := absf((B - A).cross(C - A))
	if cross < 1e-4:
		return 9999.0
	return (B - A).length() * (C - B).length() * (A - C).length() / (2.0 * cross)


func _slope(i: int) -> float:
	var n := _track.baked.size()
	var a := _track.baked[(i - 2 + n) % n]
	var b := _track.baked[(i + 2) % n]
	return (b.y - a.y) / maxf(Vector2(b.x - a.x, b.z - a.z).length(), 0.01)


## Cel mai apropiat ALT brat pe partea `sgn` (+1 stanga): distanta laterala de
## la ax la muchia lui si cota lui fata de drum. (INF, 0) = nimic pana la
## NEIGHBOR_REACH.
func _neighbor(i: int, sgn: float) -> Vector2:
	var n := _track.baked.size()
	var p := _track.baked[i]
	var side := _left(i) * sgn
	var skip := int(ceil(40.0 / (_total_len / float(n))))
	var lat := 3.0
	while lat <= NEIGHBOR_REACH:
		var q := p + side * lat
		for j in n:
			var dj := absi(j - i)
			dj = mini(dj, n - dj)
			if dj <= skip:
				continue
			var b := _track.baked[j]
			if absf(b.y - p.y) > 15.0:
				continue
			if Vector2(q.x - b.x, q.z - b.z).length() < _track.width_at_index(j):
				return Vector2(lat, b.y - p.y)
		lat += 1.0
	return Vector2(INF, 0.0)


## Cel mai apropiat punct de ALT brat (in afara ferestrei de +-40 m) fata de
## punctul lateral la 14 m pe partea `sgn`: (distanta in plan, dy fata de noi).
func _nearest_other(i: int, sgn: float) -> Vector2:
	var n := _track.baked.size()
	var p := _track.baked[i]
	var q := p + _left(i) * sgn * 14.0
	var skip := int(ceil(40.0 / (_total_len / float(n))))
	var best := INF
	var dy := 0.0
	for j in n:
		var dj := absi(j - i)
		dj = mini(dj, n - dj)
		if dj <= skip:
			continue
		var b := _track.baked[j]
		var d := Vector2(q.x - b.x, q.z - b.z).length()
		if d < best:
			best = d
			dy = b.y - p.y
	return Vector2(best, dy)


func _toward_rock(i: int, sgn: float) -> bool:
	var p := _track.baked[i]
	var to := Vector3(_rock.x - p.x, 0.0, _rock.z - p.z)
	return (_left(i) * sgn).dot(to) > 0.0


func _survey() -> void:
	print("; frac   i    x       z      y     semi  raza   panta%%  st:lat/dy       dr:lat/dy     stanca")
	var f := 0.470
	while f <= 0.592 + 1e-6:
		var i := _idx(f)
		var p := _track.baked[i]
		var l := _nearest_other(i, 1.0)
		var r := _nearest_other(i, -1.0)
		print("; %.3f %4d %7.1f %7.1f %6.2f %5.2f %6.1f %6.1f   %5.1f/%+5.1f   %5.1f/%+5.1f   %s" % [
			f, i, p.x, p.z, p.y, _track.width_at_index(i), _radius(i),
			100.0 * _slope(i), l.x, l.y, r.x, r.y,
			"st" if _toward_rock(i, 1.0) else "dr"])
		f += 0.002


# ------------------------------------------------------------------ piese

func _gates() -> void:
	for g in GATES:
		var model: String = g[0]
		var i := _idx(float(g[1]))
		var p := _track.baked[i]
		var t := _tangent(i)
		var left := _left(i)
		# X pe tangenta, Z = stanga -> baza dreapta (X x Y = Z).
		var b := Basis(t, Vector3.UP, -left)
		if b.determinant() < 0.0:
			b = Basis(t, Vector3.UP, left)
		# Baza la cota drumului in centru, coborata 0,3 m (masuratori §4.2).
		var pos := Vector3(p.x, p.y - 0.3, p.z)
		_raw_basis(model, "PoartaFort" + model.trim_prefix("fort_gate_").capitalize() + "_", pos, b, "")
		# Tesirea usciorilor (GateFunnel, ProbeRace seed 11 pe scena integrata):
		# acelasi transform ca poarta, frate in zona (nu copil al instantei GLB).
		_out.append('[node name="TesirePoarta%s" type="StaticBody3D" parent="%s"]'
			% [model.trim_prefix("fort_gate_").capitalize(), ZONE])
		_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
			% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
				pos.x, pos.y, pos.z])
		_out.append('script = ExtResource("e_gate_funnel")')
		_out.append("")
		for lp: Vector3 in TORCH_LOCAL:
			_lamp(pos + b * lp, TORCH_R, TORCH_STRETCH)
		var gt: Dictionary = GATE_TOP[model]
		for wz: float in gt["wall_z"]:
			_lamp(pos + b * Vector3(GATE_WALL_X, float(gt["wall_y"]) + DIYA_R * 0.8, wz),
				DIYA_R, 1.0)
		for tz: float in [-12.0, 12.0]:
			for rim: Vector2 in GATE_TOWER_RIM:
				_lamp(pos + b * Vector3(rim.x, float(gt["tower_y"]) + DIYA_R * 0.8,
					tz + rim.y), DIYA_R, 1.0)
		print("; poarta %s la frac %.4f (i %d) pos %s, tangenta %s, raza %.1f, panta %.1f%%" % [
			model, float(g[1]), i, str(pos), str(t), _radius(i), 100.0 * _slope(i)])


## Axa urcarii zigzagului (de la Jai Pol la iesirea spre bastion). Partea unui
## brat spre care arata axa e partea DE SUS (spre bratul urmator si stanca);
## cealalta e caderea spre oras. NU stanga/dreapta: bratele alterneaza SE/SV,
## deci orasul e pe dreapta la bratele spre SE si pe stanga la cele spre SV.
func _uphill_sign(i: int) -> float:
	var a := _track.baked[_idx(F_IN)]
	var b := _track.baked[_idx(F_OUT)]
	var ax := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
	return 1.0 if _left(i).dot(ax) > 0.0 else -1.0


## Unde NU se pun ziduri: portile (fata turnurilor, +-GATE_HALF_DEPTH) si
## acele (raza < HAIRPIN_R).
const HAIRPIN_R := 40.0

func _s(i: int) -> float:
	return float(_track._dists[i])


func _blocked(i: int) -> bool:
	for g in GATES:
		var gi := _idx(float(g[1]))
		if absf(_s(i) - _s(gi)) < GATE_HALF_DEPTH:
			return true
	return false


## Zidurile de-a lungul bratelor. Pe fiecare interval liber (intre porti si
## ace), pe fiecare parte, se merge pe linia paralela cu axa si se pun bucati
## de WALL_LEN cap la cap pe COARDA (capetele a doua bucati vecine coincid,
## deci zidul e continuu si pe curba).
func _walls() -> void:
	var i0 := _idx(F_IN)
	var i1 := _idx(F_OUT)
	var runs: Array = []
	var start := -1
	for i in range(i0, i1 + 1):
		if _blocked(i):
			if start >= 0:
				runs.append([start, i - 1])
				start = -1
		elif start < 0:
			start = i
	if start >= 0:
		runs.append([start, i1])
	var n := float(_track.baked.size())
	for r in runs:
		var a: int = r[0]
		var b: int = r[1]
		if _s(b) - _s(a) < 4.0:
			continue
		print("; interval zid %.4f-%.4f (%.1f m)" % [float(a) / n, float(b) / n,
			_s(b) - _s(a)])
		for sgn: float in [1.0, -1.0]:
			_wall_run(a, b, sgn)


func _offset_pt(i: int, sgn: float) -> Vector3:
	var half := maxf(_track.width_at_index(i), 4.5)
	return _track.baked[i] + _left(i) * sgn * (half + WALL_GAP + WALL_HALF_T)


func _wall_run(a: int, b: int, sgn: float) -> void:
	var pts: Array[Vector3] = []
	var idx: Array[int] = []
	for i in range(a, b + 1):
		pts.append(_offset_pt(i, sgn))
		idx.append(i)
	if pts.size() < 2:
		return
	var nf := float(_track.baked.size())
	# Capatul de start: prelungit cu 3 m inapoi, in turnul portii / spre ac.
	var cur := _along(pts, -3.0)
	var guard := 0
	while int(cur[1]) < pts.size() - 1 and guard < 200:
		guard += 1
		# Coarda adaptiva: 12 m pe drept, mai scurta pe curba, cat sa nu se
		# departeze de linia zidului cu mai mult de SAG_MAX (altfel imbinarile
		# dintre bucati se casca).
		var len := WALL_LEN
		var nxt := _chord_next(pts, cur, len)
		while len > WALL_MIN_LEN and _sag(pts, cur, nxt) > SAG_MAX:
			len *= 0.85
			nxt = _chord_next(pts, cur, len)
		var p0: Vector3 = cur[0]
		var p1: Vector3 = nxt[0]
		var c := (p0 + p1) * 0.5
		var z := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z).normalized()
		var ci: int = idx[clampi(int(round(float(int(cur[1]) + int(nxt[1])) * 0.5)), 0, idx.size() - 1)]
		cur = nxt
		c.y = _track.baked[ci].y
		var kind := "sprijin" if sgn == _uphill_sign(ci) else "parapet"
		if not _footprint_clear(c, z, len * 0.5, WALL_HALF_T, 0.8):
			_skipped += 1
			continue
		var road_y := _track.baked[ci].y
		var g := _sol_real(c.x, c.z)
		var top := road_y + (PARAPET_TOP if kind == "parapet" else UPHILL_TOP)
		top = maxf(top, g + 1.2)
		var base_y := top - WALL_H
		if base_y > Y_MAX:
			_skipped += 1
			continue
		var x := Vector3.UP.cross(z).normalized()
		var wb := Basis(x, Vector3.UP, z * (len / WALL_LEN))
		var wpos := Vector3(c.x, base_y, c.z)
		_raw_basis("fort_wall_segment", "zid", wpos, wb, "")
		if g - base_y > 2.0:
			_meta_last("metadata/scufundat = true")
		var toward_road := _track.baked[ci] - c
		toward_road.y = 0.0
		toward_road = toward_road.normalized()
		# Diyas pe varful FIECARUI merlon (runda 3). Pe o bucata scurtata pe
		# curba merlonii se strang odata cu ea (wb poarta scara pe Z).
		for lz: float in MERLON_Z:
			_lamp(wpos + wb * Vector3(MERLON_X, MERLON_TIP_Y + DIYA_R * 0.8, lz),
				DIYA_R, 1.0)
		# Felinarele din nise, pe fata dinspre drum a zidului inalt.
		if kind == "sprijin" and len > 8.0:
			var face_x := (WALL_HALF_T + 0.12) * (1.0 if x.dot(toward_road) > 0.0 else -1.0)
			for nz: float in NICHE_Z:
				_lamp(wpos + wb * Vector3(face_x, NICHE_Y, nz), NICHE_R, NICHE_STRETCH)
		# Ghirlanda de craite pe fata dinspre drum a parapetului, atarnata de
		# coama (originea ei e SUS, atarna 1,09 m), cate una pe bucata intreaga.
		if kind == "parapet" and len > 8.0:
			var gz: float = [-2.4, 0.0, 2.4][_rng.randi_range(0, 2)]
			var face := wpos + wb * Vector3(0.0, 0.0, gz) + toward_road * (WALL_HALF_T + 0.12)
			var gb := Basis(z, Vector3.UP, z.cross(Vector3.UP))
			_raw_basis("marigold_garland", "ghirlanda", Vector3(face.x, top - 0.1, face.z),
				gb, "none")
		if kind == "parapet" and _rng.randf() < LANGUR_P:
			var lp := c + z * _rng.randf_range(-0.35, 0.35) * len
			var yaw := atan2(toward_road.x, toward_road.z) + _rng.randf_range(-0.9, 0.9)
			_raw("langur", "langur", Vector3(lp.x, top, lp.z), yaw, 1.0, "none")
		if kind == "sprijin":
			var k2 := _rng.randi_range(0, 2) if len > 8.0 else 0
			for m in k2:
				var model: String = ["rhyolite_boulder_a", "rhyolite_boulder_b",
					"rhyolite_boulder_c"][_rng.randi_range(0, 2)]
				var scl := _rng.randf_range(0.6, 0.85)
				# Centrul 0,5 m in zid: bolovanul sta pe jumatate
				# in zid, la picior. Cu centrul in fata zidului (runda 1) cadea la
				# < 2 m de muchie si probe_manual il dadea IN DRUM.
				var bp := c + z * _rng.randf_range(-5.0, 5.0) \
					+ toward_road * (WALL_HALF_T - 0.5)
				bp.y = c.y
				if not _footprint_clear(bp, z, 1.5 * scl, 1.5 * scl, 0.8):
					continue
				_raw(model, "bolovan", Vector3(bp.x, _sol_real(bp.x, bp.z) - 0.3, bp.z),
					_rng.randf_range(0.0, TAU), scl, "hull")


## Cat se departeaza polilinia de coarda cur..nxt (m, in plan).
func _sag(pts: Array[Vector3], cur: Array, nxt: Array) -> float:
	var p0: Vector3 = cur[0]
	var p1: Vector3 = nxt[0]
	var a := Vector2(p0.x, p0.z)
	var d := Vector2(p1.x, p1.z) - a
	var l := d.length()
	if l < 1e-3:
		return 0.0
	d /= l
	var worst := 0.0
	for k in range(int(cur[1]) + 1, mini(int(nxt[1]) + 1, pts.size())):
		var q := Vector2(pts[k].x, pts[k].z) - a
		worst = maxf(worst, absf(q.x * d.y - q.y * d.x))
	return worst


## Punctul de pe polilinie la distanta `s` (m) de la inceput (negativ =
## prelungit inapoi pe primul segment). Intoarce [punct, index_segment].
func _along(pts: Array[Vector3], s: float) -> Array:
	if s <= 0.0:
		var d := pts[0] - pts[1]
		d.y = 0.0
		return [pts[0] + d.normalized() * (-s), 0]
	var acc := 0.0
	for k in range(1, pts.size()):
		var l := Vector2(pts[k].x - pts[k - 1].x, pts[k].z - pts[k - 1].z).length()
		if acc + l >= s:
			return [pts[k - 1].lerp(pts[k], (s - acc) / maxf(l, 1e-4)), k - 1]
		acc += l
	return [pts[pts.size() - 1], pts.size() - 1]


## Urmatorul punct la COARDA `len` de `cur` (in plan), mergand inainte pe
## polilinie; dupa capat se prelungeste pe ultima directie.
func _chord_next(pts: Array[Vector3], cur: Array, len: float) -> Array:
	var p0: Vector3 = cur[0]
	var k: int = maxi(int(cur[1]), 0)
	while k + 1 < pts.size():
		var q := pts[k + 1]
		if Vector2(q.x - p0.x, q.z - p0.z).length() >= len:
			var lo := pts[k]
			var hi := q
			for _i in 30:
				var m := (lo + hi) * 0.5
				if Vector2(m.x - p0.x, m.z - p0.z).length() >= len:
					hi = m
				else:
					lo = m
			return [hi, k]
		k += 1
	var last := pts[pts.size() - 1]
	var d := last - pts[pts.size() - 2]
	d.y = 0.0
	d = d.normalized()
	var w := Vector2(last.x - p0.x, last.z - p0.z)
	var dv := Vector2(d.x, d.z)
	var bq := w.dot(dv)
	var cq := w.length_squared() - len * len
	var t := -bq + sqrt(maxf(bq * bq - cq, 0.0))
	return [last + d * t, pts.size() - 1]


## Dreptunghiul (centru c, axa lunga z, semi-lungime hl, semi-latime hw) sta la
## cel putin `keep` m de muchia ORICARUI tronson de asfalt (in plan)?
func _footprint_clear(c: Vector3, z: Vector3, hl: float, hw: float,
		keep: float) -> bool:
	var x := Vector3.UP.cross(z).normalized()
	var n := _track.baked.size()
	for u: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var q := c + z * (u * hl) + x * (v * hw)
			for j in n:
				var b := _track.baked[j]
				if absf(b.y - c.y) > 30.0:
					continue
				var d := Vector2(q.x - b.x, q.z - b.z).length()
				if d < _track.width_at_index(j) + keep:
					return false
	return true


## Turn rotund pe exteriorul fiecarui ac (raza minima pe fereastra).
func _turrets() -> void:
	var n := _track.baked.size()
	var i0 := _idx(F_IN)
	var i1 := _idx(F_OUT)
	var i := i0 + 2
	while i < i1 - 2:
		var r := _radius(i)
		if r < 20.0 and r <= _radius(i - 1) and r <= _radius(i + 1):
			var p := _track.baked[i]
			var a := _track.baked[(i - 4 + n) % n]
			var c := _track.baked[(i + 4) % n]
			var mid := (a + c) * 0.5
			var out := Vector3(p.x - mid.x, 0.0, p.z - mid.z).normalized()
			var half := maxf(_track.width_at_index(i), 4.5)
			# Pe linia zidului, impins 1,5 m in afara: zidul intra in turn.
			var q := p + out * (half + WALL_GAP + WALL_HALF_T + 1.5)
			q.y = p.y
			if _footprint_clear(q, out, 3.75, 3.75, 1.0):
				var top := p.y + TURRET_TOP
				var by := top - 16.98
				if by <= Y_MAX:
					# Yaw ALINIAT pe `out`, nu aleator: soclul turnului e PATRAT
					# (7,5 x 7,5), iar `_footprint_clear` de mai sus testeaza patratul
					# aliniat pe `out`. Cu yaw aleator (runda 1) un colt ajungea cu
					# pana la 1,55 m mai aproape de asfalt decat testul — pe runda 2
					# (alt yaw din acelasi rng) ProbeRace a dat 3 repuneri la 0,500 si
					# un [blocaj] la 0,561, langa turnurile acelor.
					var tyaw := atan2(out.x, out.z)
					_raw("fort_wall_turret", "turn", Vector3(q.x, by, q.z), tyaw, 1.0, "")
					var tb := Basis.from_euler(Vector3(0.0, tyaw, 0.0))
					for rim: Vector2 in TURRET_RIM:
						_lamp(Vector3(q.x, by, q.z) + tb * Vector3(rim.x,
							TURRET_TIP_Y + DIYA_R * 0.8, rim.y), DIYA_R, 1.0)
					if _sol_real(q.x, q.z) - by > 2.0:
						_meta_last("metadata/scufundat = true")
			else:
				print("; turn sarit la frac %.4f" % (float(i) / float(n)))
			i += 8
		else:
			i += 1


# ------------------------------------------------------------------ iesire

func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_raw_basis(model, base, pos, b, mode)


func _raw_basis(model: String, base: String, pos: Vector3, b: Basis,
		mode: String) -> void:
	_n += 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "" and mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	if model.begins_with("fort_gate"):
		# Camera: piatra de deasupra arcului o opreste (ChaseCamera._unclip).
		_out.append("metadata/camera_blocker = true")
	_out.append("")


func _lamp(p: Vector3, r: float, st: float) -> void:
	_lamp_pos.append(p)
	_lamp_r.append(r)
	_lamp_s.append(st)


## Nodul FortLamps (un MultiMesh emisiv) cu toate lampile zonei.
func _lamps_node() -> void:
	_out.append('[node name="LampiFort" type="Node3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("e_fort_lamps")')
	var ps: Array[String] = []
	for v in _lamp_pos:
		ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
	_out.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
	var rs: Array[String] = []
	for v in _lamp_r:
		rs.append("%.2f" % v)
	_out.append("radii = PackedFloat32Array(%s)" % ", ".join(rs))
	var ss: Array[String] = []
	for v in _lamp_s:
		ss.append("%.2f" % v)
	_out.append("stretch = PackedFloat32Array(%s)" % ", ".join(ss))
	_out.append("")
	print("; lampi: %d (din care torte %d)" % [_lamp_pos.size(), GATES.size() * TORCH_LOCAL.size()])


## Adauga o linie de metadata la ULTIMUL nod scris (inaintea liniei goale).
func _meta_last(line: String) -> void:
	_out.insert(_out.size() - 1, line)


func _write() -> void:
	print("; asezate %d piese, %d sarite" % [_n, _skipped])
	if _out_path.is_empty():
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for line in _out:
		fa.store_line(line)
	fa.close()
	print("; scris %s" % _out_path)


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		var hit: Dictionary = _space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = _space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _sampler.ground_y(x, z)


# ------------------------------------------------------------------ --mesh

func _mesh_report() -> void:
	for stem in ["fort_wall_segment", "fort_gate_jai", "fort_wall_turret"]:
		var path := "res://assets/models/jodhpur/structures/%s.glb" % stem
		var root := (load(path) as PackedScene).instantiate()
		add_child(root)
		var ys := {}
		var low_in_gap := 0
		var lo := Vector3(INF, INF, INF)
		var hi := -lo
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var xf := _xf_to(m, root)
			for s in m.mesh.get_surface_count():
				var arr := m.mesh.surface_get_arrays(s)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				for w in v:
					var pw := xf * w
					lo = lo.min(pw)
					hi = hi.max(pw)
					if pw.y > 11.0:
						var k := snappedf(pw.y, 0.25)
						ys[k] = int(ys.get(k, 0)) + 1
					if stem == "fort_gate_jai" and absf(pw.z) < 3.4 and pw.y < 0.6:
						low_in_gap += 1
		print("; %s AABB %s .. %s" % [stem, str(lo), str(hi)])
		var keys := ys.keys()
		keys.sort()
		for k in keys:
			print(";   y %.2f : %d vertecsi" % [k, ys[k]])
		if stem == "fort_gate_jai":
			print(";   vertecsi in gol (|z|<3.4, y<0.6): %d" % low_in_gap)
		root.queue_free()


func _xf_to(n: Node3D, root: Node) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p != null and p != root:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf
