extends Node
## CAT de lata e fasia de TEREN care ramane vizibila intre marginea asfaltului si
## talpa peretelui. Aia e "umarul de iarba" din verdict: peretele chiar sta la
## 1,1-2,1 m de margine (masurat cu SvMpBApropiere), dar talpa lui e INGROPATA
## la -1,4..-2,1 m sub ax, deci intre asfalt si prima materie de piatra VIZIBILA
## ramane o felie de teren inierbat.
##
## Masoara, pe fiecare fractie: de la marginea asfaltului spre stanga, pe cati
## metri raza verticala in jos loveste TerrainBody inainte sa intre in gabaritul
## peretelui (primul x la care raza verticala urca peste cota drumului).
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _sus := 0.0

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus = hi + 250.0
	var n := _track.baked.size()
	# vertecsii peretelui, pentru testul de gabarit
	var cf := _find(_track, "CliffFaces")
	var pts := PackedVector3Array()
	for m in cf.get_children():
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		var arr: Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)
		for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			pts.append(mi.global_transform * v)
	print("=== FASIA DE TEREN intre asfalt si talpa peretelui (stanga) ===")
	print("frac  semi | teren vizibil pe stanga pana la peretele de piatra")
	print("           | (metri de la marginea asfaltului; sub 0,5 m = zero umar)")
	for f in range(48, 205, 4):
		var frac := float(f) / 1000.0
		var idx := int(round(frac * float(n))) % n
		var bp: Vector3 = _track.baked[idx]
		var fw: Vector3 = (_track.baked[(idx + 1) % n] - bp); fw.y = 0.0
		fw = fw.normalized()
		var lt := fw.cross(Vector3.UP).normalized()
		var w := _track.width_at_index(idx)
		# primul offset la care exista un vertex de perete PESTE cota drumului
		var first := -1.0
		var d := 0.0
		while d <= 14.0:
			var found := false
			for p in pts:
				var rel := p - bp
				if absf(rel.dot(fw)) > 3.0: continue
				var lat: float = -rel.dot(lt) - w   # spre stanga
				if absf(lat - d) < 0.6 and rel.y > 0.3:
					found = true; break
			if found:
				first = d; break
			d += 0.25
		print("%.3f %5.2f | %s" % [frac, w, ("  peste 14 m" if first < 0.0 else "%6.2f m" % [first])])
	get_tree().quit(0)

func _find(nod: Node, nm: String) -> Node:
	if nod.name == nm: return nod
	for c in nod.get_children():
		var r := _find(c, nm)
		if r != null: return r
	return null
