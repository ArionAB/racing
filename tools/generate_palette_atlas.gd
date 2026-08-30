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
## 20260802 a fost SEED_SURFACE, retras odata cu #132 (suprafetele vin acum din
## fotografii). Numarul NU se refoloseste pentru alt artefact: semintele sunt
## identitatea unui rezultat reproductibil, iar reciclarea unuia ar face un
## artefact viitor sa depinda tacit de istoria altuia.
const SEED_SLOTS: int = 20260801
const SEED_DETAIL: int = 20260803
const SEED_TRIM: int = 20260804
const SEED_DECAL: int = 20260805

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
	#
	# surface_sand.png si surface_asphalt.png nu se mai genereaza aici: din #132
	# vin din fotografii, prin tools/process_class_textures.gd (modul GRI).
	# Scoaterea lor NU misca nimic altceva, si asta e tocmai meritul re-semanarii
	# per artefact introduse dupa accidentul din nota lui `_hash01`: fara ea,
	# fiecare artefact ar fi continuat din starea lasata de precedentul, iar
	# stergerea unui pas ar fi regenerat detail_rock.png si trim_rock.png —
	# adica exact texturile pe care sunt calibrate cifrele din style_bible §14.
	rng.seed = SEED_DETAIL
	_detail_textures()
	rng.seed = SEED_TRIM
	_trim_rock()
	rng.seed = SEED_DECAL
	_decal_tracks()
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
			# Strate orizontale de DOUA grosimi, nu una: benzi late (~0.4 m la
			# scara de joc) peste care se suprapun unele fine. O singura frecventa
			# arata ca un cod de bare — verificat in vederea soferului.
			#
			# GROSIME NEREGULATA, nu doar linie ondulata. Versiunea anterioara
			# avea 7+17 dungi perfect periodice pe Y, doar deplasate pe X — de la
			# camera de joc citea ca biome-ul Badlands din Minecraft, dungi egale
			# la nesfarsit ("parca am facut racing in Minecraft", feedback
			# direct). Faza pe Y e acum modulata de un al doilea sinus
			# necomensurabil: benzile isi schimba grosimea de-a lungul peretelui,
			# ca sedimentarea reala. Amplitudinea dungilor fine scade si ea —
			# ele erau jumatate din efectul de cod de bare.
			var warp := sin(fx * TAU * 2.0) * 0.35 + sin(fx * TAU * 5.0) * 0.12
			var wobble := sin(fy * TAU * 1.7 + fx * TAU) * 0.9
			# Amplitudini RIDICATE in august 2026 (upgrade-ul grafic, val 4a):
			# sigma masurat pe faleza era ~6-9 fata de ~36-40 in referintele
			# BBR2/RR3 — suprafetele noastre erau de ~5x mai uniforme. Media
			# texturii ramane ~0.93 (offset-ul de la final compenseaza), ca sa nu
			# se clatine nici expunerea calibrata, nici WATER_GAIN (apa
			# esantioneaza aceeasi textura pentru ondulatie).
			var band := smoothstep(-0.35, 0.35,
				sin(fy * TAU * 6.0 + warp + wobble)) * -0.32
			var fine := smoothstep(-0.6, 0.6,
				sin(fy * TAU * 13.0 + warp * 1.7 + wobble * 1.9)) * -0.10
			# Pete lente: rup repetitia tiling-ului, care altfel se vede ca un
			# tipar regulat pe suprafetele mari.
			var macro := sin(float(x) * 0.021) * cos(float(y) * 0.017) * 0.10
			# Crapaturi verticale rare: taie benzile orizontale din loc in loc,
			# ca roca sa citeasca a blocuri individuale, nu a tapet cu dungi —
			# trucul "fiecare piatra e citibila" din BBR2, la scara noastra.
			var crack := -0.30 * pow(maxf(0.0,
				sin(fx * TAU * 9.0 + sin(fy * TAU * 2.3) * 1.4)), 24.0)
			# Granulatie: detaliul de aproape, cel care se pierde primul daca e
			# prea slab. Nu cobori sub 0.14 — sub atat, compresia il mananca.
			var grain := -rng.randf() * 0.20
			return band + fine + macro + crack + grain + 0.305)

	_sky_cover()
	# Masca per slot: cat de tare bate detaliul pe fiecare rol din paleta.
	# Slotul devine astfel canal de autorat — nisipul si roca primesc tot, iar
	# accentele de masina NIMIC (style_bible §1: masinile raman cele mai curate
	# suprafete din cadru, ca sa se desprinda de fundal).
	_write_detail_mask("res://assets/textures/detail_mask.png")
	_detail_tuff()


