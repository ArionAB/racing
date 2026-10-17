## Acoperirea decorului PE POI, nu pe toata pista.
##
##   godot --headless --path . res://tools/ProbePoiCoverage.tscn -- --track=14
##
## DE CE EXISTA. Decorul Ha Long a fost facut o data pe CATEGORII (o bucla
## pentru toata vegetatia, una pentru parapeti, una pentru dig): 120 de piese,
## toate garzile verzi, bugete sanatoase. Verdictul la volan: "the track feels
## empty overall. It is the worst job from all tracks so far."
##
## Masurat dupa aceea, pe fractie de traseu:
##   A cheiul  3 | B pontoane 25 | C dig 11 | D urcare 49
##   E coborare 0 (21% din tur!) | F canal 2 | G coasta 30
##
## Media pe toata pista ascundea distributia. Un POI gol trebuie sa PICE, nu
## sa treaca fiindca totalul e mare — asta masoara sonda asta.
##
## Pragurile sunt per POI, nu globale: un POI de apa deschisa (F) n-are nevoie
## de aceeasi densitate ca un versant (D). Se dau ca piese la 100 m de traseu,
## ca sa nu depinda de cat de lung e POI-ul.
extends Node

## (nume, frac_start, frac_end, piese_minime_la_100m)
const POI := [
	["A cheiul", 0.98, 0.05, 6.0],
	["B pontoanele", 0.05, 0.24, 4.0],
	["C digul", 0.24, 0.36, 5.0],
	["D urcarea", 0.36, 0.53, 8.0],
	["E coborarea", 0.53, 0.74, 5.0],
	["F canalul", 0.74, 0.84, 3.0],
	["G coasta", 0.84, 0.98, 6.0],
]


func _ready() -> void:
	var track_idx := 14
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			track_idx = int(a.substr(8))
	var scene_no := 22 if track_idx == 14 else track_idx
	var path := "res://scenes/tracks/Track%02d.tscn" % scene_no
	var scene := load(path) as PackedScene
	if scene == null:
		print("!! nu pot incarca ", path)
		get_tree().quit(1)
		return
	var track := scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sampler = track.get("_sampler")
	var dec := track.get_node_or_null("DecorManual")
	if sampler == null or dec == null:
		print("!! fara _sampler / DecorManual")
		get_tree().quit(1)
		return

	var n: int = sampler.point_count()
	var total_len: float = sampler.total_length()
	# lungimea cumulata, ca sa putem transforma index -> fractie
	var cum := PackedFloat32Array()
	cum.resize(n)
	var acc := 0.0
	for i in n:
		cum[i] = acc
		var p: Vector3 = sampler.baked_point(i)
		var q: Vector3 = sampler.baked_point((i + 1) % n)
		acc += Vector2(q.x - p.x, q.z - p.z).length()
	var L: float = maxf(acc, 1.0)

	var count := {}
	for row in POI:
		count[row[0]] = 0
	var afara := 0

	for ch in dec.get_children():
		var nm := String(ch.name)
		if nm.ends_with("_col"):
			continue
		var n3 := ch as Node3D
		if n3 == null:
			continue
		var f := _frac(sampler, cum, L, n, n3.position)
		var pus := false
		for row in POI:
			if _in_poi(f, float(row[1]), float(row[2])):
				count[row[0]] = int(count[row[0]]) + 1
				pus = true
				break
		if not pus:
			afara += 1

	print("=== ACOPERIRE PE POI (pista %d m) ===" % int(total_len))
	print("%-16s %6s %8s %9s %9s  %s"
		% ["POI", "piese", "lungime", "la 100m", "prag", "stare"])
	var rele := 0
	for row in POI:
		var nm: String = row[0]
		var a: float = row[1]
		var b: float = row[2]
		var span: float = (b - a) if b > a else (1.0 - a + b)
		var m: float = span * total_len
		var c: int = count[nm]
		var dens: float = (float(c) * 100.0) / maxf(m, 1.0)
		var prag: float = row[3]
		var stare := "OK"
		if dens < prag:
			stare = "SUB PRAG"
			rele += 1
		if c == 0:
			stare = "GOL !!"
		print("%-16s %6d %7.0fm %9.1f %9.1f  %s"
			% [nm, c, m, dens, prag, stare])
	if afara > 0:
		print("(%d piese n-au cazut in niciun POI)" % afara)
	print("")
	print("=== %d POI sub prag din %d ===" % [rele, POI.size()])
	print("VERDICT: %s" % ("OK" if rele == 0 else "DE REPARAT"))
	get_tree().quit(1 if rele > 0 else 0)


## Fractia de traseu a unui punct, prin cel mai apropiat punct copt.
## Cautare in doua treceri (din 16 in 16, apoi fin): trecerea completa pe toate
## piesele x toate punctele dureaza minute intregi.
func _frac(sampler, cum: PackedFloat32Array, L: float, n: int,
		wp: Vector3) -> float:
	var best := INF
	var bi := 0
	var i := 0
	while i < n:
		var p: Vector3 = sampler.baked_point(i)
		var d := Vector2(wp.x - p.x, wp.z - p.z).length_squared()
		if d < best:
			best = d
			bi = i
		i += 16
	for j in range(maxi(0, bi - 20), mini(n, bi + 21)):
		var p2: Vector3 = sampler.baked_point(j)
		var d2 := Vector2(wp.x - p2.x, wp.z - p2.z).length_squared()
		if d2 < best:
			best = d2
			bi = j
	return cum[bi] / L


func _in_poi(f: float, a: float, b: float) -> bool:
	if a < b:
		return f >= a and f < b
	return f >= a or f < b
