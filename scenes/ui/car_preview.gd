class_name CarPreview
extends SubViewportContainer
## Vitrina 3D a garajului: masina selectata, pe un podium care se roteste.
##
## NU foloseste scena `Car`: aia e un RigidBody3D cu suspensie pe raycast,
## colizor si `_physics_process` — in garaj n-avem sol, n-avem roti pe care sa
## le apese nimic, si un corp fizic lasat sa cada ar trece prin podium. Aici se
## instantiaza DOAR modelul din `CarData.model`, cu aceleasi reguli de material
## ca in cursa (`Palette.apply_world_material` pe GLB-urile noastre), plus
## figurina soferului asezata la `driver_seat`.
##
## Figurina se instantiaza direct, nu prin clasa `Driver`: aceea cere un `Car`
## proprietar si isi anima bratele din viteza masinii in `_physics_process`.
## Fara masina, ar fi fost null-check-uri pe fiecare cadru pentru nimic.

## Marja peste gabaritul masinii, la incadrare. 1.0 ar lipi caroseria de
## marginile cadrului; peste asta intra rollbar-ul, scaunele si figurina
## soferului, care ies deasupra lui `body_length` si nu sunt masurate nicaieri
## in CarData.
## Cat aer lasa incadrarea in jurul masinii.
##
## 1.22 e rezultatul a doua corecturi, amandoua masurate prin proiectie pe
## ecran (tools/ProbeGarage.tscn), nu reglate din ochi:
##   1.12 — corect cat vitrina avea fundal gol, dar cu atelierul in jur masina
##          atingea marginea de jos si podiumul nu se vedea deloc;
##   1.42 — prea larg: masina ajungea sa ocupe 16% din latimea cadrului
##          (u 0.418..0.582), adica subiectul devenea o jucarie in mijlocul
##          unei camere goale.
const FRAME_MARGIN := 1.22
## Inaltimea podiumului. Masina sta pe fata lui de sus, deci si camera tinteste
## de la cota asta in sus.
const PODIUM_H := 0.22
## Unghiul de coborare al camerei. Trei-sferturi de sus, ca in macheta: vede
## capota, parbrizul si soferul deodata. Camera de cursa sta la 28.7°, dar aia
## urmareste o masina care merge — aici obiectul e expus, nu condus.
##
## 26°, nu 18°: cu atelierul in jur, o camera prea joasa priveste pe SUB cutie.
## Masurat pe captura la 18° — podeaua umplea jumatatea de jos a vitrinei si
## peretele din fund iesea din cadru.
const CAM_PITCH_DEG := 26.0
const SPIN_SPEED_DEG := 22.0
## Unghiul de start, in spatiul PIVOTULUI. Camera priveste dinspre +Z, iar
## modelul e rotit 180° in `show_car` (GLB-urile privesc spre +Z, fata Godot e
## -Z) — deci un pivot la 0 arata SPATELE masinii, cum a si iesit la captura.
## 180° readuce botul spre camera, iar cele 32° in plus dau trei-sferturile.
const START_YAW_DEG := 212.0

## Plafonul de randare al vitrinei. Latura mare nu trece de atat, oricat de
## mare ar fi panoul: modelele sunt low-poly si pe un ecran 2x am fi randat
## degeaba. PROPORTIA insa urmeaza containerul — daca viewportul ar ramane
## fix 4:3 intr-un container inalt, incadrarea ar calcula pe un aspect fals si
## masina ar iesi din cadru.
const VIEW_MAX := 960.0

var _viewport: SubViewport
var _pivot: Node3D          # se roteste; masina atarna de el
var _camera: Camera3D
var _model_root: Node3D
var _podium: MeshInstance3D
var _yaw: float = deg_to_rad(START_YAW_DEG)
## Ultima masina aratata — ca sa se poata REINCADRA cand se schimba forma
## vitrinei (rotirea telefonului, alt raport de ecran) fara sa se reconstruiasca
## modelul.
var _data: CarData


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(int(VIEW_MAX), int(VIEW_MAX * 0.75))
	# Vitrina e o INCAPERE acum, nu o masina pe fundal gol: peretii umplu
	# cadrul, deci n-avem nevoie de alfa. Si e esential ca n-o cerem —
	# `transparent_bg` schimba modul in care viewportul isi face clear-ul, iar
	# `BG_CANVAS` de pe environment devine inoperant.
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)

	var world := Node3D.new()
	_viewport.add_child(world)

	_pivot = Node3D.new()
	world.add_child(_pivot)

	_camera = Camera3D.new()
	_camera.fov = 38.0 # teleobiectiv usor: aplatizeaza perspectiva, ca intr-o
	                   # fotografie de macheta. 68° (camera de cursa) ar fi
	                   # umflat botul si ar fi facut masina sa para un camion.
	world.add_child(_camera)

	_build_lighting(world)
	_build_atelier(world)
	_build_podium(world)
	resized.connect(_on_resized)


