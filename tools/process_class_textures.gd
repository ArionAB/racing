extends SceneTree
## Proceseaza texturile de CLASA din surse externe (PolyHaven / ComfyUI / orice
## PNG-JPG) in variante gata de joc: 512², gradate spre culorile paletei.
##
## De ce exista pasul asta si nu folosim sursele direct: texturile externe sunt
## fotografii, fiecare cu lumina, saturatia si temperatura ei. Puse netratate
## una langa alta, dau "asset soup" — un colaj in care nimic nu se leaga.
## Gradarea trage fiecare pixel spre ancora lui din paleta pastrand luminanta
## (deci detaliul), asa ca textura devine o EXTENSIE a paletei, nu o culoare
## straina. Sursa se schimba liber (azi PolyHaven, maine ComfyUI pictat) —
## pasul asta ramane.
##
## Al doilea mod, GRI (vezi `surfaces()`): pentru texturile MULTIPLICATIVE ale
## suprafetelor mari (teren, sosea). Alea nu aduc culoare deloc — se inmultesc
## peste albedo — deci nu se gradeaza spre o ancora, ci se desatureaza complet
## si li se normalizeaza media SI deviatia la cele ale texturilor procedurale pe
## care le inlocuiesc. Asa se schimba TIPARUL fara sa se miste expunerea.
##
## Rulare:
##   godot --headless --path . --script res://tools/process_class_textures.gd
##
## Iesire: assets/textures/classes/<clasa>.png (512x512), consumate de
## Palette.class_material(), plus assets/textures/surface_*.png.

const SRC_DIR := "res://assets/textures/classes/src/"
const OUT_DIR := "res://assets/textures/classes/"
const OUT_SIZE := 512

## Cat de tare se desatureaza sursa inainte de gradare (0..1).
const DESAT := 0.25
## Cat de tare se trage spre ancora de paleta (0..1). 0 = sursa neatinsa,
## 1 = doar luminanta sursei colorata integral in ancora.
const GRADE := 0.45

