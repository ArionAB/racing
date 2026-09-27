extends Node
## Sonda tehnica DuskCycle (Jodhpur, brief §7 pasul 1(c)): dovedeste ca
## ceasul de lumina chiar scrie in obiectele reale (DirectionalLight3D,
## Environment, parametrul global de shader), nu doar in variabile proprii
## ale nodului `DuskCycle` (memoria `sonda-masura-alt-obiect`: o cifra
## identica la bit intre `dusk=0` si `dusk=1` ar insemna neconectat).
##
## Nu construieste Track17 (nu exista inca). Foloseste o pista EXISTENTA cu
## soare jos si cald — Stromboli (Track11, indexul 4 din GameState.TRACK_SCENES,
## memoria `indici-de-pista-intre-unelte`: aici e pozitia din lista, nu
## numarul scenei) — si ii ADAUGA un `DuskCycle` temporar, exact cum fac
## `--dusk=` din snapshot.gd/probe_race.gd/probe_masca.gd pe orice pista fara
## unul propriu.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeJodDusk.tscn
##   ... -- [--track=4]
##
## CE MASOARA:
## 1. Forteaza `dusk` = 0 / 0,25 / 0,5 / 0,75 / 1 (force_value) si CITESTE
##    INAPOI din obiectele reale: elevatia soarelui (`rotation_degrees.x`),
##    `sun.light_energy`, `sun.light_color`, `env.ambient_light_energy`,
##    `env.ambient_light_color`, `env.fog_light_color`, `env.fog_depth_end`
##    — nu `DuskCycle.dusk` insusi, ca sa nu se masoare "ce a calculat
##    nodul", ci "ce a AJUNS in scena". Parametrul global `dusk_lamps` e
##    EXCEPTIA: `RenderingServer.global_shader_parameter_get()` nu se poate
##    citi la runtime in afara editorului (verificat: intoarce `null`
##    necondiționat, cu eroare explicita in log — vezi nota de la
##    `DuskCycle.lamps_value`), deci se citeste `dusk.lamps_value`, oglinda
##    locala a ULTIMEI valori scrise prin `global_shader_parameter_set()`
##    (calea reala, neschimbata, prin care shaderele citesc canalul).
## 2. Verifica pentru fiecare parametru: (a) valoarea la 0 difera de valoarea
##    la 1 (altfel canalul nu e conectat); (b) seria e MONOTONA pe cele 5
##    esantioane (energia soarelui scade, energia ambientului creste, etc. —
##    vezi `_MONOTONE` mai jos pentru sensul asteptat al fiecarui parametru).
## 3. Verifica separat ca `dusk` PE GRILA (fara nicio forta, cu un `Race` care
##    n-a inceput inca — countdown, `player_progress_fraction()` = 0) e chiar
##    0: instantiaza o cursa reala (`Race.tscn`) pe aceeasi pista, cu
##    `DuskCycle` copil, in starea COUNTDOWN, si citeste `dusk_cycle.dusk`
##    inainte de orice tick de cursa (brief §3: "0 pe grila si in countdown").
##
## Tabelul de la (1)+(2) e verdictul principal; (3) e un test separat, mic,
## la finalul rularii.

const STROMBOLI_INDEX: int = 4 # pozitia in TRACK_SCENES (Stromboli = Track11)
const DUSK_SAMPLES: PackedFloat32Array = [0.0, 0.25, 0.5, 0.75, 1.0]
## Sensul asteptat al fiecarui parametru intre dusk=0 si dusk=1: +1 = trebuie
## sa CREASCA monoton, -1 = trebuie sa SCADA monoton. Culorile nu au un sens
## scalar simplu, deci se verifica doar pe canalul care se misca cel mai mult
## (vezi `_color_scalar`).
enum Sense { UP = 1, DOWN = -1 }

var _track_index: int = STROMBOLI_INDEX


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	# Un cadru inainte de add_child pe root (acelasi motiv ca probe_fiord_ploaie:
	# radacina e ocupata cu propria initializare la primul _ready).
	await get_tree().process_frame

	print("=== ProbeJodDusk: DuskCycle pe %s ===" % GameState.track_label(_track_index))

	await _run_table()
	await _run_grid_zero()
	get_tree().quit(0)


