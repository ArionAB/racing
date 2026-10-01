// FERESTRELE SI NISELE APRINSE (Jodhpur: `*_Glow` pe case, porti, fort, turn,
// fatade, orizont). Pana acum erau pe atlas (slotul 20, gri-negru), nelegate
// de ceas: la dusk 1 orasul nu avea nicio fereastra aprinsa.
//
// Se aprind cu parametrul GLOBAL `dusk_lamps` (DuskCycle: 0,15 la start ->
// 0,6 la dusk 0,5 -> 1,0 la noapte), nu cu un export: un singur canal pentru
// toata pista, fara nicio referinta la nod (antetul dusk_lamp_probe.gdshader).
//
// PRAGURI (motivate in jodhpur_masuratori.md §9): brief-ul cere „turul 1 soare
// jos, turul 2 se aprind lampile". Turul 2 e dusk 0,33..0,67, adica
// dusk_lamps ~0,45..0,73. Fiecare CLADIRE isi are propriul prag, tras dintr-un
// hash pe pozitia ei, in [on_from, on_from + on_spread]; tranzitia unei case
// dureaza `on_width`. Asa orasul se aprinde casa cu casa pe tot turul 2, nu
// deodata ca un intrerupator. `off_ratio` din case raman stinse si noaptea
// (un oras cu TOATE ferestrele aprinse citeste a decor de carton).
//
// Albedo-ul ramane cel din atlas (acelasi UV colapsat pe slot, acelasi AO din
// vertex color), deci ziua fereastra e golul intunecat de pana acum.
//
// UN material pentru toate ferestrele pistei: garda numara +1.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

global uniform float dusk_lamps;

uniform sampler2D albedo_atlas : source_color, filter_linear_mipmap;
uniform vec3 glow_color : source_color = vec3(1.0, 0.62, 0.28);
uniform float energy = 1.6;
uniform float on_from = 0.40;
uniform float on_spread = 0.30;
uniform float on_width = 0.08;
uniform float off_ratio = 0.12;

varying float v_on;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	// pozitia OBIECTULUI (pe MultiMesh: a instantei), rotunjita pe 1 m ca
	// hash-ul sa nu tremure cu erorile de virgula mobila
	vec3 o = floor(MODEL_MATRIX[3].xyz + 0.5);
	float h = hash13(o);
	float h2 = hash13(o + vec3(17.0, 3.0, 41.0));
	float t0 = on_from + h * on_spread;
	float on = smoothstep(t0, t0 + on_width, dusk_lamps);
	on *= step(off_ratio, h2);
	// intensitatea variaza intre case (0,65..1,15): lampi diferite in camere
	v_on = on * mix(0.65, 1.15, fract(h2 * 7.13));
}

void fragment() {
	vec4 a = texture(albedo_atlas, UV);
	ALBEDO = a.rgb * COLOR.rgb;
	ROUGHNESS = 0.9;
	SPECULAR = 0.15;
	EMISSION = glow_color * energy * v_on;
}
