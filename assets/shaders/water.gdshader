shader_type spatial;
// Apa insulei — PRIMUL shader custom din proiect.
//
// Contract, in ordinea importantei:
//
// 1. OPAC. Fara TRANSPARENCY, fara alpha, fara depth_prepass. Nu e o alegere
//    estetica: garda din tools/probe_decor.gd numara mesh-uri, materiale si
//    triunghiuri, dar e complet OARBA la overdraw si la sortarea de
//    transparenta — exact costul care omoara fps-ul pe mobil. O suprafata de
//    apa transparenta care acopera jumatate din ecran ar trece garda cu
//    "+1 material" si ar injumatati frame rate-ul pe telefon fara ca nimic
//    sa semnaleze. Adancimea o citim din vertex colors coapte la generare
//    (vezi Track._build_water), nu din DEPTH_TEXTURE.
//
// 2. UNSHADED. Marea nu primeste lumina, umbra sau specular: o oglinda pe apa
//    ar cere reflexii, interzise pe mobil (style_bible §8), iar cascada de
//    umbre e de 90 m — acne garantat pe o suprafata plata de sute de metri.
//
//    Costul deciziei, si e real: apa sare peste pasul de iluminare pe care
//    fiecare alta suprafata din lume il primeste, deci culorile ei nu mai cad
//    singure unde trebuie. S-a incercat si varianta iluminata, tocmai ca sa
//    existe o singura conventie — nu merge: culorile INCHISE hranite ca liniare
//    se umfla, iar lumina de aici nu le mai coboara, si marea iesea palida.
//    Terenul nu are culori inchise, de-asta problema n-a aparut niciodata pana
//    la mare.
//
//    Compensarea sta intr-un singur loc, pe CPU si documentata cu numere:
//    Track.water_tint() — desaturare (adjustment_saturation e 1.18), un gain
//    masurat, si srgb_to_linear. Rezultat verificat: largul #23606E fata de
//    tinta #2E5F6B, reciful #54BCB8 fata de #54BFB8.
//
// 3. ZERO texturi noi. Ondulatia vine din detail_rock.png, textura care exista
//    deja si e incarcata oricum de Palette.world_material(). Doua straturi la
//    scari si viteze diferite, inmultite: tiparul rezultat nu are perioada
//    vizibila. Un asset nou ar fi insemnat +VRAM pentru un efect care se poate
//    face din ce avem.
//
// Ce NU face, intentionat: reflexii (SSR e interzis pe mobil, style_bible §8),
// refractie, citire de DEPTH_TEXTURE. "Adancimea" per pixel e COLOR.a, copta
// in vertex colors la generare (canalul era liber — materialul e opac, alfa
// e pur canal de date) si interpolata gratis de rasterizator.
//
// v2 (issue #99): gradient de adancime PER PIXEL (rampa era interpolata pe
// varfuri la 9.5 m si iesea in benzi), spuma animata la tarm, sun glint.
// Toate efectele noi au un uniform de intensitate cu 0 = comportamentul v1 —
// kill-switch pentru profilarea pe device (M4): daca 60fps nu tine, se sting
// pe rand de pe CPU, fara shader nou. Buget static: tot 2 esantioane de
// textura per pixel, plus ~30 de operatii ALU.
//
// v3: hula directionala (umbra in vale, lumina pe creasta, spargeri albe rare)
// si trepte de adancime. Motivul, in doua parti:
//
//   - un BUG: valurile de vertecsi din v2 (+/-12 cm) scufundau grila fina sub
//     placa de larg, care statea cu doar 4 cm mai jos, iar prin gauri se vedea
//     sea_deep. Pe laguna Okinawa ieseau pete mari albastru inchis, cu margini
//     poligonale, care se PLIMBAU (sinusoidele au TIME in ele). Reparatia nu e
//     in shader, ci in Track.SEA_FAR_DROP, acum derivat din amplitudine.
//   - o LIPSA: cu petele stinse, marea deschisa ramanea o placa perfect plata
//     de culoare. Singurul lucru care se misca pe ea era ondulatia din
//     detail_rock — o textura de ROCA, cu straturile ei — deci de la distanta
//     citea ca panza. Hula ii da directie si relief.
//
// Comparatie: docs/asset_briefs/img/okinawa_apa_v3.png.
// Cost adaugat: 1 sin + 1 pow + 1 fwidth per pixel, zero esantioane noi.
render_mode unshaded, cull_back, depth_draw_opaque;

// detail_rock.png: gri, centrata pe ALB (medie masurata 0.89), tileabila.
// Se INMULTESTE peste culoare, deci intuneca — de-asta amplitudinea e mica.
uniform sampler2D ripple_tex : source_color, filter_linear_mipmap, repeat_enable;

