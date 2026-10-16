class_name GaragePanel
extends Control
## GARAJUL: alegerea masinii, pe ecran intreg. Vitrina 3D cu masina care se
## roteste, panou de statistici in dreapta, banda de selectie jos.
##
## Inlocuieste lista de butoane-text din meniu („> Muscle  speed 37 accel 15
## grip 7 mass 1.4"). Cifrele brute nu spuneau nimic: nu stiai daca 37 e mult,
## si nu vedeai masina pe care o alegi.
##
## --- De ce barele arata asa ---
##
## 1. SPEED / ACCEL / GRIP se normalizeaza pe intervalul REAL al garajului
##    (min..max intre masinile existente), nu pe [0, max]. Plafoanele sunt
##    intre 30 si 37 m/s: normalizate de la zero, toate masinile ar fi stat
##    in ultima cincime a barei si diferentele — exact ce alegi — ar fi fost
##    invizibile. Capetele sunt rezervate: `BAR_FLOOR` lasa si cea mai slaba
##    masina cu o bara vizibila, nu goala.
##
## 2. MASA NU e o bara care se umple. `mass_factor` merge de la 0.9 (Politia)
##    la 2.6 (Autobuzul), si nici un capat nu e „mai bun": masa mare impinge,
##    masa mica e impinsa dar se invarte usor (CLAUDE.md principiul 1 —
##    bumping-ul cu masa e mecanica, nu defect; principiul 4 — masinile sunt
##    stiluri, nu upgrade-uri). Desenata ca bara care creste, ar fi spus ca
##    autobuzul e „cel mai bun la masa" si Politia o masina stricata. Deci se
##    deseneaza ca indicator CENTRAT: cursorul pleaca din mijloc spre stanga
##    (usoara) sau spre dreapta (grea), cu eticheta USOARA/MEDIE/GREA.
##
## 3. Conturul-fantoma arata valoarea masinii ACUM selectate, cat timp te uiti
##    la alta din banda. Poate aparea si la stanga capatului plin (masina din
##    vitrina e mai slaba), nu doar la dreapta — altfel ar citi ca „cat mai ai
##    pana la maxim", care e alta informatie.

signal back_pressed

const PANEL_BG := Color(0.04, 0.05, 0.08, 0.72)
const PANEL_BORDER := Color(1, 1, 1, 0.10)
const ACCENT := Color(1.0, 0.78, 0.22)
const DIM := Color(0.62, 0.68, 0.78)
const TITLE_COLOR := Color(0.93, 0.95, 0.99)
## Conturul-fantoma: gri-albastrui opac, nu amber stins. Trebuie sa se citeasca
## drept ALT lucru decat umplerea, nu o umplere mai slaba.
const GHOST_COLOR := Color(0.62, 0.68, 0.78, 0.85)

const FONT_BOLD := preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
const FONT_MEDIUM := preload("res://assets/fonts/BarlowCondensed-Medium.ttf")

## Fractia minima de bara pentru cea mai slaba masina din garaj. Zero ar fi
## aratat ca masina „n-are deloc" statistica respectiva, ceea ce e fals: si
## autobuzul merge cu 30 m/s.
const BAR_FLOOR := 0.18
const BAR_H := 16
const CARD_SIZE := Vector2(190, 132)
## Latimea coloanei din dreapta (panoul de statistici + marginea lui). Vitrina
## 3D isi scade exact atat din latime, ca masina sa se centreze pe spatiul
## RAMAS, nu pe mijlocul ecranului — altfel sta pe jumatate sub panou.
const STATS_W := 470.0

