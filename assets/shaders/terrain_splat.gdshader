// Terenul cu doua perechi de texturi (nisip si iarba), amestecate per-vertex.
//
// Exista fiindca StandardMaterial3D poate cara O SINGURA pereche micro+macro,
// iar terenul are de la #206 doua materiale de suprafata: plaja (nisip) si
// campul (iarba). Greutatea amestecului vine prin COLOR.a — builder-ul o
// calcula deja pentru tenta de culoare (lerp-ul spre inland_tint) si o arunca.
// Alternativa cinstita era taierea mesh-ului in doua suprafete, dar la celula
// de 7.9 m cusatura ar fi iesit o linie de nivel in trepte — exact conturul
// pe care banda lata de trecere (BEACH_FADE) exista ca sa-l ascunda.
//
// Matematica e identica cu StandardMaterial3D-ul de dinainte (albedo din
// vertex color x micro pe UV1 x macro pe UV2, BLEND_MODE_MUL), doar ca
// fiecare trecere alege intre doua texturi. Texturile sunt gri cu media
// 0.850 (style_bible §4), deci expunerea nu se misca indiferent de amestec.
// Cost: 4 sample-uri de textura comprimata in loc de 2 — ieftin si pe mobil;
// fill rate-ul nu se schimba (aceiasi pixeli, acelasi overdraw zero).
shader_type spatial;
render_mode cull_back;

uniform sampler2D sand_micro : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_macro : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_micro : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_macro : source_color, filter_linear_mipmap, repeat_enable;

// Cat de departe se stinge complet granulatia (metri). Peste distanta asta
// terenul ramane pe culoarea lui plata.
uniform float detail_fade_start = 40.0;
uniform float detail_fade_end = 190.0;

void fragment() {
	float w = COLOR.a;
	vec3 micro = mix(texture(sand_micro, UV).rgb,
			texture(grass_micro, UV).rgb, w);
	vec3 macro = mix(texture(sand_macro, UV2).rgb,
			texture(grass_macro, UV2).rgb, w);
	// STINGEREA CU DISTANTA. Mipmap-urile netezesc textura, dar nu-i scad
	// CONTRASTUL: la 200 m granulatia ramane la fel de tare ca sub roata, si
	// asta a fost numit, orbeste, unul din cele doua semne cele mai tari ca
	// imaginea e decor de joc. Masurat pe cadrul judecat inainte: deviatie de
	// luminanta 14.1 aproape si 16.4 departe — adica zero atenuare.
	//
	// Pe o suprafata reala, granulatia se pierde in perspectiva pana ramane
	// doar valoarea medie. Aici straturile se duc spre 1.0 (identitatea
	// inmultirii), deci departe ramane exact culoarea de baza, fara sa se
	// schimbe expunerea: texturile au media 0.85, iar mixul catre alb
	// compenseaza chiar pierderea aia.
	float d = length(VERTEX);
	float fade = smoothstep(detail_fade_start, detail_fade_end, d);
	micro = mix(micro, vec3(1.0), fade);
	macro = mix(macro, vec3(1.0), fade);
	ALBEDO = COLOR.rgb * micro * macro;
	// style_bible §4: nisip/iarba 0.95, fara specular — singurul sheen din
	// lume ramane al asfaltului.
	ROUGHNESS = 0.95;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
