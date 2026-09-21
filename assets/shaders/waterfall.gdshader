shader_type spatial;
// PERDEAUA DE APA (Fiordland, brief §5.1 clasa `waterfall`): un singur
// material pentru toate cele 7 perdele — Stirling, cele 5 de ploaie, Bowen.
//
// Ce trebuie sa citeasca ochiul: APA CARE CADE, nu un zid. Placeholder-ul
// (o cutie pe FOAM_WHITE) dadea exact zidul: fara directie, fara margine
// moale, fara fundal prin el. Runda 1 a inlocuit cutia cu dungi verticale +
// zgomot 2D, dar dungile (1 fir/m, faza identica pe toata latimea) tot
// citeau ca o DRAPERIE STATICA: `streak` (60% din greutate) nu avea deloc
// termen de timp, deci perdeaua abia se misca — masurat runda 2 (verificarea
// asta): cross-corelatie pe o fasie verticala intre doua cadre la 1s
// distanta dadea shift=0, corelatie 0.9999 — adica NIMIC nu se citea ca
// miscare, darmite miscare in jos.
//
// Runda 2 (masa de apa, nu draperie) schimba trei lucruri, in ordinea
// importantei:
//   1. DIRECTIA — bug de semn: zgomotul de curgere era esantionat la
//      `(y + TIME*viteza)`, care e echivalentul unei texturi ce SCADE pe y
//      (UV2.y creste in jos, deci asta e o alunecare in SUS pe ecran) —
//      exact plangerea "apa pare sa cada de jos in sus". Corect: `(y - TIME
//      * viteza)`, ca un fir de la o pozitie MICA de y (aproape de varf) sa
//      ajunga, la un t mai mare, la un y MAI MARE (mai aproape de baza).
//   2. DOUA OCTAVE MISCATE, nu una statica + zgomot: fire LATE, LENTE
//      (`streak`, acum translatate cu jumatate din viteza, faza pe latime)
//      + fire FINE, RAPIDE (`streak_fast`, viteza intreaga) — apa reala are
//      simultan mase mari care aluneca lent si stropi/vine care curg vizibil
//      mai repede peste ele.
//   3. FAZA VARIABILA PE LATIME (fiecare "fir" pornit dintr-un offset de
//      timp diferit, nu toate sincron) + DENSITATE mai mare spre centru
//      (perdeaua nu e o placa uniforma, centrul cade mai plin) + LUMINOZITATE
//      care creste spre BAZA (spuma urca vizual in perdea, nu doar banda de
//      la sol) + o UNDULARE ORIZONTALA usoara (zgomot 1D lent pe y, adaugat
//      la x inainte de esantionare — apa nu cade perfect vertical).
//   4. MARGINI care cad CONTINUU la zero — lateral (`edge_m` metri, profil
//      smoothstep) si sus (`top_frac` din inaltime): 0 trepte dure pe o
//      taietura prin margine (memoria `particule-muchia-nu-numarul`).
// La baza, o banda de SPUMA (`foam_m`): mai alba si mai densa — de la 100 m
// camera vede doar baza (brief §2.0), deci baza e cea care spune „apa cade
// pe drum".
//
// Contract de cost: unshaded, blend_mix, fara scriere in depth (perdelele
// si spray-ul se suprapun fara sa se taie), cull_disabled (o panza se vede
// din ambele parti), UN pass, ZERO texturi — totul e procedural. Ceata
// scenei ramane activa: perdelele departate se topesc in ea ca orice altceva.
//
// Ce ii da mesh-ul (vezi `WaterfallVisual`):
//   UV2     = (x_m, y_m) in METRI, y in jos de la varf — zgomot, viteza, fade;
//   COLOR.a = alpha de vertex (caderea radiala a placii de spuma; 1 pe panze).
// Dimensiunile vin ca INSTANCE UNIFORMS, nu prin vertex color: SurfaceTool
// taie culoarea la [0,1] (memoria `surfacetool-clamp-vertex-color`), deci o
// latime de 30 m ajungea 1 m si fade-ul lateral disparea — prima captura a
// dat o placa de sticla uniforma, exact zidul pe care il inlocuiam.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

