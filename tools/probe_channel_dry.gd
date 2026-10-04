extends Node
## Garda albiei USCATE ([member TrackChannel.dry]): aceeasi pista construita de
## doua ori, o data cu apa si o data cu `dry = true` pe canalul ei, comparate pe
## ce trebuie sa difere si pe ce trebuie sa ramana la fel.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeChannelDry.tscn \
##       [-- --track=2]
##
## Trebuie rulata ca SCENA (are nevoie de autoload-uri). `--track=` ia pozitie
## sau numar de scena, ca la restul uneltelor (GameState.resolve_track_index);
## implicit Alpii (Track09, `ParaulVaii`): un canal cu `jump` si apa proprie pe o
## tema FARA mare. Tema fara mare conteaza: pe una cu `water: true` (Jodhpur,
## Track17) `water_level_at` raspunde si pentru marea temei, deci „nivel" n-ar
## mai arata daca canalul si-a pierdut apa.
##
## Ce se verifica, per varianta:
##   apa     numarul de noduri `ChannelWater_*`        udat >= 1   uscat == 0
##   zona    numarul de zone `ChannelFall_*`            amandoua >= 1
##   nivel   `water_level_at` in axa canalului          udat > -INF uscat == -INF
##   gol     `_road_gap` pe punctul de desprindere      amandoua true
##   teren   `ground_y` in axa canalului                aceeasi cota in amandoua
##
## Ultimul rand e cel care apara sapatura: un `dry` care ar sari peste
## `_carve_channel` ar ridica fundul albiei si ar fi un gol de sosea peste un
## teren plin. Garda e verificata prin sabotaj (trei, toate pica):
##   - ramura `dry` scoasa din Track._build_channel_water        -> „zona"
##   - `dry` ignorat in TrackChannel.to_spec                      -> „zona"
##   - ramura fara `continue`, `water_y_drop` emis, `water_level_at`
##     fara test `dry` (apa se construieste, se vede)             -> „apa", „nivel"

const DEFAULT_SCENE: String = "res://scenes/tracks/Track09.tscn"

var _fail: int = 0


func _ready() -> void:
	var index := GameState.TRACK_SCENES.find(DEFAULT_SCENE)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			index = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	if index < 0:
		printerr("pista ceruta nu exista (nici ca pozitie, nici ca numar de scena)")
		get_tree().quit(1)
		return
	print("pista: %s" % GameState.track_label(index))
	await get_tree().process_frame

	var wet := await _measure(index, false)
	var dry := await _measure(index, true)
	if int(wet["channels"]) == 0:
		printerr("pista n-are niciun TrackChannel — garda n-a masurat nimic")
		get_tree().quit(1)
		return

	print("            apa  zona  nivel(m)      gol  teren(m)")
	for tag: String in ["wet", "dry"]:
		var m: Dictionary = wet if tag == "wet" else dry
		print("  %-6s %5d %5d  %9s %8s  %8.3f" % [tag, m["water"], m["fall"],
			_fmt_level(m["level"]), m["gap"], m["ground"]])

	_expect(int(wet["water"]) >= 1, "udat: lipseste suprafata de apa")
	_expect(int(dry["water"]) == 0, "uscat: s-a construit totusi apa")
	_expect(int(wet["fall"]) >= 1, "udat: lipseste plasa de cadere")
	_expect(int(dry["fall"]) >= 1, "uscat: canalul a ramas fara plasa de cadere")
	_expect(float(wet["level"]) > -INF, "udat: water_level_at nu vede apa")
	_expect(float(dry["level"]) == -INF, "uscat: water_level_at vede inca apa")
	_expect(bool(wet["gap"]) and bool(dry["gap"]), "golul din sosea lipseste")
	_expect(is_equal_approx(float(wet["ground"]), float(dry["ground"])),
		"sapatura s-a schimbat intre variante (%.3f vs %.3f)"
		% [wet["ground"], dry["ground"]])
	if _fail == 0:
		print("VERDICT: OK")
	else:
		print("VERDICT: PROBLEMA (%d)" % _fail)
	get_tree().quit(0 if _fail == 0 else 1)


func _expect(ok: bool, why: String) -> void:
	if not ok:
		_fail += 1
		print("  PICA: %s" % why)


func _fmt_level(v: float) -> String:
	return "-INF" if v == -INF else "%.2f" % v


## Construieste pista cu toate canalele ei pe `dry = value` si masoara primul
## canal. `dry` se scrie INAINTE de add_child: pista se construieste in _ready.
func _measure(index: int, value: bool) -> Dictionary:
	var track := (load(GameState.TRACK_SCENES[index]) as PackedScene) \
		.instantiate() as Track
	var nodes: Array[TrackChannel] = []
	_collect(track, nodes)
	for ch in nodes:
		ch.dry = value
	get_tree().root.add_child(track)
	# Doua cadre: rebuild() ruleaza in _ready, iar copiii intra in arbore dupa.
	await get_tree().process_frame
	await get_tree().process_frame
	var out := {"channels": nodes.size(), "water": 0, "fall": 0,
		"level": -INF, "gap": false, "ground": 0.0}
	for c in track.get_children():
		if String(c.name).begins_with("ChannelWater_"):
			out["water"] += 1
		elif String(c.name).begins_with("ChannelFall_"):
			out["fall"] += 1
	var chans: Array = track.get("_channels")
	if not chans.is_empty():
		var ch: Dictionary = chans[0]
		var o: Vector3 = ch["origin"]
		out["level"] = track.water_level_at(o)
		out["gap"] = track.call("_road_gap", int(ch["near"]))
		var sampler: TrackSideSampler = track.get("_sampler")
		out["ground"] = sampler.ground_y(o.x, o.z)
	track.queue_free()
	await get_tree().process_frame
	return out


func _collect(node: Node, out: Array[TrackChannel]) -> void:
	for child in node.get_children():
		if child is TrackChannel:
			out.append(child as TrackChannel)
		_collect(child, out)