var _preview: CarPreview
var _name_label: Label
var _bars: Array[StatBar] = []
var _mass_meter: MassMeter
var _cards: Array[Button] = []
## Bifa „asta e masina mea", cate una per cartonas. Stare separata de bordura:
## vezi nota de la `_refresh_cards`.
var _card_marks: Array[Label] = []
## Masina din vitrina. Poate diferi de `GameState.selected_car`: te uiti la una
## si inca n-ai apasat SELECT.
var _shown: int = 0
## Limitele garajului, calculate o data: [min, max] pe fiecare statistica.
var _range_speed: Vector2
var _range_accel: Vector2
var _range_grip: Vector2
var _range_mass: Vector2


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compute_ranges()
	_shown = GameState.selected_car

	# Vitrina ocupa doar spatiul LIBER, nu tot ecranul: panoul de statistici
	# sta peste dreapta, banda de cartonase peste jos. Intinsa pe tot
	# dreptunghiul, masina se centra pe mijlocul ECRANULUI — adica pe jumatate
	# ascunsa sub panou — si apoi parea taiata de banda de jos.
	_preview = CarPreview.new()
	_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview.offset_right = -STATS_W
	_preview.offset_bottom = -(CARD_SIZE.y + 36)
	_preview.offset_top = 96
	add_child(_preview)

	_build_header()
	_build_stats_panel()
	_build_card_strip()

	_show(_shown)


## Intervalele reale ale garajului. Daca cineva adauga un .tres nou in
## GameState.CAR_DATA, barele se rescaleaza singure — conform CLAUDE.md,
## „continut nou = fisier nou, zero modificari in cod".
func _compute_ranges() -> void:
	var speeds: Array[float] = []
	var accels: Array[float] = []
	var grips: Array[float] = []
	var masses: Array[float] = []
	for res in GameState.CAR_DATA:
		var data := res as CarData
		speeds.append(data.max_speed)
		accels.append(data.acceleration)
		grips.append(data.grip)
		masses.append(data.mass_factor)
	_range_speed = Vector2(speeds.min(), speeds.max())
	_range_accel = Vector2(accels.min(), accels.max())
	_range_grip = Vector2(grips.min(), grips.max())
	_range_mass = Vector2(masses.min(), masses.max())


# ------------------------------------------------------------------ antet

func _build_header() -> void:
	var title := _make_label(44, true)
	title.text = "GARAGE"
	title.add_theme_color_override("font_color", TITLE_COLOR)
	var title_panel := PanelContainer.new()
	title_panel.add_theme_stylebox_override("panel", _panel_style(16))
	title_panel.position = Vector2(28, 22)
	add_child(title_panel)
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 26)
	tm.add_theme_constant_override("margin_right", 26)
	tm.add_theme_constant_override("margin_top", 2)
	tm.add_theme_constant_override("margin_bottom", 6)
	title_panel.add_child(tm)
	tm.add_child(title)

	var close := Button.new()
	close.text = "X"
	close.custom_minimum_size = Vector2(72, 72)
	close.add_theme_font_override("font", FONT_BOLD)
	close.add_theme_font_size_override("font_size", 34)
	close.add_theme_color_override("font_color", TITLE_COLOR)
	_style_button(close, 16)
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close.position = Vector2(-100, 22)
	close.pressed.connect(func() -> void: back_pressed.emit())
	add_child(close)


# --------------------------------------------------------- panoul de stat

func _build_stats_panel() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(18))
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-STATS_W, 118)
	panel.custom_minimum_size = Vector2(STATS_W - 30.0, 0)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	_name_label = _make_label(36, true)
	_name_label.add_theme_color_override("font_color", ACCENT)
	box.add_child(_name_label)

	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.14)
	sep.custom_minimum_size = Vector2(0, 1)
	box.add_child(sep)

	for label in ["SPEED", "ACCEL", "GRIP"]:
		var bar := StatBar.new()
		bar.setup(label, _make_label(20, false), BAR_H)
		box.add_child(bar)
		_bars.append(bar)

	_mass_meter = MassMeter.new()
	_mass_meter.setup(_make_label(20, false), _make_label(20, false), BAR_H)
	box.add_child(_mass_meter)

	var select := Button.new()
	select.text = "SELECT"
	select.custom_minimum_size = Vector2(0, 76)
	select.add_theme_font_override("font", FONT_BOLD)
	select.add_theme_font_size_override("font_size", 34)
	select.add_theme_color_override("font_color", Color(0.06, 0.06, 0.08))
	select.add_theme_color_override("font_hover_color", Color(0.06, 0.06, 0.08))
	select.add_theme_color_override("font_pressed_color", Color(0.1, 0.1, 0.12))
	var filled := _panel_style(14, ACCENT, Color(1, 1, 1, 0.0))
	select.add_theme_stylebox_override("normal", filled)
	select.add_theme_stylebox_override("hover",
		_panel_style(14, ACCENT.lightened(0.12), Color(1, 1, 1, 0.0)))
	select.add_theme_stylebox_override("pressed",
		_panel_style(14, ACCENT.darkened(0.18), Color(1, 1, 1, 0.0)))
	select.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	select.pressed.connect(_on_select_pressed)
	box.add_child(select)


