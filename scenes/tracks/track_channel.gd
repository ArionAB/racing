@tool
class_name TrackChannel
extends Marker3D
## O taietura de apa peste sosea, asezata VIZUAL: tragi nodul langa drum,
## bifezi Regenerate pe radacina pistei, si golul apare acolo.
##
## Nodul e o DECLARATIE, ca [TerrainPeak] si [TrackBranch]: [Track] aduna
## nodurile astea si le trece prin acelasi [code]_resolve_channels()[/code] pe
## care il folosesc si pistele scrise in cod (vezi Track09._channel_specs).
## Saparea terenului, golul din asfalt, suprafata de apa si podul (sau
## trambulina) raman EXACT aceleasi — o singura implementare, doua feluri de a
## o hrani.
##
## [b]FRACTIA NU SE DECLARA.[/b] Se citeste din POZITIA nodului: canalul taie
## soseaua la punctul copt cel mai apropiat de el. Muti nodul, se mata si
## taietura. Acelasi motiv ca la capetele scurtaturii ([TrackBranch]): o
## fractie scrisa de mana ramane in urma la prima ajustare a traseului, iar
## atunci golul din sosea si apa de sub el ajung in locuri diferite.
##
## Ca sa vezi unde cade taietura inainte de primul Regenerate, crucea gizmo-ului
## se intinde cat [member reach] — adica exact cat tine albia in fiecare parte.
##
## [b]DOUA FELURI DE TRECERE, se alege una.[/b]
##   [member jump] = false  travee ridicatoare la interval fix ([LiftBridgeHazard]) —
##                          asteptare si sincronizare, ca stramtoarea Okinawei
##   [member jump] = true   golul ramane gol si primeste o trambulina pe toata
##                          latimea: se trece din saritura, cu viteza
##
## [b]LATIMEA GOLULUI NU E LIBERA[/b], si asta e capcana care costa cel mai mult
## timp daca o afli tarziu. Cu [member jump] pornit, [member gap] trebuie sa
## treaca de DOUA masuratori, in ordinea asta:
##   1. [code]tools/ProbeJump.tscn[/code] — de la ce viteza se trece golul.
##      Masinile din garaj au plafoane intre 30 si 37 m/s (autobuzul 30), plus
##      11 m/s cat arde turbo. Un prag peste plafonul celei mai lente inseamna
##      ca ea NU trece niciodata.
##   2. [code]tools/ProbeRace.tscn[/code] — arbitrul. Daca AI-ul se aduna in
##      albie, se vede aici ca repuneri si blocaje, nu in sonda de saritura.
## Masurat pe Alpii (august 2026): la 36 m gol, autobuzul si pompierii cadeau la
## fiecare tur — 16 repuneri intr-o cursa de 150 s. La 22 m, zero.
##
## [b]Apa nu vine de la nivelul marii.[/b] Pe o pista cu [code]water[/code] in
## tema (Okinawa), canalul sapat sub cota marii se umple singur din grila de
## tarm. In rest — un parau de munte, de pilda — apa isi are cota ei, si atunci
## [member water_y_drop] e cel care o declara SI comutatorul care cere o
## suprafata proprie.

## Cati metri de sosea LIPSESC.
##
## Valoarea se rotunjeste la pasul curbei coapte, iar cifra OBTINUTA e cea care
## conteaza pentru saritura — o tiparesc si ProbeJump, si ProbeBridge. Nu
## presupune ca ai primit exact cat ai cerut.
@export var gap: float = 22.0

## Jumatatea latimii apei, masurata in lungul soselei.
@export var water_half: float = 9.0

## Pe cati metri urca malul de la apa la cota drumului.
@export var bank: float = 16.0

## Cat sub cota soselei de acolo sta fundul albiei.
##
## Adancimea DECIDE daca ratarea e terminala: sub ~10 m masina coboara taluzul
## rostogolindu-se si se intoarce in cursa, deci frica dispare (lectia rapelor
## din Track09._ravines). Peste, o prinde [RespawnZone].
@export var depth: float = 18.0

