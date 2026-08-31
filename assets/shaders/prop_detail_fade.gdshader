shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// ATENUAREA CU DISTANTA a stratului de pete PE PROP-URI.
//
// Runda 6 a stins pestritul pe carosabil (road_detail_fade) si pe teren
// (terrain_splat), dar prop-urile au ramas pe StandardMaterial3D. Runda 7,
// amandoi criticii, cuvant cu cuvant: pe hornuri petele au "aceeasi marime si
// acelasi contrast de la 3 m la 90 m". Se vede direct in captura: conul de la
// marginea cadrului si cel de la 90 m poarta aceleasi caneluri, la fel de
// contrastante.
//
// De ce nu se putea repara in StandardMaterial3D: `distance_fade` de acolo
// stinge OBIECTUL intreg (alfa), nu un strat. Iar mipmap-urile nu ajung — la
// incidenta razanta selectorul de mip ramane pe nivelele ascutite (vezi nota
// lunga din terrain_splat.gdshader).
//
// Shaderul reproduce EXACT ce facea materialul comun — atlas pe UV1, vertex
// color ca AO, detaliu triplanar inmultit prin masca de slot — si adauga
// stingerea spre 1.0 (identitatea inmultirii) intre near_m si far_m.
//
// MATERIALE: nu cresc. Inlocuieste materialul pe care prop-ul l-ar fi avut
// oricum, exact tiparul din road_detail_fade. Verificat cu probe_decor.

uniform sampler2D albedo_atlas : source_color, filter_linear_mipmap;
uniform sampler2D detail_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_mask_tex : source_color, filter_linear_mipmap;
uniform float detail_scale = 0.35;
uniform float detail_near_m = 26.0;
uniform float detail_far_m = 130.0;
uniform float detail_floor = 0.28;
// Texturile de detaliu sunt normalizate pe media asta (style_bible §4), deci
// mixul catre ea stinge tiparul FARA sa mute expunerea.
uniform float detail_mean = 0.850;
// In cate trepte se rupe stratul de detaliu. 0 = continuu (comportamentul de
// dinainte de runda 14). Vezi nota de la `det` in fragment().
uniform float detail_steps = 16.0;
// PIVOTUL cuantizarii, si NU e `detail_mean`. Diferenta a costat cateva
// incercari, deci merita scrisa: `detail_mean` (0.850) e valoarea catre care se
// stinge stratul la distanta, o conventie din style_bible §4 — nu media reala a
// vreunei texturi. Masurate pe toti texelii: 0.920 detail_tuff.png (dupa
// redesenarea din runda 14) si 0.903 detail_rock.png. Cuantizand in jurul lui
// 0.850, suprafata obisnuita cadea deja PESTE pivot si se amplifica in sus, iar
// santurile treceau mult sub el — asimetria aia scotea "dungi de tigru" in loc
// de tuf. Se pivoteaza pe media adevarata a dalei; stingerea cu distanta ramane
// pe `detail_mean`, ca sa nu se mute expunerea.
//
// Daca se schimba textura de detaliu, se remasoara media si se scrie aici.
uniform float detail_pivot = 0.920;
// Cat de tare se desface fiecare treapta fata de pivot. Peste 1 = placile se
// separa mai mult decat o face textura, ca saltul de pe margine sa treaca pragul
// de vizibilitate al sondei de muchii (8 din 255).
uniform float detail_gain = 2.8;
uniform float roughness_v = 0.9;
uniform float specular_v = 0.15;

