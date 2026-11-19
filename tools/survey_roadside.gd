extends Node
## Masoara unde e LOC pe marginea drumului pentru decor lovibil si propune o prima asezare
## (`RoadsideSet`, decor lovibil valul 3). Fisierul scris ramane sursa adevarului: se citeste, se
## corecteaza de mana si se pazeste cu tools/ProbeRoadside.tscn.
##
##   godot --headless --fixed-fps 60 --path . res://tools/SurveyRoadside.tscn -- --track=Track19
##   ... -- --track=Track19 --write            scrie res://scenes/tracks/roadside/Track19.tres
##   ... -- --track=Track19 --write --max=10   cel mult 10 grupuri (implicit 16)
##
## Ce cauta, in ordinea asta:
##   "exit"       exteriorul iesirii din viraj — acolo scapa masina larg;
##   "overshoot"  exteriorul virajului, in dreptul varfului — acolo ajunge cine franeaza tarziu;
##   "straight"   acostamentul unei drepte lungi;
##   "outside"    alta fasie libera pe exteriorul unei curbe (peste 25 de grade);
##   "inside"     fasie libera pe interiorul unei curbe: piese mici, cine taie virajul le ia;
##   "open"       orice alta fasie libera (rezerva: se ia doar daca mai e loc).
## Ultimele trei se cauta din 60 in 60 m, pe ambele parti.
## Un loc e bun cu EXACT regula cu care se aseaza piesele (`RoadsideProps.spot`): sol aproape de
## cota drumului, plat, in afara oricarui carosabil, fara alt colizor. „Adancimea" e cati metri
## liberi sunt de la margine spre exterior; „lungimea", cati metri de-a lungul drumului.
##
## Reteta pistei (`RECIPES`) spune din ce piese si cu ce tipare se umplu locurile. O pista fara
## reteta se poate masura, dar nu se poate scrie.

const STEP_M: float = 4.0
const DEPTHS: Array[float] = [1.0, 1.8, 2.6, 3.4, 4.2, 5.0]
const TURN_WINDOW_M: float = 22.0
const CORNER_MIN_RAD: float = 0.6
const STRAIGHT_MAX_RAD: float = 0.12
const STRAIGHT_MIN_M: float = 90.0
## Nimic la mai putin de atat de linia de start (grila, poarta) si intre doua grupuri.
const START_CLEAR_M: float = 30.0
const GROUP_GAP_M: float = 45.0

## Scara implicita a pieselor: cotele din kituri sunt cele reale (butoi de 0,88 m), iar din
## camera de urmarire, la 15-25 m, o piesa reala se citeste mica. Jucariile sunt putin mai mari.
const PIECE_SCALE: float = 1.4

const JUNK := "res://assets/models/props/props_junk.glb"
const BEACH := "res://assets/models/props/knock_beach.glb"
const KIT := "res://assets/models/%s/props/knock_%s.glb"

