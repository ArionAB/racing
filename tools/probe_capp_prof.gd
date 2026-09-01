extends Node
## Profilul de raza al hornurilor, MASURAT PE MESH, nu pe pixeli.
##
## Sonda de silueta (skyline_cones.py) vede rezultatul final si e arbitrul, dar
## nu poate spune UNDE in cod se naste curbura. Asta citeste raza pe cote din
## mesh-ul construit, deci arata daca profilul e drept in geometrie inainte sa
## intre camera, ceata si suprapunerile in discutie.
##
## Raporteaza aceleasi cifre ca sonda de pixeli (raport la baza, a doua
## diferenta, suma|d2|) ca sa fie comparabile direct.

const N := 9


func _ready() -> void:
	# add_child imediat in _ready cade cu "parent is busy setting up children",
	# si atunci sonda masura un arbore vechi si raporta cifre identice inainte
	# si dupa schimbare. Se asteapta un cadru INAINTE de instantiere.
	await get_tree().process_frame
	var scn: PackedScene = load("res://scenes/tracks/Track13.tscn")
	var track: Node = scn.instantiate()
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var found: Array = []
	_collect(track, found)
	print("hornuri gasite: %d" % found.size())
	print("")
	for node in found:
		_report(node)
	get_tree().quit()


func _collect(n: Node, out: Array) -> void:
	if n.get_script() != null:
		var p: String = n.get_script().resource_path
		if p.ends_with("chimney_shape.gd"):
			out.append(n)
	for c in n.get_children():
		_collect(c, out)


func _report(n: Node) -> void:
	var mi: MeshInstance3D = null
	for c in n.get_children():
		if c is MeshInstance3D:
			mi = c
			break
	if mi == null or mi.mesh == null:
		return
	var aabb: AABB = mi.mesh.get_aabb()
	var y0 := aabb.position.y
	var h := aabb.size.y
	if h <= 0.01:
		return
	# Centrul axei: media pe XZ a vertecsilor din treimea de jos.
	var rmax := PackedFloat32Array()
	rmax.resize(N)
	rmax.fill(0.0)
	var cx := aabb.position.x + aabb.size.x * 0.5
	var cz := aabb.position.z + aabb.size.z * 0.5
	for s in mi.mesh.get_surface_count():
		var arrays: Array = mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			var t := clampf((v.y - y0) / h, 0.0, 0.9999)
			var k := int(t * float(N))
			k = clampi(k, 0, N - 1)
			var r := Vector2(v.x - cx, v.z - cz).length()
			if r > rmax[k]:
				rmax[k] = r
	# Felii goale: hornurile cu terase au taieturi unde nu cade niciun vertex in
	# cosul de cota. Un zero acolo nu inseamna raza zero, inseamna "nu stiu" —
	# se interpoleaza intre vecinii plini, altfel a doua diferenta masoara
	# gaurile sondei, nu forma hornului.
	for k in N:
		if rmax[k] > 0.0001:
			continue
		var lo := k - 1
		while lo >= 0 and rmax[lo] <= 0.0001:
			lo -= 1
		var hi := k + 1
		while hi < N and rmax[hi] <= 0.0001:
			hi += 1
		if lo < 0 and hi >= N:
			continue
		elif lo < 0:
			rmax[k] = rmax[hi]
		elif hi >= N:
			rmax[k] = rmax[lo]
		else:
			var f := float(k - lo) / float(hi - lo)
			rmax[k] = lerpf(rmax[lo], rmax[hi], f)
	var base := rmax[0]
	if base <= 0.0001:
		return
	var rat := PackedFloat32Array()
	for k in N:
		rat.append(rmax[N - 1 - k] / base)
	var d2 := PackedFloat32Array()
	var sum := 0.0
	var mx := -9.0
	for i in range(1, N - 1):
		var v := rat[i + 1] - 2.0 * rat[i] + rat[i - 1]
		d2.append(v)
		sum += absf(v)
		mx = maxf(mx, v)
	var line := ""
	for k in N:
		line += "%.2f " % rat[k]
	print("%-22s h=%5.1f  %s  d2max %+.3f  suma|d2| %.3f"
			% [n.name, h, line, mx, sum])