## Clasele pilotului: sursa -> ancora de paleta.
## Ancorele NU sunt decorative: ele garanteaza ca olanele raman in familia
## TILE_TERRACOTTA din style_bible §1, tencuiala in CONCRETE etc.
static func classes() -> Dictionary:
	return {
		"roof_tiles": {"src": "roof_tiles_src.jpg",
			"anchor": Palette.color(Palette.TILE_TERRACOTTA)},
		"plaster": {"src": "plaster_src.jpg",
			"anchor": Palette.color(Palette.CONCRETE)},
		"stone_wall": {"src": "stone_wall_src.jpg",
			"anchor": Palette.color(Palette.CORAL_SAND)},
		# Familia de roca a Dunelor (faleze/butte/arcada/bolovani): inlocuieste
		# continutul procedural al trim-ului, prin acelasi rock_material
		# triplanar — conversia intregului canion fara niciun re-export.
		# Gain-ul intinde contrastul: fotografia originala e plata fata de
		# trim-ul pictat, iar la distanta (mipmap) se topea in noroi — masurat,
		# sigma pe faleza cadea de la 10.3 la 8.4 fara corectie.
		"rock": {"src": "rock_src.jpg",
			"anchor": Palette.color(Palette.ROCK_LIGHT), "gain": 1.35,
			"lift": 0.06},
		# Metal ruginit: turn de apa, excavator, conducta.
		"rust_metal": {"src": "rust_metal_src.jpg",
			"anchor": Palette.color(Palette.RUST_METAL), "gain": 1.15},
		# Lemn imbatranit: turnul morii, grinzile portalului de mina, lazile.
		# Sursa: planks_brown_10 (PolyHaven CC0), ALEASA PRIN MASURATOARE dintre
		# cinci candidati, pe doua criterii care s-au dovedit amandoua decisive:
		#
		#   1. media aproape de luminanta ANCOREI (102.9 fata de 97.5). Prima
		#      incercare (weathered_planks) avea media 69 — cu 30% sub ancora —
		#      si turnul morii a iesit o silueta neagra in cadru. Gradarea
		#      pastreaza luminanta sursei prin constructie, deci o fotografie
		#      subexpusa ramane subexpusa oricat de bine ar fi gradata.
		#   2. lumina UNIFORMA pe dala. weathered_planks avea jumatatea dreapta
		#      vizibil mai inchisa decat stanga; pe o suprafata care se repeta,
		#      dezechilibrul ala devine benzi. Masurat aici: 0.4 diferenta
		#      stanga/dreapta.
		#
		# Fara gain: sursa are deja sigma 23.7, cea mai contrastata din toate
		# clasele. Ce lipsea nu era punch, era expunerea.
		"wood": {"src": "wood_src.jpg",
			"anchor": Palette.color(Palette.WOOD_WEATHERED)},
		# Beton de exterior: dala benzinariei, insula pompelor, cosul.
		# Sursa: concrete_floor_02 (PolyHaven CC0).
		#
		# `lift` mare, si e cazul in care parametrul chiar isi merita existenta:
		# ancora CONCRETE (#C8BDA9) are luminanta 190, iar NICIO fotografie de
		# beton nu trece de ~111 — betonul real e gri mediu, slotul din paleta e
		# ales deschis fiindca tine si coamele albe ale casei de sat, si fata
		# ecranului de drive-in. Fara ridicare, dala ar cobori la 0.58 din
		# ancora, cel mai intunecat raport din toate clasele, si s-ar apropia
		# periculos de asfalt — care trebuie sa ramana cea mai inchisa suprafata
		# continua (style_bible §1).
		#
		# Dezechilibrul de lumina al sursei e 5.2 pe o medie de 110 (4.7%), cel
		# mai prost din clasele de azi. Acceptat deliberat: alternativele erau
		# uniforme dar plate (sigma 6-9), iar petele si crapaturile sunt exact
		# detaliul pentru care exista clasa.
		"concrete": {"src": "concrete_src.jpg",
			"anchor": Palette.color(Palette.CONCRETE), "lift": 0.20},
		# --- Clasele insulei (Okinawa) ---
		#
		# Calcar coraligen (Ryukyu): stancile de recif si soclurile de piatra.
		# Sursa: coral_fort_wall_03 (PolyHaven CC0) — chiar zidaria de calcar
		# coraligen a castelelor din Okinawa, deci scobiturile si incluziunile
		# albe de corali sunt exact tiparul cerut, nu o aproximare.
		#
		# Ales prin masuratoare dintre sase candidati (ancora VOLCANIC_BLACK,
		# luminanta 83.9):
		#   coral_fort_wall_03  ratie 1.22  in-dala 15.57  dez 3.5/3.4  <- ales
		#   coral_ground_02     ratie 1.48  in-dala 21.86  dez 3.0/6.3
		#   gray_rocks          ratie 1.35  in-dala 14.19  dez 0.8/0.2
		#   dark_rock           ratie 0.34  in-dala  2.72  dez 0.1/0.9
		# `dark_rock` era cel mai aproape de ancora la CULOARE si complet PLAT —
		# exact capcana descrisa in style_bible §4. coral_ground_02 avea cea mai
		# buna structura, dar 6.3% dezechilibru pe verticala, peste pragul de 5%
		# de la care repetitia da benzi. gray_rocks era cel mai uniform, dar e o
		# dala de PIETRIS: pe un bolovan de 2 m ar citi ca prundis lipit.
		#
		# `lift` NEGATIV, primul din pipeline: sursa e cu 22% peste ancora, iar
		# stancile de recif trebuie sa ramana partea inchisa a paletei insulare
		# (bazaltul e contrastul fata de nisipul coraligen). Fara el, plaja si
		# stanca ies la aceeasi valoare si silueta se pierde.
		"coral_rock": {"src": "coral_rock_src.jpg",
			"anchor": Palette.color(Palette.VOLCANIC_BLACK), "gain": 1.10,
			"lift": -0.05},
		# Scoarta tropicala: trunchiuri de palmier, tulpini de pandanus,
		# radacinile aeriene ale banyanului. Sursa: palm_tree_bark (PolyHaven
		# CC0), o scanare de 1.3 m de trunchi — deci inelele de cicatrici cad la
		# scara reala pe o proiectie cubica de 1.3 m.
		#
		# Masurat (ancora WOOD_WEATHERED, luminanta 97.4):
		#   palm_tree_bark        ratie 1.49  in-dala 17.74  dez 2.7/4.6  <- ales
		#   bark_brown_02         ratie 0.88  in-dala 19.09  dez 5.3/3.3
		#   japanese_camphor_bark ratie 1.42  in-dala 15.61  dez 1.7/1.2
		#   palm_bark             ratie 0.81  in-dala  5.22  dez 7.7/0.3
		# `palm_bark`, cel cu numele potrivit, pica pe amandoua criteriile: sub
		# 0.85 din ancora (silueta intunecata, cazul turnului de moara) si 7.7%
		# dezechilibru pe orizontala. Miniatura nu spunea nimic din toate astea.
		#
		# Ratia 1.49 NU se corecteaza in jos: trunchiul de cocotier chiar e
		# palid-cenusiu, iar gradarea spre WOOD_WEATHERED il aduce oricum in
		# familia de maro a paletei. Dez.y 4.6% e sub prag, dar la limita — daca
		# apar benzi pe trunchiurile lungi, aici se cauta.
		"bark": {"src": "bark_src.jpg",
			"anchor": Palette.color(Palette.WOOD_WEATHERED)},
		# --- Clasele muntelui (Alpii) ---
		#
		# Granit alpin: stancile de pe flancuri si brauri, plus bolovanii din
		# benzile de decor. Sursa: castle_wall_slates (PolyHaven CC0) — sisturi
		# stratificate, adica exact tiparul geologic al unui masiv alpin, spre
		# deosebire de gresia sedimentara a canionului.
		#
		# Ales prin masuratoare dintre trei candidati (ancora CONCRETE,
		# luminanta 190):
		#   castle_wall_slates  ratie 0.67  in-dala 23.27  dez 3.2/2.3  <- ales
		#   aerial_rocks_02     ratie 0.49  in-dala 15.09  dez 0.2/1.9
		#   dark_rock           ratie 0.15  in-dala  2.74  dez 0.1/0.9
		#
		# `dark_rock` a fost prima alegere DUPA NUME si dupa miniatura — "rocă
		# întunecată" suna a granit — si a picat catastrofal: 0.15 din ancora
		# (de cinci ori sub pragul de 0.85 care a produs turnul de moara negru)
		# si complet PLAT, in-dala 2.74. Merita notat ca a fost respins din
		# aceleasi motive si la Okinawa, cu alta ancora: e o fotografie de
		# stanca uda in umbra, nu de granit.
		#
		# `lift` pozitiv, ca la beton si din acelasi motiv: ancora CONCRETE e
		# aleasa deschis, iar nicio fotografie de piatra nu ajunge la 190.
		# Gainul ridica contrastul stratificarii, care E semnatura clasei.
		"alpine_granite": {"src": "alpine_granite_src.jpg",
			"anchor": Palette.color(Palette.CONCRETE), "gain": 1.20,
			"lift": 0.12},
		# Zapada: masa avalansei. Sursa: snow_03 (PolyHaven CC0).
		#
		# Ales prin masuratoare dintre doi candidati (ancora FOAM_WHITE,
		# luminanta 239.1 — cea mai deschisa ancora din paleta):
		#   snow_03  ratie 0.65  in-dala 40.7  neuniformitate 6.34  <- ales
		#   snow_02  ratie 0.69  in-dala  8.9  neuniformitate 3.13
		#
		# `snow_02` e de doua ori mai descarcat pe PolyHaven si vizibil mai
		# „curat" in miniatura — si e exact capcana din CLAUDE.md: in-dala 8.9
		# inseamna o suprafata aproape PLATA, adica fix diagnosticul pentru care
		# exista clasele („deviatie ~2.7 la noi vs ~36-40 la referinta").
		# `snow_03` e zapada murdara, cu urme si cruste, si sta in banda tinta.
		#
		# Neuniformitatea de 6.34 e cea mai mare din pipeline si e ACCEPTATA
		# deliberat, spre deosebire de cazul lemnului unde a fost motiv de
		# respingere. Diferenta e ce poarta textura: o dala de scanduri se
		# repeta pe un turn de 8 m si dezechilibrul devine benzi orizontale
		# vizibile. Aici dala sta pe un corp de 7 m care SE ROSTOGOLESTE — nu
		# exista „sus" si „jos" stabile pe care sa se aseze o banda, iar petele
		# sunt chiar ce face rotatia lizibila. O zapada perfect uniforma pe o
		# sfera care se invarte arata identic cu una care sta pe loc.
		#
		# `lift` mare, cel mai mare din pipeline, si e cazul beton/granit dus la
		# capat: ancora e la 239 din 255, iar nicio fotografie de zapada reala nu
		# trece de ~155 (zapada in lumina zilei e gri mediu, nu alba — o vede
		# alba doar ochiul, prin adaptare). Fara ridicare, masa ar iesi la 0.65
		# din ancora, adica GRI, si ar concura cu granitul in loc sa iasa din el.
		"snow": {"src": "snow_src.jpg",
			"anchor": Palette.color(Palette.FOAM_WHITE), "gain": 1.10,
			"lift": 0.26},
		# Marmura Olkhonului (Baikal): Stanca Samanului, arcul grotei, faleza
		# insulei si peretii de stanca asezati de mana la grota.
		# Sursa: marble_cliff_04 (PolyHaven CC0), ALEASA PRIN MASURATOARE
		# dintre cinci candidati de marmura, ancora MARBLE_GREY (luminanta
		# 180.3):
		#
		#   marble_cliff_04  ratie 0.93  in-dala 18.9  dez 1.4/5.5  12.7 m  <-
		#   marble_cliff_06  ratie 0.70  in-dala 23.1  dez 6.0/6.4   8.1 m
		#   marble_cliff_03  ratie 0.72  in-dala 13.6  dez 7.0/0.6   5.7 m
		#   marble_cliff_02  ratie 0.66  in-dala 21.7  dez 1.9/8.8   6.8 m
		#   marble_rock_03   ratie 0.48  in-dala 13.2  dez 1.1/4.5   1.8 m
		#
		# Ultima coloana e SCARA REALA a sursei, si aici a decis: piesele pe
		# care cade clasa au 12-22 m (coltii Samanului 18 m, arcul grotei 12 m
		# deschidere), deci o dala de 1.8 m ar fi trebuit repetata de zece ori
		# pe o fata — adica exact esecul din #313, cand dala alpina (2 m,
		# fotografie de ZID de piatra uscata) a facut din coltii de marmura o
		# cetate. La 12.7 m sursa acopera aproape toata fata dintr-o singura
		# repetitie, iar ce se vede sunt vinele si stratele ei, nu un tipar.
		# Ratia de 0.93 fata de ancora e cea mai buna din pipeline: marmura
		# alba in soare e singura piatra care ajunge la luminanta unui slot
		# deschis, deci nu are nevoie nici de `lift`, nici de `gain`.
		"olkhon_marble": {"src": "olkhon_marble_src.jpg",
			"anchor": Palette.color(Palette.MARBLE_GREY)},
		# Gheata Baikalului (placa lacului si banda drumului de gheata): a doua
		# clasa PICTATA, tools/paint_ice.py — retea de crapaturi negre pe tor,
		# bule de metan albe in ciorchini, fond turcoaz cu pete. Ancora e
		# recifului (REEF_SHALLOW): singurul turcoaz din paleta, si e chiar
		# culoarea ghetii de lac vazute prin grosime mica.
		# Ancora e recifului AMESTECAT cu spuma (nu recif pur): la ancora pura
		# lacul iesea turcoaz de bazin pe toata suprafata; gheata de lac e
		# aproape alba, cu tenta rece, iar culoarea o da adancimea (vertex).
		"ice": {"src": "ice_src.png",
			"anchor": Palette.color(Palette.REEF_SHALLOW).lerp(
				Palette.color(Palette.FOAM_WHITE), 0.5), "gain": 1.05},
		# Acele coniferelor: coroana molizilor din kitul alpin (#222). Singura
		# clasa PICTATA, nu fotografiata — sursa e generata de
		# tools/paint_pine_needles.py, si acolo sta si motivul: o fotografie de
		# crengi are adancime, iar proiectata triplanar pe un con citeste ca
		# tapet. Masurat pe sursa: medie 91 (ratie 0.86 fata de CACTUS_GREEN,
		# 106), in-dala 26.6, dezechilibru 0.8%/0.8%. `gain` 1.2 + `lift` 0.10
		# duc media la ~1.1x ancora, DELIBERAT peste: coroana primeste in joc
		# AO copt cu `low` 0.30 plus gradientul de baza (0.46), deci vertex
		# color-ul o inchide oricum; la lift 0.05 padurea iesea uniform
		# intunecata pe captura de sofer, fara varfurile luminate care
		# separa un molid de urmatorul.
		"pine_needles": {"src": "pine_needles_src.png",
			"anchor": Palette.color(Palette.CACTUS_GREEN), "gain": 1.20,
			"lift": 0.10},
	}
	# NU exista clasa "chalet_wood", si e o decizie, nu o omisiune.
	#
	# Sursa era descarcata si masurata (dark_planks, PolyHaven CC0: ratie 0.50,
	# in-dala 6.22) cand s-a verificat UNDE ar ateriza — si raspunsul a fost
	# "nicaieri, fara pagube". Fiecare cladire alpina din kitul #226 e UN SINGUR
	# mesh cu toate suprafetele pe atlas (tencuiala, olane, ferestre, grinzi in
	# sloturi diferite ale aceleiasi dale). O clasa triplanara se aplica pe tot
	# subarborele, deci ar fi intins scandurile PESTE acoperisul rosu si peste
	# ferestre. La fel stiva de lemne, care isi are capetele de bustean
	# retag-uite ca accent deschis.
	#
	# Lemnul cu textura reala cere ce cere si `village_house`: parti NUMITE in
	# GLB si UV-uri reale, adica re-export din Blender. Cand se face asta,
	# sursa e deja aleasa si masurata — vezi istoricul acestui commit.


