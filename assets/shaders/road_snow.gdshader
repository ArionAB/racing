shader_type spatial;
// Soseaua de ZAPADA cu masca de uzura (RoadWear).
//
// Replica exact materialul standard pe care il inlocuieste (_flat_material:
// albedo_color x textura micro pe UV1 x macro pe UV2 x culoarea de vertex,
// mat, cull_back) si adauga O singura citire in plus: masca de uzura din
// spatiul benzii, care inchide si albastreste zapada pe unde s-a circulat.
// Parametrii vin din Track._build_road — aceleasi valori care intrau in
// materialul standard, deci orice recalibrare a soselei ramane intr-un loc.
render_mode cull_back;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D micro_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D macro_tex : source_color, filter_linear_mipmap, repeat_enable;
// Masca de uzura (SubViewport-ul RoadWear): alfa = cat s-a circulat aici.
uniform sampler2D wear_tex : filter_linear, repeat_enable;
// Dimensiunile benzii, in metri — ACELEASI cu care RoadWear::stamp scrie in
// masca; daca diverg, petele cad alaturi de locul pe unde a trecut roata.
uniform float lane_len = 1600.0;
uniform float lane_span = 24.0;
// UV-ul soselei e in DALE (Track._build_road imparte metrii la `tile`);
// inmultirea cu el intoarce metrii adevarati.
uniform float road_tile = 3.5;
// Nuanta zapezii presate, ca multiplicator la uzura plina: inchide rosul mai
// tare decat albastrul — fagasul compact tine umbra cerului (aceeasi judecata
// ca Track.trail_mark_color, cu care trebuie sa ramana in familie).
uniform vec3 wear_tint = vec3(0.60, 0.69, 0.86);

void fragment() {
	vec3 albedo = base_color.rgb * COLOR.rgb;
	albedo *= texture(micro_tex, UV).rgb;
	albedo *= texture(macro_tex, UV2).rgb;
	vec2 lane = vec2(
		clamp(UV.x * road_tile / lane_span + 0.5, 0.0, 1.0),
		fract(UV.y * road_tile / lane_len));
	float wear = texture(wear_tex, lane).a;
	albedo = mix(albedo, albedo * wear_tint, clamp(wear, 0.0, 1.0));
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