// Scarile sunt in unitati de lume: 0.030 => o repetitie la ~33 m, 0.009 => la
// ~110 m. Necomensurabile intentionat, ca suprapunerea sa nu se repete.
uniform float scale_near : hint_range(0.005, 0.15) = 0.030;
uniform float scale_far : hint_range(0.002, 0.05) = 0.009;
// Deriva, in metri pe secunda. Lenta: la viteza de cursa o apa care curge
// repede citeste ca zgomot, nu ca mare.
uniform vec2 drift_near = vec2(0.55, 0.30);
uniform vec2 drift_far = vec2(-0.28, 0.44);
// Cat de tare bate ondulatia. 0 = culoare plata din vertex colors.
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.35;

// Valuri de VERTECSI (nu de pixeli): doua sinusoide in coordonate de lume, cu
// frecvente necomensurabile. Grila fina de 9.5 m exista deja langa tarm —
// valurile au vertecsi exact unde se vad. Cost: vertex-only, zero fill rate,
// zero texturi.
//
// Anvelopa amplitudinii se CALCULEAZA din COLOR.a (adancime normalizata), nu
// se mai citeste direct din el. Pana la v2, alfa purta chiar amplitudinea,
// coapta pe CPU; de cand rampa de culoare are nevoie de adancime per pixel,
// canalul e ocupat de ea, iar anvelopa se reconstituie aici — e oricum o
// functie de adancime. Forma ramane identica: 0 la tarm (un val acolo deschide
// o fisura cu terenul), varf pe recif, 0 spre larg (granita cu planul fix
// SeaFar, pe care un val l-ar strapunge).
//
// Valoarea EFECTIVA vine de pe CPU (Track.SEA_WAVE_AMP), nu de aici: din ea se
// deriva Track.SEA_FAR_DROP, adica cat de jos sta placa de larg fata de grila
// fina. Cand cele doua numere s-au desincronizat (drop 4 cm, val 12 cm), grila
// s-a scufundat sub larg si prin gauri se vedea sea_deep — petele albastre
// poligonale care se plimbau pe laguna. Implicita de aici e doar plasa de
// siguranta pentru cine deschide shaderul singur.
uniform float wave_amp : hint_range(0.0, 0.5) = 0.12;
// Unde cade varful anvelopei, in adancime normalizata: SEA_REEF_DEPTH /
// SEA_NEAR_DEPTH. Setat de Track odata cu restul uniformelor, ca sa nu existe
// doua locuri unde se scrie aceeasi geometrie de recif.
uniform float wave_reef : hint_range(0.05, 0.95) = 0.357;

// --- v2. Toate culorile vin de pe CPU, din Track.water_tint(): un singur loc
// de calibrare, promisiunea din comentariul lui _sea_color ramane adevarata.
// Rampa de adancime, per pixel. 0 = doar vertex colors (v1).
uniform float ramp_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 shore_col; // nisip ud, chiar la linia apei
uniform vec3 shallow_col; // laguna turcoaz
uniform vec3 deep_col; // largul
// Spuma animata la tarm. 0 = doar spuma-geometrie din banda de varfuri.
uniform float foam_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 foam_col;
// Pana la ce adancime normalizata urca spuma pe plaja.
uniform float foam_reach : hint_range(0.01, 0.5) = 0.10;
uniform float foam_speed = 1.1;
// Scanteierea soarelui pe ondulatie. 0 = stinsa.
uniform float glint_strength : hint_range(0.0, 2.0) = 0.0;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0); // SPRE soare, normalizat

// --- v3. Doua adaugiri, amandoua pentru aceeasi problema: din masina, marea
// deschisa era o placa PLATA de culoare, fara nicio informatie de suprafata —
// singurul lucru care se misca pe ea era ondulatia din detail_rock, adica o
// textura de ROCA, cu straturile ei orizontale. La distanta citea ca panza, nu
// ca apa. Vezi capturile din docs/asset_briefs/img/okinawa_apa_v3.png.
//
// CRESTE DE HULA. Linii de val care traverseaza marea pe o directie fixa,
// analitice (fara textura, deci fara tipar care se repeta si fara VRAM). Sunt
// ce da apei DIRECTIE — fara ele nu se poate spune incotro merge marea. Doua
// trenuri cu lungimi de unda necomensurabile si directii la ~20° unul de altul,
// ridicate la putere ca sa iasa linii subtiri de creasta, nu sinusoide grase.
// Cost: 2 sin + 2 pow, zero esantioane de textura.
uniform float crest_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 crest_dir = vec2(0.80, 0.60); // directia hulei, in plan XZ
uniform float crest_len = 26.0; // distanta intre creste, in metri
uniform float crest_speed = 2.6; // cat de repede inainteaza, m/s
uniform float crest_sharp : hint_range(1.0, 64.0) = 12.0;

