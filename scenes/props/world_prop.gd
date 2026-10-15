@tool
class_name WorldProp
extends Node3D
## Pentru un prop GLB asezat de mana in editor. Ii pune pe fiecare parte
## materialul corect: textura de CLASA acolo unde partea are UV-uri reale
## (scoarta, beton, olane, tencuiala), atlasul comun peste tot restul.
##
## De ce nu doar atlasul, ca inainte: contractul atlasului (vezi palette.gd) cere
## UV-uri COLAPSATE pe centrul slotului — o fata = un texel = o culoare. Un GLB
## venit din kit, cu unwrap real, matura in schimb intreaga latime a atlasului si
## culege toate cele 32 de sloturi, inclusiv rezerva 24..31 care e MAGENTA
## intentionat (generate_palette_atlas.gd o lasa asa ca greseala de UV sa sara in
## ochi). Rezultatul, vazut pe Okinawa manual: tetrapozi in dungi curcubeu cu
## benzi magenta, trunchiuri de palmier vargate, zidul de piatra al casei la fel.
##
## Masurat pe assets-urile insulei: Tetrapod_* matura 29-32 de sloturi,
## Banyan_Bark 32, Palm_Bark 31, House_Stone 28, BentPalm_Bark 24. Doar
## House_Sand respecta contractul (u 0.016 .. 0.016, colapsat).
##
## Codul procedural stia deja asta — track.gd trece landmark-urile cu "classes"
## prin apply_class_materials si scrie negru pe alb ca apply_world_material le-ar
## face dungi. Ce lipsea era calea MANUALA: docs/decor_manual.md spune sa pui
## scriptul asta pe container, deci scriptul asta trebuie sa faca aceeasi treaba.
##
## `apply_class_materials` cade oricum pe materialul lumii pentru partile
## nemapate, deci e un inlocuitor direct: prop-urile facute in casa, cu UV-uri pe
## sloturi, se comporta exact ca inainte.
##
## Din august 2026 face si a doua treaba, din acelasi motiv: le da CORP FIZIC.
## Vezi `PROP_COLLISION` mai jos si docs/decor_manual.md §6.


## --- Coliziunea decorului asezat de mana -----------------------------------

## Cat de gros e cilindrul de trunchi, ca fractie din latimea coroanei, si cat
## de subtire poate ajunge. Aceleasi cifre ca la scatter (`_place_from_set`),
## ca un mesteacan pus de mana sa se simta ca unul tras la sorti.
const TRUNK_FRACTION: float = 0.13
const TRUNK_MIN_RADIUS: float = 0.22

## Raza cilindrului `trunk` PER MODEL, acolo unde latimea AABB minte: o coroana
## de 12 m ar da 12 x 0,13 = 1,6 m raza (stalp invizibil de 3,2 m). Valorile sunt
## masurate pe nodul de trunchi din GLB (baza evazata, Ø ~1-1,9 m la artar).
const TRUNK_RADIUS := {
	"momiji_a": 0.6, "momiji_b": 0.55, "momiji_c": 0.55,
	"ginkgo": 0.6, "niwaki_pine": 0.5,
	"moso_culm": 0.16, "bamboo_crown": 1.2,
	"paper_lantern": 0.15,
	# Monument Valley: latimea AABB minte (coroana de 4,4 m, bratul de 2 m, rombul
	# de 1,4 m); raza reala vine de pe nodul de trunchi/stalp din GLB.
	"juniper": 0.45, "telegraph_pole": 0.16, "open_range_sign": 0.12,
	# Okinawa: coroana fukugi (2,8 m) si evantaiele palmierului nu sunt trunchi.
	# Raze masurate pe nodul `*_Bark` la y < 1 m (fukugi 0,21-0,23; palmier 0,35;
	# pinul are baza evazata, r 1,35 la y < 1, dar trunchiul real e ~0,7).
	"fukugi_tree_a": 0.25, "fukugi_tree_b": 0.25, "fukugi_tree_c": 0.25,
	"ryukyu_pine": 0.7, "fan_palm": 0.35, "convex_mirror": 0.1,
}

## Numele metadatei prin care o INSTANTA anume iese din regula generala.
## In editor: Inspector -> Add Metadata -> `coliziune`, cu una din valorile
## "hull" / "trunk" / "mesh" / "none".
const COLLISION_META := "coliziune"

## Modul de coliziune per MODEL (numele fisierului .glb, fara extensie).
## Ce nu e in tabel primeste "hull" — un poliedru convex per mesh vizibil, ca
## la stancile din scatter. Adica, implicit, ORICE prop asezat de mana e solid.
##
## Cele patru moduri:
##   hull   poliedru convex per mesh (implicit) — case, garduri, stanci, lazi
##   trunk  cilindru subtire in ax — copaci si stalpi: treci prin coroana si
##          prin panglici, nu prin trunchi (hull-ul unui larice e un CON de 14 m
##          care te opreste in aer, la trei metri de trunchi)
##   mesh   colizor exact, din triunghiurile mesh-ului — DOAR pentru piesele
##          prin care se TRECE: hull-ul unei arcade e un bloc plin, adica un zid
##          invizibil peste sosea. Nu se foloseste in rest: track_cliffs.gd
##          documenteaza de ce (fiecare crapatura din silueta devine un colt in
##          care se agata masina)
##   none   fantoma — ce ar strica cursa daca ar opri masina
const PROP_COLLISION := {
	# --- se trece PRIN ele ------------------------------------------------
	"ice_grotto_arch": "mesh",       # tunelul scurt de la POI D
	"railway_tunnel_portal": "mesh", # galeria + portalul, drumul intra in ele
	"viaduct_arch": "mesh",          # soseaua trece pe DEDESUBT la 0.66-0.72
	"start_gate_logs": "mesh",       # poarta de start, peste linia de plecare
	"stone_gate_torii": "mesh",      # Okinawa: torii peste drum
	"wooden_pier": "mesh",           # pontonul are gol dedesubt
	# Cuva craterului (Stromboli): hull-ul unei cuve DESCHISE e un capac plan
	# peste gura — masina care rata saritura plutea pe el, deasupra craterului,
	# prea sus ca s-o prinda RespawnZone-ul din cuva. Cine cade trebuie sa CADA.
	"crater_bowl": "mesh",
	# Limba de lava (Stromboli): coliziunea NU e a decorului, e a hazardului.
	# world_prop construieste corpurile O DATA, la _ready, pentru mesh-urile
	# vizibile ATUNCI — adica toate trei stadiile (copilul isi face _ready
	# inaintea parintelui care le stinge). Zidul stadiului 3 ar fi existat
	# invizibil inca din turul 1, taind scurtatura. LavaFlowHazard isi
	# reconstruieste colizorul (trimesh — poarta de 4 m trebuie sa ramana
	# libera) la fiecare schimbare de stadiu.
	"lava_flow": "none",
	# Hornul crapat (Cappadocia, POI D): aceeasi capcana ca la lava, din
	# acelasi motiv. Cele trei stari stau in scena una langa alta, iar
	# `world_prop` construieste corpurile O DATA, la `_ready`, pentru
	# mesh-urile vizibile ATUNCI — adica pentru toate trei, fiindca instantele
	# GLB isi fac `_ready` inaintea hazardului care le stinge. Rampa si molozul
	# ar fi existat ca ziduri invizibile pe mijlocul drumului inca dinainte ca
	# hornul sa cada. Colizorul si-l face [CrackedChimneyHazard], la fiecare
	# schimbare de stare.
	"cracked_chimney_a": "none",
	"cracked_chimney_b": "none",
	"cracked_chimney_c": "none",
	# --- copaci si stalpi: cilindru pe trunchi ----------------------------
	"larch_winter_a": "trunk", "larch_winter_b": "trunk",
	"larch_winter_c": "trunk", "birch_winter_a": "trunk",
	"birch_winter_b": "trunk", "birch_winter_c": "trunk",
	"pine_siberian_a": "trunk", "pine_siberian_b": "trunk",
	"coconut_palm": "trunk", "beach_palm_bent": "trunk",
	"pandanus": "trunk", "banyan": "trunk",
	"serge_pole_a": "trunk", "serge_pole_b": "trunk", "serge_pole_c": "trunk",
	"village_signpost": "trunk", "power_pylon_soviet": "trunk",
	"well_crane": "trunk",
	# --- fantome ----------------------------------------------------------
	# Sina zace PE sosea: traversele au 27 cm cu tot cu sina, adica praguri
	# pe linia de curs, si sunt 34 de bucati una dupa alta.
	"rail_track": "none",
	# Podetul de peste parau (Alpii): drumul trece PE el, iar soseaua isi are
	# deja coliziunea ei acolo. Un corp solid ar fi o treapta fix pe linia de
	# curs — masurat cu tools/probe_solid.gd, gabaritul masinii il atingea la
	# fractia 0.252.
	"stream_bridge": "none",
	"ice_hole": "none",         # gaura in gheata, plata prin definitie
	"ice_shards": "none",       # cioburi de 0.5 m, imprastiate pe banda
	"ice_road_marker": "none",  # betele cu steguleț care marcheaza drumul
	"husky_dog": "none", "nerpa_seal": "none",  # figuranti
	"flowers_orange": "none", "flowers_white": "none",
	"hibiscus_bush": "none", "sugar_cane_clump": "none",
	"shrub_snow": "none", "grass_tuft_dry": "none",
	# Tufele de savana (Serengeti POI A): strat pur vizual, cu SUTELE. Un
	# hull pe fiecare ar da sute de corpuri fizice pentru obiecte de 1 m
	# peste care masina oricum trece — si ar face din campie un zid.
	# `tropical_shrub` si `grass_tuft_large` sunt declarate mai jos, cu
	# acelasi "none", de POI B (o cheie de doua ori intr-un dictionar e
	# Parse Error si opreste tot scriptul).
	"broadleaf_shrub": "none",
	# --- Chongqing (POI A-D) ----------------------------------------------
	# Stalpii: lampioanele si firmele au bratul si felinarul latite mult peste
	# stalp (lamp_lantern_a e 1.40 m lat pe un stalp de ~12 cm). Un hull ar
	# pune pe trotuar un bloc de un metru si jumatate, la inaltimea capotei.
	"lamp_lantern_a": "trunk", "lamp_lantern_b": "trunk",
	"lamp_lantern_c": "trunk",
	"neon_sign_a": "trunk", "neon_sign_b": "trunk",
	"neon_sign_c": "trunk", "neon_sign_d": "trunk",
	"bollard": "trunk", "chevron_post": "trunk",
	# Rufele stau pe o sarma peste alee, la 2.6 m: hull-ul lor ar fi un tavan
	# plin exact peste carosabil.
	"laundry_line": "mesh",
	# --- figuranti si marunt: nimic care sa opreasca o masina de cursa -----
	# Hamalii se plimba pe scara, sub linia camerei; mesele si scuterul stau pe
	# trotuarul din aleea de 6 m, adica la o roata distanta de linia de curs.
	# Mesele cu taburete, scuterul si bicicletele de pe aleea cu pravalii: decor
	# MIC care se imprastie la contact (#489, #507), nu zid si nici fantoma.
	"porter": "none", "table_stools": "bump", "steam_vent": "none",
	"scooter": "bump", "bicycle": "bump",
	# --- Cappadocia (POI E: via si balonul aterizat) ----------------------
	# Panza dezumflata ZACE PESTE drum, pe toata latimea lui (20,7 x 8,0 m,
	# groasa de 50 cm). Implicitul "hull" ar fi exact ce descrie brief-ul ca
	# fiind gresit: un zid de 20 m fix pe linia de curs, care inchide pista.
	# Panza e o SUPRAFATA, nu un obstacol — treci peste ea (incetinit).
	"balloon_landed": "none",
	# Randul de vie e scurtatura lenta prin care se TRECE (brief POI E:
	# "iarba lenta cu geometrie"). Aracii au 4 cm: un hull per rand ar fi un
	# gard de 10 m, si sunt zeci de randuri.
	"vine_row": "none",
	# Teancurile de oale de langa caruta din piata Goreme (#508): gimmick-ul nu
	# mai e „nimereste fanta de 4 m", ci „le imprastii sau ocolesti". Caruta
	# (pottery_cart) ramane zid: e jumatatea de blocaj care chiar opreste.
	"pot_stack": "bump",
	"shrub_dry": "none", "pigeon": "none",
	# (Molozul hornurilor cazute — `cracked_chimney_*` — e declarat mai sus,
	# la POI D. Motivul lui POI E e acelasi si se adauga: cele 72 de lespezi
	# de pe coama din dreapta stau la 28-60 m lateral de banda si sunt
	# gradient de contact intre stanca si sol, nu obstacole.)
	# Grohotisul de sub perete (POI E, runda 3): bolovani de 0.3-1.6 m, zeci de
	# bucati, TOATE la peste 13 m lateral de banda (generatorul le respinge mai
	# aproape). Ca si molozul de mai sus: sunt gradient de contact intre stanca
	# si sol, nu obstacole, iar un hull per bucata ar pune zeci de corpuri
	# convexe pe teren pe care masina n-are ce cauta.
	"talus_block": "none", "talus_cobble": "none", "talus_gravel": "none",
	# Plopii: cilindru pe trunchi, ca toti copacii — hull-ul unui plop de
	# 15 m e o coloana de 2,5 m latime care te opreste in aer.
	"poplar_a": "trunk", "poplar_b": "trunk",
	# Cosul balonului e mic si solid; ferma e o casa: hull implicit, corect.
	# --- Serengeti (kitul din assets/models/serengeti/, PR #376) -----------
	# Prin ele se TRECE: spartura Lerai are 12 m liber intre cele doua fete
	# (hull-ul ar fi un bloc plin peste drum), iar kopje-ul-rampa e chiar
	# rampa pe care se urca (8 x 6 x 2,8 m, 19°) — pe un hull convex masina
	# s-ar fi urcat pe un capac plan peste bolovanii de langa rampa.
	# Saltul il face un HazardMarker kind=FLYOFF pus pe buza (POI C), ca
	# `KickerulDinGura` pe Cappadocia; mesh-ul nu arunca nimic singur.
	"crater_gap": "mesh",
	"kopje_kicker": "mesh",
	# Copacii: cilindru pe trunchi. Coroana acaciei-umbrela e lata cat
	# inaltimea (8,9 x 7 m), deci hull-ul ei ar fi un cort care te opreste la
	# 4 m de trunchi; baobabul de 22 m ar fi o coloana de 13 m latime.
	"acacia_umbrella_a": "trunk", "acacia_umbrella_b": "trunk",
	"acacia_umbrella_c": "trunk", "fever_tree": "trunk", "fig_tree": "trunk",
	"baobab": "trunk", "dead_tree": "trunk", "euphorbia": "trunk",
	# Fantome: flamingii stau pe lac (sub banda), hoitul cu vulturi e o
	# lespede de 1 m in iarba, focul e 80 cm, panza balonului aterizat ZACE
	# pe sol (16,6 x 9 m, 1,8 m) exact ca `balloon_landed` de mai sus, iar
	# Lengai (300 m) si peretele opus al craterului (210 m) sunt orizont,
	# la 200-300 m de banda: un hull pe ele ar fi un corp cat o pista.
	"flamingo": "none", "flamingo_wings": "none",
	"carcass_vultures": "none", "campfire": "none",
	"safari_balloon_landed": "none",
	"lengai": "none", "crater_far_wall": "none",
	# Leul de pe kopje: sta pe platoul de la 13 m, nimeni nu ajunge la el.
	"lion_kopje": "none",
	# Coarnele Ankole se parenteaza pe capul vacii (PathMover/SlidingHazard),
	# deci n-au corp propriu — si oricum `_collect_models` sare peste ce e
	# sub un corp fizic.
	"ankole_horns": "none",
	# Tufele de savana (POI B): `tropical_shrub` din kitul comun, la 1,5-5 m de
	# banda, zeci de bucati — vegetatie moale prin care se trece, nu obstacol.
	"tropical_shrub": "none",
	# Smocurile de iarba (POI B): la 1,5-6 m de banda, sute de bucati sub 1,2 m
	# — prin ele se trece, ca prin iarba campiei.
	"grass_tuft_large": "none", "grass_tuft_small": "none",
	# Hull implicit, corect, pentru restul: kopje_camp, kopje_boulder_a/b/c,
	# termite_mound_a/b, maasai_boma, safari_tent, land_rover, crocodile,
	# hippo_back (ca decor static pe mal), elephant (ca decor static),
	# wildebeest, zebra (figuranti statici in afara turmei).
	# --- Machu Picchu (kitul din assets/models/machupicchu/, PR #386) ------
	# Modurile de mai jos vin din masurarea AABB-ului fiecarei piese (raport
	# raza-la-baza / semi-latime), nu din ochi.
	#
	# Prin ea se TRECE: cornisa podului incas. Golul masurat e 4,230 m la cota
	# cornisei (fereastra y 8,00..11,00), ceea ce confirma contractul gap=4.25
	# din Track15.tscn. Un hull ar astupa exact prapastia de 12,90 m peste care
	# sare LiftBridgeHazard — acelasi motiv ca `crater_bowl` mai sus: cine cade
	# trebuie sa CADA. (Pe toata inaltimea, y 0,15..12,80, golul se strange la
	# 3,750 m — deci contractul e la cota cornisei, nu global.)
	"inca_bridge_ledge": "mesh",
	# Copacii si bambusul: cilindru pe trunchi, ca toti copacii de mai sus.
	# Rapoartele raza-baza/semi-latime masurate sunt sub pragul de 0,5 —
	# bamboo_clump 0,40, polylepis_a 0,41, polylepis_b 0,47 — adica coroana
	# depaseste masiv baza, iar hull-ul ar fi un bloc care te opreste in aer.
	"bamboo_clump": "trunk", "polylepis_a": "trunk", "polylepis_b": "trunk",
	# Feriga arborescenta, raportul cel mai extrem din kit (0,30/2,07 = 0,15):
	# stipa de 0,30 m sub o coroana de 4,13 m. ATENTIE, cilindrul automat e
	# PREA GROS aici: `_add_trunk` ia raza din latimea AABB, adica
	# max(4,13 * TRUNK_FRACTION, TRUNK_MIN_RADIUS) = 0,537 m, de 1,8 ori raza
	# reala a stipei. Ramane "trunk" fiindca alternativele sunt mai rele (un
	# hull ar fi un cort de 4 m), dar cine o aseaza langa banda trebuie sa stie
	# ca stalpul invizibil e cu ~24 cm mai lat de fiecare parte decat se vede.
	"tree_fern": "trunk",
	# Fantome. Accente sub linia capotei, unde un corp fizic ar fi doar un
	# pietroi invizibil: condor 1,16 m, llama 0,53 m, bromeliad 0,38 m,
	# orchid_cluster 0,39 m, backpack_pile 0,69 m (bagaje, nu obstacol).
	# Lamele se monteaza oricum pe SlidingHazard, care isi face colizorul lui.
	"condor": "none", "llama": "none", "llama_b": "none", "llama_c": "none",
	"bromeliad": "none", "orchid_cluster": "none",
	# Nu "bump": generatorul ii scaleaza x1,3-1,9 (gramezi de 2,15 m, ca sa se
	# citeasca de la 35 m) — peste pragul din BumpProp, ar cadea pe hull (#489).
	"backpack_pile": "none",
	# Orizontul. Acelasi tipar ca `lengai` / `crater_far_wall` la Serengeti: un
	# hull pe ele ar fi un corp fizic cat o pista. gorge_far_wall e 196,00 x
	# 75,39 x 92,06 m si e o PANZA (doua foi cusute), deci nici n-are volum de
	# umplut; huayna_picchu 79,47 x 33,00 x 73,47 m; machu_picchu_mountain
	# 146,71 x 60,50 x 134,74 m.
	"gorge_far_wall": "none", "huayna_picchu": "none",
	"machu_picchu_mountain": "none",
	# Hull implicit, corect, pentru restul: guardhouse (raport 1,02),
	# inca_house_a (1,05), inca_house_b (1,21), tent_a/tent_b (1,29),
	# moss_boulder_a/b/c (0,87 / 0,76 / 0,82), fountain_basin (1,13),
	# inca_wall_a/b (1,01) si scarile inca_stair_a/b. Pe scari raportul iese
	# 2,11 / 2,03, dar cifra insala: pe o scara `raza la baza` masoara
	# diagonala treptei de jos, nu un trunchi, iar hull-ul unei scari e o PANA,
	# nu un capac plan. Daca o captura arata masina urcata pe capac in loc sa
	# atinga treptele, se trece pe "mesh" (tiparul `kopje_kicker`).
	# --- Fiordland (kitul din assets/models/fiordland/, brief fiordland_kit.md,
	# masurat in docs/asset_briefs/fiordland_masuratori.md) --------------------
	#
	# Fagii: Trunk/Crown separate, acelasi tipar ca la copacii de mai sus.
	# Rapoartele masurate raza-baza/semi-latime: beech_a 0,318, beech_b 0,242,
	# beech_c 0,216 — coroana depaseste masiv baza, hull-ul ar fi un bloc solid
	# de 5-9,5 m in care masina s-ar opri in aer, pe langa trunchi.
	"beech_a": "trunk", "beech_b": "trunk", "beech_c": "trunk",
	# beech_dead e UN SINGUR nod (nu Trunk+Crown separate) — coliziunea cade tot
	# pe "trunk" (raport 0,415, siluetа relativ subtire, un trunchi uscat cu
	# cateva crengi), cea mai apropiata aproximare rezonabila fara sa desparta
	# geometria in doua noduri.
	"beech_dead": "trunk",
	# rata_tree: tufa DENSA (brief-ul cere explicit "nu acacie"), raport 0,930 —
	# aproape de disc, nu de trunchi ingust. Ramane hull implicit.
	#
	# Fantome sub linia capotei sau contracte explicite de gameplay:
	"penguin_tawaki": "none",  # brief 1.7 / inventar: pinguinul e figurant
	"heli_pad": "none",  # disc jos de 0,3 m, se calca — un hull ar opri masina
	"torrent_chute": "none",  # deasupra benzii (buza +14 iese peste drum)
	"chasm_bridge_rail": "none",  # balustrada subtire pe marginea podului
	"scree_slab": "none",  # placa joasa de grohotis pe panta (1,2 m), se calca
	"snow_pole": "none",  # jalon subtire, pur decorativ
	"kayak_a": "none", "kayak_b": "none",  # pe mal/apa, nu obstacol de coliziune
	# Fundalul: 4 noduri (FarWall_A/B, SnowRidge_A/B), panze de 90-180 m — un
	# hull ar fi un corp fizic cat o pista, acelasi tipar ca `gorge_far_wall`/
	# `huayna_picchu` la Machu Picchu.
	"fiordland_horizon": "none",
	# stirling_ledge: nisa dintre Wall si fata interioara a Overhang e un gol
	# real (Shelf, pragul uscat de 3 m, la y 0,38-0,40 intre Wall si Overhang la
	# y 14,00-21,40) — hull-ul convex al intregului nod ar UMPLE concavitatea
	# de sub surplomb si ar astupa pragul pe care se conduce prin spatele
	# perdelei. Acelasi tipar ca `inca_bridge_ledge` la Machu Picchu.
	"stirling_ledge": "mesh",
	# Restul (implicit hull, corect): cafe_shed, lodge, chasm_rock, guard_rock,
	# wharf, coach_fiordland, cruise_boat, traffic_light_pole,
	# luggage_container, driftwood, stump, road_sign_blank, tussock_clump,
	# tree_avalanche (bolovanii de avalansa au propriul colizor construit de
	# AvalancheHazard, dar daca vreodata ajunge in DecorManual ca decor static,
	# hull pe fiecare Boulder_* e corect — sunt bolovani compacti).
	# bush_plane: "none" — PathMover zboara, stick_to_ground=false, un hull ar
	# fi un perete invizibil in aer pe traiectoria de zbor.
	"bush_plane": "none",
	# --- Jodhpur (kitul din assets/models/jodhpur/, brief jodhpur_kit.md,
	# masurat in docs/asset_briefs/jodhpur_masuratori.md §3) ------------------
	#
	# Se TRECE prin ele: hull-ul ar umple golul (7,16 m la porti, 18,39 m la
	# poarta pietei, masurate ca GOL) si ar face zid peste drum.
	"fort_gate_jai": "mesh", "fort_gate_fateh": "mesh",
	"fort_gate_loha": "mesh", "market_gate": "mesh",
	# Coroana depaseste masiv baza: raza-baza/semi-latime neem 0,18, khejri
	# 0,13 — hull-ul ar fi un cort de 7-8 m care opreste masina in aer.
	# (`euphorbia` e deja "trunk" mai sus, intrarea Serengeti; acelasi stem,
	# raport 0,46 si aici, deci aceeasi decizie.)
	"neem_tree": "trunk", "khejri_tree": "trunk",
	# Contract (kit §1.3): treptele fantanii sunt decor LIPIT de peretele
	# gropii; coliziunea e a terenului (`TerrainHollow`). Un hull pe modulul
	# de 12 m ar fi o treapta falsa pe rampa.
	"stepwell_flight_module": "none", "stepwell_corner": "none",
	"stepwell_pavilion": "none",
	# Teatru si figuranti (brief §3/§8: procesiunea e pe trotuar, fara
	# coliziune; vaca isi face singura cutia in `CowGate`).
	"baraat_horse": "none", "baraat_band": "none", "peacock_closed": "none",
	"peacock_fanned": "none", "langur": "none", "black_kite_bird": "none",
	"zipline_rider": "none", "zebu_cow": "none",
	# Sub linia capotei / deasupra benzii / contract: candelele, ghirlanda si
	# fasia de textile atarna peste strada, tunul e "none" prin kit §1.2.
	"diya": "none", "floating_diya": "none", "marigold_garland": "none",
	"textile_strip": "none", "rampart_cannon": "none",
	# Pe acoperisuri (nu le atinge nimeni — corpuri de fizica degeaba),
	# tuk-tuk-ul e `Car` (nu decor), orizontul e fundal de 150-200 m.
	"rooftop_tank": "none", "rooftop_clutter": "none", "tuktuk": "none",
	"jodhpur_horizon": "none",
	# --- Kyoto (Track18), brief §5.6 -----------------------------------------
	# Copaci: cilindru pe trunchi (raza din TRUNK_RADIUS, nu din latimea AABB:
	# coroana unui artar e de 10-12 m si dadea un stalp invizibil de 1,6 m raza).
	"momiji_a": "trunk", "momiji_b": "trunk", "momiji_c": "trunk",
	"ginkgo": "trunk", "niwaki_pine": "trunk",
	"moso_culm": "trunk", "bamboo_crown": "trunk",
	"paper_lantern": "trunk",  # stalp de lemn cu brat de 1 m; hull = bloc
	# Se trece PRIN ele / pe sub ele: colizor exact. Golul portilor (>= 14 m) e
	# contract de kit; stalpii laterali sunt solizi, golul nu.
	"kakezukuri_scaffold": "mesh", "niomon_gate": "mesh", "inari_romon": "mesh",
	"iron_truss_bridge": "mesh",  # drumul trece pe dedesubt (kit §1.5)
	# Piese mici si solide, aproape de banda: hull (implicitul, scris ca sa fie
	# inventarul complet). Felinarele si vulpile se simt ca un obstacol real.
	"stone_lantern_a": "hull", "stone_lantern_b": "hull",
	"yukimi_lantern": "hull", "kitsune_statue_a": "hull",
	"kitsune_statue_b": "hull",
	# Fantome: frunzele sparg in particule la trecere (cod propriu), figurantii
	# nu opresc masina, orizontul e fundal, placile de trecere sunt plate, iar
	# modulele de pod/portile torii sunt acoperis/arcade fara corp (coliziunea
	# podului e terenul, a tunelului e peretele continuu al TrackBranch).
	"leaf_pile": "none", "monk_sweeper": "none", "crow": "none",
	"sika_deer": "none", "kyoto_horizon": "none", "stepping_stones": "none",
	"tsutenkyo_roof_module": "none", "togetsukyo_module": "none",
	"torii_senbon": "none", "torii_large": "none",
	"votive_torii_cluster": "none",  # sir de 7 porti peste poteca: se trece pe sub ele
	"shiba_fence": "none",  # nuiele de 1,1 m, panou subtire: capcana de colt, nu obstacol
	"daruma_otoshi": "none",  # corpul il face DarumaOtoshiHazard
	# Restul kitului ramane hull implicit, corect: pagodele, hondo, kinkakuji,
	# altarul, clopotnita, bazinul, ema, ceainaria, zidul de templu si cel
	# ciclopic, stancile si movila de gradina, tufele karikomi. Casele machiya:
	# hull doar pe miezul `Machiya_Wood`, vezi HULL_SKIP_PARTS.
	# Restul (implicit hull, corect): casele a-e, haveli, ghanta_ghar, zidul
	# si turnul de zid (bloc plin: hull = zidul; brief-ul zicea "mesh", pe un
	# corp convex e identic si mai ieftin), bastionul, fatadele, cenotaful,
	# tarabele (brief: "pereti cu masa, nu decor fantoma"), thela, sacii,
	# bolovanii de riolit si lespedea.
	# --- Monument Valley (kitul din assets/models/monumentvalley/, PR #455) --------
	# Inventarul COMPLET, 37 de piese, scris explicit si cand modul e implicitul
	# (hull), ca sa nu mai fie nimic „probabil bun". Cheia e fisierul (stem), deci
	# `water_tower` de aici imparte cheia cu `buildings/water_tower.glb` (Dunele):
	# nicio intrare noua, fiindca ambele sunt hull — vezi comentariul de la
	# `water_tower` mai jos.
	#
	# Monolitii Mittens: `mesh`, NU hull. Un hull convex peste turn + deget ar umple
	# golul de cer dintre ele (3-4 m la baza, 5 m la mijloc) si ar lipi un perete
	# invizibil intre varful degetului si corp; mai grav, hull-ul ar acoperi si
	# punctul de pornire al `BolovanD` (rockfall #1, pe grohotisul degetului West
	# Mitten). Se ajunge la ei doar la 14+ m de banda (poarta D), deci formele
	# concave nu prind nicio masina. `Mitten_Scree`/`Cap` sunt sarite din colizor
	# (HULL_SKIP_PARTS): fusta e acoperita de terenul `TerrainPeak` de dedesubt.
	"west_mitten": "mesh", "east_mitten": "mesh",
	# Blocuri compacte, raport silueta/baza ~1 (nu au gol): hull, ieftin si corect.
	"merrick_butte": "hull", "mesa_wall_module": "hull",
	"butte_small_a": "hull", "butte_small_b": "hull", "butte_small_c": "hull",
	"rock_fin": "hull", "hoodoo": "hull",
	"talus_boulders_a": "hull", "talus_boulders_b": "hull",
	# Arcul: prin gol (>= 14 m) se TRECE. Il pune `Track._build_arch` (nu
	# DecorManual), cu colizor propriu din mesh; intrarea ramane pentru cine il
	# asaza de mana, ca sa nu iasa hull peste sosea.
	"sandstone_arch": "mesh",
	# Orizontul: panze de zeci de metri la 190+ m, fara corp.
	"horizon_mesas": "none",
	# Plantele: ienuparul e singurul cu trunchi destul de gros ca sa opreasca o
	# masina (raza din TRUNK_RADIUS); restul sunt vegetatie moale, prin care se trece.
	"juniper": "trunk",
	"sagebrush": "none", "rabbitbrush": "none", "yucca": "none",
	"tumbleweed": "bump", # se rostogoleste cand il lovesti (#489)
	# Grila pentru vite: PLATA (<= 0,15 m), se trece peste ea; stalpii de capat
	# sunt la 7,3 m de axa, adica pe margine. Sarma gardului: panou subtire, ca
	# `shiba_fence` / `wooden_fence`. Semnul si stalpul de telegraf: cilindru pe
	# stalp (bratul si traversa nu opresc masina).
	"cattle_guard": "none", "wire_fence": "none",
	"open_range_sign": "trunk", "telegraph_pole": "trunk",
	# Structuri si cladiri: solide (hull). Morii ii ramane hull-ul pe turn, iar
	# jgheabul de 0,6 m e sub linia capotei dar nu stinge niciun traseu.
	"windmill_pump": "hull", "water_tower": "hull", "corral": "hull",
	"shade_ramada": "hull",
	"trading_post": "hull", "homestead_house": "hull", "hogan": "hull",
	"pickup_old": "hull", "tour_truck": "hull",
	# Figuranti: oameni si animale nu opresc masina (caii care traverseaza sunt
	# `SlidingHazard`, cu corpul lui).
	"tourist_group": "none", "raven": "none", "sheep": "none",
	"horse_bay": "none", "horse_pinto": "none", "horse_black": "none",
	# --- Okinawa (kitul din assets/models/okinawa/, 36 de piese) -------------------
	# Inventarul COMPLET, scris explicit. Cheia e fisierul (stem).
	#
	# PORTA Ryukyu (peste drum, gol de 14,35 x 6,20 m): `mesh`, NU hull. Un hull
	# convex peste cei 8 stalpi ar umple tot golul. Doar `Gate_Lacquer` (stalpii,
	# grinzile de la 6,2 m in sus) si `Gate_Limestone` (soclurile) au corp; acoperisul,
	# mortarul si aurul sunt la >= 6,8 m deasupra soselei (HULL_SKIP_PARTS).
	"ryukyu_gate": "mesh",
	# Arcul gusuku: zid cu bolta de 4 x 4,5 m, nu e pe drum; `mesh` ca bolta sa ramana
	# libera (hull-ul ar sigila intrarea spre platforma palatului).
	"gusuku_arch_gate": "mesh",
	# Farul: turn + casa paznicului in aceeasi plasa (`Lighthouse_Plaster`), iar un
	# hull ar umple un clin de aer intre varful turnului (20 m) si acoperisul casei
	# (3,5 m). Plasa e mica (~1000 tri), deci trimesh-ul exact costa putin.
	"cape_lighthouse": "mesh",
	# Stancile-ciuperca: nisa de la baza (~1,5 m) si capul de 7-9 m fac din hull un
	# con plin sub cap, adica un perete de aer in fata nisei. `mesh` (1.200-1.450 tri).
	"notch_rock_a": "mesh", "notch_rock_b": "mesh", "notch_rock_c": "mesh",
	# Stanca-inima: doi lobi care se unesc intr-un varf infipt in apa; hull = corect.
	"heart_rock": "hull",
	# Falezele-modul (provizorii, inca nefolosite): bloc compact cu nisa la baza.
	"limestone_cliff_module": "hull", "limestone_cliff_module_b": "hull",
	# Zidurile gusuku: hull per modul. Modulul curb (R 20 m, coarda 16 m) isi umple
	# sageata de 1,7 m pe fata concava; de rezolvat la POI D, per instanta, cu
	# `coliziune = "mesh"` daca un modul se aseaza cu fata concava spre drum.
	"gusuku_wall_curve": "hull", "gusuku_wall_straight": "hull",
	"coral_stone_wall": "hull",
	# Palatul, casele, cheiul, refugiul, automatul: cladiri solide (hull per parte,
	# acoperisurile si anexele de lemn sunt sarite — HULL_SKIP_PARTS).
	"ryukyu_palace": "hull",
	"ryukyu_house_a": "hull", "ryukyu_house_b": "hull", "ryukyu_house_c": "hull",
	"concrete_house_a": "hull", "concrete_house_b": "hull",
	"harbour_quay": "hull", "bus_stop_shelter": "hull", "vending_machine": "hull",
	# Copaci: cilindru pe trunchi (TRUNK_RADIUS). Cicada, tufele si plasa de pescuit
	# sunt moi sau joase: se trece prin ele. `bougainvillea` NU are intrare aici:
	# cheia (stem) e impartita cu `stromboli/props/bougainvillea.glb`, care e `hull`
	# pe Track11 — instantele Okinawa poarta `coliziune = "none"` in .tscn.
	"fukugi_tree_a": "trunk", "fukugi_tree_b": "trunk", "fukugi_tree_c": "trunk",
	"ryukyu_pine": "trunk", "fan_palm": "trunk", "convex_mirror": "trunk",
	"cycad": "none", "fishing_net_rack": "none",
	# Animale, vapoare (mutate de hazard, au corpul lor), fundalul: fara corp.
	"water_buffalo": "none", "egret": "none",
	"island_ferry": "none", "coastal_freighter": "none", "fishing_boat": "none",
	"okinawa_horizon": "none",
	# --- Transfagarasan (kitul din assets/models/transfagarasan/) ------------
	# Prin ele se TRECE: golul portalului Balea e 14,85 x 7,40 m, al portalului de
	# stanca 15,40 x 7,60 m (masurate ca GOL); un hull ar fi un bloc plin peste
	# sosea. Coliziunea exacta, nu cutia. Lipsesc captuselile `*_Void`
	# (HULL_SKIP_PARTS).
	"tunnel_portal_balea": "mesh", "rock_tunnel_portal": "mesh",
	# Barajul: coronamentul sta SUB asfaltul procedural (nimic peste -0,05 m pe banda
	# de 12 m, `measure_tf_deck.py`), deci trimesh-ul da doar parapetul (1,1 m) si
	# peretele din aval; un hull ar fi o cutie pana la varful parapetului, adica un
	# zid peste toata latimea drumului. Acelasi tipar pentru turn si centrala.
	"vidraru_dam": "mesh",
	# Stanca Poenari: coliziune exacta pe sisturi (kit §1.2), sta lipita de drum.
	"poenari_ruin": "mesh",
	# Ziduri de sprijin, bancile de zapada, statuia, recuzita: poliedre convexe
	# per mesh, corecte (stau pe marginea drumului, nu peste el).
	"retaining_wall_straight": "hull", "retaining_wall_curve": "hull",
	"snow_wall": "hull", "prometheus_statue": "hull", "road_works": "hull",
	# Ansamblul de la trecerea la nivel are 18,8 m latime (stalpi pe ambele margini):
	# hull PER MESH (stalp, brat, felinar), nu o cutie peste drum.
	"level_crossing": "hull",
	# Semnul: stalp subtire + bolovan mic; cilindru in ax, ca stalpii.
	"bear_warning_sign": "trunk",
	# Copaci: fagul are trunchi gri neted si coroana larga (trunk, ca fagii Fiordland).
	"beech_tree_a": "trunk", "beech_tree_b": "trunk",
	# Fantome: tufe/flori (MultiMesh, sute), grohotis (con de 12 m cu o latura plana
	# lipita de perete), figuranti animati de hazarduri, trenul (TrainHazard isi
	# face garnitura), cabina telecabinei (trece pe deasupra), fundalul.
	# `snow_pole` e deja "none" mai sus (Fiordland).
	"jneapan_a": "none", "jneapan_b": "none", "bujor_de_munte": "none", "afin": "none",
	"scree_cone": "none", "brown_bear": "none", "sheepdog": "none",
	"ro_train": "none", "cable_cabin_large": "none", "transfagarasan_horizon": "none",
	# Pregatite pentru etapa de POI (hull simplu, corect): masini parcate,
	# motocicleta, stana cu tarcul, taraba, cabanele, casele din vale, aflorimentele.
	"parked_car_a": "hull", "parked_car_b": "hull", "motorbike": "hull",
	"stana": "hull", "souvenir_stall": "hull",
	"cabana_balea_lac": "hull", "cabana_balea_cascada": "hull",
	"arges_house_a": "hull", "arges_house_b": "hull",
	"schist_outcrop_a": "hull", "schist_outcrop_b": "hull", "schist_outcrop_c": "hull",
}

