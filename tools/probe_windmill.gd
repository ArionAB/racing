extends Node
## Sonda morii de vant (#245): morisca de balci devine moara, fara sa se schimbe
## mecanica.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWindmill.tscn
##
## Ce verifica, si de ce:
##
##   1. TURNUL NU E PE CAROSABIL. Cladirea sta lateral, dincolo de bataia
##      aripilor. Un turn pe axa drumului ar fi un zid in mijlocul soselei —
##      caruselul trebuie sa lase o fereastra, nu sa inchida drumul.
##   2. FEREASTRA E NESCHIMBATA. Aceeasi bataie, acelasi numar de brate, aceeasi
##      perioada ca la morisca — deci timpul in care drumul e liber ramane
##      acelasi. Asta e cifra care decide daca hazardul mai e jucabil, si e
##      chiar ce cere issue-ul sa fie remasurat.
##   3. MECANICA E NEATINSA. Ghiontul si formele de coliziune ale bratelor sunt
##      identice cu inainte.
##   4. PALETELE CLADIRII SUNT ARUNCATE. Moara are propriile ei palete la 9.66 m;
##      lasate acolo, s-ar fi invartit separat de bratele care matura drumul.
##   5. FALLBACK: fara model, iese morisca de dinainte.

const HALF_WIDTH: float = 7.0
const MODEL := "res://assets/models/buildings/windmill.glb"


func _ready() -> void:
	await get_tree().process_frame

	print("")
	print("=== Sonda moara de vant ===")
	var failed := false

	var mill := _build(true)
	var plain := _build(false)

	# 1. turnul, lateral
	var tower_x: float = mill["tower_x"]
	var clear := tower_x >= HALF_WIDTH
	if not clear:
		failed = true
	print("\nturnul:")
	print("  la %.1f m de axa (semilatime %.1f)  %s"
			% [tower_x, HALF_WIDTH,
			"OK" if clear else "PROBLEMA (sta pe carosabil)"])

	# 4. paletele cladirii
	var blades_left: int = mill["building_blades"]
	var blades_ok := blades_left == 0
	if not blades_ok:
		failed = true
	print("  palete proprii ramase -> %d  %s"
			% [blades_left, "OK (aruncate)" if blades_ok else "PROBLEMA"])

	# 2. fereastra de trecere
	print("\nfereastra de trecere (trebuie neschimbata):")
	for pair in [["bataia bratelor", "reach"], ["perioada", "period"]]:
		var label: String = pair[0]
		var key: String = pair[1]
		var a: float = mill[key]
		var b: float = plain[key]
		var same := is_equal_approx(a, b)
		if not same:
			failed = true
		print("  %-16s -> moara %.2f, morisca %.2f  %s"
				% [label, a, b, "OK" if same else "PROBLEMA"])
	# Cat timp dintr-o rotatie drumul e liber, ca fractie. Cu N brate, un brat
	# ocupa unghiul lui si restul e fereastra.
	var window: float = mill["window_frac"]
	var window_ok := window > 0.55
	if not window_ok:
		failed = true
	print("  drum liber       -> %.0f%% din rotatie  %s"
			% [window * 100.0, "OK" if window_ok else "PROBLEMA (prea inchis)"])

	# 3. mecanica
	print("\nmecanica bratelor (trebuie identica):")
	var arms_same: bool = mill["arm_shapes"] == plain["arm_shapes"]
	if not arms_same:
		failed = true
	print("  forme de coliziune -> moara %d, morisca %d  %s"
			% [mill["arm_shapes"], plain["arm_shapes"],
			"OK" if arms_same else "PROBLEMA"])
	var push_same: bool = is_equal_approx(mill["push"], plain["push"])
	if not push_same:
		failed = true
	print("  ghiont             -> %.1f / %.1f m/s  %s"
			% [mill["push"], plain["push"], "OK" if push_same else "PROBLEMA"])

	# 5. fallback
	print("\nfara model (neregresie):")
	var hub_ok: bool = plain["tower_x"] < 0.01 and int(plain["hub_meshes"]) >= 2
	if not hub_ok:
		failed = true
	print("  butuc procedural   -> %d mesh-uri pe axa  %s"
			% [plain["hub_meshes"], "OK" if hub_ok else "PROBLEMA"])

	print("")
	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


func _build(with_tower: bool) -> Dictionary:
	var c := CarouselHazard.new()
	c.arm_reach = HALF_WIDTH - 0.2
	if with_tower and ResourceLoader.exists(MODEL):
		c.tower_scene = load(MODEL)
		c.tower_scale = 1.0
		c.mill_blades = true
		c.tower_offset = HALF_WIDTH + 2.2
	add_child(c)

	# Turnul: corpul static care NU e rotorul.
	var tower_x := 0.0
	var hub_meshes := 0
	for child in c.get_children():
		if child is StaticBody3D:
			tower_x = maxf(tower_x, absf((child as Node3D).position.x))
			for m in _all(child):
				if m is MeshInstance3D:
					hub_meshes += 1

	# Paletele proprii ale cladirii, daca au ramas.
	var building_blades := 0
	for n in _all(c):
		if n is MeshInstance3D \
				and String(n.name).begins_with(CarouselHazard.BLADES_NODE):
			building_blades += 1

	# Formele de coliziune ale BRATELOR (rotorul), nu ale turnului.
	var arm_shapes := 0
	for n in _all(c):
		if n is AnimatableBody3D:
			for s in _all(n):
				if s is CollisionShape3D:
					arm_shapes += 1

	var out := {
		"tower_x": tower_x,
		"hub_meshes": hub_meshes,
		"building_blades": building_blades,
		"arm_shapes": arm_shapes,
		"reach": c.arm_reach,
		"period": c.period,
		"push": c.sweep_push,
		# Fereastra: fiecare brat ocupa un unghi dat de latimea lui la raza
		# medie; restul rotatiei e drum liber.
		"window_frac": _window_frac(c),
	}
	c.queue_free()
	return out


## Cat din rotatie drumul e liber, ca fractie 0..1.
func _window_frac(c: CarouselHazard) -> float:
	# Latimea efectiva a unui brat (grinda + panza) la jumatatea razei.
	var arm_w := 0.32 + 1.1 # vane_t + marja zonei de ghiont
	var r := maxf(c.arm_reach * 0.5, 0.001)
	var blocked := float(c.arm_count) * 2.0 * atan(arm_w * 0.5 / r)
	return clampf(1.0 - blocked / TAU, 0.0, 1.0)


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