## Lumina vitrinei: aceeasi geometrie ca in style_bible §5 (soare din
## stanga-sus la 42°, ambient rece, bounce cald), ca masina sa se citeasca la
## fel ca pe pista.
##
## Aici soarele ARUNCA umbre, spre deosebire de prima versiune. Motivul e cel
## din CLAUDE.md (abaterea asumata de la blob shadows): fara contact cu solul,
## orice obiect pare lipit peste fundal. Pe pista comutatorul exista fiindca
## 60 fps pe mid-range e in joc; aici nu e — garajul randeaza O masina, fara
## pista, fara AI si fara fizica, pe un viewport de cel mult 960 px. Cascada e
## scurta (12 m) fiindca atat masoara cutia atelierului: o cascada lunga ar
## imprastia aceeasi rezolutie de umbra pe un volum care nu exista.
func _build_lighting(world: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 135, 0)
	sun.light_color = Color("#FFD6A3")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = 		DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 26.0
	sun.shadow_blur = 1.4
	# Bias-ul: fara el, cutiile isi pun o dunga neagra pe propria talpa (acne);
	# cu prea mult, umbra se desprinde de obiect pana dispare. 1.1 (implicitul
	# pentru scene de PISTA, unde cascada acopera 90 m) stergea complet umbra
	# masinii pe o cascada de 26 m — contactul cu solul, adica exact motivul
	# pentru care s-au pornit umbrele, lipsea din captura.
	sun.shadow_normal_bias = 0.08
	sun.shadow_bias = 0.02
	world.add_child(sun)

	# A doua directionala, din partea opusa. Pe pista rolul asta il face
	# ambientul din cer plus bounce-ul din nisip; intr-o incapere inchisa nu
	# exista nici cer, nici nisip, si peretii ajung negri.
	#
	# MASURAT, nu reglat din ochi: cu soarele la (-42, 135), directia luminii e
	# (-0.525, -0.669, 0.525). Peretele din FUND are normala +Z, deci
	# N·L = -0.525 — NEGATIV. Adica peretele spre care se uita camera nu
	# primeste NIMIC din soare si traieste doar din ambient. De-aia toata
	# adancimea cadrului murea, nu fiindca AO-ul ar fi fost prea tare (podeaua
	# masurata avea AO 1.000, adica neatinsa).
	#
	# Fill-ul bate deci dinspre camera, nu lateral: acopera exact fetele pe
	# care soarele le rateaza.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-24, 18, 0)
	fill.light_color = Color("#C9D9E6")
	fill.light_energy = 0.85
	fill.shadow_enabled = false
	world.add_child(fill)

	var env := Environment.new()
	# Fundal propriu, nu BG_CANVAS: ce se vede prin usa deschisa e cerul de
	# dincolo, iar un canvas transparent ar fi lasat acolo fundalul panoului.
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#9FB6C9")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#C9D9E6")
	# 0.55 era calibrat pentru o masina singura pe fundal gol. Intr-o incapere,
	# ambientul e singura sursa pentru fetele intoarse de la soare.
	env.ambient_light_energy = 0.95
	var cam_env := WorldEnvironment.new()
	cam_env.environment = env
	world.add_child(cam_env)


## Atelierul din jurul masinii (kit: docs/asset_briefs/garage_bay.md).
##
## Compozitia e cea din brief §6 si NU e simetrica: bancul de lucru sta pe
## peretele din STANGA fiindca soarele bate din stanga-sus, deci isi arunca
## umbra spre interiorul cadrului. Pus pe dreapta, ar fi fost o pata plata.
## Restul prop-urilor stau in doua insule, nu imprastiate uniform — aranjamentul
## bate numarul (daca pui la fel de mult in stanga si in dreapta, cadrul moare).
##
## Nimic peste `z = +2`: acolo e masina si drumul camerei.
const ATELIER := "res://assets/models/interiors/%s.glb"