## Trim sheet-ul de ROCA — prima textura COLOR de clasa (upgrade grafic, val 4b).
##
## Diagnosticul BBR2: in referinte fiecare piatra e citibila individual — are
## nuanta ei, mortar intunecat in jur si un highlight pe muchia de sus (bevel
## FALS, pictat). Atlasul de paleta nu poate da asta: sloturile sunt patch-uri
## de 16px esantionate intr-un punct.
##
## Textura e TILEABILA si se aplica TRIPLANAR pe clasa de roca (faleze, butte,
## arcada, bolovani) prin Palette.rock_material() — NU prin UV unwrap per
## asset. Motivul: unwrap-ul ar sparge contractul de UV-uri colapsate din
## dio_lib si ar cere re-exportul tuturor GLB-urilor; triplanar-ul in spatiul
## lumii da acelasi rezultat vizual, tine benzile CONTINUE peste sectiunile
## vecine de faleza si nu se intinde cu scalarea instantelor (±18%).
##
## Culorile vin din paleta (ROCK_LIGHT/ROCK_DARK/SAND_SHADOW) — nu introduce
## nuante noi, doar le distribuie ca sedimentare cu variatie per bloc.
func _trim_rock() -> void:
	const N := 512
	const BANDS := 7
	var rock_light := Palette.color(Palette.ROCK_LIGHT)
	var rock_dark := Palette.color(Palette.ROCK_DARK)
	var sand_shadow := Palette.color(Palette.SAND_SHADOW)
	var img := Image.create(N, N, true, Image.FORMAT_RGB8)
	for y in N:
		var fy := float(y) / float(N)
		for x in N:
			var fx := float(x) / float(N)
			# Granita benzilor, ondulata periodic (tileabil pe ambele axe).
			var warp := sin(fx * TAU * 2.0) * 0.16 + sin(fx * TAU * 5.0) * 0.05
			var band_pos := fy * float(BANDS) + warp
			var band := wrapi(int(floorf(band_pos)), 0, BANDS)
			var in_band := band_pos - floorf(band_pos)
			# Valori deterministe per banda (LCG mic, ca in dio_lib.rock).
			var h := (band * 1103515245 + 12345) & 0x7FFFFFFF
			var mix_v := float(h % 1000) / 999.0
			h = (h * 1103515245 + 12345) & 0x7FFFFFFF
			var joints := 4 + h % 4 # blocuri per banda: 4..7 (intreg => tileabil)
			h = (h * 1103515245 + 12345) & 0x7FFFFFFF
			var joint_off := float(h % 1000) / 999.0
			# Baza benzii: intre rock_dark si rock_light, cu media impinsa spre
			# deschis — fetele de stanca stau in plin soare, iar intunericul real
			# il aduc AO-ul din vertex colors si mortarul, nu baza. O banda din
			# ~4 trage spre sand_shadow (nisip prins intre strate) si una spre
			# aproape-rock_light plin: contrastul dintre benzi vinde sedimentarea
			# de la distanta, unde mortarul nu se mai vede.
			var base := rock_dark.lerp(rock_light, 0.45 + 0.55 * mix_v)
			if band % 4 == 2:
				base = base.lerp(sand_shadow, 0.55)
			elif band % 4 == 0:
				base = base.lerp(rock_light, 0.5)
			# Blocuri: nuanta per PIATRA — asta e diferenta fata de un gradient.
			var block_pos := fx * float(joints) + joint_off
			var block := int(floorf(block_pos))
			var in_block := block_pos - floorf(block_pos)
			var bh := ((band * 31 + block) * 1103515245 + 12345) & 0x7FFFFFFF
			var stone_v := 0.90 + (float(bh % 1000) / 999.0) * 0.18
			bh = (bh * 1103515245 + 12345) & 0x7FFFFFFF
			var stone_warm := 0.97 + (float(bh % 1000) / 999.0) * 0.06
			var c := Color(base.r * stone_v * stone_warm, base.g * stone_v,
				base.b * stone_v / stone_warm)
			# Rosturi verticale: mortar intunecat + muchie luminata (bevel fals).
			var jw := 0.030
			if in_block < jw:
				c *= 0.58
			elif in_block < jw * 2.2:
				c *= 1.10
			# Granita orizontala dintre benzi: mortar sus, highlight sub el —
			# muchia de sus a fiecarui strat "prinde soarele".
			if in_band < 0.055:
				c *= 0.55
			elif in_band < 0.14:
				c *= 1.14
			# Granulatie fina, ca sa nu fie suprafete perfect netede intre rosturi.
			var grain := 1.0 - rng.randf() * 0.10
			c *= grain
			img.set_pixel(x, y, Color(clampf(c.r, 0.0, 1.0),
				clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0)))
	var path := "res://assets/textures/trim_rock.png"
	if img.save_png(path) != OK:
		push_error("Nu am putut scrie " + path)
		return
	print("  trim_rock.png  (%dx%d, %d benzi, color)" % [N, N, BANDS])