# ------------------------------------------------------------ banda de jos

func _build_card_strip() -> void:
	var strip := PanelContainer.new()
	strip.add_theme_stylebox_override("panel",
		_panel_style(0, Color(0.02, 0.03, 0.05, 0.82), Color(1, 1, 1, 0.06)))
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	strip.position.y = -(CARD_SIZE.y + 36)
	strip.custom_minimum_size = Vector2(0, CARD_SIZE.y + 36)
	add_child(strip)

	# Se deruleaza orizontal: pe telefon ingust, sase cartonase nu incap.
	# `ScrollContainer` simplu, nu `TouchScrollContainer` — aceea isi forteaza
	# in `_ready` derularea pe VERTICALA (e facuta pentru liste de piste) si
	# si-ar fi stins singura axa de care avem nevoie aici.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.add_child(scroll)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)

	for i in GameState.CAR_DATA.size():
		var index := i
		var data := GameState.CAR_DATA[i] as CarData
		var card := Button.new()
		card.custom_minimum_size = CARD_SIZE
		card.add_theme_font_override("font", FONT_MEDIUM)
		card.add_theme_font_size_override("font_size", 22)
		card.text = data.display_name
		card.pressed.connect(func() -> void: _show(index))
		row.add_child(card)
		_cards.append(card)

		# Bifa sta PESTE cartonas, ancorata in coltul din dreapta-sus. Nu intra
		# in textul butonului: acolo ar fi mutat numele masinii cand apare si
		# ar fi facut banda sa tresara la fiecare SELECT.
		var mark := Label.new()
		mark.add_theme_font_override("font", FONT_BOLD)
		mark.add_theme_font_size_override("font_size", 30)
		mark.add_theme_color_override("font_color", ACCENT)
		mark.text = "✓"
		mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		mark.position = Vector2(CARD_SIZE.x - 34.0, 4.0)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(mark)
		_card_marks.append(mark)


# ------------------------------------------------------------------ stare

## Arata masina `index` in vitrina si in panou. NU o si selecteaza — asta face
## doar butonul SELECT, ca sa poti compara fara sa-ti pierzi alegerea.
func _show(index: int) -> void:
	_shown = clampi(index, 0, GameState.CAR_DATA.size() - 1)
	var data := GameState.CAR_DATA[_shown] as CarData
	var current := GameState.CAR_DATA[GameState.selected_car] as CarData

	_preview.show_car(data)
	_preview.reset_spin()
	_name_label.text = data.display_name.to_upper()

	# Fantoma arata masina selectata ACUM — si doar cand te uiti la alta.
	var ghost := _shown != GameState.selected_car
	_bars[0].set_values(
		_norm(data.max_speed, _range_speed),
		_norm(current.max_speed, _range_speed) if ghost else -1.0)
	_bars[1].set_values(
		_norm(data.acceleration, _range_accel),
		_norm(current.acceleration, _range_accel) if ghost else -1.0)
	_bars[2].set_values(
		_norm(data.grip, _range_grip),
		_norm(current.grip, _range_grip) if ghost else -1.0)
	_mass_meter.set_values(
		_mass_offset(data.mass_factor), _mass_word(data.mass_factor),
		_mass_offset(current.mass_factor) if ghost else -2.0)

	_refresh_cards()