// Apa in cadere: alb-albastrui pal, nu alb pur (albul e pentru spuma).
uniform vec3 water_col : source_color = vec3(0.78, 0.89, 0.95);
uniform vec3 foam_col : source_color = vec3(0.97, 0.99, 1.0);
// Opacitatea maxima a corpului perdelei (brief: 0.55-0.75, fundalul trebuie
// sa se ghiceasca prin ea).
uniform float alpha_max : hint_range(0.0, 1.0) = 0.66;
// Viteza de cadere a desenului (m/s). Apa reala cade cu 15-25 m/s la baza
// unei cascade de 45 m; pe ecran, 9 se citeste ca „repede" fara sa devina
// zgomot.
uniform float fall_speed : hint_range(0.0, 30.0) = 9.0;
// Cate fire pe metru (scara zgomotului 1D pe latime).
uniform float streak_scale : hint_range(0.1, 4.0) = 1.1;
// Cat de mult unduleaza lateral perdeaua (m), zgomot lent pe verticala.
uniform float sway_m : hint_range(0.0, 3.0) = 0.6;
// Latimea (m) pe care alpha cade la zero la marginile laterale.
uniform float edge_m : hint_range(0.2, 10.0) = 2.5;
// Fractia din inaltime pe care perdeaua se topeste spre varf.
uniform float top_frac : hint_range(0.05, 0.9) = 0.4;
// Inaltimea (m) benzii de spuma de la baza.
uniform float foam_m : hint_range(0.0, 6.0) = 1.8;
// Cat coboara panza sub cota drumului (`WaterfallVisual.SINK_M`), si pe cat
// se topeste acolo: pe drum muchia de jos e ingropata in asfalt, dar unde
// terenul de langa drum e mai jos ea ar iesi ca o LINIE dreapta in aer
// (masurat pe captura din perdea: o dunga orizontala prin tot cadrul).
uniform float sink_m : hint_range(0.1, 6.0) = 2.0;
// Faza de ploaie (RainCycle) o stinge/aprinde prin `modulate` pe hazard;
// per instanta, ca sa nu se dubleze materialul.
instance uniform float intensity : hint_range(0.0, 1.0) = 1.0;
// (latime, inaltime) in metri ale panzei — per MeshInstance3D, acelasi material.
instance uniform vec2 sheet_m = vec2(6.0, 14.0);
// 1 pe placa de spuma de la sol: mereu spuma, fara fade lateral/sus.
instance uniform float pad : hint_range(0.0, 1.0) = 0.0;
// 1 pe INELUL de spuma animat de la baza perdelei (splash, brief pasul 3a):
// aceeasi geometrie de evantai ca placa de spuma (`pad`), dar cu turbulenta
// de zgomot animata in loc de alba plata — bulboana unde apa loveste solul.
// Exclusiv cu `pad`/`mist` (WaterfallVisual seteaza un singur mod per nod).
instance uniform float ring : hint_range(0.0, 1.0) = 0.0;
// 1 pe PANZA DE CEATA JOASA (brief pasul 3c): fasie plata, joasa, care se
// intinde de-a lungul drumului — ceata se topeste in alpha-ul de vertex
// (radial, ca la `pad`) si are o usoara respiratie de zgomot, nu e statica.
instance uniform float mist : hint_range(0.0, 1.0) = 0.0;

varying vec2 v_m;
varying vec4 v_col;

float hash1(float n) {
	return fract(sin(n) * 43758.5453123);
}

float vnoise1(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash1(i), hash1(i + 1.0), f);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x);
	float b = mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x);
	return mix(a, b, f.y);
}

float sstep(float x) {
	x = clamp(x, 0.0, 1.0);
	return x * x * (3.0 - 2.0 * x);
}

void vertex() {
	v_m = UV2;
	v_col = COLOR;
}

