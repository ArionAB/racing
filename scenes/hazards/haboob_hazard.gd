@tool
class_name HaboobHazard
extends FogCorridorHazard
## HABOOB-UL (Monument Valley, Track19; brief monument_valley.md §1, §2, §3):
## un zid de praf maro, ~50 m inaltime si ~400 m latime, care traverseaza valea
## pe un `Path3D`, pe un ciclu de ~101 s care NU imparte durata turului.
##
## [b]Reuse[/b] [FogCorridorHazard] (ceata doar pentru jucator, restaurare
## exacta la iesire) cu [CloudRiseHazard] ca tipar de ceas (`period`, `phase`,
## `cover_at`, `set_cycle_time`). Ce e nou: zidul SE MISCA, deci zona nu mai e
## cutia fixa de 8 m a culoarului, ci volumul zidului, care merge odata cu el.
##
## [b]Conventia culoarului, mutata pe zid.[/b] Nodul `_wall` are -Z local pe
## directia de mers, `length` = adancimea zidului (60-80 m) si `half_width` =
## jumatate din latime. Adancimea in zid se masoara ca la culoar
## (`length*0.5 - local.z`), deci `_ramp`, `ramp_in`, `ramp_out` si ceata
## mostenite merg neschimbate: rampa de la front e `ramp_in`.
##
## [b]Ceasul e deterministic[/b]: `_time` creste cu `delta` din
## `_physics_process`, iar pozitia frontului e o FUNCTIE de timpul din ciclu
## (`front_distance_at`), nu o viteza integrata care deriva.
##
## [b]Faza de start (memoria `ceasul-porneste-in-prima-faza`).[/b] Ciclul e
## telegraf -> traversare -> risipire -> liniste. La t=0 al cursei zidul trebuie
## sa fie in LINISTE, nu in telegraf: `start_clock` implicit pica in coada
## risipirii, unde `cover == 0`. Verifica pe captura (`--haboob-at=`), nu doar
## pe cifra.
##
## [b]Pedeapsa[/b] (de la 0 la plin, pe `amount` = rampa pe adancime x
## acoperirea zidului): ceata jucatorului (mostenita), `Car.blind()` o singura
## data la trecerea frontului (doar jucator), vant lateral pe TOATE masinile din
## zid, aplicat local ca forta (`apply_central_force(wind * mass)`), nu prin
## `Track.wind_at`. AI-ul isi scade tinta de viteza cu `ai_speed_factor` in
## miezul zidului prin grupul `ai_speed_zones` (vezi `AIController`): fara
## viteza trisata, fara vedere speciala.
##
## [b]Randare[/b]: 3 quad-uri verticale moi (un singur material partajat, ca
## `cloud_material()`), `distance_fade` aproape de camera, plus <= 32 de
## particule de praf (al doilea material partajat). Fara umbre. Tumbleweeds:
## doar vizuale, fara coliziune.

const TUMBLEWEED_MODEL: String = "res://assets/models/monumentvalley/plants/tumbleweed.glb"
## Grupul prin care AIController afla ca exista o zona de viteza redusa. Metoda
## ceruta: `ai_speed_scale_at(pos: Vector3) -> float`.
const AI_SPEED_GROUP: StringName = &"ai_speed_zones"

@export_group("Ciclu")
## Durata ciclului (s). Brief: ~101, NU divizor al turului (~70 s).
@export_range(20.0, 300.0, 0.5) var period: float = 101.0
## Telegraful: pacla creste la orizont, zidul se apropie (s).
@export_range(1.0, 120.0, 0.5) var telegraph_time: float = 25.0
## Traversarea: zidul e plin (s).
@export_range(1.0, 200.0, 0.5) var cross_time: float = 55.0
## Risipirea (s), din care primii `dissipate_fade` coboara acoperirea; restul
## pana la sfarsitul ciclului e LINISTE (cover = 0).
@export_range(1.0, 120.0, 0.5) var dissipate_time: float = 21.0
@export_range(0.5, 120.0, 0.5) var dissipate_fade: float = 15.0
## Unde in ciclu (s) incepe cursa. Implicit in coada risipirii, in liniste.
@export_range(0.0, 300.0, 0.5) var start_clock: float = 96.0
## Decalajul ciclului (0..1 din period), peste `start_clock`.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0
## >= 0: ceasul e FIX la valoarea asta (snapshot/sonde); nu mai avanseaza.
var force_clock: float = -1.0

