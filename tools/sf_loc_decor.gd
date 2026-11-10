extends Node3D
## TESTUL DE LOC SAN FRANCISCO (docs/track_briefs/san_francisco.md §7 pasul 0).
## Decorul strazii sintetice `tools/SfLoc.tscn`, construit in COD: testul e despre loc si
## paleta, nu despre detaliul kitului (care vine la pasul 2, ca GLB-uri).
##
## Ce pune, dupa brief §0.1 / §4:
##   - CASELE: randuri lipite pe ambele laturi, 3 niveluri (garaj la strada + doua etaje),
##     BOVINDOU pe fiecare, cornisa si ancadramente FOAM_WHITE, acoperis VOLCANIC_BLACK
##     (fronton spre strada sau plat cu cornisa), fiecare pe SOCLUL EI IN PANA: podeaua
##     casei e la cota trotuarului din capatul de SUS, deci pe panta acoperisurile coboara
##     in trepte. Peretii pe clasa `sf_clapboard` in cele cinci pasteluri (cinci tente).
##   - strada: trotuare de beton cu bordura, ZEBRE (FOAM_WHITE) pe cele doua muchii,
##     strazile transversale ale intersectiilor plate, o masina parcata PERPENDICULAR pe
##     blocul abrupt (inclinata lateral, cum se parcheaza acolo).
##   - fundalul: podul rosu (KERB_RED 7) peste golf, in stanga; insula cu far; dealurile
##     aurii din Marin (`macchia_dry`) pe tarmul de dincolo. Apa e a temei (laguna).
##
## O casa = doua noduri: `Clap_<n>` (peretii de scandura, cate o suprafata pe orientare fata
## de soare — "lit"/"graze"/"shade", in `meta sf_orient`; `meta sf_pastel` = indexul tentei) si
## `Atlas_<n>` (tot restul, pe `Palette.world_material()`). Asa sonda de loc
## (`tools/probe_sf_loc.gd`) poate atribui pixelii pe pastel si pe orientare fara caseta.
## Orientarea se socoteste fata de soarele TEMEI (`sun_rotation_deg`), nu e scrisa de mana.
##
## Nord = -Z, est = +X. Strada coboara spre nord pe x = 0 (vezi tools/gen_sf_loc.py).

const PASTELS: Array[String] = ["sf_clapboard", "sf_clapboard_pink", "sf_clapboard_blue",
	"sf_clapboard_mint", "sf_clapboard_butter"]
const PASTEL_NAMES: Array[String] = ["crem", "roz", "albastru", "menta", "galben"]

## Strada: semilatimea carosabilului si fata caselor (trotuar de 3,5 m).
const ROAD_HALF: float = 7.0
const FACADE_X: float = 10.5
const HOUSE_W: float = 7.0
const HOUSE_D: float = 12.0
const LEVEL_H: float = 3.2
const LEVELS: int = 3
const CURB_H: float = 0.15
## Pragul N.L sub care o fata cu fata spre soare e doar RAZANTA (vezi `_clap_st`).
const GRAZE_NL: float = 0.25

## Randurile de case: (latura, z-ul capatului de SUS, numar de case).
const ROWS: Array = [
	[1, 96.0, 6], [-1, 96.0, 6],
	[1, 21.0, 6], [-1, 21.0, 6],
	[1, -51.0, 6], [-1, -51.0, 6],
	[1, -99.0, 4], [-1, -99.0, 4],
]
## Intersectiile plate (centru z, semilatime): acolo trotuarul se intrerupe.
const CROSS: Array = [[36.0, 7.0], [-36.0, 7.0]]
## Muchiile cu zebra: zebra sta pe platul de DINAINTEA muchiei (z de la, z pana la).
const ZEBRAS: Array = [[25.0, 28.0], [-47.0, -44.0]]

var _track: Track
var _to_sun: Vector3 = Vector3(0, 1, 0)
var _street: PackedVector2Array = PackedVector2Array() # (z, y) pe axa strazii, sortat dupa z
var _house_n: int = 0
var _ao_base: float = 0.0
var _ao_span: float = 4.0

# SurfaceTool-urile casei curente
var _st_lit: SurfaceTool
var _st_shade: SurfaceTool
var _st_graze: SurfaceTool
var _st_atlas: SurfaceTool
var _cur_pastel: int = 0
## Transformarea casei curente: casele se construiesc intr-un cadru LOCAL (strada pe z, fatada
## la x = latura * FACADE_X) si se aseaza in lume prin ea — randul din spate si randurile de
## pe strazile transversale refolosesc acelasi constructor.
var _xf: Transform3D = Transform3D.IDENTITY


func _ready() -> void:
	call_deferred("_build")