## Corpuri fizice automate pentru tot ce e asezat de mana dedesubt.
##
## Pana in august 2026 decorul manual era DECOR: treceai prin case, prin
## tetrapozi, prin Stanca Samanului. `docs/decor_manual.md` cerea sa adaugi de
## fiecare data, de mana, un StaticBody3D si un CollisionShape3D — si nimeni nu
## a facut-o niciodata: zero corpuri in patru piste, 450 de obiecte.
##
## Se construieste DOAR la rulare (`Engine.is_editor_hint()`), si fara `owner`,
## deci nu intra in .tscn si nu incurca selectia din editor: scena ramane exact
## lista ta de modele.
@export var auto_collision: bool = true


## Partile care primesc clasa DAR au accente pictate in alte sloturi: se rup in
## doua inainte de aplicarea materialelor (vezi Palette.split_accents).
##
## Casele eoliene si biserica sunt 90-98% var (slot 22) si 1-9% obloane/usi.
## Fara ruptura, alegerea era intre o fatada plata si niste obloane pierdute;
## cu ea, corpul ia textura de tencuiala si accentul ramane pictat pe atlas.
## ATENTIE la lacomia prefixelor: prima versiune folosea "House_" si prindea si
## `House_Sand`/`House_Stone` din `village_house.glb` (Okinawa si Dunele), care
## n-au nicio treaba cu varul eolian — Track08 a capatat un material si doua
## prop-uri in plus, prins la comparatia cu `main`. Numele de aici sunt EXACTE.
## Modelele pe care se face ruptura de accente. Fara lista asta, `Church_Body`
## ar prinde si biserica din Khuzhir (Baikal) — vezi CLASSES_BY_MODEL.
const SPLIT_MODELS := {
	"aeolian_house_a": true, "aeolian_house_b": true, "aeolian_house_c": true,
	"stromboli_church": true,
	# Fatadele Chongqing: 35% din instantele asezate pe Track12 (231 din 652),
	# adica peretii coridorului prin care se conduce. Corpul ia betonul, iar
	# acoperisul (slot 20) si firmele aprinse (slot 30) raman pictate — pe o
	# pista de noapte firmele sunt chiar semnalul, deci o clasa pusa pe tot
	# corpul ar fi sters exact ce trebuie sa se vada.
	"shophouse_a": true, "shophouse_b": true, "shophouse_c": true,
	# Zidaria incasa (Machu Picchu). Piesele au iarba pe coronament — slotul
	# 12 CACTUS_GREEN — pe ACELASI nod de mesh ca piatra (masurat, fiecare
	# piesa de zidarie e un singur MeshInstance3D). Fara ruptura, clasa
	# `inca_stone` pusa pe tot nodul ar fi STERS iarba: e 6.3% din arie pe
	# ziduri, deci n-ar fi mutat culoarea piesei, dar ar fi taiat chiar
	# semnalul „ruina veche, nu zid nou". Acelasi tipar ca acacia-umbrela.
	"inca_wall_a": true, "inca_wall_b": true,
	"inca_wall_c": true,
	"inca_stair_a": true, "inca_stair_b": true,
	# sun_temple: 12 CACTUS_GREEN pe coronamentul neregulat, la fel ca zidurile.
	# Corpul e 3 (68.5%) + 29 (25.5%), amandoua piatra, deci raman impreuna.
	"sun_temple": true,
	# inca_bridge_ledge: 12 CACTUS_GREEN e 2.5% — sub pragul la care ruptura
	# mai plateste un nod in plus, si piesa sta pe prapastie, nu langa ochi.
	# inca_house_b (ruina) NU se rupe: muschiul e 22.8%, adica o TREIME din
	# silueta, iar inventarul o spune explicit — intervalele de y se SUPRAPUN
	# (muschi 0.85..2.83 peste zid 0..2.83), deci o ruptura pe inaltime ar
	# taia gresit. Ramane integral pe atlas (vezi CLASSES_BY_MODEL).
	# Arcada de biserica rupestra (Cappadocia, POI F). Aici ruptura merge in
	# sens INVERS fata de casele de mai sus: acolo CORPUL ia clasa si accentul
	# ramane pictat pe atlas, aici accentul — frescele — ia clasa si corpul de
	# piatra ramane pe atlas, ca sa pastreze valoarea de tuf pe care i-o da
	# `_retint_tuff`. Mecanica e aceeasi, doar rolurile sunt schimbate.
	#
	# Si e prima intrare LIMITATA LA GRUPURI, nu `true`. Aceeasi piesa e si
	# arcada din piata Goreme si arcul de fereastra din stanca goala, unde
	# `SLOT_REMAP_BY_MODEL["church_arch"]` a mutat deja frescele pe tuf. Acolo
	# ruptura pe [2, 4] nu gaseste frescele — le gaseste MUTATE, deci taia
	# intradosul (slotul 4, ajuns pe 19) si ii dadea textura de pictura.
	# Masurat inainte de garda: 33 de noduri `_Accente`, adica TOATE arcadele
	# pistei, inclusiv cele doua din sat. Exact capcana `House_` de mai sus,
	# a doua oara: o mapare pe model e globala pe pista.
	"church_arch": ["F1_Gura", "F2_Sala1", "F3_Gat", "F4_Sala2", "F5_Ocol"],
	# Serengeti: kopje-ul de start si spartura Lerai au IARBA pe platou
	# (slotul 13, DRY_VEGETATION — masurat pe .glb cu tools/_tmp_probe_serkit:
	# kopje_camp pe [3, 4, 13, 29], crater_gap pe [3, 4, 13, 29]). Granitul
	# (clasa triplanara) ar fi sters-o; ruptura o lasa pe atlas, ca la case.
	# Bolovanii si kopje-ul-rampa sunt pe [3, 4, 29] curat: nu se rup.
	"kopje_camp": true,
	# Boma masai: nodul `Maasai_Boma` (colibele) e 36.6% LUT (slot 2), 43.5%
	# PAIE (slot 13) si 19.8% usa (slot 4) — masurat cu probe_slots.gd pe GLB-ul
	# re-exportat. `termite_clay` pus pe tot nodul cadea si peste paie: masurat,
	# dala aterizeaza pe (189.7, 116.2, 74.3), deci paiele (#AF9F4E, luminanta
	# 157) se INCHIDEAU la 129 (-18%) si se mutau din ocru-galben in caramiziu
	# de lut, iar usa (#67421F, luminanta 71) se DESCHIDEA la 129 (+81%).
	# Adica exact acoperisurile reclamate ca plate isi pierdeau si culoarea.
	# Ruptura lasa pe corp doar lutul; paiele si usa pleaca in `_Accente` si
	# raman pe atlas. Zero materiale in plus.
	"maasai_boma": true,
	"crater_gap": true,
	# Orizontul: Lengai are varful alb (22) pe [2, 22, 29], peretele opus are
	# padurea de pe creasta (12, 21) pe [3, 12, 21]. Aceeasi ruptura, ca
	# granitul sa nu stearga exact benzile care le fac lizibile de la 200 m.
	"lengai": true,
	"crater_far_wall": true,
	# Serengeti: SCOARTA (clasa `bark`) pe copacii cu trunchi + coroana pe
	# ACELASI nod de mesh — masurat cu tools/probe_slots.gd, fiecare copac al
	# kitului e un singur MeshInstance3D (verificat pe fisier, vezi tabelul de
	# mai jos la ACCENT_SPLIT). Fara ruptura, clasa pe tot nodul ar face
	# coroana maro (trunchiul e sub 30% din arie) SAU trunchiul verde.
	#
	# Acacia-umbrela: slot 28 (LOG_DARK) 22.7-29.3% e trunchiul, restul —
	# 12/13/21 — coroana. Se rupe pe toate trei variantele.
	"acacia_umbrella_a": true,
	"acacia_umbrella_b": true,
	"acacia_umbrella_c": true,
	# fig_tree: NU `true`. Fisierul `fig_tree.glb` exista de DOUA ori in kit-uri
	# diferite — assets/models/serengeti/plants/ SI assets/models/stromboli/
	# trees/ — si SPLIT_MODELS cheie pe STEM DE FISIER (scene_file_path fara
	# extensie), nu pe cale intreaga. Verificat: ambele se numesc "fig_tree",
	# deci o intrare `true` ar fi incercat ruptura si pe smochinul de Stromboli
	# (Track11, grupul "7)Coasta de est"). Acolo insa piesa e deja DOUA noduri
	# separate (Fig_Canopy/Fig_Trunk, vezi STROMBOLI_CLASSES in track_decor.gd)
	# — `Palette.split_accents` ar fi gasit un mesh fara UV-uri colapsate pe
	# nodul gresit sau, mai rau, ar fi rupt un nod care nu mai are nevoie.
	# Limitata la grupurile Serengeti (mecanica `church_arch`), memoria
	# `nume-noduri-nu-sunt-unice`.
	"fig_tree": ["ZoneC_VadulMara", "ZoneD_PadureaDeCeata", "ZoneE_Buza",
		"ZoneG_FundulCraterului"],
	# baobab si dead_tree NU intra: sunt deja MONOCROME (100% pe un singur
	# slot, masurat) — nimic de rupt, clasa (unde se aplica) merge direct pe
	# tot nodul prin CLASSES_BY_MODEL. fever_tree NU intra: vezi nota de
	# respingere de la CLASSES_BY_MODEL — trunchiul ei e chiar accentul.
	#
	# LOTUL FRUNZISULUI (integrare): coroanele iau clasa `acacia_canopy` prin
	# ruptura INVERSATA (`ACCENT_HOLDS_CLASS`) — corpul/trunchiul ramane pe
	# atlas sau ia `bark`, accentul/coroana ia clasa. Acaciile de mai sus se
	# rup deja; aici intra speciile pe care numai frunzisul le cere.
	#
	# `fig_tree` NU e `true`, desi lotul frunzisului il scrisese asa: verificat
	# la integrare prin instantiere headless, `assets/models/serengeti/plants/`
	# are UN nod (`Fig_Tree`), iar `assets/models/stromboli/trees/` are DOUA
	# (`Fig_Canopy`, `Fig_Trunk`). Cum `SPLIT_MODELS` cheie pe STEM de fisier
	# (`get_file().get_basename()`, vezi `_split_shutters`), un `true` ar fi
	# rupt si smochinul de pe Track11. Ramane limitarea pe grupuri de mai sus.
	"fever_tree": true,
	# euphorbia: NU `true` (din sep 2026). `jodhpur/plants/euphorbia.glb` are
	# ACELASI stem ca `serengeti/plants/euphorbia.glb` (masurat,
	# jodhpur_masuratori.md), deci `true` rupea si cactusul Jodhpur si ii
	# punea `acacia_canopy` pe accent (+1 material, frunzis pe cactus).
	# Limitata la cele 8 zone Serengeti in care e asezata (Track14.tscn,
	# numarat: A 3, B 3, C 3, D 19, E 5, F 6, G 6, H 87) — mecanica
	# `fig_tree`. Serengeti ramane neschimbat.
	"euphorbia": ["ZoneA_Camp", "ZoneB_RaulDeGnu", "ZoneC_VadulMara",
		"ZoneD_PadureaDeCeata", "ZoneE_Buza", "ZoneF_Serpentine",
		"ZoneG_FundulCraterului", "ZoneH_Spartura"],
	# Elefantul (Serengeti, lotul ELEFANTULUI): pielea (corp + cap/picioare,
	# sloturile 2 si 29, 91.5% din arie masurata) ia clasa `elephant_hide`, dar
	# fildesii (slot 22, 8.5%, z=[-4.02,-2.66] — fata modelului) raman
	# pictati pe FOAM_WHITE, ca sa nu-i imbrace clasa in piele. Un singur nod
	# de mesh (`Elephant_Mesh`), deci foloseste aceeasi mecanica de ruptura ca
	# `church_arch`/`fig_tree`/`fever_tree`: ACCENT_HOLDS_CLASS, nu
	# CLASSES_BY_MODEL direct pe corp.
	"elephant": true,
	# Rata (Fiordland, lotul PADUREA DE FAGI): tufa densa cu flori rosii, UN
	# SINGUR nod de mesh (`Rata`, nu Trunk+Crown ca fagii). Masurat
	# (probe_slots.gd): 28.2% slot 7 (KERB_RED, florile — brief-ul le numeste
	# accent), 38.8% slot 21 (TROPICAL_GREEN) + 33.0% slot 28 (LOG_DARK), toate
	# TREI pe acelasi interval de inaltime (0-3.67 m) — nu se separa pe
	# verticala, e o tufa amestecata, nu copac cu coroana dezlipita de
	# trunchi (masuratori §2: raport raza-baza/semi-latime 0.930 -> `hull`).
	# `true` (nu lista de grupuri): fisierul e unic in tot proiectul (verificat
	# cu find pe assets/models), deci nu exista risc de coliziune de nume ca la
	# `fig_tree`.
	"rata_tree": true,
	# guard_rock (Fiordland, lotul STANCA UDA): un singur nod (`Rock_002`),
	# 74.0% MARBLE_GREY (corp, y 0.00-0.46) + 26.0% TROPICAL_GREEN (capacul de
	# muschi, y 0.44-0.58, piesa 0.585 m). Corectie fata de runda 1 a lotului:
	# refuzasem ruptura comparand procentul cu pragul de ~20% masurat la
	# torrent_chute/Overhang, dar acolo procentul era doar UN SIMPTOM — cauza
	# reala e SUPRAPUNEREA de y ("intervalele de y se suprapun cu stanca").
	# Aici suprapunerea e 0.02 m din 0.585 m (3.4%), fata de Overhang unde
	# muschiul e interlacat pe toata fata peretelui — nu acelasi caz. Ruptura
	# e curata: corpul ramane piatra, capacul ramane pictat.
	"guard_rock": true,
	# --- Jodhpur: casele albastre cu accente pe peretele insusi (masurat,
	# jodhpur_masuratori.md §1): a — obloane 9 WOOD 15.2% (y 2.93-4.03);
	# b — planta 12 CACTUS_GREEN 9.6% + rezervorul 28 LOG_DARK 8.7%; c —
	# rezervorul 28 LOG_DARK 18.4%. Varul (clasa) ar fi sters obloanele si
	# ar fi facut rezervorul negru albastru — exact punctul grafic pe care
	# brief-ul §4 il cere negru. d/e/haveli au peretele 100% pe 22: nu se rup.
	"blue_house_a": true, "blue_house_b": true, "blue_house_c": true,
	# Bastionul: gurile de tragere (20 VOLCANIC_BLACK, 20.9%, y 5.3-8.9) sunt
	# pe acelasi nod cu gresia; raman pictate, gresia ia `red_sandstone`.
	"fort_bastion": true,
}

const ACCENT_SPLIT := {
	"House_A": Palette.FOAM_WHITE,
	"House_B": Palette.FOAM_WHITE,
	"House_C": Palette.FOAM_WHITE,
	"Church_Body": Palette.FOAM_WHITE,
	"Church_Tower": Palette.FOAM_WHITE,
	# Zidaria incasa. ATENTIE la sensul valorii, verificat pe cod si pe captura:
	# `split_accents` pune in CORP (`mi.mesh`) triunghiurile ale caror sloturi
	# sunt in lista, si in `_Accente` pe toate celelalte — iar clasa cade pe
	# CORP. Deci aici se enumera PIATRA, nu iarba.
	#
	# Prima versiune avea aici CACTUS_GREEN, „ca sa se pastreze iarba", si
	# efectul era exact pe dos: iarba (6.3% din arie) lua textura de granit si
	# tot zidul ramanea pe atlasul plat. Masurat pe captura A/B
	# (tools/probe_mp_wall_shot.gd, caseta pe primul zid): rgb(88,63,37)
	# std 21.08 fara clasa, rgb(88,63,37) std 21.09 cu ea — identic la cifra,
	# adica materialul nu ajungea niciodata pe piatra. Casa, care NU se rupe,
	# se schimba in aceeasi captura: rgb(71,75,79) -> rgb(80,68,54).
	#
	# Piatra zidurilor sta pe 3 (ROCK_LIGHT), 29 (MARBLE_GREY) si, la
	# inca_wall_b, 4 (ROCK_DARK) pentru nise.
	#
	# CORONAMENTUL (slotul 12, CACTUS_GREEN, y 2.31-2.49) INTRA SI EL IN CORP,
	# nu mai ramane accent pictat. Redactarea de dinainte il tinea in
	# `_Accente` „ca iarba de coronament" — pe un zid izolat e corect, pe un
	# CAMP nu. In Piata Sacra sunt ~850 de piese de zid, deci ~850 de dungi
	# verzi late de 18 cm, si fiindca ochiul sta la 10 m fiecare zid din
	# planul doi isi arata coronamentul fix acolo unde zidul din planul intai
	# isi are talpa. Criticul orb al rundei 12 a citit exact asta, fara sa
	# stie ce e: „lespezile au partea de sus verde si par bucati de teren
	# decupate, nu zidarie". Decupajul A_r12_f000 confirma: linia verde e
	# continua pe fiecare lespede din cadru.
	#
	# Iarba nu dispare din cetate — ramane iarba TERENULUI intre incinte, care
	# e ce trebuie sa se vada in curti (si ce cere bara). Ce dispare e chenarul
	# verde de pe piatra. 12 e slot GLOBAL (bromelii, muschi, tent_b): de aia
	# schimbarea se face aici, pe cheia de NOD a zidului, nu pe o mapare de
	# slot — memoria `nume-noduri-nu-sunt-unice` invers, cheia e destul de
	# ingusta.
	"Inca_Wall_A": [Palette.ROCK_LIGHT, Palette.MARBLE_GREY,
		Palette.CACTUS_GREEN],
	"Inca_Wall_B": [Palette.ROCK_LIGHT, Palette.ROCK_DARK,
		Palette.MARBLE_GREY, Palette.CACTUS_GREEN],
	# `Inca_Wall_C` lipsea si de aici si din CLASSES_BY_MODEL, desi inventarul
	# o masurase ca separandu-se LA FEL de curat ca A (corp 3+29 91.5%, accent
	# 12 la y 2.33-2.43, verdict "DA"). Consecinta, gasita la POI A: din 352
	# de piese de zid asezate in Piata Sacra, 48 (13%) ramaneau pe atlasul
	# brut langa 304 clasate — aceeasi ruptura de familie ca la piesele-erou,
	# doar mai mica. Piesa se foloseste exact acolo unde se vede cel mai bine:
	# la capetele scurte de incinta, adica in colturi.
	"Inca_Wall_C": [Palette.ROCK_LIGHT, Palette.MARBLE_GREY,
		Palette.CACTUS_GREEN],
	"Inca_Stair_A": [Palette.ROCK_LIGHT, Palette.MARBLE_GREY],
	"Inca_Stair_B": [Palette.ROCK_LIGHT, Palette.MARBLE_GREY],
	# Templul Soarelui: 3 (68.5%) + 29 (25.5%) sunt piatra si raman pe corp;
	# iarba de coronament (12) pleaca in `_Accente`, ca la ziduri.
	"Sun_Temple": [Palette.ROCK_LIGHT, Palette.MARBLE_GREY],
	# Chongqing: DOUA sloturi pastrate, nu unul. Masurat pe inaltime, slotul 29
	# tine parterul (y 0..3.1) si slotul 8 etajele (y 2.9..5.8) — acelasi perete
	# de beton, taiat pe orizontala din motive de compozitie, nu doua materiale.
	# Cu un singur slot pastrat, jumatate din fatada ramanea plata langa
	# jumatatea texturata, adica exact cusatura pe care ruptura o evita.
	"ShophouseA": [Palette.CONCRETE, Palette.MARBLE_GREY],
	"ShophouseB": [Palette.CONCRETE, Palette.MARBLE_GREY],
	"ShophouseC": [Palette.CONCRETE, Palette.MARBLE_GREY],
	# Arcada de biserica rupestra: se PASTREAZA piatra (SAND_SHADOW 2 pentru
	# fetele care prind lumina de torta, ROCK_DARK 4 pentru intrados), si se
	# rup frescele — TILE_TERRACOTTA 23, LARCH_RUST 27 si VOLCANIC_BLACK 20,
	# adica exact `FRESCO_RED` / `FRESCO_RUST` / `FRESCO_DARK` din
	# `build_cappadocia_underground.py`.
	#
	# Masurat pe .glb (tools/probe_fresco_tmp.gd): 515 tri pe slotul 2, 283 pe
	# 4, 278 pe 23, 156 pe 20 si 64 pe 27 — frescele sunt 498 din 1296 de
	# triunghiuri, dar doar 10,7% din ARIE, fiindca sunt benzi si medalioane
	# subtiri pe o arcada de 255 m². De aia nu se putea pune clasa pe toata
	# piesa: ar fi imbracat 89% piatra intr-o textura de pictura.
	"Church_Arch": [Palette.SAND_SHADOW, Palette.ROCK_DARK],
	# Serengeti: lista e ce ramane in CORP (sloturile de granit, 3/4/29), ca
	# la `House_A` unde ramane varul; tot restul — iarba de pe platou (13) —
	# trece in `_Accente` si ramane pe atlas. Corpul ia granitul din
	# CLASSES_BY_MODEL.
	"Kopje_Camp": [Palette.ROCK_LIGHT, Palette.ROCK_DARK, Palette.MARBLE_GREY],
	# Boma masai: lista e ce RAMANE in corp, adica doar LUTUL peretilor
	# (SAND_SHADOW 2, 36.6% din vertecsi, y 0.00..1.70). Paiele (DRY_VEGETATION
	# 13, 43.5%, y 1.65..3.69 — acoperisul) si usa (ROCK_DARK 4) trec in
	# `Maasai_Boma_Accente` si raman pictate pe atlas.
	"Maasai_Boma": [Palette.SAND_SHADOW],
	"Crater_Gap": [Palette.ROCK_LIGHT, Palette.ROCK_DARK, Palette.MARBLE_GREY],
	"Lengai": [Palette.SAND_SHADOW, Palette.MARBLE_GREY],
	"Crater_Far_Wall": [Palette.ROCK_LIGHT],
	# Lotul FRUNZISULUI (Serengeti): `keep_slot` e trunchiul, nu coroana — pe
	# dos fata de intrarile de mai sus, unde corpul mare (var/piatra) ramane si
	# accentul mic pleaca. Aici piesa mica (trunchiul) ramane pe atlas si masa
	# mare (coroana) pleaca in `_Accente`, ca sa poata primi `acacia_canopy`
	# fara sa piarda AO-ul si vertex colors ale trunchiului scoartei — acela
	# e terenul clasei `bark` (alt agent), nu al acestui lot.
	#
	# Acaciile-umbrela: dupa `SLOT_REMAP_BY_MODEL` (13,21 -> 12), coroana e
	# UN slot (12); trunchiul ramane 28 (LOG_DARK in .glb, folosit doar ca
	# eticheta de slot aici, nu ca "barne siberiene"). keep_slot = 28.
	"Acacia_Umbrella_A": Palette.LOG_DARK,
	"Acacia_Umbrella_B": Palette.LOG_DARK,
	"Acacia_Umbrella_C": Palette.LOG_DARK,
	# fever_tree: trunchi pe 0 (SAND_LIGHT in .glb — kitul l-a desenat pe
	# galbenul scoartei acaciei-febra, nu pe nisip; eticheta de slot, nu de
	# rol). Masurat (probe_slots.gd): 33.9% verts pe 0, y 0.00..9.42 — acopera
	# si o parte din baza coroanei (trunchiul se subtiaza in ramuri), dar
	# ruptura taie pe SLOT, nu pe inaltime, deci nu conteaza unde se opreste
	# vizual trunchiul.
	"Fever_Tree": Palette.SAND_LIGHT,
	# fig_tree: trunchi pe 9 (WOOD_WEATHERED, 27.7% verts, y 0.00..10.14) SI
	# LICHENII pe 22 (FOAM_WHITE, 16.7% verts, y 5.03..8.23) raman AMBELE pe
	# corp — nu doar trunchiul.
	#
	# Ce e slotul 22, verificat la INTEGRARE in sursa kitului (nu dedus din
	# nuanta): `tools/blender/build_serengeti_plants.py:48` defineste
	# `LICHEN = FOAM_WHITE`, iar linia 151 ii numeste „fire care atarna de sub
	# coroana (identitatea padurii de ceata)". Cele doua loturi paralele au
	# ajuns la aceeasi concluzie — pastreaza 22 — din doua motive diferite:
	# lotul scoartei fiindca lichenii sunt identitatea POI-ului D, lotul
	# frunzisului fiindca H 167 e in alta familie decat verdele 12/21
	# (H 87-117). Al doilea argument e adevarat dar accidental; primul e cel
	# care tine.
	#
	# Consecinta de integrare: lotul scoartei ii trimitea in `_Accente`,
	# corect sub presupunerea LUI (accentul ramane pe atlas). Cu clasa
	# `acacia_canopy` pe accent — ruptura inversata de aici — acolo ar fi fost
	# ACOPERITI. Raman pe corp. `split_accents` accepta o LISTA de sloturi de
	# pastrat (ca la ShophouseA/B/C), deci accentul ramane doar cu 12/21.
	"Fig_Tree": [Palette.WOOD_WEATHERED, Palette.FOAM_WHITE],
	# euphorbia: "trunchi" (baza carnoasa, sub coroana candelabru) pe 28
	# (LOG_DARK), 5.9% verts, y 0.00..1.60 — cea mai mica piesa din patru.
	"Euphorbia": Palette.LOG_DARK,
	# Elefantul: se pastreaza DOAR fildesii (22, FOAM_WHITE) pe corp — restul
	# (2 SAND_SHADOW/cap-picioare, 29 MARBLE_GREY/corp, remapate deja de
	# SLOT_REMAP_BY_MODEL pe ASPHALT/VOLCANIC_BLACK inainte sa ajunga aici,
	# vezi nota de acolo) trece in `_Accente` si ia `elephant_hide`. Pe dos
	# fata de `Fig_Tree` (unde piesa mica ramane si masa mare pleaca): aici
	# ambele sloturi mari pleaca si doar accentul alb ramane, ca la
	# `Kopje_Camp` unde iarba (mica) ramane si granitul (mare) e cel ce
	# primeste clasa prin ACCENT_HOLDS_CLASS.
	"Elephant_Mesh": Palette.FOAM_WHITE,
	# Rata (Fiordland): se PASTREAZA slotul 7 (KERB_RED, florile, piesa MICA)
	# pe corp, ca la `Fig_Tree`/`Fever_Tree` de mai sus — nu ca la
	# `Elephant_Mesh` (unde piesa mica e cea care pleaca). Tufa mare
	# (sloturile 21+28, 71.8% din arie) pleaca in `_Accente` si ia clasa
	# `beech_canopy` prin ACCENT_HOLDS_CLASS mai jos, iar florile raman
	# pictate pe atlas, ca sa nu le imbrace clasa de frunzis. Masurat
	# (probe_slots.gd): slot 7 y 1.23..3.45, aproape acelasi interval ca 21
	# (0.30..3.67) — nu se poate separa pe inaltime, doar pe slot.
	"Rata": Palette.KERB_RED,
	# guard_rock (Fiordland): corpul de piatra (29 MARBLE_GREY, 74.0%) ramane
	# in CORP si primeste `wet_gneiss` (CLASSES_BY_MODEL, mai jos); capacul de
	# muschi (21 TROPICAL_GREEN, 26.0%, y 0.44-0.58) pleaca in `_Accente` si
	# ramane pictat pe atlas — e deja verdele corect, nu are nevoie de clasa.
	"Rock_002": Palette.MARBLE_GREY,
	# Jodhpur: pe CORP ramane varul (22); obloanele/planta/rezervorul pleaca
	# in `_Accente`. Prinde si `House_Wall_001..004` (Godot rescrie `.001`),
	# dar numai pe stem-urile din SPLIT_MODELS — cafe_shed (Fiordland) are si
	# el un `House_Wall` si NU e acolo.
	"House_Wall": Palette.FOAM_WHITE,
	"Bastion_Stone": Palette.ROCK_LIGHT,
}

## Modelele la care ruptura are rolurile INVERSATE: clasa sta pe ACCENT, nu pe
## corp.
##
## Conventia din Chongqing (`shophouse_*`) e ca accentul e partea care ARDE, si
## de aia `_apply_glow` si `_apply_tint` isi pun materialul DOAR pe accent cand
## modelul e rupt. Pe arcada de biserica e exact pe dos: accentul tine frescele
## (clasa `fresco`) si corpul e piatra care poate primi lumina de torta.
##
## Fara lista asta frescele erau invizibile si nu se vedea de ce: clasa se
## aplica corect pe toate cele 31 de arcade (verificat cu un print), si abia
## `_apply_glow` — F4_Sala2 are 135 de noduri cu `metadata/lumina` — o inlocuia
## cu materialul emisiv doua apeluri mai tarziu. Un `material_override` scris
## de doua ori nu lasa nicio urma in log si nicio garda nu-l prinde.
const ACCENT_HOLDS_CLASS := {
	"church_arch": true,
	# Lotul FRUNZISULUI (Serengeti): coroana (accent) ia `acacia_canopy`,
	# trunchiul (corp) ramane pe atlas — teren separat, clasa `bark`.
	"acacia_umbrella_a": true,
	"acacia_umbrella_b": true,
	"acacia_umbrella_c": true,
	"fever_tree": true,
	"fig_tree": true,
	"euphorbia": true,
	# Elefantul: accentul (corpul, cap, picioare — restul dupa ce fildesii au
	# ramas pe corp) ia `elephant_hide`; corpul original ramane doar cu
	# fildesii pe atlas.
	"elephant": true,
	# Rata (Fiordland, lotul PADUREA DE FAGI): accentul (`Rata_Accente`, tufa
	# de frunzis 21+28) ia `beech_canopy`; corpul original ramane cu florile
	# (KERB_RED) pe atlas. Nu exista astazi vreo instanta cu metadata
	# `racire`/`lumina` pe Rata, dar intrarea tine constanta consistenta cu
	# restul ruptelor inversate, pentru cazul in care un lot viitor adauga.
	"rata_tree": true,
}


