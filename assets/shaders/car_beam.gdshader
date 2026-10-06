// FASCICULUL FALS al farurilor: un con deschis, ADITIV, din far spre inainte
// (vezi scenes/cars/car_lights.gd). Nu lumineaza nimic — doar „aerul" din fata
// masinii; lumina pe asfalt o da decalul de sub el.
//
// Mesh-ul poarta in UV.y distanta relativa pe con (0 la far, 1 la capat).
// Intensitatea scade continuu pe lungime (memoria particule-muchia-nu-numarul:
// fara capat taiat drept) si spre marginile siluetei (fata vazuta pe muchie =
// putin aer traversat), deci conul nu are contur.
//
// Ceata: `fog_disabled`, ca la `lamp_halo` — pe un material aditiv ceata
// motorului ar ADUNA culoarea cetii. Stingerea pe distanta e aici.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, fog_disabled,
	shadows_disabled;

instance uniform float beam_level = 0.0;

uniform vec3 beam_color = vec3(1.0, 0.86, 0.6);
uniform float beam_gain = 0.22;
uniform float fade_begin = 60.0;
uniform float fade_end = 110.0;

varying float v_along;
varying float v_fade;

void vertex() {
	v_along = UV.y;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist = length(world - CAMERA_POSITION_WORLD);
	v_fade = 1.0 - smoothstep(fade_begin, fade_end, dist);
}

void fragment() {
	float along = 1.0 - v_along;
	float length_fall = along * along;
	// pornire moale si la far: un con care incepe cu intensitate plina ar
	// arata un disc luminos lipit de bara
	length_fall *= smoothstep(0.0, 0.08, v_along);
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float edge = facing * facing;
	ALBEDO = beam_color * beam_gain * beam_level * length_fall * edge * v_fade;
}
