class_name RoadWear
extends SubViewport
## Masca de UZURA a drumului de zapada: o textura in "spatiul benzii" —
## U = pozitia laterala pe sosea, V = metri parcursi de-a lungul ei — in care
## rotile deseneaza pete la fiecare trecere. Shaderul soselei
## (road_snow.gdshader) o citeste si inchide/albastreste zapada acolo unde
## s-a circulat, deci dupa trei tururi cu cinci masini linia ideala e vizibil
## batatorita. Asta e ce SandTrail nu poate: placutele lui se recicleaza dupa
## ~176 m, aici urmele se ACUMULEAZA toata cursa.
##
## De ce merge ieftin: soseaua isi are deja UV-urile in exact acest spatiu
## (Track._build_road: U urmareste latimea locala in metri, V = distanta
## cumulata), deci shaderul nu calculeaza nimic — normalizeaza si citeste.
## Viewportul se redeseneaza DOAR in cadrele cu stampile noi (UPDATE_ONCE),
## si atunci deseneaza doar sprite-urile aratate in cadrul ala: tinta nu se
## curata niciodata (CLEAR_MODE_ONCE), asa ca fiecare pata ramane si alfa se
## aduna la trecerile urmatoare pana la saturatie.
##
## ############################################################################
## LIFECYCLE-UL UNEI STAMPILE — de ce sprite-urile se ASCUND dupa desen.
##
## Cu tinta necuratata, orice canvas item VIZIBIL intr-un cadru randat se
## deseneaza INCA O DATA peste ce era — adica o pata lasata vizibila s-ar
## re-acumula singura la fiecare stampila a oricui, si toata banda ar converge
## spre negru fara ca nimeni sa treaca pe acolo. De aceea fiecare sprite (si
## liniile de pre-seed) traieste UN singur desen: se arata, viewportul
## randeaza o data, si primul frame_post_draw il ascunde. Pool-ul e un inel —
## zero alocari in timpul cursei, acelasi rationament ca la SandTrail.
## ############################################################################

## Rezolutia mastii. V: 4096 px pe ~1.6 km inseamna ~2.5 px/m — o placuta de
## urma acopera ~6 px, destul pentru o banda de uzura, nu pentru desen de
## anvelopa (ala e treaba lui SandTrail, de aproape). U: 128 px pe ~24 m
## inseamna ~5 px/m, deci o roata de 0.46 m are ~2.5 px. RGBA8 = 2 MB VRAM.
const MASK_W: int = 128
const MASK_H: int = 4096

## Cate stampile pot exista intr-un singur cadru: 5 masini x 2 roti, cu marja
## pentru cadrele in care acumulatorul de distanta scapa doua depuneri.
const POOL: int = 32

## Amprenta unei stampile, in METRI (latime x lungime). Mai lata decat roata
## (0.46, ca la SandTrail.MARK_SIZE) si mai lunga decat pasul de depunere
## (2.2 m), ca petele succesive sa se suprapuna intr-o dara continua.
const STAMP_SIZE: Vector2 = Vector2(0.7, 2.8)

## Alfa unei singure treceri: ~6-7 treceri pe aceeasi linie saturarea —
## drumul "se face" in primul tur de pluton si se adanceste vizibil in restul.
const STAMP_ALPHA: float = 0.20

## Cat de tare serpuieste linia de pre-seed (m) si la ce ecart stau cele doua
## fagase (jumatate din ecartamentul unei masini, ca la SandTrail).
const SEED_WANDER: float = 1.1
const SEED_GAUGE: float = 0.85
const SEED_ALPHA: float = 0.55

var _lane_len: float = 1.0
var _lane_span: float = 1.0
var _pool: Array[Sprite2D] = []
var _next: int = 0
## Sprite-urile aratate in cadrul curent, de ascuns la primul desen.
var _shown: Array[CanvasItem] = []

static var _dot: GradientTexture2D


func _init() -> void:
	# Numele apare in remote tree-ul din editor; restul sunt setarile care fac
	# dintr-un SubViewport o "foaie de acumulare": fara 3D, fara curatare.
	disable_3d = true
	transparent_bg = true
	size = Vector2i(MASK_W, MASK_H)
	render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	render_target_update_mode = SubViewport.UPDATE_ONCE
	# Petele sunt gradiente moi; filtrul implicit NEAREST le-ar face confetti.
	canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR


