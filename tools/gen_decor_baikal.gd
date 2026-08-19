extends Node
## Generator de decor MANUAL pentru Baikal (Track10, tema `baikal`).
##
## NU e o sonda de verificare — e unealta cu care se CALCULEAZA transformarile
## care se lipesc apoi in Track10.tscn. Pozitiile stau pe terenul real
## (`sampler.ground_y`), orientarile pe directia reala a soselei, iar piesele
## de pe gheata pe cota gheții, nu pe cea a malului. "Asezat de mana" inseamna
## ca fiecare grup e o DECIZIE (ce, unde, cat de des), nu ca cifrele au fost
## tastate din ochi — un obiect pus din ochi la cota gresita pluteste sau se
## ingroapa, vezi probe_manual.
##
## Rulare (ca SCENA, nu cu --script: pista instantiaza hazarde care cer
## autoload-ul AudioManager, iar --script nu incarca autoload-uri):
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorBaikal.tscn
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorBaikal.tscn -- --scan
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorBaikal.tscn -- --poi=A
##
## Iesirea se lipeste in Track10.tscn sub `DecorManual`. Numele de ext_resource
## sunt cele din header-ul scenei — cand adaugi un model nou, adauga-i randul si
## in RES, si linia [ext_resource] in scena.
##
## COMPOZITIA vine din docs/track_briefs/img/baikal_diorama_traseu.jpg, iar
## GEOMETRIA din pista. Diorama e desenata pe un octogon aproape patrat, deci
## din ea se iau regulile de asezare (cat de strans e satul, pe ce parte a
## virajului sta padurea), nu coordonatele.

const TRACK := "res://scenes/tracks/Track10.tscn"

## id-urile ext_resource asa cum trebuie sa apara in Track10.tscn.
const RES := {
	"baikal/buildings/hunting_cabin": "hunting_cabin",
	"baikal/plants/grass_tuft_dry": "grass_tuft_dry",
	"baikal/plants/shrub_snow": "shrub_snow",
	"baikal/props/barrels_crates": "barrels_crates",
	"baikal/props/fence_gate": "fence_gate",
	"baikal/props/fisher_tent_green": "fisher_tent_green",
	"baikal/props/fisher_tent_orange": "fisher_tent_orange",
	"baikal/props/frozen_boat": "frozen_boat",
	"baikal/props/ice_block_stack": "ice_block_stack",
	"baikal/props/ice_hole": "ice_hole",
	"baikal/props/ice_road_marker": "ice_road_marker",
	"baikal/props/ice_road_sign": "ice_road_sign",
	"baikal/props/ice_shards": "ice_shards",
	"baikal/props/plank_fence": "plank_fence",
	"baikal/props/serge_pole_a": "serge_pole_a",
	"baikal/props/serge_pole_b": "serge_pole_b",
	"baikal/props/serge_pole_c": "serge_pole_c",
	"baikal/props/sled": "sled",
	"baikal/props/toros_a": "toros_a",
	"baikal/props/toros_b": "toros_b",
	"baikal/props/toros_c": "toros_c",
	"baikal/rocks/boulder_lichen_a": "boulder_lichen_a",
	"baikal/rocks/boulder_lichen_b": "boulder_lichen_b",
	"baikal/rocks/boulder_lichen_c": "boulder_lichen_c",
	"baikal/rocks/cliff_face_olkhon": "cliff_face_olkhon",
	"baikal/structures/shore_staircase": "shore_staircase",
	"baikal/rocks/shaman_rock": "20_shaman",
	"baikal/structures/railway_viaduct": "22_viaduct",
	"baikal/structures/railway_tunnel_portal": "23_tunnel",
	"baikal/structures/ice_grotto_arch": "24_grotto",
	"baikal/buildings/khuzhir_church": "25_church",
	"baikal/vehicles/hovercraft_khivus": "26_khivus",
	"baikal/vehicles/train_baikal": "27_train",
	"baikal/structures/power_pylon_soviet": "28_pylon",
	"baikal/structures/start_gate_logs": "29_gate",
	"baikal/buildings/log_house_a": "30_house_a",
	"baikal/buildings/log_house_b": "30_house_b",
	"baikal/buildings/log_house_c": "30_house_c",
	"baikal/buildings/banya": "30_banya",
	"baikal/props/fish_rack": "30_fish_rack",
	"baikal/props/well_crane": "30_well",
	"baikal/props/woodpile": "30_woodpile",
	"baikal/props/village_signpost": "30_signpost",
	"baikal/vehicles/uaz_bukhanka": "32_uaz",
	"baikal/vehicles/kamaz_truck": "33_kamaz",
	"baikal/trees/larch_winter_a": "35_larch_a",
	"baikal/trees/larch_winter_b": "35_larch_b",
	"baikal/trees/larch_winter_c": "35_larch_c",
	"baikal/trees/birch_winter_a": "35_birch_a",
	"baikal/trees/birch_winter_b": "35_birch_b",
	"baikal/trees/birch_winter_c": "35_birch_c",
	"baikal/trees/pine_siberian_a": "35_pine_a",
	"baikal/trees/pine_siberian_b": "35_pine_b",
	"baikal/props/husky_dog": "37_husky",
	"baikal/props/nerpa_seal": "38_nerpa",
}

## Peste atat un obiect langa drum iese din cadrul lui ChaseCamera. Nu e o
## preferinta: plafonul se DERIVA din frustum, vezi memoria despre inaltimea
## obiectelor. Piesele mai inalte se departeaza, nu se micsoreaza.
const CAM_CEILING_M: float = 18.0

var _track: Track = null
var _scan_only := false
var _only_poi := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--scan":
			_scan_only = true
		elif arg.begins_with("--poi="):
			_only_poi = arg.trim_prefix("--poi=")
	# Primul cadru: radacina inca isi monteaza copiii, add_child ar esua.
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	# Inca doua: rebuild() coace curba in _ready al pistei, iar samplerul
	# exista abia dupa.
	await get_tree().process_frame
	await get_tree().process_frame
	_run()
	get_tree().quit(0)


