class_name WindshieldWipers
extends CanvasLayer
## „PARBRIZUL UD" (Fiordland, brief pasul 4): picaturi pe ecran cand masina
## JUCATORULUI e in perdeaua Stirling (mult, dintr-o data) sau in ploaie
## (putin, continuu) — alunecare in jos accelerata cu mici zig-zaguri,
## contopire optionala, disparitie in 2-4s.
##
## E un layer de PREZENTARE PURA: citeste starea (perdea/ploaie) prin doua
## functii mici pe care `Race` le leaga o data la `_ready`, si nu atinge
## niciodata fizica, input-ul sau camera. Pe uscat si in afara perdelei:
## 0 noduri vizibile (`visible = false` pe tot layer-ul cand nu sunt
## picaturi active — acelasi contract "cost zero" ca `RainScreen`).
##
## Construit in cod, ca `RaceHUD`/`RainScreen`: un singur `Texture2D` generat
## o data (cerc cu highlight, alfa continua la margine — memoria
## `particule-muchia-nu-numarul`, aceeasi regula si in 2D) si un pool FIX de
## `Sprite2D` (max `MAX_DROPS`), nu instantiere/eliberare per picatura — un
## overlay care aloca/dealoca noduri in fiecare cadru ar fi exact risipa pe
## care pool-ul o evita.
##
## Dezactivabil printr-un export (`enabled`), verificat din `Race` sau direct
## de-a lungul lantului: `set_enabled(false)` goleste pool-ul si opreste
## emisia, fara sa lase noduri vizibile in urma.

## Cate picaturi cel mult simultan pe ecran.
const MAX_DROPS: int = 32
## Cate picaturi dintr-o data cand masina INTRA in perdea (brief: 20-30).
const CURTAIN_BURST_MIN: int = 20
const CURTAIN_BURST_MAX: int = 30
## Rata de picaturi/secunda cat timp masina e in ploaie (brief: 1-2/s).
const RAIN_RATE_MIN: float = 1.0
const RAIN_RATE_MAX: float = 2.0
## Cat traiesc picaturile (s) inainte sa dispara (brief: 2-4s).
const LIFETIME_MIN: float = 2.0
const LIFETIME_MAX: float = 4.0
## Viteza de start/accelerare pe verticala (px/s si px/s^2) — cad accelerat,
## nu cu viteza constanta (o picatura reala pe sticla capata viteza).
const FALL_SPEED_START: float = 40.0
const FALL_ACCEL: float = 90.0
## Amplitudinea/frecventa micilor zig-zaguri laterale.
const ZIGZAG_AMPLITUDE_PX: float = 5.0
const ZIGZAG_FREQ_MIN: float = 1.5
const ZIGZAG_FREQ_MAX: float = 3.0
## Raza vizuala a unei picaturi (px) si textura generata (patrata, px).
const DROP_RADIUS_PX: float = 9.0
const TEX_SIZE: int = 32
## Sub ce distanta (px) doua picaturi se pot contopi (optional, cand se
## intersecteaza pe traiectorie): mai mica decat 2*raza, ca sa nu se
## contopeasca la simpla atingere a marginilor.
const MERGE_DIST_PX: float = 10.0
## Sansa (per pereche, per cadru cat sunt suficient de aproape) ca doua
## picaturi sa se contopeasca, in loc sa se contopeasca instant la orice
## apropiere — o contopire care se intampla mereu arata mecanica.
const MERGE_CHANCE_PER_S: float = 0.6

## Dezactivare completa (setari, sau device slab): brief pasul 4, "un export".
@export var enabled: bool = true:
	set(value):
		enabled = value
		if not value:
			_clear_all()

static var _drop_texture: ImageTexture = null
static var _material: CanvasItemMaterial = null

## Sursele de stare, legate o data din Race (`configure`). Functii, nu
## referinte directe la Car/WaterfallHazard: overlay-ul nu trebuie sa stie
## CE e o masina sau un hazard, doar "sunt in perdea?" / "cat de tare ploua?".
var _in_curtain_fn: Callable = Callable()
var _rain_factor_fn: Callable = Callable()

var _rng := RandomNumberGenerator.new()
var _pool: Array[Sprite2D] = []
## Stare per picatura, index-aliniat cu `_pool`: null = slot liber.
var _states: Array = []
var _was_in_curtain: bool = false
var _rain_accum: float = 0.0
var _viewport_size: Vector2 = Vector2(1280, 720)


