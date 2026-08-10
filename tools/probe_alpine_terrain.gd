extends Node
## Sonda TEMPORARA: cat de sus urca TERENUL Alpilor si cat din el prinde zapada.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAlpineTerrain.tscn
##
## Ca SCENA, nu cu --script: terenul se construieste in _ready, iar lantul are
## nevoie de autoload-uri (vezi antetul probe_layout.gd).
##
## Linia zapezii se alege fata de cota terenului, nu fata de cea a drumului:
## `_peak_specs` declara varfuri de 98-102, dar peste profilul de dom se aduna
## zgomotul de dune SI masca de protectie a asfaltului, deci cota REALA atinsa
## se masoara, nu se citeste din declaratie.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track09.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	# Cotele se citesc din MESH-ul de teren deja construit, nu din sampler:
	# `_sampler` e privat si invizibil prin get() in modul --script. Mesh-ul e
	# oricum adevarul final — el e ce vede jucatorul.
	var hist := {}
	var y_max := -INF
	var y_max_at := Vector2.ZERO
	var above := {}
	for line in [70.0, 75.0, 78.0, 82.0, 86.0, 90.0]:
		above[line] = 0
	var total := 0
	for m in _terrain_meshes(track):
		var arrays := m.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			var y := v.y
			total += 1
			if y > y_max:
				y_max = y
				y_max_at = Vector2(v.x, v.z)
			for line in above:
				if y >= line:
					above[line] += 1
			var bucket := int(floorf(y / 10.0)) * 10
			hist[bucket] = int(hist.get(bucket, 0)) + 1
	if total == 0:
		print("niciun mesh de teren gasit")
		get_tree().quit(1)
		return
	print("")
	print("=== Terenul Alpilor (%d varfuri de grila) ===" % total)
	print("cota maxima a TERENULUI: %.1f m la (%.0f, %.0f)" % [
		y_max, y_max_at.x, y_max_at.y])
	var road_max := -INF
	for p in track.baked:
		road_max = maxf(road_max, p.y)
	print("cota maxima a SOSELEI:   %.1f m" % road_max)
	print("")
	print("cat teren sta peste o linie de zapada candidata:")
	var lines := above.keys()
	lines.sort()
	for line in lines:
		var pct := 100.0 * float(above[line]) / float(total)
		print("  %5.1f m -> %5.2f%% din suprafata (%d esantioane)" % [
			line, pct, above[line]])
	print("")
	print("histograma de cote (pas 10 m):")
	var keys := hist.keys()
	keys.sort()
	for k in keys:
		if int(hist[k]) < 3:
			continue
		print("  %4d..%4d m %s %d" % [k, k + 10,
			"#".repeat(int(hist[k]) * 40 / total), hist[k]])
	track.queue_free()
	get_tree().quit(0)


## Mesh-urile de teren: cele mai mari suprafete din scena, fara coliziune
## proprie. Le recunosc dupa numarul de varfuri — grila are mii, un prop are
## zeci.
func _terrain_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null and mi.mesh.get_surface_count() > 0:
			var arr := mi.mesh.surface_get_arrays(0)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if vs.size() > 1500:
				out.append(mi)
	for c in n.get_children():
		out.append_array(_terrain_meshes(c))
	return out