# ------------------------------------------------------------------ nucleu

var _sampler: TrackSideSampler
var _path: TrackScenography._Path
var _ice_y: float
var _rng := RandomNumberGenerator.new()
var _placed := 0
var _skipped := 0

func _run() -> void:
	_sampler = _track._sampler
	_path = TrackScenography._Path.new(_sampler)
	# Cota gheții: pe Baikal `sea_level_offset` e linia lacului, iar autostrada
	# de gheata merge CHIAR pe ea. Piesele de pe gheata se aseaza la cota asta,
	# nu la `ground_y` — terenul sub gheata poate fi orice.
	_ice_y = _sampler.mean_road_y() + _track.sea_level_offset
	_rng.seed = 0xBA1CA1
	print("; total=%.1f m  ice_y=%.2f  half_width=%.1f"
		% [_path.total, _ice_y, _sampler.half_width()])
	if _scan_only:
		_scan()
		return
	for spec in _specs():
		if _only_poi != "" and String(spec.get("poi", "")) != _only_poi:
			continue
		match String(spec["kind"]):
			"row":
				_emit_row(spec)
			"one":
				_emit_one(spec)
			"cluster":
				_emit_cluster(spec)
	print("")
	print("; asezate %d, sarite %d" % [_placed, _skipped])


## Terenul fractie cu fractie: cota soselei, cota la +6 si +14 m in lateral, si
## cat de mult cade terenul. Cu astea se aleg retragerile din _specs() — nu din
## ochi. Pe gheata (0.19-0.56) diferenta fata de _ice_y arata unde e mal si unde
## e lac.
func _scan() -> void:
	print("; frac  road_y | s-1: g+6  g+14 | s+1: g+6  g+14   (hw = latimea locala)")
	var f := 0.0
	while f < 1.0:
		var st := _path.at(_path.total * f)
		var road: Vector3 = st["pos"]
		var hw := _track.width_at(f)
		var line := "; %.3f %6.1f  hw=%4.1f" % [f, road.y, hw]
		for side: float in [-1.0, 1.0]:
			var out: Vector3 = (st["right"] as Vector3) * side
			var g6 := _sampler.ground_y(road.x + out.x * (hw + 6.0),
				road.z + out.z * (hw + 6.0))
			var g14 := _sampler.ground_y(road.x + out.x * (hw + 14.0),
				road.z + out.z * (hw + 14.0))
			line += "  | s%+d %6.1f %6.1f" % [int(side), g6, g14]
		print(line)
		f += 0.01


