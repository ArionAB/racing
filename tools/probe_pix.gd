extends Node
## Faleza in PIXELI, nu in vertecsi: se randeaza scena de doua ori din aceeasi
## camera — o data intreaga, o data cu panza STINSA — si se compara imaginile.
##
## Sonda asta exista fiindca cea de dinainte a mintit convingator: numarul de
## vertecsi „neascunsi" a crescut de 6 ori (29 -> 169) si captura a ramas
## IDENTICA pixel cu pixel. Cauza: occluderul se testa cu raze fizice, iar panza
## n-are corp — deci se masura altceva decat deseneaza GPU-ul.
##
## Diferenta dintre cele doua randari e, prin definitie, exact suprafata pe care
## faleza o pune pe ecran. Daca e zero, faleza nu e in cadru, oricat ar spune
## orice alta sonda.
## CE NU MASOARA sonda asta, ca sa nu fie citita gresit a treia oara:
## numara doar pixelii celor doua PANZE (`Faleza*`). Dupa ce pintenul s-a mutat
## la 15 m, o buna parte din efectul vizual il face BUZA DE TEREN de la 8 m
## (masurata cu ProbeBrow: cadere de 77-85 grade), care nu e o panza si deci nu
## intra in cifra. Numarul de aici e un PLANSEU, nu nota finala — verdictul se
## da pe capturile --gamecam, cu ochiul, fata de referinta.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var fracs: Array[float] = [0.22, 0.28, 0.34]
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var mis: Array[Node] = []
	_walk(t, mis)
	print("panze de faleza gasite: %d" % mis.size())
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = ChaseCamera.FAR_PLANE
	cam.current = true
	for f in fracs:
		await _shot(t, cam, f, mis)
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _shot(t: Track, cam: Camera3D, frac: float, mis: Array[Node]) -> void:
	var route := t.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	cam.position = focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	cam.look_at(focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT, Vector3.UP)
	for m in mis:
		(m as MeshInstance3D).visible = true
	for k in 3:
		await RenderingServer.frame_post_draw
	var with_img := get_viewport().get_texture().get_image()
	for m in mis:
		(m as MeshInstance3D).visible = false
	for k in 3:
		await RenderingServer.frame_post_draw
	var without_img := get_viewport().get_texture().get_image()
	for m in mis:
		(m as MeshInstance3D).visible = true
	var w := with_img.get_width()
	var h := with_img.get_height()
	var diff := 0
	var total := w * h
	var xmin := w
	var xmax := -1
	var ymin := h
	var ymax := -1
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			var a := with_img.get_pixel(x, y)
			var b := without_img.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.02:
				diff += 1
				xmin = mini(xmin, x); xmax = maxi(xmax, x)
				ymin = mini(ymin, y); ymax = maxi(ymax, y)
	var pct := 100.0 * float(diff) / float(total / 4)
	print("\n=== frac %.2f — FALEZA IN PIXELI ===" % frac)
	if diff == 0:
		print("  0.00%% din cadru  [PICAT: panza nu deseneaza nimic]")
	else:
		print("  %.2f%% din cadru; dreptunghi x %d..%d, y %d..%d (din %dx%d, y=0 sus)"
			% [pct, xmin, xmax, ymin, ymax, w, h])
	var dd := ProjectSettings.globalize_path("res://snapshots/r3")
	DirAccess.make_dir_recursive_absolute(dd)
	with_img.save_png("%s/pix_%.2f_cu.png" % [dd, frac])

func _walk(n: Node, out: Array[Node]) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("Faleza"):
			out.append(c)
		_walk(c, out)
