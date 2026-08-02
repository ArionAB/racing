extends SceneTree
## Genereaza assets/textures/palette_atlas.png — UNICA textura a lumii.
##
##   godot --headless --path . --script res://tools/generate_palette_atlas.gd
##
## Atlasul are 32 de sloturi pe orizontala. Pana acum fiecare slot era un patrat
## de culoare UNIFORMA (atlas de 32x1 px, 288 bytes). Arata curat in editor, dar
## la viteza o suprafata de sute de m² fara nicio variatie citeste ca plastic —
## asta e diferenta principala fata de Reckless Racing 3 / Beach Buggy Racing,
## nu poligonajul.
##
## Acum fiecare slot e un PATCH TEXTURAT de 16x512 px: nisip cu granulatie, roca
## cu straturi orizontale, asfalt uzat, lemn cu fibra. Costa ~0.5 MB VRAM si
## ZERO draw call-uri in plus — materialul ramane unul singur.
##
## UV-urile existente functioneaza NESCHIMBATE: Palette.uv(slot) intoarce centrul
## slotului, care acum nimereste centrul unui patch texturat in loc de centrul
## unui patrat plat. Cele 5 props hero din Blender nu se refac.
##
## Sursa de adevar pentru culori e Palette.HEX — nu se dubleaza aici.

## Latimea unui slot in pixeli. 32 sloturi x 16 px = 512.
const SLOT_W: int = 16
## Inaltimea atlasului. Verticala e "de-a lungul" texturii: acolo intra
## straturile de roca si fibra lemnului.
const HEIGHT: int = 512
## Cati pixeli de la fiecare margine raman NEATINSI de variatie.
##
## Cu filtrare liniara si mipmap-uri, doi pixeli vecini din sloturi diferite se
## amesteca — nisipul ar capata tenta de asfalt. Marginile pastreaza culoarea
## curata a slotului, deci chiar daca filtrarea "trage" din vecin, trage dintr-o
## zona care arata corect.
const PAD: int = 2

const OUT_PATH: String = "res://assets/textures/palette_atlas.png"

## Seminte SEPARATE per artefact generat.
##
## Initial exista una singura si `rng` curgea secvential prin toata rularea:
## bucla de sloturi consuma din el, iar texturile de suprafata continuau din
## starea ramasa. Efectul secundar a aparut la adaugarea mediului insular —
## sloturile 17..23 au inceput sa consume cateva mii de extrageri, iar
## detail_rock.png, surface_sand.png si surface_asphalt.png au iesit diferite
## desi nimeni nu le atinsese. Adica o culoare noua in paleta regenera exact
## texturile pe care sunt calibrate masuratorile din style_bible §14, pentru
## toate pistele.
##
## Cu seminte separate, fiecare artefact e reproductibil independent: poti
## adauga sau scoate sloturi fara sa clatini nimic in aval.
const SEED_SLOTS: int = 20260801
const SEED_SURFACE: int = 20260802
const SEED_DETAIL: int = 20260803

var rng := RandomNumberGenerator.new()


func _init() -> void:
	# Seed fix: acelasi atlas la fiecare rulare. Altfel fiecare regenerare ar
	# produce un PNG diferit binar si ar murdari git-ul fara motiv.
	rng.seed = SEED_SLOTS
	var img := Image.create(SLOT_W * Palette.SLOTS, HEIGHT, true,
		Image.FORMAT_RGB8)
	for slot in Palette.SLOTS:
		_fill_slot(img, slot)
	DirAccess.make_dir_recursive_absolute("res://assets/textures")
	var err := img.save_png(OUT_PATH)
	if err != OK:
		push_error("Nu am putut scrie %s (eroare %d)" % [OUT_PATH, err])
		quit(1)
		return
	print("Atlas scris: %s  (%dx%d, %d sloturi)"
		% [OUT_PATH, img.get_width(), img.get_height(), Palette.SLOTS])
	# Re-semanare inainte de fiecare artefact — vezi SEED_* de mai sus.
	rng.seed = SEED_SURFACE
	_surface_textures()
	rng.seed = SEED_DETAIL
	_detail_textures()
	print("Reimporta in Godot, apoi masoara:")
	print("  godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.20 --driver")
	print("  godot --headless --path . --script res://tools/measure_surface.gd \\")
	print("      -- --image=snapshots/dunele_sofer.png")
	quit()