# ------------------------------------------------------- tabelul principal

func _run_table() -> void:
	var track := _spawn_track()
	var dusk := DuskCycle.new()
	dusk.name = "DuskCycle"
	track.add_child(dusk)
	await get_tree().process_frame
	await get_tree().process_frame # DuskCycle._collect() e call_deferred

	var sun := dusk.sun()
	var env := dusk.environment()
	if sun == null or env == null:
		print("PICAT: DuskCycle n-a gasit sun=%s env=%s pe pista asta" % [sun, env])
		track.queue_free()
		return

	# Randuri PARALELE, tipizate direct (NU un Dictionary de Dictionary de
	# PackedFloat32Array: un `PackedFloat32Array` scos dintr-o colectie
	# NETIPIZATA vine PRIN VALOARE, deci `.append()` scrie intr-o copie
	# temporara si se pierde — memoria `append-pe-copie-in-array-netipizat`,
	# platita aici la prima rulare: toate coloanele au iesit goale). Indicele
	# `i` in toate array-urile de mai jos se refera la ACELASI parametru.
	var row_names: Array[String] = [
		"sun_elev_deg", "sun_energy", "ambient_energy", "fog_end", "dusk_lamps",
		"sun_color_scalar", "ambient_color_scalar", "fog_color_scalar",
	]
	# Sensul asteptat (Sense.UP/DOWN) sau 0 (culorile: monoton in orice sens
	# consecvent, vezi `_check_table`).
	var row_sense: Array[int] = [
		Sense.DOWN, Sense.DOWN, Sense.UP, Sense.DOWN, Sense.UP, 0, 0, 0,
	]
	var row_vals: Array[PackedFloat32Array] = []
	for _i in row_names.size():
		row_vals.append(PackedFloat32Array())

	for d in DUSK_SAMPLES:
		dusk.force_value(d)
		# `force_value` aplica sincron (`_apply` direct, fara `call_deferred`),
		# dar un cadru de proces confirma ca nu exista vreo cale ascunsa care
		# ar suprascrie starea inainte de citire (acelasi tipar de precautie
		# ca in probe_fiord_ploaie, unde forta era urmata de citiri directe).
		await get_tree().process_frame
		# NU `RenderingServer.global_shader_parameter_get()` — vezi nota din
		# antet si de la `DuskCycle.lamps_value`: intoarce `null` necondiționat
		# la runtime, in afara editorului.
		var sample: PackedFloat32Array = [
			absf(sun.rotation_degrees.x),
			sun.light_energy,
			env.ambient_light_energy,
			env.fog_depth_end,
			dusk.lamps_value,
			_color_scalar(sun.light_color),
			_color_scalar(env.ambient_light_color),
			_color_scalar(env.fog_light_color),
		]
		for i in row_names.size():
			row_vals[i].append(sample[i])

	_print_table(row_names, row_vals)
	var all_ok := _check_table(row_names, row_sense, row_vals)

	print("")
	if all_ok:
		print("VERDICT: TRECUT — toti parametrii difera intre dusk=0 si dusk=1 si sunt monotoni.")
	else:
		print("VERDICT: PICAT — vezi parametrii marcati mai sus.")

	track.queue_free()
	await get_tree().process_frame


## Un scalar din Color, DOAR pentru testul "difera + monoton": suma canalelor
## ponderata spre albastru (culorile cer trec de la portocaliu-cald spre
## indigo-rece, deci albastrul creste consistent chiar daca R si G nu sunt
## monotone separat — vezi KEY_SUN_COLOR in dusk_cycle.gd: FFB27A -> FF8FA0 ->
## 8E9BD6, unde B urca 0,48 -> 0,56 -> 0,84 monoton, spre deosebire de R/G).
func _color_scalar(c: Color) -> float:
	return c.b


func _print_table(row_names: Array[String], row_vals: Array[PackedFloat32Array]) -> void:
	print("")
	var header := "%-22s" % "parametru"
	for d in DUSK_SAMPLES:
		header += "%10s" % ("dusk=%.2f" % d)
	print(header)
	for i in row_names.size():
		var vals := row_vals[i]
		var line := "%-22s" % row_names[i]
		for v in vals:
			line += "%10.4f" % v
		print(line)


