extends CanvasLayer
## Linii de viteza pe marginile ecranului (feel: sense-of-speed, partea vizuala).
##
## Apar de la ~70% din viteza maxima si cat tine turbo-ul; intensitatea creste cu
## viteza. Stau pe stratul 0 (sub HUD), ca vigneta.
##
## COST, pentru mobil: patru fasii pe margini (nu tot ecranul, ~40% din arie),
## un singur material partajat cu un shader de cateva zeci de operatii, fara
## texturi. Sub prag stratul intreg e `visible = false`: nu se randeaza nimic si
## `_process` iese din prima linie. Fara sunet de vant (partea audio vine separat).
##
## Forma: dunge RADIALE, pornind din centrul ecranului spre margini, fiecare cu
## unghi, grosime si viteza proprii (hash pe indicele sectorului), care curg spre
## exterior. Mai multe dunge se aprind pe masura ce creste intensitatea.

## De la ce fractie din viteza maxima apar liniile, si unde ating intensitatea 1.
@export var start_frac: float = 0.70
@export var full_frac: float = 1.0
## Intensitatea minima cat arde turbo-ul, oricat de incet ai merge in clipa aia.
@export var turbo_floor: float = 0.8
## Aspiratia (slipstream): de la `draft_threshold` din `Car.draft`, liniile au
## o podea de `draft_floor` * draft chiar si sub pragul de viteza, putin mai
## reci la culoare (`draft_tint`) — se vede ca „te trage" masina din fata. Mai
## slaba decat podeaua turbo-ului (0.8): e un indiciu, nu o explozie.
@export var draft_threshold: float = 0.3
@export var draft_floor: float = 0.5
@export var draft_tint: Color = Color(0.78, 0.9, 1.0)
## Alfa maxim al unei dunge la intensitatea 1 (discret: se vede la marginea ochiului).
@export var max_alpha: float = 0.5
## Cat de repede urca / coboara intensitatea afisata (1/s), netezita ca sa nu palpaie.
@export var rise_rate: float = 6.0
@export var fall_rate: float = 3.0

## Sub asta stratul se ascunde de tot.
const HIDE_BELOW: float = 0.01
const SHADER_CODE: String = """
shader_type canvas_item;
uniform float intensity = 0.0;
uniform float max_alpha = 0.5;
uniform vec3 tint = vec3(1.0);
uniform float aspect = 1.78;
const float LINES = 64.0;

float hash(float n) {
	return fract(sin(n * 127.1 + 31.7) * 43758.5453);
}

void fragment() {
	// Coordonate centrate pe ecran, ecranul = [-aspect, aspect] x [-1, 1].
	vec2 uv = FRAGCOORD.xy * SCREEN_PIXEL_SIZE;
	vec2 p = (uv - 0.5) * vec2(aspect, 1.0) * 2.0;
	float r = length(p);
	float seg = (atan(p.y, p.x) / 6.2831853 + 0.5) * LINES;
	float id = floor(seg);
	// Cate dunge sunt aprinse: creste cu intensitatea.
	float on = step(1.0 - mix(0.12, 0.55, intensity), hash(id + 11.0));
	// Subtire pe unghi, cu grosime proprie.
	float f = abs(fract(seg) - 0.5) * 2.0;
	float w = mix(0.12, 0.45, hash(id + 7.0));
	float line = 1.0 - smoothstep(w * 0.5, w, f);
	// Dasuri care curg spre exterior, fiecare cu ritmul ei.
	float h = hash(id);
	float d = fract(r * mix(0.7, 1.5, h) - TIME * mix(1.4, 3.0, hash(id + 3.0)) + h * 10.0);
	float dash = smoothstep(0.0, 0.08, d) * (1.0 - smoothstep(0.22, 0.6, d));
	// Doar spre margini, si se sting INAINTE de marginea fasiei (altfel dungile ar
	// fi taiate drept de dreptunghi): 0.13 din latime / 0.09 din inaltime, fasiile
	// au 0.14 / 0.10.
	float fx = 1.0 - smoothstep(0.0, 0.13, min(uv.x, 1.0 - uv.x));
	float fy = 1.0 - smoothstep(0.0, 0.09, min(uv.y, 1.0 - uv.y));
	float edge = max(fx, fy);
	COLOR = vec4(tint, line * dash * edge * on * intensity * max_alpha);
}
"""

## Masina urmarita (jucatorul). Fara ea, stratul ramane ascuns.
var target: Car
var _intensity: float = 0.0
var _mat: ShaderMaterial


func _ready() -> void:
	layer = 0
	var sh := Shader.new()
	sh.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_mat.set_shader_parameter("max_alpha", max_alpha)
	# fasii: stanga, dreapta (inaltime plina), sus, jos (intre ele)
	var strips: Array = [
		[0.0, 0.0, 0.14, 1.0], [0.86, 0.0, 1.0, 1.0],
		[0.14, 0.0, 0.86, 0.10], [0.14, 0.90, 0.86, 1.0],
	]
	for a: Array in strips:
		var r := ColorRect.new()
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.color = Color.WHITE
		r.material = _mat
		r.anchor_left = float(a[0])
		r.anchor_top = float(a[1])
		r.anchor_right = float(a[2])
		r.anchor_bottom = float(a[3])
		r.offset_left = 0.0
		r.offset_top = 0.0
		r.offset_right = 0.0
		r.offset_bottom = 0.0
		add_child(r)
	visible = false


## Intensitatea tinta 0..1 pentru o fractie de viteza si turbo.
## Statica ca sonda sa-i poata verifica curba fara scena.
static func intensity_for(speed_frac: float, boosting: bool, p_start: float = 0.70,
		p_full: float = 1.0, p_turbo_floor: float = 0.8, p_draft: float = 0.0,
		p_draft_threshold: float = 0.3, p_draft_floor: float = 0.5) -> float:
	var t := clampf((speed_frac - p_start) / maxf(p_full - p_start, 0.001), 0.0, 1.0)
	var base := t * t * (3.0 - 2.0 * t) # smoothstep
	if p_draft > p_draft_threshold:
		base = maxf(base, p_draft_floor * p_draft)
	return maxf(base, p_turbo_floor) if boosting else base


## Intensitatea afisata acum (dupa netezire), pentru sonde.
func intensity() -> float:
	return _intensity


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		visible = false
		return
	var frac := target.horizontal_speed() / maxf(target.max_speed, 0.1)
	# `draft` citit prin get(): fisierul ruleaza si pe ramuri unde Car nu-l are inca.
	var draft := float(target.get(&"draft"))
	var goal := intensity_for(frac, target.is_boosting, start_frac, full_frac,
		turbo_floor, draft, draft_threshold, draft_floor)
	var rate := rise_rate if goal > _intensity else fall_rate
	_intensity = move_toward(_intensity, goal, rate * delta)
	if _intensity <= HIDE_BELOW and goal <= 0.0:
		_intensity = 0.0
		visible = false
		return
	visible = true
	_mat.set_shader_parameter("intensity", _intensity)
	# Culoarea: alb, cu un strop de rece cat dureaza aspiratia (turbo-ul ramane alb).
	var cool := clampf((draft - draft_threshold) / maxf(1.0 - draft_threshold, 0.01), 0.0, 1.0)
	if target.is_boosting:
		cool = 0.0
	var c := Color.WHITE.lerp(draft_tint, cool)
	_mat.set_shader_parameter("tint", Vector3(c.r, c.g, c.b))
	var vp := get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", vp.x / maxf(vp.y, 1.0))
