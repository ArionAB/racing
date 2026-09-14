// Tablierul podului de franghie (Machu Picchu, RopeBridgeHazard): UN mesh
// (scanduri + 4 cabluri + legaturi) deformat in vertex shader din ACEIASI
// parametri pe care ii rezolva hazardul pe tick — sageata globala, balansul
// lateral si afundarile locale de sub masini. Placile de coliziune
// (AnimatableBody3D) se aseaza pe aceeasi curba in GDScript
// (RopeBridgeHazard._drop / _point): daca schimbi formula aici, schimb-o si
// acolo, altfel masina merge pe o suprafata pe care n-o vezi.
//
// De ce shader si nu mesh rescris pe tick: un tablier de ~2.6k triunghiuri
// re-comis din SurfaceTool la 60 Hz ar costa mai mult decat toata fizica
// podului; aici GPU-ul face deformarea gratis. E singurul material in plus al
// podului (brief §6: „shader-ul podului"): turnurile stau pe materialul lumii.
//
// Cadrul mesh-ului: originea la capatul apropiat, -Z de-a lungul coardei
// dintre capete, +X lateral dreapta, +Y sus. u = -z / deck_length e fractia pe
// pod. Parametrii sunt `instance uniform`: doua poduri pe o pista impart
// materialul, dar fiecare isi are starea.
shader_type spatial;
render_mode cull_back;

uniform sampler2D atlas : source_color, filter_linear_mipmap;

instance uniform float deck_length = 35.0;
// Sageata de repaus (o franghie nu sta niciodata intinsa).
instance uniform float rest_sag = 0.5;
// Amplitudinea modului global (A din hazard): parabola in jos la mijloc si
// valul care ridica sferturile (wave_gain).
instance uniform float sag = 0.0;
instance uniform float wave_gain = 1.1;
// Deplasarea laterala la mijloc (m) si bratul din care iese ruliul.
instance uniform float sway = 0.0;
instance uniform float roll_arm = 20.0;
// Afundarile locale de sub (cel mult) 4 masini: pozitia (fractie) si
// amplitudinea (m). u negativ = slot gol.
instance uniform vec4 dip_u = vec4(-1.0);
instance uniform vec4 dip_a = vec4(0.0);
instance uniform float dip_sigma = 3.5;

// Cat coboara linia mediana a tablierului la fractia u (pozitiv = in jos).
// Oglinda lui RopeBridgeHazard._drop.
float deck_drop(float u) {
	float p = 4.0 * u * (1.0 - u);
	float s2 = sin(2.0 * PI * u);
	float w = s2 * s2;
	float d = rest_sag * p + sag * (p - wave_gain * w);
	// Capetele sunt ancorate: afundarea locala se stinge pe primii/ultimii 10%.
	float e = smoothstep(0.0, 0.1, min(u, 1.0 - u));
	for (int i = 0; i < 4; i++) {
		if (dip_u[i] < 0.0) {
			continue;
		}
		float dz = (u - dip_u[i]) * deck_length / dip_sigma;
		d += dip_a[i] * exp(-dz * dz) * e;
	}
	return d;
}

void vertex() {
	float u = clamp(-VERTEX.z / deck_length, 0.0, 1.0);
	float xs = sway * sin(PI * u);
	// Ruliul unui scaun de leagan: deplasat la dreapta, marginea dreapta URCA
	// (tablierul ramane perpendicular pe cabluri). Acelasi semn ca in
	// RopeBridgeHazard._plate_basis.
	float phi = atan(xs / roll_arm);
	float c = cos(phi);
	float s = sin(phi);
	vec2 xy = vec2(VERTEX.x * c - VERTEX.y * s, VERTEX.x * s + VERTEX.y * c);
	VERTEX.x = xy.x + xs;
	VERTEX.y = xy.y - deck_drop(u);
	NORMAL.xy = vec2(NORMAL.x * c - NORMAL.y * s, NORMAL.x * s + NORMAL.y * c);
}

void fragment() {
	// Acelasi contract ca Palette.world_material: culoarea din atlas pe
	// centrul slotului, AO-ul in vertex color (doar intuneca).
	ALBEDO = texture(atlas, UV).rgb * COLOR.rgb;
	ROUGHNESS = 0.9;
	SPECULAR = 0.15;
	METALLIC = 0.0;
}
