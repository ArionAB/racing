extends Node
## Blocurile de sub Piata Kuixinglou, asezate pe cifre de pe ECRAN.
##
## Problema 1 din lista dezvoltatorului: „cele 3 blocuri sunt sub harta, din
## perspectiva masinii nu sunt vizibile". Masurat inainte: varfurile lor
## stateau la -0.0, -3.0 si -9.0 m fata de cota soselei, adica nu urcau peste
## buza platoului deloc.
##
## Runda 1 a incercat sa le ridice si raportase ca a facut-o, dar scria
## `transform`-ul TRANSPUS (vezi `tools/fix_cq_fatade.gd`), asa ca in fisier
## ajungea alt lucru decat calculase. Aici se scrie corect si, mai important,
## alegerea nu se mai face din rationament, ci din baleiere: pentru fiecare
## pereche (distanta laterala, cat urca varful) se masoara CAT DIN CADRU ocupa
## blocul prin camera de joc de la fractia 0.010.
##
## Ce a aratat baleierea (`probe_cq_r2t`, 18 combinatii):
##     lat 14-26 m -> 44-85% din ecran. Nu e o cladire, e un zid: acopera chiar
##                    golul pe care POI-ul trebuie sa-l arate.
##     lat 52 m    -> 0%. Buza platoului il ocluzeaza complet.
##     lat 34 m    -> 12-16%, cu varful sus in cadru (y=111..288 din 720).
## Deci 34 m, cu varfuri esalonate intre +8 si +12 m peste sosea, ca sirul sa
## aiba silueta, nu o linie dreapta.
const TRACK := "res://scenes/tracks/Track12.tscn"
## Inaltimea modelului `liziba_block`, masurata: talpa = varf - atat.
const BLOCK_H := 24.9

func _ready() -> void:
	await get_tree().process_frame
	var track := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	for _i in 6:
		await get_tree().physics_frame
	var r := track.routes[0]
	var n := r.baked.size()
	# frac, lateral, cat urca varful peste sosea
	var specs := [
		["bloc_sub_piata1", 0.010, 34.0, 12.0],
		["bloc_sub_piata2", 0.022, 33.0, 8.5],
		["bloc_sub_piata3", 0.034, 36.0, 10.0],
	]
	for sp: Array in specs:
		var nm: String = sp[0]
		var node := track.find_child(nm, true, false) as Node3D
		if node == null:
			push_error("lipsa %s" % nm)
			continue
		var i := int(round(float(sp[1]) * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 4) % n] - r.baked[(i - 4 + n) % n]).normalized()
		var sd := Vector3(fw.z, 0.0, -fw.x).normalized()
		var p := c + sd * float(sp[2])
		var y: float = c.y + float(sp[3]) - BLOCK_H
		# Yaw-ul ramane cel din scena: blocurile stau in sir de-a lungul
		# malului, si ferestrele lor sunt pe fetele lungi (masurat in runda 1).
		var b := node.global_basis
		print("%s|transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
			% [nm, b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y,
				b.x.z, b.y.z, b.z.z, p.x, y, p.z])
		print("# %s: lat %.0f m, varf %+.1f peste sosea (fereastra %.1f)"
			% [nm, float(sp[2]), float(sp[3]), 10.0 + 0.093 * float(sp[2])])
	get_tree().quit()
