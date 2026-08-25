// Lava incandescenta (Stromboli): crusta neagra cu crapaturi care CURG.
//
// Inlocuieste finisajul `lava` de pe atlas (Palette.FINISHES), care avea doua
// probleme, amandoua vizibile in joc:
//
//  1. Pe GEOMETRIA GENERATA IN COD — gheizerele — iesea CURCUBEU. Materialul
//     tinea textura atlasului, iar un CylinderMesh/SphereMesh al lui Godot are
//     UV-uri 0..1, deci matura TOT atlasul in loc de slotul 30. Masurat:
//     cilindrul atinge 21 de sloturi, sfera 13, si amandoua trec prin rezerva
//     MAGENTA (24..31) pe care generate_palette_atlas.gd o lasa dinadins
//     tipatoare ca greselile de UV sa sara in ochi. De-aia coloanele aratau ca
//     niste acadele in dungi.
//  2. Pe restul pieselor de lava iesea CORECT dar MORT: portocaliu plat, fara
//     nicio miscare, pe un rau de lava si pe niste gheizere care tasnesc.
//
// Shaderul rezolva amandoua fiindca nu se mai uita la UV deloc: culoarea o
// CALCULEAZA din pozitia in spatiul obiectului. Deci merge identic pe un GLB
// cu UV-uri colapsate si pe o primitiva cu UV-uri intregi — nu exista drum pe
// care sa poata culege slotul gresit.
//
// CE COSTA (masurat inainte de a fi scris, la cererea dezvoltatorului):
// +1 material pe pista, ZERO draw calls, ZERO triunghiuri, zero
// post-procesare. E aritmetica in fragment shader pe pixelii care oricum se
// desenau. Scanteile de particule au fost amanate deliberat: craterul are deja
// doua sisteme (coloana de cenusa 40, aburii de fumarole 48), iar al treilea
// ar fi insemnat suprapunere de transparente exact in punctul cel mai incarcat
// al pistei — overdraw, adica fix constrangerea care doare pe mobil.
//
// DE CE ZGOMOT PROCEDURAL SI NU O TEXTURA: o dala de lava ar fi fost a doua
// textura in VRAM si tot n-ar fi putut sa CURGA fara un al doilea set de UV-uri
// animate. Aici curgerea e o scadere din coordonata: gratis.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Crusta racita si rostul incins. Amandoua vin din paleta (sloturile 20 si 30),
// pasate de Palette.lava_material() — shaderul nu inventeaza culori proprii,
// ca lava sa ramana in aceeasi familie cu bazaltul din jur.
uniform vec3 crust_color : source_color = vec3(0.09, 0.08, 0.09);
uniform vec3 glow_color : source_color = vec3(1.0, 0.42, 0.09);
// Culoarea cea mai fierbinte, in miezul rostului. Galben, nu alb: pe un ecran
// fara bloom albul se retează la 1.0 si pierde forma crapaturii.
uniform vec3 hot_color : source_color = vec3(1.0, 0.78, 0.28);

// Cat de repede curge crusta in jos pe piesa (unitati/secunda, in spatiul
// obiectului). Mic dinadins: lava e vascoasa, iar o curgere rapida citeste ca
// apa colorata. Gheizerele isi pun o valoare mai mare, ele chiar tasnesc.
uniform float flow_speed = 0.16;
// Scara zgomotului: cate celule de crusta intra intr-un metru.
// Istoricul, ca sa nu se re-regleze la intamplare: 1.7 (pete de vopsea de
// ~60 cm) -> 3.4 (prea fin, coloana citea GRANULATA — zgomot static, nu
// crusta) -> 1.1. Cu functia de rost de mai jos (ridge, nu banda in jurul
// mijlocului) celulele mari sunt CE TREBUIE: placile de crusta au ~90 cm si
// rosturile dintre ele sunt linii continue, ca pe o pahoehoe reala.
uniform float noise_scale = 1.1;
// Cat de late sunt rosturile incinse (0 = doar linii fine, 1 = mai mult jar
// decat crusta).
// Grosimea venei incinse (vezi `ridge` in fragment). Mic = rost subtire.
// 0.055 lasa jarul pe ~15-20% din suprafata: crusta e masa, jarul e linia.
uniform float crack_width : hint_range(0.02, 0.9) = 0.055;
// Energia emisiei in varful pulsatiei.
uniform float emission_energy = 2.6;
// Cat pulseaza (0 = constant, 1 = se stinge complet intre batai).
uniform float pulse_depth : hint_range(0.0, 1.0) = 0.28;
uniform float pulse_speed = 0.9;
// Defazajul per instanta, ca doua piese vecine sa nu pulseze la unison.
// Gheizerele il primesc din indexul lor; limba de lava il lasa 0.
uniform float phase_offset = 0.0;

