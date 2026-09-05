extends Node
## Sonda de COMPARATIE pentru praful de sub roti, fata de referinta video
## (Beach Buggy Racing 2). Difera de ProbeFx prin trei lucruri, toate necesare
## ca sa se poata MASURA praful, nu doar sa se constate ca emitatorul e pornit:
##
##   1. Masina ramane PE sosea (pe Okinawa/Stromboli/Cappadocia soseaua e de
##      pamant, deci praful apare fara sa iesim de pe drum si fara teleportari
##      care aruncau masina in mare — vezi capturile goale din ProbeFx).
##   2. Camera e fixata in spatele masinii, jos, ca in inregistrarea de
##      referinta (telefon, chase cam joasa) — nu camera de urmarire, ca sa
##      compar cadre comparabile.
##   3. Salveaza PERECHEA praf pornit / praf oprit din ACELASI loc, ca sa se
##      poata izola praful prin diferenta. Fara perechea asta orice masuratoare
##      amesteca praful cu solul de sub el.
##
##   godot --rendering-driver vulkan --path . res://tools/ProbeDustLook.tscn -- --track=1

const RACE_SCENE: String = "res://scenes/race/Race.tscn"

class FlatOut extends CarController:
	var steer_cmd: float = 0.0
	var drift_cmd: bool = false
	func get_throttle() -> float: return 1.0
	func get_steer() -> float: return steer_cmd
	func is_drift_pressed() -> bool: return drift_cmd

var _race: Node = null
var _car: Car = null
var _ctrl: FlatOut = null
var _frames: int = 0
var _cam: Camera3D = null
var _tag: String = "okinawa"
var _drift: bool = false
var _trail_only: bool = false
var _taken: bool = false
var _hold: int = 0

func _ready() -> void:
	GameState.selected_track = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			GameState.selected_track = GameState.resolve_track_index(
				int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg == "--drift":
			_drift = true
		elif arg == "--trail":
			_trail_only = true
	GameState.selected_car = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)

func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames == 5:
		# Filmam o masina AI, nu jucatorul: jucatorul fara input sta pe loc, iar
		# un controller flat-out fara virare iese de pe sosea in cateva secunde
		# (capcana care lasa ProbeFx cu capturi goale). AI-ul conduce pista
		# corect, si praful e acelasi cod pentru toate masinile.
		# Ultima masina AI din lista: in spatele ei nu mai vine nimeni care sa
		# intre intre camera si nor, iar in cadru se vede numai praful ei.
		var all: Array = _race.get("cars") as Array
		for c: Car in all:
			if c != _race.player:
				_car = c
		_cam = Camera3D.new()
		add_child(_cam)
		_cam.fov = 70.0
		return
	if _car == null:
		return
	# In modul --drift fortam starea de drift pe masina filmata: AI-ul deriveaza
	# rar si scurt, iar sonda ar astepta la nesfarsit cadrul potrivit.
	if _drift and _frames > 900:
		# Pornim direct emitatorul, nu starea: `is_drifting` e recalculata in
		# fiecare cadru din input, deci valoarea fortata era stearsa imediat.
		var sm := _car.get_node_or_null("DriftSmoke") as CPUParticles3D
		if sm != null:
			sm.emitting = true
	if _trail_only:
		# Fara praf in cadru: altfel diferenta on/off amesteca norul (care
		# LUMINEAZA) cu buza brazdei (care lumineaza si ea) si nu se poate
		# masura niciuna.
		for c: Car in (_race.get("cars") as Array):
			for nm in ["Dust", "Debris", "DriftSmoke"]:
				var n := c.get_node_or_null(nm) as CPUParticles3D
				if n != null:
					n.emitting = false
					n.visible = false
	_place_cam()
	# La 220 de cadre masina e la viteza si pe sosea de destul timp cat sa fi
	# ridicat un nor stabil.
	# Cautam ACTIV cadrul bun: masina pe sosea, la viteza, cu praful pornit.
	# Un numar de cadru fix nimereste orice altceva (masina in nisip la 8 km/h).
	if _frames > 900 and not _taken:
		var want: String = "DriftSmoke" if _drift else "Dust"
		var d0 := _car.get_node_or_null(want) as CPUParticles3D
		var t0 := _race.track as Track
		var fast: bool = _car.horizontal_speed() > 20.0
		var onroad: bool = t0.is_on_road(_car.road_index, _car.global_position)
		if (d0 != null and (d0.emitting or _trail_only)) and fast and onroad:
			_taken = true
			_hold = _frames
			# Fizica STOP inainte de pereche. RenderingServer.force_draw()
			# avanseaza cadrul, deci fara asta masinile se muta intre cele doua
			# poze si diferenta masoara caroserii, nu praf (66 de "trepte dure"
			# care erau muchii de autobuz).
			# Oprim doar MISCAREA corpurilor, nu si simularea: `freeze = true`
			# pe RigidBody3D rastoarna masinile in aer (autobuz pe o roata in
			# captura), iar `Engine.time_scale = 0` opreste si particulele, deci
			# norul nu mai apucase sa creasca. Viteza zero e de ajuns: intre
			# cele doua randari nimic nu se mai muta.
			if not _trail_only:
				for c: Car in (_race.get("cars") as Array):
					c.linear_velocity = Vector3.ZERO
					c.angular_velocity = Vector3.ZERO
			RenderingServer.force_draw()
			_shot("dust_%s_on" % _tag)
			_report()
			# Perechea se ia in ACELASI cadru de simulare: ascundem praful si
			# cerem inca o randare cu RenderingServer.force_draw(). Asa singura
			# diferenta dintre poze e praful — daca lasam sa treaca un cadru,
			# masina se muta 0.6 m si diferenta masoara miscarea (prima
			# incercare: "praf pe 50%% din ecran").
			# Ascundem praful si pietricelele TUTUROR masinilor, nu doar ale
			# celei filmate: cu cinci adversari care emit in acelasi cadru,
			# diferenta continea si norii lor, iar profilul iesea plin de
			# "trepte dure" care erau de fapt caroserii.
			for c: Car in (_race.get("cars") as Array):
				for nm in ["Dust", "Debris", "DriftSmoke"]:
					var n := c.get_node_or_null(nm) as CPUParticles3D
					if n != null:
						n.visible = false
				# Si dara de rulare: ca sa se poata masura profilul brazdei
				# (fagas vs buza) izolat de textura drumului de sub ea.
				for ch in c.get_children():
					var tr := ch as SandTrail
					if tr != null:
						tr.visible = false
			RenderingServer.force_draw()
			_shot("dust_%s_off" % _tag)
			get_tree().quit(0)
	if _frames > 3000 and not _taken:
		print("=== ProbeDustLook %s: NU s-a gasit cadru bun ===" % _tag)
		print("  ultima stare: %.1f km/h  pe sosea=%s"
			% [_car.horizontal_speed() * 3.6,
			(_race.track as Track).is_on_road(_car.road_index, _car.global_position)])
		get_tree().quit(1)