void fragment() {
	float w = max(sheet_m.x, 0.01);
	float h = max(sheet_m.y, 0.01);
	float x = v_m.x;
	float y = v_m.y;
	// SEMNUL: UV2.y creste in JOS (varf=0, baza=h). Ca un fir sa alunece spre
	// baza pe masura ce TIME creste, punctul esantionat trebuie sa se
	// deplaseze spre y MIC pe masura ce t creste — deci (y - t), nu (y + t).
	// Cu (y + t) featurile alunecau spre y mic, adica spre VARF: apa cadea
	// vizual de jos in sus. Vezi antetul, runda 2.
	float t = TIME * fall_speed;

	// UNDULARE ORIZONTALA: un offset lent pe x, functie de y si de timp — apa
	// nu cade perfect drept, se leagana usor lateral pe masura ce coboara.
	float sway = (vnoise1(y * 0.05 - t * 0.02) - 0.5) * 2.0 * sway_m;
	float xs = x + sway;

	// FAZA PE LATIME: fiecare "coloana" de fire porneste dintr-un offset de
	// timp propriu, altfel toata perdeaua respira sincron (se citea ca un
	// singur tapet care aluneca, nu ca fire independente).
	float phase = vnoise1(xs * streak_scale * 0.37 + 91.0) * 6.0;

	// 1. fire LATE, LENTE: zgomot 2D, translatat la jumatate din viteza de
	//    cadere — masa mare de apa care aluneca. Scara pe y apropiata de cea
	//    pe x (nu alungita): o draperie de fire are gradient aproape doar
	//    orizontal (coloane constante pe verticala) — o masa de apa trebuie
	//    sa varieze si pe verticala, nu doar sa se scurga uniform in jos.
	float streak = vnoise2(vec2(xs * streak_scale * 1.1,
		(y - t * 0.5 + phase) * 0.85));
	// 2. fire FINE, RAPIDE: a doua octava, la viteza intreaga — scara pe y
	//    MAI DEASA decat pe x, ca segmentele scurte de curgere sa se vada
	//    clar (altfel firele raman coloane lungi si anizotropia nu scade).
	float streak_fast = vnoise2(vec2(xs * streak_scale * 2.4 + 17.0,
		(y - t + phase * 1.7) * 1.8));
	// 3. curgerea de fond: zgomot 2D suplimentar, izotrop, cea mai rapida
	//    octava — rupe orice periodicitate ramasa intre primele doua si
	//    aduce zgomot cu variatie egala pe ambele axe.
	float flow2 = vnoise2(vec2(xs * streak_scale * 3.2 + 3.0, (y - t * 1.3) * 3.2));
	float body = streak * 0.4 + streak_fast * 0.35 + flow2 * 0.25;
	// contrast intre fire: fara el dungile raman o textura de 5%, invizibila
	// de la 30 m — si perdeaua citeste iar ca placa.
	body = clamp((body - 0.5) * 1.8 + 0.5, 0.0, 1.0);

	// DENSITATE spre centru: perdeaua nu e o placa uniforma — mijlocul cade
	// mai plin decat marginile (inainte de fade-ul de margine, care ramane
	// separat, pentru ca placa de spuma sa nu mosteneasca acest profil).
	float center_u = clamp((x / w) * 2.0 - 1.0, -1.0, 1.0); // -1..1
	float density = 1.0 - 0.22 * (center_u * center_u);
	body *= density;

	// LUMINOZITATE spre BAZA: spuma urca vizual in perdea, nu doar banda de
	// la sol — un gradient continuu, separat de banda de spuma propriu-zisa.
	float base_glow = clamp(y / h, 0.0, 1.0);
	base_glow = base_glow * base_glow;

	// 4. marginile: continuu la zero, lateral si sus. Placa de spuma nu are
	//    margini de perdea — caderea ei radiala e in alpha-ul de vertex.
	float lat = sstep(min(x, w - x) / edge_m);
	float top = sstep(y / (h * top_frac));
	// sub cota drumului: 1 la sol, 0 la capatul scufundat.
	float bot = sstep((h + sink_m - y) / sink_m);
	lat = mix(lat, 1.0, pad);
	top = mix(top, 1.0, pad) * mix(bot, 1.0, pad);

	// spuma: banda de la baza, sau toata placa.
	float foam = sstep((y - (h - foam_m)) / foam_m);
	foam = max(foam, pad);

	float white_mix = clamp(foam * 0.85 + body * 0.25 + base_glow * 0.2, 0.0, 1.0);
	vec3 col = mix(water_col, foam_col, white_mix);
	float a = alpha_max * (0.25 + 0.75 * body);
	// baza mai densa — spuma e albul opac al perdelei, corpul e translucid.
	a = mix(a, min(a + 0.28, 0.92), foam * 0.8);
	a = min(a + base_glow * 0.10, 0.95);
	// marginile se aplica DUPA spuma: si banda de spuma se topeste lateral.
	a *= lat * top;

	// INELUL DE SPUMA (splash, brief pasul 3a): aceeasi geometrie de evantai
	// ca placa de spuma, dar turbulenta — zgomot 2D animat pe planul XZ local
	// (v_m aici = (x,z) in metri, vezi WaterfallVisual._ring_mesh), plus o
	// unda radiala care pulseaza spre exterior (bulboana care se latesc cand
	// apa loveste solul). Alpha ramane cea din COLOR (cadere radiala, 0 pe
	// margine — acelasi contract ca placa de spuma).
	//
	// Godot nu accepta `return` in fragment(): cele trei moduri (perdea,
	// inel, ceata) se aleg prin mix()/lerp() pe rezultatul final, nu prin
	// ramuri cu iesire timpurie.
	float churn = vnoise2(v_m * 0.6 + vec2(0.0, TIME * 1.4)) * 0.5
		+ vnoise2(v_m * 1.4 - vec2(TIME * 0.9, 0.0)) * 0.5;
	float rad = length(v_m);
	float pulse = sin(rad * 1.1 - TIME * 3.0) * 0.5 + 0.5;
	float turb = clamp(churn * 0.7 + pulse * 0.3, 0.0, 1.0);
	vec3 ring_col = mix(water_col, foam_col, 0.6 + 0.4 * turb);
	float ring_a = alpha_max * (0.5 + 0.5 * turb) * intensity * v_col.a;

	// CEATA JOASA (brief pasul 3c): panza plata, alpha radiala (COLOR, ca la
	// placa de spuma) cu o respiratie lenta de zgomot — nu e o pata statica,
	// se misca usor ca un abur care se tarage pe drum.
	float drift = vnoise2(v_m * 0.15 + vec2(TIME * 0.25, TIME * 0.08));
	float wisp = 0.65 + 0.35 * drift;
	vec3 mist_col = foam_col;
	float mist_a = alpha_max * 0.5 * wisp * intensity * v_col.a;

	vec3 final_col = mix(mix(col, ring_col, step(0.5, ring)), mist_col, step(0.5, mist));
	float final_a = mix(mix(a * intensity * v_col.a, ring_a, step(0.5, ring)), mist_a, step(0.5, mist));
	ALBEDO = final_col;
	ALPHA = final_a;
}