## Clase legate de un MODEL anume, nu de un nume de nod.
##
## Exista fiindca maparea din `prop_classes()` e GLOBALA, iar numele de noduri
## nu sunt unice intre kituri: `stromboli_church.glb` si `khuzhir_church.glb`
## au amandoua un `Church_Body`, iar `village_house.glb` (Okinawa, Dunele) are
## `House_Sand`/`House_Stone`. Prima versiune a maparii de var a prins si
## biserica siberiana — masurat, Track10 lua un material in plus si biserica de
## lemn ar fi primit tencuiala mediteraneana.
##
## Cheia e numele fisierului .glb (fara extensie); valoarea, o mapare
## nume-de-parte -> clasa, aplicata DOAR instantelor modelului aluia.
const CLASSES_BY_MODEL := {
	# --- Cappadocia: faleza in benzi a canionului rosu (POI D) --------------
	#
	# Modulul vine din kit cu UV-uri pe atlas si matura sloturile 19/23/27/2/1
	# — masurat cu tools/ProbeCappSlots: 31% CREM (19, #E9DCC0) si ZERO rosu.
	# Pe el, canionul "rosu" din brief §2 iesea crem, ca restul pistei.
	#
	# Clasa il imbraca in sisturi stratificate tentate spre caramiziu (vezi
	# `red_valley_tuff` in palette.gd, unde multiplicatorul e masurat din
	# crop-ul de referinta). E un material in plus la garda, cheltuit
	# DELIBERAT pe o CLASA de assets, nu pe o piesa — regula din CLAUDE.md.
	"cliff_band_module": {
		"Cliff_Band_Module": Palette.TRI_PREFIX + "red_valley_tuff",
	},

	# --- Cappadocia: tuful CREM (hornurile si rudele lor) -------------------
	#
	# Pana aici, din cele 44 de .glb-uri ale kitului doar modulul de faleza de
	# mai sus avea textura. Hornurile — piesa cea mai repetata a pistei si
	# subiectul ei — stateau pe atlas curat, adica pe culoare plata: exact
	# diferenta pe care style_bible §4 o masoara fata de Reckless Racing 3 /
	# Beach Buggy Racing.
	#
	# TRIPLANAR, obligatoriu, nu o alegere de gust: masurat pe toate cele 44 de
	# fisiere (tools/probe_capp_kit_slots.gd), UV-urile kitului sunt COLAPSATE
	# pe centrele sloturilor — multi `u` distincti si un singur `v`. Pe UV-urile
	# alea orice textura ar citi un texel, deci fata ar ramane la fel de plata
	# (memoria `uv-colapsat-nu-e-un-interval`). Proiectia e in spatiul LUMII:
	# piesele stau pe loc, si stratele curg continuu dintr-un horn in faleza de
	# langa el, ca la `volcanic_rock` pe Stromboli.
	#
	# CINE intra, si pe ce cifra. Regula (#313) e ca o clasa STERGE culorile din
	# sloturi, deci primesc textura doar piesele monocrome. Aici „monocrom" a
	# cerut o masuratoare in DOI pasi, fiindca .glb-ul brut minte: `_retint_tuff`
	# muta la incarcare slotul 1 pe CONCRETE si 2 pe MARBLE_GREY (vezi
	# TUFF_UV_REMAP). Masurat DUPA remapare (tools/probe_capp_familie.gd),
	# hornurile stau pe 19/29/8/20 — nuante 0.114, 0.111, 0.108 si saturatii
	# 0.18, 0.07, 0.16, 0.08. Adica O SINGURA familie de culoare, despartita
	# doar prin VALOARE: n-au ce pierde.
	#
	# Pe .glb brut aceleasi piese arata un ecart de saturatie de 0.63, ceea ce
	# le-ar fi descalificat pe toate — si asta e chiar motivul pentru care
	# masuratoarea se face dupa remapare, nu pe fisier.
	#
	# CINE NU intra, desi e din acelasi kit si pare la fel:
	#   `cave_house_a/b/c`, `dovecote`  — ecart de saturatie 0.63: au usi si
	#       obloane pictate (sloturile 9 si 3, saturatie 0.60-0.64). Textura
	#       ar fi costat exact accentul pentru care exista piesa. Aceeasi
	#       decizie ca la `House_A/B/C` de pe Stromboli.
	#   `rock_church_facade`            — 0.63, are slotul 4 (#67421F) pe
	#       deschiderile sapate; alea sunt adancimea fatadei, nu suprafata ei.
	#   `farmhouse`                     — 0.57, acoperisul pe slotul 3.
	#   `red_mesa`                      — acolo rosul e INTENTIA (vezi nota de
	#       la TUFF_UV_MODELS), si oricum e `red_valley_tuff`, nu crem.
	#   `erciyes`, siluetele de orizont — sunt cer, nu roca de prim-plan
	#       (memoria `caster-departat-fura-umbra`).
	#
	# Zero materiale in plus la garda peste unul singur: `tuff_cream` refoloseste
	# dala lui `red_valley_tuff`, deci nu se dubleaza nicio imagine in memorie —
	# se schimba doar ridicarea si tenta, ca la volcanic_rock / macchia_dry.
	# Track13 era la 20/38 materiale inainte.
	"chimney_a": {"Chimney_A": Palette.TRI_PREFIX + "tuff_cream"},
	"chimney_b": {"Chimney_B": Palette.TRI_PREFIX + "tuff_cream"},
	"chimney_c": {"Chimney_C": Palette.TRI_PREFIX + "tuff_cream"},
	"chimney_d": {"Chimney_D": Palette.TRI_PREFIX + "tuff_cream"},
	"chimney_mushroom": {
		"Chimney_Mushroom": Palette.TRI_PREFIX + "tuff_cream",
	},
	"chimney_triple": {"Chimney_Triple": Palette.TRI_PREFIX + "tuff_cream"},
	"cracked_chimney_a": {
		"Cracked_Chimney_A": Palette.TRI_PREFIX + "tuff_cream",
	},
	"cracked_chimney_b": {
		"Cracked_Chimney_B": Palette.TRI_PREFIX + "tuff_cream",
	},
	"cracked_chimney_c": {
		"Cracked_Chimney_C": Palette.TRI_PREFIX + "tuff_cream",
	},
	# Poarta geamana (POI A) si gura de pestera: acelasi tuf, si sunt piesele
	# prin care se TRECE, deci se vad de la un metru.
	"twin_chimney_gate": {
		"Twin_Chimney_Gate": Palette.TRI_PREFIX + "tuff_cream",
	},
	"cave_entrance": {"Cave_Entrance": Palette.TRI_PREFIX + "tuff_cream"},
	# Grohotisul: 100% pe slotul 19, cel mai monocrom din kit. Nu intra insa tot,
	# fiindca sub banda ingusta din style_bible §4 granulatia cade in mipmap si
	# textura iese plata oricat de corecta ar fi maparea. Masurat pe gabarit:
	# `talus_block` 2.18 x 1.30 x 1.73 m — intra; `talus_cobble` 1.81 x 0.56 —
	# la limita, si e piesa cea mai marunta din campul de moloz; `talus_gravel`
	# 3.72 x 0.23 x 2.40 m — o FOAIE de pietris de 23 cm grosime, vazuta razant
	# de la inaltimea ochiului, deci lata pe hartie si subtire pe ecran.
	# Aceeasi lectie ca `Bollard` si `Jib` pe Chongqing.
	"talus_block": {"Talus_Block": Palette.TRI_PREFIX + "tuff_cream"},

	"stromboli_church": {
		"Church_Body": Palette.TRI_PREFIX + "village_plaster",
	},

	# Fiordland (POI A/H, docs/asset_briefs/fiordland_vitrina.md "Punct
	# deschis"): `House_Roof` (`cafe_shed`) si `House_Roof_001` (`lodge`,
	# acelasi prefix — `_class_for`/bucla de mai jos fac `begins_with`, nu
	# egalitate exacta) COINCID cu `House_Roof` din `village_house.glb`
	# (landmark 6, Okinawa/Dunele), care intra in `prop_classes()` GLOBAL
	# cu clasa `roof_tiles` (memoria `nume-noduri-nu-sunt-unice`).
	# Verificat direct pe scena incarcata (nu presupus): `House_Roof`
	# primea `albedo_texture = res://assets/textures/classes/roof_tiles.png`
	# in loc de atlasul comun — media acelei texturi e (154,113,82), adica
	# exact tanul #BB8967 raportat in vitrina, nu o chestiune de slot sau
	# de lumina. Testat si respins pe captura: remap de slot (11 -> 8) NU
	# schimba nimic (acoperisul nu citeste deloc slotul din atlas cat timp
	# are alta textura), si `--rain=1` nu schimba nici el nuanta (nu e
	# reflexie speculara). `House_Wall`/`House_Wall_001` NU colideaza —
	# maparea globala n-are nicio cheie `House_Wall*` — si au iesit deja
	# corect pe `palette_atlas.png` la verificare, deci raman neatinse.
	# `ATLAS_PREFIX` forteaza inapoi materialul lumii doar pe acoperis,
	# fara sa atinga maparea globala (care ramane corecta pentru
	# `village_house`).
	"cafe_shed": {"House_Roof": Palette.ATLAS_PREFIX},
	"lodge": {"House_Roof_001": Palette.ATLAS_PREFIX},
	# Fiordland (POI A, runda 3 a criticului orb): `Boat` (cruise_boat.glb)
	# n-avea NICIO intrare aici, deci cadea pe fallback-ul implicit al lui
	# `apply_class_materials` — `world_material()`, materialul lumii cu
	# stratul triplanar de detaliu gandit pentru roca/lemn de teren
	# (style_bible §4). Pe carena ALBA (vopsea plata, nu piatra) acel strat
	# citea exact ce a numit criticul: "model de fibra de lemn/scoarta".
	# Verificat pe scena incarcata (tools/sv_boat_slots.gd), nu presupus:
	# materialul de pe `Boat` era `PaletteAtlas`-ul brut din GLB — nicio
	# coliziune de nume cu alt kit (nu e cazul `nume-noduri-nu-sunt-unice`).
	# `PLAIN_PREFIX` pastreaza acelasi atlas si acelasi AO din vertex color,
	# doar opreste `detail_enabled` — zero materiale noi la garda.
	"cruise_boat": {"Boat": Palette.PLAIN_PREFIX},
	# Fiordland (POI H, runda 6 a criticului orb): `luggage_container`
	# (containerul de bagaje de langa lodge) avea mesh-ul `Container` fara
	# NICIO intrare aici — nu se potriveste cu stem-ul "container" (alt kit,
	# Chongqing, `props_junk.glb`), deci cadea pe fallback-ul implicit al
	# lui `apply_class_materials`: `world_material()`, atlasul intins pe
	# UV-ul brut al cutiei. Exact mecanismul documentat mai sus la
	# `cruise_boat` (aceeasi capcana, alt model): pe o cutie simpla stratul
	# triplanar de detaliu iese curcubeu, nu vopsea plata. Verificat pe
	# .glb (mesh unic "Container", niciun nod `Container` in alt kit
	# fiordland). `PLAIN_PREFIX` pastreaza atlasul si AO-ul din vertex
	# color, opreste doar `detail_enabled` — zero materiale noi la garda.
	"luggage_container": {"Container": Palette.PLAIN_PREFIX},
	# Firidele din peretele stancii goale (Cappadocia, POI G): fundul lor ARDE.
	#
	# Fara asta o fereastra sapata e o pata neagra, si verdictul rundei 2 spune
	# exact ce se intampla atunci — „absentele arata cer, nu camere". Referinta
	# (Uchisar in sectiune) castiga tocmai prin deschideri LUMINATE cu interior
	# in spatele lor. `_remap_model_slots` a pus deja fundul firidei pe slotul
	# 30; aici primeste materialul care il face gura de pestera.
	#
	# [b]NU mai are emisie, si asta e reparatia rundei 3.[/b] Nota veche spunea
	# ca energia 2.0 e "fix cea folosita de ferestrele Chongqing-ului", deci
	# gratis la garda. Adevarat, si irelevant: Chongqing e o pista de NOAPTE,
	# unde o fereastra chiar e cea mai luminoasa suprafata din cadru. Cappadocia
	# e la RASARIT, si firida asta nu e o camera cu lumina aprinsa — e o gura de
	# pestera sapata intr-un perete pe care bate soarele.
	#
	# Masurat pe captura (frac 0.80, decupaj 1:1):
	#   interiorul firidei     luminanta 151.7
	#   zidul insorit langa ea luminanta  85.1   -> firida e de 1.78 ori mai
	#   zidul in umbra         luminanta  81.4      luminoasa decat zidul INSORIT
	#
	# O suprafata aflata in umbra, intr-o scobitura, care emite mai multa lumina
	# decat una batuta direct de soare: exact de aia citea RECLAMA si nu camera
	# sapata. Criticul orb a numit-o fara sa aiba cifra ("panouri luminoase"),
	# si e a doua oara cand piesa asta produce acelasi repros — prima data s-a
	# tratat marimea (scara 1.6 -> 0.7), care era doar jumatate din cauza.
	#
	# Acum fundul sta pe SAND_SHADOW, cel mai inchis tuf din paleta deja
	# folosit pe pista, fara emisie. Firida devine ce trebuia sa fie: o PATA
	# INTUNECATA in perete, adica singurul indiciu ca peretele are grosime.
	# Zero materiale in plus (slotul e pe atlasul comun, nu mai cere `glow`).
	# Nicio clasa si nicio emisie: firida ramane pe atlas, cu sloturile
	# corectate in SLOT_REMAP_BY_MODEL. Intrarea se pastreaza scrisa explicit
	# ca sa nu fie reintrodus `GLOW` din reflex — vezi nota de acolo.
	"hall_alcove": {},
	# Arcada de biserica rupestra: dupa ruptura de accente (ACCENT_SPLIT),
	# copilul `Church_Arch_Accente` tine numai benzile, medalioanele si crucile
	# — adica exact suprafata pictata — si primeste clasa `fresco`.
	#
	# TRIPLANAR, nu pe UV-uri, si nu e o alegere de gust: masurat pe .glb,
	# piesa are CINCI valori distincte de `u` si UNA singura de `v`, adica
	# UV-uri colapsate pe centrele sloturilor de atlas (memoria
	# `uv-colapsat-nu-e-un-interval`). Pusa pe UV-urile alea, orice textura ar
	# fi iesit o singura culoare — culoarea unui texel.
	#
	# Corpul NU e in mapare, deci ramane pe materialul lumii si isi pastreaza
	# valoarea de tuf de la `_retint_tuff`. Un `tri:` pe toata piesa ar fi
	# sters si frescele, si distinctia fata-intrados — memoria
	# `clase-pe-piese-de-kit`.
	"church_arch": {
		"Church_Arch_Accente": Palette.TRI_PREFIX + "fresco",
	},
	# Trestia de pe Stromboli, pe frunzisul mediteranean. Aici si nu in
	# STROMBOLI_CLASSES fiindca numele nodului ei (`Cane_Clump`) e PREFIX
	# pentru `Cane_Clump_A/B/C` din `props/sugar_cane.glb`, lanul Okinawei:
	# maparea globala ar fi imbracat si trestia de zahar in macchia si ar fi
	# adaugat un material pe Track08. Aceeasi capcana ca la `Church_Body`.
	"cane_clump": {
		"Cane_Clump": Palette.TRI_PREFIX + "macchia",
	},

	# --- Chongqing: ce ARDE noaptea -----------------------------------------
	#
	# Pe o pista de noapte, o fereastra nu e cea mai INCHISA suprafata din
	# cadru, e cea mai luminoasa. Kiturile picteaza deja ferestrele, firmele,
	# felinarele si stopurile pe slotul 30 (`GLOW` in build_chongqing_*.py) —
	# aici capata si lumina.
	#
	# DOUA energii, nu una per piesa, si nu fiindca ar arata mai bine: fiecare
	# energie distincta e un material in plus la garda (`glow_material` e
	# cache-uit per (slot, energie)). Prima versiune avea cinci trepte reglate
	# „dupa cat de aproape de camera trece piesa" si costa cinci materiale
	# pentru o diferenta pe care masuratoarea n-o vedea. Raman:
	#   2.0 — tot ce ajunge langa carosabil (ferestre, firme, felinare, stopuri)
	#   1.2 — siluetele de peste rau, care stau in ceata la 150-250 m si n-au
	#         voie sa concureze cu masinile (style_bible §1)
	# Cele 22 de modele de mai jos aduc astfel DOUA materiale, nu 22.
	# Containerele de pe cheiul Chaotianmen: 73% pe slotul 10 (rugina), deci
	# monocrome. Aici si nu in CHONGQING_CLASSES fiindca `props_junk.glb` —
	# gunoiul comun TUTUROR pistelor — are un `Container_A`, iar maparea aia e
	# globala si potriveste pe PREFIX: butoaiele si lazile de pe Dunele si
	# Okinawa ar fi capatat si ele clasa, plus un material in plus pe fiecare
	# pista. Verificat pe fisier. Aceeasi capcana ca la `Church_Body`.
	"container": {
		"Container": Palette.TRI_PREFIX + "rust_metal",
	},
	"shophouse_a": {
		# Doua roluri pe aceeasi casa, de cand fatada e rupta in doua
		# (ACCENT_SPLIT): CORPUL — parterul si etajele, sloturile 29 si 8 —
		# ia betonul, iar copilul `_Accente`, care tine acoperisul (slot 20)
		# si firmele (slot 30), ramane pe atlas si CONTINUA sa arda.
		#
		"ShophouseA": Palette.TRI_PREFIX + "city_concrete",
		"ShophouseA_Accente": Palette.GLOW_PREFIX + "30|2.0",
	},
	"shophouse_b": {
		# Doua roluri pe aceeasi casa, de cand fatada e rupta in doua
		# (ACCENT_SPLIT): CORPUL — parterul si etajele, sloturile 29 si 8 —
		# ia betonul, iar copilul `_Accente`, care tine acoperisul (slot 20)
		# si firmele (slot 30), ramane pe atlas si CONTINUA sa arda.
		#
		"ShophouseB": Palette.TRI_PREFIX + "city_concrete",
		"ShophouseB_Accente": Palette.GLOW_PREFIX + "30|2.0",
	},
	"shophouse_c": {
		# Doua roluri pe aceeasi casa, de cand fatada e rupta in doua
		# (ACCENT_SPLIT): CORPUL — parterul si etajele, sloturile 29 si 8 —
		# ia betonul, iar copilul `_Accente`, care tine acoperisul (slot 20)
		# si firmele (slot 30), ramane pe atlas si CONTINUA sa arda.
		#
		"ShophouseC": Palette.TRI_PREFIX + "city_concrete",
		"ShophouseC_Accente": Palette.GLOW_PREFIX + "30|2.0",
	},
	"restaurant_front": {
		"RestaurantFront": Palette.GLOW_PREFIX + "30|2.0",
	},
	"liziba_block": {
		"LizibaBlock": Palette.GLOW_PREFIX + "30|2.0",
	},
	"kuixinglou_pavilion": {
		"Kuixinglou": Palette.GLOW_PREFIX + "30|2.0",
	},
	"tower_silhouette_a": {
		"TowerSilhouetteA": Palette.GLOW_PREFIX + "30|1.2",
	},
	"tower_silhouette_b": {
		"TowerSilhouetteB": Palette.GLOW_PREFIX + "30|1.2",
	},
	"tower_silhouette_c": {
		"TowerSilhouetteC": Palette.GLOW_PREFIX + "30|1.2",
	},
	"neon_sign_a": {
		"NeonSignA": Palette.GLOW_PREFIX + "30|2.0",
	},
	"neon_sign_b": {
		"NeonSignB": Palette.GLOW_PREFIX + "30|2.0",
	},
	"neon_sign_c": {
		"NeonSignC": Palette.GLOW_PREFIX + "30|2.0",
	},
	"neon_sign_d": {
		"NeonSignD": Palette.GLOW_PREFIX + "30|2.0",
	},
	"lamp_lantern_a": {
		"LampLanternA": Palette.GLOW_PREFIX + "30|2.0",
	},
	"lamp_lantern_b": {
		"LampLanternB": Palette.GLOW_PREFIX + "30|2.0",
	},
	"lamp_lantern_c": {
		"LampLanternC": Palette.GLOW_PREFIX + "30|2.0",
	},
	"mini_car_a": {
		"MiniCarA": Palette.GLOW_PREFIX + "30|2.0",
	},
	"mini_car_b": {
		"MiniCarB": Palette.GLOW_PREFIX + "30|2.0",
	},
	"mini_car_c": {
		"MiniCarC": Palette.GLOW_PREFIX + "30|2.0",
	},
	"bus": {
		"Bus": Palette.GLOW_PREFIX + "30|2.0",
	},
	"monorail_train": {
		"MonorailTrain": Palette.GLOW_PREFIX + "30|2.0",
	},
	"hongya_dong": {
		"Hongya": Palette.GLOW_PREFIX + "30|2.0",
	},

	# --- Serengeti: GRANITUL kopje-urilor si al spartturii -------------------
	#
	# Clasa `granite` (palette.gd) refoloseste dala `olkhon_marble` — o faleza
	# naturala de 12,7 m, la scara kopje-ului de 14 m — cu o tenta usor
	# racita. Nu `alpine_granite` (zid de piatra de 2 m: pe stanca naturala a
	# iesit cetate de doua ori, memoria `clase-pe-piese-de-kit`) si nu `rock`
	# (gresie calda de canion, medie (141,97,58), pe cand granitul de aici sta
	# pe MARBLE_GREY/ROCK_LIGHT). Masurat: dala olkhon (178,165,150) e la
	# 3-9% de tinta pe fiecare canal, deci ajunge o tenta sub 1 — fara
	# CLASS_LIFT si fara PNG nou.
	#
	# Proiectia e in spatiul LUMII (world triplanar), ca stratele sa curga
	# continuu din bolovanul de 2 m in kopje-ul de langa el — aceeasi scara
	# pe toate piesele, deliberat: bolovanul mic prinde o fractiune din dala,
	# ceea ce pe o roca ROTUNJITA e corect (e un bulgare din acelasi corp).
	# UV-urile kitului sunt colapsate pe centrele sloturilor (verify_glb),
	# deci pe UV-uri orice textura ar fi citit un texel.
	#
	# kopje_camp si crater_gap au iarba pe platou (slot 13) si sunt RUPTE
	# intai (SPLIT_MODELS/ACCENT_SPLIT): corpul de aici e doar granitul.
	# lion_kopje NU intra: e leul (blana pe 0/27), nu stanca.
	# UN material in plus la garda pentru toata clasa (Track14: 15 -> 16).
	"kopje_camp": {"Kopje_Camp": Palette.TRI_PREFIX + "granite"},
	"kopje_kicker": {"Kopje_Kicker": Palette.TRI_PREFIX + "granite"},
	"kopje_boulder_a": {"Kopje_Boulder_A": Palette.TRI_PREFIX + "granite"},
	"kopje_boulder_b": {"Kopje_Boulder_B": Palette.TRI_PREFIX + "granite"},
	"kopje_boulder_c": {"Kopje_Boulder_C": Palette.TRI_PREFIX + "granite"},
	"crater_gap": {"Crater_Gap": Palette.TRI_PREFIX + "granite"},
	# Orizontul (Lengai, peretele opus) sta la 200-300 m, in ceata: acolo
	# textura nu se mai citeste (mip-ul cel mai mic), dar clasa NU costa
	# nimic in plus (acelasi material) si scoate piesele de pe atlasul plat
	# — siluetele raman in familia de culoare a kopje-urilor din prim-plan.
	"lengai": {"Lengai": Palette.TRI_PREFIX + "granite"},
	"crater_far_wall": {"Crater_Far_Wall": Palette.TRI_PREFIX + "granite"},

	# --- Machu Picchu: ZIDARIA INCASA (Track15) --------------------------
	#
	# Identitatea pistei si singura clasa NOUA a kitului. Rosturile de piatra
	# potrivita se citesc la 3-5 m — adica exact la distanta la care trece
	# masina pe langa ziduri — iar pe atlasul plat un zid incas e o pata
	# maro-gri fara scara. Raspunsul la „ce se vede din masina daca lipseste":
	# dispare chiar diferenta dintre zidul incas si o stanca.
	#
	# COSTA UN SINGUR MATERIAL pentru toate cele sase piese, fiindca
	# `triplanar_class_material` e cache-uit per clasa (palette.gd, dictionarul
	# de materiale pe nume de clasa) — asta e mecanismul, citit in cod.
	#
	# CIFRA INSA NU E INCA MASURATA, si se spune limpede: cat timp niciun POI
	# n-a asezat o piesa, clasa e inregistrata dar nu se aplica nicaieri, deci
	# `probe_decor --track=15` da 17 materiale si CU si FARA ea — identic la
	# cifra. Exact semnalul din docs/bara_vizuala.md ca masori altceva decat
	# crezi. Costul real se citeste la primul POI care planteaza un zid:
	# daca acolo cifra creste cu 1, mecanismul e confirmat; daca creste cu 6,
	# cache-ul nu tine si trebuie reparat inainte de urmatoarele sapte POI-uri.
	# (Prima redactare cita `probe_mp_class_cost.gd` ca dovada. Unealta e
	# MOARTA — in modul --script lipsesc autoload-urile, Track15 nu se incarca,
	# si ambele brate A/B dadeau aceeasi cifra fiindca nu masurau nimic;
	# memoria `sonda-masura-alt-obiect`.)
	#
	# Cheia e STEM DE FISIER, nu nume de nod, si asta nu e pedanterie:
	# `House_Ruin`/`Basin` sunt nume generice, iar o mapare globala pe nume
	# ar fi lovit alte kituri (memoria nume-noduri-nu-sunt-unice). Din acelasi
	# motiv NU exista un MACHUPICCHU_CLASSES in track_decor.gd.
	"inca_wall_a": {"Inca_Wall_A": Palette.TRI_PREFIX + "inca_stone"},
	"inca_wall_b": {"Inca_Wall_B": Palette.TRI_PREFIX + "inca_stone"},
	# `_c` (capatul de zid, 2 m) lipsea din lista, si nu dintr-o decizie: nu are
	# nicio nota de respingere, spre deosebire de `inca_house_b`/`fountain_basin`
	# de mai jos. Cat timp era folosit rar nu se vedea; POI G il pune de 47 de
	# ori pe serpentine si captura (G_r5_f076.png) arata de ce conteaza — panouri
	# PALIDE intre piesele tan, fiindca ramaneau pe atlas in loc sa ia dala de
	# granit. Un zid din doua materiale nu citeste ca un zid (memoria
	# scatter-nu-primeste-clasele-temei: hardcodarile ocolesc mapari corecte).
	"inca_wall_c": {"Inca_Wall_C": Palette.TRI_PREFIX + "inca_stone"},
	"inca_stair_a": {"Inca_Stair_A": Palette.TRI_PREFIX + "inca_stone"},
	"inca_stair_b": {"Inca_Stair_B": Palette.TRI_PREFIX + "inca_stone"},
	# Cele PATRU piese sacre + cele doua porti. Toate au sloturile 3 / 4 / 29,
	# care sunt TOATE piatra (ROCK_LIGHT / ROCK_DARK / MARBLE_GREY), deci clasa
	# poate cadea pe nodul intreg fara ACCENT_SPLIT — masurat in
	# machu_picchu_masuratori.md §2, care le numeste explicit la "piesele care
	# NU cer ACCENT_SPLIT". Exceptia e sun_temple, care are si 12 (iarba de
	# coronament): ala se rupe, ca zidurile.
	# (three_windows / sun_temple / intihuatana / trail_marker sunt mai jos, la
	# blocul piese-erou adaugat de POI A, cu masuratoarea de nuanta/saturatie
	# care le-a justificat. Aici ar fi fost chei DUBLATE — GDScript pastreaza
	# tacut ultima valoare, deci dublura n-ar fi crapat, doar ar fi mintit.)
	# Portile: piesele prin care CONDUCI, deci cele mai privite bucati de
	# piatra din tur. `main_gate` e gatuirea de la POI H (7,39 m gol masurat),
	# `inti_punku` e Poarta Soarelui de la POI C (13,98 m).
	"main_gate": {"Main_Gate": Palette.TRI_PREFIX + "inca_stone"},
	"inti_punku": {"Inti_Punku": Palette.TRI_PREFIX + "inca_stone"},
	# MASA DE PIATRA a cornisei (POI H). `huayna_picchu` a fost exportat ca
	# silueta de ORIZONT si e pictat ca atare: slot 29 (#B8B4AC, gri pal) pe
	# flancuri si sloturi de nisip (2 #915D27, 3 #C18446) pe restul, adica un
	# varf palid cu tenta calda, bun la 250 m dincolo de ceata. Pus la 8 m de
	# sosea ca PERETE al cornisei, grupul ala de culori citeste alb-portocaliu,
	# nu granit - masurat pe captura `H_r10_f0940.png`, unde flancul iese cea
	# mai deschisa suprafata din cadru (memoria `suprafata-palida-e-lumina`:
	# o suprafata palida inmultita cu soarele temei devine lumina, nu piatra).
	#
	# Clasa `inca_stone` (alpine_granite.png) e EXACT ce trebuie si nu costa
	# nimic: e deja clasa intregii zidarii a pistei, inclusiv a portii prin care
	# treci, deci peretele si poarta taiata in el ies din aceeasi piatra - si e
	# granit natural stratificat, nu asize de zid, deci nu face muntele sa para
	# caramida (memoria `conul-e-casa-nu-stanca`). ZERO materiale noi: clasa e
	# deja numarata in cele 19 ale pistei.
	#
	# Nu se rupe in accente: piesa n-are iarba pe coronament ca zidurile, iar
	# sloturile ei verzi (12, 21) sunt petice de vegetatie pe flanc, pe care
	# oricum le acopera vegetatia asezata de mana deasupra.
	"huayna_picchu": {"Huayna_Picchu": Palette.TRI_PREFIX + "inca_stone"},
	# Cornisa podului: piesa peste care sare LiftBridgeHazard, deci cea mai
	# privita bucata de piatra din cursa. Nu se rupe (iarba e 2.5%).
	"inca_bridge_ledge": {
		"Inca_Bridge_Ledge": Palette.TRI_PREFIX + "inca_stone",
	},
	# Casele: DOAR peretele de piatra ia clasa. Acoperisul de paie
	# (`House_Thatch`, 63-66% DRY_VEGETATION) ramane pe atlas — paiele nu sunt
	# zidarie, iar dala de granit pe ele ar fi facut acoperisul de piatra.
	# Nodurile paznicului au SUFIX _001, si maparea potriveste pe PREFIX, deci
	# "House_Stone" prinde si "House_Stone_001" — verificat pe fisier.
	"inca_house_a": {"House_Stone": Palette.TRI_PREFIX + "inca_stone"},
	"guardhouse": {"House_Stone": Palette.TRI_PREFIX + "inca_stone"},
	# inca_house_b (ruina) si fountain_basin NU intra: vezi nota de respingere
	# de sub CLASS_TEXTURES["inca_stone"] din palette.gd.
	#
	# PIESELE-EROU DE PIATRA (adaugate la POI A, pe masuratoare de captura).
	# `machu_picchu_masuratori.md` §2 le trecuse deja pe lista celor care
	# "NU cer ACCENT_SPLIT" fiindca "toate sunt piatra" — adica erau gandite
	# sa primeasca clasa pe TOT nodul — dar cheia nu fusese scrisa. Pana la
	# masuratoarea de mai jos asta nu se vedea: pe .glb brut nu se vede, se
	# vede abia dupa remap, in cadru, langa zidurile clasate
	# (memoria `monocromia-se-masoara-dupa-remap`).
	#
	# Masurat pe A_r3_sun_temple.png si A_r4_f000.png, media pe suprafata
	# luminata, in acelasi cadru cu zidaria clasata de langa ele:
	#
	#   inca_wall_* (cu `inca_stone`)  H 39-44 deg   S 0.45-0.50
	#   three_windows                  H 43 deg      S **0.22**
	#   sun_temple                     H **81** deg  S **0.06**
	#   intihuatana                    H **77** deg  S **0.05**
	#
	# Adica nuanta nimereste doar la `three_windows`, iar SATURATIA e de
	# doua-zece ori mai mica peste tot: in cadru, templul si piatra-ceas
	# citesc ca beton cenusiu-verzui langa un zid de granit cald, la 2 m
	# distanta, desi brief-ul spune ca sunt acelasi granit. Asta e ce facea
	# hero-assets-urile sa dispara in campul de ziduri al Pietei Sacre.
	#
	# Toate trei sunt mono-familie (3+4+29 / 3+29, toate sloturi de piatra),
	# deci clasa merge pe nodul intreg fara ACCENT_SPLIT — exact cum a
	# argumentat inventarul. `trail_marker` (3+29) intra din acelasi motiv.
	"three_windows": {"Three_Windows": Palette.TRI_PREFIX + "inca_stone"},
	"sun_temple": {"Sun_Temple": Palette.TRI_PREFIX + "inca_stone"},
	"intihuatana": {"Intihuatana": Palette.TRI_PREFIX + "inca_stone"},
	"trail_marker": {"Trail_Marker": Palette.TRI_PREFIX + "inca_stone"},

	# --- Serengeti: LUTUL termitierelor ---------------------------------
	#
	# Clasa `termite_clay` (palette.gd) refoloseste dala `rock` (aceeasi gresie
	# calda de canion pe care sta si granitul kopje-urilor, dar tentata altfel)
	# — masurat, e cea mai apropiata de familia caramizie a sloturilor 23/27
	# pe care sta piesa in atlas (77-78% + 22-23%, ambele caramizii). `wood`,
	# `plaster`, `concrete`, `stone_wall` au fost masurate si respinse: toate
	# cer o corectie de tenta mult mai mare pe verde/albastru ca sa ajunga
	# rosii, adica ar sterge granulatia sursei.
	#
	# TRIPLANAR, obligatoriu: UV-urile kitului Serengeti sunt colapsate pe
	# centrele sloturilor (verificat deja pe kopje/crater_gap din blocul de mai
	# sus, acelasi kit), deci pe UV-uri orice textura ar citi un texel.
	# Proiectie in spatiul LUMII: piesele stau pe loc, granulatia curge
	# continuu intre movilele vecine.
	#
	# UN material in plus la garda (Track14: 24 -> 25). Nu se rupe (fara
	# SPLIT_MODELS): fiecare piesa e un singur nod (`Termite_Mound_A/B`), 77-78%
	# deja pe familia de culoare tinta — un accent de 22-23% pe acelasi
	# caramiziu (slot 27) nu justifica o ruptura de nod.
	"termite_mound_a": {
		"Termite_Mound_A": Palette.TRI_PREFIX + "termite_clay",
	},
	"termite_mound_b": {
		"Termite_Mound_B": Palette.TRI_PREFIX + "termite_clay",
	},

	# --- Serengeti: LUTUL colibelor boma (lotul re-exportului, sep 2026) ----
	#
	# Boma a fost RESPINSA in valul 1 (materiale) cu motivul: era UN singur
	# nod de mesh, iar `ACCENT_SPLIT` rupe doar noduri copil deja existente in
	# export — cu 3 instante pe pista, reexportul nu se justifica DOAR pentru
	# clasa. Redeschisa dupa ce dezvoltatorul a vazut de la volan ca boma (POI
	# A, langa start) e mare in prim-plan, cu acoperisurile de paie complet
	# plate. Piesa a fost re-exportata pe doua noduri (tools/blender/
	# build_serengeti_camp.py, build_boma()): `Maasai_Boma` (cele 4 colibe)
	# si `Boma_Camp` (gardul de spini + Maasai-ul cu sulita).
	#
	# NUME ales dupa un bug prins headless: prima incercare a numit al doilea
	# nod `Maasai_Boma_Camp`. Maparea de aici alege pe PREFIX cel mai lung
	# (mai jos, `_apply_model_classes`), si "Maasai_Boma_Camp".begins_with(
	# "Maasai_Boma") e adevarat — gardul si Maasai-ul mosteneau `termite_clay`
	# si acopereau shuka (slot 14, CAR_RED). Instantiere Track14 (cele 3 boma)
	# arata ambele noduri cu albedo (1.0, 0.886, 0.947) — tenta clasei — pe
	# ambele. Exact capcana `House_`/`House_Sand` de mai sus. `Boma_Camp` nu
	# mai e prefixat de `Maasai_Boma`.
	#
	# Doar colibele intra aici. Masurat pe .glb (raportul complet, tools/
	# probe_slots.gd): slotul 2 (SAND_SHADOW/MUD, lutul cilindrului) e 4,4%
	# din piesa INTREAGA dinainte de ruptura — acum e o parte mult mai mare
	# din nodul `Maasai_Boma` de sine statator (colibele + usa, fara gard).
	#
	# `termite_clay`, nu o clasa noua: masurat raportul RGB al lutului (hex
	# #915D27 = 145,93,39) fata de dala `rock.png` (medie 140.7,97.3,58.2) —
	# raport (1.03, 0.96, 0.67), ecart doar 0.36 intre canale. E cea mai
	# apropiata potrivire dintre toate clasele existente (wood 0.62, plaster
	# 0.65, stone_wall 0.66, concrete 0.59, pine_needles 0.83, macchia 1.14 —
	# toate masurate cu Pillow direct pe PNG-urile din assets/textures/classes/).
	# E si aceeasi familie de MATERIAL, nu doar de culoare: lutul batut al unei
	# colibe maasai e aceeasi argila de savana ca lutul unei termitiere.
	# Refoloseste materialul deja cache-uit de termite_mound_a/b de mai sus —
	# ZERO materiale in plus la garda (Track14 ramane la 27; cache pe clasa,
	# vezi Palette._tri_mats).
	#
	# Usa (slot 4, ROCK_DARK, 4,6%) NU intra: e un accent mic si intunecat,
	# pe care clasa `termite_clay` — ridicata si tentata spre cald — l-ar fi
	# spalat. Fara SPLIT_MODELS/ACCENT_SPLIT pentru nodul asta: masurat, 4,6%
	# pe un singur slot mic nu justifica inca o ruptura (acelasi prag ca la
	# termite_mound, unde accentul de 22-23% pe UN slot n-a cerut ruptura).
	#
	# Acoperisul de paie (slot 13, DRY_VEGETATION/THATCH, 5,1%) RAMANE pe
	# atlas: masurat, ratia THATCH (hex #AF9F4E = 175,159,78) fata de ORICE
	# clasa din repo are ecart peste 0.49 (cel mai bun candidat, concrete,
	# tot gresit ca familie de material — beton turnat pe acoperis de paie).
	# Zero pipeline de textura noua in lotul asta (ca la baobab mai sus):
	# ramane pictat, refuz motivat, nu omisiune.
	"maasai_boma": {
		"Maasai_Boma": Palette.TRI_PREFIX + "termite_clay",
	},

	# --- Serengeti: SCOARTA copacilor, clasa `bark` -------------------------
	#
	# Dala `bark` exista deja (Okinawa/Stromboli, sursa palm_tree_bark, scanare
	# de 1,3 m de trunchi de PALMIER — inele fine de cicatrici de frunza,
	# CLASS_TRIPLANAR_SCALE 0.77 = o repetitie la 1,3 m REALA). Intra doar
	# piesele al caror trunchi e la scara ei; masurat pe .glb, sectiune la
	# baza (y<2 m, tools/_tmp_probe_trunk_widths.gd):
	#   acacia_umbrella_a/b/c   0.56-0.68 m  (0.4-0.5x sursa)
	#   dead_tree               0.55 m       (0.4x sursa)
	#   fig_tree                2.22 m       (1.7x sursa — contraforti grosi,
	#                                         inca in aceeasi ordine de marime)
	#   baobab                  6.44 m       (4.95x sursa — vezi RESPINGERE mai jos)
	#
	# CINE NU intra, desi are trunchi:
	#   baobab — RESPINS. 6,44 m fata de sursa de 1,3 m e acelasi tip de
	#     greseala masurata pe `alpine_granite` peste coltii Stancii Samanului
	#     (style_bible §4, memoria `clase-pe-piese-de-kit`): inelele fine de
	#     scoarta de palmier, la orice scara triplanara, tot inele de palmier
	#     raman — un trunchi de 6,4 m nu devine neted marindu-le, doar le
	#     intinde in dungi late si neclare. Reparata corect ar cere o sursa
	#     fotografiata la scara baobabului (scoarta neteda, groasa, gen piele
	#     de elefant — vezi style_bible §4 "fiecare scara isi cere propria
	#     sursa"), care nu exista azi in `assets/textures/classes/src/` si nu
	#     intra in lotul asta (zero pipeline de textura noua aici). In plus,
	#     `build_serengeti_plants.py` numeste explicit baobabul "silueta de
	#     fundal (150+ m), doar profilul conteaza" — la distanta aia orice
	#     detaliu de suprafata se pierde in mipmap oricum (aceeasi masuratoare
	#     ca "banda ingusta" din style_bible §4), deci baobabul ramane pe atlas
	#     fara nicio pierdere vizibila. Framas de verificat CAND apare o sursa
	#     potrivita: o captura de aproape ar confirma ca profilul + culoarea
	#     LARCH_RUST sunt suficiente.
	#   fever_tree — RESPINS in valul 1, REDESCHIS si INVERSAT in valul 2 (vezi
	#     intrarea "fever_tree" mai jos in acest dictionar). Observatia a fost
	#     corecta: trunchiul ei (slot 0, SAND_LIGHT) NU e un maro oarecare —
	#     `build_serengeti_plants.py` il numeste explicit BARK_YELLOW si spune
	#     direct "scoarta galben-verde... trunchiul palid e ce o deosebeste de
	#     la volan" — e identitatea speciei (de-aia se numeste "fever tree",
	#     Vachellia xanthophloea). Dala `bark` e gradata spre ancora
	#     WOOD_WEATHERED (maro), fara tenta proprie: pusa direct, l-ar fi
	#     vopsit maro peste galbenul care e chiar motivul pentru care specia
	#     exista in kit.
	#     CONCLUZIA gresita a fost "deci ramane pe atlas": exact mecanica
	#     volcanic_rock/tuff_cream/termite_clay (aceeasi dala, CLASS_LIFT +
	#     CLASS_TINT calculate) rezolva problema — clasa noua `bark_fever`
	#     ATERIZEAZA pe SAND_LIGHT in loc de WOOD_WEATHERED, deci semnul
	#     speciei se pastreaza SI trunchiul capata granulatie de scoarta.
	#     Ramane un avertisment real (inele de palmier pe un trunchi de
	#     acacie), notat la noua intrare, nu o respingere totala.
	#
	# Zero PNG nou, zero clasa noua: `bark` refoloseste exact dala si scara de
	# pe Okinawa/Stromboli. Corpurile de mai jos sunt deja RUPTE (SPLIT_MODELS/
	# ACCENT_SPLIT), deci aici se ating doar trunchiurile (Acacia_Umbrella_*,
	# Fig_Tree) sau tot nodul, cand piesa e monocroma (Dead_Tree).
	# Fig_Tree: vezi SPLIT_MODELS pentru limitarea la grupurile Serengeti —
	# fisierul "fig_tree.glb" exista si pe Stromboli (alt corp, alta mapare,
	# STROMBOLI_CLASSES in track_decor.gd), deci maparea GLOBALA de aici s-ar
	# fi aplicat si acolo daca `_apply_model_classes` n-ar filtra pe stem +
	# ruptura anterioara — verificat ca cele doua sisteme nu se ating (nodurile
	# Stromboli sunt Fig_Trunk/Fig_Canopy, generate de track_decor.gd inainte
	# sa intre in .tscn, nu Fig_Tree).
	# Dead_Tree: 100% pe slotul 28 (LOG_DARK) — monocrom, masurat, nimic de
	# rupt. Copacul uscat de pe malul raului (POI C) primeste scoarta pe tot
	# corpul, ca la baobab/dead_tree pe Okinawa unde piesele monocrome iau
	# clasa direct.
	"dead_tree": {"Dead_Tree": Palette.TRI_PREFIX + "bark"},

	# --- Serengeti: copacii, CORP + ACCENT in aceeasi intrare ---------------
	#
	# Contopite la integrare din doua loturi paralele care au atins aceleasi
	# modele cu intentii complementare: trunchiul (corp) ia `bark`, coroana
	# (`_Accente`, prin ACCENT_HOLDS_CLASS) ia `acacia_canopy`. Niciuna nu e o
	# suprascriere a celeilalte — `_apply_model_classes` potriveste pe NUME DE
	# NOD, iar ruptura a produs doua noduri distincte per copac.
	#
	# fever_tree si euphorbia au DOAR accentul: trunchiul galben-verzui al
	# acaciei-febra e chiar semnul speciei (respins deliberat de lotul
	# scoartei), iar baza carnoasa a euforbiei e 5.9% din piesa.
	# --- Serengeti: COROANA savanei (lotul FRUNZISULUI) ----------------------
	#
	# Masurat cu tools/probe_slots.gd: toata coroana zonei POI D (206 smochini,
	# 67 acacii-febra, ~150 acacii-umbrela, 19 euforbii) sta pe aceeasi pereche
	# de sloturi de atlas — 12 CACTUS_GREEN si 21 TROPICAL_GREEN — deci toata
	# adancimea padurii de ceata citea UN SINGUR SMARALD plat. Clasa noua
	# `acacia_canopy` (Palette.gd, sursa tools/paint_acacia_canopy.py) da
	# variatie de valoare in interiorul coroanei, fara sa schimbe nuanta.
	#
	# ACCENT_HOLDS_CLASS: cheia e nodul `_Accente`, nu corpul — ruptura
	# (SPLIT_MODELS/ACCENT_SPLIT) a mutat coroana acolo si a lasat trunchiul pe
	# atlas, ca sa nu se stearga clasa `bark` a trunchiului (alt agent, alt
	# lot). TRIPLANAR in spatiul LUMII: copacii nu se misca, iar intr-o padure
	# deasa (POI D) benzile de valoare curg continuu dintr-o coroana in vecina
	# ei, exact ca la `pine_needles` pe un rand de brazi.
	#
	# Acaciile-umbrela intra si in `SLOT_REMAP_BY_MODEL` (13,21 -> 12): dupa
	# remapare coroana lor e deja UN slot inainte sa ajunga aici, deci clasa
	# doar adauga textura peste o culoare deja unificata.
	"acacia_umbrella_a": {
		"Acacia_Umbrella_A": Palette.TRI_PREFIX + "bark",
		"Acacia_Umbrella_A_Accente": Palette.TRI_PREFIX + "acacia_canopy",
	},
	"acacia_umbrella_b": {
		"Acacia_Umbrella_B": Palette.TRI_PREFIX + "bark",
		"Acacia_Umbrella_B_Accente": Palette.TRI_PREFIX + "acacia_canopy",
	},
	"acacia_umbrella_c": {
		"Acacia_Umbrella_C": Palette.TRI_PREFIX + "bark",
		"Acacia_Umbrella_C_Accente": Palette.TRI_PREFIX + "acacia_canopy",
	},
	# fever_tree: CORPUL primeste scoarta acum (valul 2, redeschidere a
	# respingerii de mai sus la "fever_tree — RESPINS"). Clasa noua
	# `bark_fever` (Palette.gd) rezolva exact obiectia veche: e ACEEASI dala
	# `bark` (zero PNG nou), dar cu CLASS_LIFT+CLASS_TINT calculate sa
	# aterizeze pe SAND_LIGHT (232,192,116) — galbenul scoartei — nu pe
	# WOOD_WEATHERED. Semnul speciei (trunchi palid) se pastreaza, doar ca
	# acum are granulatie de scoarta in loc de o dala plata. Scara triplanara
	# ramane 0.77, verificata pe piesa (vezi nota din CLASS_TRIPLANAR_SCALE):
	# trunchiul are 0.648 m diametru la baza, chiar in intervalul acaciilor-
	# umbrela (0.57-0.69 m) care deja folosesc aceeasi scara fara plangeri.
	#
	# Obiectia despre INELELE de palmier ramane valabila ca AVERTISMENT, nu ca
	# motiv de respingere totala: la 148 de instante si scara comparabila cu
	# acaciile-umbrela (unde acelasi bark citeste bine), riscul e mult mai mic
	# decat pe baobab (6,44 m, RESPINS mai sus). Verificare vizuala ramasa
	# NEFACUTA (necesita captura, vezi raportul lotului) — daca inelele de
	# palmier se citesc totusi ciudat pe o acacie, following-up e o sursa noua
	# de bark, nu o alta clasa.
	"fever_tree": {
		"Fever_Tree": Palette.TRI_PREFIX + "bark_fever",
		"Fever_Tree_Accente": Palette.TRI_PREFIX + "acacia_canopy",
	},
	# fig_tree: ACCENT_SPLIT pastreaza si fructele (slot 22) pe CORP, langa
	# trunchi — vezi nota de acolo. Accentul ramane doar cu verdele (12/21),
	# deci clasa nu atinge fructele.
	"fig_tree": {
		"Fig_Tree": Palette.TRI_PREFIX + "bark",
		"Fig_Tree_Accente": Palette.TRI_PREFIX + "acacia_canopy",
	},
	"euphorbia": {
		"Euphorbia_Accente": Palette.TRI_PREFIX + "acacia_canopy",
	},

	# --- Serengeti: PIELEA elefantului -------------------------------------
	#
	# Vezi ACCENT_SPLIT["Elephant_Mesh"] pentru ruptura si nota lunga din
	# palette.gd (CLASS_TEXTURES/CLASS_TINT) pentru masuratorile care au ales
	# dala `concrete` si tenta. Aici doar cablarea: accentul (corpul, capul,
	# picioarele — 91.5% din arie) ia clasa, corpul original ramane cu
	# fildesii (FOAM_WHITE) pe atlas.
	#
	# UN material in plus la garda (Track14: 27 -> 28).
	#
	# RESPINSE, masurat, nu presupus (acelasi kit, sloturi verificate cu
	# tools/_tmp_probe_hippo_croc.gd, script temporar, sters):
	#   hippo_back — e cel mai monocrom animal din kit (100% pe slotul 4,
	#     ROCK_DARK), si tinta lui ar fi fost o tenta separata (concrete ->
	#     ROCK_DARK, (0.61, 0.41, 0.21), fara CLASS_LIFT) — merita pe cifre.
	#     NU intra fiindca lotul asta are voie sa adauge cel mult UN material
	#     (instructiunea lotului), iar elefantul e piesa ceruta explicit.
	#     O tenta separata pentru hippo ar fi un al DOILEA material (acelasi
	#     PNG, alta intrare in cache-ul `_tri_mats`, cheie pe clasa) — ramane
	#     pentru un lot viitor daca bugetul permite.
	#   crocodile — pe TREI sloturi in DOUA familii de nuanta incompatibile:
	#     12 CACTUS_GREEN (52.8%, verde ~H88) si 2 SAND_SHADOW + 4 ROCK_DARK
	#     (47.2%, maro ~H29-31) — 59 de grade distanta pe cerc, o singura
	#     tenta multiplicativa nu poate impinge un gri neutru spre AMBELE
	#     fara sa greseasca una din ele. Ar cere fie doua clase, fie o ruptura
	#     de accent — peste bugetul de 1 material, si crocodilul e oricum
	#     placi/solzi, alt limbaj de suprafata decat pielea incretita.
	#
	# NEACOPERITI, deliberat: `G_Elefant1`/`G_Elefant2` din grupul "Hazarduri"
	# (Track14.tscn) sunt elefanti MOBILI puse prin HazardMarker (motion=1,
	# sweep_speed, face_travel) — alt cod (track.gd/hazard_marker.gd,
	# `Palette.apply_triplanar_class`), care pune `material_override` pe TOT
	# subarborele, fara mecanica de accent-split. Aplicat acolo prin
	# `tri_class`, ar sterge fildesii (fara ACCENT_SPLIT in codul ala) SI ar
	# "inota" pe pielea care se MISCA (proiectie de lume pe un corp translat —
	# acelasi defect documentat la CLASS_TRIPLANAR_SCALE["snow"], unde
	# bolovanul rulant cere `apply_object_triplanar_class`). Brief-ul lotului
	# oricum numara doar cele 9 instante DecorManual (6 ZoneE + 3 ZoneG);
	# elefantii-hazard raman pe atlas pana cand cineva scrie varianta
	# obiect-spatiu + accent pentru `hazard_marker.gd`.
	"elephant": {
		"Elephant_Mesh_Accente": Palette.TRI_PREFIX + "elephant_hide",
	},

	# --- Fiordland: GNEISUL UD (Track16) ----------------------------------
	#
	# Clasa noua a pistei (brief §4/§5.6): dungile de scurgere verticale pe
	# peretii de gneis se citesc exact la distanta la care trece masina pe
	# langa ei (3-5 m). Pe atlasul plat peretele Stirling e o pata gri fara
	# scara — WaterfallHazard face apa, dar STANCA din spatele ei ramane
	# decor pur, si aici e singurul loc unde primeste material.
	#
	# COSTA UN SINGUR MATERIAL pentru toate nodurile de mai jos (cache pe
	# clasa, ca la inca_stone).
	#
	# Aplicata DOAR pe nodurile cu mus/vegetatie sub pragul la care o
	# ruptura ar merita un nod in plus (memoria clase-pe-piese-de-kit,
	# tiparul inca_bridge_ledge la 2.5%):
	#   stirling_ledge.Wall     4.8% TROPICAL_GREEN (musch pe coronament) — sub prag, ramane intreg pe wet_gneiss
	#   torrent_chute.Rock     11.7% TROPICAL_GREEN — idem, sub pragul de ~20% de la Machu Picchu
	# NU se aplica pe stirling_ledge.Overhang (27.0% TROPICAL_GREEN — peste
	# pragul de 22.8% al inca_house_b, unde intervalele de y se suprapun cu
	# stanca si o ruptura ar taia gresit) si NU pe .Shelf (20.0%, prag uscat
	# ingust, judecat de-a lungul lui, nu de sus — ramane pe atlas).
	# NU se aplica pe fiordland_horizon (FarWall_*/SnowRidge_*): acolo
	# TROPICAL_GREEN/LOG_DARK/MARBLE_GREY/FOAM_WHITE sunt BENZI DE ALTITUDINE
	# pictate intentionat (paduri/gheata/zapada pe treimi de inaltime, vezi
	# fiordland_masuratori.md) — o clasa triplanara ar sterge exact
	# stratificarea pe care tema o cere explicit (`horizon_class: ""`).
	"stirling_ledge": {
		"Wall": Palette.TRI_PREFIX + "wet_gneiss",
	},
	"torrent_chute": {
		"Rock": Palette.TRI_PREFIX + "wet_gneiss",
	},

	# --- Fiordland: PADUREA DE FAGI (Track16, lotul A) ----------------------
	#
	# Brief §4/§5.1: "verde-negru de muschi si fag, cel mai inchis verde din
	# joc" — trunchiuri negre subtiri, coronament marunt. `cloud_forest` (numit
	# in brief ca "reuse daca tine") NU EXISTA in cod (verificat cu grep pe
	# palette.gd) — clasele de mai jos sunt noi, dar refolosesc dale deja in
	# VRAM (`bark`, `acacia_canopy`), ca `bark_fever`/`termite_clay`.
	#
	# DOUA materiale noi (buget lot: +2, exact la limita).
	#
	# beech_a/b/c: kitul exporta DEJA Trunk/Crown ca noduri SEPARATE (nu
	# necesita SPLIT_MODELS/ACCENT_SPLIT, spre deosebire de Rata mai jos).
	# Masurat (probe_slots.gd): Trunk/Trunk_001/Trunk_002 100% slot 28
	# (LOG_DARK) — deja monocrom SI deja pe culoarea tinta, trunchiul primeste
	# doar granulatie de scoarta (`bark_beech`, tenta calculata in palette.gd).
	# Crown/Crown_001/Crown_002: 56% slot 21 (TROPICAL_GREEN) + 44% slot 28
	# (LOG_DARK), PE ACELASI interval de inaltime (nu se separa pe verticala
	# ca la Serengeti) — o clasa pe tot nodul ia ambele sloturi deodata, deci
	# `beech_canopy` e tentata pe media ponderata a lor (palette.gd), nu pe un
	# singur slot ales cu ochiul.
	"beech_a": {
		"Trunk": Palette.TRI_PREFIX + "bark_beech",
		"Crown": Palette.TRI_PREFIX + "beech_canopy",
	},
	"beech_b": {
		"Trunk_001": Palette.TRI_PREFIX + "bark_beech",
		"Crown_001": Palette.TRI_PREFIX + "beech_canopy",
	},
	"beech_c": {
		"Trunk_002": Palette.TRI_PREFIX + "bark_beech",
		"Crown_002": Palette.TRI_PREFIX + "beech_canopy",
	},
	# beech_dead: UN SINGUR nod (`Beech_Dead`, nu Trunk+Crown) — 94.4% slot 28
	# (LOG_DARK, acelasi trunchi negru) + 5.6% slot 12 (CACTUS_GREEN, licheni/
	# ramurele razlete, y 0.00..4.21, acelasi interval ca restul corpului — nu
	# se separa). Sub pragul de ruptura (2.5%, memoria clase-pe-piese-de-kit)
	# ar fi fost ignorat, dar 5.6% e putin peste — totusi, o ruptura pentru o
	# creanga uscata fara frunze n-are sens vizual (nu exista "coroana" de
	# separat pe un copac mort), asa ca merge direct pe tot nodul, ca
	# `dead_tree` pe Serengeti (baobab/dead_tree, aceeasi mecanica).
	"beech_dead": {
		"Beech_Dead": Palette.TRI_PREFIX + "bark_beech",
	},
	# rata_tree: vezi SPLIT_MODELS["rata_tree"] si ACCENT_SPLIT["Rata"] —
	# corpul pastreaza florile (KERB_RED, slot 7), tufa de frunzis (21+28)
	# pleaca in `Rata_Accente` si ia `beech_canopy`. Tinta ponderata a Ratei
	# (renormalizat pe 21/28: 54.0%/46.0%) cade la (68.1, 90.3, 49.9) — sub 2
	# unitati pe canal fata de tinta fagului (67.8, 91.8, 50.4), aceeasi
	# familie, deci ACEEASI clasa (nu un al treilea material).
	"rata_tree": {
		"Rata_Accente": Palette.TRI_PREFIX + "beech_canopy",
	},
	# --- Fiordland: LEMNUL UD (Track16, lotul C) ---------------------------
	#
	# Brief §4: "podetul, balustradele, pontonul — WOOD_WEATHERED 9, ud = mai
	# inchis". Clasa `wood` exista deja in palette.gd (CLASS_TEXTURES,
	# CLASS_TRIPLANAR_SCALE) din pipeline-ul general, dar pana acum n-avea
	# NICIUN consumator — infrastructura pregatita, niciodata cablata. Tenta
	# noua (CLASS_TINT["wood"]) duce dala la 65% din valoarea slotului
	# WOOD_WEATHERED uscat, vezi nota din palette.gd.
	#
	# UN SINGUR material la garda pentru tot lotul (clasa e cache-uita, ca la
	# wet_gneiss/inca_stone) — se aplica AICI doar pe `driftwood` (monocrom
	# 100% slot 9, masurat cu o sonda pe .glb, tools temporare sterse) si pe
	# tabliera generata din cod a podetului Chasm (`WoodDeckStrip.material_class`
	# in track.gd/Track16.tscn, acelasi tipar ca `CliffFace.material_class`).
	#
	# CINE NU intra, masurat, nu presupus (probe_lot_c_slots, script temporar):
	#   wharf              21 TROPICAL_GREEN 57.2% + 29 MARBLE_GREY 41.8% +
	#                      20 VOLCANIC_BLACK 0.9% — deloc lemn. Contractul
	#                      kitului ("Blocuri MARBLE_GREY, babale VOLCANIC_BLACK")
	#                      si SLOT_REMAP_BY_MODEL["wharf"] (mai sus in fisier)
	#                      confirma: e piatra de chei, nu lemn — cheiul din
	#                      brief §2 randul A e stanca, nu un ponton de lemn.
	#   chasm_bridge_rail  100% slot 9, DAR balustrada (Rail_L/Rail_R) are
	#                      grosime masurata 0.56 m (extenta X pe mesh) — sub
	#                      pragul „piese INGUSTE raman pe atlas" (memoria
	#                      clase-pe-piese-de-kit #3): la 3-5 m distanta de
	#                      camera, o bara de 56 cm primeste prea putini texeli
	#                      pentru ca fibra sa se vada, mipmap-ul o aplatizeaza.
	#   stump              88.7% slot 28 LOG_DARK + 11.3% slot 12 CACTUS_GREEN
	#                      (capac de muschi) — NU e pe WOOD_WEATHERED. LOG_DARK
	#                      e alta familie de material in paleta (barne de casa
	#                      siberiana aproape negre, deja folosit pentru
	#                      trunchiuri moarte pe alte piste), nu „lemn ud de
	#                      chei/podet" — brief-ul §4 nici nu-l numeste explicit.
	#                      O clasa `wood` (tenta bruna cald) pe un slot gandit
	#                      negru-carbune ar fi contrazis rolul lui in restul
	#                      paletei.
	#   heli_pad           76.2% slot 8 CONCRETE + 23.8% slot 22 FOAM_WHITE
	#                      (marcaje) — beton, nu lemn (brief-ul insusi il
	#                      marcheaza „probabil respins").
	#   wooden_pier        REFOLOSIT cu Okinawa (Track08) — masurat pe .glb,
	#                      NU e monocrom: 17 sloturi diferite pe acelasi nod
	#                      (`Pier_Wood`), dominante 0 SAND_LIGHT 49.2% si 31
	#                      FLAMINGO_PINK 38.1%, restul imprastiat pe alte 15.
	#                      O clasa pe tot nodul ar sterge toata pictura asta
	#                      (regula #313) — piesa nu respecta contractul de
	#                      monocromie cerut de o clasa triplanara, indiferent
	#                      de pista pe care sta.
	"driftwood": {
		"Driftwood": Palette.TRI_PREFIX + "wet_wood",
	},
	# Lotul STANCA UDA (bolovani, pietre de parapet, grohotis), val de
	# materiale sep 2026. Masurat cu tools/probe_slots.gd --dir=fiordland/rocks
	# (probele existente pentru chasm_rock/stirling_ledge/torrent_chute de mai
	# sus, verificate din nou aici):
	#
	# `guard_rock` (Rock_002, 287 instante, bolovanul de parapet de langa
	# drum — cel mai apropiat de camera din lot, 1.18x0.70x0.585 m). Sloturi:
	# 74.0% MARBLE_GREY (29, corp, y 0.00-0.46), 26.0% TROPICAL_GREEN (21,
	# capacul de muschi, y 0.44-0.58). PRIMA trecere a refuzat piesa comparand
	# 26.0% cu pragul de ~20% masurat la torrent_chute/Overhang — gresit:
	# pragul acela e un SIMPTOM, nu criteriul. Criteriul real (scris explicit
	# la Overhang mai sus) e SUPRAPUNEREA de y: acolo muschiul e interlacat pe
	# toata fata peretelui ("intervalele de y se suprapun cu stanca"), aici
	# suprapunerea e 0.02 m din 0.585 m (3.4% din inaltime) — un capac curat,
	# nu un amestec. Ruptura (SPLIT_MODELS/ACCENT_SPLIT, mai sus) separa
	# corpul (29, keep_slot in ACCENT_SPLIT["Rock_002"]) de capac (21, pleaca
	# in `_Accente`, ramane pictat — verdele lui e deja corect). Corpul
	# primeste `wet_gneiss` mai jos.
	"guard_rock": {
		"Rock_002": Palette.TRI_PREFIX + "wet_gneiss",
	},

	# REFUZAT: `scree_slab` (Rock_003, 52 instante, toate in ZoneE_Portal —
	# placa de grohotis de langa zona de avalansa). Sloturi: 50.8%
	# SAND_SHADOW (2, #915D27, saturatie 0.731, portocaliu-ruginiu — EXACT
	# tonul semnalat de memoria `rock-dark-nu-pe-bazalt`) si 49.2% MARBLE_GREY
	# (29, #B8B4AC, saturatie 0.065, gri neutru). Ecart de saturatie intre cele
	# doua sloturi: 0.666 — peste pragul de 0.63 la care Serengeti a respins
	# `cave_house_a/b/c` ca "monocrom, deci n-are accent de pierdut" (memoria
	# `monocromia-se-masoara-dupa-remap`). Aici nu e cazul opus (un accent mic
	# de aparat): cele doua sloturi sunt ~50/50 pe ARIE, iar intervalele de y
	# se suprapun aproape complet (2: 0.20-1.20, 29: 0.00-1.20, pe o piesa de
	# doar 1.196 m inaltime) — nu exista o banda curata de tras o ruptura, e
	# variatie de valoare AMESTECATA pe toata placa, nu un capac separabil.
	# O clasa `wet_gneiss` pe tot nodul ar sterge exact variatia asta si ar
	# rade portocaliul in gri uniform (schimbare de nuanta pe jumatate din
	# arie, nu o simpla umbra). Brief-ul §5.1 oricum cere alta clasa pentru
	# grohotis (`gravel_wet`, distincta de `wet_gneiss`), nu reuse — iar o
	# clasa noua ar costa +1 material, peste tinta de buget a lotului (+0).
	# Piesa ramane pe atlas, cu cele doua sloturi ei native.

	# --- Jodhpur (Track17): clasele kitului ----------------------------------
	#
	# Cheie pe FISIER, nu pe nume de nod: `House_Wall/Trim/Glow/Rail` exista
	# si pe `fiordland/buildings/cafe_shed.glb`, `Crown`/`Trunk` pe fagi,
	# `Wall_` e prefixul GLOBAL al varului de Stromboli (`prop_classes()` ->
	# STROMBOLI_CLASSES) si ar fi prins `Wall_Stone`/`Wall_Glow` ai zidului
	# de fort. De aceea fiecare model de mai jos isi numeste TOATE nodurile:
	# ce trebuie sa ramana pe atlas e scris explicit `ATLAS_PREFIX`, ca o
	# mapare globala de prefix sa nu-l poata prinde (memoria
	# `nume-noduri-nu-sunt-unice`). Clasele (palette.gd, masurate cu
	# tools/ProbeJodDale.tscn):
	#   blue_lime_light  #8FB0DC  varul caselor (tenta implicita)
	#   blue_lime_indigo #4F6FB8  aceeasi dala; se alege PE INSTANTA cu
	#                             metadata `indigo` (vezi LIME_INDIGO_META)
	#   red_sandstone    #A5553A  fortul, portile, turnul cu ceas, fatadele
	#   rose_sandstone   #D4957A  fantana in trepte
	#   rhyolite         #9A6A5A  bolovanii si lespedea parcului de desert
	# Balustradele/scarile albe (`House_Rail*`, slot 22) raman pe atlas: asa
	# le-a acceptat kitul (preview-ul tenta doar `House_Wall`). `*_Glow`
	# (golurile de fereastra) sunt pe `shader:jod_window`: albedo-ul atlasului
	# ziua, emisie calda legata de `dusk_lamps` (DuskCycle) spre noapte, cu
	# prag per cladire (assets/shaders/jod_window.gdshader,
	# jodhpur_masuratori.md §9).
	"blue_house_a": {
		"House_Wall": Palette.TRI_PREFIX + "blue_lime_light",
		"House_Rail": Palette.ATLAS_PREFIX, "House_Trim": Palette.ATLAS_PREFIX,
		"House_Glow": Palette.SHADER_PREFIX + "jod_window",
	},
	"blue_house_b": {
		"House_Wall": Palette.TRI_PREFIX + "blue_lime_light",
		"House_Rail": Palette.ATLAS_PREFIX, "House_Trim": Palette.ATLAS_PREFIX,
		"House_Glow": Palette.SHADER_PREFIX + "jod_window",
	},
	"blue_house_c": {
		"House_Wall_001": Palette.TRI_PREFIX + "blue_lime_light",
		"House_Trim_001": Palette.ATLAS_PREFIX, "House_Glow_001": Palette.SHADER_PREFIX + "jod_window",
	},
	"blue_house_d": {
		"House_Wall_002": Palette.TRI_PREFIX + "blue_lime_light",
		"House_Rail_001": Palette.ATLAS_PREFIX, "House_Trim_002": Palette.ATLAS_PREFIX,
		"House_Glow_002": Palette.SHADER_PREFIX + "jod_window",
	},
	"blue_house_e": {
		"House_Wall_003": Palette.TRI_PREFIX + "blue_lime_light",
		"House_Rail_002": Palette.ATLAS_PREFIX, "House_Trim_003": Palette.ATLAS_PREFIX,
		"House_Glow_003": Palette.SHADER_PREFIX + "jod_window",
	},
	# Haveli: decizia dezvoltatorului din 29 sep (inventar, runda 3b) —
	# albastru DESCHIS, nu indigo.
	"haveli_facade": {
		"House_Wall_004": Palette.TRI_PREFIX + "blue_lime_light",
		"House_Trim_004": Palette.ATLAS_PREFIX, "House_Glow_004": Palette.SHADER_PREFIX + "jod_window",
	},
	"ghanta_ghar": {
		"Tower_Stone": Palette.TRI_PREFIX + "red_sandstone",
		"Tower_Glow": Palette.SHADER_PREFIX + "jod_window", "Clock_Glow": Palette.SHADER_PREFIX + "jod_window",
	},
	"market_gate": {
		"Gate_Stone": Palette.TRI_PREFIX + "red_sandstone",
		"Gate_Glow": Palette.SHADER_PREFIX + "jod_window", "Gate_Doors": Palette.ATLAS_PREFIX,
	},
	"fort_gate_jai": {
		"GateJai_Stone": Palette.TRI_PREFIX + "red_sandstone",
		"GateJai_Glow": Palette.SHADER_PREFIX + "jod_window", "GateJai_Doors": Palette.ATLAS_PREFIX,
	},
	"fort_gate_fateh": {
		"GateFateh_Stone": Palette.TRI_PREFIX + "red_sandstone",
		"GateFateh_Glow": Palette.SHADER_PREFIX + "jod_window", "GateFateh_Doors": Palette.ATLAS_PREFIX,
	},
	"fort_gate_loha": {
		"GateLoha_Stone": Palette.TRI_PREFIX + "red_sandstone",
		"GateLoha_Glow": Palette.SHADER_PREFIX + "jod_window", "GateLoha_Doors": Palette.ATLAS_PREFIX,
	},
	"fort_wall_segment": {
		"Wall_Stone": Palette.TRI_PREFIX + "red_sandstone",
		"Wall_Glow": Palette.SHADER_PREFIX + "jod_window",
	},
	"fort_wall_turret": {
		"Turret_Stone": Palette.TRI_PREFIX + "red_sandstone",
		"Turret_Glow": Palette.SHADER_PREFIX + "jod_window",
	},
	# Rupt inainte (SPLIT_MODELS/ACCENT_SPLIT): corpul e doar gresia,
	# gurile de tragere (20) sunt in `Bastion_Stone_Accente`, pe atlas.
	"fort_bastion": {
		"Bastion_Stone": Palette.TRI_PREFIX + "red_sandstone",
	},
	"palace_facade_a": {
		"Palace_Stone": Palette.TRI_PREFIX + "red_sandstone",
		"Palace_Glow": Palette.SHADER_PREFIX + "jod_window",
	},
	"palace_facade_b": {
		"Palace_Stone": Palette.TRI_PREFIX + "red_sandstone",
		"Palace_Glow": Palette.SHADER_PREFIX + "jod_window",
	},
	"stepwell_flight_module": {
		"Well_Stone": Palette.TRI_PREFIX + "rose_sandstone",
	},
	"stepwell_corner": {
		"Well_Stone": Palette.TRI_PREFIX + "rose_sandstone",
	},
	"stepwell_pavilion": {
		"Well_Stone": Palette.TRI_PREFIX + "rose_sandstone",
		"Well_Glow": Palette.SHADER_PREFIX + "jod_window",
	},
	"rhyolite_boulder_a": {
		"Rhyolite_Boulder_A": Palette.TRI_PREFIX + "rhyolite",
	},
	"rhyolite_boulder_b": {
		"Rhyolite_Boulder_B": Palette.TRI_PREFIX + "rhyolite",
	},
	"rhyolite_boulder_c": {
		"Rhyolite_Boulder_C": Palette.TRI_PREFIX + "rhyolite",
	},
	"rock_slab": {
		"Rock_Slab": Palette.TRI_PREFIX + "rhyolite",
	},

	# --- Kyoto (Track18): kitul din assets/models/kyoto/ (integrare int-a) ------
	#
	# Cheie pe STEM de fisier, nu pe nume de nod: `Gate_Wood`, `Wall_Stone`,
	# `Lantern_Stone` sunt nume generice (memoria `nume-noduri-nu-sunt-unice`),
	# iar maparea din `prop_classes()` e globala. Fiecare piesa e sparta la export
	# in noduri cu UN singur material (memoria `clase-pe-piese-de-kit`), iar o
	# clasa se pune DOAR pe nodurile monocrome (masurat pe UV-uri, aria pe slot:
	# Machiya_Wood 100% WOOD, *_Plaster 100% FOAM_WHITE, Maple_Crown 100% un slot).
	# Nodurile MIXTE (Pagoda_Body 30/22/28, Machiya_Trim 9/8, Gate_Wood 30/9/28,
	# Rock_Stone 8/29/6, tigla) raman pe atlas: o clasa le-ar sterge culorile.
	#
	# Lemnul de machiya e singurul lemn de oras care ia `machiya_wood`; trunchiurile
	# (WOOD 9) raman pe atlas, ca sa nu platim un material pentru ele.
	#
	# VALUL DE MATERIALE (oct 2026, docs/track_briefs/kyoto_materiale.md, sonde
	# tools/probe_kyoto_kit_clase.gd + ProbeKyotoClase.tscn): acoperisurile iau
	# `kawara` (dala de tigla tentata pe slotul 20). Pe acoperisuri slotul 28
	# (LOG_DARK, 15% la machiya, ~48% la porti si sala) e COAMA si STREASINA:
	# intervalul lui de y il cuprinde pe al slotului 20 la ambele capete, deci
	# nu se poate rupe ca accent. Clasa il sterge DELIBERAT — un acoperis de
	# kawara e tigla si pe coama; pe captura dunga bruna de coama citea
	# „scandura", nu „tigla". Grinzile 100% LOG_DARK iau `machiya_wood` (+0:
	# tenta lui e exact LOG_DARK), lemnul deschis 100% slot 9 ia `wood`,
	# trunchiurile `bark_kyoto`, cedrii si pinii `cedar_needles`.
	"machiya_a": {"Machiya_Wood": Palette.TRI_PREFIX + "machiya_wood",
		"Machiya_Plaster": Palette.TRI_PREFIX + "village_plaster",
		"Machiya_Roof": Palette.TRI_PREFIX + "kawara"},
	"machiya_b": {"Machiya_Wood": Palette.TRI_PREFIX + "machiya_wood",
		"Machiya_Plaster": Palette.TRI_PREFIX + "village_plaster",
		"Machiya_Roof": Palette.TRI_PREFIX + "kawara"},
	"machiya_c": {"Machiya_Wood": Palette.TRI_PREFIX + "machiya_wood",
		"Machiya_Plaster": Palette.TRI_PREFIX + "village_plaster",
		"Machiya_Roof": Palette.TRI_PREFIX + "kawara"},
	"machiya_d": {"Machiya_Wood": Palette.TRI_PREFIX + "machiya_wood",
		"Machiya_Plaster": Palette.TRI_PREFIX + "village_plaster",
		"Machiya_Roof": Palette.TRI_PREFIX + "kawara"},
	"machiya_e": {"Machiya_Wood": Palette.TRI_PREFIX + "machiya_wood",
		"Machiya_Plaster": Palette.TRI_PREFIX + "village_plaster",
		"Machiya_Roof": Palette.TRI_PREFIX + "kawara"},
	# Varul portilor, salii si zidului de templu (FOAM_WHITE 100% pe nod).
	"niomon_gate": {"Gate_Plaster": Palette.TRI_PREFIX + "village_plaster",
		"Gate_Roof": Palette.TRI_PREFIX + "kawara"},
	"inari_romon": {"Gate_Plaster": Palette.TRI_PREFIX + "village_plaster",
		"Gate_Roof": Palette.TRI_PREFIX + "kawara"},
	"kiyomizu_hondo": {"Hondo_Plaster": Palette.TRI_PREFIX + "village_plaster",
		"Hondo_Roof": Palette.TRI_PREFIX + "kawara"},
	# `Wall_Roof` numit EXPLICIT: fara intrare, prefixul GLOBAL `Wall_` al varului
	# de Stromboli (`prop_classes()` -> STROMBOLI_CLASSES) il prindea, si
	# acoperisul zidului de templu iesea ALB (village_plaster) — masurat cu
	# ProbeKyotoClase inainte de valul de materiale (memoria
	# `nume-noduri-nu-sunt-unice`).
	"temple_wall": {"Wall_Plaster": Palette.TRI_PREFIX + "village_plaster",
		"Wall_Stone": Palette.TRI_PREFIX + "old_stone",
		"Wall_Roof": Palette.TRI_PREFIX + "kawara"},
	# Pagodele: acoperisul (6/28 sau 20/28, acelasi interval de y) ia tigla,
	# ferestrele 100% LOG_DARK lemnul inchis. Corpul (vermilion 30 + var 22 +
	# 28, intercalate pe toata inaltimea) ramane pe atlas. La Yasaka ferestrele
	# sunt 72/28 cu RUST_METAL 10 pe acelasi y: raman pe atlas.
	"koyasu_pagoda": {"Pagoda_Roof": Palette.TRI_PREFIX + "kawara",
		"Pagoda_Windows": Palette.TRI_PREFIX + "machiya_wood"},
	"sanjunoto_pagoda": {"Pagoda_Roof": Palette.TRI_PREFIX + "kawara",
		"Pagoda_Windows": Palette.TRI_PREFIX + "machiya_wood"},
	"yasaka_pagoda": {"Pagoda_Roof": Palette.TRI_PREFIX + "kawara"},
	"tsutenkyo_roof_module": {"Tsu_Roof": Palette.TRI_PREFIX + "kawara",
		"Tsu_Rail": Palette.TRI_PREFIX + "wood"},
	"togetsukyo_module": {"Toget_Rail": Palette.TRI_PREFIX + "wood"},
	"teahouse_front": {"Tea_Wood": Palette.TRI_PREFIX + "wood",
		"Tea_Red": Palette.TRI_PREFIX + "shu_red"},
	# Valul 2: rosul 100% pe nod, fara ruptura.
	"votive_torii_cluster": {"Torii_Wood": Palette.TRI_PREFIX + "shu_vermilion"},
	"iron_truss_bridge": {"Truss_Stone": Palette.TRI_PREFIX + "old_stone",
		"Truss_Iron": Palette.TRI_PREFIX + "shu_red"},
	# Frunzisul de toamna: o coroana = o clasa, trei nuante de artar (siluete
	# diferite in GLB, culori diferite aici). Trunchiurile (100% slot 9) iau
	# scoarta `bark_kyoto`.
	"momiji_a": {"Maple_Crown": Palette.TRI_PREFIX + "maple_crimson",
		"Maple_Trunk": Palette.TRI_PREFIX + "bark_kyoto"},
	"momiji_b": {"Maple_Crown": Palette.TRI_PREFIX + "maple_orange",
		"Maple_Trunk": Palette.TRI_PREFIX + "bark_kyoto"},
	"momiji_c": {"Maple_Crown": Palette.TRI_PREFIX + "maple_rust",
		"Maple_Trunk": Palette.TRI_PREFIX + "bark_kyoto"},
	"ginkgo": {"Ginkgo_Crown": Palette.TRI_PREFIX + "ginkgo_gold",
		"Ginkgo_Trunk": Palette.TRI_PREFIX + "bark_kyoto"},
	"niwaki_pine": {"Pine_Crown": Palette.TRI_PREFIX + "cedar_needles",
		"Pine_Trunk": Palette.TRI_PREFIX + "bark_kyoto"},
	# Cedrul: 97% slot 21 + 3% slot 28 (piciorul trunchiului, sub prag — ca
	# `beech_dead`, 5.6%). Tot nodul ia acele.
	"cedar_dark": {"Cedar_Dark": Palette.TRI_PREFIX + "cedar_needles"},
	# Tufele tunse karikomi: 63% slot 21 + 37% slot 12 pe ACELASI y (umbrirea
	# tufei). `moss` e deja pe pista (+0) si are tenta slotului 21.
	"karikomi_shrub_a": {"Karikomi_A": Palette.TRI_PREFIX + "moss"},
	"karikomi_shrub_b": {"Karikomi_B": Palette.TRI_PREFIX + "moss"},
	"stepping_stones": {"Stepping_Stone": Palette.TRI_PREFIX + "garden_stone"},
	# Frunzele de bambus: lime, pe care atlasul nu-l are (CACTUS_GREEN iese oliv).
	"bamboo_crown": {"Bamboo_Leaves": Palette.TRI_PREFIX + "bamboo_lime"},
	"leaf_pile": {"Leaf_Pile": Palette.TRI_PREFIX + "leaf_litter"},
	# Muschiul: pe nodurile `*_Moss` ale pietrelor, zidului si movilei.
	"moss_mound": {"Moss_Mound": Palette.TRI_PREFIX + "moss",
		"Moss_Stone": Palette.TRI_PREFIX + "garden_stone"},
	# POI F r3 (verdictul coordonatorului: pietrele de mal ieseau albe): piatra
	# bolovanilor de gradina pe `garden_stone`: dala de zid a lui `old_stone`, tenta
	# mai inchisa si calda (Palette.CLASS_TINT), masurata pe captura. Cu
	# `old_stone` pur iesea la fel de deschis ca atlasul (+1 material, nu +0).
	"garden_rock_a": {"Rock_Moss": Palette.TRI_PREFIX + "moss",
		"Rock_Stone": Palette.TRI_PREFIX + "garden_stone"},
	"garden_rock_b": {"RockB_Stone": Palette.TRI_PREFIX + "garden_stone"},
	"garden_rock_c": {"RockC_Moss": Palette.TRI_PREFIX + "moss",
		"RockC_Stone": Palette.TRI_PREFIX + "garden_stone"},
	"cyclopean_wall": {"Cyc_Moss": Palette.TRI_PREFIX + "moss",
		"Cyc_Stone": Palette.TRI_PREFIX + "old_stone"},
	# Piatra arhitecturala (felinare, vulpi, clopotnita, bazin, pavilion, pod):
	# gri neutru pe 29/8/6, deci monocrom ca nuanta. Bolovanii de gradina NU intra
	# (rosturi de zid pe o piatra de rau ar citi gresit).
	"stone_lantern_a": {"Lantern_Stone": Palette.TRI_PREFIX + "old_stone"},
	"stone_lantern_b": {"Lantern_Stone": Palette.TRI_PREFIX + "old_stone"},
	"yukimi_lantern": {"Lantern_Stone": Palette.TRI_PREFIX + "old_stone"},
	"kitsune_statue_a": {"Fox_Stone": Palette.TRI_PREFIX + "old_stone",
		"Fox_Bib": Palette.TRI_PREFIX + "shu_red"},
	"kitsune_statue_b": {"Fox_Stone": Palette.TRI_PREFIX + "old_stone",
		"Fox_Bib": Palette.TRI_PREFIX + "shu_red"},
	"bell_tower": {"Bell_Stone": Palette.TRI_PREFIX + "old_stone",
		"Bell_Roof": Palette.TRI_PREFIX + "kawara",
		"Bell_Beams": Palette.TRI_PREFIX + "machiya_wood",
		"Bell_Wood": Palette.TRI_PREFIX + "wood"},
	"chozuya": {"Choz_Stone": Palette.TRI_PREFIX + "old_stone",
		"Choz_Roof": Palette.TRI_PREFIX + "kawara",
		"Choz_Beams": Palette.TRI_PREFIX + "machiya_wood",
		"Choz_Wood": Palette.TRI_PREFIX + "wood"},
	# Pavilionul de Aur: aurul (16, 100%) ramane pe atlas — foita de aur e o
	# suprafata neteda, culoarea plata ESTE materialul. Lemnul de jos (9/28 pe
	# acelasi y) ramane pe atlas.
	"kinkakuji": {"Kin_Stone": Palette.TRI_PREFIX + "old_stone",
		"Kin_Roof": Palette.TRI_PREFIX + "kawara",
		"Kin_Windows": Palette.TRI_PREFIX + "machiya_wood"},
	# Restul kitului ramane pe atlas (masurat, jodhpur_masuratori.md §1):
	# cenotaful (22/29, marmura), animalele, bazarul, candelele, tuk-tuk-ul,
	# copacii (`Crown`/`Trunk` — niciun prefix global nu-i prinde, verificat
	# cu tools/ProbeJodClase.tscn), orizontul (clasa lui vine din tema).
}

