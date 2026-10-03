class_name LeafFall
extends GPUParticles3D
## FRUNZE CARE CAD (Kyoto, POI D si E; brief kyoto.md §2.0 "teatru", §5.1).
##
## UN emitator, UN material, PLAFON de count explicit ([constant MAX_LEAVES]).
## Emitatorul nu e lipit de pista: se muta cu CAMERA, in fata ei, doar cat timp
## camera e intr-o zona a [LeafCarpet] (zonele vin de la covor, o singura sursa),
## deci pe tot turul se aloca aceleasi MAX_LEAVES particule, nu cate o lume per zona.
## `local_coords = false` lasa frunzele deja nascute pe loc cand emitatorul se muta.
##
## EFECTUL NU VINE DIN NUMAR (memoria `particule-muchia-nu-numarul`): frunza e o
## panza billboard cu o textura cu alfa care CADE CONTINUU la zero spre margine
## (cos^2 x (1-d)^0.5), nu o primitiva cu silueta dura. [method edge_max_step]
## masoara asta pe textura insasi (sonda ProbeLeafCarpet), nu numara particule.

## Plafonul de particule vii (si al tuturor frunzelor care cad pe pista).
const MAX_LEAVES: int = 64
const LEAF_TEX_SIZE: int = 128
## Latura panzei (m). La 10-25 m de camera: ~12-28 px pe un ecran de 1080p.
const LEAF_SIZE: float = 0.4

## Calea catre covor (sursa zonelor).
@export var carpet_path: NodePath = ^"../CovorFrunze"
## Frunzele se nasc intr-o cutie in fata camerei: jumatati de latura (x, y, z, m).
@export var box_half: Vector3 = Vector3(13.0, 3.0, 20.0)
## Cat de in fata camerei (m) si cat de sus fata de drum e CENTRUL cutiei.
@export var ahead_m: float = 16.0
@export var height_m: float = 6.0
## Zona e "activa" de la atatia metri INAINTE de intrare, ca frunzele sa fie
## deja in aer cand ajungi, si pana la atatia metri dupa iesire.
@export var lead_in_m: float = 45.0
@export var lead_out_m: float = 12.0

static var _tex: ImageTexture = null
static var _mat: StandardMaterial3D = null

var _carpet: LeafCarpet = null
var _track: Track = null
var _idx: int = 0
var _tick: int = 0
var active: bool = false


func _ready() -> void:
	amount = MAX_LEAVES
	lifetime = 4.5
	one_shot = false
	explosiveness = 0.0
	randomness = 0.6
	local_coords = false
	fixed_fps = 30
	preprocess = 0.0
	emitting = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cutia se muta cu camera; AABB-ul de culling trebuie sa cuprinda traiectoriile.
	visibility_aabb = AABB(Vector3(-40, -14, -50), Vector3(80, 28, 100))
	process_material = _process_material()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * LEAF_SIZE
	draw_pass_1 = quad
	material_override = leaf_material()
	_find_nodes.call_deferred()


func _find_nodes() -> void:
	var n: Node = get_parent()
	while n != null:
		if n is Track:
			_track = n as Track
			break
		n = n.get_parent()
	_carpet = get_node_or_null(carpet_path) as LeafCarpet


func _process(_delta: float) -> void:
	if _track == null or _carpet == null or not _carpet.built:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	_tick += 1
	var route := _track.route_at(0)
	# Cautarea de index e incrementala si doar la fiecare al 4-lea cadru.
	if _tick % 4 == 1 or not active:
		if _tick == 1 or _idx == 0:
			_idx = route.closest_index_global(cam.global_position)
		else:
			_idx = route.closest_index(_idx, cam.global_position)
	var dist := route.dists[clampi(_idx, 0, route.baked.size() - 1)]
	var want := _carpet.zone_at_dist(dist, lead_in_m, lead_out_m) >= 0
	if want:
		var fwd := -cam.global_transform.basis.z
		fwd.y = 0.0
		fwd = fwd.normalized() if fwd.length_squared() > 1e-6 else Vector3.FORWARD
		var road_y := route.baked[clampi(_idx, 0, route.baked.size() - 1)].y
		var pos := cam.global_position + fwd * ahead_m
		pos.y = road_y + height_m
		global_position = pos
		global_rotation = Vector3(0.0, atan2(-fwd.x, -fwd.z), 0.0)
	if want != active:
		active = want
		if want:
			preprocess = lifetime
			restart()
		emitting = want


