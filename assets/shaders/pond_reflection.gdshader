shader_type spatial;
// REFLEXIA UNUI OBIECT INTR-O APA PLANA SI OPACA (Kyoto, Pavilionul de Aur pe
// iaz; brief §3 / §3.1 decizia 4: +1 material aprobat).
//
// De ce nu copia oglindita SUB apa (designul din tools/probe_kyoto_reflexie.gd):
// apa v12 e opaca, deci copia de sub ea cere o gaura in iaz, o albie la -16 m si
// o panza transparenta; pe pista reala mai cere si o gaura in TEREN (fundul
// iazului e la -3, copia unui pavilion de 14 m coboara pana la -15). Asta ar fi
// fost o schimbare de teren.
//
// Ce face shaderul in schimb: fiecare varf al modelului e OGLINDIT fata de
// planul apei si apoi PROIECTAT, pe raza camerei, inapoi pe plan (cu `lift`
// deasupra valurilor). Din camera, imaginea e exact cea a copiei oglindite (aceeasi
// raza), dar geometria sta PE apa: se testeaza normal in adancime cu tot ce e in
// fata ei (malul, masinile, tufele), fara depth texture, fara stencil, fara
// transparenta si fara gaura. Proiectia centrala pe un plan pastreaza liniile
// drepte, deci triunghiurile raman triunghiuri.
//
// Toate fetele ajung pe acelasi plan, deci ordinea dintre ele (ce fata a copiei
// e in fata) se scrie separat: varful a carui copie e mai APROAPE de camera e
// tras cu pana la `depth_sort_m` spre camera, pe aceeasi raza (pozitia pe ecran
// nu se schimba, doar adancimea).
render_mode unshaded, cull_disabled, world_vertex_coords, depth_draw_opaque, shadows_disabled;

uniform sampler2D albedo_atlas : source_color, filter_linear_mipmap;
// Cota apei (m, lume) si cat sta imaginea deasupra ei (> amplitudinea valurilor).
uniform float water_y = -1.0;
uniform float lift = 0.16;
// Ordinea fetelor: tragerea maxima spre camera si raza obiectului.
uniform float depth_sort_m = 0.35;
uniform float sort_radius_m = 12.0;
// Culoarea apei (liniar, aceeasi ca `deep_col` din materialul iazului) si cat
// din culoarea obiectului trece in reflexie.
uniform vec3 water_col = vec3(0.05, 0.12, 0.15);
uniform float strength : hint_range(0.0, 1.0) = 0.6;
uniform float gain : hint_range(0.0, 2.0) = 0.9;
// Reflexia se stinge spre varful copiei (adancime mare = departe de mal).
uniform float fade_depth_m = 18.0;

varying float v_depth;

void vertex() {
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 m = vec3(VERTEX.x, 2.0 * water_y - VERTEX.y, VERTEX.z);
	v_depth = max(water_y - m.y, 0.0);
	float plane = water_y + lift;
	vec3 d = m - cam;
	float t = (plane - cam.y) / min(d.y, -1e-4);
	vec3 p = cam + d * clamp(t, 0.0, 1.0);
	vec3 c = MODEL_MATRIX[3].xyz;
	c.y = 2.0 * water_y - c.y;
	float rel = clamp((length(d) - length(c - cam)) / sort_radius_m, -1.0, 1.0);
	float pull = depth_sort_m * 0.5 * (1.0 - rel);
	float lp = max(length(p - cam), 1.0);
	VERTEX = cam + (p - cam) * (1.0 - pull / lp);
}

void fragment() {
	vec3 a = texture(albedo_atlas, UV).rgb * COLOR.rgb;
	float k = strength * clamp(1.0 - v_depth / fade_depth_m, 0.25, 1.0);
	ALBEDO = mix(water_col, a * gain, k);
}