## Texturile GRI, multiplicative, ale suprafetelor mari.
##
## `mean` e MASURAT pe texturile procedurale pe care le inlocuiesc (surface_sand
## 0.838, surface_asphalt 0.865) si reimpus aici. Nu e pedanterie: media
## texturii e o piesa din calibrarea de expunere (style_bible §14), si e
## aplicata de DOUA ori — o data pe UV1 si o data pe UV2, ca strat de detaliu —
## deci contributia ei la luminozitatea terenului e media la patrat. O sursa cu
## alta medie ar muta expunerea intregii lumi in tacere.
##
## DOUA componente, si asta e lectia masurata a issue-ului. Prima incercare a
## folosit doar fotografia, cu media SI deviatia globala normalizate la cele ale
## texturii procedurale — pe hartie o inlocuire neutra. Masurat pe poza de
## sofer, a iesit o REGRESIE: asfaltul a cazut de la sigma 2.91 la 1.69, nisipul
## de la 2.77 la 2.37. Explicatia e ca sonda din §14 masoara deviatia INAUNTRUL
## unei dale de 8 px, iar energia unei fotografii sta la frecvente JOASE — pete
## si gradiente late. Deviatia globala era aceeasi, dar mutata acolo unde nu se
## vede la viteza. Textura procedurala era aproape numai zgomot per pixel.
##
##   `sigma` — cata structura de FOTOGRAFIE (pete, crapaturi, urme de reparatii).
##             Asta aduce sursa externa si asta nu putea da o sinusoida.
##   `grain` — amplitudinea zgomotului alb, la scara de BLOC de 4 texeli, adica
##             exact rezolutia texturii procedurale de 128 pe care o inlocuieste.
##             La 512 fara blocuri, granula ar cadea la 6 mm in lume si ar fi
##             mancata de mipmap inainte sa ajunga pe ecran.
##
## O SURSA SE ALEGE SI DUPA SCARA EI REALA, nu doar dupa cum arata.
##
## Versiunea din #132 folosea fotografii AERIENE pentru amandoua suprafetele, cu
## motivatia ca un prim-plan la o repetitie de 3.1 m ar mari granula si ar citi
## ca pietris. Rationamentul e corect — dar sursele alese erau scanari de 20 m
## (nisip) si 30 m (asfalt), afisate la 3.1 si 3.5 m. Adica invers: granulatia
## reala iesea de ~8 ori PREA MICA, sub un texel, si o manca mipmap-ul complet.
## Se vedea in cifre — asfaltul masura p25..p75 de 2.76..3.60, adica aproape
## nicio variatie, desi fotografia sursa avea deviatie in-dala 8.84.
##
## Reparatia nu e "alta poza", e SEPARAREA CELOR DOUA ROLURI. Fiecare suprafata
## are acum doua texturi, fiecare cu sursa la scara ei:
##
##   micro (UV1, o repetitie la 3.1-3.5 m)  <- scanare de 2-3 m: granula de
##       nisip, agregatul din asfalt, crapaturile. Asta se vede sub roti.
##   macro (UV2, o repetitie la ~45 m)      <- aeriana de 20-30 m: pete, urme
##       de reparatii, arce de cauciuc. Asta rupe tiparul de repetitie pe
##       suprafetele mari.
##
## Sursele aeriene de dinainte NU s-au aruncat — au fost mutate in rolul lor
## corect (surface_*_macro_src.jpg), unde scara le e potrivita.
##
## EXPUNEREA SE TINE PE LOC, dar nu mereu prin acelasi mecanism. Cele doua
## treceri se INMULTESC, deci contributia lor la luminozitate e
## mean_micro * mean_macro:
##   - la NISIP produsul se pastreaza direct: erau deja doua treceri cu aceeasi
##     textura (0.850² = 0.7225), deci amandoua raman la 0.850 si nimic nu se
##     misca;
##   - la ASFALT nu se putea. Soseaua avea o singura trecere (0.865); ca a doua
##     sa nu o intunece, perechea ar fi trebuit sa aiba mediile foarte sus (0.92
##     si 0.94), iar acolo `grain` nu mai INCAPE — media plus jumatatea
##     amplitudinii trece de 1.0, varfurile se retează si media reala scade sub
##     tinta oricum (masurat: 0.920 ceruta, 0.9086 obtinuta). Asa ca acolo
##     compensarea s-a mutat unde are loc: culoarea asfaltului din
##     `Track._build_road` e impartita la media trecerii macro. Rezultatul randat
##     e acelasi, dar amandoua texturile au headroom.
##
## `grain` NU e optional si nu e un rest istoric, si asta e a doua oara cand se
## invata: prima versiune a acestei restructurari l-a taiat (0.26 -> 0.14 pe
## asfalt) pe motiv ca fotografia la scara corecta aduce ea granulatia. Masurat
## pe poza de sofer, a iesit REGRESIE — asfaltul a cazut de la σ 3.12 la 1.96,
## sub valoarea de dinaintea intregii schimbari. Deviatia in-dala a texturii
## finale spune de ce: 18.27 inainte, 16.32 dupa. Fotografia da structura la
## frecvente MEDII (crapaturi, petice); zgomotul pe blocuri de 4 texeli e
## singurul lucru care traieste la scara unui texel, si exact aia masoara sonda
## din §14 — pentru ca exact aia se vede la 60 km/h.
const GRAIN_BLOCK := 4