## Cat de jos sta APA fata de cota soselei. Negativ = canalul se umple din marea
## pistei (comportamentul Okinawei), deci nu primeste suprafata proprie.
##
## La un VAD ([member ford]) cifra e mica si poate fi chiar NEGATIVA prin
## [member water_over_road]: apa trebuie sa treaca PESTE asfalt, altfel
## suprafata ei ramane sub carosabil si nu se vede nimic din masina (masurat pe
## Serengeti: apa la -1.43, drumul la -1.38 — mesh-ul exista, vizibil, si
## ascuns sub drum pe toata latimea).
##
## Diferenta [member depth] − [code]water_y_drop[/code] e grosimea reala a
## stratului de apa, si tot ea da scara gradientului de culoare. Un parau sapat
## 18 m cu apa la 15 are 3 m de apa: albie larga cu firicel, nu canal plin ochi.
@export var water_y_drop: float = 15.0

## Sensul de CURGERE fata de axa canalului: 1 sau -1. Doar vizual (undele si
## darele de spuma din shaderul apei aluneca in sensul asta); nu misca nimic
## din fizica.
@export var flow_sign: float = 1.0

## Cat de departe merge albia in fiecare parte, inainte sa se stinga in teren.
@export var reach: float = 90.0:
	set(value):
		reach = maxf(value, 1.0)
		gizmo_extents = reach

## Pe ultimii metri din [member reach] albia se stinge in terenul din jur.
## Fara stingere, canalul s-ar termina cu un perete drept in mijlocul campului.
@export var fade: float = 30.0

## Golul se trece din SARITURA, nu pe pod. Vezi antetul clasei.
@export var jump: bool = true

## Cu `jump = false`: podul e FIX (podet de scanduri), nu se ridica si nu
## arunca — pentru un parau de munte, nu un canal navigabil (Chasm, Fiordland
## brief §2 randul D). Vezi [LiftBridgeHazard.static_deck]. Fara efect cand
## `jump = true`.
@export var static_deck: bool = false
## Clasa triplanara pentru tabliera, in loc de culoarea plata WOOD_WEATHERED
## ([LiftBridgeHazard._deck_material]). Gol (implicit) = comportamentul
## vechi, bit-identic pe TOATE canalele existente (Okinawa inclusiv) — opt-in
## doar unde s-a masurat si s-a cerut lemn cu granulatie reala (Chasm,
## Fiordland brief §4: "podetul... WOOD_WEATHERED 9, ud = mai inchis").
## `_deck_material()` e static/partajat pe clasa hazardului, deci un canal
## care seteaza asta schimba tabliera DOAR pentru propria lui instanta de
## `LiftBridgeHazard` (fiecare `_build_lift_bridge` creeaza hazardul ei),
## nu pentru altele — dar clasa triplanara insasi (`Palette.triplanar_class_material`)
## e cache-uita GLOBAL pe numele clasei, deci costa UN singur material la
## garda indiferent pe cate canale se foloseste.
@export var deck_material_class: String = ""
## Turnurile cu grinda si lampile de avertizare — opreste-le pe un podet fix
## fara ciclu (n-are ce sa avertizeze). Fara efect cand `jump = true`.
@export var build_towers: bool = true
## Corabiile care traverseaza canalul — opreste-le pe un parau de munte, fara
## canal navigabil. Fara efect cand `jump = true`.
@export var build_ships: bool = true
## Vaporul canalului navigabil; gol = corabia cu panze din kit. Vezi
## [member LiftBridgeHazard.ship_model] si vecinele lui.
@export_file("*.glb") var ship_model: String = ""
@export var ship_node: String = ""
@export var ship_scale: float = 1.0
@export var ship_draft: float = 0.0
@export var ship_bow_neg_z: bool = true
## Canalul nu sapa sub cota unei benzi secundare (`TrackBranch`) din raza ei.
## Opt-in: pe Alpii/Stromboli garda ar schimba terenul existent.
@export var respect_branch: bool = false

