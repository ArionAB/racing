extends SceneTree
## Generator de decor MANUAL pentru urcarea de coasta din Okinawa manual
## (fracs ~0.49-0.63, zonele Zone05_CoastalClimb / Zone06_Crest din Track08).
##
## NU e o sonda de verificare — e unealta cu care s-au CALCULAT transformarile
## din Track08.tscn (PR-ul cu decorul urcarii): pozitiile stau pe terenul real
## (`sampler.ground_y`), orientarile pe directia reala a soselei, iar pontonul
## pe linia reala a apei, gasita prin acelasi mars in afara ca in
## TrackScenography._shoreline. "Asezat de mana" inseamna aici ca fiecare piesa
## e o DECIZIE (ce, unde, cat de mare), nu ca cifrele au fost tastate din ochi
## — un obiect pus din ochi la cota gresita pluteste, vezi probe_manual.
##
## Rulare:
##   godot --headless --path . --script res://tools/gen_decor_climb.gd            # emite blocuri .tscn
##   godot --headless --path . --script res://tools/gen_decor_climb.gd -- --scan  # doar terenul (mal, cote)
##
## Iesirea se lipeste in Track08.tscn sub nodurile de zona. Numele de
## ext_resource sunt cele din header-ul scenei — daca adaugi un model nou,
## adauga-i randul si acolo.

const TRACK := "res://scenes/tracks/Track08.tscn"

## id-urile ext_resource din Track08.tscn (existente + cele adaugate de PR).
const RES := {
	"coral_rock": "4_wrrxe",
	"village_house": "4_7180v",
	"banyan": "5_7180v",
	"coconut_palm": "6_jtx8o",
	"sabani_boat": "7_dydiq",
	"beach_palm_bent": "8_dledb",
	"gusuku_wall": "9_gsk",
	"hibiscus_bush": "10_hib",
	"pandanus": "11_pnd",
	"sugar_cane_clump": "12_cane",
	"fence_ranch": "13_fnc",
	"wooden_pier": "14_pier",
}

var _track: Track = null
var _frames := 0
var _scan_only := false

func _initialize() -> void:
	_scan_only = "--scan" in OS.get_cmdline_user_args()


func _process(_delta: float) -> bool:
	if _track == null:
		_track = (load(TRACK) as PackedScene).instantiate() as Track
		root.add_child(_track)
		return false
	_frames += 1
	if _frames < 3:
		return false
	_run()
	quit(0)
	return true


# ------------------------------------------------------------------ nucleu

var _sampler: TrackSideSampler
var _path: TrackScenography._Path
var _sea_y: float
var _rng := RandomNumberGenerator.new()

func _run() -> void:
	_sampler = _track._sampler
	_path = TrackScenography._Path.new(_sampler)
	_sea_y = _sampler.mean_road_y() + _track.sea_level_offset
	_rng.seed = 0xDECC1188
	print("total=%.1f m  sea_y=%.2f  half_width=%.1f"
		% [_path.total, _sea_y, _sampler.half_width()])
	if _scan_only:
		_scan()
		return
	for spec in _specs():
		match String(spec["kind"]):
			"row":
				_emit_row(spec)
			"one":
				_emit_one(spec)
			"pier":
				_emit_pier(spec)


## Terenul, fractie cu fractie: unde e malul si cat de jos e umarul drumului.
## Cu astea se aleg offseturile din _specs() — nu din ochi.
func _scan() -> void:
	var hw := _sampler.half_width()
	var f := 0.48
	while f <= 0.64:
		var st := _path.at(_path.total * f)
		var road: Vector3 = st["pos"]
		var line := "f=%.3f  road_y=%5.1f" % [f, road.y]
		for side: float in [-1.0, 1.0]:
			var out: Vector3 = st["right"] * side
			var shore := TrackScenography._shoreline(_sampler, road, out,
				hw + 1.0, _sea_y)
			var g6 := _sampler.ground_y(road.x + out.x * (hw + 6.0),
				road.z + out.z * (hw + 6.0))
			var g14 := _sampler.ground_y(road.x + out.x * (hw + 14.0),
				road.z + out.z * (hw + 14.0))
			line += "  | s%+d mal=%5.1f  g+6=%5.1f g+14=%5.1f" \
				% [int(side), shore, g6, g14]
		print(line)
		f += 0.005