## Se cheama de Track inainte de add_child: dimensiunile benzii, in metri.
## `lane_span` e TOATA latimea acoperita de masca (stanga+dreapta+marja) —
## aceeasi valoare intra ca uniform in shader, altfel petele ar cadea alaturi
## de locul pe unde a trecut roata.
func setup(lane_len: float, lane_span: float) -> void:
	_lane_len = maxf(lane_len, 1.0)
	_lane_span = maxf(lane_span, 1.0)


func _ready() -> void:
	for i in POOL:
		var s := Sprite2D.new()
		s.texture = _dot_texture()
		s.visible = false
		s.modulate = Color(1, 1, 1, STAMP_ALPHA)
		add_child(s)
		_pool.append(s)
	# Ascunderea se leaga de SFARSITUL desenului, nu de _process: _process-ul
	# cadrului urmator ruleaza inaintea desenului ALE aceluiasi cadru, deci
	# de acolo am ascunde si stampile inca nerandate.
	RenderingServer.frame_post_draw.connect(_on_frame_drawn)


func _exit_tree() -> void:
	if RenderingServer.frame_post_draw.is_connected(_on_frame_drawn):
		RenderingServer.frame_post_draw.disconnect(_on_frame_drawn)


func _on_frame_drawn() -> void:
	if _shown.is_empty():
		return
	for item in _shown:
		item.visible = false
	_shown.clear()


## Depune o pata de uzura la (metri de-a lungul soselei, metri lateral de ax).
func stamp(dist_m: float, lateral_m: float, strength: float = 1.0) -> void:
	var s := _pool[_next]
	_next = (_next + 1) % POOL
	var px := (lateral_m / _lane_span + 0.5) * float(MASK_W)
	var py := fposmod(dist_m, _lane_len) / _lane_len * float(MASK_H)
	s.position = Vector2(px, py)
	var tex_size := float(_dot_texture().get_width())
	s.scale = Vector2(
		STAMP_SIZE.x / _lane_span * float(MASK_W) / tex_size,
		STAMP_SIZE.y / _lane_len * float(MASK_H) / tex_size)
	s.modulate = Color(1, 1, 1, STAMP_ALPHA * clampf(strength, 0.0, 2.0))
	s.visible = true
	_shown.append(s)
	# Linia de sosire e si linia de start: o pata pe buza mastii trebuie sa
	# existe si pe buza cealalta, altfel dara are o pauza fixa la fiecare tur.
	var margin := STAMP_SIZE.y / _lane_len * float(MASK_H)
	if py < margin or py > float(MASK_H) - margin:
		var twin := _pool[_next]
		_next = (_next + 1) % POOL
		twin.position = Vector2(px,
			py + (float(MASK_H) if py < margin else -float(MASK_H)))
		twin.scale = s.scale
		twin.modulate = s.modulate
		twin.visible = true
		_shown.append(twin)
	render_target_update_mode = SubViewport.UPDATE_ONCE


## Doua fagase palide pe toata bucla, DINAINTE de cursa: pe un drum de sat
## se circula de-o iarna intreaga, nu incepe alb ca foaia. Serpuirea e un
## sinus dublu — destul cat linia sa nu fie trasa cu rigla, determinist ca
## totul in lume. Liniile traiesc, ca stampilele, un singur desen.
func preseed() -> void:
	for side: float in [-1.0, 1.0]:
		var line := Line2D.new()
		line.width = 0.5 / _lane_span * float(MASK_W)
		line.default_color = Color(1, 1, 1, SEED_ALPHA)
		var pts := PackedVector2Array()
		var step := 6.0
		var d := 0.0
		# Un pas DINCOLO de capat, cu acelasi meandru evaluat pe distanta
		# infasurata: capatul de jos al mastii continua exact in capatul de
		# sus, ca la stampilele-geamane de mai sus.
		while d <= _lane_len + step:
			var wrapped := fposmod(d, _lane_len)
			var lateral := SEED_WANDER * sin(wrapped * 0.011) \
				+ 0.4 * sin(wrapped * 0.023 + 1.7) + SEED_GAUGE * side
			pts.append(Vector2(
				(lateral / _lane_span + 0.5) * float(MASK_W),
				d / _lane_len * float(MASK_H)))
			d += step
		line.points = pts
		add_child(line)
		_shown.append(line)
	render_target_update_mode = SubViewport.UPDATE_ONCE


## Pata moale: gradient radial alb -> transparent. Una singura, partajata.
static func _dot_texture() -> GradientTexture2D:
	if _dot != null:
		return _dot
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	# Miez plin pana la ~0.4 din raza, apoi stingere — profilul placutei
	# SandTrail (miez cat roata, margini care se sting).
	g.add_point(0.4, Color(1, 1, 1, 1))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 64
	tex.height = 64
	_dot = tex
	return _dot
