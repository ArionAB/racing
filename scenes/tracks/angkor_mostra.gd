extends Node3D
## TESTUL DE LOC ANGKOR (docs/track_briefs/angkor.md §7 pasul 0) — TEMPORAR, se scoate inainte
## de merge odata cu `Track24Mostra*.tscn` si `tools/gen_angkor_mostra.py` (tiparul mostrei
## Carrara, ramura `carrara/mostra`).
##
## Intrebarea mostrei nu e "arata bine?", ci "SE CONFUNDA cu alta pista?" — riscul numit in
## brief e "Machu Picchu 2" (piatra gri + verde). Geometria e deci doar SILUETA locului, in cod,
## din cutii si tuburi: templul in quincunx pe soclu in trepte (turnurile-boboc), turnurile cu
## fete (Bayon), zidul de incinta din laterita cu poarta-copac (Ta Prohm), santurile cu lotusi si
## balustrada naga. Copacii sunt GLB-uri reuse in `DecorManual` (WorldProp le da sloturile).
##
## A / B difera prin TEMA (lumina, cer, drum) si prin `accents`: lichenul portocaliu, darele de
## muson, laterita rosie si jadul santului. B (martorul) are aceeasi geometrie, fara antidoturi.
##
## ORIENTARE: nord = -Z. Startul merge spre EST (+X), spre templul din (200, 0). Soarele (tema
## `angkor`) sta in VSV, deci fata de vest a templului e luminata si umbra cade spre ENE.

@export var stone_class: String = "angkor_sandstone"
## Antidoturile din brief §0.1 / §4 (A = true, B = false).
@export var accents: bool = true

const TEMPLE_C := Vector2(200.0, 0.0)
const FACE_TOWERS: Array[Vector3] = [
	# (x, z, scara)
	# Pe latura de EST: camera merge spre nord si vede fetele de S si V, luminate de soarele din VSV.
	Vector3(104.0, -84.0, 1.0),
	Vector3(-42.0, -30.0, 0.9),
	Vector3(-47.0, -58.0, 0.85),
	Vector3(-13.0, -50.0, 0.8),
	Vector3(-60.0, -82.0, 0.75),
]

var _stone: Material
var _atlas: Material
var _sampler: TrackSideSampler
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Tema si terenul se construiesc in `Track._ready()`, dupa copii.
	call_deferred("_build")


func _build() -> void:
	var track := get_parent() as Track
	if track != null:
		_sampler = track._sampler
		_hide_start_line(track)
	_rng.seed = 24
	_stone = Palette.triplanar_class_material(stone_class)
	_atlas = Palette.world_material()
	_build_temple()
	for ft in FACE_TOWERS:
		_build_face_tower(Vector2(ft.x, ft.y), ft.z)
	_build_enclosure()
	_build_moats()
	_build_naga()
	_snap_decor(track)


func _gy(x: float, z: float) -> float:
	return _sampler.ground_y(x, z) if _sampler != null else 0.0


# ----------------------------------------------------------------- culori

func _c_stone() -> Color:
	return Color.WHITE


## Cornisele si fetele de sus: lichen portocaliu / verde-galbui in A, nimic in B.
func _c_top() -> Color:
	if not accents:
		return Color(0.92, 0.92, 0.92)
	return Color(1.0, 0.78, 0.55) if _rng.randf() < 0.5 else Color(0.86, 0.88, 0.62)


## Corpul unui etaj: darele de muson (A) il intuneca pe jumatatea de sus.
func _c_body(k: int) -> Color:
	if not accents:
		return Color(0.95, 0.95, 0.95) if k % 2 == 0 else Color(0.88, 0.88, 0.88)
	return Color(0.62, 0.60, 0.58) if k % 2 == 1 else Color(0.90, 0.88, 0.84)


func _c_laterite() -> Color:
	return Color(0.78, 0.50, 0.40) if accents else Color(0.70, 0.68, 0.62)


# ----------------------------------------------------------------- templul

