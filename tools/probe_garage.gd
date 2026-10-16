extends Node
## Garda garajului: verifica panoul de selectie a masinii — normalizarea
## barelor, indicatorul de masa, conturul-fantoma si vitrina 3D.
##
## DOUA MODURI, fiindca doua lucruri diferite se pot strica:
##
##   --check   logica, merge HEADLESS. Pune panoul in scena, il plimba prin
##             toate masinile si masoara ce iese din el. Asta intra in
##             verify_local.sh.
##   (implicit) captura PNG, cere FEREASTRA (randarea nu merge headless —
##             vezi nota din snapshot.gd si memoria `snapshot-nu-merge-headless`).
##
## Rulare:
##   Godot --headless --path . res://tools/ProbeGarage.tscn -- --check
##   Godot --path . res://tools/ProbeGarage.tscn -- --car=3 --out=snapshots/garage.png
##
## --- Ce masoara `--check` si DE CE fiecare prag ---
##
## 1. SEPARARE. Diferenta dintre doua masini vecine la viteza trebuie sa se
##    vada pe bara. Garajul are plafoane intre 30 si 37 m/s: normalizate de la
##    ZERO, toate masinile ar sta intre 0.81 si 1.00 — 19% de bara pentru tot
##    garajul, adica vizual identice. Pragul cere ca intervalul acoperit de
##    masini sa fie de cel putin `MIN_SPREAD` din bara. E garda impotriva
##    intoarcerii la normalizarea naiva.
##
## 2. PODEA. Cea mai slaba masina NU are voie sa aiba bara goala: si autobuzul
##    merge cu 30 m/s, iar o bara la zero ar citi „n-are deloc".
##
## 3. MASA CENTRATA. Cea mai usoara masina trebuie sa dea offset negativ, cea
##    mai grea pozitiv, si trebuie sa existe cel putin una de fiecare parte.
##    Daca cineva transforma masa inapoi intr-o bara care se umple, semnul
##    dispare si verificarea pica. Asta e contractul din CLAUDE.md principiul
##    4: masinile sunt stiluri, nu upgrade-uri.
##
## 4. FANTOMA BIDIRECTIONALA. Exista cel putin o pereche (vitrina, selectata)
##    pentru care fantoma cade la STANGA capatului plin. Daca fantoma ar fi
##    fost desenata ca „restul pana la maxim" (cum arata in mockup-ul de
##    referinta), n-ar fi putut sta niciodata la stanga.
##
## 5. VITRINA. Dupa `show_car`, sub-viewport-ul chiar are un model cu
##    MeshInstance3D-uri, si masinile cu `open_cockpit` au si figurina.
##    Memoria `efecte-invizibile-nu-se-numara` spune de ce nu ne oprim la
##    „scriptul n-a crapat": numaram nodurile de mesh, nu apelurile.

## Cat din bara trebuie sa acopere garajul, de la cea mai slaba la cea mai
## buna masina. 0.6 = diferentele reale ocupa macar 60% din latime.
const MIN_SPREAD := 0.6
## Podeaua barei pentru cea mai slaba masina (GaragePanel.BAR_FLOOR = 0.18).
const MIN_FLOOR := 0.10

var _fails: Array[String] = []
var _notes: Array[String] = []


func _ready() -> void:
	var check := false
	var out := "snapshots/garage.png"
	var car := -1
	for arg in OS.get_cmdline_user_args():
		if arg == "--check":
			check = true
		elif arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg.begins_with("--car="):
			car = int(arg.substr(6))

	var panel := GaragePanel.new()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame

	if check:
		_run_checks(panel)
		_report()
		return

	if car >= 0:
		panel._show(car)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := out.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(out)
	print("probe_garage: %s (%dx%d)" % [out, img.get_width(), img.get_height()])
	get_tree().quit()


