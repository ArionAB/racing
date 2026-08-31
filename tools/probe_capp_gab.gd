extends SceneTree
## Gabaritul in METRI si costul in triunghiuri al GLB-urilor, la scara 1.
##
## De ce exista: `cracked_chimney_a` a fost folosit pentru "pietre de margine" la
## scara 0.45..1.40, pe premisa ca "cracked" inseamna ciot. A iesit un coridor de
## coloane de 7..23 m. GLB-ul are 16.84 m INALTIME. Aceeasi clasa de eroare ca in
## memoria `slot-ales-dupa-nume`: numele nu descrie geometria, si singura cale de
## a sti e s-o masori.
##
## Triunghiurile sunt in acelasi tabel intentionat: regula rundei 12 (o aschie de
## 20 cm nu instantiaza un mesh de 2530 tri) si alegerea scarii sunt aceeasi
## decizie, si se iau uitandu-te la aceleasi doua coloane.
func _initialize() -> void:
	for f in ["rocks/cracked_chimney_a","rocks/cracked_chimney_b","rocks/cracked_chimney_c",
			"plants/shrub_dry","plants/poplar_a","plants/vine_row","rocks/chimney_a"]:
		var ps: PackedScene = load("res://assets/models/cappadocia/%s.glb" % f)
		var nd: Node = ps.instantiate()
		var ab := AABB()
		var first := true
		var tris := 0
		var st: Array[Node] = [nd]
		while not st.is_empty():
			var x: Node = st.pop_back()
			for c in x.get_children(): st.append(c)
			var mi := x as MeshInstance3D
			if mi == null or mi.mesh == null: continue
			var a := mi.mesh.get_aabb()
			if first:
				ab = a
				first = false
			else:
				ab = ab.merge(a)
			for sf in mi.mesh.get_surface_count():
				tris += mi.mesh.surface_get_arrays(sf)[Mesh.ARRAY_VERTEX].size() / 3
		print("%-28s  %5.2f x %5.2f x %5.2f m   %5d tris" % [
			f, ab.size.x, ab.size.y, ab.size.z, tris])
	quit()
