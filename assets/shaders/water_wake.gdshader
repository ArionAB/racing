shader_type spatial;
// SIAJUL masinii prin apa: o panza plata la nivelul luciului, sub si in
// spatele masinii, cu spuma care curge SPRE SPATE cat timp mergi prin apa.
//
// De ce exista: cu apa opaca si roatele pe jumatate sub ea, masina citea ca
// „merge PE apa" (verdictul dezvoltatorului, 12 sep 2026). Ce lipsea nu era
// cota, ci INTERACTIUNEA — apa deranjata in jurul rotilor, val de etrava in
// fata, siaj in V in spate. Stropii (particule) sunt prea rari ca s-o spuna
// singuri; siajul e continuu si sta exact intre camera si masina.
//
// Contract: transparent (o singura panza mica per masina, ~12 m², nu o
// suprafata de ecran — overdraw neglijabil), unshaded, ZERO texturi noi:
// spuma vine din aceeasi detail_rock.png pe care o foloseste apa. Un singur
// material static, impartit de toate masinile.
//
// UV: x = 0 la bot, 1 la coada; y = -1..1 de-a latul. Forma vine din
// geometrie (mesh-ul e deja un V), aici se decide doar cat de alba e spuma
// in fiecare punct si cum se misca.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D ripple_tex : source_color, filter_linear_mipmap, repeat_enable;
instance uniform vec3 foam_col : source_color = vec3(0.9, 0.95, 0.95);
// Cat de tare se vede siajul (0 = stins); masina il leaga de viteza.
instance uniform float strength : hint_range(0.0, 1.0) = 1.0;
// Viteza spumei spre spate, in unitati de UV pe secunda.
uniform float flow : hint_range(0.0, 6.0) = 1.6;

void fragment() {
	vec2 uv = UV;
	// Spuma: doua esantioane pe axe rotite (stratele texturii de roca ar da
	// dungi paralele altfel — lectia din water.gdshader), care curg spre coada.
	vec2 u1 = vec2(uv.x * 1.6 - TIME * flow, uv.y * 0.9);
	vec2 u2 = vec2(u1.x * 0.454 - u1.y * 0.891, u1.x * 0.891 + u1.y * 0.454) * 0.7
		+ vec2(0.3, TIME * 0.1);
	float s = 1.0 - texture(ripple_tex, u1).r * texture(ripple_tex, u2).r;
	float foam = smoothstep(0.08, 0.55, s);
	// Plin la bot si pe muchiile V-ului, gol pe axa si la coada.
	float along = 1.0 - smoothstep(0.0, 1.0, uv.x);
	float edge = smoothstep(0.15, 0.75, abs(uv.y)) * (1.0 - smoothstep(0.85, 1.0, abs(uv.y)));
	float bow = 1.0 - smoothstep(0.0, 0.22, uv.x);
	float mask = clamp(bow * 0.9 + edge * along, 0.0, 1.0);
	float a = (0.35 + 0.65 * foam) * mask * strength;
	ALBEDO = foam_col;
	ALPHA = a * 0.85;
}