@export_group("Zid")
## Viteza frontului pe `Path3D` (m/s). Brief: 6-8.
@export_range(1.0, 20.0, 0.1) var wall_speed: float = 7.0
## Inaltimea zidului (m). Brief: ~50.
@export_range(5.0, 120.0, 1.0) var wall_height: float = 50.0
## Pe cati metri de la marginea laterala se subtiaza efectul (ceata/vant).
@export_range(0.0, 100.0, 1.0) var edge_ramp: float = 30.0
## Cate quad-uri verticale (2-3).
@export_range(2, 3) var quad_count: int = 3
## Cate particule de praf (<= 32).
@export_range(0, 32) var dust_count: int = 32

@export_group("Vant")
## Acceleratia laterala a vantului in zid (m/s^2), cu rafale intre cele doua.
## Pe asfalt grip-ul lateral mananca vantul: 2,5-3,5 dadea doar +0,2 m/s lateral
## (masurat pe ProbeHaboob), 12 m/s^2 da ~+0,7 m/s si ~1,5 m deplasare.
@export_range(0.0, 40.0, 0.1) var wind_min: float = 10.0
@export_range(0.0, 40.0, 0.1) var wind_max: float = 14.0

@export_group("Efecte asupra masinii")
## Albirea de la trecerea frontului, doar jucator (s).
@export_range(0.0, 2.0, 0.05) var blind_seconds: float = 0.3
## Pragul de intrare (amount) la care se declanseaza albirea.
@export_range(0.01, 0.5, 0.01) var blind_threshold: float = 0.1
## AI: multiplicatorul tintei de viteza in miezul zidului (0.9 = -10%).
@export_range(0.5, 1.0, 0.01) var ai_speed_factor: float = 0.90
## AI: de la ce `amount` se simte (netezit in jurul valorii).
@export_range(0.1, 0.9, 0.05) var ai_core_amount: float = 0.5

@export_group("Tumbleweeds")
@export_range(0, 8) var tumbleweed_count: int = 6
@export var tumbleweed_model: PackedScene = null
## Diametrul (m); modelul se masoara si se scaleaza la el.
@export_range(0.5, 4.0, 0.1) var tumbleweed_diameter: float = 1.6
## Cat de departe (lateral, m) de centrul zidului se rostogolesc.
@export_range(10.0, 200.0, 1.0) var tumbleweed_spread: float = 110.0
## Cat de departe in fata frontului ajung (m): [min, max].
@export var tumbleweed_ahead: Vector2 = Vector2(14.0, 80.0)

var _wall: Node3D
var _quads: Array[MeshInstance3D] = []
var _dust: CPUParticles3D
var _audio: AudioStreamPlayer3D
var _weeds: Array[Node3D] = []
var _path: Path3D
var _time: float = 0.0
var _started: bool = false
var _cover: float = 0.0
var _front_s: float = 0.0
var _inside: Dictionary = {}
var _weed_ground_y: float = 0.0
static var _wall_material: StandardMaterial3D
static var _dust_material: StandardMaterial3D


func _init() -> void:
	# Valorile de haboob. Setate in `_init` ca o scena sa le poata suprascrie.
	length = 70.0
	half_width = 200.0
	ramp_in = 20.0
	ramp_out = 15.0
	fog_begin_inside = 4.0
	fog_end_inside = 35.0
	fog_density_inside = 0.05
	fog_color = Color(0.659, 0.404, 0.243) # #A8673E


func _ready() -> void:
	_ensure_path()
	super()
	if not Engine.is_editor_hint():
		add_to_group(AI_SPEED_GROUP)
		_start_roar()


# -------------------------------------------------------------- constructie

## `_rebuild` mostenit sterge TOTI copiii (inclusiv `Path3D`-ul pe care
## designerul il trage in editor): aici se sterge doar ce a construit hazardul.
func _rebuild() -> void:
	if not is_inside_tree():
		return
	_free_wall()
	_wall = Node3D.new()
	_wall.name = "Wall"
	add_child(_wall)
	_build_zone()
	_build_visuals()
	_build_markers()


func _free_wall() -> void:
	if _wall != null and is_instance_valid(_wall):
		remove_child(_wall)
		_wall.queue_free()
	_wall = null
	_zone = null
	_quads.clear()
	_weeds.clear()
	_dust = null
	_audio = null