## Clasele pieselor de stanca Monument Valley (vezi `CLASSES_BY_THEME`).
##
## `*_Rock` si `*_Scree` iau AMBELE `mv_sandstone`, si e decizie masurata, nu
## comoditate. Pe atlas, grohotisul (RUST_METAL 10 + LARCH_RUST 27 in coaste
## alternante) iese in captura ca dungi galben-maro, „carton ondulat", la 20 m
## de camera (frac 0.2, Mitten-ul din stanga). Incercat si `red_valley_tuff`
## (maro-inchis, 136/89/65): iese aproape negru pe partea din umbra si costa un
## material in plus pe pista. `mv_sandstone` pe fusta ramane cel mai curat:
## aceeasi nuanta ca peretele, iar etajul de jos se citeste din FORMA (coaste,
## bolovani, AO copt in vertex colors), nu dintr-o a doua culoare. Zero materiale
## noi: clasa e deja pe pista prin falezele trecatorii.
## `*_Cap` (calota) ia `mv_cap` (gri-roz #B9A08C): pe atlas (SAND_LIGHT) iesea galben-oliv la umbra.
## EXCEPTIE: `Mesa_Cap` (peretii culoarului E, `mesa_wall_module`) ia `mv_sandstone`, ca
## peretele. Calota gri-roz pe un zid de 48 de module citea ca placa de marmura pusa
## peste gresie (observatia dezvoltatorului dupa tur); pe monoliti (Mitten, Butte, arc)
## calota palida ramane decizia de culoare de mai sus.
const _MV: String = Palette.TRI_PREFIX + "mv_sandstone"
const _MVC: String = Palette.TRI_PREFIX + "mv_cap"
const MV_ROCK_WEST := {"Mitten_Rock": _MV, "Mitten_Scree": _MV, "Mitten_Cap": _MVC}
const MV_ROCK_EAST := {"EastMitten_Rock": _MV, "EastMitten_Scree": _MV, "EastMitten_Cap": _MVC}
const MV_ROCK_MERRICK := {"Butte_Rock": _MV, "Butte_Scree": _MV, "Butte_Cap": _MVC}
const MV_ROCK_MESA := {"Mesa_Rock": _MV, "Mesa_Scree": _MV, "Mesa_Cap": _MV}
const MV_ROCK_ARCH := {"Arch_Rock": _MV, "Arch_Scree": _MV, "Arch_Cap": _MVC}
const MV_ROCK_BUTTE_A := {"ButteA_Rock": _MV, "ButteA_Scree": _MV, "ButteA_Cap": _MVC}
const MV_ROCK_BUTTE_B := {"ButteB_Rock": _MV, "ButteB_Scree": _MV, "ButteB_Cap": _MVC}
const MV_ROCK_BUTTE_C := {"ButteC_Rock": _MV, "ButteC_Scree": _MV, "ButteC_Cap": _MVC}
const MV_ROCK_FIN := {"Fin_Rock": _MV, "Fin_Scree": _MV}
const MV_ROCK_HOODOO := {"Hoodoo_Rock": _MV, "Hoodoo_Scree": _MV, "Hoodoo_Cap": _MVC}
const MV_ROCK_TALUS := {"Talus_Scree": _MV}