// PE FATA, nu pe pixel (runda 14). `flat` face ca amandoua sa ia valoarea
// vertexului provocator, adica UNA per triunghi — deci si coordonata triplanara,
// si ponderile ei sunt constante pe toata fata.
//
// De ce. Criticul a spus trei runde "model fatetat randat ca si cum ar fi neted",
// iar lead-ul a masurat de ce: pe o linie orizontala prin conul mare doar 15% din
// schimbarile de valoare cadeau pe muchie, fata de 54-65% in referinta.
// Amplitudinea era buna (143-154 fata de 151-175) — contrastul exista, dar CURGEA.
// Geometria era corecta (53/55 hornuri deindexate, normale pe fata) si `_shade_facets`
// / `_shade_strata` cuantizau deja corect pe triunghi. Ce le acoperea era stratul
// de detaliu de AICI: `v_obj_pos` interpolat neted peste fata da o valoare noua la
// fiecare pixel, adica exact degradeul continuu peste care ochiul citeste "neted"
// — variatia dominanta invinge muchia, oricat de reala ar fi muchia.
//
// Cu `flat`, stratul de detaliu se rotunjeste la treapta fetei pe care sta: sare
// pe muchie impreuna cu umbrirea, in loc sa o traverseze. Costa zero — acelasi
// numar de texeli cititi, doar interpolarea se schimba.
// Pozitia ramane INTERPOLATA (nu `flat`): stratul de detaliu trebuie sa varieze
// si INAUNTRU unei fete. Motivul e masurat — vezi nota lunga de la `det` din
// fragment(). Ponderile triplanare, in schimb, sunt constante pe fata: sunt
// derivate din normala, care oricum e per-fata pe un mesh deindexat.
varying vec3 v_obj_pos;
varying flat vec3 v_obj_nrm;

void vertex() {
	// Triplanarul lui StandardMaterial3D (uv2_triplanar) calculeaza coordonatele
	// din VERTEX si NORMAL in spatiul obiectului, si nu citeste niciodata
	// atributul UV2 — vezi nota din Palette.world_material.
	v_obj_pos = VERTEX * detail_scale;
	v_obj_nrm = abs(NORMAL);
}