## Repunerea unei masini care a TRECUT deja golul nu are voie sa cada inapoi in
## el. [method Car.respawn] retrage masina cu 12-14 m pe ax, iar la o saritura
## cu gol de ~15 m o ratare chiar dupa aterizare (ejectare, blocaj) o punea
## exact deasupra golului: cadea pe malul de sub buza de aterizare si ramanea
## lipita de peretele soselei, deasupra cutiei [RespawnZone] (masurat pe Track17,
## Devkund: repusa la frac 0.886, buza la 0.888, [blocaj] pe RoadSides). Pornit,
## o repunere care pleaca de dincolo de buza de aterizare si s-ar retrage
## inapoi peste ea e oprita pe asfalt, la [constant Track.GAP_RESPAWN_CLEAR_M]
## dupa buza. Cine n-a trecut inca golul se repune ca inainte (si cade, si il
## prinde [RespawnZone] cu elanul ei). Oprit (implicit) = bit-identic.
@export var respawn_past_gap: bool = false

## Elanul sariturii, in metri inaintea buzei de desprindere, pe care AI-ul nu
## traverseaza PE LANGA o masina aflata alaturi (`AIController._avoid_line`):
## trece pe partea pe care e deja, nu pe cea „mai aproape de axa". Pe Devkund
## (Track17, seed 2) regula veche trimitea autobuzul de pe margine prin
## pompierii de langa el; frecate bot in bot, amandoua caroseriile grele au
## ajuns la buza cu 16-20 m/s in loc de ~28 si au cazut in golul de 16 m.
## Zero (implicit) = regula veche, bit-identic pe orice alt canal.
@export var ai_keep_side_run_m: float = 0.0

## Sapatura e o GROAPA CIRCULARA centrata pe taietura, nu o albie in lungul
## axei. Pentru gauri care exista doar ca sa se ascunda sub un asset rotund
## (cuva craterului de pe Stromboli): terenul coboara radial de la
## [member water_half] (fund plat) la [member water_half] + [member bank]
## (buza), iar in afara cercului plateul ramane neatins — o albie
## dreptunghiulara ar fi scos colturi de sapatura de sub marginea rotunda a
## asset-ului, oricum am fi potrivit-o. [member reach] si [member fade] nu
## participa: cercul isi e propriul capat.
@export var pit: bool = false

## Canalul e un VAD: albia si apa se construiesc la fel, dar soseaua NU se
## intrerupe — se trece prin apa, nu peste gol.
##
## Motivul e masurat, nu stilistic (Serengeti, POI C): un rau care taie drumul
## avea nevoie de o albie REALA (bolovanii trebuie sa intre pe jumatate in apa,
## spinarile de hipopotam trebuie sa iasa DEASUPRA ei), dar carosabilul trebuie
## sa ramana conducibil — gimmickul e apa de 30 cm care incetineste, nu o
## saritura. Fara steagul asta singurul mecanism de sapatura din pista
## ([method TrackSideSampler._carve_channel]) venea legat de golul din asfalt,
## iar [TerrainHollow] nu ajuta: e PLAFON, nu groapa, deci nu poate cobori
## terenul sub cota la care il aseaza soseaua.
##
## Cu `ford` pornit: se sapa albia, se aseaza suprafata de apa (deci si muchia
## apa/mal, fiindca patratele uscate se sar), si NU se construieste nici gol de
## sosea, nici trambulina, nici travee, nici [RespawnZone]. [member depth] si
## [member water_y_drop] raman parghiile — diferenta lor e cata apa ai pe drum,
## si ea trebuie tinuta mica (sub ~0.5 m) ca masina sa treaca.
@export var ford: bool = false

## Cati metri de apa stau PESTE cota asfaltului la vad.
##
## Numai pentru [member ford]. E cifra pe care o simte soferul: sub ~0.15 m apa
## abia se vede, peste ~0.5 m masina inoata. Brief-ul POI C cere 30 cm.
## Suprafata se aseaza la `cota drumului + water_over_road`, iar patul rezultat
## se sapa cu [code]TrackSideSampler.FORD_BED_SINK[/code] sub drum.
@export var water_over_road: float = 0.3

