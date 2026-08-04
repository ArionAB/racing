class_name CameraTuner
extends CanvasLayer
## Reglaj de camera DIN VOLAN, pe taste, in timpul cursei.
##
## De ce exista, desi setarile au deja slidere: incadrarea se judeca stand, dar
## LENEA camerei se judeca doar conducand — cat ramane in urma intr-un drift, cat
## te ajuta la intrarea in ac de par. Un slider din meniul de pauza inseamna
## oprit, tras, repornit, uitat cum era; aici tii tasta apasata in mijlocul
## virajului si vezi diferenta pe loc.
##
## Suprapunerea arata si **valorile absolute** (metri, grade), nu doar factorii:
## cand reglajul se opreste undeva bun, alea sunt cifrele care se scriu in
## `ChaseCamera` ca sa devina implicitul tuturor. Fara ele, o sesiune de reglaj
## se termina cu "e mai bine asa" si nimic de comis.
##
## Traieste doar in build-urile de debug (`OS.is_debug_build()`, vezi race.gd):
## e unealta de dezvoltare, iar pe telefon oricum n-ai tastatura.

## Cat se schimba pe secunda de tinut apasat, in unitati REALE — asa pasul se
## simte la fel indiferent cat de departe e deja camera.
const RATE_DISTANCE: float = 6.0   # m/s
const RATE_HEIGHT: float = 5.0     # m/s
const RATE_FOV: float = 14.0       # grade/s
const RATE_FOLLOW: float = 1.6     # unitati/s

## Cat sta linistit dupa ultima apasare inainte sa scrie fisierul de setari.
## Salvarea in fiecare cadru cat tii tasta ar insemna zeci de scrieri pe disc
## pentru un singur reglaj.
const SAVE_DELAY: float = 0.6

var camera: ChaseCamera

var _label: Label
var _visible: bool = false
var _dirty: float = -1.0


func _ready() -> void:
	layer = 3 # peste HUD, sub nimic
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 6)
	_label.position = Vector2(24, 200)
	_label.visible = false
	add_child(_label)


## Comutatorul si reset-ul se citesc pe EVENIMENT, nu pe stare: tinute apasate,
## ar comuta de saizeci de ori pe secunda. Reglajele propriu-zise fac invers,
## fiindca acolo tocmai tinutul apasat e modul de folosire.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F2:
		_toggle(not _visible)
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_F4 and _visible:
		GameState.reset_camera_settings()
		_apply()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _visible:
		return
	_tick_keys(delta)
	if _dirty > 0.0:
		_dirty -= delta
		if _dirty <= 0.0:
			GameState.save_settings()
	_label.text = _report()


func _toggle(on: bool) -> void:
	_visible = on
	_label.visible = on


## Fiecare pereche de taste muta factorul respectiv. Pasul se calculeaza in
## unitati reale si se imparte la valoarea de referinta: altfel acelasi "+1 pe
## secunda" ar insemna 8% pe distanta si 25% pe FOV.
func _tick_keys(delta: float) -> void:
	var moved := false
	moved = _nudge(KEY_J, KEY_L, delta * RATE_DISTANCE / ChaseCamera.DEFAULT_DISTANCE,
		"cam_distance_scale", 0.5, 2.0) or moved
	moved = _nudge(KEY_K, KEY_I, delta * RATE_HEIGHT / ChaseCamera.DEFAULT_HEIGHT,
		"cam_height_scale", 0.4, 2.0) or moved
	moved = _nudge(KEY_U, KEY_O, delta * RATE_FOV / ChaseCamera.BASE_FOV,
		"cam_fov_scale", 0.7, 1.3) or moved
	moved = _nudge(KEY_N, KEY_M,
		delta * RATE_FOLLOW / ChaseCamera.DEFAULT_FOLLOW_SPEED,
		"cam_follow_scale", 0.4, 2.5) or moved
	if moved:
		_apply()


func _nudge(key_down: int, key_up: int, step: float, prop: String,
		lo: float, hi: float) -> bool:
	var dir := 0.0
	if Input.is_key_pressed(key_down):
		dir -= 1.0
	if Input.is_key_pressed(key_up):
		dir += 1.0
	if is_zero_approx(dir):
		return false
	GameState.set(prop, clampf(float(GameState.get(prop)) + dir * step, lo, hi))
	return true


func _apply() -> void:
	get_tree().call_group(ChaseCamera.GROUP, &"refresh_from_settings")
	_dirty = SAVE_DELAY


## Ce se vede pe ecran. Ultimele doua randuri sunt intentionat gata de copiat in
## `chase_camera.gd` — de la reglaj la valoarea implicita fara nicio conversie
## facuta de mana (si fara greseala de conversie).
func _report() -> String:
	if camera == null:
		return ""
	var lines := PackedStringArray()
	lines.append("CAMERA  [F2] inchide  [F4] reset")
	lines.append("  J/L distanta   %5.2f m  (%3d%%)"
		% [camera.distance, roundi(GameState.cam_distance_scale * 100.0)])
	lines.append("  K/I inaltime   %5.2f m  (%3d%%)"
		% [camera.height, roundi(GameState.cam_height_scale * 100.0)])
	lines.append("  U/O fov        %5.1f°   (%3d%%)"
		% [camera.base_fov, roundi(GameState.cam_fov_scale * 100.0)])
	lines.append("  N/M urmarire   %5.2f    (%3d%%)"
		% [camera.follow_speed, roundi(GameState.cam_follow_scale * 100.0)])
	lines.append("  unghi          %5.1f° in jos" % camera.pitch_degrees())
	lines.append("")
	lines.append("de scris in chase_camera.gd (masina de referinta 4.20 m):")
	# Cotele se impart inapoi la lungimea vehiculului curent: daca reglezi pe
	# autobuz, cifrele de mai jos sunt tot cele ale masinii de referinta, adica
	# exact ce inseamna constantele din cod.
	var ref := ChaseCamera.REFERENCE_LENGTH
	lines.append("  DEFAULT_DISTANCE %.2f   DEFAULT_HEIGHT %.2f"
		% [ChaseCamera.distance_for(ref) * GameState.cam_distance_scale,
			ChaseCamera.height_for(ref) * GameState.cam_height_scale])
	lines.append("  BASE_FOV %.1f   DEFAULT_FOLLOW_SPEED %.2f"
		% [camera.base_fov, camera.follow_speed])
	return "\n".join(lines)