// BENZI DE ADANCIME. Rampa de culoare e continua, deci tranzitia laguna->larg
// iesea ca un blur de zeci de metri — corect fizic, dar exact opusul liniei
// grafice a jocului (style_bible §1: forme citibile, nu degrade-uri). Aici
// se cuantizeaza adancimea in cateva trepte, iar marginea treptei se
// SERPUIESTE cu ondulatia deja esantionata — altfel ar iesi curbe de nivel
// trase cu compasul, la fel de artificiale ca blur-ul.
uniform float band_strength : hint_range(0.0, 1.0) = 0.0;
uniform float band_count : hint_range(2.0, 12.0) = 5.0;
uniform float band_wobble : hint_range(0.0, 0.4) = 0.09;

// --- v4 (Chongqing). Trei adaugiri, toate pentru aceeasi intrebare: de ce o
// suprafata desaturata si inchisa citea tot CAMP, nu apa.
//
// DOUA RAURI. Rampa de culoare e dupa ADANCIME, deci pe un singur material
// intreaga apa avea o singura familie de culoare. Cu un rau verde la mal si
// unul brun la larg (ce incercase runda 4), fiecare pixel de adancime medie
// cadea intre verde si brun — adica exact pe OLIV. Media dintre verde si maro
// e culoarea unei mirisiti; nu exista reglaj de saturatie care sa o salveze.
// Aici raul nu se mai alege dupa adancime, ci dupa LOC: o dreapta in planul
// XZ imparte apa in doua, fiecare mal cu rampa lui, iar granita e chiar linia
// de confluenta. `split_strength = 0` => o singura apa, ca inainte.
uniform float split_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 split_dir = vec2(1.0, 0.0); // normala dreptei, in plan XZ
uniform float split_offset = 0.0;        // dot(p, split_dir) al dreptei
uniform float split_soft = 24.0;         // latimea amestecului, in metri
uniform float split_meander = 40.0;      // cat serpuieste granita (metri)
uniform vec3 shore_col_b;
uniform vec3 shallow_col_b;
uniform vec3 deep_col_b;
// Linia de confluenta: dara de spuma/gunoi care se vede intre doua curenti.
// Se INTUNECA, nu se albeste — o dunga alba pe apa neagra ar fi citit iar
// spuma, iar brief-ul cere explicit fara spuma lata.
uniform float seam_strength : hint_range(0.0, 1.0) = 0.0;

// LUMINA CARE SCLIPESTE. Pana aici scanteierea venea de la soare, iar pe o
// tema de noapte soarele sta la -78 grade (aproape in zenit): reflexia lui
// pleaca in sus, camera de cursa se uita aproape razant, deci pe apa nu ajungea
// aproape nimic — cateva pete izolate in prim-plan. Ce lumineaza un rau de
// oras noaptea sunt felinarele de pe MALUL OPUS, adica o lumina JOASA, dincolo
// de apa. `glint_horizon > 0` inlocuieste soarele cu exact asa ceva: o sursa
// virtuala la inaltimea aia deasupra orizontului, mereu in continuarea privirii
// — de aceea drumul de sclipiri vine spre camera, ca luna pe mare.
uniform float glint_horizon : hint_range(0.0, 1.0) = 0.0;
// Culoarea sclipirii, in LINIAR (se ADUNA peste albedo). Alb = ca pana acum.
uniform vec3 glint_col = vec3(1.0);
// Cat de ALUNGITE sunt reflexiile pe directia privirii. Pe ecran directia aia
// e verticala, deci asta e diferenta dintre "pete pe camp" si "reflexii pe
// apa". Mecanismul: panta suprafetei se comprima pe axa privirii si se
// amplifica pe cea transversala, deci pata speculara se plimba mult in lateral
// si aproape deloc in adancime => dungi verticale. 0 = izotrop, ca in v3.
uniform float glint_streak : hint_range(0.0, 4.0) = 0.0;
// Cat de STRANSA e pata speculara. 48 (soarele) e un punct; cu o lumina joasa
// pe directia privirii, conditia de oglinda e aproape indeplinita pe toata apa
// din departare, iar un exponent mare aprinde o BANDA continua la orizont —
// masurat: toata apa la luminanta 130+, adica dune de nisip. Un exponent mic
// intinde lobul, deci sclipirea nu mai are prag, iar ce o sparge in reflexii
// separate ramane doar ondulatia.
uniform float glint_sharp : hint_range(2.0, 256.0) = 48.0;
// PRAGUL care rupe luciul in reflexii SEPARATE. Fara el, o lumina joasa pe
// directia privirii indeplineste conditia de oglinda pe aproape toata apa —
// masurat: cu intensitate 0.05, mediana apei sarea de la 18 la 44, adica
// efectul nu era o sclipire, era un strat. Cu prag, tot ce e sub el ramane
// apa neagra si doar varfurile rup pragul, deci intensitatea poate fi mare
// fara sa spele suprafata. 0 = fara prag (comportamentul v3, temele vechi).
uniform float glint_cut : hint_range(0.0, 0.95) = 0.0;
// CAT DE MARE e o reflexie. Multiplica scara mastii: sub 1 = tipar mai mare.
// A fost lipsa care a facut runda 5 sa citeasca oras, nu apa: la scara
// ondulatiei (33 m pe dala, deci detalii de ~1.5 m), petele ieseau de cativa
// pixeli si cadeau in randuri regulate — masurat pe captura, exact o grila de
// ferestre aprinse intinsa peste rau. In diorama reflexiile sunt PETE de cativa
// metri, rare si neregulate. 1.0 = masca de dinainte (temele vechi).
uniform float glint_grain : hint_range(0.05, 1.0) = 1.0;
// Raza (in metri) la care reflexiile NU sunt inca alungite. Sub ea petele
// raman rotunde, peste ea se lungesc spre privitor — vezi nota din fragment.
uniform float glint_ref = 120.0;

