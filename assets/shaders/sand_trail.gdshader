shader_type spatial;
// Brazda lasata de o roata pe teren afanat.
//
// Trei lucruri pe care un StandardMaterial3D nu le poate face impreuna, si de
// aceea exista shaderul asta:
//
//  1. MODEL DE ANVELOPA care nu se spala la distanta. Textura isi tine desenul
//     in alfa, iar alfa trece prin mipmap ca orice canal: la zece metri in urma
//     masinii GPU-ul citeste un mip mic, adica MEDIA. Vechea decal_tracks.png
//     avea medie 0.107 fata de varf 0.537 (raport 0.20) — de-aia disparea.
//     tire_tread.png e autorata cu alfa cvasi-binara (raport 0.31) SI, in plus,
//     amestecul spre banda neteda se face aici, controlat, dupa distanta: la
//     departare ramane o brazda curata, nu un gri spalacit.
//  2. SECTIUNE DE BAZIN. Adancimea se citeste din umbrire: mijlocul fagasului e
//     cel mai inchis, si se ridica lin spre marginile nederanjate. Fara buza
//     ridicata — asa cere referinta (DEPTH REFERENCE, 1.5-3 cm, profil lin).
//  3. STINGERE PER INSTANTA (NEW -> FADED). Varsta vine din INSTANCE_CUSTOM.r,
//     scris de SandTrail cand depune placuta.
//
// Nelit, ca restul straturilor de sol: pe o suprafata luminata culoarea scrisa
// nu mai e culoarea de pe ecran, iar contrastul brazdei — chiar rostul
// efectului — s-ar spala in ambianta.
render_mode unshaded, blend_mix, depth_draw_never, cull_back;

uniform sampler2D tread_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 core_color : source_color = vec3(0.35, 0.28, 0.18);
uniform float core_alpha : hint_range(0.0, 1.0) = 0.58;
// Cat de adanc se citeste mijlocul fata de margini. Bazinul, nu buza.
uniform float basin : hint_range(0.0, 1.0) = 0.45;
// Cat de tare se vede modelul de anvelopa peste brazda neteda.
uniform float tread_amount : hint_range(0.0, 1.0) = 0.65;
// De la ce distanta (m) modelul incepe sa se topeasca in brazda neteda.
uniform float tread_fade_start = 14.0;
uniform float tread_fade_end = 34.0;
// Ceasul cursei (secunde), impins de SandTrail o data pe cadru. Varsta unei
// placute = now - momentul depunerii (INSTANCE_CUSTOM.r).
uniform float now = 0.0;
uniform float fade_seconds = 26.0;

varying float v_age;

void vertex() {
	// INSTANCE_CUSTOM.r = CAND a fost depusa placuta, in secunde. Varsta
	// normalizata iese din diferenta fata de ceasul curent — asa nu trebuie
	// rescrise instantele in fiecare cadru.
	v_age = clamp((now - INSTANCE_CUSTOM.r) / fade_seconds, 0.0, 1.0);
}

void fragment() {
	// UV.x traverseaza latimea placutei, UV.y merge pe lungimea ei.
	float across = UV.x * 2.0 - 1.0;           // -1 la +1 pe latime
	// Bazin: plin in mijloc, stins spre margini. Fara umar, fara buza.
	// Bazinul modeleaza opacitatea, dar nu o duce la zero pe margini: fagasul
	// se subtiaza spre buza nederanjata, nu dispare. Fara podeaua asta,
	// produsul bazin x model x varsta taia 0.58 la ~0.15 si urma nu se vedea.
	float basin_mask = 1.0 - across * across;
	basin_mask = mix(0.45, 1.0, clamp(basin_mask, 0.0, 1.0));

	// Modelul de anvelopa se topeste cu distanta: de aproape se vad blocurile,
	// de departe ramane brazda. Altfel mipmap-ul face din el o pasta gri.
	float dist = length(VERTEX);
	float near = 1.0 - smoothstep(tread_fade_start, tread_fade_end, dist);
	float tread = texture(tread_tex, vec2(UV.x, UV.y)).a;
	// La fel pentru model: blocurile sunt mai OPACE decat canalele dintre ele,
	// dar canalul tot e sant, nu nisip curat.
	float tread_lift = mix(0.35, 1.0, tread);
	float pattern = mix(1.0, tread_lift, tread_amount * near);

	// Adancimea vine din umbrire: mijlocul bazinului mai inchis decat marginea.
	float depth = mix(1.0 - basin, 1.0, basin_mask);
	ALBEDO = core_color * depth;

	// Stingerea cu varsta: urma proaspata e plina, cea veche abia se ghiceste.
	float age = 1.0 - smoothstep(0.55, 1.0, v_age);
	// Fara COLOR: intr-un MultiMesh, COLOR vine din culoarea PER INSTANTA, iar
	// noi am pornit doar `use_custom_data`, nu si `use_colors` — deci ar fi
	// zero si ar stinge tot. (Asta a facut urmele sa dispara complet o data.)
	ALPHA = core_alpha * basin_mask * pattern * age;
}
