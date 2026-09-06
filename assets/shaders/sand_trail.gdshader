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
// De cate ori se repeta modelul pe lungimea placutei.
uniform float tread_repeats = 3.0;
uniform float tread_fade_start = 22.0;
uniform float tread_fade_end = 55.0;
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
	// BAZINUL. `across` merge de la -1 (marginea stanga) la +1 (dreapta), deci
	// `1 - across^2` e 1 pe mijloc si 0 pe margini — adica exact adancimea
	// santului, normalizata.
	float dip = clamp(1.0 - across * across, 0.0, 1.0);
	// Muchie moale, nu abrupta: "soft sloped edges" din ghid. smoothstep pe
	// adancime taluzeaza malurile.
	dip = smoothstep(0.0, 1.0, dip);

	// Modelul de anvelopa se topeste cu distanta: de aproape se vad blocurile,
	// de departe ramane brazda. Altfel mipmap-ul face din el o pasta gri.
	float dist = length(VERTEX);
	float near = 1.0 - smoothstep(tread_fade_start, tread_fade_end, dist);
	float tread = texture(tread_tex, vec2(UV.x, UV.y * tread_repeats)).a;

	// ####################################################################
	// UMBRIREA CARE FACE ADANCIMEA
	//
	// Un sant se citeste fiindca FUNDUL lui e mai intunecat decat marginile:
	// primeste mai putina lumina din cer. Deci albedo-ul trebuie sa scada spre
	// centru, nu sa creasca.
	//
	// Prima versiune facea exact invers — `depth = mix(1-basin, 1, basin_mask)`
	// dadea 1.00 pe mijloc si 0.45 pe margine, adica un sant cu fundul mai
	// LUMINOS decat malul. De-aia urma arata ca o banda pictata oricat se
	// urcau valorile din trail_profile: gradientul avea semnul gresit.
	// ####################################################################
	float shade = 1.0 - basin * dip;
	// Blocurile de anvelopa se apasa in fundul santului: acolo unde calca
	// cauciucul, solul e si mai batatorit, deci si mai inchis.
	// 0.75, nu 0.45: blocurile trebuie sa se VADA ca amprenta, nu sa fie o
	// nuanta peste sant. Fara asta, modelul de anvelopa se ghicea doar la doi
	// metri de bara si intreaga textura era degeaba.
	shade *= 1.0 - tread_amount * near * tread * 0.75;
	ALBEDO = core_color * shade;

	// Stingerea cu varsta: urma proaspata e plina, cea veche abia se ghiceste.
	float age = 1.0 - smoothstep(0.55, 1.0, v_age);
	// Fara COLOR: intr-un MultiMesh, COLOR vine din culoarea PER INSTANTA, iar
	// noi am pornit doar `use_custom_data`, nu si `use_colors` — deci ar fi
	// zero si ar stinge tot. (Asta a facut urmele sa dispara complet o data.)
	//
	// Alfa urmeaza si ea santul: plina pe fund, stinsa lin spre maluri. Fara
	// podelele de dinainte (0.45 si 0.35), care faceau placuta sa se vada la
	// fel de tare pe toata latimea si ii stergeau forma.
	// Blocul apasa mai tare decat canalul dintre ele: unde a calcat cauciucul
	// santul e mai adanc, deci si mai opac. Asa amprenta se citeste si prin
	// alfa, nu doar prin umbrire.
	float press = 1.0 + tread_amount * near * tread * 0.35;
	ALPHA = clamp(core_alpha * dip * age * press, 0.0, 1.0);
}
