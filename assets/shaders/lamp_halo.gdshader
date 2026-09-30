// HALOUL FALS al unei surse de lumina (Jodhpur: candele, becuri, felinare,
// lampile fortului). Decizia dezvoltatorului din 30 sep 2026: FARA glow/bloom
// in Environment (post-procesare scumpa pe mobil, CLAUDE.md) — o lampa
// „straluceste" printr-un billboard mic, ADITIV, cu cadere continua (brief
// jodhpur §4 si §6).
//
// UN SINGUR material pentru toate halourile pistei (garda numara materiale):
// tot ce difera intre surse vine PER INSTANTA, din MultiMesh:
//   COLOR              culoarea luminii (rgb) si intensitatea (a)
//   INSTANCE_CUSTOM.x  raza miezului (m) — „punctul" de foc
//   INSTANCE_CUSTOM.y  raza haloului (m)
//   INSTANCE_CUSTOM.z  alungirea verticala a miezului (1 = glob, >1 = flacara)
//   INSTANCE_CUSTOM.w  faza de palpaire (0 = fara palpaire)
//
// Mesh-ul e un patrat [-1,1]^2 in XY; shaderul il intoarce spre camera
// (billboard in spatiul vederii) si il dimensioneaza singur, deci instanta
// poarta doar pozitia (baza MultiMesh-ului e identitate).
//
// ORDINEA DE TAIERE din brief §6, scrisa aici ca sa nu depinda de disciplina:
// dincolo de `halo_far_begin`..`halo_far_end` (45..60 m) haloul se strange
// pana la miez, deci patratul insusi se micsoreaza — overdraw-ul scade odata
// cu el, nu doar alfa. Ramane punctul, cu o marime minima pe ecran
// (`min_core_rad`, radiani) ca sa nu cada sub un pixel si sa clipeasca.
//
// Ceata: `fog_disabled`, fiindca pe un material ADITIV ceata motorului ar
// amesteca patratul spre culoarea cetii si l-ar ADUNA — patrate gri in cer.
// Stingerea pe distanta se face aici (`fade_begin`..`fade_end`), sub fog_end
// de noapte (240 m).
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, fog_disabled,
	shadows_disabled, skip_vertex_transform;

global uniform float dusk_lamps;

uniform float halo_far_begin = 45.0;
uniform float halo_far_end = 60.0;
// Raza unghiulara minima a miezului: 0,0022 rad ~ 1,2 px la 720p / fov 68.
uniform float min_core_rad = 0.0022;
uniform float fade_begin = 120.0;
uniform float fade_end = 230.0;
// Intensitatea la dusk_lamps 0,15 (apus) si la 1,0 (noapte). Candelele si
// becurile de Diwali ard de la start, dar peste cerul de apus un halou plin
// spala fundalul, deci haloul (nu miezul) creste cu noaptea.
uniform float halo_gain_day = 0.45;
uniform float halo_gain_night = 1.0;
uniform float core_gain = 1.3;
// Cat se trage patratul spre camera (fractie din raza, plafonat in metri),
// ca haloul unei candele asezate pe o treapta sa nu fie taiat drept de
// treapta pe care sta (nu avem textura de adancime — ar fi o trecere in plus).
uniform float pull_frac = 0.8;
uniform float pull_max_m = 1.2;

varying vec2 v_local;      // pozitia in patrat, in metri (x, y)
varying float v_core;      // raza miezului (m), dupa marimea minima
varying float v_halo;      // raza haloului (m), dupa taiere
varying float v_stretch;
varying float v_fade;
varying vec4 v_color;

void vertex() {
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 cview = (VIEW_MATRIX * vec4(center, 1.0)).xyz;
	float dist = length(cview);
	float stretch = max(INSTANCE_CUSTOM.z, 1.0);
	float core = max(INSTANCE_CUSTOM.x, dist * min_core_rad);
	float keep = 1.0 - smoothstep(halo_far_begin, halo_far_end, dist);
	float halo = mix(core * stretch, max(INSTANCE_CUSTOM.y, core * stretch), keep);
	// palpaire: raza miezului respira putin (flacara), deloc pe becuri
	float ph = INSTANCE_CUSTOM.w;
	float flick = 1.0;
	if (ph > 0.0) {
		flick = 0.88 + 0.08 * sin(TIME * 11.0 + ph * 6.2831)
			+ 0.04 * sin(TIME * 23.0 + ph * 17.0);
	}
	core *= flick;
	float r = max(halo, core * stretch);
	v_local = VERTEX.xy * r;
	v_core = core;
	v_halo = halo;
	v_stretch = stretch;
	float pull = min(r * pull_frac, pull_max_m);
	vec3 dir = dist > 0.001 ? -cview / dist : vec3(0.0, 0.0, 1.0);
	VERTEX = cview + dir * min(pull, dist * 0.5) + vec3(v_local, 0.0);
	v_fade = (1.0 - smoothstep(fade_begin, fade_end, dist)) * flick;
	v_color = COLOR;
}

void fragment() {
	// miezul: disc (sau picatura alungita in sus) cu margine moale
	vec2 q = vec2(v_local.x, v_local.y / v_stretch);
	float dc = length(q) / max(v_core, 1e-4);
	float core_a = 1.0 - smoothstep(0.55, 1.0, dc);
	// haloul: cadere CONTINUA pana la zero pe margine (memoria
	// particule-muchia-nu-numarul: fara muchie de disc)
	float dh = length(v_local) / max(v_halo, 1e-4);
	float t = clamp(1.0 - dh, 0.0, 1.0);
	float halo_a = t * t * t;
	float night = smoothstep(0.15, 1.0, dusk_lamps);
	float hg = mix(halo_gain_day, halo_gain_night, night);
	vec3 col = v_color.rgb;
	// miezul se albeste spre centru: asa citeste „foc", nu „disc portocaliu"
	vec3 hot = mix(col, vec3(1.0, 0.84, 0.55), 0.4);
	vec3 c = hot * core_a * core_gain + col * halo_a * hg;
	ALBEDO = c * v_color.a * v_fade;
}