## Stratul de DETALIU al lumii — cel care repara "totul arata plat".
##
## Problema pe care o rezolva: UV-urile prop-urilor din Blender sunt colapsate pe
## UN SINGUR punct (dio_lib.assign_uvs), ca fiecare fata sa ia exact culoarea
## slotului ei din atlas. Consecinta neintentionata e ca derivata UV e zero, deci
## fiecare fata citeste UN texel — tot detaliul din _texture_for() de mai jos e,
## la runtime, invizibil pe props. Masurat: fata de faleza avea deviatie de
## luminanta 0.76, referinta ~40.
##
## Reparatia NU e sa desfasuram UV-uri (ar sparge strategia de un-singur-material
## si ar inmulti draw call-urile). E stratul de detaliu al lui Godot cu
## uv2_triplanar: coordonatele se calculeaza din pozitia si normala varfului, deci
## ATRIBUTUL UV2 NU E CITIT NICIODATA. Toate cele ~500 de obiecte capata detaliu
## fara re-export si fara material nou. Vezi Palette.world_material().
func _detail_textures() -> void:
	# Trei scari intr-o singura textura, ca sa acopere si banda de strat, si
	# granulatia. La uv2_scale 0.35 o repetitie = 2.86 m, deci cele 4 benzi cad
	# la ~0.71 m — exact intervalul cerut de style_bible §3 pentru strata.
	_write_tileable_n("res://assets/textures/detail_rock.png", 256,
		func(x: int, y: int) -> float:
			var fx := float(x) / 256.0
			var fy := float(y) / 256.0
			# Strate orizontale de DOUA grosimi, nu una: 7 benzi late (~0.4 m la
			# scara de joc) peste care se suprapun 17 fine. O singura frecventa
			# arata ca un cod de bare — verificat in vederea soferului.
			# Linia de separatie ondula pe X, altfel toate stancile au aceleasi
			# dungi drepte la aceeasi inaltime.
			var warp := sin(fx * TAU * 2.0) * 0.35 + sin(fx * TAU * 5.0) * 0.12
			var band := smoothstep(-0.25, 0.25,
				sin(fy * TAU * 7.0 + warp)) * -0.22
			var fine := smoothstep(-0.5, 0.5,
				sin(fy * TAU * 17.0 + warp * 1.7)) * -0.09
			# Pete lente: rup repetitia tiling-ului, care altfel se vede ca un
			# tipar regulat pe suprafetele mari.
			var macro := sin(float(x) * 0.021) * cos(float(y) * 0.017) * 0.07
			# Granulatie: detaliul de aproape, cel care se pierde primul daca e
			# prea slab. Nu cobori sub 0.14 — sub atat, compresia il mananca.
			var grain := -rng.randf() * 0.16
			return band + fine + macro + grain + 0.14)

	_sky_cover()
	# Masca per slot: cat de tare bate detaliul pe fiecare rol din paleta.
	# Slotul devine astfel canal de autorat — nisipul si roca primesc tot, iar
	# accentele de masina NIMIC (style_bible §1: masinile raman cele mai curate
	# suprafete din cadru, ca sa se desprinda de fundal).
	_write_detail_mask("res://assets/textures/detail_mask.png")