# ------------------------------------------------------------------ specs
##
## Compozitia, citita din diorama si mutata pe geometria reala.
##
## Ce spune diorama si nu spunea lista de assets:
##  - satul e un CIORCHINE strans pe ambele parti, cu gard continuu intre case,
##    nu obiecte rasfirate de-a lungul drumului;
##  - serge stau intr-un SIR REGULAT pe promontoriu, toti pe aceeasi parte,
##    vizibili pe cer — nu imprastiati;
##  - torosurile sunt SIRURI DIAGONALE intrerupte, cu bete cu steag rosu care
##    marcheaza culoarul dintre ele;
##  - padurea e o PERDEA DEASA doar pe partea exterioara a virajului; interiorul
##    ramane aproape gol, ca sa se vada linia;
##  - tabara pescarilor e un GRUP MIC izolat, cu spatiu gol in jur.
func _specs() -> Array[Dictionary]:
	return [
		# ---------------------------------------------------- A: satul Khuzhir
		# Poarta de start, chiar peste sosea la linia de plecare.
		{"poi": "A", "kind": "one", "model": "baikal/structures/start_gate_logs",
			"name": "PoartaStart", "frac": 0.004, "side": 1.0, "off": -0.2,
			"scale": 0.72, "face": "road", "spans_road": true},
		# Casele: ciorchine strans pe ambele parti. Retragerea de 5.5 m e
		# derivata, nu aleasa: LogHouse_B are 11.4 m latime, soseaua 8 m
		# jumatate-latime, iar gardul cere 1.5 m intre casa si drum.
		# Casele: ciorchine strans pe ambele parti. Retragerea de 5.5 m e
		# derivata, nu aleasa: LogHouse_B are 11.4 m latime, soseaua 8 m
		# jumatate-latime, iar gardul cere 1.5 m intre casa si drum.
		#
		# `model_cycle` in loc de `keep_cycle`: fiecare casa e acum fisierul ei.
		# Pasul si intervalul raman NESCHIMBATE, deci si pozitiile.
		{"poi": "A", "kind": "row", "model": "baikal/buildings/log_house_a",
			"name": "CasaS", "from": 0.010, "to": 0.043, "spacing": 13.0,
			"side": -1.0, "off": 5.5, "scale": 1.0, "face": "road",
			"yaw_jitter": 7.0,
			"model_cycle": [
				"baikal/buildings/log_house_a", "baikal/buildings/log_house_c",
				"baikal/buildings/log_house_b"]},
		{"poi": "A", "kind": "row", "model": "baikal/buildings/log_house_b",
			"name": "CasaD", "from": 0.014, "to": 0.040, "spacing": 14.0,
			"side": 1.0, "off": 6.0, "scale": 1.0, "face": "road",
			"yaw_jitter": 7.0,
			"model_cycle": [
				"baikal/buildings/log_house_b", "baikal/buildings/log_house_a"]},
		# Gardul continuu intre case — semnatura satului in diorama.
		{"poi": "A", "kind": "row", "model": "baikal/props/plank_fence",
			"name": "GardS", "from": 0.008, "to": 0.046, "spacing": 3.1,
			"side": -1.0, "off": 2.6, "scale": 1.0, "face": "along",
			"sink": 0.05,
			"model_cycle": ["baikal/props/plank_fence", "baikal/props/plank_fence", "baikal/props/fence_gate"]},
		{"poi": "A", "kind": "row", "model": "baikal/props/plank_fence",
			"name": "GardD", "from": 0.012, "to": 0.044, "spacing": 3.1,
			"side": 1.0, "off": 2.8, "scale": 1.0, "face": "along",
			"sink": 0.05,
			"model_cycle": ["baikal/props/plank_fence", "baikal/props/plank_fence"]},
		# Gospodaria din spatele caselor: baie, uscator, fantana, lemne.
		{"poi": "A", "kind": "one", "model": "baikal/buildings/banya",
			"name": "Banya", "frac": 0.022, "side": 1.0, "off": 15.0,
			"scale": 1.0, "face": "road", "yaw_jitter": 20.0},
		{"poi": "A", "kind": "one", "model": "baikal/props/fish_rack",
			"name": "Uscator", "frac": 0.017, "side": -1.0, "off": 13.5,
			"scale": 1.0, "face": "road"},
		{"poi": "A", "kind": "one", "model": "baikal/props/fish_rack",
			"name": "Uscator2", "frac": 0.031, "side": -1.0, "off": 14.5,
			"scale": 1.0, "face": "road"},
		{"poi": "A", "kind": "one", "model": "baikal/props/well_crane",
			"name": "Fantana", "frac": 0.027, "side": 1.0, "off": 12.0,
			"scale": 1.0, "face": "random"},
		{"poi": "A", "kind": "one", "model": "baikal/props/woodpile",
			"name": "Lemne", "frac": 0.019, "side": -1.0, "off": 10.5,
			"scale": 1.0, "face": "along"},
		{"poi": "A", "kind": "one", "model": "baikal/props/woodpile",
			"name": "Lemne2", "frac": 0.037, "side": 1.0, "off": 11.0,
			"scale": 1.0, "face": "along"},
		{"poi": "A", "kind": "one", "model": "baikal/props/village_signpost",
			"name": "IndicatorSat", "frac": 0.048, "side": -1.0, "off": 3.2,
			"scale": 1.0, "face": "road"},
		# Marunt: sanii si lazi lipite de garduri.
		{"poi": "A", "kind": "one", "model": "baikal/props/sled",
			"name": "Sanie", "frac": 0.015, "side": -1.0, "off": 4.2,
			"scale": 1.0, "face": "along"},
		{"poi": "A", "kind": "one", "model": "baikal/props/sled",
			"name": "Sanie2", "frac": 0.034, "side": 1.0, "off": 4.4,
			"scale": 1.0, "face": "along", "yaw_jitter": 25.0},
		{"poi": "A", "kind": "one", "model": "baikal/props/barrels_crates",
			"name": "Lazi", "frac": 0.026, "side": -1.0, "off": 4.0,
			"scale": 1.0, "face": "random"},
		{"poi": "A", "kind": "one", "model": "baikal/vehicles/uaz_bukhanka",
			"name": "UAZ", "frac": 0.040, "side": 1.0, "off": 4.6,
			"scale": 1.0, "face": "along", "yaw_jitter": 8.0},
		# Cainii: figuranti langa poarta, ca in diorama.
		{"poi": "A", "kind": "one", "model": "baikal/props/husky_dog",
			"name": "Husky", "frac": 0.009, "side": -1.0, "off": 3.4,
			"scale": 1.0, "face": "road", "yaw_jitter": 35.0},
		{"poi": "A", "kind": "one", "model": "baikal/props/husky_dog",
			"name": "Husky2", "frac": 0.011, "side": -1.0, "off": 4.6,
			"scale": 1.0, "face": "road", "yaw_jitter": 35.0},
		{"poi": "A", "kind": "one", "model": "baikal/props/husky_dog",
			"name": "Husky3", "frac": 0.013, "side": 1.0, "off": 3.8,
			"scale": 1.0, "face": "road", "yaw_jitter": 35.0},

		# ------------------------------------------- B: Stanca Samanului
		# Colturile de marmura, in stanga, departe: Shaman_Crag_Big are 19 m,
		# deci peste plafonul de cadru daca sta langa drum.
		{"poi": "B", "kind": "one", "model": "baikal/rocks/shaman_rock",
			"name": "StancaMare", "frac": 0.098, "side": -1.0, "off": 22.0,
			"scale": 1.0, "face": "road", "yaw_jitter": 12.0,
			"keep": ["Shaman_Crag_Big", "Shaman_Ice"]},
		{"poi": "B", "kind": "one", "model": "baikal/rocks/shaman_rock",
			"name": "StancaMica", "frac": 0.108, "side": -1.0, "off": 30.0,
			"scale": 1.0, "face": "road", "yaw_jitter": 20.0,
			"keep": ["Shaman_Crag_Small"]},
		# Sirul de serge: REGULAT, toti pe dreapta, ca in diorama.
		{"poi": "B", "kind": "row", "model": "baikal/props/serge_pole_a",
			"name": "Serge", "from": 0.093, "to": 0.121, "spacing": 3.6,
			"side": 1.0, "off": 3.0, "scale": 1.0, "face": "road",
			"yaw_jitter": 6.0,
			"model_cycle": ["baikal/props/serge_pole_a", "baikal/props/serge_pole_b", "baikal/props/serge_pole_c"]},
		{"poi": "B", "kind": "one", "model": "baikal/structures/shore_staircase",
			"name": "Scari", "frac": 0.126, "side": -1.0, "off": 9.0,
			"scale": 1.0, "face": "road"},
		{"poi": "B", "kind": "cluster", "model": "baikal/rocks/boulder_lichen_a",
			"name": "Bolovan", "frac": 0.104, "count": 7, "side": 0.0,
			"spread_along": 26.0, "off": 7.0, "off_jitter": 5.0,
			"scale": 1.0, "scale_jitter": 0.25, "face": "random",
			"sink": 0.2,
			"model_cycle": ["baikal/rocks/boulder_lichen_a", "baikal/rocks/boulder_lichen_b", "baikal/rocks/boulder_lichen_c"]},

		# ------------------------------------- B2: rampa de coborare pe gheata
		# Betele cu steag rosu marcheaza drumul de gheata — element de semnatura
		# in diorama, prezent pe toata portiunea de lac.
		{"poi": "B2", "kind": "row", "model": "baikal/props/ice_road_marker",
			"name": "BatRampa", "from": 0.140, "to": 0.172, "spacing": 9.0,
			"side": 1.0, "off": 2.4, "scale": 1.0, "face": "road",
			"model_cycle": ["baikal/props/ice_road_marker"]},
		# De la 0.175 terenul e deja sub linia gheții (masurat cu --scan):
		# de acolo bețele stau PE gheata, nu pe mal.
		#
		# Se opresc la 0.190, unde INCEPE rampa de latire spre autostrada
		# (7 -> 11 m intre 0.190 si 0.205). Un bat asezat in rampa la o
		# retragere fixa ajunge sub asfaltul care se largeste peste el —
		# probe_manual l-a prins de doua ori la rand, si raspunsul nu era o
		# retragere mai mare, ci sa nu pui marcaje IN tranzitie. Sirul
		# continua oricum: grupul "Bat" reia de la 0.204, pe latimea plina.
		{"poi": "B2", "kind": "row", "model": "baikal/props/ice_road_marker",
			"name": "BatRampaGheata", "from": 0.178, "to": 0.185, "spacing": 6.0,
			"side": 1.0, "off": 3.4, "scale": 1.0, "face": "road",
			"on_ice": true,
			"model_cycle": ["baikal/props/ice_road_marker"]},
		{"poi": "B2", "kind": "row", "model": "baikal/props/ice_road_marker",
			"name": "BatRampaS", "from": 0.144, "to": 0.168, "spacing": 9.0,
			"side": -1.0, "off": 2.4, "scale": 1.0, "face": "road",
			"model_cycle": ["baikal/props/ice_road_marker"]},
		{"poi": "B2", "kind": "row", "model": "baikal/props/ice_road_marker",
			"name": "BatRampaGheataS", "from": 0.178, "to": 0.185, "spacing": 6.0,
			"side": -1.0, "off": 3.4, "scale": 1.0, "face": "road",
			"on_ice": true,
			"model_cycle": ["baikal/props/ice_road_marker"]},
		{"poi": "B2", "kind": "one", "model": "baikal/props/frozen_boat",
			"name": "BarcaInghetata", "frac": 0.163, "side": 1.0, "off": 11.0,
			"scale": 1.0, "face": "random", "on_ice": true, "sink": 0.15},

		# ---------------------------------------- C: autostrada de gheata
		# Torosurile: siruri diagonale, alternand partile, cu spatiu de trecere.
		{"poi": "C", "kind": "row", "model": "baikal/props/toros_a",
			"name": "TorosS", "from": 0.212, "to": 0.268, "spacing": 11.0,
			"side": -1.0, "off": 2.5, "scale": 1.0, "face": "along",
			"on_ice": true, "yaw_jitter": 14.0,
			"model_cycle": ["baikal/props/toros_a", "baikal/props/toros_b", "baikal/props/toros_c"]},
		{"poi": "C", "kind": "row", "model": "baikal/props/toros_b",
			"name": "TorosD", "from": 0.220, "to": 0.276, "spacing": 11.0,
			"side": 1.0, "off": 2.5, "scale": 1.0, "face": "along",
			"on_ice": true, "yaw_jitter": 14.0,
			"model_cycle": ["baikal/props/toros_b", "baikal/props/toros_a", "baikal/props/toros_c"]},
		# Betele rosii pe toata autostrada, la ~20 m ca in brief.
		{"poi": "C", "kind": "row", "model": "baikal/props/ice_road_marker",
			"name": "Bat", "from": 0.204, "to": 0.360, "spacing": 12.0,
			"side": 1.0, "off": 3.0, "scale": 1.0, "face": "road",
			"on_ice": true,
			"model_cycle": ["baikal/props/ice_road_marker"]},
		{"poi": "C", "kind": "row", "model": "baikal/props/ice_road_marker",
			"name": "BatS", "from": 0.208, "to": 0.356, "spacing": 12.0,
			"side": -1.0, "off": 3.0, "scale": 1.0, "face": "road",
			"on_ice": true,
			"model_cycle": ["baikal/props/ice_road_marker"]},
		{"poi": "C", "kind": "one", "model": "baikal/vehicles/kamaz_truck",
			"name": "Kamaz", "frac": 0.246, "side": 1.0, "off": 13.0,
			"scale": 1.0, "face": "along", "on_ice": true, "yaw_jitter": 18.0},
		{"poi": "C", "kind": "one", "model": "baikal/props/ice_road_sign",
			"name": "Indicator", "frac": 0.232, "side": -1.0, "off": 3.4,
			"scale": 1.0, "face": "road", "on_ice": true},
		{"poi": "C", "kind": "one", "model": "baikal/props/ice_road_sign",
			"name": "Indicator2", "frac": 0.302, "side": 1.0, "off": 3.4,
			"scale": 1.0, "face": "road", "on_ice": true},
		{"poi": "C", "kind": "cluster", "model": "baikal/props/ice_shards",
			"name": "Cioburi", "frac": 0.258, "count": 8, "side": 0.0,
			"spread_along": 60.0, "off": 6.5, "off_jitter": 3.0,
			"scale": 1.0, "scale_jitter": 0.3, "face": "random",
			"on_ice": true,
			"model_cycle": ["baikal/props/ice_shards"]},

		# ------------------------------------------- D: campul de placi
		{"poi": "D", "kind": "cluster", "model": "baikal/props/ice_shards",
			"name": "CiobPlaci", "frac": 0.400, "count": 12, "side": 0.0,
			"spread_along": 90.0, "off": 6.5, "off_jitter": 3.5,
			"scale": 1.1, "scale_jitter": 0.3, "face": "random",
			"on_ice": true,
			"model_cycle": ["baikal/props/ice_shards"]},
		{"poi": "D", "kind": "cluster", "model": "baikal/props/ice_block_stack",
			"name": "BlocGheata", "frac": 0.412, "count": 4, "side": 0.0,
			"spread_along": 50.0, "off": 8.0, "off_jitter": 3.0,
			"scale": 1.0, "scale_jitter": 0.2, "face": "random",
			"on_ice": true,
			"model_cycle": ["baikal/props/ice_block_stack"]},

		# --------------------------------------------- E: grota de gheata
		# Arcul sta PE drum (frac 0.585, mijlocul sectorului de 6 m). Turturii
		# sunt noduri separate: pista ii desprinde la trecere.
		{"poi": "E", "kind": "one", "model": "baikal/structures/ice_grotto_arch",
			"name": "Grota", "frac": 0.585, "side": 1.0, "off": -12.0,
			"scale": 1.0, "face": "road", "spans_road": true,
			"keep": ["Grotto_Rock", "Grotto_Ice", "Icicle_A", "Icicle_B",
				"Icicle_C", "Icicle_D"]},
		{"poi": "E", "kind": "row", "model": "baikal/rocks/cliff_face_olkhon",
			"name": "Faleza", "from": 0.572, "to": 0.606, "spacing": 17.0,
			"side": -1.0, "off": 12.0, "scale": 1.0, "face": "road",
			"yaw_jitter": 10.0,
			"model_cycle": ["baikal/rocks/cliff_face_olkhon"]},

		# ------------------------------------------ F: tabara pescarilor
		# Grup MIC si izolat, cu spatiu gol in jur — asa apare in diorama.
		#
		# STA PE GHEATA, deci inainte de 0.56 unde se termina `custom_ice_ranges`.
		# Prima incercare a pus-o la 0.65, fractia din alocarea hartii, unde pista
		# urcase deja 11 m pe terasamentul viaductului: corturile pluteau la cota
		# lacului sub un drum aflat mult deasupra. probe_manual a prins-o.
		{"poi": "F", "kind": "one", "model": "baikal/props/fisher_tent_green",
			"name": "CortVerde", "frac": 0.478, "side": -1.0, "off": 7.0,
			"scale": 1.0, "face": "road", "on_ice": true, "yaw_jitter": 25.0},
		{"poi": "F", "kind": "one", "model": "baikal/props/fisher_tent_green",
			"name": "CortVerde2", "frac": 0.486, "side": -1.0, "off": 10.0,
			"scale": 1.0, "face": "road", "on_ice": true, "yaw_jitter": 25.0},
		{"poi": "F", "kind": "one", "model": "baikal/props/fisher_tent_orange",
			"name": "CortPortocaliu", "frac": 0.494, "side": 1.0, "off": 8.0,
			"scale": 1.0, "face": "road", "on_ice": true, "yaw_jitter": 25.0},
		{"poi": "F", "kind": "one", "model": "baikal/props/fisher_tent_orange",
			"name": "CortPortocaliu2", "frac": 0.502, "side": 1.0, "off": 11.5,
			"scale": 1.0, "face": "road", "on_ice": true, "yaw_jitter": 25.0},
		{"poi": "F", "kind": "cluster", "model": "baikal/props/ice_hole",
			"name": "Copca", "frac": 0.487, "count": 5, "side": 0.0,
			"spread_along": 34.0, "off": 8.5, "off_jitter": 3.5,
			"scale": 1.0, "face": "random", "on_ice": true,
			"model_cycle": ["baikal/props/ice_hole"]},
		{"poi": "F", "kind": "one", "model": "baikal/props/nerpa_seal",
			"name": "Nerpa", "frac": 0.496, "side": 1.0, "off": 10.5,
			"scale": 1.0, "face": "road", "on_ice": true, "yaw_jitter": 30.0},
		{"poi": "F", "kind": "one", "model": "baikal/vehicles/uaz_bukhanka",
			"name": "UAZTabara", "frac": 0.470, "side": -1.0, "off": 9.5,
			"scale": 1.0, "face": "along", "on_ice": true, "yaw_jitter": 15.0},
		{"poi": "F", "kind": "cluster", "model": "baikal/props/barrels_crates",
			"name": "LaziTabara", "frac": 0.488, "count": 5, "side": 0.0,
			"spread_along": 28.0, "off": 6.5, "off_jitter": 3.0,
			"scale": 1.0, "face": "random", "on_ice": true,
			"model_cycle": ["baikal/props/barrels_crates", "baikal/props/sled"]},
		{"poi": "F", "kind": "cluster", "model": "baikal/props/ice_block_stack",
			"name": "BlocTabara", "frac": 0.474, "count": 2, "side": -1.0,
			"spread_along": 16.0, "off": 12.5, "off_jitter": 2.0,
			"scale": 1.0, "face": "random", "on_ice": true,
			"model_cycle": ["baikal/props/ice_block_stack"]},

		# ----------------------------------------- G: viaduct, tunel, tren
		# Modularele stau PE terasament: viaductul se aliniaza pe axa soselei,
		# de aceea off = 0 si face = "along". Numarul de arcade se decide aici,
		# nu in asset.
		{"poi": "G", "kind": "row", "model": "baikal/structures/railway_viaduct",
			"name": "Arcada", "spans_road": true, "from": 0.716, "to": 0.760, "spacing": 12.0,
			"side": 1.0, "off": -14.0, "scale": 1.0, "face": "along",
			"keep_cycle": [["Viaduct_Arch"]]},
		{"poi": "G", "kind": "row", "model": "baikal/structures/railway_viaduct",
			"name": "Pila", "spans_road": true, "from": 0.716, "to": 0.766, "spacing": 12.0,
			"side": 1.0, "off": -14.0, "scale": 1.0, "face": "along",
			"keep_cycle": [["Viaduct_Pier"]]},
		{"poi": "G", "kind": "one", "model": "baikal/structures/railway_viaduct",
			"name": "CapatViaduct", "spans_road": true, "frac": 0.712, "side": 1.0, "off": -14.0,
			"scale": 1.0, "face": "along", "keep": ["Viaduct_End"]},
		{"poi": "G", "kind": "one", "model": "baikal/structures/railway_viaduct",
			"name": "CapatViaduct2", "spans_road": true, "frac": 0.766, "side": 1.0, "off": -14.0,
			"scale": 1.0, "face": "along", "keep": ["Viaduct_End"]},
		{"poi": "G", "kind": "one", "model": "baikal/structures/railway_tunnel_portal",
			"name": "PortalTunel", "spans_road": true, "frac": 0.786, "side": 1.0, "off": -14.0,
			"scale": 1.0, "face": "along",
			"keep": ["Tunnel_Portal", "Tunnel_Bore", "Tunnel_Niche"]},
		{"poi": "G", "kind": "one", "model": "baikal/structures/railway_tunnel_portal",
			"name": "PortalTunelIesire", "spans_road": true, "frac": 0.812, "side": 1.0,
			"off": -14.0, "scale": 1.0, "face": "along",
			"keep": ["Tunnel_Portal"]},

		# ------------------------------------------------------ H: padurea
		# Perdea DEASA pe exterior (partea -1 pe coborarea in S), interior
		# aproape gol ca sa se vada linia. Laricele mare (16 m) sta la 13 m
		# retragere: sub plafonul de cadru doar daca nu e langa drum.
		{"poi": "H", "kind": "row", "model": "baikal/trees/birch_winter_a",
			"name": "Mesteacan", "from": 0.862, "to": 0.944, "spacing": 7.5,
			"side": -1.0, "off": 5.5, "scale": 1.0, "face": "random",
			"off_jitter": 2.5,
			"model_cycle": [
				"baikal/trees/birch_winter_a", "baikal/trees/birch_winter_b",
				"baikal/trees/birch_winter_a", "baikal/trees/birch_winter_c"]},
		# Laricele costa 13 140 de triunghiuri BUCATA — de trei ori un mesteacan
		# si de cincisprezece ori un pin (masurat cu tools/measure_pieces.gd).
		# Treisprezece dintre ei faceau 170k, adica 60% din padure pentru 28%
		# din copaci. Raman patru, ca ACCENTE ruginii pe fundal — silueta de
		# larice iarna e semnatura malului, deci nu dispare, doar se raresc —
		# iar desimea o duc mestecenii si pinii, care sunt ieftini.
		{"poi": "H", "kind": "row", "model": "baikal/trees/larch_winter_b",
			"name": "Larice", "from": 0.872, "to": 0.932, "spacing": 20.0,
			"side": -1.0, "off": 15.0, "scale": 1.0, "face": "random",
			"off_jitter": 3.5,
			"model_cycle": [
				"baikal/trees/larch_winter_b", "baikal/trees/larch_winter_a",
				"baikal/trees/larch_winter_c"]},
		# Pinii preiau desimea de la larici: 874 tris fata de 13 140.
		{"poi": "H", "kind": "row", "model": "baikal/trees/pine_siberian_b",
			"name": "PinDes", "from": 0.868, "to": 0.938, "spacing": 6.0,
			"side": -1.0, "off": 12.0, "scale": 1.0, "face": "random",
			"off_jitter": 3.0,
			"model_cycle": [
				"baikal/trees/pine_siberian_b", "baikal/trees/pine_siberian_a"]},
		{"poi": "H", "kind": "row", "model": "baikal/trees/pine_siberian_a",
			"name": "Pin", "from": 0.870, "to": 0.936, "spacing": 13.0,
			"side": -1.0, "off": 20.0, "scale": 1.0, "face": "random",
			"off_jitter": 4.0,
			"model_cycle": [
				"baikal/trees/pine_siberian_a", "baikal/trees/pine_siberian_b"]},
		# Interiorul virajului: doar cateva siluete, rar.
		{"poi": "H", "kind": "row", "model": "baikal/trees/birch_winter_a",
			"name": "MesteacanInt", "from": 0.874, "to": 0.930, "spacing": 16.0,
			"side": 1.0, "off": 7.0, "scale": 1.0, "face": "random",
			"off_jitter": 3.0,
			"model_cycle": [
				"baikal/trees/birch_winter_a", "baikal/trees/birch_winter_b"]},
		{"poi": "H", "kind": "row", "model": "baikal/plants/shrub_snow",
			"name": "Tufa", "from": 0.864, "to": 0.942, "spacing": 5.0,
			"side": -1.0, "off": 3.8, "scale": 1.0, "face": "random",
			"off_jitter": 1.6, "sink": 0.1,
			"model_cycle": ["baikal/plants/shrub_snow", "baikal/plants/grass_tuft_dry", "baikal/plants/grass_tuft_dry"]},
		{"poi": "H", "kind": "row", "model": "baikal/plants/grass_tuft_dry",
			"name": "TufaInt", "from": 0.876, "to": 0.928, "spacing": 6.5,
			"side": 1.0, "off": 3.4, "scale": 1.0, "face": "random",
			"off_jitter": 1.5, "sink": 0.1,
			"model_cycle": ["baikal/plants/grass_tuft_dry", "baikal/plants/shrub_snow"]},
		{"poi": "H", "kind": "one", "model": "baikal/buildings/hunting_cabin",
			"name": "Cabana", "frac": 0.897, "side": 1.0, "off": 12.0,
			"scale": 1.0, "face": "road", "yaw_jitter": 15.0},
		# Stalpii sovietici: 26 m, deci mult peste plafonul de cadru — stau
		# departe, ca silueta pe creasta, exact ca in diorama.
		{"poi": "H", "kind": "row", "model": "baikal/structures/power_pylon_soviet",
			"name": "Stalp", "from": 0.872, "to": 0.928, "spacing": 26.0,
			"side": -1.0, "off": 34.0, "scale": 1.0, "face": "along"},
		{"poi": "H", "kind": "cluster", "model": "baikal/rocks/boulder_lichen_c",
			"name": "BolovanPadure", "frac": 0.905, "count": 5, "side": -1.0,
			"spread_along": 50.0, "off": 8.0, "off_jitter": 4.0,
			"scale": 1.0, "scale_jitter": 0.25, "face": "random", "sink": 0.25,
			"model_cycle": ["baikal/rocks/boulder_lichen_c", "baikal/rocks/boulder_lichen_b"]},

		# ------------------------------------------------ I: intrarea in sat
		{"poi": "I", "kind": "one", "model": "baikal/buildings/khuzhir_church",
			"name": "Biserica", "frac": 0.962, "side": -1.0, "off": 8.5,
			"scale": 1.0, "face": "road", "yaw_jitter": 6.0,
			"keep": ["Church_Body", "Church_Roof", "Church_Dome"]},
		{"poi": "I", "kind": "row", "model": "baikal/props/plank_fence",
			"name": "GardBiserica", "from": 0.952, "to": 0.976, "spacing": 3.1,
			"side": -1.0, "off": 3.0, "scale": 1.0, "face": "along",
			"sink": 0.05,
			"model_cycle": ["baikal/props/plank_fence"]},
		{"poi": "I", "kind": "row", "model": "baikal/buildings/log_house_c",
			"name": "CasaIntrare", "from": 0.968, "to": 0.984, "spacing": 12.0,
			"side": 1.0, "off": 6.0, "scale": 1.0, "face": "road",
			"yaw_jitter": 8.0},
		{"poi": "I", "kind": "one", "model": "baikal/props/woodpile",
			"name": "LemneIntrare", "frac": 0.958, "side": 1.0, "off": 4.5,
			"scale": 1.0, "face": "along"},
	]


