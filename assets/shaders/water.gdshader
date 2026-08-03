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

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Coordonate de LUME, nu UV de mesh: asa ondulatia curge continuu peste
	// toate petecele de apa si nu se vede grila din care e facut planul.
	vec2 p = world_pos.xz;
	vec2 uv_near = p * scale_near + TIME * drift_near * scale_near;
	// Al doilea strat pe coordonate ROTITE 90°. detail_rock.png are strate
	// ORIZONTALE (e o textura de roca sedimentara), deci doua esantioane cu
	// aceeasi orientare se aduna in dungi paralele — la prima randare marea
	// citea ca un gard de scanduri verticale. Rotite, cele doua seturi de dungi
	// se incruciseaza si rezultatul citeste ca unda.
	vec2 uv_far = vec2(p.y, -p.x) * scale_far + TIME * drift_far * scale_far;
	float a = texture(ripple_tex, uv_near).r;
	float b = texture(ripple_tex, uv_far).r;
	float ripple = mix(1.0, a * b, ripple_strength);

	// COLOR.rgb = culoarea coapta in mesh (v1), COLOR.a = adancimea
	// normalizata (0 = linia apei, 1 = SEA_NEAR_DEPTH sau mai adanc).
	float depth01 = COLOR.a;
	// sqrt intinde partea de mica adancime: laguna turcoaz ocupa mai mult
	// din banda vizibila, exact ca in imaginile de referinta.
	float t = sqrt(depth01);
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

	base *= ripple;

	// Sun glint: NU e specular din pasul de lumina (ramane unshaded — vezi
	// contractul #2), e o scanteiere geometrica din aceleasi doua esantioane.
	// Normala perturbata ieftin din ondulatie; exponentul mic tine pata larga,
	// masca de ripple o sparge in scantei.
	vec3 n = normalize(vec3((a - 0.89) * 0.9, 1.0, (b - 0.89) * 0.9));
	vec3 view = normalize(CAMERA_POSITION_WORLD - world_pos);
	float glint = pow(max(dot(reflect(-sun_dir, n), view), 0.0), 48.0);
	base += glint * smoothstep(0.55, 0.9, a * b) * glint_strength;

	ALBEDO = base;
}
