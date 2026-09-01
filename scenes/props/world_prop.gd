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
}

const ACCENT_SPLIT := {
	"House_A": Palette.FOAM_WHITE,
	"House_B": Palette.FOAM_WHITE,
	"House_C": Palette.FOAM_WHITE,
	"Church_Body": Palette.FOAM_WHITE,
	"Church_Tower": Palette.FOAM_WHITE,
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
	# Firidele din peretele stancii goale (Cappadocia, POI G): fundul lor ARDE.
	#
	# Fara asta o fereastra sapata e o pata neagra, si verdictul rundei 2 spune
	# exact ce se intampla atunci — „absentele arata cer, nu camere". Referinta
	# (Uchisar in sectiune) castiga tocmai prin deschideri LUMINATE cu interior
	# in spatele lor. `_remap_model_slots` a pus deja fundul firidei pe slotul
	# 30; aici capata emisia care il face lumina de torta, nu vopsea portocalie.
	#
	# Energia 2.0 nu e aleasa pe gust: e FIX cea folosita de ferestrele
	# Chongqing-ului, si `glow_material` e cache-uit per (slot, energie) — deci
	# firidele astea intra pe un material care exista deja in joc si garda de
	# materiale nu se misca. O energie noua, „reglata pentru zori", ar fi fost
	# un material in plus pentru o diferenta pe care captura n-o arata.
	"hall_alcove": {
		"Hall_Alcove": Palette.GLOW_PREFIX + "30|2.0",
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
	"shophouse_a": {
		"ShophouseA": Palette.GLOW_PREFIX + "30|2.0",
	},
	"shophouse_b": {
		"ShophouseB": Palette.GLOW_PREFIX + "30|2.0",
	},
	"shophouse_c": {
		"ShophouseC": Palette.GLOW_PREFIX + "30|2.0",
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
const SLOT_REMAP_BY_MODEL := {
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
	"hall_alcove": {
		2: Palette.LAVA_ORANGE,    # fundul: portocaliu de torta, cu emisie
		4: Palette.CORAL_SAND,     # rama firidei -> crem, ca peretele
		10: Palette.CORAL_SAND,    # feroneria ruginita -> tot piatra
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


func _ready() -> void:
	_remap_model_slots()
	_split_shutters()
	Palette.apply_class_materials(self, prop_classes())
	_apply_model_classes()
	_apply_glow()
	if auto_collision and not Engine.is_editor_hint():
		_build_collision()


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
	for model in models:
		var stem := model.scene_file_path.get_file().get_basename()
		if not SLOT_REMAP_BY_MODEL.has(stem):
			continue
		var remap: Dictionary = SLOT_REMAP_BY_MODEL[stem]
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			mi.mesh = _mesh_with_slots_moved(mi.mesh, remap)


## Copia unui mesh cu UV-urile mutate pe alte sloturi de atlas.
static func _mesh_with_slots_moved(src: Mesh, remap: Dictionary) -> Mesh:
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		if not uv.is_empty():
			for i in uv.size():
				var slot := int(floor(uv[i].x * float(Palette.SLOTS)))
				if remap.has(slot):
					# Centrul slotului tinta: la margine s-ar lua jumatate din
					# culoarea vecinului la prima filtrare bilineara.
					uv[i].x = (float(int(remap[slot])) + 0.5) / float(Palette.SLOTS)
			arr[Mesh.ARRAY_TEX_UV] = uv
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
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
					Palette.split_accents(mi, int(ACCENT_SPLIT[prefix]))
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
			if nm.ends_with(Palette.ACCENT_SUFFIX):
				continue
			for part: String in mapping:
				if nm.begins_with(part):
					mi.material_override = _model_class_material(
						String(mapping[part]))
					break


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
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for c in node.get_children():
				stack.append(c)
			var mi := node as MeshInstance3D
			if mi != null:
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


func _collision_mode(model: Node3D) -> String:
	if model.has_meta(COLLISION_META):
		return String(model.get_meta(COLLISION_META))
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
	for id: int in Track._LANDMARKS:
		var info: Dictionary = Track._LANDMARKS[id]
		if info.has("classes"):
			out.merge(info["classes"])
	return out
