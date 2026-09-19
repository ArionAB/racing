extends Node
## Inventarul COAMELOR pe tot turul: locurile unde panta se rastoarna din
## urcare in coborare destul de brusc cat sa lanseze masina la fizica intreaga
## (memoria car-nu-e-lansat-de-panta, ISTORIC: la RigidBody3D panta lanseaza).
## Criteriul: schimbare de semn a pantei, cu amplitudinea (panta_max_inainte -
## panta_min_dupa) pe o fereastra scurta. Raporteaza si razele, ca sa se vada
## daca se suprapune cu un viraj.
const TRACK := "res://scenes/tracks/Track15.tscn"
const WIN := 8  # indici de o parte si de alta

func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var n := t.baked.size()
	var slope := PackedFloat32Array()
	slope.resize(n)
	for i in n:
		var a: Vector3 = t.baked[i]
		var b: Vector3 = t.baked[(i + 1) % n]
		var run := Vector2(b.x - a.x, b.z - a.z).length()
		slope[i] = ((b.y - a.y) / run * 100.0) if run > 0.001 else 0.0
	print("=== COAME (rasturnare de panta) pe Track15, fereastra +/-%d indici ===" % WIN)
	print("frac    idx   cota    panta_inainte  panta_dupa   amplitudine")
	var hits := 0
	for i in n:
		var up := -1e9
		for k in range(i - WIN, i):
			up = maxf(up, slope[(k + n) % n])
		var dn := 1e9
		for k in range(i + 1, i + 1 + WIN):
			dn = minf(dn, slope[k % n])
		# coama: urca inainte, coboara dupa, si chiar aici trece prin zero
		var here := slope[i]
		var prev := slope[(i - 1 + n) % n]
		if prev > 0.0 and here <= 0.0 and up > 3.0 and dn < -3.0:
			var amp := up - dn
			hits += 1
			print("%.3f  %4d  %+6.1f    %+7.1f      %+7.1f     %6.1f puncte%s"
				% [float(i)/float(n), i, t.baked[i].y, up, dn, amp,
				   ("   <<< CEA MAI TARE" if amp > 18.0 else "")])
	if hits == 0:
		print("  (niciuna)")
	print("")
	print("total coame: %d" % hits)
	get_tree().quit(0)
