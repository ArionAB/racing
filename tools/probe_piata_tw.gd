extends Node
## Transformari pentru blocurile de sub piata Kuixinglou (brief §2 A: "sub el,
## 22 de etaje de bloc si orasul").
##
## DOUA lucruri masurate au decis forma de aici, amandoua contrazicand
## incercarile anterioare:
##
## 1. ASSETUL. `tower_silhouette_a/b/c` are un raport fatada/acoperis bun
##    (3.7-4.3) dar ferestrele lui sunt 984 de triunghiuri de 0.08 m2 — 28 cm
##    latime — insumand 4% din fatada. E construit pentru ce spune brief §2.0:
##    "turnurile exista doar ca siluete peste rau, la 150-250 m". La 9 m de
##    camera ferestrele lui sunt de 2 pixeli si piesa citeste ca o placa
##    palida — exact plangerea dezvoltatorului, doar cu alt mesh.
##    `liziba_block` are, pe fetele de Z, 9-11% arie de ferestre (204-245 m2,
##    de trei ori aria absoluta a turnului). E piesa corecta AICI.
##
## 2. ORIENTAREA. Fetele lui liziba_block nu sunt egale: Z are 9-11% ferestre,
##    X are 0.7%, acoperisul 0.4%. Asezat cu capatul (X) spre drum arata un
##    perete gol; asezat cu Z spre drum arata etaje. Incercarea anterioara cu
##    liziba_block l-a rotit cu X spre drum, de-aia "nu se vedea nimic" si de
##    aceea concluzia "nu exista cota buna pentru liziba_block" era o concluzie
##    despre orientare, nu despre piesa.
##
## 3. UNGHIUL. Varful trebuie sa treaca PESTE cota soselei, nu sa ramana sub
##    ea: cu varful sub sosea si piesa la 22-33 m lateral, unghiul de depresie
##    spre varf e 19-46 grade si camera vede acoperisul. Cu fata la 8-10 m si
##    varful peste sosea, unghiul cade la -8..+13 grade si peretele umple
##    cadrul.
## Dimensiunile lui liziba_block, din AABB (masurate, nu presupuse).
const LIZ_H: float = 24.9   # inaltime
const LIZ_D: float = 27.24  # adancimea pe Z — devine latimea LATERALA, fiindca
                            # fata cu ferestre (Z) se intoarce spre drum


## Cat se ingroapa un corp in cel de deasupra. Terasele lui liziba_block stau
## la y=9/12/15/19: cu 6 m de suprapunere, acoperisul corpului de jos si terasa
## lui cea mai de sus intra sub corpul urmator si raman la vedere doar peretii.
const OVERLAP: float = 6.0

## Inaltimea camerei de joc peste sosea (ChaseCamera.DEFAULT_HEIGHT). Pragul
## peste care un bloc nu-si mai arata acoperisul nu e cota soselei, ci ASTA.
const CAM_H: float = 10.0