## Nori pentru ProceduralSkyMaterial.sky_cover — o panorama gri, 512x256.
##
## Camera Ignition e mai plata decat cea veche (7° in loc de 11°), deci orizontul
## coboara in cadru si cerul creste de la ~40% la ~48% din imagine. Fara nimic in
## el, camera mai buna face cadrul mai GOL, nu mai imersiv.
##
## sky_cover se inmulteste peste gradientul procedural si costa zero draw
## call-uri — cerul e oricum desenat.
##
## Norii stau doar in jumatatea de sus (v < 0.5 e cerul; sub orizont nu are rost),
## se rarefiaza spre orizont si sunt intentionat difuzi: la 70° FOV si la viteza,
## nori cu contur clar ar atrage privirea de pe drum.
func _sky_cover() -> void:
	const W := 512
	const H := 256
	var img := Image.create(W, H, false, Image.FORMAT_RGB8)
	for y in H:
		var fy := float(y) / float(H)
		# 0 la orizont -> 1 la zenit. Norii se aduna sus.
		var alt := clampf(1.0 - fy * 2.0, 0.0, 1.0)
		for x in W:
			var fx := float(x) / float(W)
			# Trei valuri suprapuse cu perioade neintregi = tipar care nu se
			# repeta vizibil pe circumferinta.
			var n := sin(fx * TAU * 3.0 + fy * 7.0) * 0.5 \
				+ sin(fx * TAU * 7.0 - fy * 11.0) * 0.3 \
				+ sin(fx * TAU * 13.0 + fy * 5.0) * 0.2
			# smoothstep larg: margini moi, ca de nor de desert, nu contur taiat.
			#
			# ATENTIE la sens: sky_cover se ADUNA peste gradientul cerului, deci
			# textura trebuie sa fie NEAGRA acolo unde nu-s nori. Cu fond alb,
			# cerul iese complet spalat (verificat).
			var cloud := smoothstep(0.35, 0.90, n * 0.5 + 0.5) * alt
			img.set_pixel(x, y, Color(cloud, cloud, cloud))
	var path := "res://assets/textures/sky_cover.png"
	if img.save_png(path) != OK:
		push_error("Nu am putut scrie " + path)
		return
	print("  sky_cover.png  (%dx%d, nori pentru cer)" % [W, H])


## Masca de intensitate a detaliului, 32x1 RGBA. Alfa per slot; culoarea e alba
## peste tot (conteaza doar canalul alfa).
##
## Se importa FARA compresie si FARA mipmap-uri: BC1 are alfa pe un bit si ar
## distruge treptele, iar mipmap-urile ar amesteca sloturile vecine.
func _write_detail_mask(path: String) -> void:
	const STRENGTH := {
		0: 1.00, 1: 1.00, 2: 1.00,   # nisip
		3: 1.00, 4: 1.00,            # roca — aici conteaza cel mai mult
		5: 0.55, 6: 0.55,            # asfalt: uzura, dar sa ramana lizibil
		7: 0.35,                     # bordura: marcaj, nu suprafata naturala
		8: 0.75,                     # beton
		9: 0.85,                     # lemn: fibra
		10: 0.70,                    # metal ruginit
		11: 0.30,                    # metal vopsit: aproape curat
		12: 0.45, 13: 0.45,          # vegetatie
		14: 0.0, 15: 0.0, 16: 0.0,   # ACCENTE MASINI — raman imaculate
		# --- Mediu insular (17..23) ---
		17: 0.30, 18: 0.25,          # apa: detaliul de roca ar face-o sa arate ca noroi
		19: 1.00,                    # nisip coraligen
		20: 1.00,                    # bazalt — la fel ca roca, aici conteaza
		21: 0.45,                    # vegetatie tropicala, ca 12/13
		22: 0.20,                    # spuma: cea mai curata suprafata din decor
		23: 0.55,                    # olane: manufacturate, dar cu uzura
	}
	var img := Image.create(Palette.SLOTS, 1, false, Image.FORMAT_RGBA8)
	for slot in Palette.SLOTS:
		var a: float = STRENGTH.get(slot, 1.0)
		img.set_pixel(slot, 0, Color(1.0, 1.0, 1.0, a))
	if img.save_png(path) != OK:
		push_error("Nu am putut scrie " + path)
		return
	print("  %s  (%dx1, alfa per slot)" % [path.get_file(), Palette.SLOTS])


## Ca _write_tileable, dar cu latura configurabila si cu statistici tiparite.
##
## Media conteaza: textura se INMULTESTE peste albedo, deci o medie de 0.86
## intuneca toata lumea cu 14% si cere recalibrarea expunerii (style_bible §5).
func _write_tileable_n(path: String, n: int, noise: Callable) -> void:
	var img := Image.create(n, n, true, Image.FORMAT_RGB8)
	var lo := 1.0
	var hi := 0.0
	var sum := 0.0
	for y in n:
		for x in n:
			var v := clampf(1.0 + float(noise.call(x, y)), 0.0, 1.0)
			lo = minf(lo, v)
			hi = maxf(hi, v)
			sum += v
			img.set_pixel(x, y, Color(v, v, v))
	if img.save_png(path) != OK:
		push_error("Nu am putut scrie " + path)
		return
	print("  %s  (%dx%d, min %.2f  max %.2f  medie %.2f)"
		% [path.get_file(), n, n, lo, hi, sum / float(n * n)])


