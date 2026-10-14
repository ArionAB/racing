// Terenul cu doua perechi de texturi (nisip si iarba), amestecate per-vertex.
//
// Exista fiindca StandardMaterial3D poate cara O SINGURA pereche micro+macro,
// iar terenul are de la #206 doua materiale de suprafata: plaja (nisip) si
// campul (iarba). Greutatea amestecului vine prin COLOR.a — builder-ul o
// calcula deja pentru tenta de culoare (lerp-ul spre inland_tint) si o arunca.
// Alternativa cinstita era taierea mesh-ului in doua suprafete, dar la celula
// de 7.9 m cusatura ar fi iesit o linie de nivel in trepte — exact conturul
// pe care banda lata de trecere (BEACH_FADE) exista ca sa-l ascunda.
//
// Matematica e identica cu StandardMaterial3D-ul de dinainte (albedo din
// vertex color x micro pe UV1 x macro pe UV2, BLEND_MODE_MUL), doar ca
// fiecare trecere alege intre doua texturi. Texturile sunt gri cu media
// 0.850 (style_bible §4), deci expunerea nu se misca indiferent de amestec.
// Cost: 4 sample-uri de textura comprimata in loc de 2 — ieftin si pe mobil;
// fill rate-ul nu se schimba (aceiasi pixeli, acelasi overdraw zero).
shader_type spatial;
render_mode cull_back;

uniform sampler2D sand_micro : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_macro : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_micro : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_macro : source_color, filter_linear_mipmap, repeat_enable;

// DUNGI ORIZONTALE PE PERETI VERTICALI (lotul peretilor striati, sep 2026).
//
// Raportul dezvoltatorului, de la volan: peretele interior de la serpentina
// (Serengeti) arata striat, ca o textura trasa pe verticala. Cauza, verificata
// cu `tools/probe_terrain_uv_stretch.gd` (Jacobianul UV<->lume per triunghi,
// nu o presupunere): UV-ul de mai jos (`Vector2(v.x, v.z) * SURFACE_TILING`,
// in track.gd) e o proiectie PLANARA pe (x, z). Pe o fata verticala x si z
// aproape nu se misca intre baza si varful fetei, deci acelasi interval UV
// (ingust) se intinde pe toata inaltimea: raportul stretch_v/stretch_h
// (1.0 = izotrop, cat trebuie sa fie) masoara
//   Alpii (Track09):   0.995 pe fete <15°  ->  0.220 pe fete >70°
//   Serengeti (Track14): 0.996 pe fete <15° -> 0.223 pe fete >70°
// adica pe verticala textura se intinde de ~4.5x mai mult decat pe orizontala
// — exact "textura trasa pe verticala" din raport.
//
// FIX: triplanar in `vertex()`, blendat DOAR pe fetele inclinate. Doua
// proiectii suplimentare (planele XY si ZY, in spatiul OBIECTULUI — pentru
// Terrain e identic cu lumea, nodul TerrainBody/Track n-are transform, vezi
// track.gd `_build_terrain`) se calculeaza mereu (in `vertex()`, o data per
// vertex, nu per pixel), dar `fragment()` le CITESTE (2 sample-uri in plus pe
// canal) doar cand ponderea triplanara ajunge sub 1.0 — vezi `tri_w` mai jos.
//
// De ce triplanar si nu UV separat la generare (varianta b): UV-ul e per
// VERTEX, iar pe grila de teren un vertex de pe muchia dintre o fata plata si
// una verticala e PARTAJAT intre ele (st.index() le uneste explicit ca sa
// medieze normalele, vezi comentariul de la `st.index()`); doua UV-uri diferite
// pe acelasi vertex ar cere despicarea lui, adica taierea normalei mediate care
// tine dealurile netede — pret prea mare pentru un fix de textura.
//
// Ponderea triplanara foloseste NORMALA GEOMETRICA a fetei (`flat`), nu cea
// interpolata: cu interpolare, un vertex de pe muchia plat/vertical ar amesteca
// ponderi diferite pe cele doua fete care il ating si ar produce o cusatura
// vizibila exact acolo unde nu vrem nicio schimbare. `flat` face ca toti cei
// trei vertecsi ai unui triunghi sa raporteze ACEEASI pondere (a vertexului
// provocator), deci fiecare fata e tratata uniform — acelasi tipar ca
// `v_obj_nrm` din prop_detail_fade.gdshader.
uniform float tri_power = 4.0;
// Aceleasi doua scari ca UV/UV2 planare (SURFACE_TILING si
// SURFACE_TILING_MACRO din track.gd) — trebuie sa ramana in sincron manual,
// fiindca un shader nu poate citi o constanta GDScript. Daca se schimba una
// acolo, se schimba si aici.
uniform float tiling_micro = 0.32;
uniform float tiling_macro = 0.022;

