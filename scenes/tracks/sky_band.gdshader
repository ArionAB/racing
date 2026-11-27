// Cerul procedural al temei + o BANDA DE ORIZONT pictata (randata in Blender).
//
// E `ProceduralSkyMaterial` rescris (aceleasi formule: gradient cer/sol, discul
// soarelui, `sky_cover` ADUNAT peste gradient), plus un singur strat in plus:
// o felie equirectangulara cu alfa, intre `band_lat_min` si `band_lat_max`, cu
// turnuri, mare si jonci la kilometri distanta. Banda e pe cer, deci la
// infinit: nu e geometrie, nu intra in frustum, nu o taie FAR_PLANE (380 m).
//
// Contractul cu randarea (`tools/blender/build_halong_sky_band.py`):
//   u = atan(x, -z) / TAU + 0.5   -> u = 0,5 spre -Z (nord), u = 0,75 spre +X;
//   v = 0 sus (band_lat_max), 1 jos (band_lat_min); pixeli patrati.
// Sub banda, marea departata continua cu `band_below_color` (marginea de jos a
// benzii e deja mare, deci trecerea nu se vede).
//
// Se citeste cu textureLod(0): banda e afisata aproape 1:1 (8192 px / 360 grade
// fata de ~27 px/grad pe ecran), iar mip-urile ar desena o cusatura de un pixel
// acolo unde u sare din 1 in 0.
shader_type sky;

uniform vec4 sky_top_color : source_color = vec4(0.385, 0.454, 0.55, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);
uniform float sky_curve : hint_range(0, 1) = 0.15;
uniform float sky_energy = 1.0;
uniform sampler2D sky_cover : source_color, hint_default_black;
uniform vec4 sky_cover_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 ground_bottom_color : source_color = vec4(0.2, 0.169, 0.133, 1.0);
uniform vec4 ground_horizon_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);
uniform float ground_curve : hint_range(0, 1) = 0.02;
uniform float sun_angle_max = 0.523599; // 30 grade
uniform float sun_curve : hint_range(0, 1) = 0.15;

uniform sampler2D band : source_color, filter_linear, repeat_enable, hint_default_transparent;
uniform float band_lat_min = -0.1309; // -7,5 grade
uniform float band_lat_max = 0.2618;  //  15 grade
uniform float band_yaw = 0.0;         // rotatie a benzii, in ture (0..1)
uniform vec4 band_below_color : source_color = vec4(0.25, 0.6, 0.57, 1.0);
// NOAPTEA (opt-in; doar Jodhpur, unde `DuskCycle` duce cursa din apus in
// noapte): aceeasi felie randata a doua oara, la lumina de noapte (ferestre
// aprinse, aer indigo), amestecata peste cea de zi cu `band_night_mix` (0 = zi).
// La 0 ramura nu ruleaza: celelalte piste raman bit cu bit cum erau.
uniform sampler2D band_night : source_color, filter_linear, repeat_enable, hint_default_transparent;
uniform float band_night_mix : hint_range(0, 1) = 0.0;
uniform vec4 band_below_night : source_color = vec4(0.1, 0.1, 0.12, 1.0);

void sky() {
	float v_angle = acos(clamp(EYEDIR.y, -1.0, 1.0));
	float c = (1.0 - v_angle / (PI * 0.5));
	vec3 sky = mix(sky_horizon_color.rgb, sky_top_color.rgb,
		clamp(1.0 - pow(1.0 - c, 1.0 / sky_curve), 0.0, 1.0));
	sky *= sky_energy;

	if (LIGHT0_ENABLED) {
		float sun_angle = acos(dot(LIGHT0_DIRECTION, EYEDIR));
		if (sun_angle < LIGHT0_SIZE) {
			sky = LIGHT0_COLOR * LIGHT0_ENERGY;
		} else if (sun_angle < sun_angle_max) {
			float c2 = (sun_angle - LIGHT0_SIZE) / (sun_angle_max - LIGHT0_SIZE);
			sky = mix(LIGHT0_COLOR * LIGHT0_ENERGY, sky,
				clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
		}
	}

	vec4 cover = texture(sky_cover, SKY_COORDS);
	sky += (cover.rgb * sky_cover_modulate.rgb) * cover.a * sky_cover_modulate.a;

	c = (v_angle - (PI * 0.5)) / (PI * 0.5);
	vec3 ground = mix(ground_horizon_color.rgb, ground_bottom_color.rgb,
		clamp(1.0 - pow(1.0 - c, 1.0 / ground_curve), 0.0, 1.0));

	vec3 col = mix(ground, sky, step(0.0, EYEDIR.y));

	float lat = asin(clamp(EYEDIR.y, -1.0, 1.0));
	if (lat < band_lat_min) {
		col = band_below_color.rgb;
		if (band_night_mix > 0.0) {
			col = mix(col, band_below_night.rgb, band_night_mix);
		}
	} else if (lat <= band_lat_max) {
		float u = fract(atan(EYEDIR.x, -EYEDIR.z) / TAU + 0.5 + band_yaw);
		float v_raw = (band_lat_max - lat) / (band_lat_max - band_lat_min);
		// `repeat_enable` e pentru cusatura de pe azimut (u), dar se aplica si pe
		// v: in ultimul jumatate de pixel filtrul amesteca randul de jos cu cel de
		// SUS (cer transparent) -> o linie punctata pe mare la -7,5 grade
		// (vazuta pe Stromboli, de pe buza craterului). Pe v se strange la centrul
		// primului / ultimului rand.
		float half_px = 0.5 / float(textureSize(band, 0).y);
		float v = clamp(v_raw, half_px, 1.0 - half_px);
		vec4 b = textureLod(band, vec2(u, v), 0.0);
		if (band_night_mix > 0.0) {
			float half_n = 0.5 / float(textureSize(band_night, 0).y);
			vec4 bn = textureLod(band_night, vec2(u, clamp(v_raw, half_n, 1.0 - half_n)), 0.0);
			b = mix(b, bn, band_night_mix);
		}
		col = mix(col, b.rgb, b.a);
	}
	COLOR = col;
}