## Zona = volumul zidului, copil al nodului care se misca. Ca la culoar: fara
## masca proprie, nu `monitorable` (raporteaza cine e inauntru, nu opreste).
func _build_zone() -> void:
	_zone = Area3D.new()
	_zone.name = "HaboobZone"
	_zone.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half_width * 2.0, wall_height + 10.0, length)
	shape.shape = box
	shape.position = Vector3.UP * (wall_height * 0.5)
	_zone.add_child(shape)
	_wall.add_child(_zone)


## Fara repere: zidul nu e un culoar permanent.
func _build_markers() -> void:
	pass


## Un `Path3D` cu numele "Path" cautat intre copii; daca lipseste (sonda,
## scena goala) se face unul drept, spre -Z local, destul de lung cat sa
## acopere un ciclu intreg.
func _ensure_path() -> void:
	_path = get_node_or_null(^"Path") as Path3D
	if _path != null or Engine.is_editor_hint():
		return
	_path = Path3D.new()
	_path.name = "Path"
	var curve := Curve3D.new()
	var reach := wall_speed * (telegraph_time + cross_time) + 20.0
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, -reach))
	_path.curve = curve
	add_child(_path)


static func wall_material() -> StandardMaterial3D:
	if _wall_material == null:
		var w := 256
		var h := 128
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var low := Color(0.659, 0.404, 0.243)
		var high := Color(0.851, 0.620, 0.420) # mai deschis sus
		for x in w:
			var u := float(x) / float(w - 1)
			# Marginea de sus nu e o linie: ondulata, ca un nor de praf.
			var top := 0.90 + 0.06 * sin(u * 19.0 + 1.3) + 0.04 * sin(u * 47.0 + 0.4)
			var side := smoothstep(0.0, 0.10, u) * smoothstep(0.0, 0.10, 1.0 - u)
			for y in h:
				var v := 1.0 - float(y) / float(h - 1) # 0 jos, 1 sus
				var up := 1.0 - smoothstep(top - 0.16, top, v)
				var foot := lerpf(0.8, 1.0, smoothstep(0.0, 0.08, v))
				var a := side * up * foot
				var c := low.lerp(high, smoothstep(0.1, 0.95, v))
				img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.albedo_texture = ImageTexture.create_from_image(img)
		m.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
		# Aproape de camera zidul se topeste: inauntru nu te inconjoara o
		# panza opaca, ceata mediului face treaba.
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		m.distance_fade_min_distance = 5.0
		m.distance_fade_max_distance = 40.0
		# Fara asta, planul vertical taie soseaua intr-o linie dreapta (vazut pe
		# captura din interior). Proximity fade o topeste pe ~4 m. Cost de masurat
		# pe device: citeste textura de adancime.
		m.proximity_fade_enabled = true
		m.proximity_fade_distance = 4.0
		_wall_material = m
	return _wall_material


static func dust_material() -> StandardMaterial3D:
	if _dust_material == null:
		var grad := Gradient.new()
		grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		grad.add_point(0.35, Color(1.0, 1.0, 1.0, 0.7))
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 1.0)
		tex.width = 64
		tex.height = 64
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = tex
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		m.distance_fade_min_distance = 4.0
		m.distance_fade_max_distance = 30.0
		_dust_material = m
	return _dust_material


