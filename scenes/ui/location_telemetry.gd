class_name LocationTelemetry
extends CanvasLayer
## Telemetria de POZITIE (unealta de debug, nov 2026). Spune unde e masina
## jucatorului pe pista in coordonatele pe care le folosesc uneltele, ca
## „problema e AICI" sa devina un loc reproductibil, nu o descriere:
##
##   - indexul copt al benzii + fractia pe index = exact `--frac` din
##     tools/snapshot.gd (pe o scurtatura, fractia e din lungimea EI, ca la
##     `--route`), deci randul `snapshot:` se lipeste direct in linia de comanda;
##   - metri pe tur, lateral cu semn fata de ax (+ = dreapta sensului) si
##     latimea locala — „pe marginea din dreapta, la iesirea din viraj";
##   - cota fata de ax, rotile pe sol, unghiul fata de sensul drumului;
##   - indexul GLOBAL (cautat pe toata bucla) cand difera de cel tinut de
##     masina: trackerul pierdut e o clasa de bug in sine (vezi
##     Track.reacquire_index);
##   - cele mai apropiate noduri SCRISE in .tscn-ul pistei (owner = pista), cu
##     calea lor — se gasesc cu grep in scena, spre deosebire de o fractie.
##
## F3 comuta panoul (setarea `GameState.show_location`, persistata; pe telefon
## din SETARI). F5 sau atingere pe panou = PIN: blocul merge in clipboard, in
## consola si se adauga in `user://location_pins.txt`, ca o tura intreaga de
## locuri marcate sa poata fi citita dupa.

const REFRESH_S: float = 0.1
const NEAREST_COUNT: int = 3
## Peste atat, „cel mai apropiat nod" nu mai descrie locul, doar zgomot.
const NEAREST_MAX_M: float = 120.0
## Diferenta de index (in puncte) peste care indexul global se raporteaza.
const INDEX_MISMATCH_PTS: int = 6
const PINS_PATH: String = "user://location_pins.txt"

var car: Car
var track: Track
var track_index: int = 0
## Ceasul cursei in ms (Race._clock_ms): hazardele mobile au ceas, deci locul
## fara moment e doar jumatate din reproducere.
var race_clock: Callable

var _panel: PanelContainer
var _label: Label
var _toast: Label
var _toast_t: float = 0.0
var _clock: float = 0.0
var _text: String = ""
var _authored: Array[Node3D] = []
var _authored_scanned: bool = false
var _pins: int = 0


func _ready() -> void:
	# Sub HUD (layer 1): meniul de pauza deseneaza peste panou, nu invers.
	layer = 0
	# Merge si in pauza: „am pus pauza fix aici" e cel mai precis pin.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT,
		Control.PRESET_MODE_MINSIZE, 12)
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_panel_input)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_label)
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 14)
	_toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.text = "[F3] hide   [F5]/tap: pin + copy"
	box.add_child(_toast)
	_panel.visible = GameState.show_location


func _process(delta: float) -> void:
	_panel.visible = GameState.show_location
	if not _panel.visible or not is_instance_valid(car) or track == null:
		return
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_toast.text = "[F3] hide   [F5]/tap: pin + copy"
	_clock += delta
	if _clock < REFRESH_S and _text != "":
		return
	_clock = 0.0
	_text = _compose()
	_label.text = _text


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F3:
		GameState.show_location = not GameState.show_location
		GameState.save_settings()
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_F5 and GameState.show_location:
		pin()
		get_viewport().set_input_as_handled()


## Doar clicul: proiectul emuleaza atingerea din mouse SI mouse-ul din atingere,
## deci pe ambele platforme sosesc amandoua — tratate amandoua, un tap = 2 pinuri.
func _on_panel_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		pin()
		_panel.accept_event()