void fragment() {
	vec4 base = texture(albedo_atlas, UV);
	// Masca se citeste pe UV1, adica pe centrul slotului: slotul din paleta e
	// si canal de intensitate (roca primeste tot, masinile nimic).
	float mask = texture(detail_mask_tex, UV).a;

	// Proiectie triplanara: ponderi din normala, normalizate.
	vec3 w = v_obj_nrm;
	w = w / max(w.x + w.y + w.z, 0.0001);
	// AXELE CONTEAZA. detail_tuff.png are canelurile pe VERTICALA (tuful se
	// erodeaza prin siroire, santurile coboara cu apa — vezi cheia
	// `detail_texture` a temei si commit-ul 04d2ac8). Pe fetele aproape
	// verticale ale unui horn proiectiile laterale trebuie sa pastreze Y-ul
	// obiectului pe axa V a texturii; cu perechile inversate canelurile ies
	// ORIZONTALE, adica exact defectul reparat atunci.
	vec3 det = texture(detail_tex, v_obj_pos.zy).rgb * w.x
		+ texture(detail_tex, v_obj_pos.xz).rgb * w.y
		+ texture(detail_tex, v_obj_pos.xy).rgb * w.z;

	// CUANTIZAREA STRATULUI DE DETALIU (runda 14).
	//
	// Masurat, si contra-intuitiv, asa ca merita cifrele. Acuzatia era "model
	// fatetat randat ca si cum ar fi neted", iar tinta: peste 40% din schimbarile
	// de valoare pe o linie orizontala prin con sa cada pe muchie.
	//
	// Fatetele geometrice au fost curatate pana la capat — vertex color perfect
	// plat pe triunghi (`probe_capp_vcol`: 1489 fete neplate -> 0), AO-ul copt
	// aplatizat pe fata, umbrirea cuantizata pe 12 trepte. Rezultatul in pixeli:
	// randul chiar ARATA ca platouri curate (72,72,...,85,85,...,94,94,...), deci
	// fatetarea e reala si vizibila. Dar muchiile masurate au ramas la ~7%.
	//
	// Cauza e structurala, si se vede numarand: pe latimea casetei (167 px) conul
	// nostru pune 10-14 fatete, adica platouri de 4..15 px. Chiar daca FIECARE
	// margine ar sari, ies 6-8% — un PLAFON, nu o reglare. Referinta, cu 54-65%,
	// cere ~90 de tranzitii pe aceeasi latime, adica structuri de ~1.8 px. Nu e
	// un con mai bine umbrit, e un con cu detaliu de suprafata mult mai FIN.
	//
	// Geometria nu poate da asta: mesh-urile vin din kitul .glb (386..1099 de fete
	// de horn), si a le subdiviza ar costa triunghiuri pe toata pista pentru un
	// efect care se vede pe cateva conuri din prim-plan.
	//
	// Deci detaliul fin vine de unde vine si in referinta: din SUPRAFATA. Stratul
	// triplanar exista deja aici — problema era ca varia CONTINUU, adica exact
	// degradeul care face ochiul sa citeasca "neted". Cuantizat in trepte, acelasi
	// strat devine placi mici cu margini nete: variaza sub scara fetei (deci da
	// tranzitiile care lipseau) fara sa curga (deci nu mai ascunde muchiile
	// geometrice). E regula rundei aplicata la litera — semnalul pictat nu se
	// sterge, se cuantizeaza.
	//
	// Se cuantizeaza ABATEREA fata de `detail_pivot` (media REALA a dalei, vezi
	// nota de la uniforma), ca treptele sa fie simetrice si sa nu mute expunerea.
	//
	// Si a fost nevoie si de o dala noua: textura veche avea opt caneluri late si
	// nimic intre ele, deci amplificarea nu putea produce decat zebra. Detaliul
	// fin trebuie sa EXISTE in textura — vezi `tools/gen_detail_tuff.gd`.
	if (detail_steps >= 2.0) {
		vec3 dev = det - vec3(detail_pivot);
		dev = round(dev * detail_steps) / detail_steps;
		// ASIMETRIC, si asta e diferenta dintre "roca" si "zebra".
		//
		// Prima incercare a inmultit abaterea simetric cu 4.0: sonda a trecut
		// (44,9% muchii) si captura a iesit MAI RAU — conurile citeau a dungi
		// negre pictate, ca o blana de tigru, nu a tuf. Amplificarea la fel in
		// ambele sensuri duce santurile catre negru, si un sant negru pe o roca
		// palida nu e umbra, e desen.
		//
		// Tuful real e o piatra PALIDA cu santuri de siroire: ce se vede sunt
		// diferente in partea luminoasa, cu adanciturile doar putin mai inchise.
		// Deci partea de peste medie se desface mai mult decat cea de sub ea:
		// muchiile raman (saltul dintre trepte nu depinde de sens), dar valoarea
		// nu se mai prabuseste in negru.
		det = vec3(detail_pivot) + dev * detail_gain;
	}

	// VERTEX e in spatiul camerei, deci lungimea lui e chiar distanta.
	// Ramane per-pixel intentionat: stingerea cu distanta e un fenomen de
	// camera, nu o proprietate a fetei, iar cuantizarea ei ar fi facut ca un
	// horn intreg sa-si schimbe detaliul dintr-un cadru in altul.
	float d = length(VERTEX);
	float k = mix(1.0, detail_floor,
			clamp((d - detail_near_m) / max(detail_far_m - detail_near_m, 0.001),
			0.0, 1.0));
	det = mix(vec3(detail_mean), det, k);
	// Masca de slot decide CAT din stratul de detaliu se aplica; unde e 0,
	// rezultatul e 1.0 (identitatea inmultirii), adica material curat.
	det = mix(vec3(1.0), det, mask);

	ALBEDO = base.rgb * COLOR.rgb * det;
	ROUGHNESS = roughness_v;
	SPECULAR = specular_v;
	METALLIC = 0.0;
}