## Urma de cauciuc — decal-ul liniei de curse (upgrade grafic, val 4c).
##
## O SINGURA urma de roata, tileabila pe V (in lungul drumului): banda de
## cauciuc intunecat cu alpha care se stinge spre margini, rupta de goluri de
## profil (tread) si de uzura neregulata. Fasiile de geometrie din
## Track._build_tire_marks() o intind pe zonele de viraj+franare — trucul de
## nisip pictat din BBR2, aplicat pe asfaltul nostru.
##
## E SINGURA textura cu alpha real din lume (transparenta = costul pe care
## garda nu-l vede, vezi antetul din water.gdshader) — de-asta suprafata
## acoperita e mica si controlata: fasii de 0.34 m pe viraje, nu covor.
func _decal_tracks() -> void:
	const W := 64
	const H := 256
	var img := Image.create(W, H, true, Image.FORMAT_RGBA8)
	for y in H:
		var fy := float(y) / float(H)
		for x in W:
			var fx := float(x) / float(W)
			# Clopot pe latime: plin in centru, stins la margini.
			var across := sin(fx * PI)
			across *= across
			# Profilul cauciucului: dungi longitudinale.
			var tread := 0.72 + 0.28 * sin(fx * TAU * 5.0)
			# Uzura pe lungime: pete care intrerup urma (tileabil pe V).
			var wear := 0.55 + 0.45 * sin(fy * TAU * 3.0 + sin(fx * TAU) * 1.2)
			wear = clampf(wear + rng.randf() * 0.25 - 0.12, 0.0, 1.0)
			var alpha := clampf(across * tread * wear, 0.0, 1.0) * 0.55
			# Cauciuc: aproape negru, usor cald — se inmulteste vizual peste
			# asfaltul racoros si citeste ca urma arsa, nu ca banda gri.
			img.set_pixel(x, y, Color(0.07, 0.06, 0.055, alpha))
	var path := "res://assets/textures/decal_tracks.png"
	if img.save_png(path) != OK:
		push_error("Nu am putut scrie " + path)
		return
	print("  decal_tracks.png  (%dx%d, RGBA, urma de cauciuc)" % [W, H])


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
		# --- Stromboli ---
		30: 0.15,                    # lava: semnal incandescent, aproape curat —
									 # granulatia de roca peste glow l-ar murdari
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