## Blocul curent -> clipboard + consola + fisierul de pinuri.
func pin() -> void:
	if not is_instance_valid(car) or track == null:
		return
	_text = _compose(true)
	_label.text = _text
	_pins += 1
	var stamp := Time.get_datetime_string_from_system(false, true)
	var entry := "--- pin %d  %s\n%s\n" % [_pins, stamp, _text]
	DisplayServer.clipboard_set(_text)
	print(entry)
	var f: FileAccess
	if FileAccess.file_exists(PINS_PATH):
		f = FileAccess.open(PINS_PATH, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(PINS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(entry + "\n")
		f.close()
	_toast.text = "PIN %d copied -> %s" % [_pins,
		ProjectSettings.globalize_path(PINS_PATH)]
	_toast_t = 3.0


func _compose(force_near: bool = false) -> String:
	var r := track.route_at(car.route)
	if r == null or r.count() < 2:
		return "[LOC] no route"
	var n := r.count()
	var idx := r.wrap_index(car.road_index)
	var pos := car.global_position
	var axis := r.baked[idx]
	var nxt := r.baked[r.wrap_index(idx + 1)]
	var road_dir := Vector3(nxt.x - axis.x, 0.0, nxt.z - axis.z).normalized()
	# Mijlocul segmentului, nu capatul: snapshot.gd face `int(frac * n)`, deci
	# 306/578 rotunjit la 0.5294 ajungea inapoi la 305 (0.5294 * 578 = 305.99).
	# Cu +0.5 si 5 zecimale eroarea ramane sub jumatate de punct pana la 10^4.
	var snap_frac := (float(idx) + 0.5) / float(n)
	var lap_frac := track.frac_at(idx, car.route)

	var along: float
	var lateral: float
	var half: float
	if car.route == 0:
		var rc := track.road_coords(idx, pos)
		along = rc.x
		lateral = rc.y
		half = track.width_at_index(idx)
	else:
		along = r.dists[idx] + (pos - axis).dot(road_dir)
		lateral = (pos - axis).dot(r.side_at(idx))
		half = r.half_width
	var on_road := track.is_on_road(idx, pos, car.route)
	var surface := "OFF-ROAD"
	if on_road:
		if car.route == 0:
			surface = "road (%s%s)" % [track.road_surface,
				", loose" if track.road_is_loose_at(lap_frac) else ""]
		else:
			surface = "route '%s' (%s)" % [r.label, r.surface]

	var fwd := -car.global_transform.basis.z
	var fwd_xz := Vector3(fwd.x, 0.0, fwd.z).normalized()
	# 0° = -Z (inainte in conventia Godot), creste spre +X.
	var heading := fposmod(rad_to_deg(atan2(fwd_xz.x, -fwd_xz.z)), 360.0)
	var vs_road := rad_to_deg(road_dir.signed_angle_to(fwd_xz, Vector3.DOWN))
	var wrong_way := "  WRONG WAY" if absf(vs_road) > 100.0 else ""

	var lines: PackedStringArray = []
	var clock_txt := ""
	if race_clock.is_valid():
		var ms := int(race_clock.call())
		@warning_ignore("integer_division")
		clock_txt = " · race %d:%02d.%d" % [ms / 60000, (ms % 60000) / 1000,
			(ms % 1000) / 100]
	lines.append("[LOC] %s · track %d (%s)%s" % [track.track_name, track_index,
		track.scene_file_path.get_file(), clock_txt])
	var route_txt := "main" if car.route == 0 else "route %d '%s'" % [car.route, r.label]
	lines.append("idx %d/%d %s · frac %.5f · lap %.1f%% · %.0f / %.0f m" % [
		idx, n, route_txt, snap_frac, lap_frac * 100.0, along, r.length()])
	var gidx := track.closest_index_global(pos, car.route)
	var gap := absi(gidx - idx)
	if r.closed:
		gap = mini(gap, n - gap)
	if gap > INDEX_MISMATCH_PTS:
		lines.append("!! global idx %d (frac %.4f) != car idx %d — tracker off by %d pts" % [
			gidx, float(gidx) / float(n), idx, gap])
	lines.append("lateral %+.1f m %s (half-width %.1f) · %s · dy %+.1f m · wheels %d/4" % [
		lateral, "R" if lateral >= 0.0 else "L", half, surface, pos.y - axis.y,
		car.wheels_on_ground])
	lines.append("pos (%.1f, %.1f, %.1f) · heading %.0f° · vs road %+.0f°%s · %.0f km/h%s" % [
		pos.x, pos.y, pos.z, heading, vs_road, wrong_way,
		car.horizontal_speed() * 3.6, " · DRIFT" if car.is_drifting else ""])
	var near := _nearest_text(pos, fwd_xz, force_near)
	if near != "":
		lines.append("near: " + near)
	var route_arg := "" if car.route == 0 else " --route=%d" % car.route
	lines.append("snapshot: --track=%d --frac=%.5f%s --gamecam" % [
		track_index, snap_frac, route_arg])
	return "\n".join(lines)


## Noduri scrise de mana in scena pistei (owner = pista), fara containere:
## un grup ca DecorManual sta in origine si ar fi „cel mai aproape" oriunde.
## Scanat o data, la prima afisare; pozitiile se citesc la fiecare refresh
## (hazardele se misca).
func _scan_authored() -> void:
	_authored_scanned = true
	_authored.clear()
	for n in track.find_children("*", "Node3D", true, false):
		var node := n as Node3D
		if node.owner != track or node is Light3D or node is Camera3D \
				or node is Path3D:
			continue
		var is_group := false
		for c in node.get_children():
			if c.owner == track:
				is_group = true
				break
		if not is_group:
			_authored.append(node)


## Cel mai scump rand: Angkor are ~2000 de noduri scrise, ~1 ms pe scanare
## (masurat). Deci lista se recalculeaza la NEAREST_REFRESH_S, nu la fiecare
## refresh, si fara sortarea intregii liste — doar primele NEAREST_COUNT.
const NEAREST_REFRESH_S: float = 0.5
var _near_nodes: Array[Node3D] = []
var _near_clock: float = INF


func _nearest_text(pos: Vector3, fwd_xz: Vector3, force: bool = false) -> String:
	if not _authored_scanned:
		_scan_authored()
	_near_clock += REFRESH_S
	if force or _near_clock >= NEAREST_REFRESH_S:
		_near_clock = 0.0
		_near_nodes.clear()
		var near_d2: Array[float] = []
		var max_d2 := NEAREST_MAX_M * NEAREST_MAX_M
		for node in _authored:
			if not is_instance_valid(node):
				continue
			var d2 := node.global_position.distance_squared_to(pos)
			if d2 > max_d2:
				continue
			# Insertie in lista scurta ordonata.
			var k := near_d2.size()
			while k > 0 and near_d2[k - 1] > d2:
				k -= 1
			if k >= NEAREST_COUNT:
				continue
			near_d2.insert(k, d2)
			_near_nodes.insert(k, node)
			if near_d2.size() > NEAREST_COUNT:
				near_d2.resize(NEAREST_COUNT)
				_near_nodes.resize(NEAREST_COUNT)
	# Distanta si directia se recitesc mereu: ieftine, si se misca odata cu masina.
	var right := fwd_xz.cross(Vector3.UP)
	var parts: PackedStringArray = []
	for node in _near_nodes:
		if not is_instance_valid(node):
			continue
		var rel := node.global_position - pos
		var f := rel.dot(fwd_xz)
		var s := rel.dot(right)
		var where := "ahead" if f >= 0.0 else "behind"
		if absf(s) > absf(f) * 0.4:
			where += "-R" if s > 0.0 else "-L"
		parts.append("%s %.0f m %s" % [track.get_path_to(node), rel.length(), where])
	return " · ".join(parts)