static func surfaces() -> Dictionary:
	return {
		# --- NISIP ---
		#
		# Sursa micro: gravelly_sand (PolyHaven CC0, scanare de 2.48 m — deci
		# aproape 1:1 la repetitia de 3.125 m a terenului). Aleasa prin
		# masuratoare dintre sase candidati, pe criteriul care conteaza la o
		# textura MULTIPLICATIVA: nu media (aia se renormalizeaza oricum), ci
		# cata deviatie ramane INAUNTRUL dalei fata de cea globala. gravelly_sand
		# retine 0.88 (10.32 din 11.7); aeriana dinainte retinea 0.735. Uniformitate
		# 0.5%/1.2% — sub pragul de 5% peste care repetitia da benzi.
		# Vezi tools/measure_texture_src.gd, ritualul din style_bible §4.
		#
		# `mean` 0.850 e MOSTENIT, nu recalculat: la 0.838 (media exacta a
		# texturii procedurale de dinainte) nisipul randat iesea cu 3% mai
		# intunecat, adica eroare 14/255 pe rosu fata de #D4994D, peste pragul
		# de 12 din style_bible §14.
		#
		# sigma 0.045 -> 0.075: cu sursa la scara corecta, normalizarea la 0.045
		# ZDROBEA fotografia (deviatia sursei 11.7 taiata la 11.5, pe o sursa
		# care acum chiar are structura de citit). `grain` URCA 0.20 -> 0.22 —
		# vezi nota de mai sus despre incercarea de a-l taia.
		"surface_sand": {"src": "surface_sand_src.jpg",
			"mean": 0.850, "sigma": 0.075, "grain": 0.22},
		# Sursa macro: aeriana de 20 m de dinainte, in rolul ei corect. Pete si
		# urme late la o repetitie de 45 m — exact ce a fost fotografiat.
		#
		# Are grain, desi intuitia zice ca la 45 m/repetitie un texel acopera
		# 9 cm si zgomotul ar fi mancat de mipmap. Intuitia e gresita in PRIM-PLAN:
		# la 10 m de camera un pixel de ecran acopera ~1.3 cm, deci un texel macro
		# se intinde pe ~7 pixeli si e perfect vizibil. Trecerea macro nu e doar
		# "pete lente", e si o a doua sursa de granulatie MARITA — de aia taierea
		# ei a costat jumatate din regresia masurata.
		"surface_sand_macro": {"src": "surface_sand_macro_src.jpg",
			"mean": 0.850, "sigma": 0.075, "grain": 0.12},

		# --- IARBA ---
		#
		# Prima textura pe care campul verde o primeste vreodata: pana acum
		# "iarba" era textura de nisip tentata verde din vertex color, si de
		# acolo venea jumatate din distanta fata de referinta (deviatia de
		# luminanta ~2.7 la noi vs ~36-40 la BBR, masurata in august).
		#
		# Sursa micro: leafy_grass (PolyHaven CC0, scanare de 2.0 m la
		# repetitia de 3.125 m). Aleasa prin masuratoare din patru candidati:
		# retine 0.87 din deviatie in dala (14.21 din 16.3) — la egalitate cu
		# gravelly_sand a nisipului — si dezechilibru 1.3%/1.7%.
		# sparse_grass retinea 0.83 dar cu sigma globala 9 (poza plata);
		# aerial_grass_rock avea dezechilibru 4.0% — la limita benzilor.
		#
		# Sursa macro: coast_land_rocks_01 (PolyHaven CC0, aeriana de 20 m la
		# repetitia de 45 m — aceeasi clasa de compromis ca aeriana nisipului).
		# Cea mai UNIFORMA dintre candidati (1.3%/1.8%), criteriul care conteaza
		# la scara la care o repetitie acopera jumatate de ecran.
		#
		# mean 0.850 pe amandoua, MOSTENIT de la nisip cu buna stiinta:
		# produsul trecerilor (0.7225) ramane identic, deci expunerea campului
		# nu se misca si inland_tint-ul calibrat pe snapshot ramane valabil.
		"surface_grass": {"src": "surface_grass_src.jpg",
			"mean": 0.850, "sigma": 0.075, "grain": 0.22},
		"surface_grass_macro": {"src": "surface_grass_macro_src.jpg",
			"mean": 0.850, "sigma": 0.075, "grain": 0.12},

		# --- ASFALT ---
		#
		# Sursa micro: asphalt_02 (PolyHaven CC0, scanare de 3.0 m — practic 1:1
		# la repetitia de 3.5 m a soselei). Deviatie in-dala 14.97 fata de 8.84 a
		# aerianei, cu retentie 0.89, si dezechilibru de lumina 0.5%/1.2% fata de
		# 0.2%/5.4%. Aduce agregatul si crapaturile — ce lipsea complet.
		#
		# `mean` ramane 0.865, exact cat avea trecerea unica de dinainte: asa
		# incape `grain` 0.26 (0.865 + 0.13 = 0.995, fara retezare). Compensarea
		# celei de-a doua treceri e in culoarea din _build_road, nu aici.
		"surface_asphalt": {"src": "surface_asphalt_src.jpg",
			"mean": 0.865, "sigma": 0.085, "grain": 0.26},
		# Sursa macro: aeriana de 30 m de dinainte. La 45 m/repetitie arcele de
		# cauciuc si peticele de reparatii ies aproape la scara lor reala, si fac
		# soseaua sa citeasca a drum intretinut, nu a panglica turnata.
		"surface_asphalt_macro": {"src": "surface_asphalt_macro_src.jpg",
			"mean": 0.900, "sigma": 0.065, "grain": 0.12},

		# --- PIETRIS (umarul soselei) ---
		#
		# Sursa: rocky_gravel (PolyHaven CC0, scanare de 1.81 m, o repetitie la
		# 1.8 m in joc — 1:1). Cea mai contrastata sursa masurata: deviatie
		# in-dala 21.65 cu retentie 0.86. Pe o banda de 1.3 m latime care trece
		# la 2 m de camera, pietrele individuale sunt exact detaliul cerut.
		#
		# O SINGURA trecere, fara macro: banda e ingusta si privita in unghi
		# razant, deci repetitia nu se citeste; iar a doua trecere ar fi cerut
		# recalibrarea culorii de praf. mean 0.850 = cel al nisipului pe care il
		# inlocuieste, deci umarul isi pastreaza expunerea.
		"surface_gravel": {"src": "surface_gravel_src.jpg",
			"mean": 0.850, "sigma": 0.090, "grain": 0.20},

		# --- BORDURA ---
		#
		# Sursa: concrete_src, REFOLOSITA (concrete_floor_02, PolyHaven CC0) —
		# bordurile sunt beton vopsit, deci e chiar materialul potrivit, si o
		# clasa noua ar fi insemnat inca o sursa in repo fara castig.
		# Deviatie in-dala 17.43: pete, ciobituri si granulatie de beton, adica
		# fix uzura care lipsea de pe benzile rosu-alb.
		#
		# mean 0.940, si NU 0.850: bordurile sunt cea mai SATURATA suprafata mare
		# din cadru (rosu 0.85), iar o textura care le-ar intuneca cu 15% le-ar
		# scoate din rolul de "citesti virajul de departe". Culorile de baza din
		# _build_kerbs sunt impartite la 0.940, deci luminozitatea lor ramane
		# exact cea dinainte si se schimba doar uniformitatea.
		# grain doar 0.10: media e sus, deci amplitudinea nu incape (0.940 + 0.05
		# = 0.99 e deja la limita). Bordura isi permite — spre deosebire de
		# nisip si asfalt, ea nu e o suprafata pe care sta camera, ci o banda de
		# 0.9 m vazuta in trecere.
		"surface_kerb": {"src": "concrete_src.jpg",
			"mean": 0.940, "sigma": 0.075, "grain": 0.10},
	}