## Texturi TILEABILE pentru suprafetele mari (teren, asfalt).
##
## Atlasul rezolva prop-urile, dar nu si terenul: o suprafata de sute de m² care
## esantioneaza un singur punct din atlas ramane o pata plata, oricat de texturat
## ar fi punctul ala. Suprafetele mari au nevoie de tiling real.
##
## Sunt gri-scale si se inmultesc peste albedo-ul din _flat_material, deci NU
## aduc culori noi si nu strica paleta — doar rup uniformitatea. Un singur
## material per suprafata, deci zero draw call-uri in plus.
func _surface_textures() -> void:
	# Deviatiile sunt NEGATIVE (centrul e alb, vezi _write_tileable): textura
	# adauga umbra, nu lumina.
	#
	# Amplitudinile au fost initial foarte mici (0.09 / 0.13), din teama de zgomot
	# vizual la viteza. Masurat pe poza de sofer, contributia lor era practic
	# nula: nisipul dadea deviatie 1.48, adica sub un nivel de luminanta. Doua
	# cauze care se adunau — amplitudine mica SI compresie BC1 care turteste
	# blocurile de 4x4 (reparata in .import cu high_quality). Dublate acum, cu
	# masuratoarea ca arbitru, nu impresia.
	_write_tileable("res://assets/textures/surface_sand.png",
		func(x: int, y: int) -> float:
			# granulatie fina + dune foarte lente
			var grain := -rng.randf() * 0.20
			var dune := (sin(float(x) * 0.049
				+ sin(float(y) * 0.024) * 2.0) - 1.0) * 0.06
			return grain + dune)
	_write_tileable("res://assets/textures/surface_asphalt.png",
		func(x: int, y: int) -> float:
			# pietris: granulatie grosiera, cu pietre rare mai inchise
			var grain := -rng.randf() * 0.26
			if rng.randf() < 0.02:
				grain -= 0.16
			return grain)