func _run_checks(panel: GaragePanel) -> void:
	var n := GameState.CAR_DATA.size()
	if n < 2:
		_fails.append("garajul are %d masini — nimic de comparat" % n)
		return

	# --- 1 + 2: separare si podea, pe fiecare statistica ---
	var stats := {
		"SPEED": [panel._range_speed, "max_speed"],
		"ACCEL": [panel._range_accel, "acceleration"],
		"GRIP": [panel._range_grip, "grip"],
	}
	for label in stats:
		var limits: Vector2 = stats[label][0]
		var field: String = stats[label][1]
		var lo := 2.0
		var hi := -1.0
		for res in GameState.CAR_DATA:
			var f := panel._norm((res as CarData).get(field), limits)
			lo = minf(lo, f)
			hi = maxf(hi, f)
		var spread := hi - lo
		_notes.append("%s: bara %.2f..%.2f (acoperire %.0f%%)" % [
			label, lo, hi, spread * 100.0])
		if spread < MIN_SPREAD:
			_fails.append(("%s: masinile acopera doar %.0f%% din bara "
				+ "(minim %.0f%%) — normalizare pe [0,max] in loc de "
				+ "intervalul garajului?") % [
				label, spread * 100.0, MIN_SPREAD * 100.0])
		if lo < MIN_FLOOR:
			_fails.append(("%s: cea mai slaba masina are bara la %.2f "
				+ "(minim %.2f) — citeste ca „n-are deloc”") % [
				label, lo, MIN_FLOOR])

	# --- 3: masa e o axa cu semn, nu o bara care se umple ---
	var light := 1.0
	var heavy := -1.0
	var lightest_name := ""
	var heaviest_name := ""
	var lightest_mass := 99.0
	var heaviest_mass := -1.0
	for res in GameState.CAR_DATA:
		var data := res as CarData
		var off := panel._mass_offset(data.mass_factor)
		light = minf(light, off)
		heavy = maxf(heavy, off)
		if data.mass_factor < lightest_mass:
			lightest_mass = data.mass_factor
			lightest_name = data.display_name
		if data.mass_factor > heaviest_mass:
			heaviest_mass = data.mass_factor
			heaviest_name = data.display_name
	_notes.append("MASS: %s %.2f -> %.2f | %s %.2f -> %.2f" % [
		lightest_name, lightest_mass, light,
		heaviest_name, heaviest_mass, heavy])
	if light >= 0.0:
		_fails.append(("masa: cea mai usoara masina (%s) da offset %.2f, "
			+ "nu negativ — indicatorul nu mai e centrat") % [
			lightest_name, light])
	if heavy <= 0.0:
		_fails.append(("masa: cea mai grea masina (%s) da offset %.2f, "
			+ "nu pozitiv") % [heaviest_name, heavy])
	# Cuvantul trebuie sa urmeze semnul, altfel eticheta minte.
	if panel._mass_word(lightest_mass) != "USOARA":
		_fails.append("masa: %s (%.2f) e etichetata „%s”, nu USOARA" % [
			lightest_name, lightest_mass, panel._mass_word(lightest_mass)])
	if panel._mass_word(heaviest_mass) != "GREA":
		_fails.append("masa: %s (%.2f) e etichetata „%s”, nu GREA" % [
			heaviest_name, heaviest_mass, panel._mass_word(heaviest_mass)])

	# --- 4: fantoma poate cadea si la stanga capatului plin ---
	# Se pune selectia pe cea mai RAPIDA masina si se uita la cea mai lenta:
	# atunci reperul trebuie sa fie la dreapta. Apoi invers. Daca fantoma ar
	# fi „restul pana la maxim", al doilea caz ar fi imposibil.
	var fastest := 0
	var slowest := 0
	for i in n:
		var s := (GameState.CAR_DATA[i] as CarData).max_speed
		if s > (GameState.CAR_DATA[fastest] as CarData).max_speed:
			fastest = i
		if s < (GameState.CAR_DATA[slowest] as CarData).max_speed:
			slowest = i
	var keep := GameState.selected_car
	var left_seen := false
	var right_seen := false
	for pair in [[fastest, slowest], [slowest, fastest]]:
		GameState.selected_car = pair[0]
		panel._show(pair[1])
		var bar: GaragePanel.BarDraw = panel._bars[0]._bar
		if bar.ghost < 0.0:
			_fails.append("fantoma lipseste cand vitrina != selectia")
			continue
		if bar.ghost < bar.fill:
			left_seen = true
		elif bar.ghost > bar.fill:
			right_seen = true
	GameState.selected_car = keep
	if not left_seen:
		_fails.append("fantoma n-a cazut niciodata la STANGA umplerii — "
			+ "e desenata ca „rest pana la maxim”, nu ca reper de comparatie")
	if not right_seen:
		_fails.append("fantoma n-a cazut niciodata la dreapta umplerii")
	_notes.append("fantoma: stanga=%s dreapta=%s" % [left_seen, right_seen])

	# Pe masina selectata, fantoma trebuie sa DISPARA (n-ai cu ce compara).
	panel._show(GameState.selected_car)
	if (panel._bars[0]._bar as GaragePanel.BarDraw).ghost >= 0.0:
		_fails.append("fantoma ramane vizibila pe masina chiar selectata")

	# --- 5: INCADRAREA. Gabaritul masinii, proiectat prin camera vitrinei,
	# trebuie sa cada intreg in cadru. Prima captura avea masina taiata de jos
	# si impinsa sub panoul de statistici — o sonda care numara doar mesh-uri
	# n-ar fi vazut niciodata asta (memoria `procent-de-culoare-nu-e-dovada`:
	# captura bate cifra, dar o cifra pe geometria REALA prinde regresia).
	_check_framing(panel)

	# --- 6: masina primeste LUMINA DIRECTA ---
	# Intr-o incapere inchisa asta nu e garantat si nu se vede dintr-o privire:
	# atelierul avea soarele intrand pe usa, dar raza care trece pe sub
	# buiandrug atingea podeaua abia la z=-4.08, iar masina sta la z=0. Toata
	# vitrina parea doar "cam intunecata", cand de fapt subiectul era integral
	# in umbra si n-avea umbra proprie — adica fix contactul cu solul pentru
	# care s-au pornit umbrele lipsea.
	_check_sunlight(panel)

	# --- 7: vitrina chiar are un model, pe fiecare masina ---
	for i in n:
		var data := GameState.CAR_DATA[i] as CarData
		panel._show(i)
		var meshes := panel._preview._model_root.find_children(
			"*", "MeshInstance3D", true, false).size()
		_notes.append("%s: %d mesh-uri in vitrina" % [data.display_name, meshes])
		if meshes == 0:
			_fails.append("%s: vitrina n-are niciun MeshInstance3D" % \
				data.display_name)
		if data.open_cockpit and data.driver_model != null:
			# Soferul se verifica pe NUMELE pieselor (Driver.PART_NAMES), nu
			# pe numarul total de mesh-uri. Masurat: fiecare caroserie are
			# exact 7 mesh-uri si figurina tot 7, deci un prag pe total ar fi
			# trecut si cu figurina pe jumatate — cifra ar fi fost 14 oricum.
			# Vezi memoria `efecte-invizibile-nu-se-numara`.
			var found: Array[String] = []
			for part in Driver.PART_NAMES:
				if not panel._preview._model_root.find_children(
						String(part), "MeshInstance3D", true, false).is_empty():
					found.append(String(part))
			if found.size() != Driver.PART_NAMES.size():
				_fails.append(("%s are open_cockpit, dar figurina are %d/%d "
					+ "piese in vitrina (lipsesc: %s)") % [
					data.display_name, found.size(), Driver.PART_NAMES.size(),
					", ".join(Array(Driver.PART_NAMES).filter(
						func(p): return not String(p) in found))])