func _check_table(row_names: Array[String], row_sense: Array[int],
		row_vals: Array[PackedFloat32Array]) -> bool:
	var ok := true
	for i in row_names.size():
		var key := row_names[i]
		var vals := row_vals[i]
		var sense := row_sense[i]
		var differs := not is_equal_approx(vals[0], vals[vals.size() - 1])
		var mono := true
		if sense != 0:
			for j in range(1, vals.size()):
				var step := vals[j] - vals[j - 1]
				if sense == Sense.UP and step < -0.0001:
					mono = false
				elif sense == Sense.DOWN and step > 0.0001:
					mono = false
		else:
			# Scalarele de culoare: monotonia se verifica DOAR pe pasii dintre
			# indicii 2,3,4 (dusk 0,5 -> 0,75 -> 1,0), care e lerp PUR intre
			# cheile din brief si nu depinde de tema. Segmentul 0 -> 0,5 e PIVOTAT pe
			# culoarea de baza a PISTEI (`_lerp_key`/`_lerp_color_key` din
			# dusk_cycle.gd: la d=0 rezultatul e culoarea reala a temei, nu
			# cheia din brief) -- pe Stromboli (soare cald, albastru mic) asta
			# da un „V" pe canalul albastru intre 0 si 0,5, care NU e un
			# semn de canal neconectat, e diferenta dintre baza temei si
			# cheia de la 0,5. Contractul real (brief §4) e doar "difera intre
			# 0 si 1"; monotonia se cere unde e bine definita, adica pe partea
			# care nu depinde de pista.
			var up := true
			var down := true
			# j incepe la 3 (nu 2): indicele 2 e chiar d=0,5, capatul de jos
			# al segmentului pur; primul PAS din segmentul pur e vals[3]-vals[2].
			for j in range(3, vals.size()):
				var step := vals[j] - vals[j - 1]
				if step < -0.0001:
					up = false
				if step > 0.0001:
					down = false
			mono = up or down
		var row_ok := differs and mono
		ok = ok and row_ok
		print("  [%s] %s: difera(0,1)=%s monoton=%s"
			% ["OK " if row_ok else "PICAT", key, differs, mono])
	return ok


func _spawn_track() -> Track:
	var scene := load(GameState.TRACK_SCENES[_track_index]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	return track


# --------------------------------------------------- dusk pe grila = 0

## Brief §3: "dusk vine din progresul jucatorului... 0 pe grila si in
## countdown". Se porneste o cursa REALA (Race.tscn) pe aceeasi pista, cu un
## DuskCycle copil al pistei, si se citeste `dusk` INAINTE de orice tick de
## fizica (`_progress` e populat in `_setup()`, deci `player_progress_fraction()`
## e deja calculabil chiar in COUNTDOWN, cu `_progress[0].total` la valoarea
## initiala din grila -- brief-ul cere explicit ca punctul asta sa fie 0, nu
## doar "aproape de 0").
func _run_grid_zero() -> void:
	print("")
	print("-- dusk pe grila (fara forta, Race in COUNTDOWN) --")
	GameState.selected_track = _track_index
	GameState.champ_active = false
	var race := (load("res://scenes/race/Race.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(race)
	await get_tree().process_frame
	await get_tree().process_frame
	var dusk := DuskCycle.new()
	dusk.name = "DuskCycleGrid"
	race.track.add_child(dusk)
	await get_tree().process_frame
	await get_tree().process_frame

	var frac := 0.0
	if race.has_method("player_progress_fraction"):
		frac = float(race.call("player_progress_fraction"))
	print("  Race.state=%s player_progress_fraction()=%.4f DuskCycle.dusk=%.4f"
		% [race.state, frac, dusk.dusk])
	_check(is_equal_approx(frac, 0.0) and is_equal_approx(dusk.dusk, 0.0),
		"dusk = 0 pe grila/countdown (fara nicio forta)")

	race.queue_free()
	await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["OK " if ok else "PICAT", what])