# ------------------------------------------------------------------ specs
##
## Compozitia, citita din imaginea de referinta si mutata pe geometria reala:
## in imagine zidul de piatra cu gradini de hibiscus e pe o latura, gardul de
## lemn cu bolovani si trestie pe cealalta, iar in golf un ponton cu barca.
## Pe urcarea noastra latura -1 (spre larg) primeste zidul si gradinile —
## continua terasele de gusuku pe care scenografia le opreste la 0.498 — iar
## latura +1 (buza lagunei) primeste gardul, pietrele si trestia. Pontonul
## coboara in golful lagunei, unde il vezi de sus exact ca in referinta.
func _specs() -> Array[Dictionary]:
	return [
		# --- Zone05: zidul de piatra, in continuarea teraselor (stanga) ------
		{"kind": "row", "zone": "Zone05_CoastalClimb", "model": "gusuku_wall",
			"name": "wall", "from": 0.503, "to": 0.532, "spacing": 4.9,
			"side": -1.0, "off": 4.0, "scale": 0.6, "face": "along",
			"sink": 0.2, "keep_cycle": [["Gusuku_Wall_A"], ["Gusuku_Wall_B"]]},
		{"kind": "row", "zone": "Zone05_CoastalClimb", "model": "gusuku_wall",
			"name": "wall_up", "from": 0.552, "to": 0.576, "spacing": 4.9,
			"side": -1.0, "off": 4.4, "scale": 0.6, "face": "along",
			"sink": 0.2, "keep_cycle": [["Gusuku_Wall_A"], ["Gusuku_Wall_B"]]},
		# Gospodaria de pe versantul dinspre larg (in referinta: casele cu olane
		# de pe stanga drumului). STA INAINTE de 0.51: de acolo incepe rapa
		# coamei (ravine 0.510-0.580, ambele laturi) si dincolo de ~6 m de la
		# margine terenul cade cu 6-12 m — masurat cu --scan, nu presupus.
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "village_house",
			"name": "farm_house", "frac": 0.492, "side": -1.0, "off": 15.0,
			"scale": 1.0, "face": "road", "yaw_jitter": 10.0},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "village_house",
			"name": "farm_house2", "frac": 0.502, "side": -1.0, "off": 21.0,
			"scale": 0.95, "face": "road", "yaw_jitter": 10.0},
		# Gradinile: hibiscusul portocaliu e SEMNATURA imaginii de referinta.
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "hibiscus_bush",
			"name": "hib", "frac": 0.506, "side": -1.0, "off": 3.1,
			"scale": 1.7, "face": "random", "sink": 0.05},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "hibiscus_bush",
			"name": "hib2", "frac": 0.518, "side": -1.0, "off": 4.6,
			"scale": 1.5, "face": "random", "sink": 0.05},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "hibiscus_bush",
			"name": "hib3", "frac": 0.530, "side": -1.0, "off": 3.4,
			"scale": 1.9, "face": "random", "sink": 0.05},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "hibiscus_bush",
			"name": "hib4", "frac": 0.549, "side": -1.0, "off": 5.2,
			"scale": 1.6, "face": "random", "sink": 0.05},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "hibiscus_bush",
			"name": "hib5", "frac": 0.563, "side": -1.0, "off": 3.6,
			"scale": 1.8, "face": "random", "sink": 0.05},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "hibiscus_bush",
			"name": "hib6", "frac": 0.575, "side": -1.0, "off": 4.9,
			"scale": 1.5, "face": "random", "sink": 0.05},
		# Palmierii din spatele zidului, ca perdeaua din stanga referintei.
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coconut_palm",
			"name": "palm", "frac": 0.500, "side": -1.0, "off": 8.0,
			"scale": 1.1, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coconut_palm",
			"name": "palm2", "frac": 0.514, "side": -1.0, "off": 9.0,
			"scale": 0.95, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coconut_palm",
			"name": "palm3", "frac": 0.527, "side": -1.0, "off": 7.5,
			"scale": 1.2, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coconut_palm",
			"name": "palm4", "frac": 0.541, "side": -1.0, "off": 8.5,
			"scale": 1.0, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coconut_palm",
			"name": "palm5", "frac": 0.558, "side": -1.0, "off": 8.5,
			"scale": 1.15, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coconut_palm",
			"name": "palm6", "frac": 0.571, "side": -1.0, "off": 9.0,
			"scale": 1.05, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "banyan",
			"name": "banyan_farm", "frac": 0.498, "side": -1.0, "off": 12.0,
			"scale": 1.1, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "pandanus",
			"name": "pand", "frac": 0.496, "side": -1.0, "off": 9.0,
			"scale": 1.15, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "pandanus",
			"name": "pand2", "frac": 0.546, "side": -1.0, "off": 8.0,
			"scale": 1.25, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "beach_palm_bent",
			"name": "bent", "frac": 0.487, "side": -1.0, "off": 17.0,
			"scale": 1.1, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "beach_palm_bent",
			"name": "bent2", "frac": 0.496, "side": -1.0, "off": 23.0,
			"scale": 1.0, "face": "random"},

		# --- Zone05: gardul de lemn pe buza lagunei (dreapta) ----------------
		{"kind": "row", "zone": "Zone05_CoastalClimb", "model": "fence_ranch",
			"name": "fence", "from": 0.506, "to": 0.530, "spacing": 4.1,
			"side": 1.0, "off": 3.0, "scale": 1.0, "face": "along",
			"sink": 0.06,
			"keep_cycle": [["Fence_A"], ["Fence_A"], ["Fence_B"]]},
		{"kind": "row", "zone": "Zone05_CoastalClimb", "model": "fence_ranch",
			"name": "fence_up", "from": 0.549, "to": 0.569, "spacing": 4.1,
			"side": 1.0, "off": 3.2, "scale": 1.0, "face": "along",
			"sink": 0.06,
			"keep_cycle": [["Fence_A"], ["Fence_B"], ["Fence_A"]]},
		# Bolovanii dintre garduri — perechi, nu toata familia de 8 variante.
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coral_rock",
			"name": "rock", "frac": 0.512, "side": 1.0, "off": 6.5,
			"scale": 1.1, "face": "random", "sink": 0.35,
			"keep": ["Coral_Rock_03", "Coral_Rock_06"]},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coral_rock",
			"name": "rock2", "frac": 0.526, "side": 1.0, "off": 6.0,
			"scale": 1.3, "face": "random", "sink": 0.4,
			"keep": ["Coral_Rock_04", "Coral_Rock_07"]},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coral_rock",
			"name": "rock3", "frac": 0.556, "side": 1.0, "off": 6.5,
			"scale": 1.0, "face": "random", "sink": 0.35,
			"keep": ["Coral_Rock_05", "Coral_Rock_02"]},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "coral_rock",
			"name": "rock4", "frac": 0.577, "side": 1.0, "off": 6.5,
			"scale": 1.2, "face": "random", "sink": 0.4,
			"keep": ["Coral_Rock_03", "Coral_Rock_08"]},
		# Trestia si pandanusul de langa gard.
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "sugar_cane_clump",
			"name": "cane", "frac": 0.520, "side": 1.0, "off": 5.6,
			"scale": 1.1, "face": "random", "sink": 0.2,
			"keep": ["Cane_Clump_B"]},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "sugar_cane_clump",
			"name": "cane2", "frac": 0.565, "side": 1.0, "off": 5.0,
			"scale": 1.0, "face": "random", "sink": 0.2,
			"keep": ["Cane_Clump_C"]},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "pandanus",
			"name": "pand_r", "frac": 0.509, "side": 1.0, "off": 6.5,
			"scale": 1.1, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "pandanus",
			"name": "pand_r2", "frac": 0.545, "side": 1.0, "off": 6.5,
			"scale": 1.2, "face": "random"},
		{"kind": "one", "zone": "Zone05_CoastalClimb", "model": "hibiscus_bush",
			"name": "hib_r", "frac": 0.536, "side": 1.0, "off": 4.5,
			"scale": 1.6, "face": "random", "sink": 0.05},

		# --- Zone05: golful cu pontonul --------------------------------------
		{"kind": "pier", "zone": "Zone05_CoastalClimb",
			"frac_from": 0.505, "frac_to": 0.585, "side": 1.0},

		# --- Zone06: flori la picioarele zidului cetatii ----------------------
		{"kind": "one", "zone": "Zone06_Crest", "model": "hibiscus_bush",
			"name": "hib_crest", "frac": 0.598, "side": -1.0, "off": 4.2,
			"scale": 1.7, "face": "random", "sink": 0.05},
		{"kind": "one", "zone": "Zone06_Crest", "model": "hibiscus_bush",
			"name": "hib_crest2", "frac": 0.612, "side": -1.0, "off": 4.8,
			"scale": 1.5, "face": "random", "sink": 0.05},
		{"kind": "one", "zone": "Zone06_Crest", "model": "hibiscus_bush",
			"name": "hib_crest3", "frac": 0.628, "side": -1.0, "off": 4.0,
			"scale": 1.8, "face": "random", "sink": 0.05},
		{"kind": "one", "zone": "Zone06_Crest", "model": "pandanus",
			"name": "pand_crest", "frac": 0.605, "side": -1.0, "off": 5.5,
			"scale": 1.1, "face": "random"},
		{"kind": "one", "zone": "Zone06_Crest", "model": "pandanus",
			"name": "pand_crest2", "frac": 0.621, "side": -1.0, "off": 5.0,
			"scale": 1.2, "face": "random"},
	]