// --- v5 (Chongqing, runda 6). Pana aici toate reglajele au fost de CULOARE:
// nuanta, saturatie, cat de inchisa e apa. Masurand diorama pixel cu pixel a
// iesit ca problema nu era niciodata culoarea, ci SUPRAFATA — apa noastra n-are
// nicio variatie de valoare pe ea, iar cea din referinta are peste tot:
//
//   percentile 5/25/50/75/90 ale luminantei, pe aceeasi suprafata de apa
//     diorama (bratul verde): 32 / 44 / 49 / 56 / 72   — ecart intercuartilic 12
//     noi (runda 5, cornisa D): 22 / 22 / 22 / 24 / 26 — o placa moarta
//
//   luminanta de baza pe 6 benzi, de la departare spre prim-plan
//     diorama: 22.9 -> 18.1 -> 22.1 -> 41.3 -> 47.2 -> 48.0  (se dubleaza)
//     noi:     22.3 -> 22.3 -> 22.3 -> 22.3 -> 22.3 -> 23.4  (aceeasi valoare)
//
// A doua cifra e cea care rupe iluzia: o suprafata care RECEDE in perspectiva
// si nu isi schimba valoarea nu se citeste ca plan orizontal, se citeste ca
// perete vopsit. De aici cele doua adaugiri, in ordinea in care conteaza.

// FATETE. In diorama apa e un poliedru plat: pete mari, de zeci de metri,
// fiecare de o valoare usor diferita, cu muchii drepte intre ele. Aia e toata
// "textura" ei — nu granulatie, ci trepte de valoare pe suprafete mari.
// `band_strength` face deja asa ceva, dar cuantizeaza ADANCIMEA, iar pe un rau
// adanc peste tot adancimea e constanta, deci nu produce nimic. Aici campul
// cuantizat e SPATIAL: trei sinusoide cu directii si lungimi de unda
// necomensurabile (30-65 m), foarte lente in timp, cu marginea treptei rupta de
// ondulatia deja esantionata ca sa nu iasa curbe de nivel. Cost: 3 sin.
uniform float facet_strength : hint_range(0.0, 1.0) = 0.0;
uniform float facet_count : hint_range(2.0, 12.0) = 5.0;
uniform float facet_scale = 0.10; // rad/m; 0.10 => fatete de ~30-65 m
uniform float facet_wobble : hint_range(0.0, 1.0) = 0.35;
uniform float facet_speed = 0.05;

// GRADIENT DE PERSPECTIVA. Motivul pentru care apa dioramei se citeste ca plan
// orizontal si a noastra nu. Nu e ceata (aia coloreaza spre cer, aici valoarea
// CREsTE spre prim-plan) si nu e adancime: e unghiul sub care privesti apa.
// Razant, vezi reflexia malului opus — intuneric. De sus, vezi in apa tulbure,
// iar aluviunile in suspensie sunt ce se lumineaza. `view.y` e chiar sinusul
// unghiului ala si nu costa nimic: vectorul spre camera se calculeaza oricum
// pentru glint. view_lo = view_hi = 1.0 => niciun efect (temele vechi).
uniform float view_lo : hint_range(0.2, 2.0) = 1.0;
uniform float view_hi : hint_range(0.2, 3.0) = 1.0;
uniform float view_ref : hint_range(0.02, 1.0) = 0.22; // unghiul de "plin"

