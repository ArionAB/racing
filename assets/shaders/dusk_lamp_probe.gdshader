// MATERIAL DE PROBA pentru canalul unic de emisie a lampilor (Jodhpur,
// `DuskCycle`, docs/track_briefs/jodhpur.md §3 „Ceasul de lumina" si §4).
//
// Nu e un material de productie (nicio piesa din kit nu il foloseste inca —
// candelele/becurile/ferestrele vin cu asset-urile Jodhpur, §5). Exista ca sa
// (a) verifice ca parametrul global chiar circula pana la un shader compilat
// separat de `dusk_cycle.gd`, si (b) sa fie MODELUL de cum se conecteaza o
// lampa noua.
//
// CUM SE CONECTEAZA O LAMPA NOUA:
//   1. Materialul ei declara `global uniform float dusk_lamps;` (fara
//      `uniform` obisnuit — trebuie sa fie EXACT cheia din
//      project.godot [shader_globals], "dusk_lamps").
//   2. In fragment(), inmulteste EMISSION cu `dusk_lamps` (sau cu o functie
//      monotona a lui, ex. `smoothstep` daca lampa trebuie sa "sara" abia
//      dupa un anumit prag) — vezi mai jos.
//   3. Nu e nevoie de niciun cod GDScript, niciun grup, nicio referinta la
//      `DuskCycle`: `RenderingServer.global_shader_parameter_set()` scrie
//      valoarea o singura data pe cadru si TOATE materialele care citesc
//      cheia o vad simultan — asta e chiar rostul canalului unic (brief:
//      "orice material emisiv viitor... il poate citi").
//
// De ce global si nu un export pe fiecare material/nod: pista are potential
// mii de candele+becuri (§5, kit modular + MultiMesh). Un export per-instanta
// ar cere fie o bucla peste toate nodurile in `DuskCycle._apply_lamps`
// (cost O(n) pe cadru, plus o cale noua de "gasire" separata de restul
// efectelor), fie un shader-material PARTAJAT (`Palette.world_material()`,
// stilul clasei) care oricum ar avea nevoie de UN loc unde sa citeasca
// aceeasi valoare. Parametrul global e acel loc, gratis (RenderingServer
// il distribuie direct catre GPU, fara sa treaca prin niciun nod Godot).
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx, unshaded;

// Cheia TREBUIE sa fie identica cu `DuskCycle.LAMPS_GLOBAL_PARAM` si cu
// intrarea din project.godot [shader_globals]. Fara declaratia din
// project.godot, Godot tot accepta `global uniform` la compilare (il
// creeaza „soft", cu valoarea impartita intre shadere), dar valoarea
// initiala inainte de primul `global_shader_parameter_set()` ar fi 0 —
// declaratia din project.godot fixeaza 0,15 (brief: "0,15" la dusk=0, adica
// exact ce ar trebui sa vada o pista fara nicio cursa activa).
global uniform float dusk_lamps;

// Culoarea de baza a "flacarii" de proba — portocaliul cald din paleta
// (brief §4: candelele/gălbenelele sunt LAVA_ORANGE). Un material real de
// candela ar lua asta din `Palette` in loc sa-l scrie static aici.
uniform vec3 lamp_color : source_color = vec3(1.0, 0.55, 0.15);
// Cat de puternic arde la dusk_lamps = 1.0. Separat de `dusk_lamps` insusi,
// ca sa poata exista lampi mai puternice/slabe fara sa schimbe canalul comun.
uniform float emission_strength = 4.0;

void fragment() {
	ALBEDO = lamp_color * 0.2;
	// Inmultire directa: la dusk_lamps=0,15 (ziua) flacara abia se vede, la
	// 1,0 (noaptea turul 3) e sursa de lumina a scenei — exact rampa 0,15 ->
	// 1,0 din brief §3/§4. O lampa care vrea un "salt" mai brusc (sa ramana
	// stinsa vizual pana aproape de noapte) ar inlocui inmultirea asta cu
	// smoothstep(prag_jos, prag_sus, dusk_lamps).
	EMISSION = lamp_color * emission_strength * dusk_lamps;
}
