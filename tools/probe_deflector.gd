extends Node
## Sonda deflectorului imbracat cu un obiect din lume (#244).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDeflector.tscn
##
## Ca SCENA, nu cu --script: hazardele au nevoie de autoload-uri ca sa compileze.
##
## Ce verifica:
##
##   1. OBIECTUL APARE. Cu model declarat, bariera e facuta din piese de model,
##      nu din lama procedurala. Se numara MeshInstance-urile venite din GLB.
##   2. BARIERA E INTREAGA. Piesele acopera diagonala fara gauri prin care o
##      masina ar trece fara sa atinga nimic — se masoara acoperirea reala, nu
##      se presupune din numarul de piese.
##   3. MECANICA E NEATINSA. Coliziunea si ghiontul raman exact ce erau: acelasi
##      numar de forme, aceeasi valoare de `push`. Issue-ul cere schimbare de
##      HAINA, nu de comportament — daca s-ar fi miscat si mecanica, ar fi
##      trebuit remasurate liniile de trecere.
##   4. FALLBACK. Fara model, iese lama alba cu dungi, ca inainte.
##
## Plus: pe pistele reale, deflectoarele chiar primesc obiectul temei.

const HALF_WIDTH: float = 7.0
const MODEL := "res://assets/models/scatter/beach_clutter.glb"
const MODEL_NODE := "Driftwood_Log"


func _ready() -> void:
	await get_tree().process_frame

	print("")
	print("=== Sonda deflector din obiect ===")
	var failed := false

	var dressed := _build(true)
	var plain := _build(false)

	# 1. obiectul apare
	var pieces: int = dressed["model_pieces"]
	var pieces_ok := pieces >= 2
	if not pieces_ok:
		failed = true
	print("\ncu model declarat:")
	print("  piese de model     -> %d  %s"
			% [pieces, "OK" if pieces_ok else "PROBLEMA (a cazut pe lama)"])

	# 2. bariera e intreaga
	var gap: float = dressed["max_gap"]
	var gap_ok := gap < 1.6 # sub jumatate de masina: nu se strecoara nimeni
	if not gap_ok:
		failed = true
	print("  gaura maxima intre -> %.2f m  %s"
			% [gap, "OK" if gap_ok else "PROBLEMA (bariera are gauri)"])
	var cover: float = dressed["coverage"]
	var cover_ok := cover > 0.9
	if not cover_ok:
		failed = true
	print("  acoperire diagonala-> %.0f%%  %s"
			% [cover * 100.0, "OK" if cover_ok else "PROBLEMA"])

	# 3. mecanica neatinsa
	print("\nmecanica (trebuie identica):")
	for pair in [["forme de coliziune", "shapes"], ["zone de ghiont", "areas"]]:
		var label: String = pair[0]
		var key: String = pair[1]
		var a: int = dressed[key]
		var b: int = plain[key]
		var same := a == b
		if not same:
			failed = true
		print("  %-18s -> cu model %d, fara %d  %s"
				% [label, a, b, "OK" if same else "PROBLEMA"])
	var push_same: bool = is_equal_approx(dressed["push"], plain["push"])
	if not push_same:
		failed = true
	print("  %-18s -> %.1f / %.1f m/s  %s"
			% ["ghiont", dressed["push"], plain["push"],
			"OK" if push_same else "PROBLEMA"])

	# 4. fallback
	var plain_pieces: int = plain["model_pieces"]
	var plain_ok := plain_pieces == 0 and int(plain["meshes"]) > 0
	if not plain_ok:
		failed = true
	print("\nfara model (neregresie):")
	print("  lama procedurala   -> %d mesh-uri, 0 din GLB  %s"
			% [plain["meshes"], "OK" if plain_ok else "PROBLEMA"])

	# 5. pe piste reale
	print("\npe piste reale:")
	for entry in [[0, "Dunele"], [1, "Okinawa manual"]]:
		var idx: int = entry[0]
		var nm: String = entry[1]
		var found := await _track_deflectors(idx)
		var total: int = found["count"]
		var withmodel: int = found["with_model"]
		var ok := total == 0 or withmodel == total
		if not ok:
			failed = true
		print("  %-16s -> %d deflectoare, %d imbracate  %s"
				% [nm, total, withmodel,
				"OK" if ok else "PROBLEMA"])

	print("")
	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


## Construieste un deflector si numara ce a iesit din el.
func _build(with_model: bool) -> Dictionary:
	var d := DeflectorHazard.new()
	d.road_half_width = HALF_WIDTH
	d.side_sign = 1.0
	if with_model and ResourceLoader.exists(MODEL):
		d.model_scene = load(MODEL)
		d.model_node = MODEL_NODE
		d.tri_class = "wood"
	add_child(d)

	var meshes: Array[MeshInstance3D] = []
	var shapes := 0
	var areas := 0
	_walk(d, meshes)
	for n in _all(d):
		if n is CollisionShape3D:
			shapes += 1
		elif n is Area3D:
			areas += 1

	# Piesele de model = mesh-uri venite din GLB. Se recunosc dupa NUME (piesa
	# ceruta), nu dupa lipsa unui `material_override`: si ele primesc unul,
	# fiindca materialul de clasa se pune tot asa.
	var model_pieces := 0
	var centers: Array[Vector3] = []
	for m in meshes:
		if String(m.name).begins_with(MODEL_NODE):
			model_pieces += 1
			centers.append(d.to_local(m.global_position))

	var out := {
		"meshes": meshes.size(),
		"model_pieces": model_pieces,
		"shapes": shapes,
		"areas": areas,
		"push": d.push,
		"max_gap": _max_gap(centers),
		"coverage": _coverage(centers, d),
	}
	d.queue_free()
	return out


## Cea mai mare distanta intre doua piese consecutive de-a lungul barierei.
func _max_gap(centers: Array[Vector3]) -> float:
	if centers.size() < 2:
		return 999.0
	var sorted := centers.duplicate()
	sorted.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z > b.z)
	var worst := 0.0
	for i in range(1, sorted.size()):
		worst = maxf(worst, sorted[i - 1].distance_to(sorted[i]))
	return worst


## Cat din diagonala declarata e acoperita de piese, ca fractie.
func _coverage(centers: Array[Vector3], d: DeflectorHazard) -> float:
	if centers.size() < 2:
		return 0.0
	var lo := INF
	var hi := -INF
	for c in centers:
		lo = minf(lo, c.z)
		hi = maxf(hi, c.z)
	return clampf((hi - lo) / maxf(d.slide_len, 0.001), 0.0, 1.0)


## Cate deflectoare are pista si cate sunt imbracate cu un model.
func _track_deflectors(track_idx: int) -> Dictionary:
	var scene: PackedScene = load(GameState.TRACK_SCENES[track_idx])
	var track: Node = scene.instantiate()
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var found: Array[Node] = []
	_walk_class(track, found)
	var with_model := 0
	for f: DeflectorHazard in found:
		if f.model_scene != null:
			with_model += 1
	var out := {"count": found.size(), "with_model": with_model}
	track.queue_free()
	await get_tree().process_frame
	return out


func _walk(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_walk(c, out)


func _walk_class(n: Node, out: Array[Node]) -> void:
	if n is DeflectorHazard:
		out.append(n)
	for c in n.get_children():
		_walk_class(c, out)


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