## Stratul de detaliu al TUFULUI — varianta cu caneluri VERTICALE (Cappadocia).
##
## De ce exista o a doua textura de detaliu, si nu un retus pe prima:
## detail_rock.png are STRATE ORIZONTALE (benzi pe Y), fiindca a fost autorata
## pentru faleze sedimentare — Baikal, Stromboli, Chongqing traiesc din ea si nu
## se atinge. Pe Cappadocia insa e exact defectul pe care critica oarba l-a
## numit de doua ori: "tight, evenly-spaced horizontal contour lines ... that is
## not stratigraphy, that is a topographic map or a lathe finish".
##
## Diagnosticul care a costat doua runde: dungile NU veneau din `Builder.revolve`.
## Se vad identice pe buiandrugul arcadei — o CUTIE, deci nicio suprafata de
## revolutie — fiindca stratul de detaliu se aplica TRIPLANAR peste toata lumea.
## Rundele 1 si 2 au reparat mesh-ul, care nu era bolnav de asta.
##
## Hornul de tuf se erodeaza prin SIROIRE: apa curge in jos si sapa santuri
## verticale, deci frecventa dominanta trebuie sa fie pe X (canelura), nu pe Y
## (banda). Aici nu e o rotatie a texturii vechi: o textura rotita ar da benzi
## verticale perfect paralele, adica acelasi tapet intors pe 90°. Canelura reala
## are latimi INEGALE si se STINGE pe verticala (santul e adanc la baza, unde
## apa s-a adunat, si se pierde spre varf).
##
## Media ramane ~0.93, ca la sora ei: expunerea temei si WATER_GAIN sunt
## calibrate pe media stratului de detaliu (style_bible §14), deci o textura cu
## alta medie ar clatina toata pista, nu doar roca.
func _detail_tuff() -> void:
	_write_tileable_n("res://assets/textures/detail_tuff.png", 256,
		func(x: int, y: int) -> float:
			var fx := float(x) / 256.0
			var fy := float(y) / 256.0
			# Canelurile: frecventa dominanta pe X. Faza e modulata de Y, deci
			# santul SERPUIESTE in jos in loc sa fie o rigla — apa nu curge pe
			# linie dreapta pe un con.
			var meander := sin(fy * TAU * 1.3) * 0.55 + sin(fy * TAU * 3.1) * 0.18
			# Doua frecvente necomensurabile => santuri de LATIMI diferite. Cu una
			# singura ar iesi o roata dintata, adica exact greseala texturii
			# orizontale, doar intoarsa pe 90°.
			var flute := smoothstep(-0.40, 0.40,
				sin(fx * TAU * 7.0 + meander)) * -0.46
			var fine := smoothstep(-0.6, 0.6,
				sin(fx * TAU * 17.0 + meander * 1.6)) * -0.15
			# Santul se ADANCESTE spre baza dalei: siroirea e cumulativa in jos.
			var depth := 1.0 - 0.40 * fy
			# Pete lente, ca sa nu se vada dala repetata.
			var macro := sin(float(x) * 0.019) * cos(float(y) * 0.023) * 0.10
			# Rupturi orizontale RARE: tuful are un plan de cedare din loc in loc.
			# Rare si scurte — dese, am fi reinventat banda pe care tocmai o scoatem.
			var ledge := -0.22 * pow(maxf(0.0,
				sin(fy * TAU * 2.0 + sin(fx * TAU * 1.7) * 1.2)), 40.0)
			var grain := -rng.randf() * 0.24
			return (flute + fine) * depth + macro + ledge + grain + 0.415)


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


## Texturile TILEABILE ale suprafetelor mari (teren, sosea) au plecat de aici.
##
## Pana la #132 erau generate procedural in acest fisier: zgomot alb plus o
## sinusoida lenta, 128x128, gri, inmultite peste albedo. Din #132 vin din
## fotografii aeriene trecute prin tools/process_class_textures.gd (modul GRI),
## la 512x512, cu media SI deviatia normalizate exact la valorile de aici —
## fiindca media lor e o piesa din calibrarea de expunere (style_bible §14).
##
## Ce ramane valabil din rationamentul vechi, si de aia ramane scris: atlasul
## rezolva prop-urile, dar nu si terenul (o suprafata de sute de m² care
## esantioneaza un singur punct din atlas ramane o pata plata, oricat de
## texturat ar fi punctul ala), si texturile TREBUIE sa fie gri-scale, ca sa se
## inmulteasca peste albedo fara sa aduca vreo culoare noua.
##
## Amplitudinile procedurale au fost initial foarte mici (0.09 / 0.13), din
## teama de zgomot vizual la viteza, si masuratoarea le-a dat pe fata: nisipul
## dadea deviatie 1.48, sub un nivel de luminanta. Dublarea lor (la mediile
## 0.838 / 0.865 si sigma 0.072 / 0.078) e cifra pe care o mosteneste acum
## pipeline-ul de fotografii.


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
		Palette.ICE_TURQUOISE, Palette.ICE_DEEP:
			return _ice(base, x, y)
		Palette.ICE_CRACK:
			return _water(base, x, y)
		Palette.LARCH_RUST:
			return _vegetation(base, x, y)
		Palette.LOG_DARK:
			return _wood(base, x, y)
		Palette.MARBLE_GREY:
			return _marble(base, x, y)
		_:
			# Accentele de masina (14-16) si LAVA_ORANGE (30) raman plate:
			# accentele trebuie sa fie cele mai saturate si mai curate suprafete
			# din cadru (style_bible §1); lava isi ia viata din emisivul de
			# clasa la integrare, nu din granulatie de albedo.
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