## Clasele kitului Okinawa (Track20), pe FISIER si pe numele intreg al nodului.
##
## De ce tot kitul e aici si nu in `ISLAND_CLASSES` & co: acelea se contopesc in
## `prop_classes()`, global, iar numele de noduri ale kitului (`House_Roof`,
## `House_Plaster`, `Wall_*`, `Cliff_*`, `Palm_Bark`) COINCID cu chei ale altor
## piste (`House_Roof` -> `roof_tiles`, `Wall_` -> `village_plaster`, `Cliff_` ->
## `olkhon_marble`, `Palm_Bark` -> `bark`). Maparea pe TEMA ruleaza DUPA cea
## globala si o suprascrie, deci fiecare nod de mai jos e numit explicit, inclusiv
## cele care trebuie sa ramana pe atlas (`ATLAS_PREFIX`).
##
## Culorile se citesc din clasa, nu din slot (vezi `Palette.CLASS_TINT`):
##   `ok_limestone`  calcarul gri-crem  #CFC6B0 (dala `coral_rock` ridicata)
##   `ok_roof`       olanele            #B8452E (dala `roof_tiles` ridicata)
##   `ok_leaves`     frunzisul          #2E5A2C (atlas tentat, fara textura)
##   `ok_bloom`      bougainvillea      #C2378F (atlas tentat)
##   `ok_lacquer`    lacul porti/palat  #B3261E (atlas tentat; KERB_RED iesea #DE3013)
## Mortarul si aurul raman pe atlas.
const _OK_LIME: String = Palette.TRI_PREFIX + "ok_limestone"
const _OK_ROOF: String = Palette.TRI_PREFIX + "ok_roof"
const _OK_LEAVES: String = Palette.ATINT_PREFIX + "ok_leaves"
const _OK_BLOOM: String = Palette.ATINT_PREFIX + "ok_bloom"
const _OK_LACQUER: String = Palette.ATINT_PREFIX + "ok_lacquer"
# Tencuiala si zidul de corali (decizia coordonatorului dupa POI A r1, 10 oct 2026):
# `plaster` (152,141,126) facea casele de beton bej, iar `coral_rock` are ancora
# VOLCANIC_BLACK (kitul vechi) si scotea zidurile de corali aproape negre. Tencuiala
# ramane pe atlas (FOAM_WHITE / FLAMINGO_PINK, alb si pastel ca in bara), iar
# coralul ia calcarul gri-crem `ok_limestone`. Doua materiale mai putin pe pista.
const _OK_PLASTER: String = Palette.ATLAS_PREFIX
const _OK_CORAL: String = _OK_LIME
const _OK_CONCRETE: String = Palette.TRI_PREFIX + "concrete"
const _OK_HOUSE := {"House_Roof": _OK_ROOF, "House_Plaster": _OK_PLASTER,
	"House_Coral": _OK_CORAL}
const _OK_CONCRETE_HOUSE := {"Concrete_Plaster": _OK_PLASTER,
	"Concrete_Concrete": _OK_CONCRETE}
const _OK_NOTCH := {"Notch_Limestone": _OK_LIME}
const _OK_CLIFF := {"Cliff_Limestone": _OK_LIME,
	"Cliff_Grass": Palette.ATLAS_PREFIX}
const CLASSES_OKINAWA := {
	"ryukyu_gate": {"Gate_Limestone": _OK_LIME, "Gate_Roof": _OK_ROOF,
		"Gate_Lacquer": _OK_LACQUER},
	"ryukyu_palace": {"Palace_Limestone": _OK_LIME, "Palace_Roof": _OK_ROOF,
		"Palace_Lacquer": _OK_LACQUER},
	"gusuku_wall_curve": {"Wall_A_Limestone": _OK_LIME, "Wall_B_Limestone": _OK_LIME},
	"gusuku_wall_straight": {"Wall_Limestone": _OK_LIME},
	"gusuku_arch_gate": {"Arch_Limestone": _OK_LIME},
	"notch_rock_a": _OK_NOTCH, "notch_rock_b": _OK_NOTCH, "notch_rock_c": _OK_NOTCH,
	"heart_rock": {"Heart_Limestone": _OK_LIME},
	"limestone_cliff_module": _OK_CLIFF, "limestone_cliff_module_b": _OK_CLIFF,
	# Turnul ramane pe atlas (FOAM_WHITE): clasa `plaster` (152,141,126) il facea
	# bej pe captura, iar farul e ALB (kit §1.2). Numit explicit fiindca
	# `Lighthouse_White` e cheie globala `plaster` pentru farul vechi.
	"cape_lighthouse": {"Lighthouse_Limestone": _OK_LIME,
		"Lighthouse_Plaster": Palette.ATLAS_PREFIX, "Lighthouse_Roof": _OK_ROOF},
	"ryukyu_house_a": _OK_HOUSE, "ryukyu_house_b": _OK_HOUSE,
	"ryukyu_house_c": _OK_HOUSE,
	"concrete_house_a": _OK_CONCRETE_HOUSE, "concrete_house_b": _OK_CONCRETE_HOUSE,
	"harbour_quay": {"Quay_Concrete": _OK_CONCRETE},
	"bus_stop_shelter": {"Shelter_Roof": _OK_ROOF, "Shelter_Coral": _OK_CORAL},
	# `concrete` (ISLAND_CLASSES) iesea bej-maro pe nisip; calcarul gri-crem e deja pe pista,
	# deci nu aduce material nou. Prefixul `Tetrapod` prinde si _01, _04, _Stack_01.
	"tetrapod": {"Tetrapod": _OK_LIME},
	"coral_stone_wall": {"Coral_Wall_Coral": _OK_CORAL},
	"vending_machine": {"Vending_Plaster": _OK_PLASTER},
	"fukugi_tree_a": {"Fukugi_Leaves": _OK_LEAVES},
	"fukugi_tree_b": {"Fukugi_Leaves": _OK_LEAVES},
	"fukugi_tree_c": {"Fukugi_Leaves": _OK_LEAVES},
	"ryukyu_pine": {"Pine_Leaves": _OK_LEAVES},
	"cycad": {"Cycad_Leaves": _OK_LEAVES},
	# `Palm_Bark` e cheie GLOBALA (`bark`, non-triplanar, deci un singur texel pe
	# UV-urile colapsate): trunchiul palmierului revine explicit pe atlas.
	"fan_palm": {"Palm_Leaves": _OK_LEAVES, "Palm_Bark": Palette.ATLAS_PREFIX},
	"bougainvillea": {"Bougainvillea_Leaves": _OK_LEAVES,
		"Bougainvillea_Bloom": _OK_BLOOM},
}

## Clasele kitului Transfagarasan (Track21), pe FISIER si pe numele intreg al nodului.
##
## Acelasi motiv ca la `CLASSES_OKINAWA`: numele de noduri ale kitului (`House_Roof`,
## `House_Stone`, `House_Plaster`, `Wall_Stone`) coincid cu chei GLOBALE din
## `prop_classes()` (`roof_tiles`, `stone_wall`, `plaster`, `village_plaster`), iar
## maparea pe TEMA ruleaza dupa cea globala si o suprascrie. Deci fiecare nod care
## trebuie sa ramana pe atlas e numit explicit cu `ATLAS_PREFIX`. Nicio alta pista nu
## e atinsa: tema "transfagarasan" exista doar pe Track21.
##
## Culorile (tinta din brief §4) se citesc din clasa, vezi `Palette.CLASS_TINT`:
##   `tf_schist`   sistul        #7E8478  (dala `alpine_granite`)
##   `tf_stone`    zidaria       ~#9B978B (dala `stone_wall`, fara tenta)
##   `tf_jneapan`  jneapanul     #34503A  (dala `pine_needles`)
##   `tf_beech`    coroana fagului #5E8A3A (dala `acacia_canopy`, ridicata)
##   `snow`        zapada        (clasa existenta, netentata)
##   `concrete`    betonul       (clasa existenta, netentata)
##   `plaster`     tencuiala     (ATLAS: clasa iesea bej-maro, vezi `_TF_PLASTER`)
##   `tf_bloom`    bujorul       #B63A7A  (atlas tentat, slotul 31)
## Tabla acoperisurilor NU e clasa: tenta doar INTUNECA, deci ASPHALT_EDGE (#696765) nu
## poate urca spre argintiu. Se rezolva prin remapare de slot (`SLOT_REMAP_BY_THEME`),
## fara material nou: tabla argintie pe MARBLE_GREY, cea ruginie pe LARCH_RUST (mai putin
## saturat decat RUST_METAL). Tabla rosie (`arges_house_b`) ramane pe KERB_RED.
const _TF_SCHIST: String = Palette.TRI_PREFIX + "tf_schist"
const _TF_STONE: String = Palette.TRI_PREFIX + "tf_stone"
# Zapada pe ATLAS (FOAM_WHITE), nu pe clasa `snow`: dala clasei are pistrui granulati
# si in joc peretii de zapada se citeau ca parapet de piatra (criticul orb POI D r1:
# "zidurile albe-gri sunt parapet de piatra, nu zapada"). Pe atlas se vad treptele
# modelate ale zapezii vechi, alb-albastrui in umbra. Si un material mai putin.
const _TF_SNOW: String = Palette.ATLAS_PREFIX
const _TF_CONCRETE: String = Palette.TRI_PREFIX + "concrete"
# Tencuiala: briefului ii cere ALBA (FOAM_WHITE), iar clasa `plaster` (#978D7D) a dat in joc
# (154,121,84), bej-maro, pe cand atlasul da (192,176,149), crem. Ca la Okinawa
# (`_OK_PLASTER`), ramane pe atlas: mai aproape de alb si zero material.
const _TF_PLASTER: String = Palette.ATLAS_PREFIX
const _TF_JNEAPAN: String = Palette.TRI_PREFIX + "tf_jneapan"
const _TF_BEECH: String = Palette.TRI_PREFIX + "tf_beech"
const _TF_BLOOM: String = Palette.ATINT_PREFIX + "tf_bloom"
const _TF_OUTCROP := {"Schist_Schist": _TF_SCHIST}
const _TF_HOUSE := {"House_Stone": _TF_STONE, "House_Plaster": _TF_PLASTER,
	"House_Roof": Palette.ATLAS_PREFIX}
const _TF_WALL := {"Wall_Stone": _TF_STONE}
const _TF_BEECH_TREE := {"Beech_Leaves": _TF_BEECH}
const _TF_JNEAPAN_BUSH := {"Jneapan_Needles": _TF_JNEAPAN}
const CLASSES_TRANSFAGARASAN := {
	"schist_outcrop_a": _TF_OUTCROP, "schist_outcrop_b": _TF_OUTCROP,
	"schist_outcrop_c": _TF_OUTCROP,
	"scree_cone": {"Scree_Schist": _TF_SCHIST},
	"rock_tunnel_portal": {"Rock_Schist": _TF_SCHIST},
	# Caramida (TILE_TERRACOTTA) iesea portocaliu-viu in joc; diorama arata ruina bej-gri.
	# Pe `tf_stone` (deja pe pista): zero material nou.
	"poenari_ruin": {"Poenari_Schist": _TF_SCHIST, "Poenari_Stone": _TF_STONE,
		"Poenari_Brick": _TF_STONE},
	"prometheus_statue": {"Statue_Schist": _TF_SCHIST},
	# Kitul refolosit (kit §1.9): sistul doar pe Track21 (tema), nu global. `PeakSnow`
	# ramane pe atlas (calota alba).
	"canyon_rocks": {"Canyon_": _TF_SCHIST},
	"rock_large": {"Rock_Large": _TF_SCHIST},
	"mountain_peak": {"MountainPeak": _TF_SCHIST},
	"snow_wall": {"SnowWall_A_Snow": _TF_SNOW, "SnowWall_B_Snow": _TF_SNOW},
	"tunnel_portal_balea": {"Portal_Snow": _TF_SNOW, "Portal_Concrete": _TF_CONCRETE},
	# Numele intregi: prefixul `Dam_` ar prinde si `Dam_Rail` (dungile rosii, pe atlas).
	"vidraru_dam": {"Dam_Module_Concrete": _TF_CONCRETE,
		"Dam_PowerHouse_Concrete": _TF_CONCRETE, "Dam_Tower_Concrete": _TF_CONCRETE},
	"retaining_wall_straight": _TF_WALL, "retaining_wall_curve": _TF_WALL,
	"arges_house_a": _TF_HOUSE, "arges_house_b": _TF_HOUSE,
	"cabana_balea_lac": {"Cabana_Stone": _TF_STONE, "Cabana_Roof": Palette.ATLAS_PREFIX},
	"cabana_balea_cascada": {"Cascada_Stone": _TF_STONE,
		"Cascada_Roof": Palette.ATLAS_PREFIX},
	"stana": {"Stana_Roof": Palette.ATLAS_PREFIX},
	"jneapan_a": _TF_JNEAPAN_BUSH, "jneapan_b": _TF_JNEAPAN_BUSH,
	"beech_tree_a": _TF_BEECH_TREE, "beech_tree_b": _TF_BEECH_TREE,
	"bujor_de_munte": {"Bujor_Bloom": _TF_BLOOM},
}

## Ca [constant CLASSES_BY_MODEL], dar scopat pe TEMA pistei (`_ancestor_theme`),
## nu global — la fel cum [constant SLOT_REMAP_BY_THEME] exista langa
## [constant SLOT_REMAP_BY_MODEL].
##
## De ce nu direct in `CLASSES_BY_MODEL`: `chasm_rock.glb` e piesa fiordland a
## marmitelor (Track16 POI D), dar numele e generic si ramane reuse posibil pe
## alte piste (ca `moss_boulder_*` dinspre Machu Picchu, in sens invers) — o
## intrare globala i-ar schimba culoarea oriunde ar fi plasat, nu doar aici.
##
## Verdict critic runda 5 POI B (Fiordland): peretele de gneis din dreapta
## cornisei citea placa gri uniforma, fara dungile ude verticale si fara
## muschiul din crapaturi — semnatura de material ceruta de brief §4/§5.6.
## `chasm_rock` folosit ca bolovan de perete langa drum (nu doar in albia
## raului la POI D) e exact suprafata care trebuie sa citeasca gneisul ud, nu
## un gri neutru plat (`SLOT_REMAP_BY_THEME` ii da azi doar VOLCANIC_BLACK pe
## slotul 29 — culoare corecta ca ton, dar plata, fara dala). `wet_gneiss` e
## deja clasa corecta (stirling_ledge.Wall, torrent_chute.Rock, acelasi verdict
## de brief) si costa ZERO materiale noi: e cache pe clasa, nu pe model.
const CLASSES_BY_THEME := {
	# Kyoto, valul 2: clasele pieselor RUPTE de SPLIT_MODELS_BY_THEME. Aici, nu in
	# CLASSES_BY_MODEL, fiindca ruptura e amanata (call_deferred) si clasele de
	# model se pun SINCRON, inaintea ei — pe nodul nerupt ar fi sters accentele.
	# Accentele numite explicit (`*_Accente`) primesc clasa lor; celelalte raman
	# pe atlas (garda din `_apply_classes_mapping`).
	"kyoto": {
		"koyasu_pagoda": {"Pagoda_Body": Palette.TRI_PREFIX + "shu_vermilion"},
		"sanjunoto_pagoda": {"Pagoda_Body": Palette.TRI_PREFIX + "shu_vermilion"},
		"yasaka_pagoda": {"Pagoda_Body": Palette.TRI_PREFIX + "shu_vermilion"},
		"niomon_gate": {"Gate_Wood": Palette.TRI_PREFIX + "shu_vermilion"},
		"inari_romon": {"Gate_Wood": Palette.TRI_PREFIX + "shu_vermilion"},
		"torii_large": {"Torii_Large": Palette.TRI_PREFIX + "shu_vermilion"},
		"torii_senbon": {"Torii_Senbon": Palette.TRI_PREFIX + "shu_vermilion"},
		"small_shrine": {"Shrine_Wood": Palette.TRI_PREFIX + "shu_vermilion",
			"Shrine_Roof": Palette.TRI_PREFIX + "kawara",
			"Shrine_Roof_Accente": Palette.TRI_PREFIX + "shu_vermilion"},
		# Kiyomizu: stalpii scenei (28) lemn inchis, grinzile (9) lemn deschis.
		"kiyomizu_hondo": {"Hondo_Wood": Palette.TRI_PREFIX + "machiya_wood",
			"Hondo_Wood_Accente": Palette.TRI_PREFIX + "wood"},
		# Esafodajul kakezukuri: lemnul 9 ia `wood`; stalpii LARCH_RUST 27 raman
		# pictati (mai deschisi decat orice clasa de lemn de pe pista).
		"kakezukuri_scaffold": {"Scaffold_Wood": Palette.TRI_PREFIX + "wood"},
		"kinkakuji": {"Kin_Wood": Palette.TRI_PREFIX + "wood",
			"Kin_Wood_Accente": Palette.TRI_PREFIX + "machiya_wood"},
		"togetsukyo_module": {"Toget_Wood": Palette.TRI_PREFIX + "wood",
			"Toget_Wood_Accente": Palette.TRI_PREFIX + "machiya_wood"},
		"tsutenkyo_roof_module": {"Tsu_Wood": Palette.TRI_PREFIX + "wood",
			"Tsu_Wood_Accente": Palette.TRI_PREFIX + "machiya_wood"},
		"moso_culm": {"Moso_Culm": Palette.TRI_PREFIX + "bamboo_culm"},
		"bamboo_crown": {"Bamboo_Culms": Palette.TRI_PREFIX + "bamboo_culm"},
	},
	"fiordland": {
		"chasm_rock": {
			"Rock_001": Palette.TRI_PREFIX + "wet_gneiss",
		},
		# Lotul STANCA UDA: moss_boulder_b, DUPA ruptura (_split_theme_accents,
		# SPLIT_MODELS_BY_THEME) — corpul, curatat de capacul de muschi, ramane
		# numit "Moss_Boulder_B" (ruptura nu redenumeste nodul original, doar
		# ii scoate un copil `_Accente`), deci cheia de aici il gaseste direct.
		# moss_boulder_a/c NU intra: ruptura lor a fost refuzata (suprapunere
		# de y prea mare, vezi SPLIT_MODELS_BY_THEME), deci raman intregi cu
		# `SLOT_REMAP_BY_THEME` (fara clasa triplanara).
		"moss_boulder_b": {
			"Moss_Boulder_B": Palette.TRI_PREFIX + "wet_gneiss",
		},
	},
	# Monument Valley (Track19): gresia `mv_sandstone` pe nodurile `*_Rock` ale
	# kitului, SALVIA gri-verde pe `Sagebrush_Foliage`. Cheia e pe FISIER (stem),
	# nu pe numele nodului (memoria `nume-noduri-nu-sunt-unice`), si scopata pe
	# TEMA: `rock_arch.glb`, `butte.glb` & co de pe celelalte piste nu se ating.
	#
	# `*_Cap` ramane pe atlas, `*_Scree` ia gresia: vezi `MV_ROCK_*` mai sus.
	"monumentvalley": {
		"west_mitten": MV_ROCK_WEST,
		"east_mitten": MV_ROCK_EAST,
		"merrick_butte": MV_ROCK_MERRICK,
		"mesa_wall_module": MV_ROCK_MESA,
		"sandstone_arch": MV_ROCK_ARCH,
		"butte_small_a": MV_ROCK_BUTTE_A,
		"butte_small_b": MV_ROCK_BUTTE_B,
		"butte_small_c": MV_ROCK_BUTTE_C,
		"rock_fin": MV_ROCK_FIN,
		"hoodoo": MV_ROCK_HOODOO,
		"talus_boulders_a": MV_ROCK_TALUS,
		"talus_boulders_b": MV_ROCK_TALUS,
		"sagebrush": {"Sagebrush_Foliage": Palette.TRI_PREFIX + "mv_sage"},
		# Postul de negot: piatra pe clasa calotei (#B9A08C), nu pe SAND_LIGHT (galben).
		"trading_post": {"Post_Stone": _MVC},
	},
	# Okinawa (Track20): vezi `CLASSES_OKINAWA`.
	"okinawa": CLASSES_OKINAWA,
	# Transfagarasan (Track21): vezi `CLASSES_TRANSFAGARASAN`.
	"transfagarasan": CLASSES_TRANSFAGARASAN,
}

## Modelele care NU arunca umbra: siluetele de orizont, scalate/asezate la
## 200-300 m. Un caster de 300 m care intra in cascada de umbre ii prabuseste
## precizia pentru prim-plan (memoria `caster-departat-fura-umbra`: hornurile
## Cappadociei se auto-umbreau pe fata dinspre soare din cauza inelelor de
## orizont). `_build_horizon` din track.gd face acelasi lucru pe siluetele
## procedurale; aici e varianta pentru orizontul asezat de mana.
const NO_SHADOW_MODELS := {
	"lengai": true, "crater_far_wall": true, "kyoto_horizon": true,
	"horizon_mesas": true,
}


## Kitul de tuf (Cappadocia) si-a ales sloturile DUPA NUME, nu dupa culoare.
##
## `build_cappadocia_tuff.py` scrie `TUFF_MID = SAND_MID` si
## `TUFF_SH = SAND_SHADOW`, cu intentia „banda de variatie de VALOARE" pe un con
## crem. Dar sloturile alea nu sunt cremuri mai inchise, sunt portocaliul
## desertului: masurat, SAND_MID e #D4994D (saturatie 0,64) si SAND_SHADOW e
## #915D27 (0,73), pe langa CORAL_SAND #E9DCC0 (0,18). Rezultatul, vazut in
## captura de sofer de la fractia 0,06: hornurile ies in dungi late portocalii
## si ruginii — cosuri de fabrica, nu conuri de tuf. Referinta v3
## (`img/v3_crops/B_chimneys.png`) le are crem UNIFORM, cu doar palaria inchisa,
## iar regula de arta din brief §0.1 cere ~45% saturatie pe tot mediul.
##
## Se corecteaza aici, la incarcare, mutand UV-urile pe sloturile crem care CHIAR
## sunt variatie de valoare: CONCRETE #C8BDA9 (sat 0,22, luminanta 184) pentru
## banda medie si MARBLE_GREY #B8B4AC (sat 0,08, luminanta 178) pentru umbra.
##
## ATENTIE la cine mai umbla aici: sloturile astea NU se schimba pe unele mai
## calde. S-a incercat (runda 10, ROCK_LIGHT + LARCH_RUST, ca raspuns la
## "chalk-white" din critica) si a iesit mai rau decat punctul de plecare:
## benzile din .glb sunt SUPRAFETE LATI, nu foi subtiri de strat, deci orice
## slot cu saturatie 0,5 le transforma in dungi portocalii — cos de fabrica,
## exact defectul din runda 6. Culoarea a doua benzi late nu poate fi si calda,
## si discreta; e o problema de SUPRAFATA, nu de slot.
##
## Caldura ceruta de critica se pune in schimb din VERTEX COLOR, in
## `_warm_tuff()` de mai jos: acolo se inmulteste tot conul cu o tenta calda,
## deci se muta nuanta fara sa se schimbe raportul dintre benzi.
##
## De ce aici si nu in .glb: piesele sunt de KIT, folosite de toate POI-urile
## pistei, iar un re-export atinge sase scripturi de build si toate cele 45 de
## modele. Remaparea nu adauga niciun material si niciun slot — muta doar u-ul
## pe centrul altui slot din acelasi atlas.
##
## Cheia e pe FISIER, nu pe numele partii: maparile pe nume sunt globale in tot
## proiectul (lectia `nume-noduri-nu-sunt-unice`), iar „Chimney_A" n-are voie sa
## atinga alta pista.
const TUFF_UV_REMAP := {
	1: Palette.CONCRETE,
	2: Palette.MARBLE_GREY,
}

## Modelele pe care se aplica remaparea de mai sus: kitul de tuf al Cappadociei.
##
## Lista a crescut cand piata din Goreme a primit stratul uman. Piesele acelea
## existau in kit dar nu fusesera asezate niciodata, deci nimeni nu observase
## ca stau pe portocaliul desertului. Masurat pe ARIE (ProbeCappSlot, nou —
## aria spune CAT, hexul spune CE): `farmhouse` era 37% SAND_MID #D4994D,
## `cracked_chimney_c` 67% SAND_SHADOW #915D27, `cracked_chimney_b` 38%.
## In captura de la frac 0,02 ieseau lazi portocalii langa conuri crem, adica
## exact accidentul pe care remaparea asta il repara la hornuri.
##
## `church_arch` cere in plus ROCK_DARK -> ARCH_SHADOW: e singura piesa cu 35%
## din arie pe slotul 4 (#67421F, maro inchis), fiindca arcada are un intrados
## adanc. Lasat asa, arcul citea ca lemn ars. Vezi `ARCH_UV_REMAP`.
##
## Ce NU intra, si de ce: `vine_row` e 91% CACTUS_GREEN si `torch` 66%
## RUST_METAL + 34% flacara — nu sunt tuf, si trecerea lor pe crem ar sterge
## exact cele doua pete de culoare pe care le aduc in piata.
const TUFF_UV_MODELS := [
	"chimney_a", "chimney_b", "chimney_c", "chimney_d",
	"chimney_mushroom", "chimney_triple", "twin_chimney_gate",
	"cave_house_a", "cave_house_b", "cave_house_c",
	"dovecote", "rock_church_facade",
	"farmhouse", "cave_entrance", "church_arch",
	"cracked_chimney_a", "cracked_chimney_b", "cracked_chimney_c",
]

## Remapare SUPLIMENTARA, doar pentru arcada: maroul inchis al intradosului.
## Se tine separat fiindca ROCK_DARK e legitim pe restul kitului (crapaturi,
## interior de faleza) — mutat global, ar aplatiza fiecare umbra sapata din
## pista. MARBLE_GREY e deja folosit de umbra de tuf, deci arcul ramane in
## aceeasi familie de valoare fara sa ceara un slot nou.
const ARCH_UV_REMAP := {
	4: Palette.MARBLE_GREY,
}

## Piesele care primesc si `ARCH_UV_REMAP`, pe langa cea de tuf.
const ARCH_UV_MODELS := ["church_arch"]

## `red_mesa` NU intra in lista de mai sus, desi e din acelasi kit si are
## aceleasi sloturi in .glb. Acolo rosul e INTENTIA: masa e stratul rosu al
## vaii, singura suprafata mare non-crem a pistei (vezi `custom_strata_tint` pe
## Track13). Trecuta prin remapare ar fi iesit crem ca tot restul, adica exact
## culoarea pe care pista o cauta ca sa nu fie monocroma.

## Sloturi de paleta rescrise PER MODEL, inainte de orice material.
##
## Un GLB isi aduce sloturile din Blender, si uneori sunt sloturile gresite
## pentru pista pe care ajunge. Cazul masurat: `hollow_rock` (Cappadocia, POI G)
## e desenat pe sloturi generice de stanca — dominant ROCK_DARK (4), plus
## ASPHALT_EDGE (6) si TILE_TERRACOTTA (23). ROCK_DARK e MARO-PORTOCALIU, si pe
## el coaja iesea cu o banda de rugina lata cat stanca: exact reprosul
## „conul portocaliu/crem" din verdict, si aceeasi capcana pe care o descrie
## memoria `rock-dark-nu-pe-bazalt` (pe Stromboli ROCK_DARK iesea rugina).
##
## Se rescrie UV-ul, nu paleta: atlasul e 32x1, deci slotul unui vertex e
## `floor(u * 32)` si mutarea lui inseamna doar alt `u`. Asa NU se atinge niciun
## slot global (l-ar schimba pe toate pistele) si nu se cheltuie unul nou —
## slotul 31 s-a consumat la Chongqing, brief §4.
##
## Tinta e CORAL_SAND (19), cremul de tuf pe care il declara deja tema
## (`ground_tint`), plus SAND_SHADOW (2) pentru partile care trebuie sa ramana
## mai INCHISE decat restul: fara o a doua valoare coaja ar iesi o silueta plata
## de o singura culoare, si tot din verdict venea „culori plate".
## Rescrieri de sloturi PER GRUP de decor manual, care bat pe cele per model.
##
## De ce: `hall_alcove` primeste mai jos o rescriere gandita pentru FIRIDELE
## din peretele stancii goale (POI G) — corpul firidei pe ASPHALT_EDGE, gri
## spalat. Dar aceeasi piesa e si zidul oraselului subteran (POI F, 1300 de
## bucati in F1-F5), desenat in kit pe tuf umbrit (2), stanca bruna (4) si
## rugina (10) — adica exact piatra calda de sub torte din referinta
## (`v3_crops/F_underground.png`). Rescrierea globala a facut salile gri ca o
## parcare: reprosul „orasul subteran arata industrial" din finding_ramase
## (3 sep 2026). Un dictionar gol inseamna „lasa piesa cum vine din kit".
##
## Grupul e copilul direct al nodului DecorManual sub care sta piesa.
##
## `church_arch` are ACEEASI poveste, gasita in sep 2026 cand s-a cerut o
## textura de fresca pentru Sala 2. Rescrierea de mai jos (SLOT_REMAP_BY_MODEL)
## e gandita pentru ARCUL DE FEREASTRA din peretele stancii goale (POI G), unde
## rosul si negrul kitului citeau „potcoava ruginie" pe zid crem. Dar aceeasi
## piesa e si ARCADA DE BISERICA RUPESTRA din subteran, unde exact sloturile
## alea SUNT frescele: `build_cappadocia_underground.py` picteaza benzile de pe
## pilastri, medalionul si crucea pe FRESCO_RED = TILE_TERRACOTTA (23),
## FRESCO_RUST = LARCH_RUST (27) si FRESCO_DARK = VOLCANIC_BLACK (20).
##
## Masurat (tools/probe_fresco_px_tmp.gd, sonda temporara): pe `.glb` arcul are
## 278 tri pe 23, 156 pe 20 si 64 pe 27 — 10,7% din arie. In scena, INAINTE de
## fixul asta, histograma de sloturi pe acelasi arc era `19:283, 29:1013`:
## ZERO triunghiuri de fresca, fiindca 23/20/27 fusesera mutate pe SAND_SHADOW
## si de acolo, prin `TUFF_UV_REMAP`, pe MARBLE_GREY. Arcada de biserica era
## un arc de piatra cenusie, si asta e motivul pentru care patru critici orbi au
## cerut „fresce pictate" pe o piesa care le AVEA in kit.
##
## Deci frescele nu cer o textura de clasa si un material in plus: cer sa nu li
## se mai stearga sloturile in sala. `_retint_tuff` ramane activ pe restul
## piesei (2 -> 29), asa ca arcul isi pastreaza valoarea de tuf; doar accentele
## pictate se intorc.
const SLOT_REMAP_BY_GROUP := {
	"F1_Gura": {"hall_alcove": {}, "church_arch": {}},
	"F2_Sala1": {"hall_alcove": {}, "church_arch": {}},
	"F3_Gat": {"hall_alcove": {}, "church_arch": {}},
	"F4_Sala2": {"hall_alcove": {}, "church_arch": {}},
	"F5_Ocol": {"hall_alcove": {}, "church_arch": {}},
	# Serengeti, POI A (campul de safari). Masurat pe captura --gamecam la
	# 0.97 fata de ref_A.png: prelata cortului e pe CORAL_SAND 19 (#E9DCC0) si
	# sub soarele cald iese ALBA — in referinta corturile sunt kaki-bej;
	# CONCRETE 8 (#C8BDA9) e cel mai apropiat bej din atlas. Coroana acaciei
	# are pete pe DRY_VEGETATION 13 (galbenul ierbii) peste verdele 21: in
	# referinta coroanele sunt verde-oliv uniform, deci petele trec pe
	# CACTUS_GREEN 12. Scop pe GRUP, nu pe model: alte POI-uri decid singure.
	"ZoneA_Camp": {
		# Tufa cu frunza lata e din kitul tropical (verde 21 lucios, de
		# bananier); pe savana trece pe CACTUS_GREEN 12, oliv sters, ca sa
		# citeasca a tufa uscata pe iarba aurie (ref_A.png).
		"broadleaf_shrub": {21: Palette.CACTUS_GREEN},
		"grass_tuft_large": {21: Palette.DRY_VEGETATION,
			13: Palette.DRY_VEGETATION},
		"safari_tent": {19: Palette.CONCRETE},
		"acacia_umbrella_a": {13: Palette.CACTUS_GREEN},
		"acacia_umbrella_b": {13: Palette.CACTUS_GREEN},
		"acacia_umbrella_c": {13: Palette.CACTUS_GREEN},
	},
}