## Reteta per pista: piesele (catalogul care ajunge in fisier) si ROLURILE lor, din care
## `_menus` compune tiparele pe fel de loc:
##   "stack"  piesa care se stivuieste in picioare (piramida de butoaie, de lazi);
##   "roll"   cilindrul care se pune CULCAT si se rostogoleste (gol = pista n-are);
##   "ball"   sfera (gol = n-are);
##   "box"    cutia pentru zid pe doua randuri (gol = zidul se face din "stack");
##   "small"  piesa mica pentru interiorul virajelor si sirurile oblice;
##   "mix"    amestecul pentru gramezi.
## Fara reteta: Chongqing (are deja 34 de piese lovibile) si San Francisco (64, asteapta
## verdictul la volan).
var RECIPES := {
	"Track01": {
		"pieces": {
			"barrel": {"glb": JUNK, "node": "Barrel_A", "shape": "cylinder", "classes": "junk"},
			"barrel_b": {"glb": JUNK, "node": "Barrel_B", "shape": "cylinder", "classes": "junk"},
			"crate": {"glb": JUNK, "node": "Crate_B", "shape": "box", "classes": "junk"},
			"tyres": {"glb": JUNK, "node": "TyreStack", "shape": "cylinder", "classes": "junk"},
			"tyre": {"glb": JUNK, "node": "Tyre", "shape": "cylinder", "classes": "junk"},
		},
		"roles": {"stack": "barrel", "roll": "barrel_b", "ball": "", "box": "crate", "small": "tyres", "mix": ["tyre", "crate", "barrel"]},
	},
	"Track08": {
		"pieces": {
			"ball": {"glb": BEACH, "node": "BeachBall", "shape": "sphere", "mass": 0.6, "bounce": 0.6},
			"ring": {"glb": BEACH, "node": "SwimRing", "shape": "cylinder", "mass": 0.5, "bounce": 0.4},
			"bucket": {"glb": BEACH, "node": "SandBucket", "shape": "cylinder", "mass": 0.8},
		},
		"roles": {"stack": "bucket", "roll": "ring", "ball": "ball", "box": "", "small": "bucket", "mix": ["ball", "ring", "bucket"]},
	},
	"Track21": {
		"pieces": {
			"churn": {"glb": KIT % ["transfagarasan", "transfagarasan"], "node": "MilkChurn", "shape": "cylinder", "mass": 2.5},
			"cheese": {"glb": KIT % ["transfagarasan", "transfagarasan"], "node": "CheeseWheel", "shape": "cylinder", "mass": 1.5},
			"bale": {"glb": KIT % ["transfagarasan", "transfagarasan"], "node": "HayBale", "shape": "box", "mass": 2.0},
			"cone": {"glb": "res://assets/models/transfagarasan/props/road_works.glb",
				"node": "Works_Cone_1", "shape": "hull"},
		},
		"roles": {"stack": "bale", "roll": "cheese", "ball": "", "box": "bale", "small": "cone", "mix": ["churn", "cheese", "bale"]},
	},
	"Track10": {
		"pieces": {
			"ice": {"glb": KIT % ["baikal", "baikal"], "node": "IceBlock", "shape": "box", "mass": 3.0},
			"fish": {"glb": KIT % ["baikal", "baikal"], "node": "FishCrate", "shape": "box", "mass": 1.5},
			"drum": {"glb": KIT % ["baikal", "baikal"], "node": "FuelDrum", "shape": "cylinder"},
		},
		"roles": {"stack": "drum", "roll": "drum", "ball": "", "box": "ice", "small": "fish", "mix": ["ice", "fish", "drum"]},
	},
	"Track11": {
		"pieces": {
			"buoy": {"glb": KIT % ["stromboli", "stromboli"], "node": "FishingBuoy", "shape": "sphere", "mass": 1.0, "bounce": 0.5},
			"lemons": {"glb": KIT % ["stromboli", "stromboli"], "node": "LemonCrate", "shape": "box", "mass": 1.5},
			"amphora": {"glb": KIT % ["stromboli", "stromboli"], "node": "Amphora", "shape": "cylinder", "mass": 2.5},
		},
		"roles": {"stack": "lemons", "roll": "amphora", "ball": "buoy", "box": "lemons", "small": "buoy", "mix": ["buoy", "lemons", "amphora"]},
	},
	"Track13": {
		"pieces": {
			"pot": {"glb": KIT % ["cappadocia", "cappadocia"], "node": "ClayPot", "shape": "cylinder", "mass": 2.5},
			"pumpkin": {"glb": KIT % ["cappadocia", "cappadocia"], "node": "Pumpkin", "shape": "sphere", "mass": 1.5},
			"apples": {"glb": KIT % ["cappadocia", "cappadocia"], "node": "AppleCrate", "shape": "box", "mass": 1.5},
		},
		"roles": {"stack": "apples", "roll": "pot", "ball": "pumpkin", "box": "apples", "small": "pumpkin", "mix": ["pot", "pumpkin", "apples"]},
	},
	"Track14": {
		"pieces": {
			"drum": {"glb": KIT % ["serengeti", "serengeti"], "node": "OilDrum", "shape": "cylinder"},
			"crate": {"glb": KIT % ["serengeti", "serengeti"], "node": "SupplyCrate", "shape": "box", "mass": 2.0},
			"jerry": {"glb": KIT % ["serengeti", "serengeti"], "node": "Jerrycan", "shape": "box", "mass": 1.0},
		},
		"roles": {"stack": "drum", "roll": "drum", "ball": "", "box": "crate", "small": "jerry", "mix": ["drum", "crate", "jerry"]},
	},
	"Track15": {
		"pieces": {
			"jar": {"glb": KIT % ["machupicchu", "machupicchu"], "node": "ClayJar", "shape": "cylinder", "mass": 2.5},
			"basket": {"glb": KIT % ["machupicchu", "machupicchu"], "node": "WovenBasket", "shape": "cylinder", "mass": 1.0},
			"pack": {"glb": KIT % ["machupicchu", "machupicchu"], "node": "Backpack", "shape": "box", "mass": 1.5},
		},
		"roles": {"stack": "basket", "roll": "jar", "ball": "", "box": "pack", "small": "basket", "mix": ["jar", "basket", "pack"]},
	},
	"Track16": {
		"pieces": {
			"cone": {"glb": KIT % ["fiordland", "fiordland"], "node": "RoadCone", "shape": "hull", "mass": 1.2},
			"buoy": {"glb": KIT % ["fiordland", "fiordland"], "node": "MooringBuoy", "shape": "sphere", "mass": 1.0, "bounce": 0.5},
			"bin": {"glb": KIT % ["fiordland", "fiordland"], "node": "FishBin", "shape": "box", "mass": 2.0},
		},
		"roles": {"stack": "bin", "roll": "", "ball": "buoy", "box": "bin", "small": "cone", "mix": ["cone", "buoy", "bin"]},
	},
	"Track17": {
		"pieces": {
			"spice": {"glb": KIT % ["jodhpur", "jodhpur"], "node": "SpiceBasket", "shape": "cylinder", "mass": 1.0},
			"matka": {"glb": KIT % ["jodhpur", "jodhpur"], "node": "Matka", "shape": "sphere", "mass": 1.5},
			"sack": {"glb": KIT % ["jodhpur", "jodhpur"], "node": "SpiceSack", "shape": "box", "mass": 2.5},
		},
		"roles": {"stack": "sack", "roll": "", "ball": "matka", "box": "sack", "small": "spice", "mix": ["spice", "matka", "sack"]},
	},
	"Track18": {
		"pieces": {
			"sake": {"glb": KIT % ["kyoto", "kyoto"], "node": "SakeBarrel", "shape": "cylinder", "mass": 3.0},
			"bucket": {"glb": KIT % ["kyoto", "kyoto"], "node": "WoodBucket", "shape": "cylinder", "mass": 0.8},
			"daruma": {"glb": KIT % ["kyoto", "kyoto"], "node": "Daruma", "shape": "sphere", "mass": 1.5},
		},
		"roles": {"stack": "sake", "roll": "sake", "ball": "daruma", "box": "", "small": "bucket", "mix": ["sake", "bucket", "daruma"]},
	},
	"Track19": {
		"pieces": {
			"bale": {"glb": KIT % ["monumentvalley", "monumentvalley"], "node": "RoundBale", "shape": "cylinder"},
			"bucket": {"glb": KIT % ["monumentvalley", "monumentvalley"], "node": "FeedBucket", "shape": "cylinder", "mass": 0.8},
			"barrel": {"glb": KIT % ["monumentvalley", "monumentvalley"], "node": "RanchBarrel", "shape": "cylinder", "mass": 3.0},
			"tumble": {"glb": "res://assets/models/monumentvalley/plants/tumbleweed.glb",
				"node": "", "shape": "sphere", "mass": 1.2, "bounce": 0.35},
		},
		"roles": {"stack": "barrel", "roll": "bale", "ball": "tumble", "box": "", "small": "bucket", "mix": ["barrel", "bucket", "tumble"]},
	},
	"Track20": {
		"pieces": {
			"float": {"glb": KIT % ["okinawa", "okinawa"], "node": "GlassFloat", "shape": "sphere", "mass": 0.8, "bounce": 0.4},
			"fishbox": {"glb": KIT % ["okinawa", "okinawa"], "node": "FishBox", "shape": "box", "mass": 0.6},
			"jar": {"glb": KIT % ["okinawa", "okinawa"], "node": "KameJar", "shape": "cylinder", "mass": 2.5},
		},
		"roles": {"stack": "fishbox", "roll": "jar", "ball": "float", "box": "fishbox", "small": "float", "mix": ["float", "fishbox", "jar"]},
	},
	"Track22": {
		"pieces": {
			"barrel": {"glb": KIT % ["halong", "halong"], "node": "FloatBarrel", "shape": "cylinder", "mass": 2.0},
			"basket": {"glb": KIT % ["halong", "halong"], "node": "FishBasket", "shape": "cylinder", "mass": 1.0},
			"hats": {"glb": KIT % ["halong", "halong"], "node": "HatStack", "shape": "hull", "mass": 0.5},
		},
		"roles": {"stack": "barrel", "roll": "barrel", "ball": "", "box": "", "small": "hats", "mix": ["barrel", "basket", "hats"]},
	},
	"Track23": {
		"pieces": {
			"cone": {"glb": KIT % ["carrara", "carrara"], "node": "SiteCone", "shape": "hull", "mass": 1.2},
			"reel": {"glb": KIT % ["carrara", "carrara"], "node": "CableReel", "shape": "cylinder", "mass": 3.0},
			"marble": {"glb": KIT % ["carrara", "carrara"], "node": "MarbleOffcut", "shape": "box", "mass": 4.0},
		},
		"roles": {"stack": "reel", "roll": "reel", "ball": "", "box": "", "small": "cone", "mix": ["cone", "reel", "cone"]},
	},
	"Track24": {
		"pieces": {
			"coconut": {"glb": KIT % ["angkor", "angkor"], "node": "Coconut", "shape": "sphere", "mass": 0.6, "bounce": 0.35},
			"rice": {"glb": KIT % ["angkor", "angkor"], "node": "RiceBasket", "shape": "cylinder", "mass": 1.0},
			"jar": {"glb": KIT % ["angkor", "angkor"], "node": "WaterJar", "shape": "cylinder", "mass": 2.5},
		},
		"roles": {"stack": "rice", "roll": "jar", "ball": "coconut", "box": "", "small": "coconut", "mix": ["coconut", "rice", "jar"]},
	},
}


