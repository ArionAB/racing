extends SceneTree
## ZIDUL ROSU: sunt mesele pe inelul lor, si unde trebuie mutate ca sa fie.
##
## Cele 12 mese au fost proiectate (commit 2b0a309) ca perete al Vaii Rosii pe
## "inelul 230-300 m", dupa ce o prima asezare la 170 m iesise, in cuvintele
## autorului, "lazi stivuite: prea aproape, prea inguste, prea inalte".
## Masurat pe ramura de arta: sunt la 0.2-50 m de traseu. De aia la frac 0.55
## soferul are o cutie neagra peste drum si un "tavan de placa" deasupra —
## POI E e fundul vaii in AER LIBER, acolo n-are ce sa fie tavan.
##
## Distanta se masoara fata de CEL MAI APROPIAT punct al traseului, la fel ca
## `horizon_rings` (190-290 m) si nu fata de centrul buclei: bucla are 400 m
## raza pe unele azimuturi, deci "265 m de centru" ar pune mesele in drum pe o
## parte si dincolo de ceata (fog_end 300) pe cealalta.
##
## Mutarea pastreaza azimutul fiecarei mese fata de centru — silueta si ordinea
## din cadru raman ale autorului, se schimba doar departarea.
const TINTA := 250.0   # in inelul 230-300, sub fog_end 300
const PRAG := 200.0    # sub atat e "lada stivuita"
## Cat intra baza in teren, ca sa nu se vada muchia de jos a lespezii.
const INGROP := 6.0

func _initialize() -> void:
	var track: Node = load("res://scenes/tracks/Track13.tscn").instantiate()
	root.add_child(track)
	await process_frame
	await process_frame
	var r = track.routes[0]
	var n: int = r.baked.size()
	var ctr := Vector2.ZERO
	for i in n: ctr += Vector2(r.baked[i].x, r.baked[i].z)
	ctr /= float(n)
	var grp := _find(track, "ZidulRosuDeDeparte")
	var bad := 0
	print("%-14s %8s  %s" % ["mesa", "d_min", "propunere"])
	for m in grp.get_children():
		var mi := m as Node3D
		var o: Vector3 = mi.global_transform.origin
		var d := _dist(mi, r, n)
		if d >= PRAG:
			print("%-14s %7.1fm  pe inel, nu se atinge" % [String(mi.name), d])
			continue
		bad += 1
		var az := (Vector2(o.x, o.z) - ctr)
		if az.length() < 0.1: az = Vector2(1, 0)
		az = az.normalized()
		# cauta pe azimut pana cand distanta pana la traseu ajunge la TINTA
		var step := 5.0
		var pos := Vector2(o.x, o.z)
		var guard := 0
		while _dmin(pos, r, n) < TINTA and guard < 400:
			pos += az * step
			guard += 1
		# COTA se citeste din TEREN, nu se pastreaza. Mutata pe orizontala cu
		# y-ul vechi, mesa a iesit plutind deasupra orizontului ("lazi in aer"),
		# fiindca la 250 m terenul e mult mai jos decat langa sosea. Baza intra
		# ingropata cu INGROP m, ca sa nu se vada muchia de jos.
		var gy: float = track.call("_terrain_mesh_y", pos.x, pos.y)
		print("%-14s %7.1fm  -> (%.3f, %.3f, %.3f)  d=%.1fm  teren_y=%.1f" % [
			String(mi.name), d, pos.x, gy - INGROP - _base_off(mi), pos.y, _dmin(pos, r, n), gy])
	print("\n%d din %d sub pragul de %.0f m" % [bad, grp.get_child_count(), PRAG])
	quit()

## Cat de jos coboara geometria mesei sub originea nodului ei.
func _base_off(node: Node3D) -> float:
	var lo := INF
	var st: Array[Node] = [node]
	while not st.is_empty():
		var x: Node = st.pop_back()
		for c in x.get_children(): st.append(c)
		var mi := x as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		var tf := mi.global_transform
		var ab: AABB = mi.mesh.get_aabb()
		for k in 8:
			lo = minf(lo, (tf * ab.get_endpoint(k)).y)
	return node.global_transform.origin.y - lo


func _dmin(p: Vector2, r, n: int) -> float:
	var mind := INF
	for i in n:
		mind = minf(mind, p.distance_to(Vector2(r.baked[i].x, r.baked[i].z)))
	return mind

func _dist(node: Node3D, r, n: int) -> float:
	var mind := INF
	var st: Array[Node] = [node]
	while not st.is_empty():
		var x: Node = st.pop_back()
		for c in x.get_children(): st.append(c)
		var mi := x as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		var tf := mi.global_transform
		for s in mi.mesh.get_surface_count():
			var vs: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for k in range(0, vs.size(), 7):
				var w: Vector3 = tf * vs[k]
				mind = minf(mind, _dmin(Vector2(w.x, w.z), r, n))
	return mind

func _find(nd: Node, nm: String) -> Node:
	if String(nd.name) == nm: return nd
	for c in nd.get_children():
		var r := _find(c, nm)
		if r != null: return r
	return null
