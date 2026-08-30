shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// ATENUAREA CU DISTANTA a stratului de pete PE PROP-URI.
//
// Runda 6 a stins pestritul pe carosabil (road_detail_fade) si pe teren
// (terrain_splat), dar prop-urile au ramas pe StandardMaterial3D. Runda 7,
// amandoi criticii, cuvant cu cuvant: pe hornuri petele au "aceeasi marime si
// acelasi contrast de la 3 m la 90 m". Se vede direct in captura: conul de la
// marginea cadrului si cel de la 90 m poarta aceleasi caneluri, la fel de
// contrastante.
//
// De ce nu se putea repara in StandardMaterial3D: `distance_fade` de acolo
// stinge OBIECTUL intreg (alfa), nu un strat. Iar mipmap-urile nu ajung — la
// incidenta razanta selectorul de mip ramane pe nivelele ascutite (vezi nota
// lunga din terrain_splat.gdshader).
//
// Shaderul reproduce EXACT ce facea materialul comun — atlas pe UV1, vertex
// color ca AO, detaliu triplanar inmultit prin masca de slot — si adauga
// stingerea spre 1.0 (identitatea inmultirii) intre near_m si far_m.
//
// MATERIALE: nu cresc. Inlocuieste materialul pe care prop-ul l-ar fi avut
// oricum, exact tiparul din road_detail_fade. Verificat cu probe_decor.

uniform sampler2D albedo_atlas : source_color, filter_linear_mipmap;
uniform sampler2D detail_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_mask_tex : source_color, filter_linear_mipmap;
uniform float detail_scale = 0.35;
uniform float detail_near_m = 26.0;
uniform float detail_far_m = 130.0;
uniform float detail_floor = 0.28;
// Texturile de detaliu sunt normalizate pe media asta (style_bible §4), deci
// mixul catre ea stinge tiparul FARA sa mute expunerea.
uniform float detail_mean = 0.850;
uniform float roughness_v = 0.9;
uniform float specular_v = 0.15;

varying vec3 v_obj_pos;
varying vec3 v_obj_nrm;

void vertex() {
	// Triplanarul lui StandardMaterial3D (uv2_triplanar) calculeaza coordonatele
	// din VERTEX si NORMAL in spatiul obiectului, si nu citeste niciodata
	// atributul UV2 — vezi nota din Palette.world_material.
	v_obj_pos = VERTEX * detail_scale;
	v_obj_nrm = abs(NORMAL);
}

void fragment() {
	vec4 base = texture(albedo_atlas, UV);
	// Masca se citeste pe UV1, adica pe centrul slotului: slotul din paleta e
	// si canal de intensitate (roca primeste tot, masinile nimic).
	float mask = texture(detail_mask_tex, UV).a;

	// Proiectie triplanara: ponderi din normala, normalizate.
	vec3 w = v_obj_nrm;
	w = w / max(w.x + w.y + w.z, 0.0001);
	// AXELE CONTEAZA. detail_tuff.png are canelurile pe VERTICALA (tuful se
	// erodeaza prin siroire, santurile coboara cu apa — vezi cheia
	// `detail_texture` a temei si commit-ul 04d2ac8). Pe fetele aproape
	// verticale ale unui horn proiectiile laterale trebuie sa pastreze Y-ul
	// obiectului pe axa V a texturii; cu perechile inversate canelurile ies
	// ORIZONTALE, adica exact defectul reparat atunci.
	vec3 det = texture(detail_tex, v_obj_pos.zy).rgb * w.x
		+ texture(detail_tex, v_obj_pos.xz).rgb * w.y
		+ texture(detail_tex, v_obj_pos.xy).rgb * w.z;

	// VERTEX e in spatiul camerei, deci lungimea lui e chiar distanta.
	float d = length(VERTEX);
	float k = mix(1.0, detail_floor,
			clamp((d - detail_near_m) / max(detail_far_m - detail_near_m, 0.001),
			0.0, 1.0));
	det = mix(vec3(detail_mean), det, k);
	// Masca de slot decide CAT din stratul de detaliu se aplica; unde e 0,
	// rezultatul e 1.0 (identitatea inmultirii), adica material curat.
	det = mix(vec3(1.0), det, mask);

	ALBEDO = base.rgb * COLOR.rgb * det;
	ROUGHNESS = roughness_v;
	SPECULAR = specular_v;
	METALLIC = 0.0;
}
