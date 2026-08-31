extends Node
## Umple TREIMEA DE JOS a cadrului: pietre si tufe LANGA banda, in padurea de
## hornuri.
##
## De ce mai e nevoie de un generator cand `gen_capp_moloz` exista deja. Sonda
## `probe_capp_treime` masoara 9.8% acoperire la frac 0.05 desi molozul de
## margine e acolo — fiindca acela pune aschii de 0.10..0.30 scara la 7.5..15 m
## LATERAL. La inaltimea camerei de sofer (3.2 m) o piatra de 30 cm la 12 m
## lateral si 20 m in fata subintinde vreo 8 px: exista in scena, nu exista in
## cadru. Aceeasi capcana ca in memoria `efecte-invizibile-nu-se-numara`.
##
## Ce pune asta, si de ce chiar acolo. Treimea de jos a cadrului de la --driver
## (ochi la 7.5 m in spate si 3.2 m sus, privind 14 m inainte) inseamna solul de
## la ~6 m pana la ~30 m in fata masinii, in vreo +/-14 m lateral. Deci:
##   - banda de asezare 6.8..13 m de axa (half_width e 6, plus o palma ca roata
##     sa nu prinda nimic — memoria `suprafete-cu-goluri-si-praguri`);
##   - marimi de la 0.45 la 1.4, adica pietre de la genunchi la peste capota,
##     nu aschii;
##   - tufe intre ele, ca marginea sa nu fie doar piatra pe piatra.
##
## SCARILE SE DERIVA DIN GABARIT, NU DIN NUME. Prima varianta a pus
## `cracked_chimney_a` la scara 0.45..1.40 crezand ca "cracked" inseamna ciot de
## piatra. Captura a iesit un coridor de coloane: GLB-ul are 16.8 m INALTIME la
## scara 1, deci "0.45" era o stanca de 7.5 m. `probe_capp_gab` tipareste
## gabaritele in metri; de acolo se citeste ca lespedea plata e
## `cracked_chimney_c` (9.9 x 0.98 x 5.9 m), si ea e ce arata a moloz.
## Se cere inaltimea in METRI si scara se calculeaza, ca sa nu mai depinda de
## ce GLB e ales.
##
## Cost: cracked_chimney_c are 527 triunghiuri si shrub_dry 84, deci ~115 piese
## costa ~30k — nimic langa cele 415k ale pistei, si ZERO materiale noi (ambele
## GLB-uri sunt deja in scena).
##
##   godot --headless --path . res://tools/GenCappUmar.tscn
## Scrie .claude/umar_banda.txt, de lipit in Track13.tscn ca noduri EDITABILE.

const HALF: float = 6.0
## Inaltimile GLB-urilor la scara 1, masurate cu `probe_capp_gab`. Scrise ca
## constante fiindca scara se DERIVA din ele: cere inaltime in metri, nu factor.
const SLAB_W: float = 9.90   ## cracked_chimney_c: lespede plata 9.9 x 0.98 x 5.9
const SHRUB_H: float = 0.90  ## shrub_dry
const CONE_H: float = 13.36  ## chimney_d