func _build() -> void:
	_track = get_parent() as Track
	if _track == null:
		push_error("sf_loc_decor: parintele nu e Track")
		return
	var rot: Vector3 = _track._sun_rotation_deg()
	var b := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	_to_sun = -(b * Vector3.FORWARD)
	_collect_street()
	_hide_start_line()
	_build_street_furniture()
	var idx := 0
	for row: Array in ROWS:
		var s: int = row[0]
		var z0: float = row[1]
		var n: int = row[2]
		for i in n:
			var za := z0 - float(i) * HOUSE_W
			# Pastelul: decalat pe latura si pe rand, ca vecinii sa difere mereu.
			var p := (i * 2 + (0 if s > 0 else 3) + idx) % PASTELS.size()
			var roof := "gable" if ((i + idx + (1 if s > 0 else 0)) % 3) != 1 else "flat"
			_xf = Transform3D.IDENTITY
			_build_house(s, za, p, roof)
			# randul din SPATE (aceeasi cota), ca deasupra acoperisurilor sa fie oras, nu iarba
			_xf = Transform3D(Basis.IDENTITY, Vector3(float(s) * (HOUSE_D + 0.5), 0.0, 0.0))
			_build_house(s, za, (p + 2) % PASTELS.size(), "flat" if roof == "gable" else "gable")
		idx += 1
	# Randurile de pe STRAZILE TRANSVERSALE (plate): cadrul local are strada pe z, deci
	# z local -> x lumii, x local -> -z lumii; casele incep dincolo de colturile randurilor
	# principale (|x| >= 23).
	for c: Array in CROSS:
		var zc: float = c[0]
		var yflat := road_y(zc)
		_xf = Transform3D(Basis(Vector3(0, 0, -1), Vector3.UP, Vector3(1, 0, 0)), Vector3(0, 0, zc))
		for s: int in [1, -1]:
			for e: float in [1.0, -1.0]:
				for i in 6:
					var za := (23.0 + HOUSE_W * float(i + 1)) if e > 0.0 else -(23.0 + HOUSE_W * float(i))
					var p := (i * 3 + (1 if s > 0 else 4) + (2 if e > 0.0 else 0) + idx) % PASTELS.size()
					var roof := "gable" if (i + idx) % 3 != 2 else "flat"
					_build_house(s, za, p, roof, yflat)
				idx += 1
	_xf = Transform3D.IDENTITY
	_hide_chevrons()
	_build_parked_car()
	_build_bridge()
	_build_island()
	_build_hills()
	print("sf_loc_decor: %d case, soare spre (%.3f, %.3f, %.3f)"
		% [_house_n, _to_sun.x, _to_sun.y, _to_sun.z])


# --------------------------------------------------------------------- strada

func _collect_street() -> void:
	var pts: Array[Vector2] = []
	for p: Vector3 in _track.baked:
		if absf(p.x) < 0.6 and p.z > -150.0 and p.z < 110.0:
			pts.append(Vector2(p.z, p.y))
	pts.sort_custom(func(a: Vector2, c: Vector2) -> bool: return a.x < c.x)
	_street = PackedVector2Array(pts)


## Cota soselei pe axa strazii la z (interpolare liniara pe punctele coapte).
func road_y(z: float) -> float:
	var n := _street.size()
	if n == 0:
		return 0.0
	if z <= _street[0].x:
		return _street[0].y
	if z >= _street[n - 1].x:
		return _street[n - 1].y
	var lo := 0
	var hi := n - 1
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if _street[mid].x <= z:
			lo = mid
		else:
			hi = mid
	var a := _street[lo]
	var c := _street[hi]
	var t := (z - a.x) / maxf(c.x - a.x, 1e-4)
	return lerpf(a.y, c.y, t)


## Linia de start in sah e un overlay alb-negru pus neconditionat pe punctul 0: nu are ce
## cauta intr-o captura de LOC (tiparul `carrara_mostra.gd`).
func _hide_start_line() -> void:
	if _track.baked.is_empty():
		return
	var p0: Vector3 = _track.baked[0]
	for child in _track.get_children():
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box := mi.mesh.get_aabb()
		if box.size.y < 0.3 and box.size.x < 20.0 and box.size.z < 20.0 \
				and (mi.global_transform * box.get_center()).distance_to(p0) < 8.0:
			mi.visible = false


## Sagetile de viraj (chevron) pe care Track le pune singur in curbe: mobilier de circuit, nu
## de oras — in capturile de loc ar fi un semnal strain.
func _hide_chevrons() -> void:
	for n in _track.find_children("Chevron*", "Node3D", true, false):
		(n as Node3D).visible = false


func _in_cross(z: float) -> bool:
	for c: Array in CROSS:
		if absf(z - float(c[0])) < float(c[1]):
			return true
	return false


