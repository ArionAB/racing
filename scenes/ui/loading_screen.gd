class_name LoadingScreen
extends CanvasLayer
## Ecranul de incarcare al unei curse: regiunea si numele pistei, o bara de
## progres si un sfat de joc, cat timp se citeste scena si se genereaza pista.
## Il monteaza [Race] doar cand cursa porneste din joc (GameState.start_race);
## sondele si F6 din editor instantiaza Race direct si nu-l vad.
##
## DE CE force_draw SI NU CADRE REALE INTRE PASI. Constructia pistei
## (`Track.rebuild`) ramane UN SINGUR apel sincron, exact ca inainte. Intre
## fazele ei pista emite `build_step`, iar ecranul redeseneaza pe loc cu
## `RenderingServer.force_draw()`. Daca am fi lasat cadre reale sa treaca
## intre pasi, apelurile amanate (`call_deferred`) puse de decorul manual in
## `_ready` — remaparea sloturilor, ruptura de accente — ar fi rulat la
## MIJLOCUL constructiei in loc de dupa ea, iar discurile de umbra ar fi citit
## alte noduri: pista din joc ar fi iesit alta decat cea din editor si sonde.
##
## Pretul: intre pasi se vede doar ce se schimba prin TRANSFORM. Bara e un
## [Node2D] scalat pe x, deci se misca; textul si redesenarile de [Control]
## trec prin coada de mesaje, care nu se goleste in timpul constructiei — de
## aceea pe ecran nu exista nimic care sa trebuiasca rescris intre pasi.
##
## BARA INVATA. Durata fiecarei faze se masoara si se pastreaza per pista in
## `user://incarcare.cfg`; de la a doua incarcare bara avanseaza proportional
## cu timpul real de pe ACEST dispozitiv. Prima data foloseste
## `DEFAULT_SECONDS`, proportiile masurate pe desktop.

const SAVE_PATH := "user://incarcare.cfg"

## Fazele, in ordine. Cele din mijloc sunt `Track.BUILD_STEPS`; "scena" e
## citirea .tscn-ului (pe fir separat), "masini" e restul lui Race (masini,
## HUD, camera), "incalzire" sunt cadrele randate in spatele ecranului ca
## shaderele sa se compileze inainte sa-l ridicam.
const PHASES: Array[StringName] = [&"scena", &"pregatire", &"drum",
	&"obstacole", &"umeri", &"decor", &"teren", &"umbre", &"apa", &"masini",
	&"incalzire"]

## Secunde asteptate pe faza, pana cand o pista isi are propriile masuratori:
## media celor 11 piste pe desktop, dupa reparatia lui `ground_y` (oct 2026,
## tools/ProbeLoading.tscn). Conteaza doar PROPORTIILE dintre faze, nu
## valorile absolute — pe telefon totul e mai lent, dar cam in acelasi raport.
const DEFAULT_SECONDS := {
	&"scena": 0.3, &"pregatire": 1.0, &"drum": 0.15, &"obstacole": 0.03,
	&"umeri": 0.9, &"decor": 1.4, &"teren": 0.25, &"umbre": 1.3, &"apa": 0.55,
	&"masini": 0.1, &"incalzire": 0.2,
}

## Cate cadre se randeaza scena 3D in spatele ecranului inainte de fade.
const WARMUP_FRAMES: int = 3
const FADE_SECONDS: float = 0.35

const BG_COLOR := Color(0.07, 0.09, 0.14)
const BAR_BG := Color(1.0, 1.0, 1.0, 0.14)
const BAR_FILL := Color(0.95, 0.83, 0.48) # galbenul de focus al cartonaselor
const TEXT_DIM := Color(0.62, 0.68, 0.78)
const BAR_HEIGHT := 10.0

const TIPS: Array[String] = [
	"Tine TURBO apasat in ultima secunda a numaratorii pentru rocket start.",
	"Driftul umple bara de turbo mult mai repede decat mersul drept.",
	"Turbo-ul e al tau: pastreaza-l pentru o dreapta lunga sau inaintea unei sarituri.",
	"Masinile grele imping, cele usoare zboara. Alege-ti bine cu cine te freci.",
	"Iarba te incetineste, dar unele scurtaturi tot merita riscul.",
]

## Pozitia pistei in GameState.TRACK_SCENES; se seteaza inainte de add_child.
var track_index: int = 0

var _root: Control
var _bar: Control
var _fill: Node2D
var _fill_rect: ColorRect
var _key: String = ""
var _expect: Dictionary = {}
var _measured: Dictionary = {}
var _phase: int = 0
var _phase_t0: int = 0


func _ready() -> void:
	layer = 100 # peste HUD si peste parbrizul ud
	# Fade-ul (tween pe nod) nu are voie sa inghete daca arborele e in pauza.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_key = TrackInfo.scene_key(track_index)
	_load_expectations()
	_build_ui()
	_set_fraction(0.0)
	_phase_t0 = Time.get_ticks_usec()


## Citeste scena pistei pe un fir separat, cu cadre reale intre timp (bara se
## misca, ecranul traieste). Daca firul nu porneste sau pica, cade pe `load`.
func load_scene(path: String) -> PackedScene:
	# Ecranul trebuie sa fi aparut macar o data inainte de orice munca grea:
	# dupa doua cadre de proces, cel dintai a fost sigur desenat. NU
	# `frame_post_draw`: cu fereastra minimizata (sau in --headless) motorul
	# nu deseneaza deloc, iar semnalul n-ar mai veni — incarcarea ar sta.
	for i in 2:
		await get_tree().process_frame
	_phase_t0 = Time.get_ticks_usec()
	var scene: PackedScene = null
	if ResourceLoader.load_threaded_request(path, "PackedScene") == OK:
		var progress := []
		while true:
			var status := ResourceLoader.load_threaded_get_status(path, progress)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				scene = ResourceLoader.load_threaded_get(path) as PackedScene
				break
			if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				break
			if not progress.is_empty():
				_set_fraction(_fraction(float(progress[0])))
			await get_tree().process_frame
	if scene == null:
		scene = load(path) as PackedScene
	end_phase(&"scena")
	return scene