## Gheata de Baikal: bule de metan inghetate in straturi + retea de fisuri fine.
##
## Cele doua trasaturi ale gheatii de Baikal in fotografii sunt exact astea, si
## se citesc la scari diferite: bulele sunt discuri albe de 5-15 cm prinse in
## straturi la adancimi diferite (deci se suprapun partial, cu opacitati
## diferite), iar fisurile sunt o retea fina, aproape rectilinie. Amplitudinea
## bulelor e mai mare decat la celelalte suprafete (+0.16 fata de ±0.04-0.08
## uzual): pe gheata ele SUNT desenul, nu o rupere de monotonie. Fara ele
## suprafata citeste ca sticla turnata, adica exact plasticul de care fugim.
func _ice(base: Color, x: int, y: int) -> Color:
	# Bule pe trei straturi de adancime, fiecare cu propria grila si opacitate.
	# Straturile suprapuse sunt ce da senzatia de volum transparent.
	var bub := 0.0
	for layer in 3:
		var scale := 7.0 + float(layer) * 6.0
		var fade := 0.16 - float(layer) * 0.045
		var cx := fposmod(float(x) + float(layer) * 3.7, scale) - scale * 0.5
		var cy := fposmod(float(y) + float(layer) * 11.3, scale) - scale * 0.5
		var d := sqrt(cx * cx + cy * cy) / (scale * 0.30)
		if d < 1.0:
			bub += (1.0 - d * d) * fade
	# Fisuri: linii aproape drepte, rare, INTUNECATE — reteaua neagra din poze.
	var crack := 0.0
	var warp := sin(float(y) * 0.014) * 6.0
	if fposmod(float(x) + warp, 13.0) < 1.0:
		crack = -0.13
	if fposmod(float(y) + sin(float(x) * 0.03) * 9.0, 61.0) < 1.2:
		crack = -0.11
	var grain := (_hash01(x, y, 7) - 0.5) * 0.03
	return _shade(base, bub + crack + grain)


## Marmura Stancii Samanului: vene diagonale palide pe fond cenusiu.
##
## Venele sunt DIAGONALE si de doua grosimi — cele late dau silueta pietrei la
## distanta, cele fine apar abia de aproape. Orizontale ar fi citit ca strate
## sedimentare (aia e roca din _rock), iar marmura de Olkhon e masiva, nu
## stratificata: diferenta se vede exact in orientarea venei.
func _marble(base: Color, x: int, y: int) -> Color:
	var diag := float(x) * 3.0 + float(y) * 0.7
	var vein := sin(diag * 0.06 + sin(float(y) * 0.02) * 2.0)
	var wide := smoothstep(0.55, 1.0, vein) * 0.075
	var fine := smoothstep(0.80, 1.0, sin(diag * 0.19)) * 0.035
	var grain := (_hash01(x, y, 8) - 0.5) * 0.035
	return _shade(base, wide + fine + grain)


## Aplica o deviatie de luminozitate pastrand nuanta. Lucreaza in HSV ca sa nu
## se "spele" culoarea la valori mari, cum s-ar intampla adunand direct in RGB.
func _shade(base: Color, delta: float) -> Color:
	var v := clampf(base.v + delta, 0.0, 1.0)
	return Color.from_hsv(base.h, base.s, v, 1.0)