# ------------------------------------------------------------------ emitere

func _emit_row(spec: Dictionary) -> void:
	var d0: float = _path.total * float(spec["from"])
	var d1: float = _path.total * float(spec["to"])
	var spacing := float(spec["spacing"])
	var keeps: Array = spec.get("keep_cycle", [])
	var i := 0
	var d := d0
	while d <= d1:
		var st := _path.at(d)
		var keep: Array = keeps[i % keeps.size()] if not keeps.is_empty() else []
		_place(spec, st, float(spec["off"]), keep,
			"%s%s" % [spec["name"], "" if i == 0 else str(i + 1)])
		i += 1
		d += spacing


func _emit_one(spec: Dictionary) -> void:
	var st := _path.at(_path.total * float(spec["frac"]))
	_place(spec, st, float(spec["off"]), spec.get("keep", []),
		String(spec["name"]))


## Verificarile comune + tiparirea blocului .tscn.
func _place(spec: Dictionary, st: Dictionary, off: float, keep: Array,
		node_name: String) -> void:
	var side := float(spec["side"])
	var out: Vector3 = st["right"] * side
	var road: Vector3 = st["pos"]
	var hw := _sampler.half_width()
	var pos := road + out * (hw + off)
	pos.y = _sampler.ground_y(pos.x, pos.z) - float(spec.get("sink", 0.0))
	if pos.y < _sea_y + 0.25:
		print("; SARIT (in apa): %s la frac dat, y=%.2f" % [node_name, pos.y])
		return
	if _sampler.clearance_at(pos) < hw + 1.0:
		print("; SARIT (prea aproape de alta banda): %s" % node_name)
		return
	if absf(pos.y - road.y) > 4.0:
		print("; ATENTIE %s: cade cu %.1f m fata de sosea" % [node_name,
			pos.y - road.y])
	var yaw := 0.0
	match String(spec.get("face", "along")):
		"along":
			var along: Vector3 = st["along"]
			yaw = atan2(-along.z, along.x)
		"road":
			var to_road: Vector3 = -(st["along"] as Vector3) \
				.cross(Vector3.UP) * side
			yaw = atan2(-to_road.x, -to_road.z)
		_:
			yaw = _rng.randf_range(0.0, TAU)
	yaw += deg_to_rad(_rng.randf_range(-1.0, 1.0)
		* float(spec.get("yaw_jitter", 0.0)))
	_print_node(node_name, String(spec["zone"]), String(spec["model"]),
		pos, yaw, float(spec.get("scale", 1.0)), keep)