## Camera joasa, in spate, ca in referinta.
func _place_cam() -> void:
	var back := _car.global_basis.z
	if _trail_only:
		# Privire in URMA masinii, de sus: camera de joc se uita inainte, deci
		# nu vede niciodata dara pe care tocmai a lasat-o.
		_cam.global_position = _car.global_position + back * 5.0 + Vector3.UP * 4.5
		_cam.look_at(_car.global_position + back * 22.0, Vector3.UP)
	else:
		_cam.global_position = _car.global_position + back * 9.5 + Vector3.UP * 3.0
		_cam.look_at(_car.global_position + Vector3.UP * 0.4, Vector3.UP)
	_cam.make_current()

func _report() -> void:
	var d := _car.get_node_or_null("Dust") as CPUParticles3D
	var t := _race.track as Track
	print("=== ProbeDustLook %s ===" % _tag)
	print("  viteza      : %.1f km/h" % (_car.horizontal_speed() * 3.6))
	print("  pe sosea    : %s" % t.is_on_road(_car.road_index, _car.global_position))
	print("  sol afanat  : %s" % t.road_is_loose())
	if d != null:
		print("  praf emite  : %s  amount=%d  culoare=%s"
			% [d.emitting, d.amount, d.color])
	for ch in _car.get_children():
		var tr := ch as SandTrail
		if tr == null:
			continue
		var used := 0
		for i in tr.multimesh.instance_count:
			if tr.multimesh.get_instance_transform(i).basis.determinant() != 0.0:
				used += 1
		var sm := tr.material_override as ShaderMaterial
		if sm != null:
			print("    shader now=%s core_alpha=%s basin=%s tread=%s tex=%s"
				% [sm.get_shader_parameter("now"),
				sm.get_shader_parameter("core_alpha"),
				sm.get_shader_parameter("basin"),
				sm.get_shader_parameter("tread_amount"),
				sm.get_shader_parameter("tread_tex")])
		print("  DARA: %d/%d instante  vizibil=%s  mat=%s  custom=%s"
			% [used, tr.multimesh.instance_count, tr.visible,
			tr.material_override, tr.multimesh.use_custom_data])
		var mm := tr.multimesh
		if used > 0:
			print("    prima instanta: %s  custom=%s"
				% [mm.get_instance_transform(0).origin,
				mm.get_instance_custom_data(0)])

func _shot(n: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://snapshots/%s.png" % n))
	print("  captura: snapshots/%s.png" % n)