## Doua stari DIFERITE pe aceeasi banda, si de-aia nu pot arata la fel:
##   „ma uit la ea" (= e in vitrina)  -> cadru alb gros + fundal ridicat
##   „e masina mea"  (= selectata)    -> bifa amber in coltul cartonasului
##
## Prima incercare le dadea amandurora doar o bordura, amber pentru selectie si
## alb-45% pentru vitrina. La captura, cartonasul din vitrina disparea in banda
## iar ochiul citea bifa amber de pe ALT cartonas ca fiind masina afisata — se
## vedea „MUSCLE" in panou si rama aprinsa pe Autobuzul. Starea pe care o
## schimbi cu degetul trebuie sa fie cea mai zgomotoasa.
func _refresh_cards() -> void:
	for i in _cards.size():
		var chosen := i == GameState.selected_car
		var looking := i == _shown
		var border := Color(1, 1, 1, 0.75) if looking else Color(1, 1, 1, 0.08)
		var bg := Color(0.13, 0.16, 0.22, 0.95) if looking \
			else Color(0.04, 0.05, 0.08, 0.70)
		var style := _panel_style(14, bg, border)
		style.set_border_width_all(3 if looking else 1)
		_cards[i].add_theme_stylebox_override("normal", style)
		_cards[i].add_theme_stylebox_override("hover",
			_panel_style(14, bg.lightened(0.06), border))
		_cards[i].add_theme_stylebox_override("pressed",
			_panel_style(14, bg.darkened(0.15), border))
		_cards[i].add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		_cards[i].add_theme_color_override("font_color",
			TITLE_COLOR if looking else DIM)
		_card_marks[i].visible = chosen


func _on_select_pressed() -> void:
	GameState.selected_car = _shown
	GameState.save_settings()
	_show(_shown) # fantoma dispare: masina din vitrina E cea selectata


## Repune garajul pe masina salvata — chemat cand se deschide panoul, ca sa nu
## ramana pe ce te uitai data trecuta fara sa fi apasat SELECT.
func reopen() -> void:
	_show(GameState.selected_car)


# ------------------------------------------------------------ normalizare

## Fractia de bara pentru `value`, pe intervalul `limits` (x = min, y = max) al
## garajului, cu `BAR_FLOOR` rezervat capatului de jos. Daca toate masinile au
## aceeasi valoare, intervalul e zero si toate primesc bara plina — altfel ar
## iesi o impartire la zero pentru o diferenta care nu exista.
func _norm(value: float, limits: Vector2) -> float:
	var span := limits.y - limits.x
	if span < 0.0001:
		return 1.0
	var t := (value - limits.x) / span
	return BAR_FLOOR + t * (1.0 - BAR_FLOOR)


## Pozitia cursorului de masa, in [-1, 1], cu 0 = mijlocul garajului. Semnul e
## ce conteaza: negativ = mai usoara decat media, pozitiv = mai grea. Nu e o
## nota, e un loc pe o axa.
func _mass_offset(mass: float) -> float:
	var mid := (_range_mass.x + _range_mass.y) * 0.5
	var half := (_range_mass.y - _range_mass.x) * 0.5
	if half < 0.0001:
		return 0.0
	return clampf((mass - mid) / half, -1.0, 1.0)


func _mass_word(mass: float) -> String:
	var t := _mass_offset(mass)
	if t < -0.33:
		return "USOARA"
	if t > 0.33:
		return "GREA"
	return "MEDIE"


# ------------------------------------------------------------------ stil

