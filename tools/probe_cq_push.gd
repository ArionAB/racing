extends Node
## Unde trebuie mutata fiecare pila ca sa iasa din culoarul de mers?
##
## Pista trece PE DEASUPRA ei insasi in nodul F, deci "cel mai apropiat punct
## de pe ruta" in 2D minte: da etajul gresit. Pentru fiecare pila luam TOATE
## fractiile care trec pe langa ea in plan si pastram doar pe cea care are si
## cota potrivita — pila e sub tablier, deci ne intereseaza felia de ruta care
## trece PESTE varful ei, nu cea de dedesubt.
const CLEAR: float = 11.0
const PILLAR_R: float = 1.4    ## raza gabaritului pilei (scale ~1.3 pe GLB)

func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var decor := track.find_child("DecorManual", true, false)
	var out := {}
	for child in decor.find_children("pila*", "", true, false):
		var node := child as Node3D
		if node == null:
			continue
		var p: Vector3 = node.global_position
		# toate feliile care trec la mai putin de 20 m in plan
		var worst_lat := 1e18
		var worst_i := -1
		for i in n:
			var c: Vector3 = r.baked[i]
			var d2 := Vector2(c.x - p.x, c.z - p.z).length()
			if d2 > 20.0:
				continue
			# doar etajul care trece pe LANGA cota pilei (+/- 6 m)
			if absf(c.y - p.y) > 6.0:
				continue
			var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
			var side := Vector3(fw.z, 0.0, -fw.x).normalized()
			var lat: float = Vector2(p.x - c.x, p.z - c.z).dot(Vector2(side.x, side.z))
			if absf(lat) < absf(worst_lat):
				worst_lat = lat
				worst_i = i
		if worst_i < 0:
			continue    # nicio felie la cota ei: pila e curata
		var need: float = track.width_at_index(worst_i) + 2.5 + PILLAR_R
		if absf(worst_lat) >= need:
			continue    # deja libera
		var c2: Vector3 = r.baked[worst_i]
		var fw2 := (r.baked[(worst_i + 1) % n] - r.baked[(worst_i - 1 + n) % n]).normalized()
		var side2 := Vector3(fw2.z, 0.0, -fw2.x).normalized()
		# NU o mutam pe axa (ar aluneca zeci de metri de-a lungul curbei si ar
		# iesi de sub tablierul pe care il sustine). O impingem perpendicular,
		# de la locul ei, exact cat ii lipseste.
		var want: float = maxf(CLEAR, need) * (1.0 if worst_lat >= 0.0 else -1.0)
		var np := p + side2 * (want - worst_lat)
		out[str(node.name)] = np
		print("%s | frac=%.3f y=%.1f lat=%+6.2f (nevoie %.1f) -> %+6.2f | (%.6f, %.6f) -> (%.6f, %.6f)" % [
			node.name, float(worst_i) / float(n), p.y, worst_lat, need, want, p.x, p.z, np.x, np.z])
	print("--- de mutat: %d" % out.size())
	get_tree().quit()