func _build_street_furniture() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_st_atlas = st
	# Trotuarele: fasie de beton de la bordura la fatada, cu fata bordurii.
	for s: int in [1, -1]:
		var z := 104.0
		while z > -146.0:
			var z1 := z - 1.0
			if not (_in_cross(z) or _in_cross(z1)):
				var ya := road_y(z)
				var yb := road_y(z1)
				var xi := float(s) * ROAD_HALF
				var xo := float(s) * (FACADE_X + 0.5)
				_aquad(Vector3(xi, ya + CURB_H, z), Vector3(xo, ya + CURB_H, z),
					Vector3(xo, yb + CURB_H, z1), Vector3(xi, yb + CURB_H, z1),
					Vector3.UP, Palette.CONCRETE)
				_aquad(Vector3(xi, ya - 0.3, z), Vector3(xi, ya + CURB_H, z),
					Vector3(xi, yb + CURB_H, z1), Vector3(xi, yb - 0.3, z1),
					Vector3(-float(s), 0, 0), Palette.CONCRETE)
			z = z1
	# Strazile transversale (plate) ale intersectiilor, spre ambele laturi.
	for c: Array in CROSS:
		var zc: float = c[0]
		var hw: float = c[1]
		# Cota urmeaza soseaua pe z (la muchie spline-ul urca ~0,3 m inainte sa cada, iar umarul
		# pistei iesea prin asfaltul plat ca pete de pamant), +6 cm peste umar.
		for s: int in [1, -1]:
			var x0 := float(s) * ROAD_HALF
			var x1 := float(s) * 70.0
			var steps := 14
			for j in steps:
				var z0 := lerpf(zc + hw, zc - hw, float(j) / steps)
				var z1 := lerpf(zc + hw, zc - hw, float(j + 1) / steps)
				var y0 := road_y(z0) + 0.06
				var y1 := road_y(z1) + 0.06
				_aquad(Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z1),
					Vector3(x0, y1, z1), Vector3.UP, Palette.ASPHALT)
			# trotuarele strazii transversale
			for e: float in [1.0, -1.0]:
				var za := zc + e * hw
				var zb := zc + e * (hw + 3.5)
				var ya := road_y(za) + 0.06 + CURB_H
				var yb := road_y(zb) + 0.06 + CURB_H
				_aquad(Vector3(x0 + float(s) * 3.5, ya, za), Vector3(x1, ya, za),
					Vector3(x1, yb, zb), Vector3(x0 + float(s) * 3.5, yb, zb),
					Vector3.UP, Palette.CONCRETE)
	# COLTURILE intersectiilor: placa de beton intre trotuarul strazii, al strazii transversale
	# si capetele randurilor de case (altfel acolo se vedea pamantul terenului).
	for c: Array in CROSS:
		var zc: float = c[0]
		for s: int in [1, -1]:
			for e: float in [1.0, -1.0]:
				var za := zc + e * 10.5
				var zb := zc + e * 18.0
				var steps := 8
				for j in steps:
					var z0 := lerpf(za, zb, float(j) / steps)
					var z1 := lerpf(za, zb, float(j + 1) / steps)
					var x0 := float(s) * ROAD_HALF
					var x1 := float(s) * 24.0
					_aquad(Vector3(x0, road_y(z0) + CURB_H, z0), Vector3(x1, road_y(z0) + CURB_H, z0),
						Vector3(x1, road_y(z1) + CURB_H, z1), Vector3(x0, road_y(z1) + CURB_H, z1),
						Vector3.UP, Palette.CONCRETE)
	# ZEBRELE (decal FOAM_WHITE): bare de 0,5 m in lungul strazii, pe platul dinaintea muchiei.
	for zb: Array in ZEBRAS:
		var za: float = zb[1]
		var zz: float = zb[0]
		for k in 12:
			var xc := -6.05 + float(k) * 1.1
			var steps := 6
			for j in steps:
				var z0 := lerpf(za, zz, float(j) / steps)
				var z1 := lerpf(za, zz, float(j + 1) / steps)
				_aquad(Vector3(xc - 0.25, road_y(z0) + 0.035, z0),
					Vector3(xc + 0.25, road_y(z0) + 0.035, z0),
					Vector3(xc + 0.25, road_y(z1) + 0.035, z1),
					Vector3(xc - 0.25, road_y(z1) + 0.035, z1), Vector3.UP, Palette.FOAM_WHITE)
	var mi := MeshInstance3D.new()
	mi.name = "Strada"
	mi.mesh = st.commit()
	# Atlasul FARA stratul de detaliu: pe o suprafata orizontala, stratele triplanare ale
	# lumii (gandite pentru faleze) desenau dune pe trotuar — prima captura citea "nisip".
	mi.material_override = Palette.plain_material()
	add_child(mi)


# ---------------------------------------------------------------------- casele

