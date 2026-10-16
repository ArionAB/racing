## Cat de aproape de AX ajunge fiecare piesa de decor, masurat pe AABB-ul ei
## real din scena (nu pe raza nominala a mesh-ului).
##
## De ce: turnurile sunt asezate "la 30-38 m lateral", dar aia e distanta
## pana la ORIGINE. Un turn scalat 2,95x are ~16 m raza, deci marginea lui
## ajunge la ~14 m de ax, pe o pista cu semi-latime 7 m. ProbeRace nu-l vede
## (masina trece pe sub consola), dar in cadru turnul atarna peste asfalt.
##
##   godot --headless --path . res://tools/SvHalongGabarit.tscn
extends Node
const PREFIXE := ["TurnCalcar", "Veg", "Dig", "Parapet", "CasaPlutitoare",
	"TarcPeste", "BarcaMica", "PavilionBelvedere", "RastelPlase"]
## `Insulita` NU intra: insulitele fixe de sub ponton sunt PRIN DEFINITIE pe
## traseu — ele poarta capetele tablierului. Contractul lor e pragul vertical
## (< 0,3 m), verificat de `ProbePonton`, nu departarea laterala.
## Semi-latimea pistei + o margine de umar. Sub atat, piesa e peste drum.
## Semi-latimea pistei e 7,0 m. Pragul e 8,0: un metru de umar, cat sa nu
## atarne nimic peste asfalt. Peste atat, piesele de margine (parapet, dig)
## chiar trebuie sa fie aproape — ele MARGINESC drumul.
const LIBER_M := 8.0
## Distanta orizontala pana la axul soselei.
##
## `TrackSideSampler` NU expune `distance_to_road` — prima versiune a sondei
## o chema prin `has_method` si cadea pe INF, deci TOATE piesele treceau si
## verdictul iesea "0 peste gabarit" din prima, pe o pista cu turnuri vizibil
## peste asfalt. O cifra perfecta din prima inseamna sonda goala, nu succes
## (memoria `multimesh-masuratoare-moarta`). Se calculeaza aici din punctele
## coapte ale traseului, care SUNT expuse.
func _dist_la_ax(sampler, wx: float, wz: float) -> float:
	# Cautare in DOUA TRECERI: intai din 16 in 16 puncte, apoi fin in jurul
	# celui mai bun. Trecerea completa pe toate punctele, pentru 120 de piese
	# x 4 colturi, depasea 10 minute.
	var n: int = sampler.point_count()
	if n == 0:
		return INF
	var best := INF
	var bi := 0
	var i := 0
	while i < n:
		var p: Vector3 = sampler.baked_point(i)
		var d := Vector2(wx - p.x, wz - p.z).length_squared()
		if d < best:
			best = d
			bi = i
		i += 16
	for j in range(maxi(0, bi - 20), mini(n, bi + 21)):
		var p2: Vector3 = sampler.baked_point(j)
		best = minf(best, Vector2(wx - p2.x, wz - p2.z).length_squared())
	return sqrt(best)


func _ready() -> void:
	var scene := load("res://scenes/tracks/Track22.tscn") as PackedScene
	var track := scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var sampler = track.get("_sampler")
	var dec := track.get_node_or_null("DecorManual")
	if dec == null or sampler == null:
		print("!! fara DecorManual/_sampler"); get_tree().quit(1); return
	var rele := 0
	var total := 0
	print("%-20s %8s %8s  %s" % ["nod", "origine", "margine", "stare"])
	for ch in dec.get_children():
		var nm := String(ch.name)
		if nm.ends_with("_col"):
			continue
		var ok := false
		for pre in PREFIXE:
			if nm.begins_with(pre):
				ok = true
				break
		if not ok:
			continue
		var n3 := ch as Node3D
		if n3 == null:
			continue
		# AABB-ul real, in coordonate de lume
		var aabb := AABB()
		var first := true
		var stack: Array[Node] = [n3]
		while not stack.is_empty():
			var q: Node = stack.pop_back()
			for c in q.get_children():
				stack.append(c)
			var mi := q as MeshInstance3D
			if mi != null and mi.mesh != null:
				var a := mi.global_transform * mi.mesh.get_aabb()
				if first:
					aabb = a
					first = false
				else:
					aabb = aabb.merge(a)
		if first:
			continue
		total += 1
		# distanta de la ax: cea mai mica dintre cele 4 colturi orizontale
		var best := INF
		for sx in [aabb.position.x, aabb.position.x + aabb.size.x]:
			for sz in [aabb.position.z, aabb.position.z + aabb.size.z]:
				best = minf(best, _dist_la_ax(sampler, sx, sz))
		var org: float = _dist_la_ax(sampler, n3.global_position.x, n3.global_position.z)
		var stare := "OK"
		if best < LIBER_M:
			stare = "PESTE DRUM (%.1f m de ax)" % best
			rele += 1
		print("%-20s %8.1f %8.1f  %s" % [nm, org, best, stare])
	print("")
	print("=== %d piese, %d peste gabarit (prag %.0f m) ===" % [total, rele, LIBER_M])
	print("VERDICT: %s" % ("OK" if rele == 0 else "DE REPARAT"))
	get_tree().quit(0)