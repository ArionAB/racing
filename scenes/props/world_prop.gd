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
	"porter": "none", "table_stools": "none", "steam_vent": "none",
	"scooter": "none", "bicycle": "none",
	# --- Cappadocia -------------------------------------------------------
	# Plopii: aceeasi problema ca laricele — hull-ul unei coroane de 12 m e un
	# con care te opreste in aer, la trei metri de trunchi.
	"poplar_a": "trunk", "poplar_b": "trunk",
	# Via si tufele: sub linia capotei, pe acostament. Un corp solid acolo ar
	# transforma iesirea de pe banda in zid.
	"vine_row": "none", "shrub_dry": "none",
	# Molozul hornului cazut (0.98 m inaltime) e o dara de pietre pe nisip:
	# hull-ul lui ar fi o lespede de 10 m pe care masina s-ar urca.
	"cracked_chimney_c": "none",
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
}

const ACCENT_SPLIT := {
	"House_A": Palette.FOAM_WHITE,
	"House_B": Palette.FOAM_WHITE,
	"House_C": Palette.FOAM_WHITE,
	"Church_Body": Palette.FOAM_WHITE,
	"Church_Tower": Palette.FOAM_WHITE,
	# Chongqing: DOUA sloturi pastrate, nu unul. Masurat pe inaltime, slotul 29
	# tine parterul (y 0..3.1) si slotul 8 etajele (y 2.9..5.8) — acelasi perete
	# de beton, taiat pe orizontala din motive de compozitie, nu doua materiale.
	# Cu un singur slot pastrat, jumatate din fatada ramanea plata langa
	# jumatatea texturata, adica exact cusatura pe care ruptura o evita.
	"ShophouseA": [Palette.CONCRETE, Palette.MARBLE_GREY],
	"ShophouseB": [Palette.CONCRETE, Palette.MARBLE_GREY],
	"ShophouseC": [Palette.CONCRETE, Palette.MARBLE_GREY],
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
	"stromboli_church": {
		"Church_Body": Palette.TRI_PREFIX + "village_plaster",
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


func _ready() -> void:
	_split_shutters()
	_retint_tuff()
	_warm_tuff()
	_strata_tuff()
	_redden_cliff()
	Palette.apply_class_materials(self, prop_classes())
	_apply_model_classes()
	_fade_tuff_detail()
	_apply_glow()
	if auto_collision and not Engine.is_editor_hint():
		_build_collision()


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
		if not SPLIT_MODELS.has(model.scene_file_path.get_file().get_basename()):
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


## Aplica `CLASSES_BY_MODEL` peste materialele deja puse. Ruleaza DUPA
## `apply_class_materials`, ca sa aiba ultimul cuvant pe partile ambigue.
func _apply_model_classes() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		if not CLASSES_BY_MODEL.has(stem):
			continue
		# NU `apply_class_materials`: ala pune materialul lumii pe tot ce nu e
		# in mapare, deci ar sterge clasele deja aplicate pe celelalte parti
		# (`Church_Tower` tocmai primise varul). Aici se ating DOAR partile
		# numite.
		var mapping: Dictionary = CLASSES_BY_MODEL[stem]
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
			var best := -1
			for part: String in mapping:
				if nm.begins_with(part) and part.length() > best:
					best = part.length()
					cls = String(mapping[part])
			if cls.is_empty():
				continue
			# Nodurile de accente exista tocmai ca sa RAMANA pe atlas, deci o
			# clasa de suprafata nu are ce cauta pe ele. LUMINA insa da: pe
			# fatadele Chongqing accentele SUNT partea care arde, si dupa
			# ruptura sunt singurul nod care mai poarta slotul 30.
			var is_accent := nm.ends_with(Palette.ACCENT_SUFFIX)
			if is_accent and not cls.begins_with(Palette.GLOW_PREFIX):
				continue
			mi.material_override = _model_class_material(cls)


## Materialul unei clase din `CLASSES_BY_MODEL`, dupa prefix.
##
## Pana in august 2026 aici era un apel direct la `triplanar_class_material`:
## maparea avea un singur client (varul bisericii) si toate valorile ei erau
## "tri:". Al doilea client — ferestrele aprinse ale Chongqing-ului — e "glow:",
## iar cu apelul vechi ar fi primit tacut o textura triplanara pe o clasa
## inexistenta. Prefixele sunt aceleasi ca in `apply_class_materials`, ca o
## mapare sa insemne acelasi lucru indiferent pe unde intra.
func _model_class_material(cls: String) -> Material:
	if cls.begins_with(Palette.GLOW_PREFIX):
		return Palette._glow_from_spec(cls.trim_prefix(Palette.GLOW_PREFIX))
	if cls.begins_with(Palette.FINISH_PREFIX):
		return Palette.finish_material(cls.trim_prefix(Palette.FINISH_PREFIX))
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
		var split: bool = SPLIT_MODELS.has(
			model.scene_file_path.get_file().get_basename())
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null:
				continue
			if split and not String(mi.name).ends_with(Palette.ACCENT_SUFFIX):
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


func _build_collision() -> void:
	var models: Array[Node3D] = []
	_collect_models(self, models)
	for model in models:
		var mode := _collision_mode(model)
		if mode == "none":
			continue
		var body := StaticBody3D.new()
		body.name = "%s_col" % model.name
		var added := false
		match mode:
			"trunk":
				added = _add_trunk(body, model)
			"mesh":
				added = _add_trimesh(body, model)
			_:
				added = TrackDecor.add_hull_collision(body, model, true)
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
				var arr := mi.mesh.surface_get_arrays(s)
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				for i in uv.size():
					var slot := int(floor(uv[i].x * float(Palette.SLOTS)))
					if remap.has(slot):
						uv[i] = Palette.uv(int(remap[slot]))
						changed = true
				arr[Mesh.ARRAY_TEX_UV] = uv
				out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
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
				var arr := mi.mesh.surface_get_arrays(si)
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
				out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
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
				var arr := mi.mesh.surface_get_arrays(si)
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
					out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
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
				out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
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
				var arr := mi.mesh.surface_get_arrays(si)
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
				out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
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
const COLLISION_MODES := ["hull", "trunk", "mesh", "none"]

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
	cyl.radius = maxf(aabb.size.x * TRUNK_FRACTION, TRUNK_MIN_RADIUS)
	var col := CollisionShape3D.new()
	col.shape = cyl
	col.position = aabb.position + Vector3(aabb.size.x * 0.5,
		aabb.size.y * 0.5, aabb.size.z * 0.5)
	body.add_child(col)
	return true


## Colizor exact, pentru piesele prin care se trece. Fetele se transforma o
## data, la constructie, in spatiul parintelui — ca la hull-uri — ca sa nu
## depinda de scalarea nodului de forma.
func _add_trimesh(body: StaticBody3D, model: Node3D) -> bool:
	var added := false
	for entry in TrackDecor.visible_meshes(model, model.transform):
		var mi: MeshInstance3D = entry[0]
		var xform: Transform3D = entry[1]
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
static func prop_classes() -> Dictionary:
	var out := {}
	out.merge(TrackDecor.ISLAND_CLASSES)
	out.merge(TrackDecor.BAIKAL_CLASSES)
	out.merge(TrackDecor.STROMBOLI_CLASSES)
	out.merge(TrackDecor.CHONGQING_CLASSES)
	for id: int in Track._LANDMARKS:
		var info: Dictionary = Track._LANDMARKS[id]
		if info.has("classes"):
			out.merge(info["classes"])
	return out