# ------------------------------------------------------------------ emitere

func _emit_row(spec: Dictionary) -> void:
	var d0: float = _path.total * float(spec["from"])
	var d1: float = _path.total * float(spec["to"])
	var spacing := float(spec["spacing"])
	var keeps: Array = spec.get("keep_cycle", [])
	var jitter := float(spec.get("off_jitter", 0.0))
	var i := 0
	# `model_cycle` alterneaza FISIERUL de la o pozitie la alta, asa cum
	# `keep_cycle` alterneaza nodul pastrat dintr-un GLB multi-nod. De cand
	# cladirile de sat au un fisier fiecare, varianta pe noduri nu mai are ce
	# filtra — dar ciclul trebuie sa ramana, altfel casele ies toate la fel.
	#
	# Alternativa incercata intai (un rand separat per model, cu pasul
	# inmultit) NU e echivalenta: pe intervalul si pasul din spec ea a pierdut
	# o casa din opt, fiindca impartirea pe sloturi nu cade la fel. Ciclul pe
	# acelasi rand pastreaza exact pozitiile vechi.
	var models: Array = spec.get("model_cycle", [])
	var d := d0
	while d <= d1:
		var st := _path.at(d)
		var keep: Array = keeps[i % keeps.size()] if not keeps.is_empty() else []
		var off := float(spec["off"]) + _rng.randf_range(-jitter, jitter)
		var one := spec
		if not models.is_empty():
			one = spec.duplicate()
			one["model"] = models[i % models.size()]
		_place(one, st, off, keep, _numbered(String(spec["name"]), i))
		i += 1
		d += spacing