func _build_visuals() -> void:
	# --- quad-urile zidului: fata, mijloc, spate (in cadrul zidului)
	var zs: Array[float] = [-length * 0.5, -length * 0.05, length * 0.40]
	for i in quad_count:
		var q := MeshInstance3D.new()
		q.name = "Quad%d" % i
		var quad := QuadMesh.new()
		quad.size = Vector2(half_width * 2.0, wall_height)
		q.mesh = quad
		q.material_override = wall_material()
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.position = Vector3(0.0, wall_height * 0.5 - 2.0, zs[i] if quad_count == 3 else (zs[0] if i == 0 else zs[2]))
		_wall.add_child(q)
		_quads.append(q)
	# --- praful: <= 32 particule pe fata zidului
	if dust_count > 0:
		_dust = CPUParticles3D.new()
		_dust.name = "Dust"
		_dust.amount = mini(dust_count, 32)
		_dust.lifetime = 4.0
		_dust.local_coords = false
		_dust.emitting = false
		_dust.preprocess = 4.0
		var pm := QuadMesh.new()
		pm.size = Vector2(22.0, 22.0)
		pm.material = dust_material()
		_dust.mesh = pm
		_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		_dust.emission_box_extents = Vector3(minf(half_width, 140.0), wall_height * 0.35, 6.0)
		_dust.position = Vector3(0.0, wall_height * 0.35, -length * 0.5)
		_dust.direction = Vector3(0.0, 0.15, -1.0)
		_dust.spread = 12.0
		_dust.initial_velocity_min = 3.0
		_dust.initial_velocity_max = 7.0
		_dust.gravity = Vector3.ZERO
		_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ramp := Gradient.new()
		ramp.set_color(0, Color(fog_color.r, fog_color.g, fog_color.b, 0.0))
		ramp.set_color(1, Color(fog_color.r, fog_color.g, fog_color.b, 0.0))
		ramp.add_point(0.3, Color(fog_color.r, fog_color.g, fog_color.b, 0.38))
		ramp.add_point(0.7, Color(fog_color.r, fog_color.g, fog_color.b, 0.38))
		_dust.color_ramp = ramp
		_wall.add_child(_dust)
	# --- tumbleweeds (doar vizuale). Deferit: copiii isi fac `_ready` INAINTE de
	# parinte, deci pe pista, la acest moment Palette n-are inca tema (memoria
	# `decor-ready-inaintea-temei`): prima chemare `world_material()` esua
	# (D3D12 CreateResource) si clasele ramaneau fara textura de detaliu.
	_build_weeds.call_deferred(_wall)
	# --- vuietul
	_audio = AudioStreamPlayer3D.new()
	_audio.name = "Roar"
	_audio.bus = &"SFX"
	_audio.max_distance = 320.0
	_audio.unit_size = 40.0
	_audio.position = Vector3(0.0, 8.0, -length * 0.5)
	_wall.add_child(_audio)


func _build_weeds(wall: Node3D) -> void:
	if wall != _wall or _wall == null or not is_instance_valid(_wall):
		return
	var scene := tumbleweed_model if tumbleweed_model != null \
		else load(TUMBLEWEED_MODEL) as PackedScene
	if scene == null or tumbleweed_count <= 0:
		return
	for i in tumbleweed_count:
		var piece := scene.instantiate() as Node3D
		if piece == null:
			continue
		var box := _model_bounds(piece)
		var size := maxf(maxf(box.size.x, box.size.y), box.size.z)
		var sc := tumbleweed_diameter / maxf(size, 0.01)
		piece.scale = Vector3.ONE * sc
		# Centrul geometric in originea suportului: se roteste in jurul lui.
		piece.position = -(box.position + box.size * 0.5) * sc
		Palette.apply_object_class_materials(piece, WorldProp.prop_classes(), sc)
		var holder := Node3D.new()
		holder.name = "Tumbleweed%d" % i
		holder.visible = false
		holder.add_child(piece)
		_wall.add_child(holder)
		_weeds.append(holder)


## AABB-ul reuniunii mesh-urilor (in cadrul piesei, fara transformarile
## copiilor — suficient pentru un GLB cu un singur nivel).
func _model_bounds(node: Node) -> AABB:
	var out := AABB()
	var first := true
	for child in _walk(node):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var b := mi.transform * mi.mesh.get_aabb() if mi != node else mi.mesh.get_aabb()
		out = b if first else out.merge(b)
		first = false
	if first:
		return AABB(Vector3.ZERO, Vector3.ONE)
	return out


func _start_roar() -> void:
	# Prin arbore, nu prin identificatorul de autoload (memoria
	# `godot-headless-gotchas`: in `--script` identificatorul nu compileaza).
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager == null or _audio == null:
		return
	var stream: AudioStream = manager.call("stream", &"typhoon_roar")
	if stream != null:
		_audio.stream = stream
		_audio.volume_db = -80.0


# -------------------------------------------------------------------- ceas

## Acoperirea 0..1 la momentul t din ciclu: telegraful o ridica, traversarea o
## tine plina, risipirea o coboara pe primii `dissipate_fade` s, apoi liniste.
func cover_at(t: float) -> float:
	if t < telegraph_time:
		return smoothstep(0.0, 1.0, t / telegraph_time)
	if t < telegraph_time + cross_time:
		return 1.0
	var falling := t - telegraph_time - cross_time
	if falling < minf(dissipate_fade, dissipate_time):
		return 1.0 - smoothstep(0.0, 1.0, falling / minf(dissipate_fade, dissipate_time))
	return 0.0


## Distanta frontului (m, pe `Path3D`) la momentul t din ciclu. Functie de timp,
## nu viteza integrata: doua rulari dau aceleasi cifre. Dupa traversare ramane la
## capat (cat se risipeste), iar in liniste e ascuns.
func front_distance_at(t: float) -> float:
	return wall_speed * minf(maxf(t, 0.0), telegraph_time + cross_time)