func _process_material() -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box_half
	pm.direction = Vector3(0.3, -1.0, 0.0)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 1.0
	# Cadere de frunza: viteza terminala = g / amortizare ~ 1.5 m/s, cu deriva de vant.
	pm.gravity = Vector3(1.2, -3.0, 0.4)
	pm.damping_min = 1.6
	pm.damping_max = 2.4
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	pm.angular_velocity_min = -160.0
	pm.angular_velocity_max = 160.0
	pm.scale_min = 0.7
	pm.scale_max = 1.35
	# Legaginea (turbulenta): 64 de particule, cost neglijabil.
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.4
	pm.turbulence_noise_scale = 2.5
	pm.turbulence_influence_min = 0.06
	pm.turbulence_influence_max = 0.14
	# Culoare per particula: carmin / portocaliu / ruginiu / un strop de auriu.
	var grad := Gradient.new()
	grad.set_offsets(PackedFloat32Array([0.0, 0.34, 0.68, 1.0]))
	grad.set_colors(PackedColorArray([
		LeafCarpet._class_color("maple_crimson").srgb_to_linear(),
		LeafCarpet._class_color("maple_orange").srgb_to_linear(),
		LeafCarpet._class_color("leaf_litter").srgb_to_linear(),
		Palette.color(Palette.CAR_YELLOW).srgb_to_linear()]))
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	gt.width = 64
	pm.color_initial_ramp = gt
	# Apare si se stinge moale (alfa pe viata particulei).
	var fade := Gradient.new()
	fade.set_offsets(PackedFloat32Array([0.0, 0.12, 0.8, 1.0]))
	fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)]))
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	ft.width = 32
	pm.color_ramp = ft
	return pm


## UN material pentru toate frunzele care cad (+1 pe pista), partajat.
static func leaf_material() -> StandardMaterial3D:
	if _mat != null:
		return _mat
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_mat.billboard_keep_scale = true
	_mat.vertex_color_use_as_albedo = true
	_mat.albedo_texture = leaf_texture()
	_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mat.disable_receive_shadows = true
	_mat.particles_anim_h_frames = 1
	return _mat


## Silueta de frunza de artar: stea cu 5 lobi, alfa cu cadere CONTINUA la zero.
## Generata in cod, o data (ca RangoliDecal): niciun fisier de textura nou.
static func leaf_texture() -> ImageTexture:
	if _tex != null:
		return _tex
	_tex = ImageTexture.create_from_image(_leaf_image())
	return _tex


static func _leaf_image() -> Image:
	var res := LEAF_TEX_SIZE
	var img := Image.create(res, res, true, Image.FORMAT_RGBA8)
	var half := float(res) * 0.5
	for py in res:
		for px in res:
			var dx := (float(px) + 0.5 - half) / half
			var dy := (float(py) + 0.5 - half) / half
			var r := sqrt(dx * dx + dy * dy)
			var a := atan2(dy, dx)
			# Marginea lobata: 5 lobi, raza de baza 0.78 (ramane loc pentru cadere).
			var edge_r := 0.78 * (1.0 + 0.22 * cos(5.0 * a - 1.5708))
			var d := r / edge_r
			var alpha := 0.0
			# Miez plin pana la 0.5 din raza, apoi cadere cos^2 pana la zero (panta
			# zero la capat: fara umar). 128 px: tranzitia se intinde pe ~20 px.
			if d < 0.5:
				alpha = 1.0
			elif d < 1.0:
				var c := cos((d - 0.5) * 2.0 * 1.5707963)
				alpha = c * c
			# Nervura mediana: un pic mai inchis pe axa verticala a frunzei.
			var rib := exp(-pow(dx / 0.05, 2.0)) * 0.25
			var shade := 1.0 - rib
			img.set_pixel(px, py, Color(shade, shade, shade, clampf(alpha, 0.0, 1.0)))
	img.generate_mipmaps()
	return img


## Cel mai mare salt de alfa intre doi pixeli vecini ai texturii frunzei (0..1).
## Masura de MUCHIE din `particule-muchia-nu-numarul`: sub ~0.12 = fara trepte.
static func edge_max_step() -> float:
	var img := _leaf_image()
	var res := img.get_width()
	var worst := 0.0
	for py in res:
		for px in res:
			var a := img.get_pixel(px, py).a
			if px + 1 < res:
				worst = maxf(worst, absf(a - img.get_pixel(px + 1, py).a))
			if py + 1 < res:
				worst = maxf(worst, absf(a - img.get_pixel(px, py + 1).a))
	return worst
