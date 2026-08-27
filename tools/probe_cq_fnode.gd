extends Node
## Verdictul POI F pe pista REALA, prin RAZE, nu prin indecsi.
##
## De ce raze: in POI F pista trece peste ea insasi, iar `baked`/`closest_index`
## aleg etajul gresit (memoria `pista-peste-pista`). O raza trasa in jos de
## deasupra carosabilului nimereste suprafata pe care chiar calca masina, si
## masoara exact ce conteaza: exista podea peste tot pe unde trece modulul, si
## are praguri?
const CAR_HALF: float = 1.05
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var span := track.find_child("PasajRotativ", false, false)
	var crane := track.find_child("Macara", false, false)
	var ok := true

	# 1. Podeaua pe toata lungimea modulului, pe 3 benzi.
	var lip: float = span.span_length * 0.5
	var reach: float = lip + span.deck_run + span.ramp_run
	print("PasajRotativ la %s" % span.global_position)
	print("  podea pe %.0f m, banda directa x = +-%.2f (golul e intre +-%.1f)" % [2.0 * reach, CAR_HALF, lip])
	var prev := {}
	var gaps := 0
	var steps := 0
	var z := -reach
	while z <= reach:
		for lane: float in [-CAR_HALF, 0.0, CAR_HALF]:
			var wp: Vector3 = span.global_transform * Vector3(lane, 0.0, z)
			var from := wp + Vector3.UP * 8.0
			var to := wp + Vector3.DOWN * 12.0
			var q := PhysicsRayQueryParameters3D.create(from, to)
			var hit := space.intersect_ray(q)
			var inside_gap: bool = absf(z) <= lip + 0.2
			if hit.is_empty():
				if not inside_gap:
					gaps += 1
					if gaps <= 6:
						print("    GOL la z=%+.1f banda %+.1f" % [z, lane])
			else:
				var y: float = hit.position.y
				if str(hit.collider.name) == "Gate":
					continue
				var key := lane
				if prev.has(key) and not inside_gap:
					var dy: float = absf(y - prev[key])
					if dy > 0.30:
						steps += 1
						if steps <= 6:
							print("    PRAG %.2f m la z=%+.1f banda %+.1f" % [dy, z, lane])
				prev[key] = y
		z += 1.0
	print("  goluri: %d | praguri >0.30 m: %d" % [gaps, steps])
	# Profilul cotei pe axa, ca sa se vada UNDE si CAT se desprinde placa.
	print("  profil pe axa (z | cota lovita | cota placii):")
	var zz := -reach - 6.0
	while zz <= reach + 6.0:
		var wp2: Vector3 = span.global_transform * Vector3(0.0, 0.0, zz)
		var q3 := PhysicsRayQueryParameters3D.create(wp2 + Vector3.UP * 10.0, wp2 + Vector3.DOWN * 14.0)
		var h3 := space.intersect_ray(q3)
		var got: String = "%8.2f" % h3.position.y if not h3.is_empty() else "     ---"
		var who := ""
		if not h3.is_empty():
			var c3 = h3.collider
			who = "%s" % c3.name
			var par = c3.get_parent()
			while par != null and par != track:
				who = "%s/%s" % [par.name, who]
				par = par.get_parent()
		print("    %+6.1f | %s | %8.2f | %s" % [zz, got, wp2.y, who])
		zz += 2.0
	if gaps > 0 or steps > 0:
		ok = false

	# 2. Macaraua: turnul nu e pe carosabil, sarcina matura banda.
	var to_x: float = crane.tower_offset * signf(float(crane.tower_side))
	var lo: float = to_x - crane.hook_radius
	var hi: float = to_x + crane.hook_radius
	var hw: float = crane.road_half_width
	var cov: float = minf(hi, hw) - maxf(lo, -hw)
	print("Macara la %s" % crane.global_position)
	print("  turn la x=%+.1f (banda +-%.1f) | carlig x in [%.1f, %.1f] -> matura %.1f din %.1f m" % [
		to_x, hw, lo, hi, maxf(cov, 0.0), 2.0 * hw])
	if absf(to_x) - 1.8 < hw:
		print("  !! turnul e pe carosabil"); ok = false
	if cov < 3.0:
		print("  !! nu matura banda"); ok = false
	# sarcina fata de asfaltul REAL de sub ea
	var under: Vector3 = crane.global_transform * Vector3(0.0, 0.0, 0.0)
	var q2 := PhysicsRayQueryParameters3D.create(under + Vector3.UP * 6.0, under + Vector3.DOWN * 30.0)
	var h2 := space.intersect_ray(q2)
	if h2.is_empty():
		print("  !! nu e asfalt sub macara"); ok = false
	else:
		var slab_bottom: float = crane.global_position.y + crane.load_clearance
		print("  asfalt la %.2f, talpa sarcinii la %.2f -> garda %.2f m" % [
			h2.position.y, slab_bottom, slab_bottom - h2.position.y])
		if slab_bottom - h2.position.y < 0.2 or slab_bottom - h2.position.y > 2.5:
			print("  !! garda sub sarcina in afara contractului (0.2..2.5)"); ok = false
	print("VERDICT F: %s" % ("OK" if ok else "PROBLEME"))
	get_tree().quit()