## Proiecteaza colturile gabaritului fiecarei masini prin camera vitrinei si
## verifica ca TOATE cad in dreptunghiul [0,1]x[0,1] al cadrului, cu o rama de
## siguranta. Cutia e lungime x latime x o inaltime generoasa (rollbar, scaune,
## figurina — nimic din astea nu e in CarData).
func _check_framing(panel: GaragePanel) -> void:
	var preview := panel._preview
	var cam := preview._camera
	var vp := preview._viewport
	for i in GameState.CAR_DATA.size():
		var data := GameState.CAR_DATA[i] as CarData
		panel._show(i)
		var hl := data.body_length * 0.5
		var hw := data.body_width * 0.5
		var top := maxf(data.body_length * 0.42, 1.6) # cat urca rollbar+sofer
		var worst_x := 0.0
		var worst_y := 0.0
		# Pivotul se roteste; incadrarea trebuie sa tina pe TOT tur-ul, nu doar
		# pe unghiul de start. Altfel masina iese din cadru dupa doua secunde.
		for step in 12:
			var yaw := TAU * float(step) / 12.0
			var basis := Basis(Vector3.UP, yaw)
			for sx in [-1.0, 1.0]:
				for sy in [0.0, 1.0]:
					for sz in [-1.0, 1.0]:
						# Masina sta pe fata de sus a podiumului, nu pe y=0.
						var local := Vector3(sx * hw,
							CarPreview.PODIUM_H + sy * top, sz * hl)
						var world: Vector3 = basis * local
						if cam.is_position_behind(world):
							_fails.append("%s: colt in spatele camerei" % 								data.display_name)
							continue
						var p2 := cam.unproject_position(world)
						var u := p2.x / float(vp.size.x)
						var v := p2.y / float(vp.size.y)
						worst_x = maxf(worst_x, maxf(-u, u - 1.0))
						worst_y = maxf(worst_y, maxf(-v, v - 1.0))
		_notes.append("%s: depasire cadru x=%.3f y=%.3f" % [
			data.display_name, worst_x, worst_y])
		if worst_x > 0.0 or worst_y > 0.0:
			_fails.append(("%s: gabaritul iese din cadru (x %.3f, y %.3f din "
				+ "latura) — masina apare taiata in vitrina") % [
				data.display_name, worst_x, worst_y])


