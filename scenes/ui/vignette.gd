class_name Vignette
extends CanvasLayer
## Vigneta: colturile ecranului putin mai intunecate, ochiul tras spre masina.
##
## Specificata in style_bible §8 de la inceput (0.10), lasata neimplementata
## fiindca "efectul se vede doar in capturi". La 0.10 e adevarat; aici e
## 0.16, cu caderea abia de la jumatatea razei, ca sa se simta la volan fara
## sa manance imaginea. Cost: UN singur strat de canvas pe tot ecranul, cu
## blend multiplicativ — pe un GPU cu placi e cel mai ieftin efect posibil,
## si singurul "post-proces" care nu cere o pasa in plus.
##
## Sta pe stratul 0, SUB HUD (stratul 1): HUD-ul, contorul si minimapa raman
## la luminozitatea lor, doar lumea se intuneca pe margini.
##
## Tot aici sta si flash-ul de margine al izbiturilor (`flash_edge`, feel:
## who-hit-me): o dunga luminoasa, scurta, pe partea ecranului dinspre care a
## venit lovitura. Patru fasii de gradient, toate ascunse in repaus (cost zero);
## `_process` ruleaza doar cat dureaza flash-ul.

## Cat de intunecate ajung colturile (0 = deloc, 1 = negru).
const STRENGTH: float = 0.16
## De unde incepe caderea, ca fractie din raza (0.5 = de la jumatate).
const START: float = 0.50

## Marginile flash-ului, ca indici pentru `edge_alpha`.
enum Edge { LEFT, RIGHT, TOP, BOTTOM }
## Cat din ecran acopera fasia unei margini (fractie din latura).
const FLASH_DEPTH: float = 0.22
## Cat de repede se stinge flash-ul (alfa pe secunda). 5 => ~0.1-0.2 s.
const FLASH_DECAY: float = 5.0
const FLASH_COLOR: Color = Color(1.0, 0.88, 0.7)

var _edge_rects: Array[TextureRect] = []
var _edge_alpha: Array[float] = [0.0, 0.0, 0.0, 0.0]

func _ready() -> void:
	layer = 0
	var rect := TextureRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture = _texture()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	rect.material = mat
	add_child(rect)
	_build_edges()
	set_process(false)


## `screen_dir`: directia OBSTACOLULUI pe ecran (x: + dreapta, y: + sus/in fata).
## `strength` 0..1 = alfa maxim. Marginea cea mai aproape de directie se aprinde
## cel mai tare; o lovitura pe diagonala le aprinde pe amandoua.
func flash_edge(screen_dir: Vector2, strength: float) -> void:
	if screen_dir.length_squared() < 1e-6 or strength <= 0.0:
		return
	var d := screen_dir.normalized()
	var comps: Array[float] = [maxf(-d.x, 0.0), maxf(d.x, 0.0),
		maxf(d.y, 0.0), maxf(-d.y, 0.0)]
	for i in 4:
		_edge_alpha[i] = maxf(_edge_alpha[i], comps[i] * strength)
	_apply_edges()
	set_process(true)


func edge_alpha(edge: int) -> float:
	return _edge_alpha[edge]


func _process(delta: float) -> void:
	var any := false
	for i in 4:
		_edge_alpha[i] = maxf(_edge_alpha[i] - FLASH_DECAY * delta, 0.0)
		any = any or _edge_alpha[i] > 0.0
	_apply_edges()
	if not any:
		set_process(false)


func _apply_edges() -> void:
	for i in 4:
		var r := _edge_rects[i]
		r.visible = _edge_alpha[i] > 0.003
		r.modulate.a = _edge_alpha[i]


## Patru fasii de gradient (opac la margine, transparent spre interior). Fiecare
## TextureRect ia ancorele marginii ei; gradientul e un GradientTexture2D liniar
## orientat spre interior.
func _build_edges() -> void:
	# (ancore: stanga, sus, dreapta, jos), (fill_from, fill_to) in textura
	var specs: Array = [
		[Vector4(0.0, 0.0, FLASH_DEPTH, 1.0), Vector2(0, 0.5), Vector2(1, 0.5)],
		[Vector4(1.0 - FLASH_DEPTH, 0.0, 1.0, 1.0), Vector2(1, 0.5), Vector2(0, 0.5)],
		[Vector4(0.0, 0.0, 1.0, FLASH_DEPTH), Vector2(0.5, 0), Vector2(0.5, 1)],
		[Vector4(0.0, 1.0 - FLASH_DEPTH, 1.0, 1.0), Vector2(0.5, 1), Vector2(0.5, 0)],
	]
	for spec: Array in specs:
		var a: Vector4 = spec[0]
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([FLASH_COLOR, Color(FLASH_COLOR, 0.0)])
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.width = 64
		tex.height = 64
		tex.fill = GradientTexture2D.FILL_LINEAR
		tex.fill_from = spec[1]
		tex.fill_to = spec[2]
		var r := TextureRect.new()
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.texture = tex
		r.anchor_left = a.x
		r.anchor_top = a.y
		r.anchor_right = a.z
		r.anchor_bottom = a.w
		r.offset_left = 0.0
		r.offset_top = 0.0
		r.offset_right = 0.0
		r.offset_bottom = 0.0
		r.visible = false
		add_child(r)
		_edge_rects.append(r)


## Gradient radial alb -> gri, intins pe tot ecranul. Textura e mica (256²):
## o rampa lina n-are nevoie de rezolutie, iar filtrarea liniara o intinde
## fara trepte.
static func _texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, START, 1.0])
	g.colors = PackedColorArray([Color.WHITE, Color.WHITE,
		Color(1.0 - STRENGTH, 1.0 - STRENGTH, 1.0 - STRENGTH)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 1.0)
	return tex