func _build_house(s: int, za: float, pastel: int, roof: String, flat_y: float = NAN) -> void:
	_house_n += 1
	_cur_pastel = pastel
	_st_lit = SurfaceTool.new()
	_st_lit.begin(Mesh.PRIMITIVE_TRIANGLES)
	_st_shade = SurfaceTool.new()
	_st_shade.begin(Mesh.PRIMITIVE_TRIANGLES)
	_st_graze = SurfaceTool.new()
	_st_graze.begin(Mesh.PRIMITIVE_TRIANGLES)
	_st_atlas = SurfaceTool.new()
	_st_atlas.begin(Mesh.PRIMITIVE_TRIANGLES)

	var fs := float(s)
	var xf := fs * FACADE_X
	var xb := fs * (FACADE_X + HOUSE_D)
	var out := Vector3(-fs, 0, 0) # normala fatadei, spre strada
	var zb := za - HOUSE_W
	# SOCLUL IN PANA: podeaua casei la cota trotuarului din capatul de SUS.
	var yf := (road_y(za) if is_nan(flat_y) else flat_y) + CURB_H
	var ybot := (road_y(zb) if is_nan(flat_y) else flat_y) - 3.0
	var h := LEVEL_H * float(LEVELS)
	_ao_base = yf
	_ao_span = 4.0
	_box(Vector3(minf(xf, xb), ybot, zb), Vector3(maxf(xf, xb), yf, za), Palette.CONCRETE, false)
	# Corpul casei: scandura (fara capac — acoperisul il face mai jos).
	_box(Vector3(minf(xf, xb), yf, zb), Vector3(maxf(xf, xb), yf + h, za), -1, true)
	# Garajul sub bovindou (latura de JOS a fatadei), usa de intrare pe latura de SUS.
	var zc_bay := za - 4.3
	_panel(Vector3(xf, 0, zc_bay), out, yf + 0.02, 2.6, 2.4, Palette.WOOD_WEATHERED, 0.16)
	_panel(Vector3(xf, 0, za - 1.15), out, yf + 0.3, 1.0, 2.3, Palette.LOG_DARK, 0.14)
	# treapta de la intrare
	_obox(Vector3(xf, yf, za - 1.15), Vector3(0, 0, 1), out, 0.75, 0.35, 0.3, Palette.CONCRETE)
	# Brau alb intre garaj si etaje, pervazuri de colt (delimiteaza casele in rand).
	_obox(Vector3(xf, yf + LEVEL_H, (za + zb) * 0.5), Vector3(0, 0, 1), out,
		HOUSE_W * 0.5, 0.06, 0.12, Palette.FOAM_WHITE)
	for zc: float in [za - 0.1, zb + 0.1]:
		_obox(Vector3(xf, yf + h * 0.5, zc), Vector3(0, 0, 1), out, 0.1, 0.05, h * 0.5,
			Palette.FOAM_WHITE)
	# Ferestrele fatadei plate, pe latura de sus (doua etaje).
	for lv in range(1, LEVELS):
		var y0 := yf + float(lv) * LEVEL_H + 0.65
		_window(Vector3(xf, 0, za - 1.15), Vector3(0, 0, 1), out, y0, 0.95, 1.85)
	_build_bay(fs, xf, zc_bay, yf, out)
	# Cornisa si acoperisul.
	if roof == "flat":
		# Italianate: cornisa groasa care ascunde acoperisul plat (atic).
		_obox(Vector3(xf, yf + h + 0.4, (za + zb) * 0.5), Vector3(0, 0, 1), out,
			HOUSE_W * 0.5 + 0.15, 0.3, 0.45, Palette.FOAM_WHITE)
		_aquad(Vector3(xf, yf + h + 0.3, za), Vector3(xb, yf + h + 0.3, za),
			Vector3(xb, yf + h + 0.3, zb), Vector3(xf, yf + h + 0.3, zb), Vector3.UP,
			Palette.VOLCANIC_BLACK)
		# aticul pe celelalte trei laturi (sa nu se vada golul de sub acoperis)
		_box(Vector3(minf(xf, xb), yf + h, zb), Vector3(maxf(xf, xb), yf + h + 0.3, za), -1, true)
	else:
		_obox(Vector3(xf, yf + h - 0.1, (za + zb) * 0.5), Vector3(0, 0, 1), out,
			HOUSE_W * 0.5 + 0.1, 0.25, 0.22, Palette.FOAM_WHITE)
		_build_gable(fs, xf, xb, za, zb, yf + h, out)
	_commit_house(s, za)


## BOVINDOUL: trei fete (doua diagonale la 45 de grade + fata), pe etajele 1-2, peste garaj.
## Umbra lui pe fatada e ce tine pastelul sa nu fie plat (brief §6, riscul vizual 3).
func _build_bay(fs: float, xf: float, zc: float, yf: float, out: Vector3) -> void:
	var depth := 0.95
	var half_front := 1.3
	var half_base := half_front + depth
	var y0 := yf + LEVEL_H + 0.1
	var y1 := yf + LEVEL_H * float(LEVELS) - 0.25
	var xo := xf - fs * depth
	var a := Vector3(xf, 0, zc + half_base)
	var b := Vector3(xo, 0, zc + half_front)
	var c := Vector3(xo, 0, zc - half_front)
	var d := Vector3(xf, 0, zc - half_base)
	var faces := [[a, b], [b, c], [c, d]]
	for f: Array in faces:
		var p: Vector3 = f[0]
		var q: Vector3 = f[1]
		var u := (q - p).normalized()
		var n := u.cross(Vector3.UP).normalized()
		if n.dot(out) < 0.0:
			n = -n
		_cquad(Vector3(p.x, y0, p.z), Vector3(q.x, y0, q.z), Vector3(q.x, y1, q.z),
			Vector3(p.x, y1, p.z), n)
		var mid := (p + q) * 0.5
		var w := (q - p).length()
		for lv in range(1, LEVELS):
			var wy := yf + float(lv) * LEVEL_H + 0.6
			_window(mid, u, n, wy, w * 0.62, 1.9)
		# stalpisori albi pe muchiile bovindoului
		_obox(Vector3(p.x, (y0 + y1) * 0.5, p.z), u, n, 0.08, 0.05, (y1 - y0) * 0.5,
			Palette.FOAM_WHITE)
	# capacul si talpa bovindoului (albe), cu streasina mica
	var cap: Array[Vector3] = [a, b, c, d]
	_fan(cap, y1, Vector3.UP, Palette.FOAM_WHITE, 0.0)
	_fan(cap, y1 + 0.3, Vector3.UP, Palette.FOAM_WHITE, 0.0)
	_fan(cap, y0, Vector3.DOWN, Palette.FOAM_WHITE, 0.0)
	# cornisa bovindoului: fasie alba verticala de 0,3 m pe cele trei fete
	for f: Array in faces:
		var p: Vector3 = f[0]
		var q: Vector3 = f[1]
		var n := (q - p).normalized().cross(Vector3.UP).normalized()
		if n.dot(out) < 0.0:
			n = -n
		var pp := p + n * 0.12
		var qq := q + n * 0.12
		_aquad(Vector3(pp.x, y1, pp.z), Vector3(qq.x, y1, qq.z), Vector3(qq.x, y1 + 0.3, qq.z),
			Vector3(pp.x, y1 + 0.3, pp.z), n, Palette.FOAM_WHITE)