func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8:
		await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 150832
	var space = get_tree().root.world_3d.direct_space_state
	var out := PackedStringArray()
	out.append('[node name="UmarulBenzii" type="Node3D" parent="DecorManual"]\n')
	var k := 0
	var nr := 0
	var nt := 0
	var nc := 0
	# Padurea de hornuri, cu o palma de fiecare parte. Cadrul de livrare e la
	# 0.05-0.06, dar decorul nu poate exista doar acolo: s-ar vedea de la volan
	# ca o insula care incepe si se termina.
	var f := 0.012
	while f < 0.125:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var dir: Vector3 = (a - p).normalized()
		var right := dir.cross(Vector3.UP).normalized()
		for side in [-1.0, 1.0]:
			var cate := rng.randi_range(1, 3)
			for c in cate:
				var zar := rng.randf()
				# Un con MIC din cand in cand, nu doar pietre si tufe. Sonda
				# `probe_capp_unde` spune ca nimic asezat pe sol langa banda nu
				# coboara sub y=419, deci ce se poate face pentru compozitie e
				# sa ADUCI continut cat mai jos si mai aproape — iar un con de
				# 5-8 m la 7-9 m lateral umple fasia 300..420, pe care pana acum
				# o taia doar cer si asfalt.
				var con := zar < 0.16
				var tufa := zar >= 0.16 and zar < 0.55
				# 6.8 m: dincolo de carosabil (6.0) plus o palma. Sub atat,
				# roata prinde piatra.
				# 6.8 m: dincolo de carosabil (6.0) plus o palma. 10.5 m sus:
				# masurat cu ProbeCappCine pe cadrul de la --driver, marginea
				# de sus a treimii de jos (y=480) cade pe teren la 15 m in fata;
				# ce sta mai departe de 10-11 m lateral proiecteaza DEASUPRA ei,
				# adica in treimea de mijloc, unde erau si pana acum conuri.
				# Conurile stau mai afara: unul lipit de carosabil taie vederea
				# spre padure si, la 8 m, e si un perete pe care il vezi doar
				# cand a trecut de tine.
				var off_min: float = 8.5 if con else 6.8
				var off: float = side * rng.randf_range(off_min, 11.5 if con else 10.5)
				var along := rng.randf_range(-5.0, 5.0)
				var xz: Vector3 = p + right * off + dir * along
				# Cota REALA a terenului, nu cota soselei: pe portiunea asta
				# malul urca, si o piatra pusa la cota benzii ar pluti.
				var q := PhysicsRayQueryParameters3D.create(
					xz + Vector3.UP * 80.0, xz - Vector3.UP * 80.0)
				var hit: Dictionary = space.intersect_ray(q)
				if hit.is_empty():
					continue
				var gy: float = hit["position"].y
				# NUMAI PE TEREN. Raza loveste si hornurile — poala lor de moloz
				# se intinde metri buni in lateral — iar o lespede asezata pe
				# flancul unui horn iese o placa care PLUTESTE in fata pietrei.
				# S-a si intamplat: prima varianta a pus una peste conul din
				# stanga cadrului de la 0.05 si a taiat amplitudinea sondei de
				# muchii de la 148 la 90 pe randul ala, adica a stricat runda 14
				# cu decor de runda 15.
				#
				# Filtrul pe cota (`gy` fata de banda) NU ajunge: poala unui horn
				# incepe chiar la cota soselei. Se cere ca lucrul lovit sa NU
				# atarne de DecorManual.
				var col: Object = hit["collider"]
				var pe_decor := false
				var anc: Node = col as Node
				while anc != null:
					if String(anc.name) == "DecorManual":
						pe_decor = true
						break
					anc = anc.get_parent()
				if pe_decor:
					continue
				if absf(gy - p.y) > (9.0 if con else 6.0):
					continue
				# Inaltimea DORITA in metri; scara iese din gabaritul GLB-ului.
				var want_m: float
				var glb_ref: float
				var res_id: String
				var nume: String
				if con:
					# Conuri MICI: cele mari sunt deja in padure, iar un horn de
					# 15 m la 8 m lateral ar fi un zid, nu un reper.
					want_m = rng.randf_range(5.0, 8.5)
					glb_ref = CONE_H
					res_id = "13_ch_d"
					nume = "conUmar%d" % k
					nc += 1
				elif tufa:
					want_m = rng.randf_range(1.0, 2.0)
					glb_ref = SHRUB_H
					res_id = "22_shrub"
					nume = "tufaUmar%d" % k
					nt += 1
				else:
					# De la genunchi (0.5 m) pana peste capota (1.9 m). Sub
					# jumatate de metru piatra dispare din cadru la 20 m; peste
					# doi metri incepe sa concureze cu hornurile si sa taie
					# vederea spre padure.
					# Se cere LATIMEA: de la o piatra cat o roata (1.2 m) pana
					# la un bolovan cat masina (3.4 m). Inaltimea iese ~a zecea
					# parte, adica exact o lespede culcata.
					want_m = rng.randf_range(2.0, 4.6)
					glb_ref = SLAB_W
					res_id = "27_crk_c"
					nume = "piatraUmar%d" % k
					nr += 1
				# Scara UNIFORMA, dar aleasa dupa dimensiunea care conteaza. La
				# tufa aia e inaltimea. La lespede e LATIMEA: cracked_chimney_c
				# e 9.9 m lat si nici un metru inalt, deci scaland-o dupa
				# inaltime ("vreau 1.9 m") iesea o placa de 19 m — un carosabil
				# fals lipit de banda, nu un bolovan.
				var sc: float = want_m / glb_ref
				var yaw := rng.randf() * TAU
				var cs := cos(yaw) * sc
				var sn := sin(yaw) * sc
				# Ingropata cu ~25% din inaltime: o piatra asezata pe teren cu
				# baza exact la cota citeste a obiect pus, nu a bolovan.
				var sink: float
				if con:
					sink = sc * 0.10
				elif tufa:
					sink = sc * 0.20
				else:
					sink = sc * 0.25
				out.append('[node name="%s" parent="DecorManual/UmarulBenzii" instance=ExtResource("%s")]' % [nume, res_id])
				out.append('transform = Transform3D(%.6f, 0, %.6f, 0, %.6f, 0, %.6f, 0, %.6f, %.3f, %.3f, %.3f)' % [
					cs, sn, sc, -sn, cs, xz.x, gy - sink, xz.z])
				out.append('metadata/coliziune = "none"\n')
				k += 1
		f += 0.007
	var path := "res://.claude/umar_banda.txt"
	var fh := FileAccess.open(path, FileAccess.WRITE)
	fh.store_string("\n".join(out))
	fh.close()
	print("scrise %d piese (%d pietre, %d tufe, %d conuri) in %s" % [
		k, nr, nt, nc, path])
	get_tree().quit(0)