## Ca [constant SLOT_REMAP_BY_GROUP], dar scopeaza pe TEMA pistei
## (`Track.theme_decor`, citit prin `_ancestor_theme`), nu pe numele grupului
## de decor manual.
##
## De ce nu GROUP: `moss_boulder_a/b/c.glb` e reuse din Machu Picchu (brief
## fiordland_kit.md), iar pe Fiordland zonele POI sunt inca goale — nu exista
## niciun nume de grup de care sa agatam o reparatie. Tema exista din prima zi
## a pistei (`custom_theme = "fiordland"` in Track16.tscn), deci e cheia care
## nu asteapta dupa niciun POI. Scop pe TEMA, nu pe MODEL (SLOT_REMAP_BY_MODEL
## ar fi global): Machu Picchu (tema "machupicchu") foloseste acelasi
## `moss_boulder_*.glb` prin `_model_flock` cu `tri_class="inca_stone"`
## (tools/gen_decor_mp_f.gd), care ignora complet sloturile de atlas — dar
## piesele plasate individual (WorldProp, ex. `--vitrina`) tot citesc atlasul,
## si o remapare globala pe model le-ar fi schimbat si pe Track15.
const SLOT_REMAP_BY_THEME := {
	# Transfagarasan (Track21), tabla acoperisurilor. Brief: tabla argintie, dar slotul
	# ASPHALT_EDGE 6 (#696765) e gri de asfalt, iar o clasa o poate doar INTUNECA. Deci slotul
	# se muta pe MARBLE_GREY 29 (#B8B4AC), fara material nou. `cascada` are tabla pe
	# RUST_METAL 10 (#91461E, saturatie 0.79, "foarte saturata"): trece pe LARCH_RUST 27
	# (#A8683A, 0.65). `stana` are ambele (78% argintie, 22% ruginita). Slotul 6 nu e folosit
	# de alt nod din aceste modele (masurat pe UV-uri), deci mutarea atinge doar tabla.
	"transfagarasan": {
		# Tabla argintie pe PAINTED_METAL (#7692A8), nu pe MARBLE_GREY: sub soarele cald
		# al temei (1, .85, .66) MARBLE_GREY iesea bej, ca stuful (POI A, runda 1), pe
		# cand albastrul lui PAINTED_METAL se neutralizeaza spre gri (~118,124,111) si
		# citeste tabla albastru-gri din diorama. Zero material nou (remap de slot).
		"arges_house_a": {6: Palette.PAINTED_METAL},
		"cabana_balea_lac": {6: Palette.PAINTED_METAL},
		# Prometeu: bronzul pe LARCH_RUST iesea „jucarie portocalie” (162,85,36) sub soarele
		# temei (critic/constructor POI B r1). DRY_VEGETATION da auriu mat (180,139,52),
		# bronzul din diorama; umbrele raman pe LOG_DARK.
		"prometheus_statue": {27: Palette.DRY_VEGETATION},
		"cabana_balea_cascada": {10: Palette.LARCH_RUST},
		"stana": {6: Palette.MARBLE_GREY, 10: Palette.LARCH_RUST},
		# Trunchiul fagului: scoarta neteda dar INCHISA, nu cremul slotului 29 (#B8B4AC).
		# Mutata pe VOLCANIC_BLACK 20 (#55535A), fara material nou (tenta doar intuneca,
		# dar un ATINT ar fi costat un material pentru un trunchi).
		"beech_tree_a": {29: Palette.VOLCANIC_BLACK},
		"beech_tree_b": {29: Palette.VOLCANIC_BLACK},
	},
	"fiordland": {
		# `moss_boulder_a/b/c`: masurat pe .glb (probe ad-hoc), un SINGUR
		# material/mesh cu trei sloturi — corpul pe 3 ROCK_LIGHT (bej-tan
		# 206,141,74), inelul de baza pe 29 MARBLE_GREY (gri deschis
		# 182,178,170) si capacul de "muschi" pe 12 CACTUS_GREEN (oliv
		# 88,120,50). Pe Fiordland, sub soarele rece al temei, asta randa
		# DAMIER galben-verde / corp ALB cu capac verde crud / corp portocaliu
		# (vezi capturile POI B/C/D) — bolovanul citea a piatra calda de
		# Anzi, nu a gneis Fiordland.
		#
		# Bara (bara_poi_B/C/D.png) cere stanca INCHISA invelita in muschi
		# VERDE INCHIS, aceeasi materie ca peretele `stirling_ledge`/terenul
		# pe pantă (`scarp_tint`, randat ~(62,63,63), aproape achromatic). Nu
		# exista slot de atlas la (62,63,63) exact, dar 20 VOLCANIC_BLACK
		# (86,84,91, H257 L0.34 S0.04) e cel mai apropiat gri-neutru inchis
		# deja in atlas — ZERO sloturi noi. Corpul SI inelul de baza trec pe
		# 20, ca sa fie aceeasi piatra (fara sa desparta bolovanul in doua
		# materii la baza). Capacul trece pe 21 TROPICAL_GREEN (66,127,62,
		# H116) — mai inchis si mai saturat decat 12, verde de muschi de
		# padure temperata, nu oliv de tufa uscata.
		"moss_boulder_a": {3: Palette.VOLCANIC_BLACK, 29: Palette.VOLCANIC_BLACK,
			12: Palette.TROPICAL_GREEN},
		"moss_boulder_b": {3: Palette.VOLCANIC_BLACK, 29: Palette.VOLCANIC_BLACK,
			12: Palette.TROPICAL_GREEN},
		"moss_boulder_c": {3: Palette.VOLCANIC_BLACK, 29: Palette.VOLCANIC_BLACK,
			12: Palette.TROPICAL_GREEN},
		# `chasm_rock` NU mai e aici din runda 5 POI B: fixul de runda 4
		# (VOLCANIC_BLACK pe slotul 29) dadea gneisul ca ton corect dar plat —
		# criticul a cerut semnatura de material (dungi ude + muschi in
		# crapaturi), nu doar culoarea, deci piesa a trecut pe clasa
		# triplanara `wet_gneiss` (`CLASSES_BY_THEME`, mai jos in fisier).
		# `material_override` inlocuieste tot ce era pe atlas, inclusiv
		# remaparea asta de slot — pastrarea ei aici ar fi o a doua sursa
		# de adevar moarta, niciodata citita.
	},
}

## Ca [constant SPLIT_MODELS], dar scopat pe TEMA pistei (`_ancestor_theme`),
## nu global — acelasi motiv ca [constant SLOT_REMAP_BY_THEME]: piesa e reuse
## pe alta pista, cu alta tema, si acolo nu trebuie sa se rupa.
##
## Lotul STANCA UDA (Fiordland): `moss_boulder_b` (corp remapat pe 20
## VOLCANIC_BLACK de `SLOT_REMAP_BY_THEME`, capac de muschi pe 21
## TROPICAL_GREEN, y corp 0.00-1.06 / y capac 0.92-1.96 pe o piesa de 1.957 m
## — suprapunere 0.14 m, 7.2% din inaltime) primeste ruptura: corpul, curatat
## de muschi, poate lua `wet_gneiss` (CLASSES_BY_THEME, mai jos) fara sa
## piarda capacul verde, care ramane pictat.
##
## `moss_boulder_a` si `moss_boulder_c` NU intra aici, desi arata la fel la
## prima vedere (acelasi kit, aceeasi remapare de slot). Masurat cu
## tools/probe_slots.gd --dir=machupicchu/rocks (y-urile de mai jos sunt DUPA
## remaparea de tema, calculate din sloturile brute 3+29 -> 20 si 12 -> 21):
##   moss_boulder_a: corp y 0.00-0.68, capac y 0.38-0.74 (h 0.741) —
##     suprapunere 0.30 m = 40.5% din inaltime
##   moss_boulder_c: corp y 0.00-1.66, capac y 0.97-3.07 (h 3.069) —
##     suprapunere 0.69 m = 22.5% din inaltime
## Verificat si pe FOOTPRINT (x/z): muschiul acopera aproape tot conturul
## orizontal al bolovanului la toate trei (nu un petic intr-o parte), deci
## banda de muschi INFASOARA bolovanul ca un guler — asta e normal si nu
## descalifica o ruptura pe cont propriu (la fel ca o creasta cu capac de
## zapada, memoria `benzi-vertex-color-bisect`). Ce descalifica e cat de MULT
## se intretaie pe verticala cu piatra: la `_a`/`_c` muschiul se intinde in
## jos peste o treime sau mai mult din corp, exact tiparul `stirling_ledge.
## Overhang`/`inca_house_b` (22.8-27.0%, "intervalele de y se suprapun cu
## stanca, deci o ruptura ar taia gresit"); la `_b`, 7.2% e in familia
## `guard_rock` (3.4%) si `torrent_chute.Rock` (sub prag, nici n-a cerut
## ruptura). Pragul care conteaza e SUPRAPUNEREA, nu procentul brut de arie.
const SPLIT_MODELS_BY_THEME := {
	"fiordland": {
		"moss_boulder_b": true,
	},
	# Kyoto, valul 2 de materiale (docs/track_briefs/kyoto_materiale.md §Valul 2):
	# nodurile MIXTE ale templelor si podurilor se rup PE SLOT, ca vermilionul /
	# lemnul / tulpina sa ia clasa fara sa stearga restul. Ruptura e pe triunghi
	# (`Palette.split_accents`), iar piesele de arhitectura au sloturile pe fete
	# separate (panouri, grinzi, stalpi), deci ruptura e exacta — testul de
	# suprapunere pe y al rocilor cu muschi nu se aplica aici.
	"kyoto": {
		"koyasu_pagoda": true, "sanjunoto_pagoda": true, "yasaka_pagoda": true,
		"niomon_gate": true, "inari_romon": true,
		"kiyomizu_hondo": true, "kakezukuri_scaffold": true,
		"kinkakuji": true, "togetsukyo_module": true, "tsutenkyo_roof_module": true,
		"torii_large": true, "torii_senbon": true, "small_shrine": true,
		"moso_culm": true, "bamboo_crown": true,
	},
}

## Ca [constant ACCENT_SPLIT], dar consultat DOAR de [method
## _split_theme_accents], pentru intrarile din [constant SPLIT_MODELS_BY_THEME].
## Cheia e numele de nod (dupa remaparea de slot), valoarea slotul/sloturile
## care raman in CORP.
const ACCENT_SPLIT_BY_THEME := {
	"fiordland": {
		# Dupa SLOT_REMAP_BY_THEME, corpul lui moss_boulder_b e pe 20
		# VOLCANIC_BLACK (3 si 29 mutate acolo); capacul de muschi ramane pe 21
		# TROPICAL_GREEN si pleaca in `_Accente`.
		"Moss_Boulder_B": Palette.VOLCANIC_BLACK,
	},
	# Valoarea = sloturile care raman pe CORP (si primesc clasa corpului); restul
	# pleaca in `_Accente` (atlas, sau clasa numita explicit in CLASSES_BY_THEME).
	"kyoto": {
		"Pagoda_Body": Palette.LAVA_ORANGE,     # vermilion; var 22 + lemn 28 raman
		"Gate_Wood": Palette.LAVA_ORANGE,       # vermilion; grinda 9 + 28 raman
		"Torii_Large": Palette.LAVA_ORANGE,     # vermilion; kasagi 28 + soclu 20
		"Torii_Senbon": Palette.LAVA_ORANGE,
		"Shrine_Wood": Palette.LAVA_ORANGE,
		"Shrine_Roof": [Palette.ASPHALT_EDGE, Palette.LOG_DARK],  # tigla; fascia 30 -> accent
		"Hondo_Wood": Palette.LOG_DARK,         # stalpii scenei 28; grinzile 9 -> accent
		"Kin_Wood": Palette.WOOD_WEATHERED,
		"Toget_Wood": Palette.WOOD_WEATHERED,
		"Tsu_Wood": Palette.WOOD_WEATHERED,
		"Scaffold_Wood": Palette.WOOD_WEATHERED,
		"Moso_Culm": Palette.CACTUS_GREEN,      # tulpina 12; inelele 13 raman
		"Bamboo_Culms": Palette.TROPICAL_GREEN, # tulpina 21; inelele 13 raman
	},
}

const SLOT_REMAP_BY_MODEL := {
	# Ursul brun (Transfagarasan, Track21): blana pe LARCH_RUST 27 (#A8683A) iesea
	# portocalie sub soarele temei, (161,88,40) pe captura, adica vaca ruginie; pe
	# WOOD_WEATHERED 9 tot (138,84,40). Blana intreaga pe LOG_DARK 28 (#4A3526).
	# Sta AICI, nu in SLOT_REMAP_BY_THEME: ursul e modelul unui HazardMarker, iar
	# `SlidingHazard._remap_model_slots` citeste doar tabelul pe model. Pe tema,
	# remaparea nu ajungea niciodata la urs (captura de joc: tot roscat).
	"brown_bear": {27: Palette.LOG_DARK},
	# `wharf.glb` (Fiordland POI A): toata fata de SUS a peretelui de piatra
	# (17 triunghiuri, y in [1.98, 2.12] — masurat direct pe mesh, acopera
	# intreaga lungime de 20 m si latime de 4,2 m, deci CHIAR platforma de
	# mers, nu un accent mic) e pe slotul 21 TROPICAL_GREEN, nu 29 MARBLE_GREY
	# ca restul peretelui. Contractul (`fiordland_kit.md`): "Blocuri
	# MARBLE_GREY, babale VOLCANIC_BLACK" — DOI sloturi, fara verde. Pe
	# captura, platforma iese verde-crud (culoarea ierbii), nu piatra gri a
	# babalelor de langa ea — se citeste ca un acoperis de casa, nu ca zid de
	# chei (bara: piatra uniforma). Kitul are 400/400 triunghiuri (buget
	# epuizat), deci nu se rescrie GLB-ul aici — remap de slot, ca la
	# acaciile-umbrela.
	"wharf": {21: Palette.MARBLE_GREY},
	# `fort_gate_loha.glb` (Jodhpur POI E): canaturile `GateLoha_Doors` sunt pe
	# slotul 11 PAINTED_METAL (+20), iar pe Jai/Fateh pe 9 WOOD_WEATHERED (+20).
	# Slotul 11 e albastru-vopsea (containere), deci canaturile Loha ieseau
	# albastre in toate capturile E; bara cere „canaturi de lemn inchis" la
	# toate portile. Remap cheiat pe model, ca la wharf: tuk-tuk-ul isi pastreaza
	# slotul 11, nicio alta piesa nu se atinge.
	"fort_gate_loha": {Palette.PAINTED_METAL: Palette.WOOD_WEATHERED},

	# Acaciile-umbrela (Serengeti, POI B): coroana e pe 13 (DRY_VEGETATION —
	# ACELASI slot ca iarba de sub ele, deci fata de sus a coroanei iesea
	# (190,188,96), identica cu campia) si pe 21 (TROPICAL_GREEN, verde de
	# brocoli (92,183,50)). Referinta are coroane OLIV INCHIS, (69,68,26) /
	# (105,105,31), mai intunecate decat iarba. Amandoua merg pe CACTUS_GREEN
	# (5B7C34, oliv); variatia ramane din AO-ul din vertex colors si din
	# lumina. Trunchiul (28) si ramurile (12) nu se ating.
	"acacia_umbrella_a": {13: Palette.CACTUS_GREEN, 21: Palette.CACTUS_GREEN},
	"acacia_umbrella_b": {13: Palette.CACTUS_GREEN, 21: Palette.CACTUS_GREEN},
	"acacia_umbrella_c": {13: Palette.CACTUS_GREEN, 21: Palette.CACTUS_GREEN},
	# Tufa de savana: acelasi verde ca acaciile de langa ea (21 -> 12).
	# A/B runda 1b (POI B): totul pe 21 TROPICAL_GREEN da (65,133,35), nuanta
	# 0.28 (verde de brocoli); pe 12 da (139,148,54), nuanta 0.18 = nuanta
	# referintei (92,93,34), doar mai deschis. Se pastreaza 12: nuanta e a
	# slotului, valoarea e a luminii.
	# Runda 2: si slotul 12 (CACTUS_GREEN) al tufei merge pe 13 DRY_VEGETATION.
	# Masurat pe fasia de umar din cadrul de joc, referinta are 0,6 % verde viu
	# la nivelul solului; tot verdele ei e in coroanele acaciilor. Tufa ramane
	# ca SILUETA (etaj intre sol si coroane), dar in registrul uscat al campiei.
	"tropical_shrub": {21: Palette.CACTUS_GREEN, 12: Palette.DRY_VEGETATION},
	# Smocurile de iarba (POI B, runda 2). Slotul unei piese se citeste din
	# UV.x * 32, nu din vertex color — prima incercare a remapat sloturile 7 si
	# 8 (citite gresit din culoarea vertecsilor) si smocurile au ramas VERZI pe
	# captura. Masurat corect (UV): `grass_tuft_large` e pe 12 CACTUS_GREEN +
	# 21 TROPICAL_GREEN, `grass_tuft_small` pe 13 + 12. Pe savana toate merg pe
	# 13 DRY_VEGETATION (#AF9F4E) — acelasi slot ca iarba campiei, ca smocul sa
	# fie campia RIDICATA, nu un obiect verde asezat peste ea. Verdele ramane
	# doar pe coroanele acaciilor, unde referinta il are.
	"grass_tuft_large": {12: Palette.DRY_VEGETATION, 21: Palette.DRY_VEGETATION},
	"grass_tuft_small": {12: Palette.DRY_VEGETATION},
	# Elefantul: pe .glb corpul sta pe [2, 22, 29] — SAND_SHADOW, FOAM_WHITE si
	# MARBLE_GREY, adica trei griuri NEUTRE. Sub soarele cald al temei
	# (1.0, 0.90, 0.72) plus saturatia 1.18 din post, orice gri neutru iese
	# crem: masurat pe G_r1_lac.png, elefantii citeau ca bolovani albi, nu ca
	# animale. Aceeasi capcana ca la hipopotam (handoff §5.13): singurul gri
	# care ramane gri e un slot RECE. Pielea pe PAINTED_METAL (11, gri-albastrui,
	# masurat sat 0.09 pe hipopotam), fildesii raman pe FOAM_WHITE 22 ca sa
	# citeasca in contrast.
	# DOUA sloturi, nu unul: criticul rundei 2 a cerut ecart de valoare INTRE
	# corp / cap / urechi / fildesi, nu doar "sa nu fie crem". Pe .glb slotul 29
	# (56% din vertecsi) e masa corpului, slotul 2 (34%) capul, urechile si
	# picioarele, iar 22 (10%, z=[-3.21,-1.92]) sunt fildesii — masurat cu o
	# sonda pe UV-uri, nu ghicit. Corpul pe VOLCANIC_BLACK (20, #55535A, gri
	# rece inchis) ca sa stea SUB luminanta drumului, capul si picioarele pe
	# ASPHALT (5, #4B4B4D) gri NEUTRU inchis, fildesii raman pe FOAM_WHITE 22.
	# PAINTED_METAL 11 a fost incercat pe 2 si respins pe captura: e albastru
	# destul cat urechile si labele sa iasa bleu-plastic langa corpul gri
	# (masurat sat 0.12 dar citit ca petice colorate) — vezi G_r3_ele2.png.
	# Griurile NEUTRE ale .glb-ului ies crem sub soarele cald (1.0,0.90,0.72) +
	# saturatia 1.18 din post; doar sloturile RECI raman gri.
	"elephant": {
		2: Palette.ASPHALT,
		29: Palette.VOLCANIC_BLACK,
	},
	# Flamingii: pe .glb stau pe [4, 20, 31]. Penajul (31, 73% din vertecsi)
	# NU se mai remapeaza — slotul 31 e de acum FLAMINGO_PINK in atlas, exact
	# culoarea pentru care kitul a fost exportat.
	#
	# Patru runde de critica au cautat rozul in remap, si toate au esuat din
	# aceeasi cauza: slotul 31 era NEDEFINIT in HEX, deci generatorul de atlas
	# ii dadea magenta pur, iar magenta x sun_color da vermilion. Ocolirile
	# incercate, in ordine, toate respinse pe captura:
	#   - TILE_TERRACOTTA 23: portocaliu-caramida (G_r1_hero.png);
	#   - CONCRETE 8 palid: pasarile DISPAR pe crusta de soda alba
	#     (G_r3_flam.png) — pe fundal palid o masa palida nu are contrast;
	#   - CAR_RED 14: cea mai buna dintre ele, si tot rosu — masurat pe
	#     captura hero sat 0.66 la hue +16.3, fata de sat 0.51 la hue +3.9 in
	#     diorama de referinta.
	# Niciuna nu putea reusi: masurate toate cele 31 de culori scrise, atlasul
	# chiar nu avea niciun slot cu hue 300-30 sub saturatie 0.55. Reparatia era
	# o culoare noua in atlas, nu inca un slot vechi (vezi Palette.FLAMINGO_PINK).
	#
	# Ce ramane din rundele vechi, fiindca s-a masurat ca ajuta silueta: gatul
	# si capul (20, 14% din vertecsi, y=[0.82,1.23]) stau pe CONCRETE palid, ca
	# pasarea sa aiba un ecart de valoare in interior in loc sa fie o singura
	# bila; picioarele (4, ROCK_DARK maro) pe SAND_LIGHT, ca sa nu para batute
	# in crusta.
	"flamingo": {20: Palette.CONCRETE, 4: Palette.SAND_LIGHT},
	"flamingo_wings": {20: Palette.CONCRETE, 4: Palette.SAND_LIGHT},
	"hollow_rock": {
		4: Palette.CORAL_SAND,     # ROCK_DARK maro -> crem de tuf
		6: Palette.SAND_SHADOW,    # ASPHALT_EDGE -> tuf umbrit (valoare, nu tenta)
		23: Palette.CORAL_SAND,    # TILE_TERRACOTTA rosu -> crem
		0: Palette.CORAL_SAND,     # SAND_LIGHT galbui -> acelasi crem
		1: Palette.CORAL_SAND,     # SAND_MID ocru saturat -> crem
	},
	# Firidele din peretele stancii. Aceeasi poveste ca la coaja: piesa vine
	# desenata pentru sala subterana, deci pe stanca maro (2/4) si pe metal
	# ruginit (10) — pe zidul crem ieseau niste cutii maro lipite pe el.
	#
	# Fundul firidei ramane pe slotul 30 (`LAVA_ORANGE`), care e portocaliul
	# incandescent al paletei, si primeste emisie prin `CLASSES_BY_MODEL`. Asta
	# e chiar reprosul din verdict: „absentele arata cer, nu camere" — o
	# fereastra citeste ca incapere doar daca are un FUND si pe fund cade
	# lumina. Slotul nu e nou: e cel al lavei de pe Stromboli, refolosit ca
	# lumina de torta, exact rolul de accent care ARDE pentru care exista.
	# Care slot e FUNDUL s-a masurat, nu s-a ghicit (tools, z mediu pe triunghi):
	#   slot  2  z +0.162  -> cel mai in SPATE: fundul firidei
	#   slot  4  z +0.001  -> centrat: rama/glaful
	#   slot 10  z +0.094  -> feroneria
	# Prima incercare aprinsese slotul 4 si a iesit exact pe dos pe captura: o
	# RAMA portocalie in jurul unei gauri negre, adica o reclama luminoasa, nu
	# o incapere. Fundul se aprinde, rama ramane piatra.
	# [b]Runda 3: fundul nu mai ARDE, se INTUNECA.[/b] Vezi nota lunga din
	# CLASSES_BY_MODEL. Pe scurt: la rasarit, o scobitura in perete e cea mai
	# inchisa suprafata din cadru, nu cea mai deschisa. Masurat, firida
	# portocalie era de 1.78 ori mai luminoasa decat zidul INSORIT de langa ea.
	#
	# Fundul trece pe SAND_SHADOW (slotul 2), cel mai inchis tuf din paleta.
	# Rama ramane pe CORAL_SAND, ca peretele — asta nu se schimba: prima
	# incercare de acum doua runde aprinsese RAMA si iesise o reclama cu
	# contur, iar lectia aia ramane valabila.
	# [b]Runda 3, si nota veche identifica GRESIT partile.[/b] Ea zicea
	# "slot 2 z +0.162 -> cel mai in SPATE: fundul firidei". Semnul e invers:
	# in piesa +Z arata spre privitor, deci z-ul cel mai MARE e cel mai in
	# FATA. Remasurat pe GLB-ul original (z mediu si interval pe slot):
	#   slot  4  z +0.013, -0.750 .. +0.750  -> CORPUL firidei, toata adancimea
	#   slot 10  z +0.100, -0.179 .. +0.379  -> glaful, spre gura
	#   slot  2  z +0.156, -0.500 .. +0.750  -> buza, cel mai in fata
	# Adica slotul 4 nu e "rama", e chiar suprafata mare care se vede prin
	# deschidere — si el era remapat pe CORAL_SAND, cel mai PALID slot din
	# paleta (luminanta 221, fata de 100 al lui SAND_SHADOW).
	#
	# Asta era cauza reala a reprosului "panouri luminoase", nu emisia: masurat
	# pe captura, interiorul firidei avea luminanta 151.7 langa un zid insorit
	# la 85.1, adica de 1.78 ori mai luminos decat zidul BATUT DE SOARE. O
	# scobitura mai deschisa decat fata pe care bate soarele nu poate citi decat
	# ca suprafata care emite.
	#
	# Acum corpul si glaful trec pe SAND_SHADOW si firida devine ce trebuia sa
	# fie: o pata INTUNECATA, adica singurul indiciu ca peretele are grosime.
	# Buza (slotul 2) ramane crem: ea e piatra taiata a deschiderii, batuta de
	# soare ca restul peretelui, si e cea care da pragul.
	# [b]Si umbra se alege pe SATURATIE, nu dupa numele slotului.[/b] Prima
	# corectie a pus corpul pe SAND_SHADOW, care se numeste "nisip umbrit" si
	# pare alegerea evidenta. Pe captura a iesit o RAMA ROSIATICA in jurul
	# fiecarei deschideri, masurata rgb(97, 40, 6) — adica exact defectul din
	# memoria `rock-dark-nu-pe-bazalt`, pe alta piesa.
	#
	# Cauza, masurata pe paleta: SAND_SHADOW (#915D27) are saturatia 0.73. Nu e
	# o umbra, e un MARO SATURAT. Umbra unei pietre creme trebuie sa fie aceeasi
	# nuanta, doar mai inchisa si mai SPALATA — o suprafata la umbra pierde
	# saturatie, nu castiga:
	#   CORAL_SAND (peretele)  nuanta 41, saturatie 0.18, luminanta 221
	#   SAND_SHADOW            nuanta 31, saturatie 0.73, luminanta 100  <- rugina
	#   ASPHALT_EDGE           nuanta 30, saturatie 0.04, luminanta 103  <- umbra
	# ASPHALT_EDGE e la 11 grade de nuanta fata de perete, aproape nesaturat, si
	# la 47% din luminanta lui. Numele lui vine din alt rol, dar dala e exact ce
	# trebuie aici — memoria `slot-ales-dupa-nume` spune sa masori dala, nu sa
	# alegi eticheta. Slot deja folosit pe pista, deci zero materiale in plus.
	"hall_alcove": {
		2: Palette.CORAL_SAND,     # buza deschiderii: piatra taiata, la soare
		4: Palette.ASPHALT_EDGE,   # corpul firidei: umbra spalata, nu maro
		10: Palette.ASPHALT_EDGE,  # glaful: aceeasi umbra, nu al doilea ton
	},
	# Arcul de fereastra din peretele stancii goale. Aceeasi poveste ca la
	# coaja si la firide, a treia oara: piesa e desenata pentru sala subterana,
	# unde ruginiul citeste piatra la lumina de torta. Pe zidul crem al hornului
	# iesea o potcoava RUGINIE lipita pe perete - exact reprosul "rama
	# portocalie in jurul unei gauri", si exact capcana din memoria
	# `rock-dark-nu-pe-bazalt`.
	#
	# Masurat pe GLB (histograma de sloturi): 378 vertecsi pe slotul 2, 249 pe 4
	# (ROCK_DARK, maro), 96 pe 20 (VOLCANIC_BLACK) - deci ruginiul vine de pe 4
	# si 20, nu din lumina. Peretele pe care sta e tot pe 2 (SAND_SHADOW), deci
	# arcul se muta pe aceeasi familie. Zero sloturi noi, zero materiale noi.
	"church_arch": {
		# Valorile se dau dupa ADANCIME, masurata pe mesh (z mediu pe slot), nu
		# dupa ce culoare avea piesa in sala subterana. Prima incercare a pus 4 si
		# 20 pe doua valori diferite si arcul a iesit in DUNGI de bomboana:
		# bolzarii vecini cadeau alternativ pe crem si pe umbrit.
		#   slot  2  z +0.005  fata dinspre drum -> crem (nemutat, e deja bine)
		#   slot  4  z -0.241  cordonul/rama     -> crem, aceeasi valoare ca fata
		#   slot 23  z -0.733  glaful            -> umbrit: aici incepe adancimea
		#   slot 20  z -1.185  fundul            -> umbrit: partea cea mai retrasa
		#   slot 27  z -1.135  detaliul inchis   -> umbrit, tot in familia tufului
		4: Palette.CORAL_SAND,     # ROCK_DARK maro -> crem, ca fata arcului
		23: Palette.SAND_SHADOW,   # TILE_TERRACOTTA rosu -> tuf umbrit (glaful)
		20: Palette.SAND_SHADOW,   # VOLCANIC_BLACK -> acelasi umbrit (fundul)
		27: Palette.SAND_SHADOW,   # detaliul ruginit -> tot tuf umbrit
	},
}


## Repictare CONDITIONATA DE GEOMETRIE: muta pe alt slot triunghiurile care cad
## intr-o caseta din spatiul LOCAL al modelului, indiferent pe ce slot sunt.
##
## Exista fiindca `SLOT_REMAP_BY_MODEL` nu putea rezolva Land Rover-ul: pe
## `land_rover.glb` cele patru roti (masurate: 342 de triunghiuri in 4 grupuri
## la x ±0.87..1.21, y 0.00..0.82, z -2.20..-1.07 si +0.81..+1.63) stau pe
## ACELASI slot 4 ca sasiul si acoperisul, deci orice mutare de slot le-ar fi
## dus impreuna cu corpul. Verdictul rundei 4 spunea exact asta: „o cutie verde
## cu capac crem, fara roti care sa rupa linia solului, fara banda intunecata de
## parbriz". Geometria EXISTA (nu e capcana „parametrului care doar aduna"), doar
## culoarea o topea intr-o singura silueta.
##
## Fiecare regula e {"min": Vector3, "max": Vector3, "slot": int} in coordonate
## LOCALE, si se aplica pe CENTROIDUL triunghiului — o fata partial in caseta
## ramane intreaga pe slotul ei, deci nu apar dungi la marginea casetei.
## Vertecsii se DESPART inainte de scriere (fiecare triunghi isi primeste
## propriile UV-uri), altfel un vertex partajat intre roata si aripa ar fi tras
## si aripa in negru.
const SLOT_REPAINT_BY_BOX := {
	"land_rover": [
		# Cele 4 roti: tot ce e sub y 0.84 si mai in afara de x 0.84 —
		# adica anvelopa si janta, nu si podeaua sasiului dintre ele.
		{"min": Vector3(0.84, -0.05, -2.40), "max": Vector3(1.30, 0.84, 1.80),
			"slot": Palette.ICE_CRACK},
		{"min": Vector3(-1.30, -0.05, -2.40), "max": Vector3(-0.84, 0.84, 1.80),
			"slot": Palette.ICE_CRACK},
		# Banda de geam: chenarul de sus al cabinei, sub streasina (y 1.97) si
		# deasupra taliei (y 1.45), pe toata latimea corpului. Rupe caroseria
		# verde in doua valori pe verticala — cerinta 3 din verdict.
		{"min": Vector3(-1.05, 1.45, -2.30), "max": Vector3(1.05, 1.94, 2.30),
			"slot": Palette.SEA_DEEP},
	],
}


func _ready() -> void:
	# `_remap_model_slots` cere `_ancestor_theme()`, iar Godot cheama _ready()
	# BOTTOM-UP: DecorManual (acest nod) e copil direct al Track/TrackFromPath,
	# deci ruleaza INAINTEA lui Track._ready() -> TrackFromPath._apply_custom()
	# -> apply_theme(custom_theme). La acel moment theme_decor e inca implicitul
	# "forest", nu tema reala a pistei (ex. "fiordland") — SLOT_REMAP_BY_THEME
	# nu se aplica NICIODATA la runtime, desi codul e corect si testele izolate
	# (instantiere manuala + await process_frame) confirma tema corecta o clipa
	# mai tarziu. Descoperit runda 4 POI B Fiordland: moss_boulder_a/b/c si
	# chasm_rock ies MARBLE_GREY (gri deschis) in captura reala din joc, desi
	# fixurile anterioare (a4491e4d, 0f83d9aa) pareau sa treaca gardile — gardile
	# nu verifica CULOAREA randata, doar numarul de materiale. `call_deferred`
	# muta remaparea dupa ce tot lantul de _ready() (inclusiv al parintelui) s-a
	# terminat, cand `theme_decor` e deja cel real. Restul functiilor de mai jos
	# NU depind de tema, raman sincrone. `_apply_theme_classes` (runda 5 POI B:
	# `CLASSES_BY_THEME`, `chasm_rock` -> `wet_gneiss` doar pe fiordland) are
	# aceeasi dependenta de `_ancestor_theme()` si aceeasi problema, deci merge
	# deferred langa `_remap_model_slots`.
	#
	# `_split_theme_accents` (lotul STANCA UDA, Fiordland) e ruptura de accente
	# ECHIVALENTA lui `_split_shutters`, dar SCOPATA PE TEMA in loc de global:
	# `moss_boulder_b` are nevoie de ruptura DOAR pe fiordland (corpul remapat
	# de `_remap_model_slots` pe slotul 20 -> `wet_gneiss`), nu si pe Machu
	# Picchu, unde acelasi .glb ramane intreg pe `inca_stone`
	# (`_model_flock`). De aceea NU intra in `SPLIT_MODELS`/`ACCENT_SPLIT`
	# (globale) ci in `SPLIT_MODELS_BY_THEME`/`ACCENT_SPLIT_BY_THEME`.
	# Deferred, ca sa ruleze DUPA `_remap_model_slots` (citeste sloturile deja
	# mutate: corp pe 20, nu pe sloturile brute 3/29 din .glb) si INAINTE de
	# `_apply_theme_classes` (nodul `_Accente` trebuie sa existe cand se pune
	# clasa pe corp, la fel ca la `_split_shutters`/`apply_class_materials`).
	# Godot executa `call_deferred` in ordinea in care au fost puse in coada.
	call_deferred("_remap_model_slots")
	call_deferred("_split_theme_accents")
	call_deferred("_apply_theme_classes")
	_repaint_slot_boxes()
	_split_shutters()
	_retint_tuff()
	_warm_tuff()
	_strata_tuff()
	_redden_cliff()
	_cool_inca_cliff()
	Palette.apply_class_materials(self, prop_classes())
	_apply_model_classes()
	_apply_lime_indigo()
	_fade_tuff_detail()
	_apply_tint()
	_apply_glow()
	_apply_no_shadow()
	if not Engine.is_editor_hint():
		_hide_degenerate()
	if auto_collision and not Engine.is_editor_hint():
		_build_collision()


## Piesele cu baza DEGENERATA (determinant ~0, o scara pe o axa = 0) se ascund
## si se numesc in log (#530).
##
## Pe desktop o asemenea piesa nu se deseneaza deloc, deci nimeni nu vede ca e
## stricata; pe rendererul Mobile insa iese ca o placa turtita, cu textura
## intinsa in dungi. Asa au stat 6 saptamani cele 101 module ale zidului Vaii
## Rosii pe Cappadocia: invizibile la dezvoltare, placi portocalii pe telefon.
## Ascunderea face desktopul si telefonul sa arate la fel; avertismentul face
## ca urmatoarea scena stricata sa nu mai treaca in tacere.
func _hide_degenerate() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		if absf(model.global_transform.basis.determinant()) < 1e-6:
			model.visible = false
			push_warning("world_prop: %s are baza degenerata (det ~0) — ascunsa"
				% get_path_to(model))