func cycle_time() -> float:
	return fposmod(_time, period)


## Aduce ceasul la momentul t din ciclu si aseaza zidul (snapshot --haboob-at).
func set_cycle_time(t: float) -> void:
	_started = true
	_time = t
	_update_clock_state()


func cover() -> float:
	return _cover


func wall() -> Node3D:
	return _wall


func weeds() -> Array[Node3D]:
	return _weeds


func quads() -> Array[MeshInstance3D]:
	return _quads


func _update_clock_state() -> void:
	var t := fposmod(_time, period)
	_cover = cover_at(t)
	_front_s = front_distance_at(t)
	_place_wall()
	_place_weeds(t)


## Zidul pe `Path3D`: centrul la `_front_s`, cu -Z pe tangenta (orizontala).
func _place_wall() -> void:
	if _wall == null:
		return
	var vis := _cover > 0.002
	_wall.visible = vis
	var p_local := Vector3.ZERO
	var dir_local := Vector3(0.0, 0.0, -1.0)
	var xf := global_transform
	if _path != null and _path.curve != null and _path.curve.point_count >= 2:
		var curve := _path.curve
		var plen := curve.get_baked_length()
		var s := clampf(_front_s, 0.0, plen)
		p_local = curve.sample_baked(s)
		var s2 := minf(s + 1.0, plen)
		var s1 := maxf(s2 - 1.0, 0.0)
		dir_local = (curve.sample_baked(s2) - curve.sample_baked(s1))
		xf = _path.global_transform
	var pos := xf * p_local
	var dir := xf.basis * dir_local
	dir.y = 0.0
	if dir.length() < 0.001:
		dir = Vector3(0.0, 0.0, -1.0)
	dir = dir.normalized()
	_wall.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), pos)
	# Zidul creste cu acoperirea: pacla de la orizont se ridica.
	var grow := lerpf(0.35, 1.0, _cover)
	var alpha := clampf(_cover, 0.0, 1.0)
	for q in _quads:
		q.scale = Vector3(1.0, grow, 1.0)
		q.position.y = wall_height * 0.5 * grow - 2.0
		q.transparency = 1.0 - alpha
	if _dust != null:
		var want := _cover > 0.05
		if want and not _dust.emitting:
			# `preprocess` + `restart`: praful apare deja raspandit din primul cadru
			# (snapshot --haboob-at nu mai asteapta cateva secunde de simulare).
			_dust.emitting = true
			_dust.restart()
		elif not want and _dust.emitting:
			_dust.emitting = false
	if _audio != null and _audio.stream != null:
		if _cover > 0.02:
			_audio.volume_db = lerpf(-28.0, -4.0, _cover)
			if not _audio.playing:
				_audio.play()
		elif _audio.playing:
			_audio.stop()


## Tumbleweeds in fata frontului: pozitie si rotatie ca functii de timp.
func _place_weeds(t: float) -> void:
	var n := _weeds.size()
	if n == 0 or _wall == null:
		return
	var show := _cover > 0.05
	var gy := _ground_y_ahead()
	for i in n:
		var w := _weeds[i]
		w.visible = show
		if not show:
			continue
		var frac := fposmod(float(i) / float(n) + t * 0.045, 1.0)
		var ahead := lerpf(tumbleweed_ahead.x, tumbleweed_ahead.y, frac)
		var lat := sin(float(i) * 12.9898 + 1.7) * tumbleweed_spread
		var r := tumbleweed_diameter * 0.5
		var hop := absf(sin(t * 2.2 + float(i) * 1.9)) * 0.35
		w.position = Vector3(lat, gy + r + hop, -length * 0.5 - ahead)
		# Se rostogolesc spre directia de mers (-Z): rotatie in jurul lui X.
		w.rotation = Vector3(-(_front_s + ahead * 2.0 + float(i) * 3.0) / r, 0.0, float(i))
		var fade := smoothstep(0.0, 0.12, frac) * smoothstep(0.0, 0.12, 1.0 - frac)
		w.scale = Vector3.ONE * clampf(fade, 0.01, 1.0)


