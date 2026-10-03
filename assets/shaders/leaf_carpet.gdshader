shader_type spatial;
// COVORUL DE FRUNZE de pe drum (Kyoto, POI D si E; brief kyoto.md §3 "Covorul
// de frunze"). Un panou transparent pus la 4 cm peste asfalt, cu frunzele
// desenate din CLASA de textura `leaf_litter` (autumn_foliage.png, aceeasi dala
// ca pe teren: niciun fisier de textura nou) si "curatate" de masini.
//
// RoadWear FOLOSIT INVERS: foaia de uzura (SubViewport, alfa = cat s-a circulat)
// nu mai inchide zapada, ci SCOATE frunzele: alfa_frunza *= (1 - uzura). Roata
// care trece lasa o dara de asfalt gol prin rosu; dupa cateva tururi se vede
// linia de cursa a plutonului.
//
// Doar VIZUAL: grip-ul nu citeste nimic de aici (decizia dezvoltatorului,
// brief §3.1 pct. 3).
//
// Mesh-ul (LeafCarpet) da prin vertex color: R = acoperirea zonei (densitate x
// topirea la capete), G = |pozitia laterala| / semilatime (0 pe ax, 1 la
// margine). UV = (metri laterali de la ax, metri in spatiul foii de uzura).
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
// Foaia de uzura (RoadWear): alfa = uzura.
uniform sampler2D wear_tex : filter_linear, repeat_disable;
// Dimensiunile foii, in metri: ACELEASI cu RoadWear.setup, altfel dara cade
// alaturi de roata.
uniform float lane_len = 600.0;
uniform float lane_span = 14.0;
// Cate repetitii ale dalei pe metru (CLASS_TRIPLANAR_SCALE["leaf_litter"]).
uniform float tex_scale = 0.25;
// Cele trei tente de frunza (carmin, portocaliu, ruginiu — clasele paletei).
uniform vec3 col_a : source_color = vec3(0.89, 0.30, 0.20);
uniform vec3 col_b : source_color = vec3(1.0, 0.36, 0.25);
uniform vec3 col_c : source_color = vec3(0.66, 0.41, 0.23);
// Acoperirea pe AX (0..1) fata de margine (1.0): frunzele se aduna la margini,
// pe ax masinile le-au batut deja inainte de cursa.
uniform float center_cover = 0.55;

varying vec2 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = wpos * tex_scale;
	float lum = texture(leaf_tex, p).r;
	// Zgomot de frecventa joasa din aceeasi dala (decorelat prin rotire/offset):
	// alege tenta si ciucureste frunzele in palcuri.
	float low = texture(leaf_tex, p * 0.11 + vec2(0.37, 0.71)).r;
	float edge = smoothstep(0.30, 0.95, COLOR.g);
	float dens = clamp(COLOR.r * mix(center_cover, 1.0, edge), 0.0, 1.0);
	// Prag pe luminanta dalei: dala are goluri intunecate (p5 = 0.42) si frunze
	// luminoase (p50 = 0.80). dens 1 -> aproape tot e frunza; dens 0.5 -> doar
	// jumatatea cea mai luminoasa.
	float clump = (low - 0.8) * 0.35;
	float thr = mix(0.97, 0.15, dens) - clump;
	float leaf = smoothstep(thr - 0.07, thr + 0.07, lum);
	leaf *= smoothstep(0.02, 0.12, dens);
	// Uzura: foaia e in spatiul benzii; UV.x = metri laterali, UV.y = metri.
	vec2 lane = vec2(UV.x / lane_span + 0.5, UV.y / lane_len);
	float wear = texture(wear_tex, lane).a;
	float swept = 1.0 - smoothstep(0.04, 0.70, wear);
	float a = leaf * swept * 0.94;
	// Tenta: carmin -> portocaliu -> ruginiu dupa zgomotul de joasa frecventa.
	float k = clamp((low - 0.55) / 0.45, 0.0, 1.0);
	vec3 tint = mix(col_a, col_b, smoothstep(0.0, 0.45, k));
	tint = mix(tint, col_c, smoothstep(0.45, 1.0, k));
	ALBEDO = tint * (0.45 + 0.65 * lum);
	ALPHA = a;
	ROUGHNESS = 1.0;
}