## FRONTONUL spre strada (Queen Anne): triunghi de scandura cu bordura alba, doua ape de
## acoperis VOLCANIC_BLACK care coboara spre vecini, fronton inchis si in spate.
func _build_gable(fs: float, xf: float, xb: float, za: float, zb: float, ytop: float,
		out: Vector3) -> void:
	var rise := 3.0
	var zm := (za + zb) * 0.5
	var ov := 0.35
	var xfo := xf - fs * ov
	var xbo := xb + fs * 0.2
	# triunghiurile de fronton (fata si spate), pe scandura
	_ctri(Vector3(xf, ytop, za), Vector3(xf, ytop, zb), Vector3(xf, ytop + rise, zm), out)
	_ctri(Vector3(xb, ytop, za), Vector3(xb, ytop, zb), Vector3(xb, ytop + rise, zm), -out)
	# apele acoperisului (si dedesubtul lor, vazut de pe strada de jos)
	var e := 0.3 * rise / (HOUSE_W * 0.5)
	for side: float in [1.0, -1.0]:
		var ze := zm + side * (HOUSE_W * 0.5 + 0.3)
		var ye := ytop - e
		var n := Vector3(0, HOUSE_W * 0.5, side * rise).normalized()
		_aquad(Vector3(xfo, ytop + rise, zm), Vector3(xbo, ytop + rise, zm),
			Vector3(xbo, ye, ze), Vector3(xfo, ye, ze), n, Palette.VOLCANIC_BLACK)
		_aquad(Vector3(xfo, ytop + rise - 0.12, zm), Vector3(xbo, ytop + rise - 0.12, zm),
			Vector3(xbo, ye - 0.12, ze), Vector3(xfo, ye - 0.12, ze), -n, Palette.VOLCANIC_BLACK)
		# bordura alba (bargeboard) pe muchia inclinata din fata
		var p := Vector3(xfo + fs * 0.05, ytop + rise, zm)
		var q := Vector3(xfo + fs * 0.05, ye, ze)
		var u := (q - p).normalized()
		var mid := (p + q) * 0.5
		_obox(mid, u, out, (q - p).length() * 0.5, 0.06, 0.16, Palette.FOAM_WHITE,
			u.cross(out).normalized())
	# o fereastra mica in fronton
	_window(Vector3(xf, 0, zm), Vector3(0, 0, 1), out, ytop + 0.5, 0.8, 1.2)


func _commit_house(s: int, za: float) -> void:
	var clap := ArrayMesh.new()
	var orient: Array[String] = []
	for pair: Array in [[_st_lit, "lit"], [_st_graze, "graze"], [_st_shade, "shade"]]:
		var st: SurfaceTool = pair[0]
		var arrays := st.commit_to_arrays()
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if verts.is_empty():
			continue
		clap.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		clap.surface_set_material(clap.get_surface_count() - 1,
			Palette.triplanar_class_material(PASTELS[_cur_pastel]))
		orient.append(pair[1])
	var mi := MeshInstance3D.new()
	mi.name = "Clap_%d" % _house_n
	mi.mesh = clap
	mi.set_meta("sf_pastel", _cur_pastel)
	mi.set_meta("sf_orient", orient)
	mi.add_to_group("sf_clap")
	add_child(mi)
	var am := MeshInstance3D.new()
	am.name = "Atlas_%d" % _house_n
	am.mesh = _st_atlas.commit()
	am.material_override = Palette.world_material()
	add_child(am)
	# Corp: peretii + soclul (casele umbresc strada in sonda de soare si opresc camera).
	var body := StaticBody3D.new()
	body.name = "Corp_%d" % _house_n
	body.collision_layer = 1 | Track.CAMERA_BLOCKER_LAYER
	body.add_to_group("sf_house_body")
	for m: Mesh in [clap, am.mesh]:
		var cs := CollisionShape3D.new()
		cs.shape = m.create_trimesh_shape()
		body.add_child(cs)
	add_child(body)


# ------------------------------------------------------------- primitive de fata

func _col(v: Vector3) -> Color:
	# AO copt: baza peretelui putin mai inchisa (1,5-4 m), restul alb.
	var t := clampf((v.y - _ao_base) / _ao_span, 0.0, 1.0)
	var k := lerpf(0.84, 1.0, t)
	return Color(k, k, k)


func _emit(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, uv: Vector2) -> void:
	a = _xf * a
	b = _xf * b
	c = _xf * c
	n = _xf.basis * n
	# Godot: fata din FATA are ordinea ORARA privita dinspre normala.
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	for v: Vector3 in [a, b, c]:
		st.set_color(_col(v))
		st.set_normal(n)
		st.set_uv(uv)
		st.add_vertex(v)


func _aquad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, slot: int) -> void:
	var uv := Palette.uv(slot)
	_emit(_st_atlas, a, b, c, n, uv)
	_emit(_st_atlas, a, c, d, n, uv)


func _clap_st(n: Vector3) -> SurfaceTool:
	# Trei clase fata de soarele temei: SPRE soare (N.L >= GRAZE_NL: diagonalele bovindoului,
	# peretii cu fata spre sud), RAZANT (0 < N.L < GRAZE_NL: fatadele in lungul strazii, pe
	# care soarele aliniat cu strada abia le atinge) si CU SPATELE (N.L <= 0).
	var nl := n.dot(_to_sun)
	if nl >= GRAZE_NL:
		return _st_lit
	return _st_graze if nl > 0.0 else _st_shade


func _cquad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	var st := _clap_st(_xf.basis * n)
	_emit(st, a, b, c, n, Vector2.ZERO)
	_emit(st, a, c, d, n, Vector2.ZERO)