func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	# model, inaltime nescalata, fractie, lateral, scara, top = sosea + acest offset
	# (offset negativ = varful ramane sub sosea, pentru randul departat)
	# "d" e distanta laterala pana la FATA turnului (peretele dinspre drum), nu
	# pana la centru: piesele au 9.5-14.5 m latime, deci un centru la 9 m baga
	# peretele in carosabil. Centrul se deduce mai jos: d + jumatate de latime.
	# liziba_block: 40.6 x 24.9 x 27.2 m, ferestre pe fetele de Z.
	# "w" e latimea piesei pe directia LATERALA a drumului. Cu Z spre drum,
	# lateral inseamna adancimea Z (27.24), nu X.
	# "t" = cota varfului fata de sosea. Randul apropiat trece PESTE sosea ca
	# peretele sa umple cadrul; cele departate raman sub ea, ca fundal.
	var plan := [
		# randul APROPIAT: fatada cu ferestre chiar sub buza (buza e la 6 m)
		# Fata la 12-14 m, nu la 8.5: la 8.5 blocul devine un ZID lipit de
		# parapet si acopera chiar golul pe care trebuie sa-l arate. La 12-14 m
		# ramane o fasie de vid intre bara si fatada — caderea se citeste, iar
		# unghiul spre varf e inca mic (fatada, nu acoperis).
		#
		# "t" >= CAM_H (+10 m fata de sosea) pe randul APROPIAT, si asta e
		# lectia care lipsea: camera de joc sta la sosea + 10 m, deci un bloc
		# care se opreste la sosea + 4 isi arata tot acoperisul. Nu "peste
		# sosea" e pragul, ci "peste CAMERA". Acoperisul lui liziba_block are
		# 8926 m2 — de patru ori o fata de Z — deci orice bucata de acoperis
		# lasata in cadru domina fatada.
		# DOUA blocuri inalte, nu patru, si departate intre ele: patru la rand
		# faceau un zid neintrerupt care ascundea chiar golul pe care POI-ul
		# trebuie sa-l arate. Doua repere inalte + goluri intre ele = si fatada
		# in cadru, si caderea vizibila printre ele (brief §8, adancimea prin
		# proximitate).
		{"f": 0.0060, "d": 13.0, "s": 1.00, "t": 13.0},
		{"f": 0.0250, "d": 12.5, "s": 1.05, "t": 15.0},
		# planul MIJLOCIU: varfuri sub buza, se vede orasul coborand peste ele.
		# Stau in golurile dintre cele doua blocuri inalte, ca privirea sa cada
		# pe ceva cand trece prin fanta.
		{"f": 0.0125, "d": 22.0, "s": 1.00, "t": -4.0},
		{"f": 0.0185, "d": 26.0, "s": 1.05, "t": -7.0},
		{"f": 0.0330, "d": 24.0, "s": 1.00, "t": -5.0},
		# fundalul, jos in rapa
		{"f": 0.0095, "d": 44.0, "s": 1.00, "t": -14.0},
		{"f": 0.0290, "d": 40.0, "s": 1.05, "t": -12.0},
	]
	var i := 0
	for e: Dictionary in plan:
		i += 1
		var f: float = e["f"]
		var sc: float = e["s"]
		var mh: float = LIZ_H
		var s: float = f * L
		var face: float = float(e["d"])
		var p := c.sample_baked(s)
		var p2 := c.sample_baked(minf(s + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		# Distanta la CENTRU = distanta ceruta pana la fata + semi-latimea PROIECTATA
		# pe directia laterala. Piesa e rotita cu unghiul drumului fata de axele
		# lumii, deci proiectia se calculeaza din baza reala, nu din diagonala:
		# altfel marja e cu 40% prea mare si turnul se departeaza inapoi in zona
		# in care camera ii vede acoperisul.
		# Piesa se roteste EXACT cu drumul (X piesa = fwd, Z piesa = -right, vezi
		# baza de mai jos), deci fata dinspre drum e la exact o semi-latime de
		# centru pe directia laterala. Fara marja de diagonala: ar impinge turnul
		# cu 40% mai departe, inapoi in zona unde camera ii vede acoperisul.
		var ext: float = LIZ_D * sc * 0.5
		var d: float = face + ext
		var o: Vector3 = p + right * d + Vector3.UP * 60.0
		var q := PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN * 260.0)
		var h := space.intersect_ray(q)
		var ground: float = h.position.y if not h.is_empty() else 23.0
		var pos: Vector3 = p + right * d
		# Varful se aseaza la sosea + offset (asta decide unghiul camerei), iar
		# baza trebuie sa ajunga in stanca, altfel blocul pluteste.
		# Golul e de ~50 m, blocul are 24.9: NU se intinde pe Y (la scara 2.1
		# etajele ies de 6 m si citirea de "22 de etaje" se pierde — chiar
		# lucrul care trebuie sa se vada). Se STIVUIESC doua corpuri, cum arata
		# si Chongqing-ul real: un bloc peste altul, cu fatadele decalate.
		var want_top: float = p.y + float(e["t"])
		var want_base: float = ground - 3.0
		var span: float = want_top - want_base
		var sy: float = sc
		var levels: int = maxi(1, int(ceil(span / maxf(mh * sy - OVERLAP, 1.0))))
		pos.y = want_top - mh * sy
		var top_final: float = want_top
		# fata cu ferestre spre drum: +Z al piesei spre -right (spre sosea)
		# Fata cu ferestre (Z al piesei) spre CAMERA, nu perpendicular pe drum.
		# Camera de joc nu sta pe verticala blocului: e cu 12.5 m mai in SPATE
		# pe traseu si cu 10 m mai sus. Un bloc intors perpendicular pe drum
		# isi arata fatada aprinsa in unghi de 38-68 grade — masurat cu
		# probe_liz_yaw.gd — si ferestrele se sting in muchie. Se tinteste
		# direct pozitia camerei din dreptul blocului, proiectata in plan.
		var cam_pos: Vector3 = p - fwd * 12.5 + Vector3.UP * 10.0
		var to_cam := (cam_pos - (p + right * d))
		to_cam.y = 0.0
		to_cam = to_cam.normalized()
		var bz := to_cam * sc
		var by := Vector3.UP * sy
		var bx := to_cam.cross(Vector3.UP).normalized() * sc
		# baza trebuie sa ramana dreapta (determinant pozitiv), altfel piesa e
		# oglindita si Godot o culleaza (vezi nota despre scale.x negativ)
		if bx.cross(by).dot(bz) < 0.0:
			bx = -bx
		var b := Basis(bx, by, bz)
		var depr := rad_to_deg(atan2(p.y + 10.0 - top_final, d))
		print("bloc%d frac=%.4f fata=%.1f centru=%.1f teren=%.1f varf=%.1f sosea=%.1f peste=%.1f depresie=%.1f corpuri=%d"
			% [i, f, face, d, ground, top_final, p.y, top_final - p.y, depr, levels])
		# Corpurile stivuite: fiecare sub cel de deasupra, cu o mica rotire in
		# plan ca stiva sa nu fie un singur prisma neintrerupta.
		# SUPRAPUNERE, nu asezare cap la cap. liziba_block are 8926 m2 de
		# suprafata orizontala (terase la y=9/12/15/19 plus acoperisul) fata de
		# 2288 m2 pe o fata de Z: lasate la vedere, terasele umplu cadrul si
		# ferestrele scad la ~2% din aria vizibila. Corpul de deasupra se lasa
		# peste cel de dedesubt cu `OVERLAP`, asa incat din corpul de jos
		# ramane vizibila doar BANDA DE FATADA dintre doua terase.
		for lv in levels:
			var q3: Vector3 = pos - Vector3.UP * (mh * sy - OVERLAP) * float(lv)
			# decalaj lateral marunt pe corpurile de jos: fatada capata praguri
			q3 += right * (0.9 * float(lv))
			var bb := b
			if lv % 2 == 1:
				bb = Basis(-b.x, b.y, -b.z)
			print("transform = Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.3f, %.3f, %.3f)"
				% [bb.x.x, bb.x.y, bb.x.z, bb.y.x, bb.y.y, bb.y.z, bb.z.x, bb.z.y, bb.z.z,
					q3.x, q3.y, q3.z])
	get_tree().quit()