func _emit_one(spec: Dictionary) -> void:
	var st := _path.at(_path.total * float(spec["frac"]))
	_place(spec, st, float(spec["off"]), spec.get("keep", []),
		String(spec["name"]))


## Grup imprastiat in jurul unei fractii: pentru lucrurile care in diorama
## apar ca gramada (cioburi, bolovani, copci), nu ca sir.
func _emit_cluster(spec: Dictionary) -> void:
	var center: float = _path.total * float(spec["frac"])
	var spread := float(spec["spread_along"])
	var count := int(spec["count"])
	var keeps: Array = spec.get("keep_cycle", [])
	var jitter := float(spec.get("off_jitter", 0.0))
	var sj := float(spec.get("scale_jitter", 0.0))
	var base_side := float(spec["side"])
	for i in count:
		var d := center + _rng.randf_range(-spread * 0.5, spread * 0.5)
		var st := _path.at(fposmod(d, _path.total))
		var keep: Array = keeps[i % keeps.size()] if not keeps.is_empty() else []
		var off := float(spec["off"]) + _rng.randf_range(-jitter, jitter)
		var one := spec.duplicate()
		# side 0 in spec inseamna "oricare parte" — se alege aici, ca sa fie
		# grupul imprastiat de ambele parti, nu aliniat.
		one["side"] = base_side if not is_zero_approx(base_side) \
			else (-1.0 if i % 2 == 0 else 1.0)
		one["scale"] = float(spec.get("scale", 1.0)) \
			+ _rng.randf_range(-sj, sj)
		_place(one, st, off, keep, _numbered(String(spec["name"]), i))