// ATENUAREA CU DISTANTA a stratului de pete. Runda 6, cererea (4) a criticii:
// "dala de pete ocupa ~40% din imagine... nu se atenueaza cu distanta si e
// aceeasi pe nisip, pe drum si pe acostament. Se citeste ca un MATERIAL, nu ca
// un peisaj."
//
// De ce nu se rezolva singur din mipmap-uri: `micro` se repeta la ~2 m si
// contine granulatie de pixel (vezi `grain` din _detail_tuff/_write_tileable_n).
// Mipmap-ul mediaza patru texeli, dar la incidenta RAZANTA — si de la volan tot
// nisipul e razant — derivata pe axa vederii e mica, deci selectorul de mip
// ramane pe nivelele ascutite pana departe. Textura ramane la fel de
// contrastanta la 5 m si la 150 m, iar creierul citeste "suprafata plata
// texturata", nu "sol care se departeaza".
//
// Ce facem: dupa `near_m` interpolam fiecare trecere spre MEDIA ei (texturile
// sunt normalizate pe 0.850, style_bible §4), deci petele se sting spre culoarea
// curata a terenului fara sa mute expunerea cu nimic. La `far_m` a mai ramas
// `floor` din contrast — nu zero: o suprafata perfect neteda la distanta ar fi
// celalalt defect.
//
// Costa doi mix() si o lungime de vector. Zero materiale, zero texturi.
uniform float detail_near_m = 26.0;
uniform float detail_far_m = 130.0;
uniform float detail_floor = 0.28;
uniform float detail_mean = 0.850;

// `flat`: toti cei trei vertecsi ai unui triunghi vad ponderea vertexului
// provocator — fara cusatura de-a lungul muchiei plat/vertical (vezi antetul).
varying flat float v_tri_w;
// Cele doua proiectii laterale (planele ZY si XY ale obiectului), calculate o
// data per vertex. Nu sunt `flat`: in interiorul unei fete inclinate trebuie
// sa varieze continuu, ca micro-textura sa curga normal pe suprafata — doar
// PONDEREA dintre planar si triplanar e constanta pe fata.
varying vec2 v_uv_side;
varying vec2 v_uv_side_macro;

// PETICE DE ZAPADA VECHE (track.gd, cheia de tema `snow_patches`). Zgomotul si
// marginea taiata se fac AICI, per pixel: vertex color nu poate (se taie la [0,1],
// deci doar intuneca, iar grila de 7.9 m nu poarta o margine de 1 m). Vertexul da
// doar permisiunea (CUSTOM0.r: 0 langa drum, 1 de la ~8 m). `snow_on` = 0 pe orice
// tema fara cheie: ramura nu se executa, randarea ramane bit-identica.
uniform float snow_on = 0.0;
uniform vec3 snow_color : source_color = vec3(1.0);
uniform float snow_y0 = 24.0;
uniform float snow_y_ramp = 14.0;
uniform float snow_cover = 0.35;
uniform float snow_scale = 0.045;
uniform float snow_slope_gain = 0.6;
uniform float snow_edge_noise = 0.10;
varying float v_snow_elig;
varying vec3 v_wpos;
varying float v_ny;

