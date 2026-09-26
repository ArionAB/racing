extends SceneTree
## VERIFICA AMPRENTA pieselor din DecorManual/<zona> fata de marginea
## carosabilului -- pentru piese cu coliziune "none" (fantoma, memoria
## coliziune-none-e-fantoma-nu-stearsa), sondele pe raycast/intersect_shape
## nu le vad deloc, deci verdictul trebuie dat pe MESH AABB, cu rotatia si
## scara REALE ale nodului (bbox proiectat pe axa laterala a pistei, nu pe
## centrul piesei).
##
## Regula (coordonator, runda 4 POI F Fiordland):
##   - piese cu inaltime >= 0.3 m: amprenta STRICT in afara carosabilului
##     (nicio intrare, adica intrarea trebuie sa fie <= 0)
##   - piese cu inaltime < 0.3 m: max 1.5 m de intrare fata de marginea
##     carosabilului (half_width la fractia lor)
##   - EXCEPTIE explicita (brief-ul POI F): trunchiurile cazute (`driftwood`)
##     au radacina pe acostament si varful poate ajunge pana la 1,5 m peste
##     margine, desi inaltimea lor (0,384 m la scara 1, mai mult la scara
##     variata din _scar_pileup) trece pragul de 0,3 m -- un trunchi culcat e
##     jos, nu un zid, chiar daca AABB-ul lui (inainte de scalare pe lungime)
##     "citeste" inalt in test.
##
##   godot --headless --path . --script res://tools/probe_pileup_footprint.gd -- \
##       --track=16 --zone=DecorManual/ZoneF_Coborare

const HEIGHT_THRESHOLD := 0.3
const MAX_OVER_SMALL := 1.5
## Stem-uri cu exceptia de trunchi cazut (max 1,5 m peste margine chiar daca
## AABB-ul trece pragul de inaltime).
const FALLEN_TRUNK_STEMS := ["driftwood"]

var _frames := 0
var _track: Node3D = null
var _zone_path := "DecorManual/ZoneF_Coborare"
var _track_idx := 16


func _process(_delta: float) -> bool:
	if _track == null:
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--track="):
				_track_idx = int(a.trim_prefix("--track="))
			elif a.begins_with("--zone="):
				_zone_path = a.trim_prefix("--zone=")
		var path := "res://scenes/tracks/Track%02d.tscn" % _track_idx
		if not ResourceLoader.exists(path):
			push_error("probe_pileup_footprint: nu exista %s" % path)
			quit(1)
			return true
		print("=== %s :: %s ===" % [path, _zone_path])
		_track = (load(path) as PackedScene).instantiate()
		root.add_child(_track)
		return false
	_frames += 1
	if _frames < 3:
		return false
	quit(0 if _report() else 1)
	return true


## Piesele "trunk" (copaci) au corpul de coliziune REAL doar pe trunchi, nu pe
## coroana -- world_prop.gd (`trunk` = cilindru subtire in ax). Un fag cu
## coroana de 9 m citeste "in drum" pe AABB brut desi masina trece prin
## coroana fara sa loveasca nimic; asta ar falsifica verdictul cu zeci de
## fagi din padurea rara din jurul cicatricei (`_forest()`), care nu sunt
## piesele reparate aici. Pentru "trunk" folosim raza de baza (masurata,
## acelasi BASE_R din gen_decor_fiord_f.gd) in loc de AABB-ul coroanei.
const TRUNK_STEMS := ["beech_a", "beech_b", "beech_c", "beech_dead"]
const TRUNK_BASE_R := {
	"beech_a": 0.81, "beech_b": 0.77, "beech_c": 1.03, "beech_dead": 0.68,
}
## Inaltimea REALA (nu 0) a copacilor -- toti peste pragul de 0,3 m, deci
## trebuie sa stea STRICT in afara carosabilului (BASE_R e raza trunchiului,
## nu o piesa mica).
const TRUNK_HEIGHT := {
	"beech_a": 7.030, "beech_b": 10.189, "beech_c": 13.501, "beech_dead": 8.515,
}

## Numele de fisier .glb (stem) al instantei -- din scene_file_path, ca in
## probe_manual.gd (_effective_collision_mode).
func _stem_of(n3: Node3D) -> String:
	return n3.scene_file_path.get_file().get_basename()