func _numbered(base: String, i: int) -> String:
	return base if i == 0 else "%s%d" % [base, i + 1]


## Verificarile comune + tiparirea blocului .tscn.
##
## Cota: piesele de pe lac se aseaza pe `_ice_y` (gheata e un plan), restul pe
## terenul real. Diferenta conteaza — `ground_y` sub lac da fundul, nu suprafata.
func _place(spec: Dictionary, st: Dictionary, off: float, keep: Array,
		node_name: String) -> void:
	var side := float(spec["side"])
	var out: Vector3 = (st["right"] as Vector3) * side
	var road: Vector3 = st["pos"]
	var frac: float = float(st.get("frac", 0.0))
	# Latimea LOCALA, nu cea implicita: pe Baikal soseaua variaza 6-11 m, deci
	# o retragere masurata fata de `half_width()` ar intra in asfalt pe gheata
	# si ar lasa un gol in grota.
	var hw := _track.width_at(frac) if st.has("frac") else _sampler.half_width()
	var pos := road + out * (hw + off)
	var on_ice: bool = bool(spec.get("on_ice", false))
	if on_ice:
		pos.y = _ice_y - float(spec.get("sink", 0.0))
	else:
		pos.y = _sampler.ground_y(pos.x, pos.z) - float(spec.get("sink", 0.0))
	if not on_ice and pos.y < _ice_y + 0.2:
		print("; SARIT (sub linia gheții): %s y=%.2f" % [node_name, pos.y])
		_skipped += 1
		return
	# Piesele care TREC peste sosea — poarta de start, arcul grotei, viaductul,
	# portalul de tunel — sunt cerute exact acolo unde garda de banda se plange.
	# `spans_road` e declaratia ca suprapunerea e intentionata; restul pieselor
	# raman pazite, ca un copac sa nu ajunga zid invizibil pe scurtatura.
	if not bool(spec.get("spans_road", false)):
		if _sampler.clearance_at(pos) < hw + 0.8:
			print("; SARIT (prea aproape de alta banda): %s" % node_name)
			_skipped += 1
			return
	if not on_ice and absf(pos.y - road.y) > 5.0:
		print("; ATENTIE %s: cade cu %.1f m fata de sosea"
			% [node_name, pos.y - road.y])
	_warn_if_tall(spec, keep, off, node_name)
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
	_print_node(node_name, String(spec["model"]), pos, yaw,
		float(spec.get("scale", 1.0)), keep)
	_placed += 1


