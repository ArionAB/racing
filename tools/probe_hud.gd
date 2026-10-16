extends Node
## Captura HUD-ului de cursa, singur, peste un fundal de proba.
##
## De ce o sonda separata si nu `snapshot.gd`: snapshot-ul randeaza pista, nu
## si CanvasLayer-ul HUD-ului, deci nu poate arata niciodata ce s-a schimbat
## in HUD. Sonda asta monteaza `RaceHUD` exact cum il monteaza `Race` si ii da
## valori reprezentative, ca sa se vada ASEZAREA si lizibilitatea, nu doar ca
## scriptul compileaza.
##
## CU FEREASTRA (randarea nu merge headless — vezi snapshot.gd):
##   Godot --path . res://tools/ProbeHUD.tscn -- --bg=nisip
##
##   --out=cale.png   unde se salveaza (implicit snapshots/hud.png)
##   --bg=nisip|zapada|noapte
##                    fundalul de sub HUD. HUD-ul sta peste lumi de culori
##                    foarte diferite; „citibil pe nisip" nu implica „citibil
##                    noaptea", iar panourile translucide se verifica pe
##                    extreme, nu pe o singura tema.
##   --turbo=0.72     cat de plina e bara (1.0 aprinde fulgerul si butonul)

const BACKGROUNDS := {
	"nisip": Color(0.86, 0.76, 0.55),
	"zapada": Color(0.90, 0.93, 0.96),
	"noapte": Color(0.06, 0.07, 0.12),
}

func _ready() -> void:
	var out := "snapshots/hud.png"
	var bg_name := "nisip"
	var turbo := 0.72
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg.begins_with("--bg="):
			bg_name = arg.substr(5)
		elif arg.begins_with("--turbo="):
			turbo = float(arg.substr(8))
	if not BACKGROUNDS.has(bg_name):
		push_error("--bg necunoscut: %s (are: %s)" % [
			bg_name, ", ".join(BACKGROUNDS.keys())])
		get_tree().quit(1)
		return

	# Fundalul plat tine locul lumii. Nu incercam sa randam o pista: ce se
	# verifica aici e contrastul HUD-ului fata de o suprafata mare si uniforma,
	# cazul cel mai rau pentru text cu contur.
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = BACKGROUNDS[bg_name]
	add_child(bg)

	var hud := RaceHUD.new()
	add_child(hud)
	# Minimapa si controalele touch se deseneaza doar dupa ce au date,
	# respectiv dupa prima atingere. Fara pasii astia doi, captura arata un
	# HUD pe jumatate gol si ar fi trecut drept „bine" exact zonele pe care
	# le-am schimbat.
	_fake_minimap(hud)
	# Valorile din mockup: locul 5 din 6, turul 1 din 3, 142 km/h.
	hud.set_info(5, 6, 1, 3, 142.0, "00:05.5", "00:56.7")
	hud.set_detail("race: 00:05.5   rec: 00:54.2   race rec: 02:48.9\n"
		+ "Pickup on Dunele   [SPACE] turbo  [SHIFT] drift")
	hud.set_turbo(turbo, false)

	# Doua cadre: unul ca sa se aseze layout-ul containerelor (dimensiunile
	# reale se afla abia dupa primul `sort_children`), al doilea ca sa se
	# randeze cu ele. O captura dupa un singur cadru prinde panoul la
	# dimensiunea minima, nu la cea finala.
	await get_tree().process_frame
	await get_tree().process_frame
	# Starea de „degete apasate" se pune DUPA asezare: ancorele rescriu `size`
	# dupa `_ready()`, iar butoanele se deseneaza raportat la ea.
	_fake_touch(hud)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var img := get_viewport().get_texture().get_image()
	var dir := out.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(out)
	print("probe_hud: %s (%dx%d, fundal %s)" % [
		out, img.get_width(), img.get_height(), bg_name])
	get_tree().quit()


## Minimapa cu un traseu sintetic. `Minimap.setup()` cere un `Track` si masini
## reale — adica toata lumea fizica — pentru ceva ce se verifica vizual din
## cateva puncte. Scriem direct in starea ei de desen: ce se masoara aici e
## conturul, steguletul si punctele, nu proiectia XZ (aia o verifica cursa).
func _fake_minimap(hud: RaceHUD) -> void:
	# Acelasi motiv ca la `_fake_touch`: cautare pe `is`, nu pe numele clasei.
	var mm: Minimap = null
	for node in hud.find_children("*", "Control", true, false):
		if node is Minimap:
			mm = node as Minimap
			break
	if mm == null:
		push_error("probe_hud: nu gasesc Minimap in HUD")
		return
	var pts := PackedVector2Array()
	# O bucla inchisa, usor turtita si rotita: seamana cu o pista reala mai
	# mult decat un cerc, deci arata si cum se aseaza steguletul pe un traseu
	# care nu e simetric.
	var steps := 48
	for i in steps + 1:
		var a := TAU * float(i) / float(steps)
		var r := 52.0 + 14.0 * sin(a * 3.0)
		pts.append(Vector2(Minimap.MAP_SIZE, Minimap.MAP_SIZE) * 0.5
			+ Vector2(cos(a) * r * 1.12, sin(a) * r * 0.82))
	mm.set("_points", pts)
	mm.set("_finish", pts[0])
	mm.custom_minimum_size = Vector2(Minimap.MAP_SIZE, Minimap.MAP_SIZE)
	mm.queue_redraw()


## Controalele touch cu degete „apasate", ca sa se vada si starea activa.
## `_touches` e starea pe care o scriu evenimentele reale; o populam direct
## fiindca `InputEventScreenTouch` sintetic n-ar ajunge la `_unhandled_input`
## intr-o sonda fara fereastra focalizata.
func _fake_touch(hud: RaceHUD) -> void:
	# Cautam dupa tipul de script, nu prin `find_children(type)`: acolo tipul e
	# clasa de MOTOR, iar `TouchControls` e clasa unui script — filtrul nu o
	# vede si intoarce lista goala (exact asa a ramas prima captura fara
	# butoane, desi codul lor era corect).
	var tc: TouchControls = null
	for node in hud.find_children("*", "Control", true, false):
		if node is TouchControls:
			tc = node as TouchControls
			break
	if tc == null:
		push_error("probe_hud: nu gasesc TouchControls in HUD")
		return
	# Un deget pe viraj-dreapta si unul pe turbo: starea obisnuita intr-un
	# viraj luat cu bara plina, deci si cea in care butoanele se suprapun cel
	# mai mult cu restul HUD-ului.
	tc.set("_touches", {0: "right", 1: "gas"})
	tc.queue_redraw()
	print("probe_hud: TouchControls size = %s" % tc.size)