class DropState:
	var pos: Vector2
	var vy: float
	var zigzag_phase: float
	var zigzag_freq: float
	var age: float = 0.0
	var lifetime: float


func _ready() -> void:
	# Layer mai MIC decat HUD-ul (RaceHUD nu-si seteaza `layer`, deci ramane
	# implicitul 1): un CanvasLayer deseneaza deasupra celor cu layer mai mic,
	# deci 0 sta DEASUPRA lumii 3D (care nu e pe niciun CanvasLayer) dar SUB
	# HUD — picaturile nu au voie sa acopere viteza/pozitia/bara de turbo.
	layer = 0
	_rng.randomize()
	visible = false
	_build_pool()
	_viewport_size = get_viewport().get_visible_rect().size
	set_process(true)


## Legat o data de `Race._ready()`. `in_curtain_fn`: `func() -> bool` — e
## masina jucatorului ACUM sub perdeaua Stirling? `rain_factor_fn`:
## `func() -> float` — 0..1, intensitatea ploii curente (RainCycle).
func configure(in_curtain_fn: Callable, rain_factor_fn: Callable) -> void:
	_in_curtain_fn = in_curtain_fn
	_rain_factor_fn = rain_factor_fn


static func _texture() -> ImageTexture:
	if _drop_texture == null:
		var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
		var c := Vector2(TEX_SIZE * 0.5, TEX_SIZE * 0.5)
		var r := TEX_SIZE * 0.5 - 1.0
		for y in TEX_SIZE:
			for x in TEX_SIZE:
				var p := Vector2(x + 0.5, y + 0.5)
				var d := p.distance_to(c) / r
				# Alfa continua la margine (cos^2-style falloff), nu prag dur —
				# aceeasi regula ca RainScreen/spray-ul cascadei.
				var a := clampf(1.0 - d, 0.0, 1.0)
				a = a * a * (3.0 - 2.0 * a) # smoothstep, 0 exact la r=1
				# Highlight: un punct mai alb, deplasat spre stanga-sus, ca sa
				# citeasca "picatura de sticla", nu disc plat.
				var hl := (p - c * 0.68).length() / (r * 0.55)
				var hl_a := clampf(1.0 - hl, 0.0, 1.0)
				hl_a = hl_a * hl_a
				var col := Color(1.0, 1.0, 1.0, a)
				col.r = clampf(col.r + hl_a * 0.35, 0.0, 1.0)
				col.g = clampf(col.g + hl_a * 0.35, 0.0, 1.0)
				col.b = clampf(col.b + hl_a * 0.35, 0.0, 1.0)
				img.set_pixel(x, y, col)
		_drop_texture = ImageTexture.create_from_image(img)
	return _drop_texture


static func _drop_material() -> CanvasItemMaterial:
	if _material == null:
		_material = CanvasItemMaterial.new()
		_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	return _material


func _build_pool() -> void:
	var tex := _texture()
	var mat := _drop_material()
	var foam := Palette.color(Palette.FOAM_WHITE)
	for i in MAX_DROPS:
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.material = mat
		sp.centered = true
		sp.visible = false
		sp.modulate = Color(foam.r, foam.g, foam.b, 0.75)
		var scale_f := DROP_RADIUS_PX * 2.0 / float(TEX_SIZE)
		sp.scale = Vector2(scale_f, scale_f)
		add_child(sp)
		_pool.append(sp)
		_states.append(null)


func _process(delta: float) -> void:
	if not enabled:
		return
	var in_curtain := false
	if _in_curtain_fn.is_valid():
		in_curtain = bool(_in_curtain_fn.call())
	var rain_f := 0.0
	if _rain_factor_fn.is_valid():
		rain_f = float(_rain_factor_fn.call())

	# INTRARE in perdea: rafala, o singura data la tranzitia fals->adevarat
	# (nu la fiecare cadru cat timp ramane inauntru — la fel ca splash-ul
	# hazardului, brief pasul 3b).
	if in_curtain and not _was_in_curtain:
		var n := _rng.randi_range(CURTAIN_BURST_MIN, CURTAIN_BURST_MAX)
		for _i in n:
			_spawn_drop()
	_was_in_curtain = in_curtain

	# PLOAIE: rata continua, proportionala cu intensitatea (brief: 1-2/s la
	# ploaie plina; 0 pe uscat).
	if rain_f > 0.001:
		var rate := lerpf(RAIN_RATE_MIN, RAIN_RATE_MAX, rain_f)
		_rain_accum += rate * delta
		while _rain_accum >= 1.0:
			_rain_accum -= 1.0
			_spawn_drop()
	else:
		_rain_accum = 0.0

	_advance_drops(delta)
	_maybe_merge(delta)

	var any_active := false
	for st in _states:
		if st != null:
			any_active = true
			break
	visible = any_active