// Hash si zgomot valoare 3D clasice. Ieftine si, mai important, STABILE: nu
// depind de derivate, deci nu clipesc la distanta ca un zgomot bazat pe fwidth.
float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep, ca celulele sa nu aiba muchii
	float n000 = hash13(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	return mix(
		mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
		mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

// Doua octave. A treia nu se vede la viteza de joc si costa un sample in plus
// pe fiecare pixel de lava — masura, nu economie de principiu.
float fbm(vec3 p) {
	return vnoise(p) * 0.65 + vnoise(p * 2.13) * 0.35;
}

// Pozitia in spatiul OBIECTULUI, retinuta pentru fragment. In spatiul lumii
// tiparul ar sta pe loc cand piesa se misca — iar coloana gheizerului chiar
// se misca, e tot rostul ei.
varying vec3 obj_pos;

void vertex() {
	obj_pos = VERTEX;
}

void fragment() {
	// Curgerea: cobori coordonata pe Y cu timpul. Piesa pare ca se scurge in
	// jos fiindca tiparul migreaza in sus prin ea.
	vec3 p = obj_pos * noise_scale;
	p.y -= TIME * flow_speed * noise_scale;

	// ROSTUL, si aici a fost greseala primei versiuni: `abs(fbm - 0.5)` da
	// PETE, nu vene — e o banda de nivel pe un camp neted, deci la orice
	// latime iesea fie girafa (banda lata), fie granulatie (banda ingusta).
	// Un rost de crusta e o CREASTA de zgomot: `1 - abs(2*n - 1)` are maxim
	// exact pe linia de nivel si scade liniar in ambele parti, deci produce
	// linii continue care se ramifica — desenul unei placi care se rupe.
	float n = fbm(p);
	float ridge = 1.0 - abs(2.0 * n - 1.0);
	// Ridicarea la putere subtiaza vena fara s-o rupa: exponent mare = rost
	// ingust. `crack_width` ramane parametrul de autorat, doar ca acum
	// controleaza grosimea venei, nu latimea unei benzi.
	float crack = pow(ridge, 1.0 / max(crack_width, 0.02));
	// Miezul: aceeasi vena, si mai stransa.
	float core = crack * crack * crack;

	// Pulsatia: respiratia lenta a masei. `phase_offset` desincronizeaza
	// instantele.
	float pulse = 1.0 - pulse_depth
			+ pulse_depth * (0.5 + 0.5 * sin(TIME * pulse_speed + phase_offset));

	vec3 albedo = mix(crust_color, glow_color, crack);
	// 0.8 -> 0.45: galbenul e MIEZUL rostului, nu culoarea lui. La 0.8 topea
	// tot rostul in galben si crusta parea o pata pe jar.
	albedo = mix(albedo, hot_color, core * 0.45);
	ALBEDO = albedo;

	// Emisia arde DOAR pe rosturi — crusta ramane stinsa, altfel piesa devine
	// o lanterna si isi pierde forma (aceeasi lectie ca la masca de slot din
	// finisajul vechi: textura e semnalul, nu emisia globala).
	EMISSION = mix(glow_color, hot_color, core) * crack * emission_energy * pulse;

	ROUGHNESS = mix(0.95, 0.55, crack); // rostul topit e mai lucios ca crusta
	SPECULAR = 0.15;
}