## Pontonul: cauta golful (malul cel mai apropiat de sosea pe interval), apoi
## aseaza pontonul pe linia apei, barca la capatul lui si un palmier pe mal.
func _emit_pier(spec: Dictionary) -> void:
	var side := float(spec["side"])
	var hw := _sampler.half_width()
	var best_f := -1.0
	var best_shore := INF
	var f := float(spec["frac_from"])
	while f <= float(spec["frac_to"]):
		var st := _path.at(_path.total * f)
		var shore := TrackScenography._shoreline(_sampler, st["pos"],
			(st["right"] as Vector3) * side, hw + 1.0, _sea_y)
		if shore > 0.0 and shore < best_shore:
			best_shore = shore
			best_f = f
		f += 0.0025
	if best_f < 0.0:
		print("; PONTON: nu am gasit mal pe interval, sarit")
		return
	print("; ponton: frac=%.3f, malul la %.1f m de axa" % [best_f, best_shore])
	var st := _path.at(_path.total * best_f)
	var out: Vector3 = (st["right"] as Vector3) * side
	# Radacina chiar pe linia apei, nu trasa pe mal: malul golfului e o rapa
	# (3.5 m cadere pe ultimii 2.5 m, masurat de probe_manual la prima
	# incercare), deci orice retragere ingroapa puntea in faleza.
	var root_pos: Vector3 = (st["pos"] as Vector3) + out * (best_shore - 0.5)
	root_pos.y = _sea_y
	var yaw := atan2(-out.z, out.x)
	var zone := String(spec["zone"])
	_print_node("pier", zone, "wooden_pier", root_pos, yaw, 1.0, [])
	# Barca, acostata paralel cu pontonul, spre golf.
	var lateral := Vector3(out.z, 0.0, -out.x) # perpendicular pe ponton
	var boat_pos := root_pos + out * 10.5 + lateral * 2.3
	boat_pos.y = _sea_y - 0.12
	_print_node("pier_boat", zone, "sabani_boat", boat_pos,
		yaw + deg_to_rad(6.0), 1.0, [])
	# Palmierul aplecat peste apa, la radacina pontonului.
	var palm_pos: Vector3 = (st["pos"] as Vector3) + out * (best_shore - 6.0) \
		+ lateral * -4.0
	palm_pos.y = _sampler.ground_y(palm_pos.x, palm_pos.z)
	if palm_pos.y > _sea_y + 0.2:
		_print_node("pier_palm", zone, "beach_palm_bent", palm_pos,
			yaw + deg_to_rad(160.0), 1.1, [])
	# Doua stanci in apa mica, langa mal — IN apa, nu pe mal: la prima rulare
	# lateral*-5 fara avans spre larg le punea pe faleza, ingropate.
	var rock_pos := root_pos + lateral * -4.5 + out * 6.0
	rock_pos.y = _sea_y - 0.5
	_print_node("pier_rock", zone, "coral_rock", rock_pos,
		_rng.randf_range(0.0, TAU), 1.2, ["Coral_Rock_06", "Coral_Rock_04"])