func _spawn_drop() -> void:
	var slot := _states.find(null)
	if slot < 0:
		return # pool plin — o picatura in plus se pierde, nu se forteaza peste plafon
	var st := DropState.new()
	st.pos = Vector2(
		_rng.randf_range(_viewport_size.x * 0.05, _viewport_size.x * 0.95),
		_rng.randf_range(-_viewport_size.y * 0.15, _viewport_size.y * 0.3))
	st.vy = FALL_SPEED_START * _rng.randf_range(0.7, 1.3)
	st.zigzag_phase = _rng.randf_range(0.0, TAU)
	st.zigzag_freq = _rng.randf_range(ZIGZAG_FREQ_MIN, ZIGZAG_FREQ_MAX)
	st.lifetime = _rng.randf_range(LIFETIME_MIN, LIFETIME_MAX)
	_states[slot] = st
	var sp := _pool[slot]
	sp.position = st.pos
	sp.visible = true
	sp.modulate.a = 0.75


func _advance_drops(delta: float) -> void:
	for i in _states.size():
		var st: DropState = _states[i]
		if st == null:
			continue
		st.age += delta
		if st.age >= st.lifetime:
			_states[i] = null
			_pool[i].visible = false
			continue
		st.vy += FALL_ACCEL * delta
		var zz := sin(st.age * st.zigzag_freq * TAU * 0.25 + st.zigzag_phase) * ZIGZAG_AMPLITUDE_PX
		st.pos.y += st.vy * delta
		var sp := _pool[i]
		sp.position = Vector2(st.pos.x + zz, st.pos.y)
		# Fade in ultima treime din viata (dispare lin, nu brusc) si fade-in
		# scurt la nastere (evita "pocnetul" unei rafale de 20-30 deodata).
		var fade_in := clampf(st.age / 0.15, 0.0, 1.0)
		var fade_out := clampf((st.lifetime - st.age) / (st.lifetime * 0.3), 0.0, 1.0)
		sp.modulate.a = 0.75 * fade_in * fade_out
		if st.pos.y > _viewport_size.y + DROP_RADIUS_PX * 2.0:
			_states[i] = null
			sp.visible = false


## Contopire OPTIONALA: cand doua picaturi active sunt suficient de aproape,
## una absoarbe cealalta (creste usor, cealalta dispare) — nu e o coliziune
## fizica, doar un efect vizual ocazional (`MERGE_CHANCE_PER_S`), ca ecranul
## sa nu para o grila perfect independenta de puncte.
func _maybe_merge(delta: float) -> void:
	var active: Array[int] = []
	for i in _states.size():
		if _states[i] != null:
			active.append(i)
	for a in active.size():
		var ia: int = active[a]
		var sa: DropState = _states[ia]
		if sa == null:
			continue
		for b in range(a + 1, active.size()):
			var ib: int = active[b]
			var sb: DropState = _states[ib]
			if sb == null:
				continue
			if sa.pos.distance_to(sb.pos) > MERGE_DIST_PX:
				continue
			if _rng.randf() > MERGE_CHANCE_PER_S * delta:
				continue
			# Cea mai de jos (mai avansata) absoarbe pe cealalta — se comporta
			# ca o picatura care a "prins" alta din urma.
			var keep_i := ia if sa.pos.y >= sb.pos.y else ib
			var drop_i := ib if keep_i == ia else ia
			var keep_st: DropState = _states[keep_i]
			keep_st.vy = maxf(keep_st.vy, _states[drop_i].vy)
			_pool[keep_i].scale *= 1.12
			_states[drop_i] = null
			_pool[drop_i].visible = false


func _clear_all() -> void:
	for i in _states.size():
		_states[i] = null
		_pool[i].visible = false
	visible = false


## Pentru sonde/capturi (`Snapshot --wipers-demo`): umple pool-ul direct cu
## `count` picaturi, fara sa astepte `_in_curtain_fn`/`_rain_factor_fn` (care,
## in afara unei curse reale, n-au de unde sa vina). Aceeasi geometrie/pool ca
## in joc — doar punctul de intrare difera.
func force_spawn_demo(count: int) -> void:
	visible = true
	for _i in mini(count, MAX_DROPS):
		_spawn_drop()