// Cat de adanca e umbra hulei. Pana la v4 era scrisa in cod, 0.12 — calibrata
// pe o mare vazuta de departe, unde crestele sunt ce da relieful. Pe un rau
// vazut de sus e singura modulatie CONTINUA de pe suprafata, deci trebuie sa
// poata fi urcata fara sa se atinga si spargerile albe.
uniform float crest_shade : hint_range(0.0, 0.8) = 0.12;

// MARGINEA si INTERIORUL unei reflexii. Masurat in diorama, petele aurii stau
// la 1.8-2.8x fata de apa pe care se afla, cu halou si cu valoare care variaza
// pe ele; la noi ieseau la 6-7.4x, cu contur de hartie rupta si interior plat —
// adica obiecte lipite pe suprafata, nu lumina in unda. `glint_soft` lateste
// tranzitia, `glint_body` face intensitatea sa creasca cu adancimea fisurii in
// loc sa sara la maxim imediat dupa prag. 0 = taietura de pana acum.
uniform float glint_soft : hint_range(0.02, 0.6) = 0.17;
uniform float glint_body : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_pos;

// Anvelopa valurilor din adancimea normalizata: urca de la 0 la tarm pana la 1
// pe recif, coboara inapoi la 0 spre larg. Identica cu masca pe care o cocea
// CPU-ul in alfa inainte de v2 — doar ca socotita din singurul numar pe care
// alfa il mai poate purta acum.
float wave_envelope(float depth01) {
	return clamp(depth01 / wave_reef, 0.0, 1.0)
		* clamp((1.0 - depth01) / max(1.0 - wave_reef, 0.001), 0.0, 1.0);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float swell = sin(world_pos.x * 0.55 + TIME * 1.05) * 0.6
		+ cos(world_pos.z * 0.47 - TIME * 0.85) * 0.4;
	VERTEX.y += swell * wave_amp * wave_envelope(COLOR.a);
}

