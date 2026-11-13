shader_type spatial;
// FRUNZIS DIN CARDURI PUNCTATE (arborii Kyoto, nodurile `*_Leaves`; nov 2026).
//
// Tinta e frunzisul din art of rally: mii de puncte rotunde, coroana prin care
// se vad crengile. Prima incercare (o pata = un quad de 2 triunghiuri) dubla
// triunghiurile din valea de artari si tot iesea rara si colturoasa. Aici
// punctele NU mai sunt geometrie:
//
//   - un card = 2 triunghiuri si poarta doua straturi de puncte decupate in
//     fragment (fara textura: un hash pe celula da daca punctul exista, unde
//     sta in celula, cat e de mare si cat de deschis). Doua straturi decalate,
//     nu unul: o singura grila se citea ca tabla perforata;
//   - cardul se intoarce spre camera in vertex shader, deci niciunul nu e vazut
//     pe muchie. In pasa de umbra „camera" e lumina: cardurile se intorc spre
//     soare si umbra iese pestrita, din aceleasi puncte.
//
// CONTRACTUL DE MESH (`leaf_cards` in tools/blender/kyoto_shapes.py):
//   VERTEX  coltul cardului, in planul perpendicular pe NORMAL. Geometria e
//           REALA (nu 4 varfuri in acelasi punct): cutia mesh-ului, LOD-urile
//           importerului si orice unealta care masoara triunghiuri vad cardul.
//   NORMAL  normala MASEI coroanei: lumina curge pe coroana, nu pe card. Din ea
//           iese si planul cardului (t1 = sus x n, t2 = n x t1), deci nu are
//           voie sa fie verticala (generatorul o apleaca la minimum 6 grade).
//   UV2     coltul fata de centru in baza (t1, t2), in metri. Centrul se
//           reface ca VERTEX - t1 * UV2.x - t2 * UV2.y.
//   UV      samanta cardului, ACEEASI pe cele 4 colturi
//   COLOR   culoarea cardului, liniara, absoluta (slot x umbra x variatie)
//
// Costul s-a mutat din triunghiuri in pixeli (`discard`), axa sensibila pe
// telefon: se masoara cu ProbePerf, nu se presupune.
render_mode cull_disabled, skip_vertex_transform, diffuse_lambert, specular_disabled, vertex_lighting, shadows_disabled;

// Puncte pe latura cardului: fiecare card isi ia o valoare intre cele doua,
// ca punctele sa nu aiba toate aceeasi marime.
uniform float grid_min = 4.0;
uniform float grid_max = 6.0;
// Cata parte din celule au punct, pe fiecare strat.
uniform float fill : hint_range(0.0, 1.0) = 0.88;
// Raza punctului, in celule (0,5 = atinge marginile celulei).
uniform float r_min : hint_range(0.05, 0.5) = 0.17;
uniform float r_max : hint_range(0.05, 0.5) = 0.44;
// Sub ce cosinus (normala masei fata de directia spre camera) cardul nu se mai
// deseneaza. -1 = toate; -0.25 = cele clar intoarse cu spatele dispar.
uniform float back_cull : hint_range(-1.0, 0.5) = -0.25;
// Cat de mult variaza luminozitatea de la un punct la altul.
uniform float shade : hint_range(0.0, 0.6) = 0.22;

varying vec2 v_card;
varying vec3 v_seed;

void vertex() {
	vec3 n = normalize(NORMAL);
	vec3 t1 = normalize(cross(vec3(0.0, 1.0, 0.0), n));
	vec3 t2 = cross(n, t1);
	vec3 centre = VERTEX - t1 * UV2.x - t2 * UV2.y;
	v_card = sign(UV2) * 0.5 + 0.5;
	v_seed = vec3(floor(UV * 251.0), mix(grid_min, grid_max, fract(UV.x * 13.7)));
	// Rotire proprie in planul ecranului: altfel toate grilele ar fi aliniate
	// la marginile ecranului.
	float a = UV.y * 6.2831853;
	vec2 off = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * UV2;
	float inst_scale = length(MODEL_MATRIX[0].xyz);
	vec4 vp = MODELVIEW_MATRIX * vec4(centre, 1.0);
	vec3 nv = normalize((MODELVIEW_MATRIX * vec4(n, 0.0)).xyz);
	// COSTUL E IN PIXELI, nu in triunghiuri: fiecare card rasterizat plateste
	// shaderul si acolo unde pixelul cade pe gol. Doua taieturi, amandoua prin
	// strangerea cardului intr-un punct (nu mai deseneaza nimic):
	//  - cardurile de pe partea CEALALTA a coroanei (normala masei intoarsa de
	//    la camera): le ascund miezul si cardurile din fata;
	//  - pasa de umbra a soarelui, care e ortografica (PROJECTION_MATRIX[3][3]
	//    = 1): umbra o arunca miezul si trunchiul, nu punctele. ATENTIE: orice
	//    camera ortografica pateste la fel — in captura de ansamblu de sus a lui
	//    Snapshot arborii apar fara carduri. Shaderul nu are alt semn al pasei
	//    de umbra.
	float keep = step(back_cull, dot(nv, normalize(-vp.xyz))) * (1.0 - PROJECTION_MATRIX[3][3]);
	vp.xy += off * inst_scale * keep;
	VERTEX = vp.xyz;
	NORMAL = nv;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Tonul punctului din celula lui `g` (0..1), sau -1 daca pixelul cade pe gol.
// Un singur hash pe celula; restul valorilor ies din el.
float dot_tone(vec2 g, vec2 seed, float cells) {
	vec2 f = fract(g);
	float h = hash12(floor(g) + seed);
	// Ciorchinele e rotund, dar din puncte INTREGI: cade celula al carei centru
	// iese din disc (raza usor diferita pe fiecare celula), nu pixelul. Un cerc
	// taiat pe pixel dadea discuri cu margine neteda — nasturi, nu frunzis.
	vec2 cc = (floor(g) + 0.5) / cells - 0.5;
	if (h > fill || dot(cc, cc) > 0.13 + 0.10 * fract(h * 29.7)) {
		return -1.0;
	}
	float r = mix(r_min, r_max, fract(h * 17.31));
	vec2 c = vec2(0.5) + (vec2(fract(h * 113.7), fract(h * 541.3)) - 0.5) * 2.0 * (0.5 - r);
	return distance(f, c) > r ? -1.0 : fract(h * 7919.0);
}

void fragment() {
	// Grila unduita: fara asta punctele stau pe randuri drepte si cardul se
	// citeste ca tabla perforata.
	vec2 g = v_card * v_seed.z;
	g += 0.28 * sin(g.yx * 1.9 + v_seed.xy);
	float tone = dot_tone(g, v_seed.xy, v_seed.z);
	if (tone < 0.0) {
		tone = dot_tone(g * 0.83 + vec2(0.37, 0.61), v_seed.xy + vec2(57.0, 113.0), v_seed.z * 0.83);
		if (tone < 0.0) {
			discard;
		}
	}
	ALBEDO = COLOR.rgb * (1.0 - shade * tone);
	ROUGHNESS = 0.9;
}