## Stinge umbra pe modelele din `NO_SHADOW_MODELS` (orizontul asezat de mana).
## Ruleaza DUPA rupturi (`_split_shutters`), ca sa prinda si copiii `_Accente`.
func _apply_no_shadow() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		if not NO_SHADOW_MODELS.has(stem):
			continue
		for node in Palette._walk(model):
			if node is GeometryInstance3D:
				(node as GeometryInstance3D).cast_shadow = \
					GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Muta vertecsii unui model de pe un slot de atlas pe altul (vezi
## [constant SLOT_REMAP_BY_MODEL]).
##
## Mesh-ul se DUPLICA inainte de scriere: resursa importata din .glb e partajata
## intre toate instantele modelului si e tinuta in cache de ResourceLoader, deci
## o scriere pe loc ar schimba piesa pentru toata lumea si ar reaplica mutarea
## la fiecare instanta noua (crem -> si mai crem), inclusiv pe alte piste.
func _remap_model_slots() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	var _theme_cache := _ancestor_theme()
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		var group := _group_of(model)
		var remap: Dictionary
		if SLOT_REMAP_BY_GROUP.has(group) and (SLOT_REMAP_BY_GROUP[group] as Dictionary).has(stem):
			remap = SLOT_REMAP_BY_GROUP[group][stem]
		elif SLOT_REMAP_BY_THEME.has(_theme_cache) and (SLOT_REMAP_BY_THEME[_theme_cache] as Dictionary).has(stem):
			remap = SLOT_REMAP_BY_THEME[_theme_cache][stem]
		elif SLOT_REMAP_BY_MODEL.has(stem):
			remap = SLOT_REMAP_BY_MODEL[stem]
		else:
			continue
		if remap.is_empty():
			continue
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			mi.mesh = _mesh_with_slots_moved(mi.mesh, remap)
	_dim_model_vertex_colors()


## Cat de mult se INTUNECA vertecsii unui model, per stem (1.0 = neatins).
##
## De ce exista. Coroanele acaciilor stau pe slotul 12 (CACTUS_GREEN #5B7C34),
## ales in rundele trecute pentru NUANTA lui — si masuratoarea confirma alegerea:
## slotul are H 87 / S 0.58, iar coroana din referinta H 75 / S 0.55. Ce nu se
## potriveste e VALOAREA. Masurat pe cadrul de joc (--frac=0.06 --gamecam), pe
## toti pixelii verzi: coroanele noastre ies RGB(102,128,20) V 0.53 pe 9,8 % din
## cadru, referinta le are RGB(58,67,30) V 0.27 pe 2,0 %. Sub soare cald plus
## expunere 1.10 orice slot verde se ridica, si nu exista slot mai inchis cu
## aceeasi nuanta: 21 e verde de brocoli, 5/20 sunt griuri reci.
##
## De ce vertex color si nu o clasa proprie de frunzis: e clampata la [0,1] si
## se inmulteste peste albedo (memoria `surfacetool-clamp-vertex-color`), deci
## poate DOAR sa intunece — singurul sens de care avem nevoie. Costa zero
## materiale (acelasi `world_material` partajat, garda ramane la 12/38) si
## pastreaza variatia de AO deja coapta in vertecsi, fiindca inmulteste in loc
## sa inlocuiasca. O clasa proprie ar costa un material pentru o singura
## diferenta de luminanta.
##
## Factorul e DERIVAT, nu ales: 0.27 / 0.53 = 0.51 din valoarea randata, iar
## masuratoarea A/B pe captura (0.62 -> V 0.43, 0.38 -> V 0.33) confirma
## proportionalitatea. 0.44 pune coroana pe V 0.28.
const VERTEX_DIM_BY_MODEL := {
	"acacia_umbrella_a": 0.44,
	"acacia_umbrella_b": 0.44,
	"acacia_umbrella_c": 0.44,
}


## Inmulteste culorile de vertex ale modelelor din VERTEX_DIM_BY_MODEL.
##
## Ruleaza DUPA `_remap_model_slots`, pe mesh-ul deja duplicat de acolo cand
## modelul are si remap — altfel ar scrie in resursa partajata din cache si ar
## intuneca piesa pentru toate instantele si toate pistele (aceeasi capcana
## explicata la `_remap_model_slots`). Pentru modelele fara remap duplica el.
func _dim_model_vertex_colors() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		if not VERTEX_DIM_BY_MODEL.has(stem):
			continue
		var f := float(VERTEX_DIM_BY_MODEL[stem])
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			mi.mesh = _mesh_with_colors_dimmed(mi.mesh, f)


## Copia unui mesh cu culorile de vertex inmultite cu `f`.
##
## Daca mesh-ul n-are deloc culori de vertex (cazul obisnuit pentru un GLB de
## kit), se SCRIE un canal plin cu `f` — altfel intunecarea n-ar avea pe ce sa
## se aplice. Alpha ramane 1.
static func _mesh_with_colors_dimmed(src: Mesh, f: float) -> Mesh:
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := MeshCpu.surface_arrays(src, s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		if cols.is_empty():
			cols = PackedColorArray()
			cols.resize(verts.size())
			for i in cols.size():
				cols[i] = Color(f, f, f, 1.0)
		else:
			for i in cols.size():
				var c := cols[i]
				cols[i] = Color(c.r * f, c.g * f, c.b * f, c.a)
		arr[Mesh.ARRAY_COLOR] = cols
		MeshCpu.add_surface(out, arr)
		var m := src.surface_get_material(s)
		if m != null:
			out.surface_set_material(s, m)
	return out


## Numele grupului de decor manual (copilul direct al acestui nod) in care sta
## `node`; "" daca nodul e chiar copil direct sau in afara arborelui.
func _group_of(node: Node) -> String:
	var n := node
	while n != null and n.get_parent() != self:
		n = n.get_parent()
	return String(n.name) if n != null and n != self else ""


## Cheia de tema a pistei-stramos (`Track.theme_decor`, ex. "fiordland",
## "machupicchu"), urcand in ierarhie ca la `FlockProp._find_sampler`.
##
## De ce exista: `SLOT_REMAP_BY_GROUP` scopeaza pe numele grupului de decor
## manual (copilul direct din .tscn), dar acela apartine constructorilor de
## POI-uri si pe Fiordland zonele sunt inca goale la ora asta. O reparatie pe
## PISTA (nu pe model, ca sa nu atinga Machu Picchu, care refoloseste acelasi
## `moss_boulder_*.glb`) are nevoie de o cheie care exista INAINTE ca vreun
## POI sa fie construit: tema pistei. "" daca WorldProp nu e sub un Track (ex.
## piesa de vitrina printr-un holder in afara pistei — desi `--vitrina` chiar
## adauga holderul ca frate cu Track, deci si acolo se gaseste).
func _ancestor_theme() -> String:
	var cur: Node = get_parent()
	while cur != null:
		if cur is Track:
			return String((cur as Track).theme_decor)
		cur = cur.get_parent()
	# FALLBACK: in decorul real (.tscn), WorldProp e mereu descendentul unui
	# Track, deci bucla de mai sus il gaseste din primul pas si linia de mai
	# jos nu se atinge niciodata. Exceptia e harnasul de test: `--vitrina`
	# (tools/snapshot.gd, `_place_vitrina`) adauga holderul CA FRATE al pistei
	# (amandoi copii ai radacinii scriptului de captura), nu ca descendent —
	# deci urcarea in ierarhie de mai sus nu ajunge niciodata la Track, si o
	# reparatie scopeaza-pe-tema testata prin --vitrina ar parea moarta desi
	# codul de productie merge. Cauta deci un Track oriunde in arbore, ca sa
	# nu depinda de cum isi construieste harnasul scena.
	if is_inside_tree():
		var root := get_tree().root
		var stack: Array[Node] = [root]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is Track:
				return String((n as Track).theme_decor)
			for c in n.get_children():
				stack.append(c)
	return ""


## Copia unui mesh cu UV-urile mutate pe alte sloturi de atlas.
static func _mesh_with_slots_moved(src: Mesh, remap: Dictionary) -> Mesh:
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := MeshCpu.surface_arrays(src, s)
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		if not uv.is_empty():
			for i in uv.size():
				var slot := int(floor(uv[i].x * float(Palette.SLOTS)))
				if remap.has(slot):
					# Centrul slotului tinta: la margine s-ar lua jumatate din
					# culoarea vecinului la prima filtrare bilineara.
					uv[i].x = (float(int(remap[slot])) + 0.5) / float(Palette.SLOTS)
			arr[Mesh.ARRAY_TEX_UV] = uv
		MeshCpu.add_surface(out, arr)
		var m := src.surface_get_material(s)
		if m != null:
			out.surface_set_material(s, m)
	return out


## Aplica [constant SLOT_REPAINT_BY_BOX] pe modelele din arbore.
func _repaint_slot_boxes() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		if not SLOT_REPAINT_BY_BOX.has(stem):
			continue
		var rules: Array = SLOT_REPAINT_BY_BOX[stem]
		if rules.is_empty():
			continue
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			mi.mesh = _mesh_with_boxes_repainted(mi.mesh, rules)


## Copia unui mesh cu triunghiurile din casetele `rules` mutate pe alt slot.
## Mesh-ul se duplica (ca la `_mesh_with_slots_moved`): resursa .glb e partajata
## intre toate instantele si tinuta in cache de ResourceLoader.
static func _mesh_with_boxes_repainted(src: Mesh, rules: Array) -> Mesh:
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := MeshCpu.surface_arrays(src, s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if verts.is_empty() or uv.is_empty() or idx.is_empty():
			MeshCpu.add_surface(out, arr)
			var m0 := src.surface_get_material(s)
			if m0 != null:
				out.surface_set_material(s, m0)
			continue
		var normals: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] 			if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var colors: PackedColorArray = arr[Mesh.ARRAY_COLOR] 			if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		# Desparte vertecsii pe triunghi: un vertex partajat intre roata si
		# aripa ar duce culoarea rotii si pe aripa.
		var nv := PackedVector3Array()
		var nn := PackedVector3Array()
		var nu := PackedVector2Array()
		var nc := PackedColorArray()
		var ni := PackedInt32Array()
		var tri_count := idx.size() / 3
		for t in tri_count:
			var a := idx[t * 3]
			var b := idx[t * 3 + 1]
			var c := idx[t * 3 + 2]
			var centroid := (verts[a] + verts[b] + verts[c]) / 3.0
			var target := -1
			for r: Dictionary in rules:
				var lo: Vector3 = r["min"]
				var hi: Vector3 = r["max"]
				if centroid.x >= lo.x and centroid.x <= hi.x 						and centroid.y >= lo.y and centroid.y <= hi.y 						and centroid.z >= lo.z and centroid.z <= hi.z:
					target = int(r["slot"])
					break
			for k in [a, b, c]:
				ni.append(nv.size())
				nv.append(verts[k])
				if not normals.is_empty():
					nn.append(normals[k])
				if not colors.is_empty():
					nc.append(colors[k])
				nu.append(Palette.uv(target) if target >= 0 else uv[k])
		var na := []
		na.resize(Mesh.ARRAY_MAX)
		na[Mesh.ARRAY_VERTEX] = nv
		na[Mesh.ARRAY_TEX_UV] = nu
		na[Mesh.ARRAY_INDEX] = ni
		if not nn.is_empty():
			na[Mesh.ARRAY_NORMAL] = nn
		if not nc.is_empty():
			na[Mesh.ARRAY_COLOR] = nc
		MeshCpu.add_surface(out, na)
		var m := src.surface_get_material(s)
		if m != null:
			out.surface_set_material(s, m)
	return out


## Rupe accentele pictate de pe partile din ACCENT_SPLIT, ca ele sa poata primi
## o clasa fara sa piarda culoarea. Trebuie sa ruleze INAINTE de
## `apply_class_materials`: nodul nou trebuie sa existe cand se impart
## materialele, altfel ar ramane fara.
func _split_shutters() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		# Pe MODEL, nu pe tot arborele: `Church_Body` exista si la biserica
		# siberiana din Khuzhir, care n-are obloane de rupt. Ruptura acolo era
		# inofensiva vizual, dar adauga un nod si un desen pe o pista pe care
		# task-ul asta n-are ce cauta — iar diferentele „inofensive" fata de
		# `main` sunt exact cele care se acumuleaza netestate.
		var stem := model.scene_file_path.get_file().get_basename()
		if not SPLIT_MODELS.has(stem):
			continue
		# Valoarea poate fi `true` (peste tot) sau o lista de GRUPURI de decor
		# manual in care ruptura are voie sa se faca — vezi nota de la
		# `church_arch` in SPLIT_MODELS.
		var where: Variant = SPLIT_MODELS[stem]
		if where is Array and not (where as Array).has(_group_of(model)):
			continue
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null:
				continue
			for prefix: String in ACCENT_SPLIT:
				if String(mi.name).begins_with(prefix):
					Palette.split_accents(mi, ACCENT_SPLIT[prefix])
					break


## Ca [method _split_shutters], dar scopat pe TEMA in loc de global — vezi
## [constant SPLIT_MODELS_BY_THEME] pentru motiv (`moss_boulder_b`, reuse pe
## Machu Picchu, nu trebuie sa se rupa acolo).
##
## `call_deferred` din `_ready()`, DUPA `_remap_model_slots` (citeste sloturile
## deja mutate de tema) si INAINTE de `_apply_theme_classes` (nodul `_Accente`
## trebuie sa existe cand se pune clasa pe corp) — vezi comentariul din
## `_ready()`.
func _split_theme_accents() -> void:
	var theme := _ancestor_theme()
	if not SPLIT_MODELS_BY_THEME.has(theme):
		return
	var split_models: Dictionary = SPLIT_MODELS_BY_THEME[theme]
	var accent_split: Dictionary = ACCENT_SPLIT_BY_THEME.get(theme, {})
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		if not split_models.has(stem):
			continue
		var where: Variant = split_models[stem]
		if where is Array and not (where as Array).has(_group_of(model)):
			continue
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null:
				continue
			for prefix: String in accent_split:
				if String(mi.name).begins_with(prefix):
					Palette.split_accents(mi, accent_split[prefix])
					break


## Aplica `CLASSES_BY_MODEL` peste materialele deja puse. Ruleaza DUPA
## `apply_class_materials`, ca sa aiba ultimul cuvant pe partile ambigue.
func _apply_model_classes() -> void:
	_apply_classes_mapping(CLASSES_BY_MODEL)
	_apply_meta_class()


## Clasa triplanara ceruta de INSTANTA, nu de model: metadata `clasa_triplanara` =
## "mv_sandstone" pe instanta sau pe un container (se mosteneste in jos), ca la
## `racire`/`lumina`. Exista fiindca `CLASSES_BY_MODEL` e pe fisier-model, deci
## global: un `butte.glb` imbracat acolo ar schimba si Dunele. Aici turnurile
## Mittens (Track19) isi iau gresia fara sa atinga nicio alta pista. Fara
## metadata nu se intampla nimic (bit-identic).
const CLASS_META := "clasa_triplanara"

func _apply_meta_class() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var cls := ""
		var p: Node = model
		while p != null and p != self.get_parent():
			if p.has_meta(CLASS_META):
				cls = String(p.get_meta(CLASS_META))
				break
			p = p.get_parent()
		if not cls.is_empty():
			Palette.apply_triplanar_class(model, cls)


## Metadata care muta varul unei case albastre (Jodhpur) de pe tenta deschisa
## (`blue_lime_light`, implicita din CLASSES_BY_MODEL) pe INDIGO
## (`blue_lime_indigo`). In Inspector: Add Metadata -> `indigo` = true, pe
## instanta casei SAU pe un container (zona) — se mosteneste in jos.
##
## De ce metadata si nu o mapare pe model: aceeasi casa (acelasi .glb) apare in
## ambele tente, amestecate casa cu casa (brief §0.1: „doua tente, nu una").
## Costul e +1 material pe pista (clasa indigo), oricate case ar purta-o.
## Umplutura din interiorul buclei (`CityFill`) foloseste aceeasi metadata pe
## sabloanele ei, deci amestecul se decide intr-un singur loc.
const LIME_INDIGO_META := "indigo"
const LIME_LIGHT := "blue_lime_light"
const LIME_INDIGO := "blue_lime_indigo"


func _apply_lime_indigo() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		if not _wants_indigo(model):
			continue
		var stem := model.scene_file_path.get_file().get_basename()
		var mapping: Dictionary = CLASSES_BY_MODEL.get(stem, {})
		var parts: Array[String] = []
		for part: String in mapping:
			if String(mapping[part]) == Palette.TRI_PREFIX + LIME_LIGHT:
				parts.append(part)
		if parts.is_empty():
			continue
		var mat := Palette.triplanar_class_material(LIME_INDIGO)
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or String(mi.name).ends_with(Palette.ACCENT_SUFFIX):
				continue
			for part in parts:
				if String(mi.name).begins_with(part):
					mi.material_override = mat
					break


func _wants_indigo(model: Node) -> bool:
	var n: Node = model
	while n != null and n != self:
		if n.has_meta(LIME_INDIGO_META):
			return bool(n.get_meta(LIME_INDIGO_META))
		n = n.get_parent()
	return false


## Ca [method _apply_model_classes], dar din [constant CLASSES_BY_THEME],
## scopat pe tema pistei-stramos. `call_deferred` din `_ready()`, la fel ca
## `_remap_model_slots` si pentru acelasi motiv: `_ancestor_theme()` e citit
## BOTTOM-UP, inainte ca `Track._ready()` sa fi aplicat `custom_theme` — sincron
## aici, `chasm_rock` n-ar primi niciodata `wet_gneiss` pe fiordland (tema ar
## fi inca implicitul "forest", pentru care `CLASSES_BY_THEME` n-are intrare).
func _apply_theme_classes() -> void:
	var theme := _ancestor_theme()
	if not CLASSES_BY_THEME.has(theme):
		return
	_apply_classes_mapping(CLASSES_BY_THEME[theme])


## Motorul comun: aplica o mapare stem -> (nume-de-parte -> clasa) pe modelele
## din subtree. NU `apply_class_materials`: ala pune materialul lumii pe tot ce
## nu e in mapare, deci ar sterge clasele deja aplicate pe celelalte parti
## (`Church_Tower` tocmai primise varul). Aici se ating DOAR partile numite.
func _apply_classes_mapping(by_stem: Dictionary) -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		if not by_stem.has(stem):
			continue
		var mapping: Dictionary = by_stem[stem]
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null:
				continue
			var nm := String(mi.name)
			# Prefixul cel mai LUNG castiga, ca in `Palette._class_for`, si nu
			# e un detaliu de stil: `ShophouseA_Accente` incepe si cu
			# `ShophouseA`, deci cu prima potrivire din dictionar rezultatul ar
			# fi depins de ordinea cheilor — o mapare corecta ar fi devenit
			# gresita la o reordonare inocenta.
			var cls := ""
			var matched := false
			var best := -1
			for part: String in mapping:
				if nm.begins_with(part) and part.length() > best:
					best = part.length()
					cls = String(mapping[part])
					matched = true
			# `cls` poate fi gol prin constructie DOAR daca nimic nu s-a
			# potrivit — un prefix care se potriveste dar are valoarea
			# `ATLAS_PREFIX` nu e gol, deci trece mai departe si forteaza
			# materialul lumii (vezi nota de la `ATLAS_PREFIX`).
			if not matched:
				continue
			# Nodurile de accente exista tocmai ca sa RAMANA pe atlas, deci o
			# clasa de suprafata nu are ce cauta pe ele PRIN LACOMIA UNUI
			# PREFIX. LUMINA insa da: pe fatadele Chongqing accentele SUNT
			# partea care arde, si dupa ruptura sunt singurul nod care mai
			# poarta slotul 30.
			#
			# Regula de aici nu e „accentele n-au voie sa aiba clasa", e „nu
			# mostenesc clasa corpului": pe `ShophouseA_Accente` prefixul
			# `ShophouseA` se potriveste, deci fara garda acoperisul ar fi luat
			# betonul fatadei. Cand maparea NUMESTE accentul pe numele lui
			# intreg, alegerea e explicita si se respecta — asa ia
			# `Church_Arch_Accente` clasa `fresco`, care e chiar motivul
			# pentru care s-a facut ruptura pe arcada.
			var is_accent := nm.ends_with(Palette.ACCENT_SUFFIX)
			if is_accent and not cls.begins_with(Palette.GLOW_PREFIX) 					and not mapping.has(nm):
				continue
			mi.material_override = _model_class_material(cls)
			if Palette.is_smooth_foliage(cls):
				mi.mesh = Palette.smoothed_mesh(mi.mesh)


## Materialul unei clase din `CLASSES_BY_MODEL`, dupa prefix.
##
## Pana in august 2026 aici era un apel direct la `triplanar_class_material`:
## maparea avea un singur client (varul bisericii) si toate valorile ei erau
## "tri:". Al doilea client — ferestrele aprinse ale Chongqing-ului — e "glow:",
## iar cu apelul vechi ar fi primit tacut o textura triplanara pe o clasa
## inexistenta. Prefixele sunt aceleasi ca in `apply_class_materials`, ca o
## mapare sa insemne acelasi lucru indiferent pe unde intra.
func _model_class_material(cls: String) -> Material:
	if cls == Palette.ATLAS_PREFIX:
		return Palette.world_material()
	if cls == Palette.PLAIN_PREFIX:
		return Palette.plain_material()
	if cls.begins_with(Palette.GLOW_PREFIX):
		return Palette._glow_from_spec(cls.trim_prefix(Palette.GLOW_PREFIX))
	if cls.begins_with(Palette.FINISH_PREFIX):
		return Palette.finish_material(cls.trim_prefix(Palette.FINISH_PREFIX))
	# "shader:" (azi doar ferestrele Jodhpur, `jod_window`): fara ramura asta
	# ar fi cazut tacut pe o clasa triplanara inexistenta, ca "glow:" inainte.
	if cls.begins_with(Palette.SHADER_PREFIX):
		return Palette.shader_material(cls.trim_prefix(Palette.SHADER_PREFIX))
	if cls.begins_with(Palette.ATINT_PREFIX):
		return Palette.atlas_tint_material(cls.trim_prefix(Palette.ATINT_PREFIX))
	return Palette.triplanar_class_material(
		cls.trim_prefix(Palette.TRI_PREFIX))


## Numele metadatei prin care o INSTANTA capata LUMINA: sloturile din paleta
## care ard, si cat de tare. In Inspector: Add Metadata -> `lumina`, valoare
## `"30"` (un slot), `"30|2.2"` (slot + energie) sau `"28,30|1.6"` (mai multe
## sloturi cu aceeasi energie).
##
## Mai multe sloturi, fiindca "cladire luminata din interior" rareori sta
## intr-unul singur: pe `hongya_dong.glb` aurul (30) e 0.8% din arie, iar
## corpul de lemn (28) e 61% — aprins doar 30, hero-ul ramane o silueta
## neagra.
##
## De ce metadata si nu o mapare per model, ca la `CLASSES_BY_MODEL`: aceeasi
## piesa se foloseste si aprinsa si stinsa. Pe Chongqing, `hongya_dong.glb`
## agatat sub cornisa ARDE auriu (e hero-ul vizual, brief §2 POI D), dar
## siluetele aceluiasi kit de peste rau nu trebuie sa arda — daca ar arde, ar
## trage ochiul de pe hero fix acolo unde ceata trebuie sa le stinga.
##
## Costul e UN material per (slot, energie), partajat de toate instantele care
## cer aceeasi combinatie: `Palette.glow_material` le tine intr-un cache. Un
## cartier intreg de case aurii aduce +1 la garda, nu +40.
const GLOW_META := "lumina"


## Numele metadatei prin care o instanta (sau un container de zona intreg)
## primeste LUMINA RECE DE UMPLERE pe sloturile ei de piatra. In Inspector:
## Add Metadata -> `racire`, valoare `"2,4|0.55|#39445C"` — aceeasi gramatica
## ca `lumina` (sloturi | energie | nuanta).
##
## Exista pentru piatra din subteran. Piesele salii stau pe sloturile 2 si 4,
## amandoua brunuri calde saturate, deci sala avea o singura croma de la cauciuc
## pana in tavan si cele 16 torte se citeau ca un singur jar. De ce lumina
## ADITIVA si nu o tenta pe albedo (si de ce corectia de ambient a rundei trecute
## n-a schimbat nimic): aritmetica e in antetul lui `Palette.cool_fill_material`
## — pe scurt, tot ce inmulteste pastreaza saturatia brunului, doar adunarea
## ridica podeaua canalelor mici.
##
## E per ZONA, nu per piesa: se pune o data pe `F2_Sala1` si coboara pe tot ce e
## sub el, exact ca `lumina`.
##
## Nu se confunda cu `lumina`: aia aprinde o piesa care ARDE (torta, fereastra),
## asta e umplerea difuza a incaperii. Cand o piesa cere si una si alta, lumina
## are ultimul cuvant — vezi ordinea din `_ready`.
const TINT_META := "racire"


## Pune lumina rece de umplere pe instantele care cer `racire`.
##
## Ruleaza DUPA clase si INAINTE de `_apply_glow`: o torta care si arde si sta
## intr-o zona racita trebuie sa ramana aprinsa, deci lumina are ultimul cuvant.
func _apply_tint() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var spec := _tint_spec(model)
		if spec.is_empty():
			continue
		var parts := spec.split("|", false)
		var slots: Array = []
		for token in parts[0].split(",", false):
			slots.append(int(token))
		var energy := float(parts[1]) if parts.size() > 1 else 0.55
		var tint := Color.html(String(parts[2]).strip_edges()) \
			if parts.size() > 2 else Color.html("39445C")
		# Racirea sare peste partea care poarta o clasa, exact ca lumina de mai
		# jos: `apply_cool_fill` scria pana acum pe TOT subarborele, deci pe o
		# piesa rupta ar fi sters clasa fara sa se vada nicaieri.
		var skip := ""
		if ACCENT_HOLDS_CLASS.has(model.scene_file_path.get_file().get_basename()):
			skip = Palette.ACCENT_SUFFIX
		Palette.apply_cool_fill(model, slots, tint, energy, skip)


## Racirea unei instante: metadata pe model, altfel pe containerul de zona — asa o
## sala intreaga se raceste dintr-un singur loc. Acelasi tipar ca `_glow_spec`.
func _tint_spec(model: Node3D) -> String:
	if model.has_meta(TINT_META):
		return String(model.get_meta(TINT_META))
	var p: Node = model.get_parent()
	while p != null and p != self.get_parent():
		if p.has_meta(TINT_META):
			return String(p.get_meta(TINT_META))
		p = p.get_parent()
	return ""


## Pune materialul emisiv pe instantele care cer `lumina`.
##
## Ruleaza DUPA `_apply_model_classes`, ca sa aiba ultimul cuvant: o piesa care
## si arde si are o clasa triplanara ar ramane altfel cu clasa, adica stinsa.
func _apply_glow() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var spec := _glow_spec(model)
		if spec.is_empty():
			continue
		var parts := spec.split("|", false)
		var slots: Array = []
		for token in parts[0].split(",", false):
			slots.append(int(token))
		var energy := float(parts[1]) if parts.size() > 1 else 1.2
		# Al treilea camp, optional, e CULOAREA luminii (`#RRGGBB`). Fara el,
		# fiecare slot arde in propria culoare — bun pentru jar. Cu el, masca
		# ramane aceeasi dar lumina are o singura nuanta: vezi
		# `Palette._slots_glow_texture`, unde scrie de ce lemnul lui Hongya
		# Dong nu se poate lumina cu propria lui culoare.
		var tint := Color.BLACK
		var multiply := false
		if parts.size() > 2:
			var t := String(parts[2]).strip_edges()
			# un `*` la coada cere operatorul MULTIPLY: pastreaza relieful
			# (albedo + AO) si doar il incalzeste. Vezi Palette.
			if t.ends_with("*"):
				multiply = true
				t = t.substr(0, t.length() - 1)
			tint = Color.html(t)
		var mat := Palette.glow_material_slots(slots, energy, tint, multiply)
		# Modelele RUPTE de `_split_shutters` isi impart rolurile: corpul
		# pastreaza clasa primita mai devreme (betonul fatadei), iar copilul
		# `_Accente` — care tine acoperisul si firmele de pe slotul 30 — ia
		# emisia. Fara distinctia asta lumina ar cadea si pe corp, adica
		# exact peste clasa, si fatadele Chongqing ar fi ramas la fel de plate.
		#
		# Pe modelele NErupte nu se schimba nimic: `split` e fals, deci lumina
		# cade pe tot arborele ca pana acum.
		var stem_g := model.scene_file_path.get_file().get_basename()
		var split: bool = SPLIT_MODELS.has(stem_g)
		var inverted: bool = ACCENT_HOLDS_CLASS.has(stem_g)
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null:
				continue
			# Pe modelele rupte lumina cade pe O SINGURA parte, si care anume
			# depinde de cine poarta clasa: la fatadele Chongqing accentul arde
			# si corpul are betonul, la arcada de biserica accentul are frescele
			# si corpul e piatra pe care bate torta (`ACCENT_HOLDS_CLASS`).
			var is_acc := String(mi.name).ends_with(Palette.ACCENT_SUFFIX)
			if split and is_acc == inverted:
				continue
			mi.material_override = mat


## Specificatia de lumina a unei instante: metadata pe model, altfel pe
## containerul de zona (asa un cartier intreg se aprinde dintr-un singur loc).
func _glow_spec(model: Node3D) -> String:
	if model.has_meta(GLOW_META):
		return String(model.get_meta(GLOW_META))
	var p: Node = model.get_parent()
	while p != null and p != self.get_parent():
		if p.has_meta(GLOW_META):
			return String(p.get_meta(GLOW_META))
		p = p.get_parent()
	return ""


## Parti de mesh fara hull, per MODEL (stem .glb). Fantele de tragere ale
## fortului Jodhpur sunt placi subtiri inauntrul hull-ului pietrei; Jolt le
## respingea hull-ul la unele rotatii (`zid82_col`, 30 sep 2026). Vezi
## `TrackDecor.add_hull_collision`.
const HULL_SKIP_PARTS := {
	"fort_wall_segment": ["Wall_Glow"],
	"fort_wall_turret": ["Turret_Glow"],
	# Monument Valley: la monolitii mari fusta de grohotis si calota nu au corp
	# fizic propriu — fusta e deja terenul `TerrainPeak` de dedesubt (un colizor
	# pe ea ar schimba traseul bolovanilor care se rostogolesc pe teren), iar
	# calota e o placa subtire sus. Lista e citita si de `_add_trimesh` (Mittens
	# sunt `mesh`). Piesele mici (butte_small_*, hoodoo, fin) isi pastreaza fusta:
	# conul lor E sprijinul lor, nu exista teren sub el.
	"west_mitten": ["Mitten_Scree", "Mitten_Cap"],
	"east_mitten": ["EastMitten_Scree", "EastMitten_Cap"],
	"merrick_butte": ["Butte_Scree", "Butte_Cap"],
	# Okinawa. Portile si arcurile sunt `mesh` (citit tot de `_add_trimesh`).
	# Poarta: acoperisul/mortarul/aurul stau la >= 6,8 m peste drum, deasupra oricarei
	# masini; stalpii si soclurile sunt corpul. Arcul: canatul de lemn e decor.
	"ryukyu_gate": ["Gate_Roof", "Gate_Mortar", "Gate_Gold"],
	"gusuku_arch_gate": ["Arch_Wood"],
	"notch_rock_a": ["Notch_Grass"], "notch_rock_b": ["Notch_Grass"],
	"notch_rock_c": ["Notch_Grass"],
	"limestone_cliff_module": ["Cliff_Grass"], "limestone_cliff_module_b": ["Cliff_Grass"],
	# Cladiri: hull doar pe corp (pereti, curte, platforma). Acoperisul (streasina
	# iese 1-1,5 m), mortarul, aurul, shisa, lemnaria prispei si scarile nu sunt
	# obstacole: hull pe ele ar umple prispa si ar lipi un perete in aer sub streasina.
	"ryukyu_palace": ["Palace_Roof", "Palace_Mortar", "Palace_Gold"],
	"ryukyu_house_a": ["House_Roof", "House_Mortar", "House_Shisa", "House_Wood"],
	"ryukyu_house_b": ["House_Roof", "House_Mortar", "House_Shisa", "House_Wood"],
	"ryukyu_house_c": ["House_Roof", "House_Mortar", "House_Shisa", "House_Wood"],
	"concrete_house_a": ["Concrete_Wood"], "concrete_house_b": ["Concrete_Wood"],
	"harbour_quay": ["Quay_Rubber"],
	"bus_stop_shelter": ["Shelter_Concrete", "Shelter_Mortar"],
	# Kyoto: casele de oras au hull doar pe miezul de lemn (peretii). Acoperisul
	# (streasina iese 1,1 m dincolo de perete), zabrelele din fata (pana la 0,9 m
	# in strada), norenul si jaluzelele nu sunt obstacole: un hull pe ele ar
	# fi un bloc mai lat decat casa, la inaltimea capotei in dreptul streasinii
	# intermediare.
	"machiya_a": ["Machiya_Roof", "Machiya_Trim", "Machiya_Plaster",
		"Machiya_Noren"],
	"machiya_b": ["Machiya_Roof", "Machiya_Trim", "Machiya_Plaster",
		"Machiya_Noren"],
	"machiya_c": ["Machiya_Roof", "Machiya_Trim", "Machiya_Plaster"],
	"machiya_d": ["Machiya_Roof", "Machiya_Trim", "Machiya_Plaster",
		"Machiya_Bamboo"],
	"machiya_e": ["Machiya_Roof", "Machiya_Trim", "Machiya_Plaster"],
	# Transfagarasan (kitul din assets/models/transfagarasan/): captuselile negre ale
	# gurilor sunt vizuale. Portalurile sunt `mesh` (se trece prin gol), iar `*_Void`
	# e un tub cu pereti lipiti de gol: ca trimesh ar da camerei din tunel un fals
	# "in solid" (parity pe un tub inchis, vezi tools/probe_camera_solid.gd), iar golul
	# trebuie sa ramana gol.
	"tunnel_portal_balea": ["Portal_Void"],
	"rock_tunnel_portal": ["Rock_Void"],
}


func _build_collision() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var mode := _collision_mode(model)
		if mode == "none":
			continue
		if mode == "bump":
			if BumpProp.wrap(model) != null:
				continue
			mode = "hull"
		var body := StaticBody3D.new()
		body.name = "%s_col" % model.name
		var added := false
		match mode:
			"trunk":
				added = _add_trunk(body, model)
			"mesh":
				added = _add_trimesh(body, model)
			_:
				added = TrackDecor.add_hull_collision(body, model, true,
					HULL_SKIP_PARTS.get(
						model.scene_file_path.get_file().get_basename(), []))
		if not added:
			body.free()
			continue
		# Modul ramane lipit de corp, ca sonda (tools/probe_solid.gd) sa poata
		# separa piesele care stau peste sosea PRIN PROIECT de accidente.
		body.set_meta("mod_coliziune", mode)
		# CAMERA: o piesa PRIN CARE SE TRECE trebuie sa opreasca si camera.
		#
		# Implicit decorul nu intra pe `CAMERA_BLOCKER_LAYER` — si e corect:
		# altfel camera s-ar smuci la fiecare felinar de pe margine. Dar blocul
		# Liziba e o cladire prin al carei parter trece SOSEAUA, iar camera de
		# joc zboara la 10 m inaltime: masurat la fractia 0.89, camera ajungea
		# in plansee, iar cadrul era o placa neagra cu o dunga de lume sus —
		# masina disparea cu totul pe trei fractii. Cu piesa pe layerul de
		# blocare, `ChaseCamera._unclip` o trage in fata plafonului si intra in
		# hol odata cu masina, adica exact ce cerea dezvoltatorul: „sa ne vedem
		# masina inauntru".
		if bool(model.get_meta("camera_blocker", false)) 				or bool(get_meta("camera_blocker", false)):
			body.collision_layer |= Track.CAMERA_BLOCKER_LAYER
		# FRATE, nu parinte: `add_hull_collision` scrie formele in spatiul
		# PARINTELUI modelului (porneste din `model.transform`), iar
		# reparentarea ar muta nodul asezat de mana — adica exact ce n-are voie
		# sa faca un pas automat peste munca din editor.
		model.get_parent().add_child(body)
		_add_camera_only_body(model)


## Partile care blocheaza DOAR CAMERA, nu masina (stem -> nume de mesh).
##
## Poarta Ryukyu are acoperisul la 6,8-13,2 m peste drum, deasupra oricarei masini,
## deci `ryukyu_gate` nu are corp fizic pe el (`HULL_SKIP_PARTS`). Camera de joc sta
## insa la 10 m: cand masina e la 9-15 m dincolo de poarta, camera e INAUNTRUL
## acoperisului si cadrul devine o culoare plata (vezi tools/probe_camera_solid.gd).
## Corpul de aici are hull pe parti si sta DOAR pe `CAMERA_BLOCKER_LAYER`, fara
## masca: `ChaseCamera._unclip` il vede si trage camera in fata lui, masina trece
## prin el ca prin aer.
const CAMERA_ONLY_PARTS := {
	"ryukyu_gate": ["Gate_Roof", "Gate_Mortar"],
}


func _add_camera_only_body(model: Node3D) -> void:
	var stem := model.scene_file_path.get_file().get_basename()
	if not CAMERA_ONLY_PARTS.has(stem):
		return
	var keep: Array = CAMERA_ONLY_PARTS[stem]
	var skip: Array = []
	for entry in TrackDecor.visible_meshes(model, model.transform):
		var nm := String((entry[0] as MeshInstance3D).name)
		if not keep.has(nm):
			skip.append(nm)
	var body := StaticBody3D.new()
	body.name = "%s_cam" % model.name
	body.collision_layer = Track.CAMERA_BLOCKER_LAYER
	body.collision_mask = 0
	if not TrackDecor.add_hull_collision(body, model, true, skip):
		body.free()
		return
	body.set_meta("mod_coliziune", "camera")
	model.get_parent().add_child(body)


## Instantele de model din subarbore. Se opreste la prima gasita (un .glb nu
## contine alt .glb) si sare peste ce e deja sub un corp fizic — atat peste
## StaticBody-urile puse de mana dupa reteta veche din docs, cat si peste
## modelele purtate de un [PathMover], care sunt copiii unui AnimatableBody3D si
## se MISCA: un colizor static lasat in urma lor ar fi un zid fantoma.
## Muta UV-urile de pe sloturile portocalii pe cele crem, pe modelele din
## `TUFF_UV_MODELS`. Vezi comentariul de la `TUFF_UV_REMAP` pentru masuratoare.
##
## Lucreaza pe o COPIE a mesh-ului (`ArrayMesh` nou), nu pe resursa incarcata:
## un `.glb` e partajat intre toate instantele si intre piste, deci scrisul in el
## ar fi vopsit si ce nu trebuie, iar in editor s-ar fi salvat in import.
## Trece kitul de tuf pe materialul cu pete care SE STING CU DISTANTA.
##
## Runda 7, numit independent de amandoi criticii: pe hornuri petele au aceeasi
## marime si acelasi contrast de la 3 m la 90 m. Pe carosabil si pe teren
## stingerea exista din runda 6 (shadere proprii); prop-urile ramasesera pe
## `world_material`, care e StandardMaterial3D si nu poate stinge UN STRAT —
## `distance_fade` de acolo stinge obiectul intreg.
##
## Ruleaza DUPA `_apply_model_classes` ca sa aiba ultimul cuvant, dar sare
## peste orice parte care si-a primit deja o clasa proprie (palaria pe clasa
## de roca, accentele rupte): alea au material din alt motiv, si nu au voie
## sa-l piarda aici.
##
## Costa UN material pe toata pista, nu unul per horn — vezi
## `Palette.faded_detail_material`. Verificat cu tools/probe_decor.gd.
func _fade_tuff_detail() -> void:
	var mat := Palette.faded_detail_material()
	var world := Palette.world_material()
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		if not TUFF_UV_MODELS.has(model.scene_file_path.get_file().get_basename()):
			continue
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null:
				continue
			# Doar piesele ramase pe materialul LUMII: o parte care si-a luat
			# deja o clasa (tri:, glow:, finish:) o pastreaza.
			if mi.material_override == world:
				mi.material_override = mat


func _retint_tuff() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		if not TUFF_UV_MODELS.has(stem):
			continue
		# Arcada duce si maroul de intrados pe cenusiu; restul kitului nu.
		var remap := TUFF_UV_REMAP.duplicate()
		if ARCH_UV_MODELS.has(stem):
			remap.merge(ARCH_UV_REMAP)
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var out := ArrayMesh.new()
			var changed := false
			for s in mi.mesh.get_surface_count():
				var arr := MeshCpu.surface_arrays(mi.mesh, s)
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				for i in uv.size():
					var slot := int(floor(uv[i].x * float(Palette.SLOTS)))
					if remap.has(slot):
						uv[i] = Palette.uv(int(remap[slot]))
						changed = true
				arr[Mesh.ARRAY_TEX_UV] = uv
				MeshCpu.add_surface(out, arr)
			if changed:
				mi.mesh = out


## Caldura tufului, din VERTEX COLOR.
##
## De ce nu din sloturi: vezi nota lunga de la TUFF_UV_REMAP. Benzile din .glb
## sunt suprafete late; schimbarea slotului le face dungi portocalii. Tenta pe
## vertecsi se aplica in schimb pe TOT conul, deci muta nuanta fara sa atinga
## raportul dintre benzi — si asta e chiar ce cerea critica: "a warm pinkish
## buff", nu "benzi mai colorate".
##
## Multiplicatorul poate DOAR sa intunece (memoria
## `surfacetool-clamp-vertex-color`), ceea ce pica bine aici: reprosul era ca
## rocile sunt prea ALBE, deci coborarea e chiar directia ceruta. Se taie din
## verde si mai ales din albastru, si aproape deloc din rosu — asa un crem
## acromatic (212, 189, 169 la CORAL_SAND) ajunge roz-caramiziu fara sa fie
## nevoie de un slot nou.
##
## Gradientul pe inaltime: baza mai calda si mai inchisa, varful aproape
## neatins. Doua motive. In referinta conurile chiar sunt mai roz jos, unde
## sta stratul de tuf mai vechi. Si, mai practic, palaria inchisa are nevoie de
## contrast cu ce e sub ea — daca varful se intuneca odata cu baza, silueta se
## aplatizeaza.
##
## `hue_shift` per instanta rupe uniformitatea: critica cerea explicit "hue
## variation between neighbouring cones", iar cu o singura tenta pe tot kitul
## padurea ar fi ramas monocroma, doar de alta culoare decat inainte.
func _warm_tuff() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		if not TUFF_UV_MODELS.has(stem):
			continue
		# Seed stabil per instanta: acelasi horn primeste aceeasi nuanta la
		# fiecare incarcare, altfel padurea ar palpai intre rulari.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(model.name) & 0x7fffffff
		var hue_shift := rng.randf_range(-0.035, 0.035)
		var strength := rng.randf_range(0.82, 1.0)
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var aabb := mi.mesh.get_aabb()
			var y0 := aabb.position.y
			var h := maxf(aabb.size.y, 0.001)
			var out := ArrayMesh.new()
			for si in mi.mesh.get_surface_count():
				var arr := MeshCpu.surface_arrays(mi.mesh, si)
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				# ARRAY_COLOR e `null`, nu un vector gol, cand mesh-ul n-are
				# culori de vertex — atribuirea directa intr-un
				# PackedColorArray tipat pica la rulare. Se citeste ca Variant
				# si se materializeaza alb daca lipseste.
				var raw_cols: Variant = arr[Mesh.ARRAY_COLOR]
				var cols := PackedColorArray()
				if raw_cols is PackedColorArray:
					cols = raw_cols
				if cols.size() != verts.size():
					cols = PackedColorArray()
					cols.resize(verts.size())
					cols.fill(Color.WHITE)
				# PE TRIUNGHI, nu pe vertex (runda 14).
				#
				# Aici se pierdea, masurat, umbrirea pe fata a hornurilor.
				# `_shade_facets` scrie o valoare PLATA per triunghi (mesh
				# deindexat, cei 3 vertecsi sunt numai ai fetei), dar bucla asta
				# rula dupa el si recalcula `t` din Y-ul FIECARUI vertex: pe o
				# fata inclinata cei trei vertecsi au cote diferite, deci primeau
				# trei valori diferite si rasterizatorul le interpola inapoi intr-un
				# degrade. Sonda `probe_capp_vcol` a gasit 1489 din 1637 de fete cu
				# culoare neplata pe triunghi — adica umbrirea pe fata era ca si
				# stearsa pe 91% din horn, oricat de fin ar fi fost cuantizata in
				# `_shade_facets`. (De-aia urcarea la 12 trepte n-a miscat captura:
				# repara treapta, nu ce o netezea la loc.)
				#
				# Se ia cota CENTROIDULUI si se aplica aceeasi valoare pe cei trei
				# vertecsi: gradientul cald ramane (conul e tot mai cald la baza),
				# dar se rotunjeste la treapta fetei pe care sta, in loc sa curga
				# peste ea. Exact regula ceruta: un semnal pictat peste fatete ori
				# se cuantizeaza pe fata, ori sterge fatetele.
				#
				# Fallback pe vertex daca surface-ul nu e triunghiuri intregi:
				# functia atinge tot kitul de tuf, nu doar hornurile deindexate.
				if verts.size() % 3 == 0:
					for tri in verts.size() / 3:
						var i := tri * 3
						var cy := (verts[i].y + verts[i + 1].y
								+ verts[i + 2].y) / 3.0
						# 1 la baza, 0 la varf.
						var t := 1.0 - clampf((cy - y0) / h, 0.0, 1.0)
						# Plancherul de 0.62 (nu 0.35) e o corectie MASURATA, nu
						# o preferinta. Cu 0.35, treimea de sus a conului ramanea
						# la luminanta 158 fata de 138 in referinta — adica exact
						# "chalk-white in its upper two-thirds" ramanea nereparat,
						# chiar daca media pe tot conul cadea bine. Media pe toata
						# suprafata poate sa fie corecta cu varful gresit; se
						# masoara pe FASII de inaltime, nu global.
						# RUNDA 15: tenta slabita (0.06/0.15/0.26 ->
						# 0.03/0.09/0.16). Masurat pe captura, saturatia rocii
						# era 0.62-0.67 fata de 0.46 in referinta — tuful iesea
						# caramiziu-portocaliu, nu crem cald. Taind mai ales din
						# albastru, tenta muta nuanta dar SCADE si luminanta
						# (albastrul e 11% din ea, verdele 59%): cu 0.15 pe verde
						# se pierdeau ~10 unitati din valoare degeaba. Plancherul
						# ramane 0.62, deci gradientul baza-varf se pastreaza.
						var k := strength * (0.62 + 0.38 * t)
						var warm := Color(
							1.0 - 0.03 * k,
							1.0 - (0.09 + hue_shift) * k,
							1.0 - (0.16 + hue_shift * 2.0) * k)
						for j in 3:
							cols[i + j] = cols[i + j] * warm
				else:
					for i in verts.size():
						var t := 1.0 - clampf((verts[i].y - y0) / h, 0.0, 1.0)
						var k := strength * (0.62 + 0.38 * t)
						cols[i] = cols[i] * Color(
							1.0 - 0.03 * k,
							1.0 - (0.09 + hue_shift) * k,
							1.0 - (0.16 + hue_shift * 2.0) * k)
				arr[Mesh.ARRAY_COLOR] = cols
				MeshCpu.add_surface(out, arr)
			mi.mesh = out


## STRATUL DE MINERAL ROSU pe tuful din PRIM-PLAN si PLAN MEDIAN.
##
## De ce exista. Masurat pe captura de sofer (frac 0.06, --driver), cadrul
## nostru era MONOCROM: IQR de nuanta 2.86 grade, cu 90.9% din pixelii saturati
## intr-un SINGUR interval de 15 grade. Referinta are IQR 5.2-7. Iar singura a
## doua nuanta pe care o aveam statea la ORIZONT (`red_mesa`, masurata la 114 m
## de camera) — adica la adancimea la care nu separa nimic.
##
## De ce nuanta era blocata, si asta e cauza reala: SURSELE DE LUMINA sunt
## amandoua portocalii. `sun_color` (1.0, 0.82, 0.63) are nuanta 30.8 grade,
## `ambient_color` F0C79A are 31.4. Mediana cadrului nostru era 32.4. Cu alte
## cuvinte cadrul nu era de culoarea rocilor, era de culoarea LUMINII: orice
## albedo aproape acromatic (cremul CORAL_SAND, saturatie 0.18) iese din
## inmultire pe nuanta becului, indiferent ce piesa e.
##
## De aici si singura iesire posibila: un albedo care e el insusi SATURAT si mai
## rosu decat lumina. Socotit inainte de scris, nu dupa:
##   crem E9DCC0 * soare  ->  nuanta 31.8   (adica exact media cadrului)
##   ocru C4784F * soare  ->  nuanta 20.0
##   rosu A8683A * soare  ->  nuanta 22.2
## Deci un strat ocru chiar muta nuanta cu 10-12 grade. Nimic mai palid n-o face.
##
## DE CE PE VERTECSI SI NU PE SLOTURI. S-a incercat de doua ori (rundele 6 si
## 10) sa se mute UV-urile hornurilor pe sloturi calde, si de fiecare data a
## iesit "cos de fabrica": benzile din .glb sunt SUPRAFETE LATE, si orice slot
## saturat pe ele da dungi de un metru si jumatate. Nota de la `TUFF_UV_REMAP`
## spune concluzia: culoarea a doua benzi late nu poate fi si calda, si
## discreta. Aici banda NU e cea din .glb — se taie dupa COTA DE LUME, deci
## grosimea ei o aleg eu, si o aleg SUBTIRE (STRAT_H = 2.2 m pe hornuri de
## 11-18 m, adica 12-20% din inaltime).
##
## SE TAIE PE COTA DE LUME, NU PE FRACTIE DIN PIESA, si asta e chiar ce face
## diferenta dintre geologie si decoratie: un strat la aceeasi cota pe toate
## piesele care impart solul citeste ca un STRAT MINERAL care traverseaza
## padurea; acelasi strat la "20% din inaltimea fiecarei piese" ar sui si ar
## cobori cu palaria si ar citi ca vopsea per obiect.
##
## Masurat cu ProbeCappCote, bazele celor 130 de piese de tuf de pe Track13:
##   p5 44.3   p25 46.4   p50 47.7   p75 48.8   p95 51.6   (extreme 31.4 si 101.4)
## Deci 90% din kit sta intr-o felie de 7 metri, si acolo o cota fixa chiar e
## un strat comun. Extremele nu sunt insa neglijabile: la piesa de la 101 m un
## strat fix la 49 ar cadea sub pamant, iar la cea de la 31.4 ar trece pe
## deasupra palariei. Pentru ele banda se MUTA in treimea de jos a piesei —
## stratul ramane vizibil, doar ca inceteaza sa mai fie acelasi strat, ceea ce
## e adevarat si geologic: o piesa la 50 m diferenta de cota chiar e din alt
## bazin.
##
## Cuantizarea pe TRIUNGHI e obligatorie, aceeasi lectie ca la `_warm_tuff`:
## pe o fata inclinata cei trei vertecsi au cote diferite, deci o taiere pe
## vertex ar interpola marginea stratului intr-un degrade care sterge exact
## fatetarea. Se ia cota centroidului. Rezolutia asta e si limita reala a
## grosimii: masurat cu probe_capp_geo, `chimney_a` are 11.26 m si numai 18
## cote distincte de vertex, adica un inel la ~0.6 m. Sub un metru banda ar
## cadea intre inele si ar aparea si dispare de la piesa la piesa.
##
## DOUA STRATE, NU UNUL, si asta e chiar afirmatia structurala a referintei:
## singurul lucru din cadrul ei care spune ca roca are ISTORIE e ca peretele are
## STRATE de mineral diferit, la plural. Cu un singur strat masuratoarea urcase
## doar la 3.47 (de la 2.86, tinta ~7): o banda pe un horn de 15 m e un accent,
## doua benzi la cote diferite sunt o stratigrafie. Al doilea e mai SUS si mai
## SUBTIRE, ca sa nu iasa doua dungi gemene — in roca reala stratele nu au
## grosimi egale.
##
## Cotele nu sunt alese la intamplare: 49.6 e la ~1 m deasupra soselei (focus
## Y 48.8 la fractia 0.06, masurat cu ProbeCappStrate), deci stratul de jos
## trece exact prin banda de imagine pe care o umple prim-planul; 53.4 cade in
## treimea mijlocie a hornurilor de 11-18 m, adica se vede si pe piesele din
## planul median, care in cadru intra doar cu partea de sus.
const STRAT_COTA: float = 49.6
const STRAT_COTA_SUS: float = 53.4
## Grosimea stratului. 2.2 m = 3-4 inele de fatete pe un horn, adica o muchie
## care se vede, nu o dunga de un texel. Cel de sus e mai subtire (1.4 m):
## doua benzi de aceeasi latime ar citi ca un tipar, nu ca geologie.
const STRAT_H: float = 2.2
const STRAT_H_SUS: float = 1.4
## Peste cat se stinge stratul la margini. Fara topire, marginea de sus a
## benzii ar fi o linie perfect orizontala pe toata padurea — desen tehnic, nu
## strat de roca. Cu 0.9 m ea se pierde intr-un inel-doua de fatete.
const STRAT_FADE: float = 0.9
## Tenta stratului, SOCOTITA CA SA NIMEREASCA PERETELE DIN REFERINTA, nu aleasa
## din ochi. Masurat pe `docs/track_briefs/img/cappadocia_v3.jpeg`:
##   peretele rosu al canionului   RGB(156, 97, 72)  nuanta 14.1  sat 0.56
##   hornurile crem de langa el    RGB(176,132, 96)  nuanta 27.2  sat 0.46
## Adica referinta tine intre roca rosie si roca crem o distanta de 13 grade de
## nuanta, la saturatii APROPIATE. Aia e stratigrafia; nu un accent portocaliu.
##
## SI DE CE SE COBOARA SI ROSUL, desi asta pare invers fata de "vrem mai rosu".
## Prima incercare taia numai G si B (0.62 / 0.30). Nuanta iesea 21.4 — bine —
## dar saturatia sarea la 0.85 fata de 0.56 in referinta, adica exact
## portocaliul aprins pentru care au picat rundele 6 si 10 ("cos de fabrica").
## Rosul referintei e INCHIS si STINS, nu aprins. Ca sa scada saturatia fara sa
## urce nuanta la loc trebuie coborat si canalul rosu — un multiplicator poate
## doar sa taie (memoria `surfacetool-clamp-vertex-color`), deci "mai putin
## saturat" se obtine taind din TOATE canalele, doar inegal.
##
## Valorile de mai jos sunt rezultatul unei cautari pe grila peste cele trei
## canale, cu eroarea calculata fata de nuanta 15.5, saturatia 0.56 si luminanta
## 108 ale peretelui din referinta. Ies:
##   crem (212,189,169) * (0.72, 0.58, 0.64) = (153, 110, 108)
##   sub soarele (1.0, 0.82, 0.63):  nuanta 15.4  sat 0.55  luminanta 106
## fata de 14.1 / 0.56 / 111 in referinta. Sub un grad si sub o unitate de
## saturatie — nu mai e nimic de reglat din ochi aici.
const STRAT_R: float = 0.72
const STRAT_G: float = 0.58
const STRAT_B: float = 0.64
## Stratul de sus e mai SLAB, nu doar mai subtire. Doua benzi la fel de
## saturate ar avea aceeasi greutate in cadru si s-ar citi ca doua accente
## puse; una tare jos si una stinsa sus citesc ca un profil care se estompeaza
## in sus — exact cum arata un perete stratificat pe care partea de jos e
## stratul vechi. Aceiasi multiplicatori, trasi ~40% catre alb.
const STRAT_R_SUS: float = 0.88
const STRAT_G_SUS: float = 0.82
const STRAT_B_SUS: float = 0.85


## Aplica stratul rosu. Rulat DUPA `_warm_tuff`, ca sa se inmulteasca peste
## caldura lui, nu in locul ei: gradientul baza-varf al conului trebuie sa
## ramana, stratul doar il taie pe o felie.
func _strata_tuff() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		if not TUFF_UV_MODELS.has(model.scene_file_path.get_file().get_basename()):
			continue
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			# Cota de LUME a piesei, si inaltimea ei reala. Ambele din
			# transformarea globala, nu din AABB-ul local: piesele sunt scalate
			# si rotite in .tscn, deci un AABB local ar da metri de model, nu
			# metri de lume.
			var xf := mi.global_transform
			var wa := xf * mi.mesh.get_aabb()
			var baza := wa.position.y
			var h := maxf(wa.size.y, 0.001)
			# Unde cade banda pe piesa ASTA. Implicit la cota comuna; daca
			# piesa nu o intersecteaza (vezi nota lunga de mai sus), banda
			# coboara in treimea ei de jos.
			var cota := STRAT_COTA
			var cota_sus := STRAT_COTA_SUS
			if cota < baza + 0.3 or cota > baza + h - 0.5:
				cota = baza + h * 0.28
			if cota_sus < baza + 0.3 or cota_sus > baza + h - 0.5:
				cota_sus = baza + h * 0.55
			var out := ArrayMesh.new()
			for si in mi.mesh.get_surface_count():
				var arr := MeshCpu.surface_arrays(mi.mesh, si)
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var raw_cols: Variant = arr[Mesh.ARRAY_COLOR]
				var cols := PackedColorArray()
				if raw_cols is PackedColorArray:
					cols = raw_cols
				if cols.size() != verts.size():
					cols = PackedColorArray()
					cols.resize(verts.size())
					cols.fill(Color.WHITE)
				if verts.size() % 3 != 0:
					arr[Mesh.ARRAY_COLOR] = cols
					MeshCpu.add_surface(out, arr)
					continue
				for tri in verts.size() / 3:
					var i := tri * 3
					# Cota CENTROIDULUI, in metri de lume. Pe triunghi, nu pe
					# vertex: vezi nota de la `_warm_tuff` despre cele 1489 de
					# fete carora interpolarea le stersese umbrirea.
					var cy: float = (xf * verts[i]).y
					cy += (xf * verts[i + 1]).y
					cy += (xf * verts[i + 2]).y
					cy /= 3.0
					var t := Color.WHITE
					var wj := _pondere_strat(cy, cota, STRAT_H)
					if wj > 0.0:
						t.r *= 1.0 - (1.0 - STRAT_R) * wj
						t.g *= 1.0 - (1.0 - STRAT_G) * wj
						t.b *= 1.0 - (1.0 - STRAT_B) * wj
					var ws := _pondere_strat(cy, cota_sus, STRAT_H_SUS)
					if ws > 0.0:
						t.r *= 1.0 - (1.0 - STRAT_R_SUS) * ws
						t.g *= 1.0 - (1.0 - STRAT_G_SUS) * ws
						t.b *= 1.0 - (1.0 - STRAT_B_SUS) * ws
					if wj <= 0.0 and ws <= 0.0:
						continue
					for j in 3:
						cols[i + j] = cols[i + j] * t
				arr[Mesh.ARRAY_COLOR] = cols
				MeshCpu.add_surface(out, arr)
			mi.mesh = out


## Ponderea unui strat la cota data: 1 in miez, topita liniar peste STRAT_FADE
## la margini, 0 in afara. Scoasa in functie fiindca o foloseau amandoua benzile
## si copierea ei ar fi insemnat doua locuri de reglat cand se muta topirea.
func _pondere_strat(cy: float, cota: float, gros: float) -> float:
	var d := absf(cy - cota)
	if d > gros * 0.5 + STRAT_FADE:
		return 0.0
	return 1.0 - clampf((d - gros * 0.5) / STRAT_FADE, 0.0, 1.0)


## Peretele Vaii Rosii: mai ROSU si mai LUMINOS decat il da .glb-ul.
##
## De ce. Zidul de pe umarul exterior (ZidulValeiRosii) e construit din
## `cliff_band_module`, si in captura iesea cenusiu — panouri de beton intr-un
## desert cald. Prima banuiala, ca sloturile din .glb sunt gresite, e FALSA:
## masurat cu ProbeCappZidUV, piesa foloseste 1/2/19/23/27, adica D4994D,
## 915D27, E9DCC0, C4784F, A8683A — toate calde. Cenusiul vine din LUMINA:
## fata dinspre drum e intoarsa de la soarele de 13 grade, iar AO-ul copt in
## vertecsi o mai coboara o data.
##
## Masurat pe pixeli, zidul fata de canionul din referinta:
##   al nostru    nuanta 29.2  luminanta  88.9
##   referinta    nuanta 14.6  luminanta 110.7
## Adica prea INCHIS cu 22 de puncte si prea putin rosu cu 15 grade. Un perete
## de vale rosie care nu e rosu nu spune ca acolo e Valea Rosie; ramane un zid.
##
## Se corecteaza pe vertex color, ca si caldura tufului. Multiplicatorul poate
## doar sa intunece, deci luminanta NU se poate urca de aici — se urca stingand
## AO-ul copt (culorile existente se duc catre alb) si abia apoi se aplica
## tenta rosie. Asta e si motivul pentru care functia e separata de
## `_warm_tuff`: acolo AO-ul trebuie PASTRAT, aici e chiar ce incurca.
func _redden_cliff() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		if model.scene_file_path.get_file().get_basename() != "cliff_band_module":
			continue
		if not String(model.name).begins_with("zidValea"):
			continue
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var out := ArrayMesh.new()
			for si in mi.mesh.get_surface_count():
				var arr := MeshCpu.surface_arrays(mi.mesh, si)
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var raw_cols: Variant = arr[Mesh.ARRAY_COLOR]
				var cols := PackedColorArray()
				if raw_cols is PackedColorArray:
					cols = raw_cols
				if cols.size() != verts.size():
					cols = PackedColorArray()
					cols.resize(verts.size())
					cols.fill(Color.WHITE)
				for i in verts.size():
					# AO-ul copt se stinge pe jumatate: peretele e departat si
					# in ceata, iar ocluzia lui de aproape doar il inchide.
					var c := cols[i]
					# AO-ul copt se stinge aproape complet. 0.55 nu ajungea:
					# masurat pe pixeli, luminanta zidului urcase doar de la
					# 88.9 la 92.5, fata de 110.7 in referinta. Peretele e
					# departat si in ceata — ocluzia lui de contact nu se vede
					# de la 60 m, dar il inchide cat sa citeasca a beton.
					c = c.lerp(Color.WHITE, 0.88)
					# Tenta: taie din verde si mai ales din albastru, rosul
					# neatins, ca nuanta sa coboare de la ~29 catre ~16 grade.
					c.g *= 0.72
					c.b *= 0.42
					cols[i] = c
				arr[Mesh.ARRAY_COLOR] = cols
				MeshCpu.add_surface(out, arr)
			mi.mesh = out


func _collect_models(node: Node, out: Array[Node3D]) -> void:
	for c in node.get_children():
		var spatial := c as Node3D
		if spatial == null:
			continue
		if spatial is PhysicsBody3D:
			continue
		if not spatial.scene_file_path.is_empty():
			out.append(spatial)
			continue
		_collect_models(spatial, out)


## Cele patru moduri valide. Exista ca sa poata fi VERIFICATA metadata scrisa
## de mana sau de un generator: `match` de mai jos are ramura implicita `_`, deci
## o valoare scrisa gresit nu cade in gol, ci face HULL — adica exact pe dos
## fata de intentie, si in tacere.
##
## "bump" (#489): piesa devine `BumpProp` — corp rigid usor, adormit, pe care
## masina il imprastie. Doar pentru piese mici (pragul e in BumpProp); una prea
## mare, sau peste plafonul pistei, cade pe "hull".
const COLLISION_MODES := ["hull", "trunk", "mesh", "none", "bump"]

func _collision_mode(model: Node3D) -> String:
	if model.has_meta(COLLISION_META):
		var m := String(model.get_meta(COLLISION_META))
		if COLLISION_MODES.has(m):
			return m
		# NU se ghiceste ce a vrut sa spuna: se striga, si se cade pe implicit.
		#
		# Cazul care a cerut verificarea asta: `tools/gen_capp_creasta.gd` scria
		# `coliziune = "niciuna"` (romaneste) pe cele 101 module ale zidului
		# Vaii Rosii, cu comentariul lui explicit — „departe de banda si sub
		# nivelul ei: nu are nevoie de corp fizic, un hull per modul ar fi zeci
		# de corpuri degeaba". Valoarea nu e in tabel, deci pica pe ramura `_`
		# si producea fix cele zeci de corpuri: masurat, 101 corpuri cu 101
		# forme convexe. Doua runde au trecut pe langa ea fiindca nimic nu se
		# plangea.
		push_warning(("world_prop: `%s = \"%s\"` pe %s nu e un mod valid " +
			"(%s). Se aplica implicitul \"hull\".")
			% [COLLISION_META, m, model.name, ", ".join(COLLISION_MODES)])
	var stem := model.scene_file_path.get_file().get_basename()
	return String(PROP_COLLISION.get(stem, "hull"))


## Cilindru pe axa modelului, cu raza trunchiului. Aceeasi forma ca la copacii
## din scatter, ca sa nu existe doua feluri de copac in aceeasi padure.
func _add_trunk(body: StaticBody3D, model: Node3D) -> bool:
	var aabb := Track.model_aabb(model)
	if aabb.size.y <= 0.01:
		return false
	var cyl := CylinderShape3D.new()
	cyl.height = aabb.size.y
	var stem := model.scene_file_path.get_file().get_basename()
	cyl.radius = float(TRUNK_RADIUS[stem]) if TRUNK_RADIUS.has(stem) \
		else maxf(aabb.size.x * TRUNK_FRACTION, TRUNK_MIN_RADIUS)
	var col := CollisionShape3D.new()
	col.shape = cyl
	col.position = aabb.position + Vector3(aabb.size.x * 0.5,
		aabb.size.y * 0.5, aabb.size.z * 0.5)
	# Cu raza masurata (TRUNK_RADIUS) axa e a MODELULUI, nu centrul AABB: o
	# coroana asimetrica (ramura lunga intr-o parte) muta centrul casetei de pe
	# trunchi, si un cilindru subtire centrat pe caseta rateaza lemnul.
	if TRUNK_RADIUS.has(stem):
		col.position.x = model.transform.origin.x
		col.position.z = model.transform.origin.z
	body.add_child(col)
	return true


## Colizor exact, pentru piesele prin care se trece. Fetele se transforma o
## data, la constructie, in spatiul parintelui — ca la hull-uri — ca sa nu
## depinda de scalarea nodului de forma.
func _add_trimesh(body: StaticBody3D, model: Node3D) -> bool:
	var added := false
	# Aceeasi lista de parti sarite ca la hull (`HULL_SKIP_PARTS`): Mittens-urile
	# (`mesh`) isi lasa fusta de grohotis si calota fara corp propriu.
	var skip: Array = HULL_SKIP_PARTS.get(
		model.scene_file_path.get_file().get_basename(), [])
	for entry in TrackDecor.visible_meshes(model, model.transform):
		var mi: MeshInstance3D = entry[0]
		var xform: Transform3D = entry[1]
		if not skip.is_empty() and skip.has(String(mi.name)):
			continue
		var src := _trimesh_faces(mi.mesh)
		if src.is_empty():
			continue
		var faces := PackedVector3Array()
		faces.resize(src.size())
		for i in src.size():
			faces[i] = xform * src[i]
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)
		added = true
	return added


## Cache pe RESURSA de mesh, ca la hull-uri: portalul de tunel e asezat de
## patru ori pe Baikal, si e cea mai grea piesa din tabel.
static var _face_cache: Dictionary = {}

static func _trimesh_faces(mesh: Mesh) -> PackedVector3Array:
	if mesh == null:
		return PackedVector3Array()
	var key := mesh.get_rid()
	if _face_cache.has(key):
		return _face_cache[key]
	var shape := mesh.create_trimesh_shape()
	var faces := PackedVector3Array() if shape == null else shape.get_faces()
	_face_cache[key] = faces
	return faces


## Maparea nume-de-parte -> clasa de material, adunata din sursele EXISTENTE.
##
## Nu e o copie: ISLAND_CLASSES si tabelul de landmark-uri rămân singurul adevar,
## iar aici doar se citesc. O a doua listă scrisa de mana ar rămâne in urma la
## primul asset nou — exact capcana descrisa in track08.gd despre punctele de
## control duplicate.
## PUBLICA dinadins: acelasi tabel il foloseste si [PathMover], pentru
## modelele care se misca (vezi `Palette.apply_object_class_materials`). O a
## doua lista scrisa de mana ar fi ramas in urma la primul asset nou.
## Kyoto, valul 2: piesele care se MISCA (trenul Sagano, ricsa). Un [PathMover]
## citeste doar `prop_classes()` (global, pe nume de nod) si aplica clasele in
## spatiul OBIECTULUI, ca textura sa nu „inoate" pe caroserie. Numele sunt unice
## in tot `assets/models/` (verificat cu grep pe .glb), deci intrarea globala nu
## prinde alt kit.
const KYOTO_MOVING_CLASSES := {
	"Train_Body": Palette.TRI_PREFIX + "shu_red",
	"Rick_Red": Palette.TRI_PREFIX + "shu_red",
}

static func prop_classes() -> Dictionary:
	var out := {}
	out.merge(TrackDecor.ISLAND_CLASSES)
	out.merge(TrackDecor.BAIKAL_CLASSES)
	out.merge(TrackDecor.STROMBOLI_CLASSES)
	out.merge(TrackDecor.CHONGQING_CLASSES)
	out.merge(TrackDecor.CAPPADOCIA_CLASSES)
	out.merge(TrackDecor.FIORDLAND_AIRSTRIP_CLASSES)
	out.merge(KYOTO_MOVING_CLASSES)
	for id: int in Track._LANDMARKS:
		var info: Dictionary = Track._LANDMARKS[id]
		if info.has("classes"):
			out.merge(info["classes"])
	return out


## Masele de stanca ale cornisei incase: coborate din CLIPPING, ca fatetele sa
## se vada din nou.
##
## DE CE. Criticul orb al POI-ului H a numit defectul asa: peretele „e o duna de
## nisip neteda, dintr-o singura nuanta, in loc de masa de roca fatetata", si
## zidaria „n-are din ce sa fie zid". Prima ipoteza — ca mesh-ul e neted, sau ca
## n-are AO — e FALSA, masurata (tools/sv_facet.gd, pe .glb):
##
##   huayna_picchu: abaterea normalei de vertex fata de fata = 6,5 grade mediana
##                  (deci e FLAT shaded, fatetele exista in geometrie)
##                  lambert pe fata p10=0,09 p50=0,47 p90=0,94 (spread bun)
##                  AO copt in vertecsi p10=0,23 p50=0,48 p90=0,94 (exista)
##
## Geometria si AO-ul sunt in regula. Ce nu e in regula se vede abia pe PIXELI
## (memoria `procent-de-culoare-nu-e-dovada`: captura bate cifra), comparand
## distributia de valoare cu decupajul din bara:
##
##   masa huayna (noi)   V: p10=0,36 p25=0,60 p50=0,88 p75=0,98 p90=1,00
##   stanca (bara)       V: p10=0,31 p25=0,41 p50=0,69 p75=0,86 p90=0,99
##
## INTERVALUL e acelasi (0,64 fata de 0,67) — deci nu e „lipsa de contrast".
## Distributia insa e imbacsita la varf: **29,4 % din pixelii masei sunt la
## >= 250, si 44,2 % peste 240**, fata de 16,0 % / 20,4 % in referinta. Peste
## jumatate din suprafata luminata e TAIATA la alb, si doua fatete care ies
## amandoua din scala au exact aceeasi culoare — asa dispar muchiile si asa
## devine roca o duna. Nu clasa e gresita (`inca_stone` e granit cald, corect
## pentru zidarie si calculat pe masuratoare), ci faptul ca aceeasi valoare,
## potrivita pe un zid de 2,5 m, arde pe un flanc de 79 m intors spre soare.
##
## CUM. Nu se schimba clasa si nu se adauga alta (ar fi +1 material pentru o
## problema de expunere, nu de materie): se coboara ALBEDO-ul piesei din vertex
## color, mecanismul lui `_redden_cliff` de mai sus, cu doua deosebiri.
##
## 1. NU e un multiplicator plat. Un ×0,78 uniform ar aseza mediana pe referinta
##    (0,88 -> 0,69) dar ar stinge si varfurile, iar in bara varfurile TRAIESC
##    (p90 = 0,99): creasta prinde soarele. Factorul se conduce din AO-ul copt,
##    care e mare exact pe muchiile expuse si mic in scobituri:
##        factor = LO + (1 - LO) * ao^K,  LO = 0,62, K = 3,0
##    Asa fetele de mijloc (AO ~0,48) coboara la 0,66 — ies din taiere — iar
##    muchiile (AO ~0,94) raman la 0,94. Verificat pe cifre inainte de a fi
##    scris: V 0,88 -> 0,58, V 1,00 (AO 0,94) -> 0,94, adica exact forma
##    distributiei din bara.
## 2. Tenta. Masurat pe captura fata de bara, roca noastra e si prea calda si
##    prea saturata: H 37 S 0,50 fata de H 31 S 0,30. Multiplicatorul care duce
##    culoarea pe tinta e (0,71, 0,76, 1,00) — calculat, nu ales: raportul pe
##    canale intre HSV(31, 0,30, 0,50) si HSV(37, 0,50, 0,70). Albastrul ramane
##    1,0 fiindcă vertex color-ul poate doar sa INTUNECE (memoria
##    `surfacetool-clamp-vertex-color`), deci racirea se face taind rosu si
##    verde, nu urcand albastru.
##
## Se aplica DOAR pe `huayna_picchu` — masele mari, care sunt singurele ce ard.
## `moss_boulder_*` sunt de 0,7-3 m, stau in umbra vegetatiei si masoara sub
## prag; nu se ating, ca sa nu se strice contactul lor cu iarba.
##
## ZERO materiale noi: clasa ramane `inca_stone`, se schimba doar vertecsii
## instantei.
const CLIFF_AO_FLOOR := 0.62
const CLIFF_AO_POW := 3.0
const CLIFF_COOL := Color(0.71, 0.76, 1.0)


func _cool_inca_cliff() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		if model.scene_file_path.get_file().get_basename() != "huayna_picchu":
			continue
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var out := ArrayMesh.new()
			for si in mi.mesh.get_surface_count():
				var arr := MeshCpu.surface_arrays(mi.mesh, si)
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var raw_cols: Variant = arr[Mesh.ARRAY_COLOR]
				var cols := PackedColorArray()
				if raw_cols is PackedColorArray:
					cols = raw_cols
				if cols.size() != verts.size():
					# Fara AO copt n-avem din ce conduce umarul, si un
					# multiplicator plat ar stinge si muchiile. Mai bine
					# nemodificat decat aplatizat.
					cols = PackedColorArray()
					cols.resize(verts.size())
					cols.fill(Color.WHITE)
				for i in verts.size():
					var c := cols[i]
					var ao := clampf(c.r, 0.0, 1.0)
					var f: float = CLIFF_AO_FLOOR + (1.0 - CLIFF_AO_FLOOR) * pow(ao, CLIFF_AO_POW)
					c.r *= f * CLIFF_COOL.r
					c.g *= f * CLIFF_COOL.g
					c.b *= f * CLIFF_COOL.b
					cols[i] = c
				arr[Mesh.ARRAY_COLOR] = cols
				MeshCpu.add_surface(out, arr)
			mi.mesh = out
