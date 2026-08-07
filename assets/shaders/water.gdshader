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
	vec3 ramp = mix(shore_col, shallow_col, smoothstep(0.0, 0.40, t));
	ramp = mix(ramp, deep_col, smoothstep(0.40, 1.0, t));
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
	base *= 1.0 + (sin(phase) * 0.5 + 0.5) * 0.12 * crest_aa - 0.06 * crest_aa;
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
	vec3 n = normalize(vec3(
		(a - 0.89) * 0.9 + cd.x * slope, 1.0, (b - 0.89) * 0.9 + cd.y * slope));
	vec3 view = normalize(CAMERA_POSITION_WORLD - world_pos);
	float glint = pow(max(dot(reflect(-sun_dir, n), view), 0.0), 48.0);
	base += glint * smoothstep(0.55, 0.9, a * b) * glint_strength;

	ALBEDO = base;
}