## Amprenta REALA a nodului in spatiu GLOBAL, cu rotatia+scara ale nodului
## (nu ale mesh-ului copil, care e local identic pentru toate instantele):
## pentru piese "hull" (bolovani, trunchiuri) foloseste AABB-ul mesh-ului
## transformat prin global_transform -- pentru piese "trunk" (copaci)
## foloseste un cilindru cu raza de baza masurata, fiindca asta e coliziunea
## REALA cu care se joaca (coroana e strabatuta).
func _global_footprint(n3: Node3D) -> Dictionary:
	var stem := _stem_of(n3)
	if TRUNK_STEMS.has(stem):
		var r: float = TRUNK_BASE_R.get(stem, 1.0) * n3.scale.x
		var c := n3.global_position
		var pts: Array[Vector3] = []
		for ang in [0.0, PI * 0.5, PI, PI * 1.5]:
			pts.append(c + Vector3(cos(ang), 0.0, sin(ang)) * r)
		var h: float = TRUNK_HEIGHT.get(stem, 10.0)
		return {"points": pts, "height": h, "trunk": true}
	var mesh := _find_mesh(n3)
	if mesh == null:
		return {}
	var aabb: AABB = mesh.get_aabb()
	var xf: Transform3D = mesh.global_transform
	var min_y := INF
	var max_y := -INF
	var pts: Array[Vector3] = []
	for dx in [0.0, aabb.size.x]:
		for dy in [0.0, aabb.size.y]:
			for dz in [0.0, aabb.size.z]:
				var local := aabb.position + Vector3(dx, dy, dz)
				var g := xf * local
				pts.append(g)
				min_y = minf(min_y, g.y)
				max_y = maxf(max_y, g.y)
	return {"points": pts, "min_y": min_y, "max_y": max_y, "height": max_y - min_y, "trunk": false}


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for c in node.get_children():
		var r := _find_mesh(c)
		if r != null:
			return r
	return null


func _report() -> bool:
	var t: Node3D = _track
	var zone: Node3D = t.get_node_or_null(_zone_path)
	if zone == null:
		push_error("probe_pileup_footprint: zona %s nu exista" % _zone_path)
		return false
	var baked: PackedVector3Array = t.baked
	var bad := 0
	var checked := 0
	print("%-24s %7s %9s %9s   %s" % ["nod", "h(m)", "half(m)", "intra(m)", "verdict"])
	for c in zone.get_children():
		var n3 := c as Node3D
		if n3 == null:
			continue
		var fp := _global_footprint(n3)
		if fp.is_empty():
			continue
		checked += 1
		var pts: Array[Vector3] = fp["points"]
		var height: float = fp["height"]
		# cel mai apropiat punct pe axa pistei, dupa centrul piesei (suficient
		# de precis pe o zona locala; half_width variaza lent fata de amprenta
		# unei piese de cativa metri).
		var center := n3.global_position
		var near_i := 0
		var near_d := 1e9
		for i in baked.size():
			var d := Vector2(center.x - baked[i].x, center.z - baked[i].z).length_squared()
			if d < near_d:
				near_d = d
				near_i = i
		var frac: float = t.frac_at(near_i)
		var half: float = t.width_at(frac)
		var p: Vector3 = baked[near_i]
		var fwd := (baked[(near_i + 1) % baked.size()] - p)
		if fwd.length() < 0.001:
			fwd = Vector3.FORWARD
		fwd = fwd.normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		# proiecteaza toate cele 8 colturi pe axa laterala (fata de axul
		# pistei la punctul cel mai apropiat) si ia extremul cel mai APROAPE
		# de ax -- acela decide cat de mult intra amprenta pe carosabil.
		var min_abs_lat := INF
		for pt in pts:
			var rel := pt - p
			var lat := rel.dot(side)
			min_abs_lat = minf(min_abs_lat, absf(lat))
		var over: float = half - min_abs_lat # >0 inseamna ca amprenta intra pe asfalt
		var stem := _stem_of(n3)
		var limit: float = MAX_OVER_SMALL if (height < HEIGHT_THRESHOLD
			or FALLEN_TRUNK_STEMS.has(stem)) else 0.0
		var verdict := "ok"
		if over > limit:
			verdict = "INTRA PESTE LIMITA"
			bad += 1
		print("%-24s %7.3f %9.2f %9.2f   %s" % [String(n3.name), height, half, over, verdict])
	print("")
	print("%d noduri verificate in %s" % [checked, _zone_path])
	if bad > 0:
		print("VERDICT: %d piese incalca regula (>=0.3m trebuie sa stea AFARA, <0.3m max 1.5m intrare)" % bad)
		return false
	print("VERDICT: OK -- nicio piesa nu incalca regula de amprenta pe carosabil")
	return true