## Cota solului in fata frontului, in cadrul zidului. Raza se arunca doar de
## cateva ori pe secunda si se tine minte; o lovitura de masina nu o strica.
func _ground_y_ahead() -> float:
	if _wall == null or not _wall.is_inside_tree() or not is_inside_tree():
		return 0.0
	var space := _wall.get_world_3d().direct_space_state if _wall.get_world_3d() != null else null
	if space == null:
		return _weed_ground_y
	var from := _wall.to_global(Vector3(0.0, 60.0, -length * 0.5 - 40.0))
	var to := _wall.to_global(Vector3(0.0, -60.0, -length * 0.5 - 40.0))
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var hit := space.intersect_ray(q)
	if hit.is_empty() or hit.get("collider") is Car:
		return _weed_ground_y
	_weed_ground_y = _wall.to_local(hit["position"]).y
	return _weed_ground_y


# --------------------------------------------------------------- fizica

## Cat de „in zid" e un punct (0..1): rampa pe adancime de la front, subtiata la
## marginile laterale, inmultita cu acoperirea. In afara zidului 0.
func amount_at(pos: Vector3) -> float:
	if _wall == null or _cover <= 0.001 or not _wall.is_inside_tree():
		return 0.0
	var local := _wall.global_transform.affine_inverse() * pos
	if local.y > wall_height or local.y < -30.0:
		return 0.0
	var depth := length * 0.5 - local.z
	var a := _ramp(depth)
	if a <= 0.0:
		return 0.0
	var lat := half_width - absf(local.x)
	if lat <= 0.0:
		return 0.0
	a *= 1.0 if edge_ramp <= 0.01 else clampf(lat / edge_ramp, 0.0, 1.0)
	return a * _cover


## Directia vantului = directia de mers a zidului (orizontala, in lume).
func wind_direction() -> Vector3:
	if _wall == null:
		return Vector3(0.0, 0.0, -1.0)
	var d := -_wall.global_transform.basis.z
	d.y = 0.0
	return d.normalized() if d.length() > 0.001 else Vector3(0.0, 0.0, -1.0)


## Acceleratia vantului acum (m/s^2): intre `wind_min` si `wind_max`, cu rafale
## deterministe (functie de timpul din ciclu). Suprascrisa de sonda de sabotaj.
func _wind_accel() -> float:
	var t := fposmod(_time, period)
	var g := clampf(0.5 + 0.5 * (0.6 * sin(t * 2.3) + 0.4 * sin(t * 5.1 + 1.3)), 0.0, 1.0)
	return lerpf(wind_min, wind_max, g)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if force_clock >= 0.0:
		_started = true
		_time = force_clock
	elif not _started:
		_started = true
		_time = start_clock + phase * period
	else:
		_time += delta
	_update_clock_state()
	if _zone != null and _cover > 0.01:
		_affect_cars()
	elif not _inside.is_empty():
		_inside.clear()
	super(delta)


func _affect_cars() -> void:
	var dir := wind_direction()
	var accel := _wind_accel()
	var present: Dictionary = {}
	for body in _zone.get_overlapping_bodies():
		var car := body as Car
		if car == null:
			continue
		var amount := amount_at(car.global_position)
		if amount <= 0.0:
			continue
		var id := car.get_instance_id()
		present[id] = true
		# Vantul: acceleratie (forta * masa), doar cu rotile pe sol — in aer ar
		# fi inca un mecanism de zbor (acelasi motiv ca la vantul temei).
		if accel > 0.0 and car.wheels_on_ground > 0:
			car.apply_central_force(dir * accel * amount * car.mass)
		# Albirea: o data pe trecere, doar jucator, la trecerea frontului.
		if car.is_player and amount >= blind_threshold and not _inside.has(id):
			_inside[id] = true
			if blind_seconds > 0.0:
				car.blind(blind_seconds)
		elif amount < 0.02:
			_inside.erase(id)
	for id in _inside.keys():
		if not present.has(id):
			_inside.erase(id)


## Cat de „in ceata" e masina jucatorului, 0..1 (suprascrie culoarul).
func _depth_amount() -> float:
	if _zone == null or _cover <= 0.001 or not _zone.monitoring:
		return 0.0
	var best := 0.0
	for body in _zone.get_overlapping_bodies():
		var car := body as Car
		if car == null or not car.is_player:
			continue
		best = maxf(best, amount_at(car.global_position))
	return best


## Carligul AI-ului (grupul `ai_speed_zones`): cu cat se inmulteste tinta de
## viteza a unei masini AI aflate la `pos`. 1.0 in afara miezului.
func ai_speed_scale_at(pos: Vector3) -> float:
	var a := amount_at(pos)
	if a <= 0.0:
		return 1.0
	var k := smoothstep(ai_core_amount - 0.15, ai_core_amount + 0.15, a)
	return lerpf(1.0, ai_speed_factor, k)
