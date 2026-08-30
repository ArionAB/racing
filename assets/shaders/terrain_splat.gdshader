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

// ATENUAREA CU DISTANTA a stratului de pete. Runda 6, cererea (4) a criticii:
// "dala de pete ocupa ~40% din imagine... nu se atenueaza cu distanta si e
// aceeasi pe nisip, pe drum si pe acostament. Se citeste ca un MATERIAL, nu ca
// un peisaj."
//
// De ce nu se rezolva singur din mipmap-uri: `micro` se repeta la ~2 m si
// contine granulatie de pixel (vezi `grain` din _detail_tuff/_write_tileable_n).
// Mipmap-ul mediaza patru texeli, dar la incidenta RAZANTA — si de la volan tot
// nisipul e razant — derivata pe axa vederii e mica, deci selectorul de mip
// ramane pe nivelele ascutite pana departe. Textura ramane la fel de
// contrastanta la 5 m si la 150 m, iar creierul citeste "suprafata plata
// texturata", nu "sol care se departeaza".
//
// Ce facem: dupa `near_m` interpolam fiecare trecere spre MEDIA ei (texturile
// sunt normalizate pe 0.850, style_bible §4), deci petele se sting spre culoarea
// curata a terenului fara sa mute expunerea cu nimic. La `far_m` a mai ramas
// `floor` din contrast — nu zero: o suprafata perfect neteda la distanta ar fi
// celalalt defect.
//
// Costa doi mix() si o lungime de vector. Zero materiale, zero texturi.
uniform float detail_near_m = 26.0;
uniform float detail_far_m = 130.0;
uniform float detail_floor = 0.28;
uniform float detail_mean = 0.850;

void fragment() {
	float w = COLOR.a;
	vec3 micro = mix(texture(sand_micro, UV).rgb,
			texture(grass_micro, UV).rgb, w);
	vec3 macro = mix(texture(sand_macro, UV2).rgb,
			texture(grass_macro, UV2).rgb, w);
	// VERTEX e in spatiul camerei (view), deci lungimea lui e chiar distanta
	// pana la fragment — fara matrici in plus.
	float d = length(VERTEX);
	float k = mix(1.0, detail_floor,
			clamp((d - detail_near_m) / max(detail_far_m - detail_near_m, 0.001),
			0.0, 1.0));
	micro = mix(vec3(detail_mean), micro, k);
	macro = mix(vec3(detail_mean), macro, k);
	ALBEDO = COLOR.rgb * micro * macro;
	// style_bible §4: nisip/iarba 0.95, fara specular — singurul sheen din
	// lume ramane al asfaltului.
	ROUGHNESS = 0.95;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