func _initialize() -> void:
	_do_surfaces()
	var spec := classes()
	for cls: String in spec:
		var src_path: String = SRC_DIR + spec[cls]["src"]
		var img := Image.new()
		var err := img.load(ProjectSettings.globalize_path(src_path))
		if err != OK:
			push_error("Nu am putut citi %s (eroare %d)" % [src_path, err])
			continue
		img.resize(OUT_SIZE, OUT_SIZE, Image.INTERPOLATE_LANCZOS)
		_grade(img, spec[cls]["anchor"], float(spec[cls].get("gain", 1.0)),
			float(spec[cls].get("lift", 0.0)))
		var out: String = OUT_DIR + cls + ".png"
		DirAccess.make_dir_recursive_absolute(OUT_DIR)
		if img.save_png(out) != OK:
			push_error("Nu am putut scrie " + out)
			continue
		print("  %s.png  (%dx%d, ancora %s)"
			% [cls, OUT_SIZE, OUT_SIZE, spec[cls]["anchor"].to_html(false)])
	quit()


const SURFACE_DIR := "res://assets/textures/"

func _do_surfaces() -> void:
	for name: String in surfaces():
		var cfg: Dictionary = surfaces()[name]
		var src_path: String = SRC_DIR + cfg["src"]
		var img := Image.new()
		if img.load(ProjectSettings.globalize_path(src_path)) != OK:
			push_error("Nu am putut citi " + src_path)
			continue
		img.resize(OUT_SIZE, OUT_SIZE, Image.INTERPOLATE_LANCZOS)
		var got := _to_grayscale(img, float(cfg["mean"]), float(cfg["sigma"]),
			float(cfg["grain"]))
		var out: String = SURFACE_DIR + name + ".png"
		if img.save_png(out) != OK:
			push_error("Nu am putut scrie " + out)
			continue
		print("  %s.png  (%dx%d, gri, medie %.4f sigma %.4f — tinta %.3f/%.3f)"
			% [name, OUT_SIZE, OUT_SIZE, got.x, got.y, cfg["mean"], cfg["sigma"]])


