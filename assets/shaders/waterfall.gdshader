shader_type spatial;
// PERDEAUA DE APA (Fiordland, brief §5.1 clasa `waterfall`): un singur
// material pentru toate cele 7 perdele — Stirling, cele 5 de ploaie, Bowen.
//
// Ce trebuie sa citeasca ochiul: APA CARE CADE, nu un zid. Placeholder-ul
// (o cutie pe FOAM_WHITE) dadea exact zidul: fara directie, fara margine
// moale, fara fundal prin el. Aici forma vine din trei lucruri, in ordinea
// importantei:
//   1. DUNGI VERTICALE (fire de apa) — zgomot 1D pe latime, deci gradientul
//      orizontal e mult mai mare decat cel vertical (memoria
//      `statistica-de-ordin-zero-nu-vede-forma`: forma se masoara prin
//      anizotropia muchiilor, nu prin culoare);
//   2. CURGERE in jos — zgomot 2D alungit pe verticala, translatat cu TIME
//      (`fall_speed` in metri pe secunda, fiindca UV2 e in metri);
//   3. MARGINI care cad CONTINUU la zero — lateral (`edge_m` metri, profil
//      smoothstep) si sus (`top_frac` din inaltime): 0 trepte dure pe o
//      taietura prin margine (memoria `particule-muchia-nu-numarul`).
// La baza, o banda de SPUMA (`foam_m`): mai alba si mai densa — de la 100 m
// camera vede doar baza (brief §2.0), deci baza e cea care spune „apa cade
// pe drum".
//
// Contract de cost: unshaded, blend_mix, fara scriere in depth (perdelele
// si spray-ul se suprapun fara sa se taie), cull_disabled (o panza se vede
// din ambele parti), UN pass, ZERO texturi — totul e procedural. Ceata
// scenei ramane activa: perdelele departate se topesc in ea ca orice altceva.
//
// Ce ii da mesh-ul (vezi `WaterfallVisual`):
//   UV2     = (x_m, y_m) in METRI, y in jos de la varf — zgomot, viteza, fade;
//   COLOR.a = alpha de vertex (caderea radiala a placii de spuma; 1 pe panze).
// Dimensiunile vin ca INSTANCE UNIFORMS, nu prin vertex color: SurfaceTool
// taie culoarea la [0,1] (memoria `surfacetool-clamp-vertex-color`), deci o
// latime de 30 m ajungea 1 m si fade-ul lateral disparea — prima captura a
// dat o placa de sticla uniforma, exact zidul pe care il inlocuiam.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

// Apa in cadere: alb-albastrui pal, nu alb pur (albul e pentru spuma).
uniform vec3 water_col : source_color = vec3(0.78, 0.89, 0.95);
uniform vec3 foam_col : source_color = vec3(0.97, 0.99, 1.0);
// Opacitatea maxima a corpului perdelei (brief: 0.55-0.75, fundalul trebuie
// sa se ghiceasca prin ea).
uniform float alpha_max : hint_range(0.0, 1.0) = 0.66;
// Viteza de cadere a desenului (m/s). Apa reala cade cu 15-25 m/s la baza
// unei cascade de 45 m; pe ecran, 9 se citeste ca „repede" fara sa devina
// zgomot.
uniform float fall_speed : hint_range(0.0, 30.0) = 9.0;
// Cate fire pe metru (scara zgomotului 1D pe latime).
uniform float streak_scale : hint_range(0.1, 4.0) = 1.1;
// Latimea (m) pe care alpha cade la zero la marginile laterale.
uniform float edge_m : hint_range(0.2, 10.0) = 2.5;
// Fractia din inaltime pe care perdeaua se topeste spre varf.
uniform float top_frac : hint_range(0.05, 0.9) = 0.4;
// Inaltimea (m) benzii de spuma de la baza.
uniform float foam_m : hint_range(0.0, 6.0) = 1.8;
// Faza de ploaie (RainCycle) o stinge/aprinde prin `modulate` pe hazard;
// per instanta, ca sa nu se dubleze materialul.
instance uniform float intensity : hint_range(0.0, 1.0) = 1.0;
// (latime, inaltime) in metri ale panzei — per MeshInstance3D, acelasi material.
instance uniform vec2 sheet_m = vec2(6.0, 14.0);
// 1 pe placa de spuma de la sol: mereu spuma, fara fade lateral/sus.
instance uniform float pad : hint_range(0.0, 1.0) = 0.0;

varying vec2 v_m;
varying vec4 v_col;

float hash1(float n) {
	return fract(sin(n) * 43758.5453123);
}

float vnoise1(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash1(i), hash1(i + 1.0), f);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x);
	float b = mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x);
	return mix(a, b, f.y);
}

float sstep(float x) {
	x = clamp(x, 0.0, 1.0);
	return x * x * (3.0 - 2.0 * x);
}

void vertex() {
	v_m = UV2;
	v_col = COLOR;
}

void fragment() {
	float w = max(sheet_m.x, 0.01);
	float h = max(sheet_m.y, 0.01);
	float x = v_m.x;
	float y = v_m.y;
	float t = TIME * fall_speed;

	// 1. firele: doua octave de zgomot 1D pe latime, statice — dunga ramane
	//    la locul ei, doar apa din ea curge.
	float streak = vnoise1(x * streak_scale * 3.0) * 0.55
		+ vnoise1(x * streak_scale * 0.9 + 17.0) * 0.45;
	// 2. curgerea: zgomot 2D alungit pe verticala (x de ~6 ori mai des decat
	//    y), translatat in jos; a doua octava cade putin mai repede — apa nu
	//    e un tapet care aluneca.
	float flow = vnoise2(vec2(x * streak_scale * 2.2, (y + t) * 0.35));
	float flow2 = vnoise2(vec2(x * streak_scale * 5.0 + 3.0, (y + t * 1.3) * 0.9));
	float body = streak * 0.6 + flow * 0.25 + flow2 * 0.15;
	// contrast intre fire: fara el dungile raman o textura de 5%, invizibila
	// de la 30 m — si perdeaua citeste iar ca placa.
	body = clamp((body - 0.5) * 1.8 + 0.5, 0.0, 1.0);

	// 3. marginile: continuu la zero, lateral si sus. Placa de spuma nu are
	//    margini de perdea — caderea ei radiala e in alpha-ul de vertex.
	float lat = sstep(min(x, w - x) / edge_m);
	float top = sstep(y / (h * top_frac));
	lat = mix(lat, 1.0, pad);
	top = mix(top, 1.0, pad);

	// spuma: banda de la baza, sau toata placa.
	float foam = sstep((y - (h - foam_m)) / foam_m);
	foam = max(foam, pad);

	vec3 col = mix(water_col, foam_col, clamp(foam * 0.85 + body * 0.25, 0.0, 1.0));
	float a = alpha_max * (0.25 + 0.75 * body);
	// baza mai densa — spuma e albul opac al perdelei, corpul e translucid.
	a = mix(a, min(a + 0.28, 0.92), foam * 0.8);
	// marginile se aplica DUPA spuma: si banda de spuma se topeste lateral.
	a *= lat * top;
	ALBEDO = col;
	ALPHA = a * intensity * v_col.a;
}
