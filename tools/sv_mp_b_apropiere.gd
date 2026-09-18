extends Node
## Cat de aproape de asfalt ajunge peretele, masurat ca DISTANTA MINIMA de la
## fiecare vertex la banda, nu prin bucketing pe fractie.
##
## Bucketing-ul precedent asocia fiecare vertex celui mai apropiat punct de
## traseu; pe capetele stinse (unde `cut_tuck_m` retrage talpa cu 12 m) asta
## amesteca coloane de capat in feliile din mijloc si scoate o cifra falsa.
## Aici: pentru fiecare FELIE de drum, minimul lateral peste vertecsii care
## cad in felia aia pe DIRECTIA DE MERS (reziduu sub 2 m), nu peste cei mai
## apropiati euclidian.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var n := _track.baked.size()
	var cf := _find(_track, "CliffFaces")
	var pts: PackedVector3Array = PackedVector3Array()
	for m in cf.get_children():
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		var arr: Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)
		for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			pts.append(mi.global_transform * v)
	print("vertecsi de perete: ", pts.size())
	print("")
	print("Pentru fiecare fractie: cel mai apropiat vertex de perete de MARGINEA")
	print("asfaltului, luat doar dintre cei care cad in felia longitudinala (+-4 m).")
	print("")
	print("frac   semi | cel mai aproape perete | cota lui fata de ax | vertecsi in felie")
	for f in range(40, 212, 4):
		var frac := float(f) / 1000.0
		var idx := int(round(frac * float(n))) % n
		var bp: Vector3 = _track.baked[idx]
		var fw: Vector3 = (_track.baked[(idx + 1) % n] - bp); fw.y = 0.0
		fw = fw.normalized()
		var lt := fw.cross(Vector3.UP).normalized()
		var w := _track.width_at_index(idx)
		var best := 1e9; var besty := 0.0; var cnt := 0
		# A doua masuratoare, cea care conteaza pentru OCHIul soferului: dintre
		# vertecsii aflati PESTE cota drumului (deci care fac silueta, nu talpa
		# ingropata), cel mai apropiat lateral; plus cota lui maxima si UNGHIUL
		# sub care se vede de la ochiul din masina (ax + 1,6 m).
		#
		# Talpa peretelui sta la -1,5..-2,1 m sub ax: e sub asfalt, deci n-o vede
		# nimeni. Ce citeste camera e prima materie de DEASUPRA liniei ochiului.
		var best_sus := 1e9; var y_sus := 0.0
		var top_y := -1e9; var top_d := 0.0
		for p in pts:
			var rel := p - bp
			if absf(rel.dot(fw)) > 4.0: continue
			cnt += 1
			var d: float = absf(rel.dot(lt)) - w
			if d < best:
				best = d; besty = p.y - bp.y
			if p.y - bp.y > 1.6 and d < best_sus:
				best_sus = d; y_sus = p.y - bp.y
			if p.y - bp.y > top_y:
				top_y = p.y - bp.y; top_d = d
		if cnt == 0:
			print("%.3f %5.2f | (niciun vertex in felie)" % [frac, w])
		else:
			var unghi := 0.0
			if top_y > 1.6 and top_d > 0.01:
				unghi = rad_to_deg(atan2(top_y - 1.6, top_d))
			print("%.3f %5.2f | talpa %+6.2f m (y%+5.1f) | peste ochi: %s | coama y%+6.1f la %+6.2f m => %4.1f grade" % [frac, w, best, besty, ("%+6.2f m (y%+5.1f)" % [best_sus, y_sus]) if best_sus < 1e8 else "  NIMIC PESTE OCHI ", top_y, top_d, unghi])
	get_tree().quit(0)

func _find(nod: Node, nm: String) -> Node:
	if nod.name == nm: return nod
	for c in nod.get_children():
		var r := _find(c, nm)
		if r != null: return r
	return null
