extends Node
## PUNCTUL 1 din raportul de la volan: "baloanele plutesc IN INTERIORUL
## muntelui, si unele sunt dezumflate/turtite".
##
## Doua intrebari separate, si sonda le tine separate fiindca au reparatii
## diferite:
##
##   (a) DEGAJARE — panza intra in stanca? Se testeaza pe MASA panzei, nu pe
##       nod: din centrul fiecarei panze pornesc raze pe orizontala si in jos;
##       daca prima lovitura e mai aproape decat raza panzei, panza e in roca.
##       Casetele nu ajung (o caseta peste un balon contine si cer), deci se
##       masoara pe raza reala a mesh-ului.
##
##   (b) TURTIRE — cat de aplatizata e panza. `balloon_far` din brief (§5.4) e
##       piesa de MultiMesh sub 100 tri; daca formele turtite sunt ALTCEVA
##       (panze intregi scalate pe y), atunci reparatia nu e la piesa de
##       departe, ci la scara nodurilor.
##
##   godot --headless --path . res://tools/ProbeCappBaloaneDegajare.tscn -- --track=6

var root_ref: Node = null


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var t := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame

	var space := t.get_world_3d().direct_space_state
	root_ref = t
	var nodes: Array = []
	_collect(t, t, nodes)
	print("=== (a) DEGAJAREA PANZELOR FATA DE ROCA ===")
	print("%d panze de balon gasite" % nodes.size())
	var in_rock := 0
	for d in nodes:
		var mi: MeshInstance3D = d["mi"]
		var a := mi.get_aabb()
		var c: Vector3 = mi.global_transform * a.get_center()
		var sc := mi.global_transform.basis.get_scale()
		var raza: float = maxf(a.size.x * absf(sc.x), a.size.z * absf(sc.z)) * 0.5
		var worst := 1e9
		var dir_worst := ""
		# Razele pornesc din CENTRUL panzei, deci prima lovitura poate fi chiar
		# corpul balonului insusi (cosul e AnimatableBody3D, iar cablul si
		# peretii de rachita au colizoare). Asa a iesit prima masuratoare:
		# "0.08 m" pe toate baloanele ancorate, neschimbat dupa ce am mutat
		# nodul zece metri — semnul ca sonda masura obiectul, nu vecinatatea.
		# Se exclude tot ce apartine aceluiasi balon.
		var proprii: Array[RID] = []
		for body in _bodies(d["radacina"]):
			proprii.append(body.get_rid())
		# Si TARUSUL PERECHE. Cablul de ancorare e un nod FRATE (`Tarus N`), pus
		# la exact aceleasi coordonate ca balonul, fiindca prin constructie
		# cablul urca pe axa balonului. Deci raza pornita din centrul panzei il
		# loveste la 8 cm si sonda anunta "balon in stanca, patrunde 4.57 m".
		#
		# Asta e chiar cazul care a rasturnat punctul 1 din raport: dupa ce am
		# mutat balonul 10 m, cifra a ramas IDENTICA LA ZECIMALA — semnul ca nu
		# masuram vecinatatea, ci un obiect care se muta odata cu el. Balonul nu
		# era in roca deloc.
		for sib in _pereche(d["radacina"]):
			proprii.append(sib.get_rid())
		for dd in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK,
				Vector3.DOWN]:
			var q := PhysicsRayQueryParameters3D.create(c, c + dd * (raza + 40.0))
			q.collide_with_areas = false
			q.exclude = proprii
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				continue
			var dist: float = (Vector3(hit["position"]) - c).length()
			if dist < worst:
				worst = dist
				var col := hit["collider"] as Node
				dir_worst = "%s [%s]" % [str(dd),
					(String(root_ref.get_path_to(col)) if col != null else "?")]
		# O panza CULCATA (balloon_landed: 20.7 x 0.5 m) intalneste versantul la
		# cativa metri pe orizontala si asta e CORECT — o foaie intinsa pe o
		# coasta atinge coasta. Prima versiune a sondei le numara pe toate zece
		# ca "in roca" cu 7 m patrundere, adica raporta ca defect chiar asezarea
		# ceruta de brief. Deci degajarea se cere doar de la panzele care au
		# VOLUM pe verticala; cele culcate se judeca la (b), nu aici.
		var hh0: float = a.size.y * absf(sc.y)
		var ww0: float = maxf(a.size.x * absf(sc.x), a.size.z * absf(sc.z))
		if hh0 / maxf(ww0, 0.001) < 0.85:
			continue
		var gol: float = worst - raza
		if worst < 1e8 and gol < 0.0:
			in_rock += 1
			print("  IN ROCA  %-34s raza %5.2f | prima lovitura %5.2f %s | patrunde %.2f m | centru (%.1f, %.1f, %.1f)"
				% [d["path"], raza, worst, dir_worst, -gol, c.x, c.y, c.z])
	print("  -> %d din %d panze intra in geometrie solida" % [in_rock, nodes.size()])

	print("=== (b) CAT DE TURTITE SUNT PANZELE ===")
	print("  (raport inaltime/latime; o panza de balon e mai INALTA decat lata)")
	var flat := 0
	for d in nodes:
		var mi: MeshInstance3D = d["mi"]
		var a := mi.get_aabb()
		var sc := mi.global_transform.basis.get_scale()
		var hh: float = a.size.y * absf(sc.y)
		var ww: float = maxf(a.size.x * absf(sc.x), a.size.z * absf(sc.z))
		var rap: float = hh / maxf(ww, 0.001)
		if rap < 0.85:
			flat += 1
			print("  TURTITA  %-34s %.1f x %.1f m (raport %.2f)"
				% [d["path"], ww, hh, rap])
	print("  -> %d din %d panze au raportul sub 0.85" % [flat, nodes.size()])
	get_tree().quit(0)


func _collect(node: Node, root: Node, out: Array) -> void:
	var nm := String(node.name).to_lower()
	if (nm.contains("balon") or nm.contains("balloon") or nm.contains("departe")) \
			and not nm.contains("basket") and not nm.contains("cos") \
			and not nm.contains("tarus") and not nm.contains("fabric"):
		for mi in _meshes(node):
			out.append({"path": String(root.get_path_to(node)), "mi": mi,
				"radacina": node})
		if not out.is_empty():
			pass
	for c in node.get_children():
		_collect(c, root, out)


## Corpurile tarusului asezat la aceleasi coordonate ca balonul (sub 1 m).
func _pereche(node: Node) -> Array[CollisionObject3D]:
	var out: Array[CollisionObject3D] = []
	var par := node.get_parent()
	if par == null or not (node is Node3D):
		return out
	var here := (node as Node3D).global_position
	for sib in par.get_children():
		if sib == node or not (sib is Node3D):
			continue
		if (sib as Node3D).global_position.distance_to(here) <= 1.0:
			out.append_array(_bodies(sib))
	return out


func _bodies(node: Node) -> Array[CollisionObject3D]:
	var out: Array[CollisionObject3D] = []
	var st: Array[Node] = [node]
	while not st.is_empty():
		var n: Node = st.pop_back()
		if n is CollisionObject3D:
			out.append(n as CollisionObject3D)
		for c in n.get_children(): st.append(c)
	return out


func _meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var st: Array[Node] = [node]
	while not st.is_empty():
		var n: Node = st.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree():
			out.append(n as MeshInstance3D)
		for c in n.get_children(): st.append(c)
	return out