## Scrie o textura gri de 128x128 in care `noise` da deviatia fata de ALB.
##
## Centrul e 1.0, nu 0.5: textura se INMULTESTE peste albedo, deci un gri mediu
## ar intuneca totul cu 50% si ar spala culoarea (nisipul cald #D8A86A ar vira
## spre gri-maroniu). Cu centrul in alb, textura doar moduleaza — culoarea din
## paleta ramane cea din style_bible.
func _write_tileable(path: String, noise: Callable) -> void:
	const N := 128
	var img := Image.create(N, N, true, Image.FORMAT_RGB8)
	for y in N:
		for x in N:
			var v := clampf(1.0 + float(noise.call(x, y)), 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	if img.save_png(path) != OK:
		push_error("Nu am putut scrie " + path)
		return
	print("  %s  (%dx%d, gri, tileabila)" % [path.get_file(), N, N])


## Umple un slot cu textura potrivita rolului lui.
func _fill_slot(img: Image, slot: int) -> void:
	var base := _base_color(slot)
	var x0 := slot * SLOT_W
	for y in HEIGHT:
		for x in range(x0, x0 + SLOT_W):
			var local_x := x - x0
			var c := base
			# Marginile raman curate — vezi PAD.
			if local_x >= PAD and local_x < SLOT_W - PAD:
				c = _texture_for(slot, base, local_x, y)
			img.set_pixel(x, y, c)


## Culoarea de baza a slotului. Sloturile fara culoare definita (24..31, rezerva)
## raman magenta, ca o greseala de UV sa sara in ochi imediat. Garda s-a ingustat
## de la 17..31 cand mediul insular a ocupat 17..23 — dar exista in continuare.
func _base_color(slot: int) -> Color:
	if slot < Palette.HEX.size():
		return Palette.color(slot)
	return Color(1.0, 0.0, 1.0)


## Textura per rol. Amplitudinile sunt mici intentionat (±4-8%): scopul e sa
## rupa suprafata plata, nu sa atraga atentia. La 60 km/h, o variatie mai mare
## devine zgomot vizual si strica citirea liniei de curs.
func _texture_for(slot: int, base: Color, x: int, y: int) -> Color:
	match slot:
		Palette.SAND_LIGHT, Palette.SAND_MID, Palette.SAND_SHADOW:
			return _sand(base, x, y)
		Palette.ROCK_LIGHT, Palette.ROCK_DARK:
			return _rock(base, x, y)
		Palette.ASPHALT, Palette.ASPHALT_EDGE:
			return _asphalt(base, x, y)
		Palette.CONCRETE:
			return _concrete(base, x, y)
		Palette.WOOD_WEATHERED:
			return _wood(base, x, y)
		Palette.RUST_METAL:
			return _rust(base, x, y)
		Palette.PAINTED_METAL:
			return _painted(base, x, y)
		Palette.CACTUS_GREEN, Palette.DRY_VEGETATION, Palette.TROPICAL_GREEN:
			return _vegetation(base, x, y)
		Palette.CORAL_SAND:
			return _sand(base, x, y)
		Palette.REEF_SHALLOW, Palette.SEA_DEEP, Palette.FOAM_WHITE:
			return _water(base, x, y)
		Palette.VOLCANIC_BLACK:
			return _volcanic(base, x, y)
		Palette.TILE_TERRACOTTA:
			return _tile(base, x, y)
		_:
			# Accentele de masina (14-16) raman plate: masinile trebuie sa fie
			# cele mai saturate si mai curate suprafete din cadru (style_bible §1).
			return base


## Nisip: granulatie fina, cu valuri foarte lente peste ea. Fara granulatie,
## dunele arata ca plastic turnat.
func _sand(base: Color, x: int, y: int) -> Color:
	var grain := (rng.randf() - 0.5) * 0.08
	var ripple := sin(float(y) * 0.09 + float(x) * 0.4) * 0.022
	return _shade(base, grain + ripple)


## Roca: straturi ORIZONTALE (style_bible §3 — stanca sedimentara, niciodata
## zimtata), cu granulatie peste. Straturile sunt semnatura falezelor de canion.
func _rock(base: Color, x: int, y: int) -> Color:
	# Grosime neregulata de strat: doua sinusuri necomensurabile, ca sa nu se
	# vada perioada.
	var strata := sin(float(y) * 0.075) * 0.5 + sin(float(y) * 0.031) * 0.5
	var band := smoothstep(-0.25, 0.25, strata) * 0.09 - 0.045
	var grain := (rng.randf() - 0.5) * 0.05
	# Crapaturi rare, orizontale.
	var crack := 0.0
	if fposmod(float(y) * 0.075, TAU) < 0.16:
		crack = -0.07
	return _shade(base, band + grain + crack)


## Asfalt: granulatie grosiera. Ramane cea mai INCHISA suprafata continua din
## scena (style_bible §1), deci variatia trage mai mult in jos decat in sus.
func _asphalt(base: Color, x: int, y: int) -> Color:
	var grain := (rng.randf() - 0.62) * 0.10
	# pete rare de uzura, mai deschise
	if rng.randf() < 0.012:
		grain += 0.06
	return _shade(base, grain)


func _concrete(base: Color, x: int, y: int) -> Color:
	var grain := (rng.randf() - 0.5) * 0.05
	var mottle := sin(float(y) * 0.05 + float(x) * 0.7) * 0.018
	return _shade(base, grain + mottle)


## Lemn: fibra VERTICALA (de-a lungul scandurii), cu noduri rare.
func _wood(base: Color, x: int, y: int) -> Color:
	var fiber := sin(float(x) * 2.1 + sin(float(y) * 0.02) * 1.5) * 0.035
	var grain := (rng.randf() - 0.5) * 0.03
	return _shade(base, fiber + grain)


## Metal ruginit: pete neregulate, mai inchise jos (apa se scurge in jos).
func _rust(base: Color, x: int, y: int) -> Color:
	var blotch := sin(float(y) * 0.041 + float(x) * 0.9) \
		* cos(float(y) * 0.017) * 0.06
	var grain := (rng.randf() - 0.5) * 0.05
	var vertical := (float(y) / float(HEIGHT) - 0.5) * -0.04
	return _shade(base, blotch + grain + vertical)


## Metal vopsit: aproape curat, doar o urma de decolorare. E singura suprafata
## de decor care are voie sa arate ingrijita.
func _painted(base: Color, x: int, y: int) -> Color:
	var streak := sin(float(x) * 1.3) * 0.012
	return _shade(base, streak + (rng.randf() - 0.5) * 0.02)


## Vegetatie: pestrita, cu jumatatea de jos mai inchisa (style_bible §4).
func _vegetation(base: Color, x: int, y: int) -> Color:
	var speckle := (rng.randf() - 0.5) * 0.09
	var vertical := (float(y) / float(HEIGHT) - 0.5) * -0.06
	return _shade(base, speckle + vertical)


## Zgomot determinist din POZITIE, nu din rng — folosit doar de sloturile
## insulare (17..23).
##
## Motivul nu e estetic, e de reproductibilitate. `rng` e un flux secvential
## partajat: _fill_slot il consuma pentru sloturile 0..31, iar DUPA bucla,
## _surface_textures() si _detail_textures() continua din starea ramasa. Prima
## versiune a sloturilor insulare chema rng.randf() si a deplasat fluxul cu
## cateva mii de extrageri — consecinta a fost ca detail_rock.png,
## surface_sand.png si surface_asphalt.png au iesit DIFERITE, desi nimeni nu le
## atinsese. Adica: adaugarea unei culori regenera texturile pe care sunt
## calibrate masuratorile din style_bible §14, pentru toate cele 4 piste.
##
## Cu hash pozitional, un slot nou nu mai poate perturba nimic din afara lui.
func _hash01(x: int, y: int, salt: int) -> float:
	var h := (x * 374761393) ^ (y * 668265263) ^ (salt * 2147483647)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xFFFFFF) / float(0x1000000)


