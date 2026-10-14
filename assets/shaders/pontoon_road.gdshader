// Tablierul drumului de pontoane (Ha Long, PontoonRoadHazard): UN mesh
// (scanduri de bambus + butoaie de flotor) deformat in vertex shader din
// ACEIASI parametri pe care ii rezolva hazardul pe tick — sageata globala,
// balansul lateral, TANGAJUL si VALUL. Placile de coliziune
// (AnimatableBody3D) se aseaza pe aceeasi curba in GDScript
// (PontoonRoadHazard._drop / _point / _pitch_at): daca schimbi o formula aici,
// schimb-o si acolo, altfel masina merge pe o suprafata pe care n-o vezi.
//
// E geamanul lui rope_bridge.gdshader, cu trei diferente (brief §5.3):
//  1. forma modului NU moare la capete (`free_ends`): un ponton pluteste pe
//     toata lungimea, nu e ancorat in turnuri;
//  2. TANGAJ: inclinare longitudinala, pe care un pod cu capete fixe n-o are;
//  3. VALUL joncilor: fortare externa, deci pontonul se misca si cand pista e
//     goala.
//
// Cadrul mesh-ului: originea la capatul apropiat, -Z de-a lungul coardei,
// +X lateral dreapta, +Y sus. u = -z / deck_length e fractia pe ponton.
// Parametrii sunt `instance uniform`: trei tronsoane pe o pista impart
// materialul, dar fiecare isi are starea (si faza proprie de val).
shader_type spatial;
render_mode cull_back;

uniform sampler2D atlas : source_color, filter_linear_mipmap;

instance uniform float deck_length = 60.0;
// Sageata de repaus (un ponton sta deja putin in apa sub greutatea lui).
instance uniform float rest_sag = 0.12;
// Amplitudinea modului global (A din hazard).
instance uniform float sag = 0.0;
// CAPETE LIBERE: cat din forma modului ramane la buze. 0 = capete ancorate,
// adica exact podul de franghie.
instance uniform float free_ends = 0.35;
// Pe cati METRI de la buza se stinge cedarea (pragul spre insulita fixa).
instance uniform float edge_clamp = 5.0;
// Deplasarea laterala la mijloc (m) si bratul din care iese ruliul.
instance uniform float sway = 0.0;
instance uniform float roll_arm = 18.0;
// TANGAJ: metri de ridicare la capatul departat (pozitiv = capatul far urca).
instance uniform float pitch = 0.0;
// VALUL joncilor: amplitudine (m), ceasul (in perioade, deja cu faza adunata)
// si cat din el calatoreste pe lungime.
instance uniform float wave_amp = 0.10;
instance uniform float wave_t = 0.0;
instance uniform float wave_travel = 0.6;
// Afundarile locale de sub (cel mult) 4 masini. u negativ = slot gol.
instance uniform vec4 dip_u = vec4(-1.0);
instance uniform vec4 dip_a = vec4(0.0);
instance uniform float dip_sigma = 4.0;

const float TAU_ = 6.28318530718;

// Forma modului. Oglinda lui PontoonRoadHazard._p.
float mode_shape(float u) {
	return free_ends + (1.0 - free_ends) * 4.0 * u * (1.0 - u);
}

// Stingerea cedarii pe ultimii metri. Oglinda lui _edge_fade.
float edge_fade(float u) {
	if (edge_clamp <= 0.0) {
		return 1.0;
	}
	float m = min(u, 1.0 - u) * deck_length;
	return smoothstep(0.0, edge_clamp, m);
}

// Valul joncilor. Oglinda lui _wave (care primeste t = _clock/period + phase).
float wave_at(float u) {
	if (wave_amp <= 0.0) {
		return 0.0;
	}
	float travelling = sin(TAU_ * (wave_t - u * wave_travel));
	float bulk = sin(TAU_ * wave_t);
	return wave_amp * mix(bulk, travelling, wave_travel);
}

// Cat coboara linia mediana la fractia u (pozitiv = in jos).
// Oglinda lui PontoonRoadHazard._drop.
float deck_drop(float u) {
	float p = mode_shape(u);
	float fade = edge_fade(u);
	float d = rest_sag * p + sag * p * fade - wave_at(u) * fade;
	for (int i = 0; i < 4; i++) {
		if (dip_u[i] < 0.0) {
			continue;
		}
		float dz = (u - dip_u[i]) * deck_length / dip_sigma;
		d += dip_a[i] * exp(-dz * dz) * fade;
	}
	return d;
}

// Inclinarea longitudinala la fractia u. Oglinda lui _pitch_at.
float pitch_at(float u) {
	return pitch * (u - 0.5) * 2.0;
}

void vertex() {
	float u = clamp(-VERTEX.z / deck_length, 0.0, 1.0);
	float xs = sway * sin(PI * u);
	// Ruliul de leagan: deplasat la dreapta, marginea dreapta urca. ACELASI
	// semn ca in _plate_basis.
	float phi = atan(xs / roll_arm);
	float cs = cos(phi);
	float sn = sin(phi);
	vec3 p = VERTEX;
	// Rotatia de ruliu in planul (x, y), in jurul axei tronsonului.
	float rx = p.x * cs - p.y * sn;
	float ry = p.x * sn + p.y * cs;
	p.x = rx + xs;
	p.y = ry - deck_drop(u) + pitch_at(u);
	VERTEX = p;
	// Normala urmeaza ruliul, ca iluminarea sa nu rămână plata cand pontonul
	// se inclina (la pod era acelasi lucru: fara asta, scandurile par pictate).
	vec3 n = NORMAL;
	NORMAL = normalize(vec3(n.x * cs - n.y * sn, n.x * sn + n.y * cs, n.z));
}

void fragment() {
	vec4 c = texture(atlas, UV);
	ALBEDO = c.rgb * COLOR.rgb;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
