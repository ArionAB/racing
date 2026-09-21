class_name RainScreen
extends GPUParticles3D
## PLOAIA PE ECRAN (Fiordland, docs/track_briefs/fiordland.md §2.0 „Ploaia
## trebuie sa se vada ca vine", §3 „ploaie pe ecran", §6 overdraw).
##
## Un singur emitator de dare verticale care URMEAZA CAMERA ACTIVA (nu masina):
## cutia de emisie sta in fata camerei, picaturile cad in coordonate de LUME
## (`local_coords = false`), deci masina trece prin ele si ele curg pe langa
## camera, nu odata cu ea. Urmarim `get_viewport().get_camera_3d()`, nu
## `ChaseCamera`: si Snapshot (camera proprie, `--gamecam`) si jocul trebuie sa
## vada aceeasi ploaie, altfel captura ar minti (memoria
## `unealta-de-captura-e-parte-din-masuratoare`).
##
## Intensitatea NU e `emitting` on/off (ar sari): e `amount_ratio`, condusa de
## `RainCycle` prin `set_intensity()` cu `rain_factor`-ul lui. Pe uscat nodul e
## `visible = false` si nu emite — ZERO desene in cadru (brief §6: sprite-urile
## de ploaie sunt primul strat care se taie pe device).
##
## Dara = QuadMesh alungit, billboard pe axa Y (`BILLBOARD_FIXED_Y`) ca sa
## ramana verticala din orice unghi, cu textura generata in cod: alfa care
## cade CONTINUU la zero pe ambele axe (memoria `particule-muchia-nu-numarul`:
## muchia dura, nu numarul, face particula sa citeasca „obiect"). Un singur
## material static pentru toate instantele: +1 material pe pista, bugetat.

## Cate dare cel mult (brief: ≤ 400). `amount_ratio` reduce de aici.
const COUNT: int = 400
## Cutia de emisie (m), centrata in fata camerei.
const BOX: Vector3 = Vector3(20.0, 12.0, 20.0)
## Cat de mult in fata camerei (pe orizontala) sta centrul cutiei.
const AHEAD_M: float = 8.0
## Cat peste camera sta centrul cutiei: picaturile trebuie sa PORNEASCA
## deasupra cadrului si sa treaca prin el.
const UP_M: float = 2.0
## Viteza de cadere (m/s), ~terminala pentru picaturi mari; gravitatie zero,
## deja la viteza constanta.
const FALL_SPEED: float = 12.0
## Peste ce salt al emitatorului intre doua cadre (m) se re-umple cutia prin
## `restart()` + `preprocess`: la teleportare (start de cursa, camera pusa de
## Snapshot dupa ce ploaia e fortata) picaturile vechi raman in urma in lume
## si cadrul ar fi gol o secunda.
const JUMP_RESTART_M: float = 15.0
## Textura darei: lata x inalta (pixeli). Mica: e doar un gradient de alfa.
const TEX_W: int = 16
const TEX_H: int = 64

static var _material: StandardMaterial3D = null

var _last_center: Vector3 = Vector3.INF
## Cat mai tine nodul vizibil dupa ce intensitatea a ajuns la 0, ca ultimele
## picaturi sa-si termine viata in loc sa dispara dintr-odata.
var _hide_left: float = -1.0


static func streak_material() -> StandardMaterial3D:
	if _material == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.billboard_keep_scale = true
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.albedo_texture = _streak_texture()
		m.disable_fog = false
		_material = m
	return _material


## Alfa: cos^2 pe latime, sin^1.3 pe inaltime — zero exact la margine, fara
## umar (un smoothstep lasa o treapta vizibila la r=1, vezi memoria).
static func _streak_texture() -> ImageTexture:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	for y in TEX_H:
		var v := (float(y) + 0.5) / float(TEX_H)
		var ay := pow(sin(PI * v), 1.3)
		for x in TEX_W:
			var u := (float(x) + 0.5) / float(TEX_W)
			var c := cos(PI * (u - 0.5))
			var ax := c * c
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, ax * ay))
	return ImageTexture.create_from_image(img)


func _init() -> void:
	name = "RainScreen"
	amount = COUNT
	amount_ratio = 0.0
	lifetime = 1.0
	preprocess = 1.0
	explosiveness = 0.0
	randomness = 0.3
	local_coords = false
	emitting = false
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# AABB in spatiul nodului: nodul se muta cu camera, deci camera e mereu
	# inauntru si emitatorul nu e niciodata taiat de culling. Coboara mai mult
	# decat cutia: picaturile emise jos mai cad 12 m pana mor.
	visibility_aabb = AABB(
		Vector3(-BOX.x * 0.5 - 4.0, -BOX.y * 0.5 - FALL_SPEED * lifetime - 2.0,
			-BOX.z * 0.5 - 4.0),
		Vector3(BOX.x + 8.0, BOX.y + FALL_SPEED * lifetime + 4.0, BOX.z + 8.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = BOX * 0.5
	# Putin vant: directia nu e perfect verticala. Dara ramane verticala pe
	# ecran (billboard FIXED_Y), vantul se vede in DERIVA picaturilor.
	pm.direction = Vector3(0.10, -1.0, 0.04).normalized()
	pm.spread = 1.5
	pm.initial_velocity_min = FALL_SPEED * 0.85
	pm.initial_velocity_max = FALL_SPEED * 1.1
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	# FOAM_WHITE (brief §4: singurul alb curat din decor), cu alfa: dara e
	# translucida, se citeste pe peretele intunecat, nu arde cerul.
	var foam := Palette.color(Palette.FOAM_WHITE)
	pm.color = Color(foam.r, foam.g, foam.b, 0.62)
	# Intra si iese din viata pe alfa, nu pe pocnet.
	var fade := Gradient.new()
	fade.set_offsets(PackedFloat32Array([0.0, 0.10, 0.85, 1.0]))
	fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.0)]))
	var fade_tex := GradientTexture1D.new()
	fade_tex.gradient = fade
	pm.color_ramp = fade_tex
	process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.9)
	quad.material = streak_material()
	draw_pass_1 = quad


func _process(delta: float) -> void:
	if not visible:
		return
	if not emitting and _hide_left >= 0.0:
		_hide_left -= delta
		if _hide_left <= 0.0:
			visible = false
			_hide_left = -1.0
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var fwd := -cam.global_basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 1e-4:
		fwd = Vector3.FORWARD
	var center := cam.global_position + fwd.normalized() * AHEAD_M + Vector3.UP * UP_M
	var jumped := _last_center == Vector3.INF \
		or center.distance_to(_last_center) > JUMP_RESTART_M
	global_position = center
	_last_center = center
	if jumped and emitting:
		# Re-umple cutia la noua pozitie (preprocess = lifetime).
		restart()


## 0 = nicio picatura (nodul dispare din cadru dupa ce mor ultimele),
## 1 = ploaie plina. Continuu prin `amount_ratio`, nu prin emitting on/off.
func set_intensity(f: float) -> void:
	f = clampf(f, 0.0, 1.0)
	if f <= 0.0001:
		if emitting:
			emitting = false
			_hide_left = lifetime
		amount_ratio = 0.0
		return
	if not visible:
		visible = true
	_hide_left = -1.0
	amount_ratio = f
	if not emitting:
		emitting = true