static func _panel_style(radius: int, bg: Color = PANEL_BG,
		border: Color = PANEL_BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(1)
	return sb


func _style_button(button: Button, radius: int) -> void:
	button.add_theme_stylebox_override("normal", _panel_style(radius))
	button.add_theme_stylebox_override("hover",
		_panel_style(radius, Color(0.10, 0.12, 0.17, 0.80)))
	button.add_theme_stylebox_override("pressed",
		_panel_style(radius, Color(0.02, 0.03, 0.05, 0.88)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_label(font_size: int, bold: bool) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT_BOLD if bold else FONT_MEDIUM)
	label.add_theme_font_size_override("font_size", font_size)
	return label


# ------------------------------------------- bara de statistica (clasa interna)

## O linie „ETICHETA + bara": umplere amber pe sina inchisa, plus conturul
## masinii de comparatie. Desenata cu _draw, nu din Control-uri stivuite:
## fantoma poate cadea oriunde pe sina, inclusiv sub umplere, si un ColorRect
## ar fi cerut reasezare la fiecare schimbare.
class StatBar extends VBoxContainer:
	var _label: Label
	var _bar: BarDraw

	func setup(text: String, label: Label, height: int) -> void:
		add_theme_constant_override("separation", 5)
		_label = label
		_label.text = text
		_label.add_theme_color_override("font_color", GaragePanel.DIM)
		add_child(_label)
		_bar = BarDraw.new()
		_bar.custom_minimum_size = Vector2(0, height)
		add_child(_bar)

	func set_values(fill: float, ghost: float) -> void:
		_bar.fill = fill
		_bar.ghost = ghost
		_bar.queue_redraw()


class BarDraw extends Control:
	var fill: float = 0.0
	## < 0 = fara fantoma (masina din vitrina e chiar cea selectata).
	var ghost: float = -1.0

	func _draw() -> void:
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, h)),
			Color(0, 0, 0, 0.45), true)
		var w := size.x * clampf(fill, 0.0, 1.0)
		if w > 1.0:
			draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)),
				GaragePanel.ACCENT, true)
		# Segmentele: patru taieturi subtiri, ca bara sa se citeasca in trepte
		# si nu ca un lichid — ajuta ochiul sa compare doua masini.
		for i in range(1, 5):
			var x := size.x * i / 5.0
			draw_rect(Rect2(Vector2(x - 1.0, 0), Vector2(2.0, h)),
				Color(0, 0, 0, 0.55), true)
		if ghost >= 0.0:
			var gx := size.x * clampf(ghost, 0.0, 1.0)
			# Linia verticala + doua aripioare: se citeste ca un REPER, nu ca
			# o a doua umplere. Poate cadea si in stanga capatului amber.
			draw_rect(Rect2(Vector2(gx - 1.5, -2.0), Vector2(3.0, h + 4.0)),
				GaragePanel.GHOST_COLOR, true)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, h)),
			Color(1, 1, 1, 0.12), false, 1.0)


## Indicatorul de masa: cursor pe o axa cu zero la mijloc. Vezi nota 2 din
## antetul fisierului — masa nu e o nota, deci nu e o bara care se umple.
class MassMeter extends VBoxContainer:
	var _label: Label
	var _word: Label
	var _axis: MassDraw

	func setup(label: Label, word: Label, height: int) -> void:
		add_theme_constant_override("separation", 5)
		var head := HBoxContainer.new()
		_label = label
		_label.text = "MASS"
		_label.add_theme_color_override("font_color", GaragePanel.DIM)
		head.add_child(_label)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(spacer)
		_word = word
		_word.add_theme_color_override("font_color", GaragePanel.ACCENT)
		head.add_child(_word)
		add_child(head)
		_axis = MassDraw.new()
		_axis.custom_minimum_size = Vector2(0, height)
		add_child(_axis)

	func set_values(offset: float, word: String, ghost: float) -> void:
		_word.text = word
		_axis.offset = offset
		_axis.ghost = ghost
		_axis.queue_redraw()


class MassDraw extends Control:
	var offset: float = 0.0
	## <= -2 = fara fantoma. Nu -1: -1 e o pozitie VALIDA (cea mai usoara).
	var ghost: float = -2.0

	func _draw() -> void:
		var h := size.y
		var mid := size.x * 0.5
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, h)),
			Color(0, 0, 0, 0.45), true)
		# Axa si zero-ul: fara ele, cursorul n-ar avea fata de ce sa fie citit.
		draw_rect(Rect2(Vector2(0, h * 0.5 - 1.0), Vector2(size.x, 2.0)),
			Color(1, 1, 1, 0.10), true)
		draw_rect(Rect2(Vector2(mid - 1.0, h * 0.18), Vector2(2.0, h * 0.64)),
			Color(1, 1, 1, 0.22), true)
		var x := mid + mid * clampf(offset, -1.0, 1.0)
		if ghost > -2.0:
			var gx := mid + mid * clampf(ghost, -1.0, 1.0)
			draw_rect(Rect2(Vector2(gx - 1.5, 0), Vector2(3.0, h)),
				GaragePanel.GHOST_COLOR, true)
		# Bara de la zero pana la cursor: lungimea spune CAT, iar partea pe care
		# cade spune INCOTRO.
		var from_x := minf(mid, x)
		var w := absf(x - mid)
		if w > 1.0:
			draw_rect(Rect2(Vector2(from_x, h * 0.28), Vector2(w, h * 0.44)),
				GaragePanel.ACCENT, true)
		draw_rect(Rect2(Vector2(x - 3.0, 0), Vector2(6.0, h)),
			GaragePanel.ACCENT, true)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, h)),
			Color(1, 1, 1, 0.12), false, 1.0)
