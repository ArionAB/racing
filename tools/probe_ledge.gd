extends Node
## Cat de mult iese CU ADEVARAT o treapta din fata peretelui, masurat pe scena
## incarcata, nu pe intentia din generator.
##
## Captura de dupa runda 3 pas 1 arata peretele neschimbat, desi s-au scris 184
## de cutii. Doua explicatii posibile si trebuie separate prin masuratoare, nu
## prin ochi: (a) cutiile sunt INGROPATE — cota lor `z` le pune in interiorul
## modulului, deci nu ies nicaieri; (b) ies, dar prea putin.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var base := track.get_node_or_null("DecorManual/D) Canionul rosu")
	if base == null:
		print("LIPSA base"); get_tree().quit(1); return
	var strate := base.get_node_or_null("Strate")
	var faleza := base.get_node_or_null("Faleza")
	print("Strate=", strate.get_child_count(), " Faleza=", faleza.get_child_count())
	# Pentru primele 8 trepte: distanta de la fata treptei pana la cel mai
	# apropiat vertex de modul, pe directia normalei treptei.
	var mods: Array = []
	for m in faleza.get_children():
		mods.append(m)
	var n := 0
	for t in strate.get_children():
		if n >= 8: break
		var mi := t as MeshInstance3D
		if mi == null: continue
		var xf := mi.global_transform
		var aabb := mi.mesh.get_aabb()
		# cele 8 colturi in lume
		var zmin := 1e9
		var zmax := -1e9
		var pts: Array = []
		for i in 8:
			var c := aabb.get_endpoint(i)
			pts.append(xf * c)
		# Normala treptei = coloana Z a basisului, normalizata
		var nrm := xf.basis.z.normalized()
		var ctr := xf.origin
		# Cel mai iesit punct al treptei pe normala
		var out_t := -1e9
		for p in pts:
			out_t = maxf(out_t, (p - ctr).dot(nrm))
		# Cel mai iesit punct al MODULULUI vecin pe aceeasi normala
		var best := 1e9
		var out_m := -1e9
		for m in mods:
			var d: float = (m.global_transform.origin - ctr).length()
			if d < best:
				best = d
				out_m = -1e9
				for mi2 in m.find_children("*", "MeshInstance3D", true, false):
					var mm := (mi2 as MeshInstance3D).mesh
					if mm == null: continue
					var x2 := (mi2 as MeshInstance3D).global_transform
					var ab := mm.get_aabb()
					for i in 8:
						var wp: Vector3 = x2 * ab.get_endpoint(i)
						out_m = maxf(out_m, (wp - ctr).dot(nrm))
		print("%s  iese_treapta %6.2f  iese_modul %6.2f  DELTA %6.2f  (modul la %.1f m)"
			% [mi.name, out_t, out_m, out_t - out_m, best])
		n += 1
	get_tree().quit(0)