## Verifica, geometric, ca soarele ajunge la masina.
##
## NU prin raycast fizic: atelierul e decor pur, fara corpuri de coliziune, deci
## `direct_space_state` n-are ce intersecta si garda ar fi trecut mereu — exact
## tiparul "sonda masura alt obiect". Se intersecteaza raza cu TRIUNGHIURILE
## mesh-urilor de atelier, care sunt singura geometrie reala de acolo.
func _check_sunlight(panel: GaragePanel) -> void:
	var preview := panel._preview
	var world: Node3D = preview._viewport.get_child(0)
	var sun: DirectionalLight3D = null
	for n in world.get_children():
		var l := n as DirectionalLight3D
		if l != null and l.shadow_enabled:
			sun = l
			break
	if sun == null:
		_fails.append("vitrina n-are directionala cu umbre — fara ea masina "
			+ "pluteste peste fundal (CLAUDE.md, contactul cu solul)")
		return
	var atelier := world.find_child("Atelier", false, false)
	if atelier == null:
		_notes.append("lumina: vitrina n-are atelier, nimic de ocluzat")
		return
	# Directia DINSPRE care vine lumina = +Z al basisului luminii.
	var to_sun := sun.global_transform.basis.z.normalized()
	var tris := _collect_triangles(atelier)
	_notes.append("lumina: %d triunghiuri de atelier testate" % (tris.size() / 3))
	var probes := [Vector3(0, 1.0, 0), Vector3(-0.9, 0.9, -1.2),
		Vector3(0.9, 0.9, 1.2)]
	var blocked := 0
	for origin in probes:
		if _ray_hits(tris, origin + to_sun * 0.05, to_sun):
			blocked += 1
	_notes.append("lumina: %d/%d puncte de pe masina in umbra" % [
		blocked, probes.size()])
	if blocked == probes.size():
		_fails.append("masina e INTEGRAL in umbra: niciunul dintre cele %d "
			% probes.size()
			+ "puncte nu vede soarele. Fara lumina directa nu exista nici "
			+ "umbra proprie, deci nici contact cu solul.")


## Toate triunghiurile mesh-urilor din `root`, in spatiul lumii.
func _collect_triangles(root: Node) -> PackedVector3Array:
	var out := PackedVector3Array()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var mesh := mi.mesh
		if mesh == null:
			continue
		var xf := mi.global_transform
		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if idx.is_empty():
				for v in verts:
					out.append(xf * v)
			else:
				for i in idx:
					out.append(xf * verts[i])
	return out


## Möller–Trumbore: raza loveste vreun triunghi?
func _ray_hits(tris: PackedVector3Array, origin: Vector3,
		dir: Vector3) -> bool:
	var i := 0
	while i + 2 < tris.size():
		var e1 := tris[i + 1] - tris[i]
		var e2 := tris[i + 2] - tris[i]
		var h := dir.cross(e2)
		var a := e1.dot(h)
		if absf(a) > 1e-7:
			var f := 1.0 / a
			var sv := origin - tris[i]
			var u := f * sv.dot(h)
			if u >= 0.0 and u <= 1.0:
				var q := sv.cross(e1)
				var v := f * dir.dot(q)
				if v >= 0.0 and u + v <= 1.0 and f * e2.dot(q) > 1e-4:
					return true
		i += 3
	return false


func _report() -> void:
	for note in _notes:
		print("  ", note)
	if _fails.is_empty():
		print("probe_garage: OK (%d masini)" % GameState.CAR_DATA.size())
		get_tree().quit()
		return
	for f in _fails:
		printerr("probe_garage: ", f)
	print("probe_garage: %d PROBLEME" % _fails.size())
	get_tree().quit(1)
