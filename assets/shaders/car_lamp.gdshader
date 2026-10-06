// LENTILA unei lampi de masina (stop sau far) — nodurile `*_Lamp_Tail` /
// `*_Lamp_Head` din GLB-urile garajului, vezi scenes/cars/car_lights.gd.
//
// UN SINGUR material pentru toate lampile tuturor masinilor (garda numara
// materiale): ce difera intre stop si far, si intre masini, vine PER INSTANTA
// (`instance uniform`), deci franarea unei masini nu atinge materialul altora
// si nu sparge nimic in randare.
//
// Stinsa, lentila e o culoare de baza mata (rosu inchis / alb mat), luminata
// normal de soare. Aprinsa, emisia se ADUNA peste: pe noapte citeste „bec",
// iar pe zi stopul franat iese din caroserie prin saturatie, nu prin bloom
// (Jodhpur a decis: fara glow in Environment). Haloul il da `lamp_halo`.
shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

instance uniform vec3 base_color = vec3(0.45, 0.05, 0.04);
instance uniform vec3 glow_color = vec3(1.0, 0.12, 0.06);
instance uniform float lamp_level = 0.0;

uniform float emission_energy = 3.0;

void fragment() {
	ALBEDO = base_color;
	ROUGHNESS = 0.35;
	EMISSION = glow_color * lamp_level * emission_energy;
}
