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

## Cat de intunecate ajung colturile (0 = deloc, 1 = negru).
const STRENGTH: float = 0.16
## De unde incepe caderea, ca fractie din raza (0.5 = de la jumatate).
const START: float = 0.50

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