## Leaga bara de fazele constructiei. De chemat inainte de add_child(track):
## faza "pregatire" incepe acum si include `_ready`-ul decorului manual.
func watch_build(track: Track) -> void:
	_phase_t0 = Time.get_ticks_usec()
	track.build_step.connect(_on_build_step)


## Inchide o faza: ii noteaza durata si muta bara la capatul ei.
func end_phase(phase: StringName) -> void:
	var idx := PHASES.find(phase)
	if idx < _phase:
		return
	var now := Time.get_ticks_usec()
	_measured[phase] = float(now - _phase_t0) / 1000000.0
	_phase = idx + 1
	_phase_t0 = now
	_set_fraction(_fraction(0.0))


## Ultimele cadre in spatele ecranului, salvarea duratelor si fade-ul. Se
## intoarce cand ecranul INCEPE sa se ridice; fade-ul continua singur, apoi
## nodul se elibereaza.
func finish() -> void:
	for i in WARMUP_FRAMES:
		await get_tree().process_frame
	end_phase(&"incalzire")
	_save_measurements()
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(queue_free)


## Duratele masurate la aceasta incarcare (secunde pe faza) — pentru sonde.
func measured() -> Dictionary:
	return _measured.duplicate()


func _on_build_step(step: StringName) -> void:
	end_phase(step)
	# Constructia nu lasa cadre sa treaca: cadrul se deseneaza de mana. Doar
	# daca fereastra chiar se poate desena: minimizata (sau in --headless)
	# n-are ce arata, iar un cadru fortat pe o suprafata de 0x0 da erori.
	if DisplayServer.get_name() != "headless" 			and DisplayServer.window_can_draw():
		RenderingServer.force_draw()


func _fraction(sub: float) -> float:
	var total := 0.0
	var done := 0.0
	for i in PHASES.size():
		var e: float = _expect.get(PHASES[i], 0.0)
		total += e
		if i < _phase:
			done += e
		elif i == _phase:
			done += e * clampf(sub, 0.0, 1.0)
	return done / total if total > 0.0 else 0.0


func _set_fraction(f: float) -> void:
	if _fill != null:
		# Scala zero face baza singulara; un fir de bara nu se vede oricum.
		_fill.scale = Vector2(maxf(f, 0.001), 1.0)


func _load_expectations() -> void:
	_expect = DEFAULT_SECONDS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for phase in PHASES:
		if not cfg.has_section_key(_key, String(phase)):
			continue
		var v: Variant = cfg.get_value(_key, String(phase))
		if v is float and float(v) >= 0.0:
			_expect[phase] = float(v)


## Media mobila 50/50 cu ce era salvat: o incarcare rece (prima dupa pornirea
## aplicatiei) nu sterge tot ce s-a invatat, dar nici nu ramane ignorata.
func _save_measurements() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH) # lipsa fisierului e normala la prima rulare
	for phase in PHASES:
		if not _measured.has(phase):
			continue
		var now: float = _measured[phase]
		var old: Variant = cfg.get_value(_key, String(phase)) 			if cfg.has_section_key(_key, String(phase)) else null
		var v := now if not (old is float) else lerpf(float(old), now, 0.5)
		cfg.set_value(_key, String(phase), v)
	cfg.save(SAVE_PATH)


func _build_ui() -> void:
	var info := TrackInfo.for_track(track_index)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Ecranul inghite atingerile: nimic de sub el nu are voie sa reactioneze.
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = BG_COLOR
	_root.add_child(bg)
	var thumb := TrackInfo.thumbnail(track_index)
	if thumb != null:
		var pic := TextureRect.new()
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.texture = thumb
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.modulate = Color(0.55, 0.55, 0.6)
		_root.add_child(pic)
	else:
		# Fara imagine: o pata de culoarea pistei, ca fiecare sa-si aiba tonul.
		var glow := TextureRect.new()
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var grad := Gradient.new()
		grad.set_color(0, Color(info.accent, 0.55))
		grad.set_color(1, Color(info.accent, 0.0))
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.15, 1.0)
		tex.fill_to = Vector2(0.95, 0.1)
		glow.texture = tex
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		_root.add_child(glow)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 56)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 48)
	_root.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var region := _label(22, info.accent.lightened(0.45))
	region.text = info.region.to_upper() if info.region != "" else "PISTA"
	column.add_child(region)
	var title := _label(60, Color.WHITE)
	title.text = info.display_name if info.display_name != "" \
		else GameState.TRACK_NAMES[track_index]
	column.add_child(title)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	column.add_child(gap)
	_bar = ColorRect.new()
	(_bar as ColorRect).color = BAR_BG
	_bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_bar)
	# Umplerea e un Node2D: scala lui ajunge la RenderingServer pe loc, deci se
	# vede si in cadrele desenate de mana din timpul constructiei.
	_fill = Node2D.new()
	_bar.add_child(_fill)
	_fill_rect = ColorRect.new()
	_fill_rect.color = BAR_FILL
	_fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill.add_child(_fill_rect)
	_bar.resized.connect(func() -> void: _fill_rect.size = _bar.size)

	var tip := _label(20, TEXT_DIM)
	tip.text = TIPS[randi() % TIPS.size()]
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(tip)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 6)
	return label