func _build_temple() -> void:
	var mb := _Mb.new()
	var c := TEMPLE_C
	var y0 := _gy(c.x, c.y) - 0.5
	# Soclul in trei trepte (48 → 40 → 32 m, cate 2,5 m).
	var y := y0
	for i in 3:
		var w := 48.0 - 8.0 * i
		var h := 2.5
		var top := _c_top()
		mb.box(Vector3(c.x, y + h * 0.5, c.y), Vector3(w, h, w),
				[_c_body(i), _c_body(i), top, _c_stone(), _c_body(i), _c_body(i)])
		# Cornisa iesita la fiecare treapta: linia orizontala care da etajarea.
		mb.box(Vector3(c.x, y + h - 0.15, c.y), Vector3(w + 0.8, 0.3, w + 0.8),
				[_c_stone(), _c_stone(), top, _c_stone(), _c_stone(), _c_stone()])
		y += h
	# Galeria de pe treapta de sus: un inel de colonade joase (stalpi + acoperis).
	_gallery_ring(mb, Vector3(c.x, y, c.y), 30.0, 3.2)
	# Quincunx: centrul 20 m, colturile 13 m, peste soclu (vârful central ~27,5 m peste sol).
	_prang(mb, Vector3(c.x, y, c.y), 20.0, 7.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_prang(mb, Vector3(c.x + sx * 11.0, y, c.y + sz * 11.0), 13.0, 5.0)
	# Gopura de vest pe axa caii de acces, pe soclu.
	_gopura(mb, Vector3(c.x - 27.0, y0, c.y), 9.0, 7.0)
	_commit(mb, "Templu", _stone)


## Turnul-boboc de lotus: un ax si cinci etaje care se strang pe o ogiva, fiecare cu plan in
## cruce (doua cutii incrucisate = colturile in trepte) si cornisa; varful e un boboc.
func _prang(mb: _Mb, base: Vector3, height: float, w0: float) -> void:
	var shaft_h := height * 0.38
	var y := base.y
	mb.box(Vector3(base.x, y + shaft_h * 0.5, base.z), Vector3(w0, shaft_h, w0 * 0.72),
			_faces(_c_body(0), _c_top()))
	mb.box(Vector3(base.x, y + shaft_h * 0.5, base.z), Vector3(w0 * 0.72, shaft_h, w0),
			_faces(_c_body(0), _c_top()))
	# Usa falsa pe fiecare fata (o nisa inchisa).
	var door := Color(0.25, 0.24, 0.23)
	for s in [-1.0, 1.0]:
		mb.box(Vector3(base.x + s * w0 * 0.5, y + shaft_h * 0.4, base.z),
				Vector3(0.12, shaft_h * 0.55, w0 * 0.2), _faces(door, door))
		mb.box(Vector3(base.x, y + shaft_h * 0.4, base.z + s * w0 * 0.5),
				Vector3(w0 * 0.2, shaft_h * 0.55, 0.12), _faces(door, door))
	y += shaft_h
	var tiers := 5
	var tier_h := height * 0.50 / tiers
	for k in tiers:
		var t := float(k) / float(tiers)
		# Ogiva: se strange lent jos si repede sus (silueta de boboc, nu de piramida).
		var w := w0 * (0.92 - 0.62 * pow(t, 1.5))
		mb.box(Vector3(base.x, y + 0.12, base.z), Vector3(w * 1.12, 0.24, w * 1.12),
				_faces(_c_stone(), _c_top()))
		mb.box(Vector3(base.x, y + tier_h * 0.5, base.z), Vector3(w, tier_h, w * 0.7),
				_faces(_c_body(k + 1), _c_top()))
		mb.box(Vector3(base.x, y + tier_h * 0.5, base.z), Vector3(w * 0.7, tier_h, w),
				_faces(_c_body(k + 1), _c_top()))
		y += tier_h
	# Bobocul: doua cutii rotite cu 45 de grade, ascutite.
	var bud_h := height * 0.12
	var bw := w0 * 0.26
	mb.box(Vector3(base.x, y + bud_h * 0.35, base.z), Vector3(bw, bud_h * 0.7, bw),
			_faces(_c_body(1), _c_top()), PI * 0.25)
	mb.box(Vector3(base.x, y + bud_h * 0.8, base.z), Vector3(bw * 0.45, bud_h * 0.6, bw * 0.45),
			_faces(_c_body(1), _c_top()), PI * 0.25)


func _gallery_ring(mb: _Mb, c: Vector3, side: float, h: float) -> void:
	var half := side * 0.5
	var step := 2.6
	var n := int(side / step)
	for i in n + 1:
		var u := -half + i * (side / n)
		for p in [Vector2(u, -half), Vector2(u, half), Vector2(-half, u), Vector2(half, u)]:
			mb.box(Vector3(c.x + p.x, c.y + h * 0.5, c.z + p.y), Vector3(0.7, h, 0.7),
					_faces(_c_stone(), _c_top()))
	for s in [-1.0, 1.0]:
		mb.box(Vector3(c.x, c.y + h + 0.4, c.z + s * half), Vector3(side + 1.4, 0.8, 2.2),
				_faces(_c_body(1), _c_top()))
		mb.box(Vector3(c.x + s * half, c.y + h + 0.4, c.z), Vector3(2.2, 0.8, side + 1.4),
				_faces(_c_body(1), _c_top()))


## Gopura: corp cu deschidere pe axa E-V (doi piloni + buiandrug) si un turn-boboc mic.
func _gopura(mb: _Mb, c: Vector3, w: float, h: float) -> void:
	var open := 3.6
	var pil := (w - open) * 0.5
	for s in [-1.0, 1.0]:
		mb.box(Vector3(c.x, c.y + h * 0.5, c.z + s * (open * 0.5 + pil * 0.5)),
				Vector3(w * 0.8, h, pil), _faces(_c_body(0), _c_top()))
	mb.box(Vector3(c.x, c.y + h - 0.8, c.z), Vector3(w * 0.8, 1.6, open),
			_faces(_c_body(1), _c_top()))
	_prang(mb, Vector3(c.x, c.y + h, c.z), 8.0, 4.5)


# ----------------------------------------------------------------- turnuri cu fete

## Turnul Bayonului: soclu, ax, patru FETE (sprancene, ochi inchisi, nas, buze, urechi,
## diadema) si un varf etajat. Fetele sunt din cutii — se masoara SILUETA si umbrirea, nu
## portretul.
func _build_face_tower(p: Vector2, s: float) -> void:
	var mb := _Mb.new()
	var y := _gy(p.x, p.y) - 0.3
	var base := Vector3(p.x, y, p.y)
	mb.box(base + Vector3(0, 1.0 * s, 0), Vector3(8.0, 2.0, 8.0) * s, _faces(_c_body(1), _c_top()))
	var sh := 7.5 * s
	var sw := 6.0 * s
	mb.box(base + Vector3(0, 2.0 * s + sh * 0.5, 0), Vector3(sw, sh, sw), _faces(_c_body(1), _c_top()))
	# Fata ocupa aproape tot axul: de la 2,6 la 9,2 m. Trasaturile ies 0,5-1,1 m din perete,
	# altfel la 30-50 m de camera nu fac umbra si fata nu exista (prima captura).
	var f0 := 2.0 * s
	var dark := Color(0.22, 0.21, 0.20)
	var lit := Color(1.0, 0.98, 0.95)
	for d: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var side := Vector3(-d.z, 0, d.x)
		var o: Vector3 = base + d * (sw * 0.5)
		# Diadema: banda lata cu trei fleuroane deasupra.
		mb.box(o + Vector3(0, f0 + 6.7 * s, 0) + d * 0.35 * s, _orient(d, 5.6 * s, 0.9 * s, 0.7 * s),
				_faces(_c_body(0), _c_top()))
		for e in [-1.0, 0.0, 1.0]:
			mb.box(o + Vector3(0, f0 + 7.5 * s, 0) + side * e * 1.8 * s + d * 0.35 * s,
					_orient(d, 0.9 * s, 0.9 * s, 0.5 * s), _faces(_c_body(0), _c_top()), 0.0)
		# Fruntea + sprancenele: o creasta lunga, iesita.
		mb.box(o + Vector3(0, f0 + 5.8 * s, 0) + d * 0.5 * s, _orient(d, 4.6 * s, 0.45 * s, 1.0 * s),
				_faces(lit, _c_top()))
		# Ochii inchisi: doua fante inchise sub sprancene (in umbra ei).
		for e in [-1.0, 1.0]:
			mb.box(o + Vector3(0, f0 + 5.2 * s, 0) + side * e * 1.15 * s + d * 0.12 * s,
					_orient(d, 1.4 * s, 0.3 * s, 0.25 * s), _faces(dark, dark))
		# Pometii / obrajii: doua volume rotunjite in trepte.
		for e in [-1.0, 1.0]:
			mb.box(o + Vector3(0, f0 + 4.1 * s, 0) + side * e * 1.4 * s + d * 0.35 * s,
					_orient(d, 1.5 * s, 1.6 * s, 0.7 * s), _faces(_c_body(0), _c_top()))
		# Nasul lat (Bayon): iesit 1,1 m, cu narile umbrite dedesubt.
		mb.box(o + Vector3(0, f0 + 4.3 * s, 0) + d * 0.6 * s, _orient(d, 1.1 * s, 2.0 * s, 1.2 * s),
				_faces(lit, _c_top()))
		mb.box(o + Vector3(0, f0 + 3.3 * s, 0) + d * 0.75 * s, _orient(d, 1.5 * s, 0.4 * s, 1.0 * s),
				_faces(lit, dark))
		# Zambetul: buza de sus lata, buza de jos iesita, colturile ridicate.
		mb.box(o + Vector3(0, f0 + 2.55 * s, 0) + d * 0.45 * s, _orient(d, 2.6 * s, 0.35 * s, 0.8 * s),
				_faces(lit, _c_top()))
		mb.box(o + Vector3(0, f0 + 2.15 * s, 0) + d * 0.5 * s, _orient(d, 2.0 * s, 0.4 * s, 0.85 * s),
				_faces(_c_body(0), dark))
		for e in [-1.0, 1.0]:
			mb.box(o + Vector3(0, f0 + 2.75 * s, 0) + side * e * 1.4 * s + d * 0.35 * s,
					_orient(d, 0.45 * s, 0.3 * s, 0.6 * s), _faces(lit, _c_top()))
		# Barbia
		mb.box(o + Vector3(0, f0 + 1.5 * s, 0) + d * 0.35 * s, _orient(d, 2.4 * s, 0.6 * s, 0.6 * s),
				_faces(_c_body(0), _c_top()))
		# Urechile lungi, cu lobul pana la barbie.
		for e in [-1.0, 1.0]:
			mb.box(o + Vector3(0, f0 + 3.8 * s, 0) + side * e * 2.75 * s + d * 0.3 * s,
					_orient(d, 0.55 * s, 3.2 * s, 0.6 * s), _faces(_c_body(0), _c_top()))
	# Varful etajat deasupra fetelor.
	_prang(mb, base + Vector3(0, 2.0 * s + sh, 0), 6.5 * s, 4.8 * s)
	_commit(mb, "TurnFete_%d" % int(p.x), _stone)


## Dimensiunile unei cutii date ca (latime pe fata, inaltime, adancime spre `d`).
func _orient(d: Vector3, w: float, h: float, depth: float) -> Vector3:
	if absf(d.x) > 0.5:
		return Vector3(depth, h, w)
	return Vector3(w, h, depth)


# ----------------------------------------------------------------- incinta Ta Prohm

func _build_enclosure() -> void:
	var mb := _Mb.new()
	var roots := _Mb.new()
	var z := -134.0
	var lat := _c_laterite()
	var x := 6.0
	while x < 94.0:
		var gx := 50.0
		if absf(x - gx) < 6.0:
			x += 2.0
			continue
		var y := _gy(x, z)
		# Blocuri de laterita in randuri, cu o coama de gresie.
		var h := 3.2 - (0.6 if _rng.randf() < 0.15 else 0.0)
		mb.box(Vector3(x + 1.0, y + h * 0.5 - 0.2, z), Vector3(2.0, h, 1.6),
				[lat, lat, lat, lat, lat.darkened(0.12), lat])
		mb.box(Vector3(x + 1.0, y + h - 0.05, z), Vector3(2.1, 0.3, 1.9),
				_faces(_c_body(1), _c_top()))
		x += 2.0
	# Poarta-copac: gopura mica strinsa de radacini (ficusul GLB sta deasupra, in DecorManual).
	var gy := _gy(50.0, z)
	_gopura(mb, Vector3(50.0, gy - 0.2, z), 8.0, 6.0)
	_commit(mb, "Incinta", _stone)
	# Radacinile: tuburi groase si serpuite, palide, care curg de pe acoperisul portii pe pereti
	# si peste zid pana in sol (ficusul sugrumator din Ta Prohm). Gri-argintiu cald, nu alb.
	var pale := Color(0.70, 0.66, 0.58) if accents else Color(0.50, 0.46, 0.40)
	for i in 10:
		var a := TAU * float(i) / 10.0 + _rng.randf_range(-0.2, 0.2)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var top := Vector3(50.0, gy + 13.0, z) + dir * 0.8
		var shoulder := Vector3(50.0, gy + 7.2, z) + dir * Vector3(4.6, 0, 3.4)
		var knee := Vector3(50.0, gy + 3.5, z) + dir * Vector3(5.4, 0, 4.2) 				+ Vector3(_rng.randf_range(-0.8, 0.8), 0, _rng.randf_range(-0.8, 0.8))
		var foot := Vector3(50.0, gy - 0.4, z) + dir * Vector3(_rng.randf_range(7.0, 11.0), 0,
				_rng.randf_range(5.0, 8.0))
		roots.tube(_wavy([top, shoulder, knee, foot], 3), _rng.randf_range(0.35, 0.6), pale)
	# Radacini peste zid, mai departe de poarta.
	for wx in [16.0, 24.0, 33.0, 68.0, 77.0, 87.0]:
		var wy := _gy(wx, z)
		var crest := Vector3(wx, wy + 3.4, z)
		roots.tube(_wavy([crest + Vector3(0.5, 4.0, -2.0), crest,
				crest + Vector3(0.6, -1.4, 1.2), Vector3(wx + 1.6, wy - 0.4, z + 3.6)], 2),
				0.5, pale)
		roots.tube(_wavy([crest, crest + Vector3(-0.7, -1.5, -1.2),
				Vector3(wx - 1.4, wy - 0.4, z - 3.6)], 2), 0.42, pale)
	_commit(roots, "Radacini", _atlas, Palette.uv(Palette.CORAL_SAND))


# ----------------------------------------------------------------- santurile si naga

func _build_moats() -> void:
	var water := Color(0.40, 0.64, 0.48) if accents else Color(0.55, 0.62, 0.70)
	_pool("Sant_N", 30.0, 112.0, -30.0, -6.5, water)
	_pool("Sant_S", 30.0, 112.0, 6.5, 30.0, water)
	_pool("Sant_E", 136.0, 168.0, -60.0, 40.0, water)


func _pool(pname: String, x0: float, x1: float, z0: float, z1: float, col: Color) -> void:
	var y := _gy((x0 + x1) * 0.5, (z0 + z1) * 0.5) + 0.06
	var mb := _Mb.new()
	mb.quad_up(Vector3(x0, y, z0), Vector3(x1, y, z1), col)
	# Vertex color nu tenteaza atlasul aici: culoarea apei e SLOTUL. SEA_DEEP (jad inchis) pe
	# AMBELE variante: CACTUS_GREEN pe B se citea gazon, nu apa — martorul ar fi pierdut pe un
	# defect, nu pe lipsa antidoturilor (laterita, lichen, radacini, lumina).
	_commit(mb, pname, _atlas, Palette.uv(Palette.SEA_DEEP))
	# Lotusii: frunze plate si cateva flori roz.
	var pads := _Mb.new()
	var flowers := _Mb.new()
	var n := int((x1 - x0) * (z1 - z0) / 60.0)
	for i in n:
		var px := _rng.randf_range(x0 + 1.0, x1 - 1.0)
		var pz := _rng.randf_range(z0 + 1.0, z1 - 1.0)
		var r := _rng.randf_range(0.5, 1.1)
		pads.box(Vector3(px, y + 0.03, pz), Vector3(r, 0.04, r), _faces(Color.WHITE, Color.WHITE),
				_rng.randf_range(0.0, PI))
		if _rng.randf() < 0.35:
			flowers.box(Vector3(px + 0.2, y + 0.25, pz), Vector3(0.3, 0.4, 0.3),
					_faces(Color.WHITE, Color.WHITE), PI * 0.25)
	_commit(pads, pname + "_Lotus", _atlas, Palette.uv(Palette.TROPICAL_GREEN))
	_commit(flowers, pname + "_Flori", _atlas, Palette.uv(Palette.FLAMINGO_PINK))


## Balustrada naga pe calea de acces: trupul sarpelui pe stalpi scunzi, cu goluri prabusite si
## capul cu sapte guri (evantai) la capete.
func _build_naga() -> void:
	var mb := _Mb.new()
	for s in [-1.0, 1.0]:
		var z: float = s * 5.6
		var x := 32.0
		while x < 110.0:
			if (x > 58.0 and x < 63.0) or (s > 0.0 and x > 84.0 and x < 88.0):
				x += 1.0
				continue
			var y := _gy(x, z)
			mb.box(Vector3(x + 0.5, y + 0.95, z), Vector3(1.05, 0.42, 0.5),
					_faces(_c_body(0), _c_top()))
			if int(x) % 3 == 0:
				mb.box(Vector3(x + 0.5, y + 0.4, z), Vector3(0.35, 0.8, 0.35),
						_faces(_c_body(1), _c_top()))
			x += 1.0
		# Capul cu sapte guri: un evantai de sapte "dinti" in jurul unui cap.
		var hx := 30.5
		var hy := _gy(hx, z)
		for k in 7:
			var a := lerpf(-1.1, 1.1, float(k) / 6.0)
			mb.box(Vector3(hx, hy + 1.6 + cos(a) * 1.1, z + sin(a) * 1.1),
					Vector3(0.5, 0.9, 0.45), _faces(_c_body(0), _c_top()), 0.0)
		mb.box(Vector3(hx + 0.3, hy + 1.0, z), Vector3(1.2, 1.4, 1.6), _faces(_c_body(1), _c_top()))
	_commit(mb, "Naga", _stone)


# ----------------------------------------------------------------- decor si utilitare

## Copacii din DecorManual sunt scrisi la y = 0: se aseaza pe teren aici, dupa ce exista.
func _snap_decor(track: Track) -> void:
	if track == null:
		return
	var dm := track.get_node_or_null("DecorManual") as Node3D
	if dm == null:
		return
	for child in dm.get_children():
		var n3 := child as Node3D
		if n3 == null:
			continue
		var gp := n3.global_position
		n3.global_position = Vector3(gp.x, _gy(gp.x, gp.z) - 0.15, gp.z)


func _hide_start_line(track: Track) -> void:
	if track.baked.is_empty():
		return
	var p0: Vector3 = track.baked[0]
	for child in track.get_children():
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box := mi.mesh.get_aabb()
		if box.size.y < 0.3 and box.size.x < 20.0 and box.size.z < 20.0 \
				and (mi.global_transform * box.get_center()).distance_to(p0) < 8.0:
			mi.visible = false


## Subdivide o polilinie si o serpuieste lateral: radacina nu e un stalp drept.
func _wavy(pts: Array, sub: int) -> Array:
	var out: Array = []
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		for k in sub:
			var t := float(k) / float(sub)
			var p := a.lerp(b, t)
			if i > 0 or k > 0:
				p += Vector3(_rng.randf_range(-0.45, 0.45), 0.0, _rng.randf_range(-0.45, 0.45))
			out.append(p)
	out.append(pts[pts.size() - 1])
	return out


func _faces(side: Color, top: Color) -> Array:
	return [side, side, top, side, side, side]


func _commit(mb: _Mb, mesh_name: String, mat: Material, uv: Vector2 = Vector2.ZERO) -> void:
	if mb.verts.is_empty():
		return
	var uvs := PackedVector2Array()
	uvs.resize(mb.verts.size())
	uvs.fill(uv)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = mb.verts
	arrays[Mesh.ARRAY_NORMAL] = mb.normals
	arrays[Mesh.ARRAY_COLOR] = mb.colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = mb.idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = m
	mi.material_override = mat
	add_child(mi)


## Acumulator de geometrie: cutii (cu culoare pe fata si rotatie pe Y), tuburi, quad-uri.
class _Mb:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var idx := PackedInt32Array()

	## `cols` = +X, -X, +Y, -Y, +Z, -Z.
	func box(center: Vector3, size: Vector3, cols: Array, yaw: float = 0.0) -> void:
		var basis := Basis(Vector3.UP, yaw)
		var h := size * 0.5
		var dirs: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN,
			Vector3.BACK, Vector3.FORWARD]
		for f in 6:
			var nrm := dirs[f]
			var up := Vector3.UP if absf(nrm.y) < 0.5 else Vector3.FORWARD
			var right := up.cross(nrm)
			var base := verts.size()
			for corner in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1)]:
				var local: Vector3 = nrm * h + right * corner.x * h + up * corner.y * h
				# `nrm * h` etc. sunt produse pe componente: proiectia corecta pe fiecare axa.
				verts.append(center + basis * local)
				normals.append(basis * nrm)
				colors.append(cols[f])
			idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

	func quad_up(a: Vector3, b: Vector3, col: Color) -> void:
		var base := verts.size()
		for p in [Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, a.y, b.z),
				Vector3(a.x, a.y, b.z)]:
			verts.append(p)
			normals.append(Vector3.UP)
			colors.append(col)
		idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

	## Tub hexagonal pe o polilinie, cu raza care scade spre capat (radacina se subtiaza).
	func tube(pts: Array, radius: float, col: Color) -> void:
		var sides := 6
		var n := pts.size()
		var base := verts.size()
		for i in n:
			var p: Vector3 = pts[i]
			var t: Vector3
			if i == 0:
				t = (pts[1] as Vector3) - p
			elif i == n - 1:
				t = p - (pts[i - 1] as Vector3)
			else:
				t = (pts[i + 1] as Vector3) - (pts[i - 1] as Vector3)
			t = t.normalized()
			var ref := Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT
			var u := t.cross(ref).normalized()
			var v := t.cross(u).normalized()
			var r := radius * lerpf(1.0, 0.55, float(i) / float(n - 1))
			for k in sides:
				var a := TAU * float(k) / float(sides)
				var nrm := (u * cos(a) + v * sin(a))
				verts.append(p + nrm * r)
				normals.append(nrm)
				colors.append(col)
		for i in n - 1:
			for k in sides:
				var k2 := (k + 1) % sides
				var a0 := base + i * sides + k
				var a1 := base + i * sides + k2
				var b0 := a0 + sides
				var b1 := a1 + sides
				idx.append_array([a0, b0, b1, a0, b1, a1])
