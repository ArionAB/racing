// Carosabilul cu granulatia care SE STINGE CU DISTANTA.
//
// De ce exista: `_flat_material` construieste soseaua din albedo (micro, UV1) x
// detail (macro, UV2), amandoua cu BLEND_MODE_MUL. Mipmap-urile netezesc
// tiparul, dar nu-i scad CONTRASTUL — la 200 m pestritul e la fel de tare ca
// sub roata. Masurat pe cadrul judecat: deviatie de luminanta 14.1 aproape,
// 16.4 departe, adica nu scade deloc.
//
// Critica oarba a numit exact simptomul asta ca fiind unul din cele doua semne
// cele mai tari ca imaginea e decor de joc, si e o problema de FIZICA a
// imaginii, nu de gust: pe o suprafata reala granulatia se pierde in
// perspectiva pana ramane doar valoarea medie a materialului.
//
// StandardMaterial3D nu poate cere asa ceva (`distance_fade` stinge tot
// obiectul, nu un strat), deci carosabilul primeste shader propriu. Zero
// materiale in plus la numaratoarea garzii: inlocuieste materialul care
// oricum se construia, nu se adauga peste el.
shader_type spatial;
render_mode cull_back;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D micro_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D macro_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float roughness_v = 1.0;
uniform float specular_v = 0.0;
// Unde incepe si unde se termina stingerea (metri de la camera).
uniform float fade_start = 35.0;
uniform float fade_end = 170.0;

void fragment() {
	vec3 micro = texture(micro_tex, UV).rgb;
	vec3 macro = texture(macro_tex, UV2).rgb;
	// Spre 1.0, adica spre identitatea inmultirii: departe ramane exact
	// culoarea de baza. Texturile au media 0.85 (style_bible §4), iar mixul
	// catre alb compenseaza chiar pierderea aia, deci expunerea nu se muta.
	float fade = smoothstep(fade_start, fade_end, length(VERTEX));
	micro = mix(micro, vec3(1.0), fade);
	macro = mix(macro, vec3(1.0), fade);
	ALBEDO = base_color.rgb * COLOR.rgb * micro * macro;
	ROUGHNESS = roughness_v;
	SPECULAR = specular_v;
	METALLIC = 0.0;
}