func _ctri(a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	_emit(_clap_st(_xf.basis * n), a, b, c, n, Vector2.ZERO)


## Cutie aliniata pe axe; slot < 0 => scandura (fetele laterale), fara capac sus/jos.
func _box(lo: Vector3, hi: Vector3, slot: int, clap: bool) -> void:
	var x0 := lo.x
	var x1 := hi.x
	var y0 := lo.y
	var y1 := hi.y
	var z0 := lo.z
	var z1 := hi.z
	var faces := [
		[Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3.LEFT],
		[Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3.RIGHT],
		[Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3.FORWARD],
		[Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK],
	]
	if not clap:
		faces.append([Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.UP])
	for f: Array in faces:
		if clap:
			_cquad(f[0], f[1], f[2], f[3], f[4])
		else:
			_aquad(f[0], f[1], f[2], f[3], f[4], slot)


## Cutie ORIENTATA lipita de o fata: `c` e centrul ei PE planul fetei, iar cutia iese din
## plan pe normala n cu grosimea 2*hn (u = lungimea, `vaxis` = inaltimea, implicit sus).
func _obox(c: Vector3, u: Vector3, n: Vector3, hu: float, hn: float, hh: float, slot: int,
		vaxis: Vector3 = Vector3.UP) -> void:
	_cbox(c + n * hn, u, n, hu, hn, hh, slot, vaxis)


## Cutie ORIENTATA centrata in `base` (semi-dimensiuni pe u, n, vaxis).
func _cbox(base: Vector3, u: Vector3, n: Vector3, hu: float, hn: float, hh: float, slot: int,
		vaxis: Vector3 = Vector3.UP) -> void:
	var v := vaxis
	var cu := u * hu
	var cn := n * hn
	var cv := v * hh
	var corners: Array[Vector3] = []
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				corners.append(base + cu * sx + cv * sy + cn * sz)
	# indice = (sx>0)*4 + (sy>0)*2 + (sz>0)
	var quads := [
		[[4, 5, 7, 6], u], [[0, 1, 3, 2], -u],
		[[2, 3, 7, 6], v], [[0, 1, 5, 4], -v],
		[[1, 3, 7, 5], n], [[0, 2, 6, 4], -n],
	]
	for q: Array in quads:
		var ids: Array = q[0]
		_aquad(corners[ids[0]], corners[ids[1]], corners[ids[2]], corners[ids[3]], q[1], slot)


## Panou plat pe fatada (usa de garaj, usa de intrare) cu ancadrament alb pe trei laturi.
func _panel(at: Vector3, out: Vector3, y0: float, w: float, h: float, slot: int,
		frame: float) -> void:
	var u := Vector3(0, 0, 1)
	var p := Vector3(at.x, 0, at.z) + out * 0.03
	_aquad(Vector3(p.x, y0, p.z - w * 0.5), Vector3(p.x, y0, p.z + w * 0.5),
		Vector3(p.x, y0 + h, p.z + w * 0.5), Vector3(p.x, y0 + h, p.z - w * 0.5), out, slot)
	var fx := Vector3(at.x, 0, at.z)
	_obox(Vector3(fx.x, y0 + h + frame * 0.5, fx.z), u, out, w * 0.5 + frame, 0.07, frame * 0.5,
		Palette.FOAM_WHITE)
	for e: float in [-1.0, 1.0]:
		var zc := fx.z + e * (w * 0.5 + frame * 0.5)
		_obox(Vector3(fx.x, y0 + h * 0.5, zc), u, out, frame * 0.5, 0.07, h * 0.5,
			Palette.FOAM_WHITE)


## Fereastra: geam inchis (ICE_CRACK) + ancadrament alb in relief + pervaz + fronton mic.
func _window(mid: Vector3, u: Vector3, n: Vector3, y0: float, w: float, h: float) -> void:
	var c := Vector3(mid.x, 0, mid.z)
	var g := c + n * 0.035
	var hu := u * (w * 0.5)
	_aquad(Vector3(g.x, y0, g.z) - hu, Vector3(g.x, y0, g.z) + hu,
		Vector3(g.x, y0 + h, g.z) + hu, Vector3(g.x, y0 + h, g.z) - hu, n, Palette.ICE_CRACK)
	var f := 0.12
	# montantii
	for e: float in [-1.0, 1.0]:
		var p := c + u * e * (w * 0.5 + f * 0.5)
		_obox(Vector3(p.x, y0 + h * 0.5, p.z), u, n, f * 0.5, 0.06, h * 0.5, Palette.FOAM_WHITE)
	# pervazul (iese mai mult) si fruntarul cu "fronton" mic
	_obox(Vector3(c.x, y0 - 0.07, c.z), u, n, w * 0.5 + f * 1.6, 0.1, 0.07, Palette.FOAM_WHITE)
	_obox(Vector3(c.x, y0 + h + 0.1, c.z), u, n, w * 0.5 + f * 1.4, 0.09, 0.1, Palette.FOAM_WHITE)
	# o bara orizontala (fereastra ghilotina in doua)
	_obox(Vector3(c.x, y0 + h * 0.5, c.z), u, n, w * 0.5, 0.05, 0.03, Palette.FOAM_WHITE)


## Poligon convex orizontal (evantai) la cota y.
func _fan(pts: Array[Vector3], y: float, n: Vector3, slot: int, _grow: float) -> void:
	var uv := Palette.uv(slot)
	var p0 := Vector3(pts[0].x, y, pts[0].z)
	for i in range(1, pts.size() - 1):
		_emit(_st_atlas, p0, Vector3(pts[i].x, y, pts[i].z),
			Vector3(pts[i + 1].x, y, pts[i + 1].z), n, uv)


# ----------------------------------------------------------- masina parcata

## Masina parcata PERPENDICULAR pe blocul abrupt (latura de est, z 12, panta 28%): botul spre
## bordura, inclinata lateral cu panta strazii. Prin WorldProp, ca un prop pus de mana.
func _build_parked_car() -> void:
	var wp := WorldProp.new()
	wp.name = "MasinaParcata"
	var car := (load("res://assets/models/chongqing/vehicles/mini_car_b.glb") as PackedScene) \
		.instantiate() as Node3D
	var z := 12.0
	var slope := (road_y(z + 1.0) - road_y(z - 1.0)) * 0.5
	var up := Vector3(0, 1, -slope).normalized()
	# modelul are botul pe +Z local: il intoarcem spre +X (bordura de est)
	var fwd := Vector3(1, 0, 0)
	var side := up.cross(fwd).normalized()
	var basis := Basis(side, up, fwd)
	car.transform = Transform3D(basis, Vector3(4.6, road_y(z) + 0.02, z))
	wp.add_child(car)
	# si cateva parcate PARALEL pe strazile transversale (plate), la bordura
	var packed := load("res://assets/models/chongqing/vehicles/mini_car_b.glb") as PackedScene
	for spec: Array in [[36.0, -1.0, -30.0], [36.0, 1.0, 44.0], [-36.0, -1.0, 52.0],
			[-36.0, 1.0, -40.0]]:
		var zc: float = spec[0]
		var sgn: float = spec[1]
		var x: float = spec[2]
		var c2 := packed.instantiate() as Node3D
		var f2 := Vector3(1, 0, 0) if sgn > 0.0 else Vector3(-1, 0, 0)
		c2.transform = Transform3D(Basis(Vector3.UP.cross(f2), Vector3.UP, f2),
			Vector3(x, road_y(zc) + 0.02, zc + sgn * 5.6))
		wp.add_child(c2)
	add_child(wp)


# ------------------------------------------------------------------- fundal

func _new_atlas_st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_st_atlas = st
	_ao_base = -1000.0
	return st


func _finish_atlas(name_: String, shadows: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name_
	mi.mesh = _st_atlas.commit()
	mi.material_override = Palette.world_material()
	if not shadows:
		# Siluetele de fundal nu arunca umbra (memoria `caster-departat-fura-umbra`).
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _sea_y() -> float:
	return _track._sampler.mean_road_y() + _track.sea_level_offset if _track._sampler != null else 1.2


## PODUL ROSU (KERB_RED 7, brief §4): suspendat, doua turnuri de 45 m peste apa, tablierul la
## +18, cablurile principale in parabola. In stanga coborarii, traversand golful in diagonala.
func _build_bridge() -> void:
	_new_atlas_st()
	var sea := _sea_y()
	# Pozitia e MASURATA pe capturi, nu aleasa pe harta: in diagonala, la (-150, -230), podul
	# cadea in spatele randului de case din stanga pe toate cele cinci vederi (de pe strada se
	# vede doar culoarul dintre randuri, +-4..8 grade). Asa traverseaza golful aproape frontal,
	# putin la stanga axului, cu turnul de est in culoar.
	var center := Vector3(-45.0, 0.0, -250.0)
	var d := Vector3(0.94, 0.0, -0.342).normalized()
	var w := d.cross(Vector3.UP).normalized() # de-a latul tablierului
	var half_len := 125.0
	var deck_y := sea + 18.0
	var tower_h := 45.0
	var tower_off := 48.0
	var deck_hw := 9.0
	# tablierul: grinda cu zabrele = cutie rosie de 2,4 m
	_cbox(center + Vector3(0, deck_y - 1.2, 0), d, w, half_len, deck_hw, 1.2, Palette.KERB_RED)
	_cbox(center + Vector3(0, deck_y + 0.02, 0), d, w, half_len, deck_hw - 0.6, 0.02, Palette.ASPHALT)
	for e: float in [-1.0, 1.0]:
		var tc := center + d * (e * tower_off)
		# doua picioare, trei portaluri
		for side: float in [-1.0, 1.0]:
			var leg := tc + w * (side * (deck_hw + 0.6))
			_cbox(Vector3(leg.x, sea + tower_h * 0.5, leg.z), d, w, 1.6, 1.2, tower_h * 0.5,
				Palette.KERB_RED)
		for hy: float in [deck_y + 8.0, deck_y + 17.0, sea + tower_h - 2.0]:
			_cbox(Vector3(tc.x, hy, tc.z), w, d, deck_hw + 1.6, 1.0, 1.0, Palette.KERB_RED)
		# soclul turnului in apa
		_cbox(Vector3(tc.x, sea - 1.0, tc.z), d, w, 4.0, deck_hw + 3.0, 2.0, Palette.CONCRETE)
	# cablurile principale: parabola intre turnuri, cadere spre capete pe deschiderile laterale
	var top := sea + tower_h - 0.5
	for side: float in [-1.0, 1.0]:
		var off := w * (side * (deck_hw + 0.6))
		var pts: Array[Vector3] = []
		var nseg := 28
		for i in nseg + 1:
			var t := -half_len + 2.0 * half_len * float(i) / float(nseg)
			var y: float
			if absf(t) <= tower_off:
				var k := t / tower_off
				y = deck_y + 2.0 + (top - deck_y - 2.0) * k * k
			else:
				var k2 := (absf(t) - tower_off) / (half_len - tower_off)
				y = top + (deck_y + 1.0 - top) * k2
			pts.append(center + d * t + off + Vector3(0, y, 0))
		for i in nseg:
			var p := pts[i]
			var q := pts[i + 1]
			var u := (q - p).normalized()
			var nn := u.cross(Vector3.UP).normalized()
			_cbox((p + q) * 0.5, u, nn, (q - p).length() * 0.5 + 0.2, 0.4, 0.4, Palette.KERB_RED,
				nn.cross(u).normalized())
	_finish_atlas("Pod", false)


## Insula cu far (Alcatraz strans aproape, brief §2.0): stanca joasa + far alb + cladire.
func _build_island() -> void:
	_new_atlas_st()
	var sea := _sea_y()
	var c := Vector3(95.0, 0.0, -215.0)
	var seg := 10
	var rings: Array = [[24.0, sea - 1.0], [20.0, sea + 4.0], [13.0, sea + 8.0], [0.0, sea + 9.0]]
	for r in rings.size() - 1:
		var r0: float = rings[r][0]
		var y0: float = rings[r][1]
		var r1: float = rings[r + 1][0]
		var y1: float = rings[r + 1][1]
		for i in seg:
			var a0 := TAU * float(i) / seg
			var a1 := TAU * float(i + 1) / seg
			var sx := 1.6 # alungita est-vest
			var p00 := c + Vector3(cos(a0) * r0 * sx, y0, sin(a0) * r0)
			var p01 := c + Vector3(cos(a1) * r0 * sx, y0, sin(a1) * r0)
			var p10 := c + Vector3(cos(a0) * r1 * sx, y1, sin(a0) * r1)
			var p11 := c + Vector3(cos(a1) * r1 * sx, y1, sin(a1) * r1)
			var n := (p01 - p00).cross(p10 - p00).normalized()
			if n.y < 0.0:
				n = -n
			var slot := Palette.MARBLE_GREY if r < 2 else Palette.DRY_VEGETATION
			_aquad(p00, p01, p11, p10, n, slot)
	# cladirea inchisorii si farul
	_cbox(c + Vector3(-6.0, sea + 10.5, 0.0), Vector3(1, 0, 0), Vector3(0, 0, 1), 9.0, 4.0, 2.5,
		Palette.CONCRETE)
	_cbox(c + Vector3(8.0, sea + 14.0, 1.0), Vector3(1, 0, 0), Vector3(0, 0, 1), 1.0, 1.0, 6.0,
		Palette.FOAM_WHITE)
	_cbox(c + Vector3(8.0, sea + 20.6, 1.0), Vector3(1, 0, 0), Vector3(0, 0, 1), 1.3, 1.3, 0.6,
		Palette.VOLCANIC_BLACK)
	_finish_atlas("Insula", false)


## DEALURILE din Marin, dincolo de golf: creasta joasa, aurie (`macchia_dry`, brief §4), care
## pleaca de la apa la tarmul de nord (z -283) si urca la 25-55 m.
func _build_hills() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sea := _sea_y()
	var nx := 36
	var nz := 6
	var x0 := -360.0
	var x1 := 320.0
	var z0 := -282.0
	var z1 := -340.0
	var grid: Array = []
	for j in nz + 1:
		var row: Array[Vector3] = []
		var tz := float(j) / nz
		for i in nx + 1:
			var tx := float(i) / nx
			var x := lerpf(x0, x1, tx)
			var z := lerpf(z0, z1, tz)
			var peak := 30.0 + 14.0 * sin(x * 0.021 + 0.7) + 9.0 * sin(x * 0.047 + 2.1)
			var prof := sin(clampf(tz * 1.25, 0.0, 1.0) * PI * 0.5)
			var y := sea - 0.5 + (peak) * prof
			row.append(Vector3(x, y, z))
		grid.append(row)
	for j in nz:
		for i in nx:
			var a: Vector3 = grid[j][i]
			var b: Vector3 = grid[j][i + 1]
			var c: Vector3 = grid[j + 1][i + 1]
			var d: Vector3 = grid[j + 1][i]
			for tri: Array in [[a, b, c], [a, c, d]]:
				var t0: Vector3 = tri[0]
				var t1: Vector3 = tri[1]
				var t2: Vector3 = tri[2]
				var n := (t1 - t0).cross(t2 - t0).normalized()
				if n.y < 0.0:
					n = -n
				# iarba uscata aurie (DRY_VEGETATION 13), cu pete de chaparral verde-inchis
				# (TROPICAL_GREEN 21 umbrit) pe vai — atlasul, nu `macchia_dry`, care iesea portocaliu.
				var mid := (t0 + t1 + t2) / 3.0
				var g := sin(mid.x * 0.09 + mid.z * 0.05) + sin(mid.x * 0.031 - 1.3)
				var slot := Palette.TROPICAL_GREEN if g > 0.9 else Palette.DRY_VEGETATION
				var k := 0.5 if slot == Palette.TROPICAL_GREEN else 0.64 + 0.06 * sin(mid.x * 0.05)
				_emit_plain(st, t0, t1, t2, n, Palette.uv(slot), Color(k, k, k))
	var mi := MeshInstance3D.new()
	mi.name = "Dealuri"
	mi.mesh = st.commit()
	mi.material_override = Palette.world_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _emit_plain(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, uv: Vector2,
		col: Color) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	for v: Vector3 in [a, b, c]:
		st.set_color(col)
		st.set_normal(n)
		st.set_uv(uv)
		st.add_vertex(v)
