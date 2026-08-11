extends Node
## Sonda masivelor plasate vizual (TerrainPeak in TrackFromPath).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePeaks.tscn
##
## Ca SCENA, nu cu --script: pista se construieste in _ready si are nevoie de
## autoload-uri (vezi antetul probe_layout.gd).
##
## Construieste ACEEASI pista de doua ori — o data goala, o data cu un
## TerrainPeak in mijlocul buclei — si compara terenul si soseaua intre ele.
## Acelasi nume de pista = aceeasi samanta de lume, deci dunele sunt identice
## si orice diferenta vine numai din varf. Trei verdicte:
##
##   1. muntele EXISTA: terenul de langa centrul varfului urca semnificativ;
##   2. soseaua NU se misca: punctele coapte au exact aceleasi cote;
##   3. banda de protectie TINE: terenul de la marginea asfaltului (pana la
##      PEAK_ROAD_CLEAR dincolo de ea) ramane neschimbat — muntele nu trece
##      peste drum.

const PEAK_POS := Vector3(30.0, 25.0, -55.0)
const PEAK_RADIUS := 55.0
## Cat trebuie sa urce terenul la centru ca sa spunem ca muntele exista.
## Varful declarat e la 25 m, media soselei ~2 m; cerem macar jumatate din
## diferenta, ca sa nu pice pe zgomotul de dune (±5.5 m varf-la-varf).
const MIN_RISE: float = 10.0
## Toleranta pe banda protejata: masca e 0 acolo, deci diferenta reala e 0;
## lasam loc doar erorii de virgula mobila si esantionarii grilei.
const BAND_TOLERANCE: float = 0.2


func _ready() -> void:
	await get_tree().process_frame
	var plain := await _measure(false)
	var peaked := await _measure(true)
	var failed := false

	print("")
	print("=== Sonda TerrainPeak (varf %.0f m, raza %.0f m la %.0f,%.0f) ===" % [
		PEAK_POS.y, PEAK_RADIUS, PEAK_POS.x, PEAK_POS.z])

	var rise: float = peaked["center_max"] - plain["center_max"]
	print("teren la centru: %.1f -> %.1f m (crestere %.1f, prag %.1f)" % [
		plain["center_max"], peaked["center_max"], rise, MIN_RISE])
	if rise < MIN_RISE:
		print("  PROBLEMA: muntele nu s-a ridicat")
		failed = true

	var road_delta: float = _max_road_delta(plain["road"], peaked["road"])
	print("soseaua: diferenta maxima de cota %.3f m" % road_delta)
	if road_delta > 0.01:
		print("  PROBLEMA: varful a miscat soseaua")
		failed = true

	var band_delta: float = _max_band_delta(plain, peaked)
	print("banda de protectie (pana la %.0f m de asfalt): diferenta %.3f m" % [
		TrackSideSampler.PEAK_ROAD_CLEAR, band_delta])
	if band_delta > BAND_TOLERANCE:
		print("  PROBLEMA: muntele a trecut peste banda drumului")
		failed = true

	print("VERDICT: %s" % ("PROBLEMA" if failed else "OK"))
	get_tree().quit(1 if failed else 0)


## Construieste pista starter a lui TrackFromPath (cu sau fara varf) si intoarce
## masuratorile. Pistele se construiesc PE RAND, nu simultan: doua lumi intregi
## in acelasi arbore isi dubleaza degeaba decorul si mediul.
func _measure(with_peak: bool) -> Dictionary:
	var track := TrackFromPath.new()
	track.custom_name = "SondaVarf" # acelasi nume in ambele rulari = aceeasi lume
	if with_peak:
		var peak := TerrainPeak.new()
		peak.position = PEAK_POS
		peak.radius_m = PEAK_RADIUS
		track.add_child(peak)
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var road := PackedVector3Array()
	for p in track.baked:
		road.append(p)

	# Cotele se citesc din MESH-ul de teren construit, ca in probe_alpine_terrain:
	# el e adevarul final — de el se lovesc rotile.
	var center_max := -INF
	var band := {}
	for m in _terrain_meshes(track):
		var arrays := m.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			if Vector2(v.x - PEAK_POS.x, v.z - PEAK_POS.z).length() < 20.0:
				center_max = maxf(center_max, v.y)
			var d := _road_distance(road, v)
			if d < track.half_width + TrackSideSampler.PEAK_ROAD_CLEAR:
				# Cheie pe pozitia XZ cuantizata: grila e identica intre rulari,
				# deci acelasi varf de grila se regaseste exact.
				band[Vector2i(int(roundf(v.x * 10.0)), int(roundf(v.z * 10.0)))] = v.y

	track.queue_free()
	await get_tree().process_frame
	return {"road": road, "center_max": center_max, "band": band}


## Distanta XZ minima de la un punct la axa soselei (pe puncte coapte, cu pas:
## la ~3 m intre ele, eroarea fata de segmentul adevarat e sub 1.5 m — destul
## pentru o banda de verificare de 13 m).
func _road_distance(road: PackedVector3Array, v: Vector3) -> float:
	var best := INF
	var i := 0
	while i < road.size():
		var dx := road[i].x - v.x
		var dz := road[i].z - v.z
		best = minf(best, dx * dx + dz * dz)
		i += 2
	return sqrt(best)


func _max_road_delta(a: PackedVector3Array, b: PackedVector3Array) -> float:
	if a.size() != b.size():
		return INF
	var worst := 0.0
	for i in a.size():
		worst = maxf(worst, absf(a[i].y - b[i].y))
	return worst


func _max_band_delta(plain: Dictionary, peaked: Dictionary) -> float:
	var worst := 0.0
	var band_a: Dictionary = plain["band"]
	var band_b: Dictionary = peaked["band"]
	for key in band_a:
		if band_b.has(key):
			worst = maxf(worst, absf(float(band_a[key]) - float(band_b[key])))
	return worst


## Mesh-urile de teren, recunoscute dupa numarul de varfuri (grila are mii, un
## prop are zeci) — acelasi criteriu ca in probe_alpine_terrain.
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