## [piesa, pozitie, rotatie Y in grade]
const ATELIER_PROPS := [
	["garage_bay", Vector3(0, 0, 0), 0.0],
	["garage_door", Vector3(0, 5.3, -7.9), 0.0],
	# insula de langa banc (stanga-fund)
	["garage_bench", Vector3(-8.4, 0, -3.2), 90.0],
	["garage_toolbox", Vector3(-6.9, 0, -0.4), 74.0],
	["garage_tire_stack", Vector3(-7.6, 0, -5.9), 0.0],
	["garage_barrel", Vector3(-8.8, 0, -6.9), 0.0],
	# insula din dreapta-fund, mai rara: asimetria tine cadrul viu
	["garage_crate", Vector3(5.2, 0, -6.4), 18.0],
	["garage_crate", Vector3(6.3, 0.7, -6.1), -9.0],
	["garage_tire_stack", Vector3(4.1, 0, -5.2), 0.0],
	["garage_barrel", Vector3(7.0, 0, -5.0), 0.0],
]


func _build_atelier(world: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "Atelier"
	world.add_child(holder)
	for entry in ATELIER_PROPS:
		var scene: PackedScene = load(ATELIER % entry[0])
		if scene == null:
			push_warning("CarPreview: lipseste piesa de atelier '%s'" % entry[0])
			continue
		var node := scene.instantiate() as Node3D
		holder.add_child(node)
		node.position = entry[1]
		node.rotation.y = deg_to_rad(entry[2])
		# Acelasi material de clasa ca restul lumii: atlas + AO din vertex
		# colors. Tot kitul costa UN material, care e constrangerea reala.
		Palette.apply_world_material(node)


## Podiumul: un disc plat de beton, din paleta lumii (slot `concrete`), plus un
## inel mai inchis pe margine. E singurul indiciu de contact cu solul — fara
## el masina pluteste, exact defectul pentru care s-au pornit umbrele dinamice
## pe piste (CLAUDE.md, „fara contact cu solul, orice obiect pare lipit").
func _build_podium(world: Node3D) -> void:
	_podium = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 4.2
	disc.bottom_radius = 4.4
	disc.height = PODIUM_H
	# Primitiva creata in cod: segmentele se seteaza EXPLICIT (CLAUDE.md —
	# implicitul de 64 ar da un cilindru cu geometria unei planete pentru o
	# forma pe care o vezi ca pe un disc).
	disc.radial_segments = 28
	disc.rings = 1
	_podium.mesh = disc
	# Podiumul sta PESTE podeaua atelierului, nu ingropat in ea. Inainte de
	# atelier lumea n-avea podea si un disc la y=-0.175 parea sa stea pe sol;
	# cu podeaua la y=0 disparea sub ea. `PODIUM_H * 0.5` il ridica exact cat
	# sa-i fie fata superioara la cota la care stau rotile.
	_podium.position.y = PODIUM_H * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Palette.color(Palette.CONCRETE).darkened(0.25)
	mat.roughness = 0.95
	mat.metallic_specular = 0.1
	_podium.material_override = mat
	world.add_child(_podium)


## Asaza o masina in vitrina. Se poate chema oricat de des — modelul vechi se
## arunca intai, deci schimbarea rapida din strip nu lasa masini stivuite.
func show_car(data: CarData) -> void:
	if _model_root != null:
		_model_root.queue_free()
		_model_root = null
	if data == null:
		return

	_data = data
	_model_root = Node3D.new()
	_pivot.add_child(_model_root)

	if data.model != null:
		var model := data.model.instantiate() as Node3D
		model.scale = Vector3.ONE * data.model_scale
		model.rotation.y = deg_to_rad(data.model_rotation_deg)
		_model_root.add_child(model)
		# Acelasi material de clasa ca in cursa: GLB-urile noastre merg pe
		# atlas + AO din vertex colors, FBX-urile RgsDev isi pastreaza ale lor.
		if data.palette_model:
			Palette.apply_world_material(model)
		if data.open_cockpit and data.driver_model != null:
			_seat_driver(data)
	else:
		# CarData fara model: cutia de rezerva, ca vitrina sa nu fie goala.
		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(data.body_width, 1.2, data.body_length)
		box.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = data.color
		box.mesh.surface_set_material(0, mat)
		box.position.y = 0.6
		_model_root.add_child(box)

	_frame_camera(data)


## Figurina soferului, la cota scaunului din CarData.
##
## Se adauga FRATE cu modelul, nu copil al lui — exact cum face
## `Car.apply_data`, unde `Driver` atarna de `_visual` si primeste direct
## `position = data.driver_seat`. `driver_seat` e exprimat in spatiul MASINII
## (fata = -Z), nu in spatiul modelului rotit cu 180°; pus sub model, ajunge
## oglindit pe Z — adica pe capota in loc de pe scaun, cum a si iesit la
## prima captura.
func _seat_driver(data: CarData) -> void:
	var figure := data.driver_model.instantiate() as Node3D
	_model_root.add_child(figure)
	figure.position = data.driver_seat
	Palette.apply_world_material(figure)


## Incadrarea: camera se da inapoi cat sa incapa masina pe axa STRANSA a
## vitrinei. Asa autobuzul de 5.56 m si buggy-ul de 3.7 m ocupa aceeasi
## fractiune din cadru — identitatea se citeste din FORMA, nu din cat de mare a
## iesit in viewport.
##
## Distanta se CALCULEAZA din fov si din proportia viewportului, nu se ia dintr-un
## factor fix. Un `body_length * 2.05` nimerit pe 16:9 taie masina de indata ce
## vitrina devine mai inalta decat lata (panoul de statistici ii musca din
## latime) — exact ce s-a intamplat la prima captura.
func _frame_camera(data: CarData) -> void:
	var pitch := deg_to_rad(CAM_PITCH_DEG)
	# Sfera care cuprinde masina, vazuta din trei-sferturi: diagonala
	# lungime-latime, plus o marja pentru rollbar, scaune si figurina (care
	# ies deasupra caroseriei si nu intra in `body_length`).
	var span := sqrt(data.body_length * data.body_length
		+ data.body_width * data.body_width) * 0.5
	var radius := span * FRAME_MARGIN
	var aspect := float(_viewport.size.x) / float(_viewport.size.y)
	var v_fov := deg_to_rad(_camera.fov)
	# `fov` in Godot e unghiul VERTICAL cand aspectul e supraunitar; pe o
	# vitrina mai inalta decat lata, axa stransa e cea orizontala.
	var h_fov := 2.0 * atan(tan(v_fov * 0.5) * aspect)
	var tight := minf(v_fov, h_fov)
	var dist := radius / tan(tight * 0.5)
	# Tinta urca peste mijlocul caroseriei, ca sub masina sa ramana loc pentru
	# podium si umbra lui — indiciul de contact cu solul. Masurat: cu tinta la
	# nivelul caroseriei, masina se aseza la v=0.60 (prea jos) si fata
	# podiumului cadea la v=0.91, pe muchia cadrului.
	var look_at := Vector3(0, PODIUM_H + data.body_length * 0.16, -0.2)
	_camera.position = look_at + Vector3(
		0.0, sin(pitch) * dist, cos(pitch) * dist)
	_camera.look_at(look_at, Vector3.UP)
	# Podiumul creste cu masina, ca sa nu iasa rotile din el la autobuz.
	var disc_r := maxf(data.body_length * 0.62, 2.6)
	var disc := _podium.mesh as CylinderMesh
	disc.top_radius = disc_r
	disc.bottom_radius = disc_r + 0.2


## Vitrina si-a schimbat forma: viewportul ia noua proportie (cu latura mare
## plafonata la VIEW_MAX) si incadrarea se reface pe ea.
func _on_resized() -> void:
	var box := size
	# La primul cadru containerul poate fi inca zero; atunci nu e nimic de facut.
	if box.x < 1.0 or box.y < 1.0:
		return
	var scale_down := minf(1.0, VIEW_MAX / maxf(box.x, box.y))
	_viewport.size = Vector2i(
		maxi(1, int(box.x * scale_down)), maxi(1, int(box.y * scale_down)))
	if _data != null:
		_frame_camera(_data)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_yaw += deg_to_rad(SPIN_SPEED_DEG) * delta
	_pivot.rotation.y = _yaw


## Repune unghiul de start — chemat cand se deschide garajul, ca masina sa fie
## mereu prezentata din acelasi trei-sferturi, nu de unde a ramas data trecuta.
func reset_spin() -> void:
	_yaw = deg_to_rad(START_YAW_DEG)
	_pivot.rotation.y = _yaw
