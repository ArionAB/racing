shader_type spatial;
// Brazda lasata de o roata pe teren afanat.
//
// De ce shader si nu StandardMaterial3D: placuta poarta DOUA culori, nu una —
// fagasul (inchis) si buza de material impins in lateral (deschisa). Un
// StandardMaterial3D cu `vertex_color_use_as_albedo` poate inmulti o singura
// culoare cu vertex color-ul; noi trebuie sa ALEGEM intre doua dupa unde se
// afla vertexul pe latimea urmei.
//
// Conventia din mesh (SandTrail._shared_mesh): COLOR.r = cat de mult e fagas,
// COLOR.g = cat de mult e buza, COLOR.a = cat de tare, in total.
//
// Nelit, ca restul straturilor de sol (vezi SandTrail._shared_material): pe o
// suprafata luminata, culoarea scrisa nu mai e culoarea de pe ecran, iar
// contrastul fagas/buza — chiar rostul efectului — s-ar spala in ambianta.
render_mode unshaded, blend_mix, depth_draw_never, cull_back;

uniform vec3 core_color : source_color = vec3(0.35, 0.28, 0.18);
uniform vec3 lip_color : source_color = vec3(0.72, 0.62, 0.44);
uniform float core_alpha : hint_range(0.0, 1.0) = 0.58;
uniform float lip_alpha : hint_range(0.0, 1.0) = 0.30;

void fragment() {
	float core = COLOR.r;
	float lip = COLOR.g;
	// Suma e mereu 1 (vertecsii sunt ori fagas, ori buza), deci interpolarea
	// pe suprafata da chiar trecerea dintre ele.
	ALBEDO = mix(core_color, lip_color, lip);
	ALPHA = COLOR.a * mix(core_alpha, lip_alpha, lip);
}