void fragment() {
	// Coordonate de LUME, nu UV de mesh: asa ondulatia curge continuu peste
	// toate petecele de apa si nu se vede grila din care e facut planul.
	vec2 p = world_pos.xz;
	vec2 uv_near = p * scale_near + TIME * drift_near * scale_near;
	// Al doilea strat pe coordonate ROTITE. detail_rock.png are strate
	// ORIZONTALE (e o textura de roca sedimentara), deci doua esantioane cu
	// aceeasi orientare se aduna in dungi paralele — la prima randare marea
	// citea ca un gard de scanduri verticale. Rotite, cele doua seturi de dungi
	// se incruciseaza si rezultatul citeste ca unda.
	//
	// Unghiul a fost 90° si l-am schimbat la 63°: la 90° ambele seturi de dungi
	// raman ALINIATE LA AXE, deci incrucisarea da o GRILA — vizibila ca tesatura
	// in orice captura de sus a largului. Un unghi care nu e multiplu de 90 rupe
	// si alinierea, nu doar paralelismul.
	vec2 rot = vec2(p.x * 0.454 - p.y * 0.891, p.x * 0.891 + p.y * 0.454);
	vec2 uv_far = rot * scale_far + TIME * drift_far * scale_far;
	float a = texture(ripple_tex, uv_near).r;
	float b = texture(ripple_tex, uv_far).r;
	float ripple = mix(1.0, a * b, ripple_strength);

	// COLOR.rgb = culoarea coapta in mesh (v1), COLOR.a = adancimea
	// normalizata (0 = linia apei, 1 = SEA_NEAR_DEPTH sau mai adanc).
	float depth01 = COLOR.a;
	// sqrt intinde partea de mica adancime: laguna turcoaz ocupa mai mult
	// din banda vizibila, exact ca in imaginile de referinta.
	float t = sqrt(depth01);
	// Trepte de adancime. Serpuirea se aplica INAINTE de cuantizare, ca sa
	// deformeze granita; aplicata dupa, ar fi doar zgomotat culoarea plata din
	// interiorul benzii, adica fix ce nu voiam.
	float tw = t + (a * b - 0.79) * band_wobble;
	float tq = floor(tw * band_count) / max(band_count - 1.0, 1.0);
	t = mix(t, clamp(tq, 0.0, 1.0), band_strength);
	float t_shore = smoothstep(0.0, 0.40, t);
	float t_deep = smoothstep(0.40, 1.0, t);
	vec3 ramp = mix(shore_col, shallow_col, t_shore);
	ramp = mix(ramp, deep_col, t_deep);
	// Al doilea rau: aceeasi rampa de adancime, alta familie de culoare.
	// Granita SERPUIESTE cu ondulatia deja esantionata (acelasi a*b ca peste
	// tot in shaderul asta) — o dreapta perfecta ar fi citit ca margine de
	// poligon, nu ca intalnirea a doua ape.
	float sd = dot(p, normalize(split_dir)) - split_offset
		+ (a * b - 0.79) * split_meander;
	float side = smoothstep(-split_soft, split_soft, sd) * split_strength;
	vec3 ramp_b = mix(shore_col_b, shallow_col_b, t_shore);
	ramp_b = mix(ramp_b, deep_col_b, t_deep);
	ramp = mix(ramp, ramp_b, side);
	// Dara de confluenta: ingusta (putere 6 peste triunghiul de tranzitie),
	// si doar acolo unde amestecul chiar are loc.
	float seam = pow(1.0 - abs(side * 2.0 - 1.0), 6.0) * split_strength;
	ramp *= 1.0 - seam * seam_strength;
	vec3 base = mix(COLOR.rgb, ramp, ramp_strength);

	// Spuma: o banda care "linge" plaja. Pulsul curge SPRE mal (faza scade cu
	// adancimea), iar pragul pe ondulatia deja esantionata ii rupe marginea —
	// fara el iesea o dunga paralela cu tarmul, trasa cu rigla.
	float band = 1.0 - smoothstep(0.0, foam_reach, depth01);
	float pulse = 0.55 + 0.45 * sin(TIME * foam_speed - depth01 * 42.0);
	float ragged = smoothstep(0.72, 0.95, a * b + band * 0.25);
	float foam = clamp(band * pulse * ragged * 2.2, 0.0, 1.0) * foam_strength;
	base = mix(base, foam_col, foam);

	// HULA. Un singur tren de valuri, care da marii directie.
	//
	// Doua incercari gresite inaintea asteia, amandoua din acelasi motiv — am
	// desenat SPUMA acolo unde trebuia desenata FORMA:
	//
	//   1. Doua trenuri de creste ascutite la 20° unul de altul: o PLASA alba
	//      peste toata marea. Doua seturi de linii care se intersecteaza dau o
	//      grila, oricat de necomensurabile ar fi lungimile de unda.
	//   2. Un singur tren de creste albe: linii paralele care converg spre
	//      punctul de fuga, ca liniile unui caiet. Marea vazuta de la 200 m nu
	//      arata linii albe continue — arata alternanta lumina/umbra.
	//
	// Deci hula MODULEAZA LUMINOZITATEA (valea mai intunecata, creasta mai
	// deschisa), si abia peste ea, rar, apar spargeri albe. Suprafata primeste
	// relief citibil fara sa fie acoperita de spuma.
	vec2 cd = normalize(crest_dir);
	float k1 = 6.2831853 / max(crest_len, 1.0);
	// Faza SERPUIESTE cu ondulatia deja esantionata: fara asta crestele sunt
	// drepte pe kilometri, si nimic dintr-o mare nu e drept.
	float phase = dot(p, cd) * k1 - TIME * crest_speed * k1
		+ (a * b - 0.79) * 5.0;
	// ANTIALIASING. Un tipar analitic n-are mipmap-uri: spre orizont o perioada
	// intreaga intra intr-un pixel si iese moire. fwidth(phase) spune cate
	// radiane trece tiparul pe un pixel; peste ~1.2 nu mai e rezolvabil si se
	// stinge. Costul e o derivata, nu un esantion.
	float crest_aa = (1.0 - smoothstep(0.35, 1.2, fwidth(phase)))
		* crest_strength;
	// Umbra de hula: ±6% pe culoarea deja calculata. Cat sa se vada forma, nu
	// cat sa se vada efectul.
	base *= 1.0 + (sin(phase) * 0.5 + 0.5) * crest_shade * crest_aa
		- crest_shade * 0.5 * crest_aa;
	// Spargeri: doar varful crestei, si doar unde o modulatie lenta de-a lungul
	// ei o lasa — altfel toata creasta ar sparge pe toata lungimea, la fel de
	// artificial ca liniile de caiet.
	vec2 along = vec2(-cd.y, cd.x);
	float breaker = pow(max(sin(phase), 0.0), crest_sharp)
		* smoothstep(0.62, 0.98, sin(dot(p, along) * 0.09 + TIME * 0.31) * 0.5
			+ 0.5 + (a * b - 0.79));
	// Se stinge chiar la tarm: acolo comanda banda de spuma, iar doua efecte
	// albe suprapuse pe aceiasi pixeli ies ca o pata laptoasa.
	breaker *= smoothstep(0.0, foam_reach * 2.0, depth01) * crest_aa;
	base = mix(base, foam_col, breaker * (1.0 - foam));

	base *= ripple;

	// FATETE. Un camp spatial lent, cuantizat in trepte: pete mari de valoare
	// usor diferita, cu muchii — ce vezi in diorama cand te uiti la apa de la
	// 60 m. Marginea treptei se rupe cu ondulatia deja esantionata (acelasi
	// a*b ca peste tot aici); fara asta ies contururi de sinusoida, adica
	// exact curbele de nivel pe care band_wobble le evita si el.
	if (facet_strength > 0.0) {
		float f = sin(dot(p, vec2(0.83, 0.55) * facet_scale) + TIME * facet_speed)
			+ sin(dot(p, vec2(-0.47, 1.31) * facet_scale)
				- TIME * facet_speed * 0.74)
			+ sin(dot(p, vec2(1.67, 1.04) * facet_scale)
				+ TIME * facet_speed * 0.41);
		f = f * 0.1667 + 0.5 + (a * b - 0.79) * facet_wobble;
		float fq = floor(clamp(f, 0.0, 0.999) * facet_count)
			/ max(facet_count - 1.0, 1.0);
		base *= 1.0 + (clamp(fq, 0.0, 1.0) - 0.5) * facet_strength;
	}

	vec3 view = normalize(CAMERA_POSITION_WORLD - world_pos);
	// Directia privirii, proiectata in plan: axa pe care reflexiile trebuie sa
	// se lungeasca (pe ecran e verticala).
	vec2 to_cam = world_pos.xz - CAMERA_POSITION_WORLD.xz;
	float cam_r = length(to_cam);
	vec2 vdir = to_cam / max(cam_r, 1e-4);

	// GRADIENT DE PERSPECTIVA. view.y e sinusul unghiului sub care cade
	// privirea pe apa: aproape 0 la orizont, mare in prim-plan. Suprafata se
	// deschide odata cu el — asta e semnalul "planul asta e orizontal si se
	// departeaza", si e ce lipsea cel mai tare (masurat: valoare identica pe
	// toata adancimea cadrului).
	if (view_lo != 1.0 || view_hi != 1.0) {
		base *= mix(view_lo, view_hi, smoothstep(0.0, view_ref, view.y));
	}

	// Sun glint: NU e specular din pasul de lumina (ramane unshaded — vezi
	// contractul #2), e o scanteiere geometrica din aceleasi doua esantioane.
	// Normala perturbata ieftin din ondulatie; exponentul mic tine pata larga,
	// masca de ripple o sparge in scantei.
	//
	// v3: la perturbarea din textura se adauga PANTA crestelor. Fara ea,
	// scanteierea urma straturile din detail_rock — adica desena pe mare
	// tiparul unei roci — si nu avea nimic de-a face cu valurile pe care le vezi
	// trecand. Cu ea, sclipirea alearga de-a lungul crestelor, care e chiar
	// motivul pentru care apa sclipeste in realitate. Amplitudinea vine din
	// crest_strength: un singur intrerupator pentru tot ce tine de hula.
	float slope = cos(phase) * crest_strength * 0.30;
	vec2 tilt = vec2(
		(a - 0.89) * 0.9 + cd.x * slope, (b - 0.89) * 0.9 + cd.y * slope);
	// Cu `glint_streak`, panta care hotaraste unde e oglinda ramane DOAR cea a
	// hulei — neteda, de zeci de metri. Ondulatia din textura are detalii de
	// ~1.5 m: bagata in normala speculara, sparge lobul in sclipici de cativa
	// pixeli, iar o apa acoperita de sclipici marunt citeste oras, nu rau
	// (masurat, runda 5). Forma reflexiei o da MASCA, care are grauntele ei.
	if (glint_streak > 0.0) {
		tilt = cd * slope;
	}
	float tilt_along = dot(tilt, vdir);
	// Componenta pe adancime se comprima, cea transversala se amplifica:
	// suprafata isi pastreaza aceeasi "energie" de valuri, dar pata speculara
	// nu mai fuge in departare la fiecare rid — ramane pe loc si se intinde.
	tilt = (tilt - vdir * tilt_along) * (1.0 + glint_streak * 0.6)
		+ vdir * tilt_along / (1.0 + glint_streak * 3.0);
	vec3 n = normalize(vec3(tilt.x, 1.0, tilt.y));
	// Sursa: soarele, sau o lumina joasa dincolo de apa (vezi glint_horizon).
	vec3 gl = sun_dir;
	if (glint_horizon > 0.0) {
		gl = normalize(vec3(vdir.x, glint_horizon, vdir.y));
	}
	float glint = pow(max(dot(reflect(-gl, n), view), 0.0), glint_sharp);
	float gmask = smoothstep(0.55, 0.90, a * b);
	if (glint_streak > 0.0) {
		// FORMA reflexiei. Doua lucruri, amandoua invatate masurand:
		//
		// 1. Se citesc CRAPATURILE texturii, nu campul ei. detail_rock.png e
		//    o roca: mediana canalului rosu e 0.96, un sfert din texeli sunt
		//    fix 1.0 — adica e alba cu fisuri rare. Masca de pana acum lua
		//    partea ALBA, deci "reflexie" insemna aproape toata apa, iar ce
		//    ramanea intunecat erau fisurile: rau de aur cu crapaturi verzi.
		//    Inversata, fisurile devin exact ce trebuie — pete rare, cu
		//    marimi diferite si margini neregulate.
		// 2. Deformarea e RADIALA fata de CAMERA, si asta cere o raza de
		//    referinta. Varianta dinainte descompunea pozitia ABSOLUTA pe
		//    directia privirii; termenul dot(camera, vdir) se roteste odata cu
		//    vdir, deci petele ieseau arcuite intr-un evantai in jurul
		//    camerei — pensulatii, nu reflexii. Aici se comprima doar
		//    DISTANTA fata de camera, in jurul lui `glint_ref` metri: la raza
		//    aia scara transversala ramane 1, iar cea radiala scade, deci
		//    petele se lungesc SPRE privitor. Pe ecran, spre verticala.
		float k = 1.0 + glint_streak * 4.0;
		// Compresia distantei e LOGARITMICA in jurul lui `glint_ref`, nu afina.
		// Cu forma afina (rg = ref + (r - ref) / k) tot ce e mult mai APROAPE
		// decat referinta cadea practic in acelasi punct de esantionare: pe pod,
		// apa de la 20-40 m primea o singura pata intinsa pe zeci de metri —
		// limbi de flacara verticale, nu reflexii (masurat, runda 6). Aici
		// factorul de alungire LOCAL e rg / (k * cam_r): mic in prim-plan (pete
		// aproape rotunde, cum se vad de pe chei) si mare in departare (dungi
		// spre privitor, cum se vede luna pe mare). Acelasi `glint_streak`, doar
		// ca acum inseamna acelasi lucru la orice distanta.
		float rg = glint_ref * pow(max(cam_r, 1.0) / glint_ref, 1.0 / k);
		vec2 gp = CAMERA_POSITION_WORLD.xz + vdir * rg;
		float s = scale_near * glint_grain;
		// A doua dala pe axe rotite si la o scara incomensurabila (0.37, nu
		// 1/2 sau 1/3): perioada comuna a celor doua iese in afara cadrului,
		// deci petele nu mai cad intr-o grila.
		vec2 gq = vec2(gp.x * 0.454 - gp.y * 0.891,
			gp.x * 0.891 + gp.y * 0.454);
		float c1 = texture(ripple_tex, gp * s + TIME * drift_near * s).r;
		float c2 = texture(ripple_tex,
			gq * s * 0.37 + TIME * drift_far * s * 0.37).r;
		// `glint_cut` = cat de adanca trebuie sa fie fisura ca sa se aprinda.
		// E singura marime pe care o compar cu diorama: acolo reflexiile aurii
		// tin 2-12% din pixelii apei.
		// Marginea NU e taiata cu cutitul. La 0.09 latime petele ieseau ca
		// hartie rupta — contur zimtat, interior de o singura culoare plata;
		// in diorama fiecare pata are un halou si valoare care variaza pe ea.
		float m = 1.0 - c1 * c2;
		gmask = smoothstep(glint_cut, glint_cut + glint_soft, m);
		// Interiorul nu e plat: cu cat fisura e mai adanca, cu atat pata e mai
		// aprinsa. Fara asta o pata e o singura culoare pana la contur, adica
		// hartie decupata; in diorama fiecare reflexie are miez si halou.
		gmask *= mix(1.0, smoothstep(glint_cut, 1.0, m), glint_body);
	}
	float g = glint * gmask;
	base += g * glint_strength * glint_col;

	ALBEDO = base;
}