## Meniurile de tipare pe fel de loc, compuse din rolurile pistei. Meniul se parcurge pe rand,
## ca doua grupuri vecine sa nu fie la fel.
static func _menus(roles: Dictionary) -> Dictionary:
	var stack := String(roles["stack"])
	var roll := String(roles.get("roll", ""))
	var ball := String(roles.get("ball", ""))
	var box := String(roles.get("box", ""))
	var small := String(roles["small"])
	var mix: Array = roles["mix"]
	var exit: Array = [
		{"pattern": "pyramid", "piece": stack, "count": 3, "layers": 2},
		{"pattern": "cluster", "piece": mix, "count": 5},
	]
	if not box.is_empty():
		exit.append({"pattern": "wall", "piece": box, "count": 3, "rows": 2})
	else:
		exit.append({"pattern": "row", "piece": stack, "count": 4})
	var overshoot: Array = []
	if not roll.is_empty():
		overshoot.append({"pattern": "row", "piece": roll, "count": 3, "lying": true})
	if not ball.is_empty():
		overshoot.append({"pattern": "row", "piece": ball, "count": 3})
	overshoot.append({"pattern": "taper", "piece": small, "count": 4})
	var inside: Array = [
		{"pattern": "row", "piece": small, "count": 2},
		{"pattern": "taper", "piece": small, "count": 3, "skew": 0.4},
	]
	var straight: Array = [{"pattern": "cluster", "piece": mix, "count": 4}]
	if not roll.is_empty():
		straight.append({"pattern": "row", "piece": roll, "count": 2, "lying": true})
	straight.append({"pattern": "row", "piece": stack, "count": 3})
	return {"exit": exit, "overshoot": overshoot, "inside": inside, "straight": straight}


