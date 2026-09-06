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
// Cat de tare se lumineaza malul dinspre soare. Fara el, dara e o pata inchisa:
// vezi blocul RELIEFUL de mai jos.
uniform float lip_light : hint_range(0.0, 2.0) = 0.55;
// Directia soarelui in spatiul lumii, impinsa de SandTrail din DirectionalLight3D.
uniform vec3 sun_dir = vec3(0.0, -1.0, 0.0);
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

	// ####################################################################
	// RELIEFUL: umbra SINGURA nu se vede ca adancitura
	//
	// Un sant se citeste fiindca are DOUA lucruri — umbra in fund SI lumina pe
	// malul dinspre soare. Ochiul deduce forma din perechea asta.
	//
	// Masurat pe ghidul vizual (panoul TRACKS CLOSE-UP): 30.7% din pixeli sunt
	// mai inchisi decat fundalul, dar 20.8% sunt mai DESCHISI — raport 0.68.
	// Varianta cu umbra singura, care a stat pe main, avea raport 0.04: 96% din
	// dara doar intuneca. De la volan nu avea nicio adancime, oricat de bine
	// era modelat bazinul. Garda e tools/ProbeRelief.tscn.
	//
	// Panta malului pe latime e derivata lui `dip`: d/dx(1 - x^2) = -2x. Malul
	// a carui panta urca spre soare primeste lumina, celalalt ramane in umbra —
	// de-aia trebuie directia REALA a soarelui, nu o buza simetrica. O buza
	// luminata pe amandoua partile arata fals exact cand soarele bate oblic.
	// ####################################################################
	vec3 sun_w = normalize(sun_dir);
	// Normala placutei in lume e Y; malul inclina normala pe latimea urmei.
	// `slope` e +1 pe malul din dreapta, -1 pe cel din stanga, 0 pe fund.
	float slope = -2.0 * across;
	// Latimea urmei in lume, ca sa stim in ce directie "cade" malul.
	vec3 side_w = normalize(vec3(MODEL_MATRIX[0].xyz));
	// Cat de mult priveste malul spre soare (soarele bate DINSPRE -sun_dir).
	float toward = dot(side_w * slope, -sun_w);
	// Buza traieste pe TALUZ, nu pe muchia de afara. `dip * (1 - dip)` are
	// varful la jumatatea pantei, adica exact unde malul urca — iar acolo alfa
	// placutei inca exista. Prima varianta punea varful la `across = ±1`, unde
	// `dip` (si deci alfa) e zero: buza se desena fix unde placuta e invizibila,
	// si de-aia raportul urcase doar de la 0.04 la 0.12.
	float band = dip * (1.0 - dip) * 4.0;
	// Buza se adauga PROPORTIONAL cu cat de deschis e solul, nu absolut. Pe
	// nisip luminos un plus de 0.5 se pierde in stralucire; pe soseaua
	// vulcanica a Strombolilui acelasi plus e o dunga alba, fiindca porneste
	// de la aproape negru. Masurat: aceeasi buza dadea raport 0.36 pe Okinawa
	// si peste 3 pe Stromboli. Inmultind cu `shade` (deci cu culoarea locala),
	// buza ramane o LUMINARE a solului, nu o vopsea peste el.
	float lip = max(toward, 0.0) * band * lip_light;
	shade *= 1.0 + lip;
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