## Zgomot determinist din POZITIE, nu dintr-un flux de rng — aceeasi regula ca
## in generate_palette_atlas._hash01, si din acelasi motiv: un artefact nu are
## voie sa se schimbe fiindca altul de langa el a consumat extrageri.
func _hash01(x: int, y: int, salt: int) -> float:
	var h := (x * 374761393) ^ (y * 668265263) ^ (salt * 2147483647)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xFFFFFF) / float(0x1000000)


## Desaturare completa + remapare liniara la (mean, sigma) + granulatie pe
## blocuri. Intoarce media si deviatia REALE de dupa clamp, ca sa se vada cat
## s-a pierdut la margini.
func _to_grayscale(img: Image, mean_t: float, sigma_t: float,
		grain: float) -> Vector2:
	var w := img.get_width()
	var h := img.get_height()
	var n := float(w * h)
	var vals := PackedFloat32Array()
	vals.resize(w * h)
	var sum := 0.0
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var l := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			vals[y * w + x] = l
			sum += l
	var mean_src := sum / n
	var var_src := 0.0
	for v in vals:
		var_src += (v - mean_src) * (v - mean_src)
	var sd_src := sqrt(var_src / n)
	var k := sigma_t / maxf(sd_src, 1e-5)
	var got_sum := 0.0
	var got_sq := 0.0
	for y in h:
		for x in w:
			# Granulatia se scade, nu se aduna: textura moduleaza in JOS peste
			# albedo (centrul e alb), la fel ca varianta procedurala. Media
			# tintita se corecteaza cu jumatatea amplitudinii, ca adaugarea
			# granulatiei sa nu intunece suprafata — adica sa nu clatine
			# expunerea, care e tot rostul normalizarii.
			var g := _hash01(x / GRAIN_BLOCK, y / GRAIN_BLOCK, 1) * grain
			var v: float = clampf(
				mean_t + grain * 0.5 - g + (vals[y * w + x] - mean_src) * k,
				0.0, 1.0)
			got_sum += v
			got_sq += v * v
			img.set_pixel(x, y, Color(v, v, v))
	var got_mean := got_sum / n
	return Vector2(got_mean, sqrt(maxf(got_sq / n - got_mean * got_mean, 0.0)))


