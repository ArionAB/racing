extends Node
## Separarea pe verticala intre turele spiralei din stanca goala.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappCoils.tscn -- --track=6
##
## Bara e 14 m: sub atat masina de pe tura de jos vede tavanul turei de sus in
## frustum si spirala citeste ca un tunel turtit, nu ca o sala. Se masoara pe
## PUNCTE COAPTE, nu pe punctele de control: bake-ul e cel pe care il ating
## rotile.

const MIN_GAP: float = 14.0
## Cat de aproape in plan XZ trebuie sa fie doua puncte ca sa fie "unul peste
## celalalt". Latimea benzii e 6 m, deci 7 m acopera si umerii.
const XZ_TOL: float = 7.0
## Banda de tur in care traseul chiar e spirala (= custom_overpass_ranges).
const HELIX_F0: float = 0.769
const HELIX_F1: float = 0.962


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var r := track.routes[0]
	var n := r.baked.size()
	var worst := INF
	var worst_f := 0.0
	var pairs := 0
	# separat: TURA-peste-TURA (ambele in banda elicei) si tura-sub-DRUMUL DE
	# IESIRE, care e alta intrebare — prima spune daca spirala e o sala, a doua
	# daca ai tavan cand treci pe sub gura stancii.
	var coil := INF
	var coil_f := 0.0
	var worst_j := 0.0
	var worst_p := Vector3.ZERO
	var worst_q := Vector3.ZERO
	for i in n:
		var p := r.baked[i]
		for j in n:
			# doar perechi departate pe traseu: vecinii de pe aceeasi tura sunt
			# la 3 m unul de altul si n-au ce cauta in masuratoare.
			var apart := absf(float(i - j))
			if minf(apart, float(n) - apart) < 30.0:
				continue
			var q := r.baked[j]
			if Vector2(q.x - p.x, q.z - p.z).length() > XZ_TOL:
				continue
			var gap := absf(q.y - p.y)
			pairs += 1
			var fi := r.frac_at(i)
			var fj := r.frac_at(j)
			var both_helix := fi >= HELIX_F0 and fi <= HELIX_F1 				and fj >= HELIX_F0 and fj <= HELIX_F1
			if both_helix and gap < coil:
				coil = gap
				coil_f = fi
			if gap < worst:
				worst = gap
				worst_f = r.frac_at(i)
				worst_j = r.frac_at(j)
				worst_p = p
				worst_q = q

	print("")
	print("=== %s — separarea intre ture ===" % track.track_name)
	print("  perechi suprapuse in plan (<= %.0f m)  %d" % [XZ_TOL, pairs])
	if pairs == 0:
		print("  nicio suprapunere — pista nu trece pe deasupra ei insasi")
		print("VERDICT: OK")
		get_tree().quit(0)
		return
	print("  cea mai mica separare              %.2f m  (bara %.0f)" % [worst, MIN_GAP])
	print("    frac %.3f  (%.1f, %.2f, %.1f)" % [worst_f, worst_p.x, worst_p.y, worst_p.z])
	print("    frac %.3f  (%.1f, %.2f, %.1f)" % [worst_j, worst_q.x, worst_q.y, worst_q.z])
	print("")
	print("  TURA peste TURA (ambele in spirala)  %.2f m la frac %.3f"
		% [coil, coil_f])
	print("")
	var ok := coil >= MIN_GAP
	print("VERDICT: %s" % ("OK" if ok else "PROBLEMA (turele se ating)"))
	get_tree().quit(0 if ok else 1)