var _track: Track
var _props: RoadsideProps
var _n: int = 0
var _spacing: float = 1.0


func _ready() -> void:
	var track_arg := ""
	var write := false
	var max_groups := 16
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_arg = arg.trim_prefix("--track=")
		elif arg == "--write":
			write = true
		elif arg.begins_with("--max="):
			max_groups = int(arg.trim_prefix("--max="))
	var idx := GameState.resolve_track_arg(track_arg)
	if idx < 0:
		push_error("SurveyRoadside: pista invalida '%s'" % track_arg)
		get_tree().quit(2)
		return
	var scene_path := String(GameState.TRACK_SCENES[idx])
	var stem := scene_path.get_file().get_basename()
	print("[roadside] pista %s" % GameState.track_arg_label(track_arg, idx))
	await get_tree().process_frame
	_track = (load(scene_path) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	for k in 4:
		await get_tree().physics_frame
	# Locurile se masoara FARA decorul lovibil deja asezat din fisier.
	var old := _track.get_node_or_null(^"RoadsideProps")
	if old != null:
		old.free()
		await get_tree().physics_frame
	_props = RoadsideProps.new()
	_props.track = _track
	_props.data = RoadsideSet.new()
	_track.add_child(_props)
	await get_tree().physics_frame
	_n = _track.baked.size()
	_spacing = _track._dists[_n] / float(_n)
	var spots := _find_spots()
	print("[roadside] %d locuri (lungime tur %.0f m, pas %.1f m)" % [spots.size(),
		_track._dists[_n], _spacing])
	print("    frac   parte  fel        viraj   adancime  lungime")
	for s: Dictionary in spots:
		print("    %.4f  %s  %-9s  %5.0f°   %4.1f m    %4.0f m" % [float(s["frac"]),
			"dr " if int(s["side"]) > 0 else "stg", String(s["kind"]), float(s["turn_deg"]),
			float(s["depth"]), float(s["along"])])
	if write:
		if not RECIPES.has(stem):
			push_error("SurveyRoadside: nicio reteta pentru %s" % stem)
			get_tree().quit(2)
			return
		_write(stem, spots, max_groups)
	get_tree().quit(0)


## Adancimea libera (m) de la marginea drumului spre exterior, la indexul si partea date.
func _depth(i: int, side_sign: float) -> float:
	if _track._road_gap(i) or _track._bridge_mix(i) > 0.05:
		return 0.0
	var out := _track._side_at(i) * side_sign
	out.y = 0.0
	out = out.normalized()
	var edge := _track.baked[i] + out * _track.width_at_index(i)
	var best := 0.0
	for d in DEPTHS:
		if _props.spot(edge + out * d, _track.baked[i].y, 0.4).is_empty():
			break
		best = d
	return best


func _find_spots() -> Array[Dictionary]:
	var step := maxi(1, int(roundf(STEP_M / _spacing)))
	var ang := _track._turn_angles()
	var win := maxi(1, int(TURN_WINDOW_M / _spacing))
	# Virajul cumulat pe fereastra, per index.
	var turn := PackedFloat32Array()
	turn.resize(_n)
	for i in _n:
		var t := 0.0
		for k in range(-win, win + 1):
			t += ang[(i + k + _n) % _n]
		turn[i] = t
	# Adancimea libera, pe ambele parti, la fiecare pas.
	var depth := {1: PackedFloat32Array(), -1: PackedFloat32Array()}
	for sgn: int in [1, -1]:
		var arr := PackedFloat32Array()
		arr.resize(_n)
		for i in range(0, _n, step):
			var d := _depth(i, float(sgn))
			for k in step:
				if i + k < _n:
					arr[i + k] = d
		depth[sgn] = arr
	var start_clear := int(START_CLEAR_M / _spacing)
	var out: Array[Dictionary] = []
	# Viraje: varful = maximul local al |virajului|.
	var i := 0
	while i < _n:
		if absf(turn[i]) < CORNER_MIN_RAD:
			i += 1
			continue
		var apex := i
		var j := i
		while j < _n and absf(turn[j]) >= CORNER_MIN_RAD * 0.6:
			if absf(turn[j]) > absf(turn[apex]):
				apex = j
			j += 1
		# Exteriorul: virajul la stanga (unghi pozitiv) are exteriorul pe dreapta.
		var sgn := 1 if turn[apex] > 0.0 else -1
		for kind: String in ["overshoot", "exit"]:
			var lo := apex + int((2.0 if kind == "overshoot" else 22.0) / _spacing)
			var hi := apex + int((16.0 if kind == "overshoot" else 48.0) / _spacing)
			var best := _best_in(depth[sgn], lo, hi, step)
			if best.is_empty():
				continue
			var bi := int(best["i"])
			if bi < start_clear or bi > _n - start_clear:
				continue
			out.append({"i": bi, "frac": float(bi) / float(_n), "side": sgn, "kind": kind,
				"turn_deg": rad_to_deg(turn[apex]), "depth": best["depth"], "along": best["along"]})
		i = j + 1
	# Drepte lungi: mijlocul, pe partea cu mai mult loc.
	i = 0
	while i < _n:
		if absf(turn[i]) > STRAIGHT_MAX_RAD:
			i += 1
			continue
		var j := i
		while j < _n and absf(turn[j]) <= STRAIGHT_MAX_RAD:
			j += 1
		if float(j - i) * _spacing >= STRAIGHT_MIN_M:
			var mid := (i + j) / 2
			var span := int(20.0 / _spacing)
			var a := _best_in(depth[1], mid - span, mid + span, step)
			var b := _best_in(depth[-1], mid - span, mid + span, step)
			var pick := a
			var sgn := 1
			if a.is_empty() or (not b.is_empty() and float(b["depth"]) > float(a["depth"])):
				pick = b
				sgn = -1
			if not pick.is_empty():
				var bi := int(pick["i"])
				if bi >= start_clear and bi <= _n - start_clear:
					out.append({"i": bi, "frac": float(bi) / float(_n), "side": sgn,
						"kind": "straight", "turn_deg": 0.0, "depth": pick["depth"],
						"along": pick["along"]})
		i = j + 1
	# Restul fasiilor libere, pe ambele parti, din 60 in 60 m.
	var hop := int(60.0 / _spacing)
	for sgn: int in [1, -1]:
		for base in range(start_clear, _n - start_clear, hop):
			var pick := _best_in(depth[sgn], base, base + hop - 1, step)
			if pick.is_empty():
				continue
			var bi := int(pick["i"])
			if bi < start_clear or bi > _n - start_clear:
				continue
			var kind := "open"
			if absf(turn[bi]) >= 0.44:
				kind = "outside" if (turn[bi] > 0.0) == (sgn > 0) else "inside"
			out.append({"i": bi, "frac": float(bi) / float(_n), "side": sgn, "kind": kind,
				"turn_deg": rad_to_deg(turn[bi]), "depth": pick["depth"], "along": pick["along"]})
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return int(x["i"]) < int(y["i"]))
	# Cat din tur are acostament liber, pe fiecare parte, si cate viraje sunt.
	var free_r := 0
	var free_l := 0
	var corners := 0
	var was := false
	for q in _n:
		if depth[1][q] >= 1.8:
			free_r += 1
		if depth[-1][q] >= 1.8:
			free_l += 1
		var now := absf(turn[q]) >= CORNER_MIN_RAD
		if now and not was:
			corners += 1
		was = now
	print("[roadside] acostament liber (>= 1,8 m): dreapta %d%%, stanga %d%% din tur; %d viraje" % [
		free_r * 100 / _n, free_l * 100 / _n, corners])
	return out