float snow_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float snow_vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(snow_hash(i), snow_hash(i + vec2(1.0, 0.0)), f.x),
			mix(snow_hash(i + vec2(0.0, 1.0)), snow_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	// VERTEX si NORMAL sunt aici in spatiul OBIECTULUI (inainte de proiectia
	// in `vertex()`). Pentru Terrain asta e identic cu spatiul lumii: nodul
	// TerrainBody (si Track, parintele lui) nu poarta niciun transform — vezi
	// track.gd `_build_terrain`, unde `body`/`inst` raman la Transform3D
	// implicit. De-asta UV-ul planar existent poate folosi direct v.x/v.z
	// fara MODEL_MATRIX, si de-asta triplanarul de aici poate face la fel.
	vec3 n = abs(NORMAL);
	// Pondere: 0 pe fata perfect verticala (n.y = 0), 1 pe fata orizontala
	// (n.y = 1). Ridicata la putere ca tranzitia sa stea ingusta in jurul
	// pantelor mari si sa lase fetele aproape plate EXACT ca inainte — vezi
	// masuratoarea din antet (stretch la <15° ramane 0.995-0.997 neatins).
	v_tri_w = pow(clamp(n.y, 0.0, 1.0), tri_power);
	// Proiectie pe planul lateral dominant (ZY sau XY dupa care axa
	// orizontala a normalei e mai mare) — o singura proiectie laterala, nu
	// doua amestecate, fiindca pe un perete de-a lungul benzii normala are
	// aproape intotdeauna o axa orizontala clar dominanta (viraje, nu colturi
	// de cutie); vezi nota de cost din fragment(). Pe axa verticala (Y a
	// texturii) folosim VERTEX.y direct: exact directia care lipsea din
	// proiectia planara, si motivul intregului fix.
	vec2 side = mix(VERTEX.zy, VERTEX.xy, step(n.x, n.z));
	v_uv_side = side * tiling_micro;
	v_uv_side_macro = side * tiling_macro;
	if (snow_on > 0.5) {
		v_snow_elig = CUSTOM0.r;
		v_wpos = VERTEX;
		v_ny = NORMAL.y;
	}
}

void fragment() {
	float w = COLOR.a;
	vec3 micro_planar = mix(texture(sand_micro, UV).rgb,
			texture(grass_micro, UV).rgb, w);
	vec3 macro_planar = mix(texture(sand_macro, UV2).rgb,
			texture(grass_macro, UV2).rgb, w);
	vec3 micro = micro_planar;
	vec3 macro = macro_planar;
	// TRIPLANAR doar unde chiar conteaza: sub pragul asta ponderea planarului
	// e >=0.999, deci cele doua sample-uri suplimentare nu ar schimba
	// rezultatul cu nimic vizibil — le sarim (early-out), ca fetele plate
	// (marea majoritate a ariei, vezi raportul probei) sa nu coste NIMIC in
	// plus fata de shaderul dinainte de fix.
	if (v_tri_w < 0.999) {
		vec3 micro_side = mix(texture(sand_micro, v_uv_side).rgb,
				texture(grass_micro, v_uv_side).rgb, w);
		vec3 macro_side = mix(texture(sand_macro, v_uv_side_macro).rgb,
				texture(grass_macro, v_uv_side_macro).rgb, w);
		micro = mix(micro_side, micro_planar, v_tri_w);
		macro = mix(macro_side, macro_planar, v_tri_w);
	}
	// VERTEX e in spatiul camerei (view), deci lungimea lui e chiar distanta
	// pana la fragment — fara matrici in plus.
	float d = length(VERTEX);
	float k = mix(1.0, detail_floor,
			clamp((d - detail_near_m) / max(detail_far_m - detail_near_m, 0.001),
			0.0, 1.0));
	micro = mix(vec3(detail_mean), micro, k);
	macro = mix(vec3(detail_mean), macro, k);
	ALBEDO = COLOR.rgb * micro * macro;
	if (snow_on > 0.5) {
		vec2 q = v_wpos.xz * snow_scale;
		float n = 0.55 * snow_vnoise(q) + 0.30 * snow_vnoise(q * 2.3 + 17.0)
				+ 0.15 * snow_vnoise(q * 5.1 + 41.0);
		// Margine rupta de un zgomot fin (~0.7 m), ca conturul sa nu iasa blob neted.
		n += (snow_vnoise(v_wpos.xz * 1.4) - 0.5) * snow_edge_noise;
		float e = clamp((v_wpos.y - snow_y0) / snow_y_ramp, 0.0, 1.0);
		float steep = clamp(1.0 - v_ny, 0.0, 1.0);
		float score = n + (e - 1.0) * 0.6 + steep * snow_slope_gain;
		float thr = 1.0 - snow_cover;
		float aa = fwidth(score) * 1.0 + 0.004;
		float m = smoothstep(thr - aa, thr + aa, score);
		float ae = fwidth(v_snow_elig) + 0.01;
		m *= smoothstep(0.5 - ae, 0.5 + ae, v_snow_elig);
		float lum = (micro.g * macro.g) / (detail_mean * detail_mean);
		vec3 snow_albedo = snow_color * mix(1.0, lum, 0.5);
		ALBEDO = mix(ALBEDO, snow_albedo, m);
	}
	// style_bible §4: nisip/iarba 0.95, fara specular — singurul sheen din
	// lume ramane al asfaltului.
	ROUGHNESS = 0.95;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