## Plafonul de cadru nu e o eroare, e o avertizare: un obiect inalt E permis
## daca sta departe. Regula practica din memoria despre camera: retragerea sa
## fie cel putin cat inaltimea peste plafon.
func _warn_if_tall(spec: Dictionary, keep: Array, off: float,
		node_name: String) -> void:
	var tallest := 0.0
	for piece in _glb_sizes(String(spec["model"])):
		if not keep.is_empty() and not (piece["node"] in keep):
			continue
		tallest = maxf(tallest, float(piece["h"]))
	if tallest <= CAM_CEILING_M:
		return
	if off < tallest - CAM_CEILING_M + 8.0:
		print("; ATENTIE %s: %.1f m inaltime la %.1f m retragere — iese din cadru"
			% [node_name, tallest, off])


## Numele emise pana acum. Godot cere nume unic per parinte: doua noduri cu
## acelasi nume in .tscn nu dau eroare, se SUPRAPUN — al doilea mosteneste
## pozitia primului. S-a intamplat cu doi "Indicator" (unul in sat, unul pe
## gheata): cel de pe gheata a ajuns ingropat 3.7 m in dealul satului, si s-a
## vazut abia la probe_manual.
var _names := {}

func _print_node(node_name: String, model: String, pos: Vector3, yaw: float,
		scale: float, keep: Array) -> void:
	if _names.has(node_name):
		push_error("gen_decor_baikal: nume dublat '%s' — se suprapun in .tscn"
			% node_name)
		print("; EROARE: nume dublat '%s'" % node_name)
	_names[node_name] = true
	var basis := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(
		Vector3.ONE * scale)
	var t := Transform3D(basis, pos)
	print("")
	print("[node name=\"%s\" parent=\"DecorManual\" instance=ExtResource(\"%s\")]"
		% [node_name, RES[model]])
	print("transform = %s" % var_to_str(t).replace("\n", " "))
	if keep.is_empty():
		return
	# Variantele NEpastrate se sting prin override pe copilul instantei. Godot
	# nu randeaza `visible = false`, deci nu intra nici in numaratoarea gardei.
	for child in _glb_children(model):
		if child in keep:
			continue
		print("")
		print("[node name=\"%s\" parent=\"DecorManual/%s\"]"
			% [child, node_name])
		print("visible = false")


var _children_cache := {}
var _sizes_cache := {}

func _glb_children(model: String) -> Array:
	if not _children_cache.has(model):
		_load_glb(model)
	return _children_cache[model]


func _glb_sizes(model: String) -> Array:
	if not _sizes_cache.has(model):
		_load_glb(model)
	return _sizes_cache[model]


func _load_glb(model: String) -> void:
	var scene := load("res://assets/models/%s.glb" % model) as PackedScene
	var names: Array = []
	var sizes: Array = []
	if scene == null:
		push_warning("gen_decor_baikal: lipseste %s.glb" % model)
		_children_cache[model] = names
		_sizes_cache[model] = sizes
		return
	var inst := scene.instantiate()
	for c in inst.get_children():
		names.append(String(c.name))
		sizes.append({"node": String(c.name), "h": _height_of(c)})
	inst.free()
	_children_cache[model] = names
	_sizes_cache[model] = sizes


func _height_of(node: Node) -> float:
	var out := 0.0
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		var mi := cur as MeshInstance3D
		if mi != null:
			out = maxf(out, mi.get_aabb().size.y)
		for c in cur.get_children():
			stack.push_back(c)
	return out