## Cel mai bun index din [lo, hi]: adancime cel putin 1,8 m, cu cea mai lunga fasie libera.
func _best_in(depth: PackedFloat32Array, lo: int, hi: int, step: int) -> Dictionary:
	var best := {}
	for i in range(lo, hi + 1, step):
		var w := ((i % _n) + _n) % _n
		if depth[w] < 1.8:
			continue
		# Lungimea fasiei libere in jurul lui, cu adancimea minima de pe ea.
		var along := 0
		var dmin := depth[w]
		for dir: int in [-1, 1]:
			var k := 1
			while k * step * _spacing < 12.0:
				var q := (((i + dir * k * step) % _n) + _n) % _n
				if depth[q] < 1.8:
					break
				dmin = minf(dmin, depth[q])
				along += 1
				k += 1
		var along_m := float(along + 1) * float(step) * _spacing
		if along_m < 5.0:
			continue
		var score := dmin * 2.0 + along_m * 0.25
		if best.is_empty() or score > float(best["score"]):
			best = {"i": w, "depth": dmin, "along": along_m, "score": score}
	return best


func _write(stem: String, spots: Array[Dictionary], max_groups: int) -> void:
	var recipe: Dictionary = RECIPES[stem]
	var menus := _menus(recipe["roles"])
	# Un grup per SECTOR de tur (turul impartit in `max_groups` felii egale), ca decorul sa fie
	# intins pe toata pista, nu strans in zona cu cele mai multe viraje. In sector castiga felul
	# de loc (iesirea din viraj inaintea dreptei), apoi adancimea. Doua grupuri vecine nu stau
	# la mai putin de GROUP_GAP_M.
	var rank := {"exit": 0, "overshoot": 1, "outside": 1, "straight": 2, "inside": 2, "open": 3}
	var gap := int(GROUP_GAP_M / _spacing)
	var kept: Array[Dictionary] = []
	for sector in max_groups:
		var lo := _n * sector / max_groups
		var hi := _n * (sector + 1) / max_groups
		var best := {}
		for s: Dictionary in spots:
			var si := int(s["i"])
			if si < lo or si >= hi:
				continue
			if not kept.is_empty() and si - int(kept[-1]["i"]) < gap:
				continue
			if best.is_empty() or int(rank[s["kind"]]) < int(rank[best["kind"]]) \
					or (rank[s["kind"]] == rank[best["kind"]] and float(s["depth"]) > float(best["depth"])):
				best = s
		if not best.is_empty():
			kept.append(best)
	var res := RoadsideSet.new()
	res.pieces = (recipe["pieces"] as Dictionary).duplicate(true)
	for id: String in res.pieces:
		if not (res.pieces[id] as Dictionary).has("scale"):
			res.pieces[id]["scale"] = PIECE_SCALE
	var dropped := 0
	var turn_at := {"exit": 0, "overshoot": 0, "outside": 0, "straight": 0, "inside": 0, "open": 0}
	var groups: Array[Dictionary] = []
	var total := 0
	for s: Dictionary in kept:
		# Fiecare fel de loc isi are meniul; cele fara meniu propriu il iau pe al rudei.
		var fallback := {"outside": "overshoot", "overshoot": "exit", "inside": "straight",
			"open": "straight", "straight": "exit"}
		var key := String(s["kind"])
		while not menus.has(key):
			key = String(fallback[key])
		var menu: Array = menus[key]
		var pick: Dictionary = (menu[int(turn_at[s["kind"]]) % menu.size()] as Dictionary).duplicate(true)
		turn_at[s["kind"]] = int(turn_at[s["kind"]]) + 1
		# Loc ingust: zidul pe mai multe randuri devine sir.
		if String(pick.get("pattern", "row")) == "wall" and float(s["depth"]) < 3.0:
			pick["rows"] = 1
		if String(pick.get("pattern", "row")) == "cluster" and float(s["depth"]) < 3.4:
			pick["pattern"] = "row"
		var g := {"frac": snappedf(float(s["frac"]), 0.0001), "side": int(s["side"]), "gap": 1.2,
			"note": "%s, viraj %.0f grade" % [s["kind"], float(s["turn_deg"])]}
		g.merge(pick)
		# Propunerea se verifica pe locul ei, cu regula de asezare: cat timp o piesa n-are loc
		# bun, grupul se micsoreaza, apoi devine sir simplu; daca nici asa, nu se scrie.
		_props.data = res
		while _props.missing(g) > 0:
			if int(g.get("count", 3)) > 2:
				g["count"] = int(g.get("count", 3)) - 1
			elif String(g.get("pattern", "row")) != "row":
				g["pattern"] = "row"
				g["count"] = 3
				g.erase("rows")
				g.erase("layers")
			else:
				g = {}
				break
		if g.is_empty():
			dropped += 1
			continue
		groups.append(g)
	res.groups = groups
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RoadsideProps.SET_DIR))
	var path := RoadsideProps.SET_DIR + stem + ".tres"
	var err := ResourceSaver.save(res, path)
	print("[roadside] scris %s: %d grupuri, %d renuntate fara loc (cod %d)" % [path,
		groups.size(), dropped, err])
	for g: Dictionary in groups:
		print("    %.4f  %s  %-8s %-22s x%d   %s" % [float(g["frac"]),
			"dr " if int(g["side"]) > 0 else "stg", String(g["pattern"]), str(g["piece"]),
			int(g.get("count", 3)), String(g["note"])])
		total += 1
