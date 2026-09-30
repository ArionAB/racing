// FUMUL TUNURILOR DE SALUT (Jodhpur, POI F): un MultiMesh de patrate billboard,
// AMESTECATE (nu aditive: fumul alb peste cerul de apus trebuie sa acopere,
// nu sa straluceasca). Pe tiparul `lamp_halo.gdshader`: patratul [-1,1]^2 in XY
// e intors spre camera in spatiul vederii si dimensionat per instanta.
//
// Per instanta (MultiMesh):
//   COLOR              culoarea fumului (rgb) si opacitatea (a)
//   INSTANCE_CUSTOM.x  raza pufului (m)
//
// Marginea: cadere CONTINUA pana la zero (memoria particule-muchia-nu-numarul),
// plus o variatie de densitate din unghi, ca pufurile sa nu citeasca discuri.
// Fara umbre (memoria caster-departat-fura-umbra), fara scriere in adancime.
shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_disabled,
	shadows_disabled, skip_vertex_transform;

varying vec2 v_q;
varying vec4 v_color;
varying float v_seed;

void vertex() {
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 cview = (VIEW_MATRIX * vec4(center, 1.0)).xyz;
	float r = max(INSTANCE_CUSTOM.x, 0.01);
	v_q = VERTEX.xy;
	v_seed = fract(center.x * 0.37 + center.z * 0.71);
	VERTEX = cview + vec3(VERTEX.xy * r, 0.0);
	v_color = COLOR;
}

void fragment() {
	float d = length(v_q);
	float ang = atan(v_q.y, v_q.x);
	// buza neregulata: raza efectiva variaza cu unghiul (+-12 %)
	float edge = 1.0 + 0.12 * sin(ang * 5.0 + v_seed * 20.0)
		+ 0.06 * sin(ang * 9.0 - v_seed * 13.0);
	float t = clamp(1.0 - d / edge, 0.0, 1.0);
	float a = t * t * (3.0 - 2.0 * t);
	// miezul putin mai dens si mai inchis (volum), marginea mai deschisa
	vec3 c = v_color.rgb * mix(1.04, 0.86, t);
	ALBEDO = c;
	ALPHA = a * v_color.a;
}
