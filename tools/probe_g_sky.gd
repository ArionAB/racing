extends Node
## Cate azimuturi lasa CER deasupra, pe masura ce masina urca prin stanca goala.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeGSky.tscn
##
## [b]Ce intreaba, si de ce nu ce intreba prima versiune.[/b] Criticul orb a zis
## "camera e sigilata intr-un butoi maro inchis, fara cer". Prima versiune a
## sondei masura plafonul decorului pe azimut la o cota FIXA a masinii (30 m) si
## raporta 0/24 — si inainte, si dupa o schimbare care coborase capacul cu 30 m.
## Adica masura o cota, nu efectul. E aceeasi capcana ca peste tot in proiect:
## sonda numara, nu se uita.
##
## Brief-ul POI G nu cere "sa fie deschis", cere ca "lumina de sus sa creasca la
## fiecare tura". Aia e o DERIVATA: cate azimuturi se deschid pe masura ce urci
## de la 12 la 48 m. Camera vede in sus `y_masina + 10 + 0.093*d`, deci acelasi
## zid se deschide singur cand ochiul urca. Cifra care conteaza e coloana, nu o
## celula din ea.
##
## Se masoara cazul CEL MAI GREU: masina pe banda diametral opusa peretelui,
## unde distanta (si deci plafonul frustumului) e maxima, dar si zidul e vazut
## de departe.

const AXIS := Vector2(-302.02, 6.00)
const HELIX_R: float = 28.0
const CAM_H: float = 10.0


func _ready() -> void:
	var track: Node = (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var g: Node = track.get_node_or_null("DecorManual/G) Stanca goala")
	if g == null:
		print("VERDICT: ESEC — nu exista DecorManual/G) Stanca goala")
		get_tree().quit(1)
		return
	var top := {}
	var stack: Array[Node] = [g]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for k in c.get_children():
			stack.append(k)
		var mi := c as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := mi.global_transform
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			for v in arr[Mesh.ARRAY_VERTEX] as PackedVector3Array:
				var w: Vector3 = xf * v
				var d := Vector2(w.x - AXIS.x, w.z - AXIS.y)
				var az := int(round(rad_to_deg(atan2(d.y, d.x)) / 15.0)) * 15
				if az < 0:
					az += 360
				if not top.has(az) or w.y > float(top[az][0]):
					top[az] = [w.y, d.length()]
	var keys := top.keys()
	keys.sort()

	print("
=== POI G — cate azimuturi lasa cer, pe masura ce urci ===")
	var first := -1
	var last := -1
	for car_y: float in [12.0, 20.0, 28.0, 36.0, 44.0, 48.0]:
		var n := 0
		for az in keys:
			var y: float = float(top[az][0])
			var r: float = float(top[az][1])
			var d: float = r + HELIX_R
			if y < car_y + CAM_H + 0.093 * d:
				n += 1
		if first < 0:
			first = n
		last = n
		print("  masina la %5.1f m -> %2d / %d azimuturi cu CER" % [car_y, n, keys.size()])

	print("
=== plafonul pe azimut ===")
	print(" azimut | cota max | raza")
	for az in keys:
		print("  %5d | %8.1f | %5.1f" % [az, float(top[az][0]), float(top[az][1])])

	# Contractul: la baza inchis (drama), la varf deschis (rasplata), si sa
	# CREASCA intre ele. Un inel care e deschis peste tot ar fi la fel de gresit
	# ca unul inchis peste tot — n-ar mai fi nicio crestere de lumina.
	print("")
	if last <= first:
		print("VERDICT: ESEC — lumina nu creste: %d azimuturi la baza, %d la varf"
			% [first, last])
		get_tree().quit(1)
		return
	if last == 0:
		print("VERDICT: ESEC — butoi inchis: 0 azimuturi cu cer chiar si la varf")
		get_tree().quit(1)
		return
	print("VERDICT: OK — cerul creste de la %d azimuturi la baza la %d la varf"
		% [first, last])
	get_tree().quit()