## Gradarea unui pixel, in doi pasi:
##  1. desaturare partiala (DESAT) — taie varfurile de culoare ale fotografiei;
##  2. amestec spre "ancora scalata la luminanta pixelului" (GRADE) — nuanta
##     converge spre paleta, dar detaliul (variatia de luminanta) ramane intact.
## `gain` intinde contrastul in jurul mediei de luminanta (1.0 = neatins);
## `lift` ridica uniform luminozitatea DUPA gain. Ambele per clasa: o
## fotografie plata are nevoie de punch ca sa supravietuiasca mipmap-urilor,
## una contrastata nu.
func _grade(img: Image, anchor: Color, gain: float = 1.0,
		lift: float = 0.0) -> void:
	var anchor_lum := anchor.r * 0.2126 + anchor.g * 0.7152 + anchor.b * 0.0722
	# media de luminanta a imaginii — pivotul in jurul caruia se intinde
	var mean := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			mean += c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	mean /= float(img.get_width() * img.get_height())
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			c = Color(
				clampf(mean + (c.r - mean) * gain + lift, 0.0, 1.0),
				clampf(mean + (c.g - mean) * gain + lift, 0.0, 1.0),
				clampf(mean + (c.b - mean) * gain + lift, 0.0, 1.0))
			var lum := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			var desat := Color(
				lerpf(c.r, lum, DESAT),
				lerpf(c.g, lum, DESAT),
				lerpf(c.b, lum, DESAT))
			var scale := lum / maxf(anchor_lum, 0.001)
			var target := Color(
				clampf(anchor.r * scale, 0.0, 1.0),
				clampf(anchor.g * scale, 0.0, 1.0),
				clampf(anchor.b * scale, 0.0, 1.0))
			img.set_pixel(x, y, Color(
				lerpf(desat.r, target.r, GRADE),
				lerpf(desat.g, target.g, GRADE),
				lerpf(desat.b, target.b, GRADE)))