## Apa si spuma: unde vals lente, FARA granulatie.
##
## Granulatia (care e semnatura nisipului si a rocii) face apa sa arate ca noroi
## — de-asta nu reciclam _sand aici. Doua sinusuri necomensurabile pe verticala
## dau ondulatie fara perioada vizibila. Amplitudine mica: suprafata mare de apa
## e fundal, nu subiect.
func _water(base: Color, x: int, _y: int) -> Color:
	var swell := sin(float(x) * 0.55) * 0.5 + sin(float(x) * 0.23) * 0.5
	return _shade(base, swell * 0.030)


## Bazalt: ciupituri, NU straturi orizontale.
##
## _rock() face stanca sedimentara — semnatura falezelor de canion, corecta
## pentru gresie. Bazaltul de recif e vezicular: gaurit de bule de gaz, fara
## nicio stratificatie. Reciclarea lui _rock ar face insula sa arate ca desertul
## vopsit in gri. Abatere de la style_bible §3 ("roca stratificata, niciodata
## zimtata") asumata: regula acopera roca sedimentara, nu lava.
func _volcanic(base: Color, x: int, y: int) -> Color:
	var pit := 0.0
	if _hash01(x, y, 1) < 0.06:
		pit = -0.10
	# Pete lente: bazaltul se decoloreaza in placi, nu uniform.
	var mottle := sin(float(y) * 0.033 + float(x) * 1.1) \
		* cos(float(y) * 0.019) * 0.045
	var grain := (_hash01(x, y, 2) - 0.5) * 0.05
	return _shade(base, pit + mottle + grain)


## Olane: nervuri VERTICALE (de-a lungul pantei acoperisului), regulate.
##
## Spre deosebire de lemn, unde fibra e neregulata, olanele sunt manufacturate:
## nervura e curata si periodica. Asta le si diferentiaza citirea de la distanta.
func _tile(base: Color, x: int, y: int) -> Color:
	var rib := sin(float(x) * 1.6) * 0.045
	# Rosturile de mortar, orizontale si rare.
	var joint := 0.0
	if fposmod(float(y), 42.0) < 2.0:
		joint = -0.05
	var grain := (_hash01(x, y, 3) - 0.5) * 0.025
	return _shade(base, rib + joint + grain)


## Aplica o deviatie de luminozitate pastrand nuanta. Lucreaza in HSV ca sa nu
## se "spele" culoarea la valori mari, cum s-ar intampla adunand direct in RGB.
func _shade(base: Color, delta: float) -> Color:
	var v := clampf(base.v + delta, 0.0, 1.0)
	return Color.from_hsv(base.h, base.s, v, 1.0)