## Albie USCATA: aceeasi taietura, acelasi gol, aceeasi trambulina, dar FARA
## suprafata de apa. Pentru un uadi/o albie secata (Track19 monumentvalley,
## docs/track_briefs/monument_valley.md §3, „Saritura peste albie"), unde golul
## e prapastia, nu un rau.
##
## Pana la steagul asta un canal avea doua feluri de apa si niciunul uscat:
## `water_y_drop` pozitiv aducea suprafata proprie ([method
## Track._build_channel_water]), iar unul NEGATIV facea canalul „la nivelul
## marii" — adica tot apa, a grilei de tarm. Si ocolirea evidenta
## (`water_y_drop = -1` pe o tema fara mare) nu mergea: plasa [RespawnZone] a
## albiei se construieste in aceeasi bucla cu apa, deci canalul ramanea uscat SI
## fara repunere — cine rateaza aterizarea cadea pe nisip si ramanea acolo.
##
## Cu `dry` pornit: se sapa albia ([method TrackSideSampler._carve_channel]),
## golul si trambulina raman, [RespawnZone]-ul din albie ramane (zona incepe la
## `Track.CHANNEL_DRY_SURFACE_M` − 0.6 m peste fundul albiei, ca la un parau de
## 3 m adancime), si NU se mai construieste apa. Nici stropul, nici franarea in
## apa ([method Track.water_level_at]) nu mai vad canalul, iar [member
## water_y_drop] e ignorat. Se potriveste cu `jump = true`: podul mobil
## ([LiftBridgeHazard]) isi calculeaza plasa de cadere din cota apei, pe care o
## albie uscata n-o are. Turnurile si corabiile raman la steagurile lor
## ([member build_towers], [member build_ships]) si nu conteaza cu `jump`.
## Oprit (implicit) = bit-identic pe toate canalele existente.
@export var dry: bool = false

## Numele afisat in sonde si in mesaje de eroare.
@export var label: String = ""


func _ready() -> void:
	# Setter-ul nu ruleaza pentru valoarea implicita la instantiere — crucea ar
	# ramane la cei 0.25 m ai lui Marker3D si amprenta n-ar comunica nimic.
	# Aceeasi capcana ca la TerrainPeak.
	gizmo_extents = reach


## Declaratia, in formatul pe care il intoarce si `Track._channel_specs()`.
##
## `frac` se DERIVA din pozitia nodului, in coordonatele pistei — conteaza daca
## nodul e grupat sub ceva cu transformare proprie.
func to_spec(track: Node3D) -> Dictionary:
	var spec := {
		"gap": gap,
		"water_half": water_half,
		"bank": bank,
		"depth": depth,
		"reach": reach,
		"fade": fade,
		"jump": jump,
		"pit": pit,
		"ford": ford,
		"dry": dry,
		"flow_sign": flow_sign,
		"label": label if label != "" else name,
		"static_deck": static_deck,
		"deck_material_class": deck_material_class,
		"build_towers": build_towers,
		"build_ships": build_ships,
		"ship_model": ship_model,
		"ship_node": ship_node,
		"ship_scale": ship_scale,
		"ship_draft": ship_draft,
		"ship_bow_neg_z": ship_bow_neg_z,
		"respect_branch": respect_branch,
		"respawn_past_gap": respawn_past_gap,
		"ai_keep_side_run_m": ai_keep_side_run_m,
	}
	if ford:
		# Apa peste drum = drop NEGATIV fata de cota soselei. Steagul „canal la
		# nivelul marii" (drop < 0) nu se aplica la vad: acolo suprafata proprie
		# e obligatorie, altfel n-ar exista rau.
		spec["water_y_drop"] = -water_over_road
		spec["water_over_road"] = water_over_road
	elif dry:
		# Albie uscata: nicio cota de apa de declarat. Cheia lipseste cu buna
		# stiinta, ca nimic care citeste `water_y_drop` sa nu o ia drept apa.
		pass
	elif water_y_drop >= 0.0:
		spec["water_y_drop"] = water_y_drop
	return spec


## Pozitia nodului in coordonatele PISTEI (nu in lume, nu in spatiul parintelui).
func local_position(track: Node3D) -> Vector3:
	return track.to_local(global_position)
