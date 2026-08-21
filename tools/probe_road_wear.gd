extends Node
## Sonda foii de uzura (RoadWear) de pe drumul de zapada al Baikalului.
##
## Ruleaza CU FEREASTRA, ca Snapshot: viewport-urile nu deseneaza headless,
## iar aici chiar continutul foii e ce se verifica — o sonda care doar numara
## noduri ar trece si cu masca goala (lectia din tools/probe_fx.gd: efectele
## nu se verifica numarand, se citesc pixeli, cu punct de control curat).
##
##   godot --path . res://tools/ProbeRoadWear.tscn
##
## Ce verifica:
##   1. foaia exista pe Track10 si shaderul soselei o are ca uniform;
##   2. road_coords intoarce (distanta, lateral) corecte pe puncte cunoscute;
##   3. o rafala de stampile pe fractiile 0.60-0.64 chiar SCRIE in foaie:
##      pixelii cititi inapoi au alfa acolo, si NU au pe un punct de control
##      nestampilat de la marginea benzii;
##   4. pre-seed-ul (fagasele "de-o iarna") exista pe un rand nestampilat.
## Salveaza foaia intreaga si o captura la nivelul soselei in snapshots/.

const TRACK := "res://scenes/tracks/Track10.tscn"

var _fails := 0


func _check(what: String, ok: bool, detail: String = "") -> void:
	print("  %s  %s%s" % ["OK  " if ok else "PICA", what,
		"" if detail.is_empty() else "  (" + detail + ")"])
	if not ok:
		_fails += 1


func _ready() -> void:
	print("=== ProbeRoadWear: Track10 (Baikal) ===")
	var track: Track = (load(TRACK) as PackedScene).instantiate()
	add_child(track)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var wear: RoadWear = track.get_node_or_null("RoadWear") as RoadWear
	_check("foaia de uzura exista pe drumul de zapada", wear != null)
	if wear == null:
		_finish()
		return

	# 2. Matematica spatiului benzii, pe puncte construite de mana.
	var i := 200
	var on_axis: Vector3 = track.baked[i]
	var side: Vector3 = track._side_at(i)
	var rc := track.road_coords(i, on_axis + side * 3.0)
	_check("road_coords: lateralul unui punct impins 3 m",
		absf(rc.y - 3.0) < 0.3, "lat=%.2f" % rc.y)
	_check("road_coords: distanta ramane a indexului",
		absf(rc.x - float(track._dists[i])) < 4.0,
		"d=%.1f fata de %.1f" % [rc.x, float(track._dists[i])])

	# 3. Rafala de stampile pe malul dintre tabara si viaduct (0.60-0.64 —
	# sosea de zapada, nu gheata). MAXIM cateva pe cadru: pool-ul foii e un
	# inel de 32, o rafala intr-un singur cadru si-ar rescrie propriile
	# sprite-uri inainte de desen.
	var n: int = track.baked.size()
	var total: float = track._dists[n]
	var stamped := 0
	for batch in 25:
		for k in 8:
			var f := 0.60 + 0.04 * float(stamped) / 200.0
			var idx := int(f * float(n)) % n
			var pos: Vector3 = track.baked[idx] \
				+ track._side_at(idx) * (2.0 * sin(float(stamped) * 0.13))
			track.stamp_wear(idx, pos)
			stamped += 1
		await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var img := wear.get_texture().get_image()
	_check("foaia se poate citi inapoi", img != null and not img.is_empty())
	if img == null or img.is_empty():
		_finish()
		return
	var w := img.get_width()
	var h := img.get_height()

	# Randul din mijlocul rafalei: pe banda centrala (stampilele au serpuit
	# +-2 m in jurul axului) trebuie sa existe alfa consistenta.
	var band_max := 0.0
	var py := int(0.62 * float(h))
	for px in range(int(0.30 * w), int(0.70 * w)):
		band_max = maxf(band_max, img.get_pixel(px, py).a)
	_check("stampilele au scris in foaie la frac 0.62", band_max > 0.10,
		"alfa max %.2f" % band_max)

	# Punct de CONTROL: acelasi rand, buza laterala a mastii — nicio roata
	# n-a calcat acolo, nici pre-seed-ul nu ajunge (el serpuieste +-2 m in
	# jurul axului, buza e la ~12 m).
	var edge_max := 0.0
	for px in range(0, 6):
		edge_max = maxf(edge_max, img.get_pixel(px, py).a)
	_check("punctul de control de pe buza ramane curat", edge_max < 0.02,
		"alfa max %.2f" % edge_max)

	# 4. Pre-seed: un rand DEPARTE de rafala are deja fagasele palide.
	var seed_max := 0.0
	var py_seed := int(0.85 * float(h))
	for px in range(int(0.30 * w), int(0.70 * w)):
		seed_max = maxf(seed_max, img.get_pixel(px, py_seed).a)
	_check("fagasele de pre-seed exista pe un rand nestampilat",
		seed_max > 0.05, "alfa max %.2f" % seed_max)

	# Capturi pentru ochi: foaia intreaga + soseaua de la nivelul masinii,
	# exact prin banda stampilata.
	DirAccess.make_dir_recursive_absolute("res://snapshots")
	img.save_png("res://snapshots/probe_wear_mask.png")
	var cam := Camera3D.new()
	add_child(cam)
	var eye_i := int(0.606 * float(n)) % n
	var ahead := int(0.625 * float(n)) % n
	cam.position = track.baked[eye_i] + Vector3.UP * 2.5
	cam.current = true
	cam.look_at(track.baked[ahead] + Vector3.UP * 0.5)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	shot.save_png("res://snapshots/probe_wear_road.png")
	print("  salvat: snapshots/probe_wear_mask.png + probe_wear_road.png")
	print("  (uzura totala: %d stampile pe %d m de sosea)" % [stamped, int(total)])
	_finish()


func _finish() -> void:
	print("VERDICT: " + ("OK" if _fails == 0 else "PICA (%d)" % _fails))
	get_tree().quit(0 if _fails == 0 else 1)