func _print_node(node_name: String, zone: String, model: String, pos: Vector3,
		yaw: float, scale: float, keep: Array) -> void:
	var basis := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(
		Vector3.ONE * scale)
	var t := Transform3D(basis, pos)
	print("")
	print("[node name=\"%s\" parent=\"DecorManual/%s\" instance=ExtResource(\"%s\")]"
		% [node_name, zone, RES[model]])
	print("transform = %s" % var_to_str(t).replace("\n", " "))
	if keep.is_empty():
		return
	# Variantele NEpastrate se sting prin override pe copilul instantei.
	for child in _glb_children(model):
		if child in keep:
			continue
		print("")
		print("[node name=\"%s\" parent=\"DecorManual/%s/%s\"]"
			% [child, zone, node_name])
		print("visible = false")


var _children_cache := {}

## assets/models/ e impartit pe foldere de categorie; uneltele care primesc
## doar numele modelului il cauta in toate categoriile.
const MODEL_DIRS := ["rocks", "trees", "plants", "buildings", "signs",
	"structures", "vehicles", "props", "scatter", "effects"]

static func _model_path(model: String) -> String:
	for dir in MODEL_DIRS:
		var p := "res://assets/models/%s/%s.glb" % [dir, model]
		if ResourceLoader.exists(p):
			return p
	return "res://assets/models/%s.glb" % model

func _glb_children(model: String) -> Array:
	if not _children_cache.has(model):
		var scene := load(_model_path(model)) as PackedScene
		var inst := scene.instantiate()
		var names: Array = []
		for c in inst.get_children():
			names.append(String(c.name))
		inst.free()
		_children_cache[model] = names
	return _children_cache[model]
