extends Node
## Randeaza o pista si salveaza PNG in snapshots/. Ruleaza CU FEREASTRA
## (randarea nu merge headless); fereastra apare ~o secunda si se inchide singura.
##
##   --track=N   POZITIA din GameState.TRACK_SCENES (Dunele 0 · Okinawa 1 ·
##               Alpii 2 · Baikal 3 · Stromboli 4). Se accepta si numarul
##               scenei (--track=11 = Track11); un numar care nu e nici una,
##               nici alta opreste cu eroare, nu se retează tăcut.
##
##   --track=0                 ansamblu, de sus (ortografic)
##   --track=0 --frac=0.2      prim-plan inclinat la o fractie din traseu
##   --track=0 --frac=0.2 --driver
##                             POZA DE MASURARE (perspectiva). Vezi mai jos.
##   --track=0 --frac=0.2 --gamecam
##   --track=3 --eye=250,6,-118 --look=232,8,-165
##                             CAMERA LIBERA: ochi si punct privit, in metri
##                             de lume (x,y,z). Pentru ce nu se vede de pe
##                             sosea: viaductul din lateral, de pe gheata.
##                             vederea reala de JOC, cu parametrii curenti ai
##                             camerei de urmarire
##   --shishi-phase=0.72       (Kyoto) ceasul shishi-odoshi la fractia data din ciclu:
##                             0.02 sus, 0.72 aproape orizontal, 0.90 lovit.
##   --leaf-wear=N             (Kyoto) covorul de frunze cu N treceri simulate ale plutonului
##                             pe linia de cursa; `--no-leaves` = fara covor si fara frunze
##                             care cad (starea "inainte"); `--no-leaf-fall` = doar covorul.
##   --daruma-phase=0.15       (Kyoto) ceasul daruma-otoshi la fractia data din ciclul
##                             MARE (71 s): 0.15 = turn plin, ciocanul tras inapoi
##                             (telegraful); 0.16 = discul in mijlocul drumului;
##                             0.45 = turn scazut la 3 etaje. `--daruma-clock=S` da
##                             direct secunde (11.5 = discul la ~1/3 din drum).
##   --daruma-dist=120         (Kyoto) cu --gamecam: pune CAMERA la atatia metri pe
##                             axa, inaintea turnului (fractia se deduce, nu se ghiceste).
##   --track=0 --frac=0.5 --gamecam --route=1
##                             la fel, dar pe BANDA SECUNDARA cu indexul dat
##                             (1 = prima scurtatura, in ordinea din
##                             Track.routes); fractia e din lungimea benzii,
##                             nu din tur. Fara asta, o scurtatura se putea
##                             vedea doar din racorduri, de pe sosea.
##   --track=0 --landmark=2 [--dist=30]
##                             LANDMARK-ul cu id-ul cerut (`_LANDMARKS` din
##                             track.gd), vazut DE PE SOSEA, de la inaltimea
##                             camerei de urmarire. Fara el, singurul mod de a
##                             prinde un prop anume in cadru era sa ghicesti
##                             fractia, iar landmark-urile stau la 10-15 m
##                             lateral, deci ies din cadru la cea mai mica
##                             eroare. Poza asta e pentru VERIFICAREA unui
##                             asset, nu pentru compozitia pistei.
##   --dirt=0.2,0.4[;0.6,0.7]  pune intervale de DRUM DE PAMANT (`custom_dirt_ranges`)
##                             pe o pista cu asfalt, inainte sa se construiasca:
##                             asa se vede tranzitia asfalt/pamant fara sa
##                             editezi scena. Ex.: --track=0 --frac=0.2 --gamecam
##                             --dirt=0.2,0.4 prinde inceputul portiunii de pamant.
##   --train-at=0.55           muta ceasul trecerii de cale ferata la fractia
##                             ceruta din ciclu, ca trenul sa fie IN cadru la
##                             momentul capturii (implicit e parcat, invizibil)
##   --typhoon-at=0.12         la fel, pentru mini-typhoon: 0 = pe axa soselei,
##                             0.25 = la capatul maturarii, 0.12 = la jumatatea
##                             traversarii. Fara el, captura o prinde mereu pe
##                             mijlocul drumului si nu se vede niciodata trecerea.
##   --wave-at=0.30           la fel, pentru valul care spala soseaua: 0 = abia
##                             intrat in cadru dinspre larg, ~0.30 = pe axa
##                             soselei, peste ~0.60 = in larg, invizibil.
##   --bridge-at=0.24          la fel, pentru podul mobil: 0 = inchis, ~0.24 =
##                             travee sus cu corabia in gol. Fara el, captura
##                             prinde podul la inceputul ciclului, adica exact
##                             starea in care gimmick-ul nu se vede.
##   --rain=1                  FAZA DE PLOAIE (RainCycle, Fiordland) fortata
##                             la 1 (0 = uscat fortat): aprinde grupul
##                             `rain_falls` (cascadele de ploaie, altfel
##                             `visible = false`) si mediul de ploaie. Fara el,
##                             captura prinde mereu faza uscata.
##   --dusk=0.5                 CEASUL DE LUMINA (DuskCycle, Jodhpur) fortat la
##                             fractia data (0 = turul 1 auriu, 1 = turul 3,
##                             noapte cu artificii — docs/track_briefs/
##                             jodhpur.md §3/§4). Daca pista are deja un
##                             `DuskCycle` (grupul `dusk_cycle`), i se cheama
##                             `force_value()`; daca NU are (orice pista in
##                             afara de Jodhpur), Snapshot ADAUGA unul temporar
##                             — asa se poate testa ceasul pe piste existente
##                             INAINTE ca Track17 sa existe (memoria
##                             `sonda-masura-alt-obiect`: fara asta n-ai cum sa
##                             verifici ca parametrii chiar se misca, doar ca
##                             scriptul compileaza). Fara acest flag, o pista
##                             fara `DuskCycle` propriu ramane exact ca inainte
##                             (dusk=0, neatins).
##   --torrent-at=11.0         TORENTUL IN PULSURI (TorrentCycle, scurtatura
##                             Chasm): ceasul ciclului in secunde; 0 = CALM,
##                             7 = inceputul anuntului, 10 = inceputul pulsului
##   --rain-clock=2.5          la fel, dar prin CEAS (secunde de la inceputul
##                             ciclului RainCycle): 0-5 = telegraph (cerul se
##                             inchide, primele picaturi), 5-30 = ploaie,
##                             30-35 = zvantare. Pentru captura de telegraph.
##   --overdraw                randeaza cu Viewport.DEBUG_DRAW_OVERDRAW (fiecare
##                             strat desenat pe pixel aduna aceeasi cantitate):
##                             luminanta / luminanta unui singur strat = cate
##                             straturi are pixelul. Sufix `_overdraw` pe fisier.
##                             Dupa orice captura de joc se tiparesc si desenele
##                             / primitivele din cadru (RenderingServer).
##   --lava-stage=1            stadiul limbii de lava (Stromboli): 0 = turul 1,
##                             1 = poarta, 2 = zid. Implicit 0 — adica exact
##                             starea in care gimmick-ul nu se vede.
##   --balloon-at=0.62         cosurile care urca (BalloonHazard) la o fractie
##                             din ciclul lor (toate la aceeasi faza): ~0.29-0.57
##                             urca, ~0.60-0.64 MATURA banda, ~0.64-0.68 urca
##                             sa elibereze.
##   --cloud-at=5.0            NORUL din defileu (CloudRiseHazard, Machu
##                             Picchu) la N SECUNDE in ciclul lui (31 s;
##                             `phase` ignorat): 0-3.5 urca de sub banda,
##                             3.5-7.5 ACOPERA drumul, 7.5-10 se retrage,
##                             restul = ascuns. Fara el norul e in defileu.
##   --haboob-at=57.0          HABOOB-UL (HaboobHazard, Monument Valley) la N
##                             SECUNDE in ciclul lui (~101 s; `start_clock` si
##                             `phase` ignorate, ceasul INGHETAT): 0-25 telegraf
##                             (pacla creste, zidul se apropie), 25-80 traversare
##                             (zid plin), 80-95 risipire, 95-101 LINISTE (nimic
##                             pe ecran). Fara el zidul ruleaza de la `start_clock`
##                             (liniste la start).
##   --rim-at=T [--rim-hit]    BOLOVANUL DE PE BUZA (RimBoulderHazard, Track19, culoarul E)
##                             cu ceasul INGHETAT la T s din ciclul de 19 s. Cu `--car --rim-hit`
##                             masina sta pe punctul de impact, strivita + <=> inversat.
##   --no-haboob               scoate HaboobHazard din scena INAINTE de captura
##                             (cadrul de control fara zid, pentru A/B/overdraw).
##   --tuk-at=0.93,0.96[:-2.2] TUK-TUK-URI (Jodhpur) la fractiile date din
##                             bucla, pe banda STANGA (lat -2,2 = offsetul
##                             TrafficController; `:lat` il suprascrie per
##                             piesa). Snapshot nu porneste cursa, deci fara
##                             flag traficul nu apare in captura. Corpuri
##                             `Car` + tuktuk.tres, INGHETATE (on_start_grid),
##                             botul pe sensul de mers. Fara flag: nimic.
##   --cow=stand|lie           VACA din ulicioara (CowGate, Jodhpur D′)
##                             inghetata: `lie` culcata in gura (scurtatura
##                             inchisa), `stand` pe prag (deschisa). Fara
##                             flag: pe prag, ceasul nu ruleaza.
##   --bus-at=30               AUTOBUZUL de pe serpentine (BusHazard, Machu
##                             Picchu) la N SECUNDE de coborare pe curba lui
##                             (7 m/s => 30 s = 210 m de la capatul de sus),
##                             cu ceasul oprit pe durata pozei. Fara el e sus,
##                             ascuns — exact starea in care nu se vede.
##   --rope-load=2.6[,0.5]     PODUL DE FRANGHIE (RopeBridgeHazard, Machu
##                             Picchu): o masina-fantoma cu mass_factor-ul dat
##                             (Autobuz 2.6, sport 0.9) apasa tablierul la
##                             fractia u din pod (implicit 0.5 = mijloc), iar
##                             sageata e adusa direct la echilibru. Fara el
##                             podul e in repaus (0.5 m) si gimmick-ul nu se
##                             vede. Cu `--car`, masina e asezata PE tablierul
##                             afundat (nu la cota soselei) si isi lasa si ea
##                             greutatea.
##   --burner-at=0.05          arzatorul balonului (BurnerHazard) la o fractie
##                             din ciclul lui: 0.00-0.06 = telegraf (flacara),
##                             0.06-0.10 = sufla (praf), restul = stins.
##   --door-at=0.70            usa de piatra (SlidingHazard.Motion.USA) la o
##                             fractie din ciclul ei: 0 = abia deschisa (in
##                             nisa), ~0.53 = la jumatatea rostogolirii spre
##                             axa, 0.60-0.84 = INCHISA pe banda.
##   --salute-at=5.0           TUNURILE DE SALUT (BastionTheatre, Jodhpur POI F)
##                             la N secunde in ciclul de 31 s (salvele trag la
##                             4,0 / 4,8 / 5,6 / 6,4 / 7,2 s). Ceas inghetat.
##   --zip-at=4.0              TIROLIANA: figura pe cablu la N secunde (ciclu
##                             23 s, cursa 0..9 s). Ceas inghetat.
##   --fireworks-at=1.0        ARTIFICIILE la N secunde, APRINSE indiferent de
##                             dusk (lumina o da `--dusk=1`). Ceas inghetat.
##   --rock-at=3.5             bolovanii cu traseu, la N SECUNDE de la
##                             desprindere (nu fractie: traseele au lungimi
##                             diferite). Se SIMULEAZA cadru cu cadru de la 0,
##                             fiindca lipirea de teren si saltul de pe buza
##                             sunt stare, nu functie de timp. Ceasul din
##                             hazard (`_cross_time`) spune cand e piatra
##                             deasupra soselei; sonda il tipareste.
##   --herd-at=4.0             RAUL DE GNU (HerdHazard, Serengeti) la N SECUNDE
##                             in ciclul pulsului (puls 8 s + gol 7 s = 15 s;
##                             `_time` absolut, fara `phase`). Capul pulsului
##                             e pe axa soselei la 0; blocul de 52 m vine din
##                             spate, deci 3-8 = drumul PLIN pe toate benzile,
##                             9-14 = culoar liber. Turma se calculeaza in
##                             _physics_process, iar captura o ingheata —
##                             fara asta pozele arata pozitia de la _ready.
##   --hippo-at=0.12           hipopotamii (HippoHazard) la o fractie din ciclul
##                             lor (20 s implicit; `phase` ignorat, toti la
##                             aceeasi faza): 0.05-0.07 = urca, 0.07-0.17 =
##                             SUS pe banda, 0.17-0.21 = se scufunda, restul
##                             = sub albie, invizibili.
##   --vitrina=<stem>           instantiaza piesa de kit <stem>.glb (cautata in
##                             _VITRINA_MODEL_PATHS din acest fisier) prin
##                             ACEEASI cale prin care DecorManual pune nodurile
##                             din Track16.tscn (WorldProp deasupra instantei
##                             GLB, ca sa primeasca clasa de textura si
##                             coliziunea din world_prop.gd), asezata pe teren
##                             la fractia din --frac, la --vitrina-side metri
##                             lateral pe DREAPTA fata de axa, cu yaw-ul din
##                             --vitrina-yaw fata de directia drumului. Camera
##                             e cea de joc (--gamecam implicit), cu masina
##                             jucatorului in cadru ca scara de referinta
##                             (4,0 x 1,8 x 1,5 m). Iese in
##                             snapshots/vitrina_<stem>.png. Pentru piese cu mai
##                             multe noduri numite (fiordland_horizon,
##                             tree_avalanche) instantiaza fisierul intreg —
##                             nodurile ies asezate unele langa altele, exact
##                             cum sta GLB-ul.
##   --vitrina-side=10          distanta laterala (m), implicit 10; mareste
##                             pentru piesele mari (stirling_ledge,
##                             fiordland_horizon, lodge, coach_fiordland,
##                             cruise_boat, torrent_chute).
##   --vitrina-yaw=0            rotatie (grade) fata de directia drumului.
##   --vitrina-anim=Open        forteaza AnimationPlayer-ul gasit in piesa pe
##                             clipul dat si il seeks la ULTIMUL cadru (poza
##                             deschisa/intinsa) inainte de captura. Piesa
##                             asezata prin --vitrina e statica (WorldProp),
##                             nu un PathMover, deci fara asta un model cu
##                             AnimationPlayer (kea: Idle/Open) ramane in bind
##                             pose. Sufixul intra in numele fisierului:
##                             vitrina_kea_open.png.
##   --cross-at=8.0            obstacolele care TRAVERSEAZA (SlidingHazard
##                             Motion.TRAVERSARE: elefantii din Serengeti,
##                             cireada) la N SECUNDE absolute in ciclul lor
##                             (`phase` intra in socoteala, ca in joc). Un ciclu
##                             = 2 x (5 s parcat + 1,2 s telegraf + traversare);
##                             sonda tipareste pentru fiecare unde e si daca e
##                             pe carosabil.
##   --cross-phase=0.25        (cu --cross-at) faza ciclului de mers, 0..1, pentru
##                             modelele CU SCHELET (caii din Monument Valley:
##                             Walk/Idle): animatia aleasa dupa viteza reala,
##                             pusa pe faza data si INGHETATA. Fara el, fizica
##                             e oprita cu delta 0 si caii raman in poza de repaus.
##
## Vederile ortografice de sus turtesc tot ce e vertical, deci mint despre
## densitatea decorului de pe margine: ceva ce arata presarat de sus poate
## strange cadrul perfect din masina, si invers.
##
## ############################################################################
## --driver ESTE UN INSTRUMENT DE MASURA, NU O CAPTURA DE ECRAN.
##
## Parametrii lui (MEASURE_*) sunt INGHETATI. Sunt etalonul fata de care se
## compara deviatia de luminanta pe suprafete intre build-uri — vezi
## tools/measure_surface.gd si style_bible §14. Daca cineva ii "sincronizeaza"
## cu valorile curente ale camerei, toate cifrele de sigma din istoricul de
## PR-uri devin fara sens si nu mai stim daca lumea s-a imbunatatit sau doar
## s-a mutat camera.
##
## Pentru compozitie si pentru "cum arata cand joc" foloseste --gamecam, care
## citeste chiar constantele lui ChaseCamera.
## ############################################################################

## Poza de MASURARE. Nu se schimba niciodata.
const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2

## Tabelul de rezolvare stem -> cale .glb pentru --vitrina. Contine cele 31 de
## piese native Fiordland (assets/models/fiordland/, pe subfoldere) plus cele
## 8 reuse-uri inregistrate in Track16.tscn (fern_cluster, nerpa_seal,
## tree_fern, moss_boulder_a/b/c, chevron_sign, wooden_pier) — vezi
## docs/asset_briefs/fiordland_inventory.md.
const _VITRINA_MODEL_PATHS := {
	"kea": "res://assets/models/fiordland/animals/kea.glb",
	"penguin_tawaki": "res://assets/models/fiordland/animals/penguin_tawaki.glb",
	"cafe_shed": "res://assets/models/fiordland/buildings/cafe_shed.glb",
	"lodge": "res://assets/models/fiordland/buildings/lodge.glb",
	"tree_avalanche": "res://assets/models/fiordland/effects/tree_avalanche.glb",
	"beech_a": "res://assets/models/fiordland/plants/beech_a.glb",
	"beech_b": "res://assets/models/fiordland/plants/beech_b.glb",
	"beech_c": "res://assets/models/fiordland/plants/beech_c.glb",
	"beech_dead": "res://assets/models/fiordland/plants/beech_dead.glb",
	"rata_tree": "res://assets/models/fiordland/plants/rata_tree.glb",
	"tussock_clump": "res://assets/models/fiordland/plants/tussock_clump.glb",
	"driftwood": "res://assets/models/fiordland/props/driftwood.glb",
	"kayak_a": "res://assets/models/fiordland/props/kayak_a.glb",
	"kayak_b": "res://assets/models/fiordland/props/kayak_b.glb",
	"luggage_container": "res://assets/models/fiordland/props/luggage_container.glb",
	"road_sign_blank": "res://assets/models/fiordland/props/road_sign_blank.glb",
	"snow_pole": "res://assets/models/fiordland/props/snow_pole.glb",
	"stump": "res://assets/models/fiordland/props/stump.glb",
	"traffic_light_pole": "res://assets/models/fiordland/props/traffic_light_pole.glb",
	"chasm_rock": "res://assets/models/fiordland/rocks/chasm_rock.glb",
	"fiordland_horizon": "res://assets/models/fiordland/rocks/fiordland_horizon.glb",
	"guard_rock": "res://assets/models/fiordland/rocks/guard_rock.glb",
	"scree_slab": "res://assets/models/fiordland/rocks/scree_slab.glb",
	"stirling_ledge": "res://assets/models/fiordland/rocks/stirling_ledge.glb",
	"torrent_chute": "res://assets/models/fiordland/rocks/torrent_chute.glb",
	"chasm_bridge_rail": "res://assets/models/fiordland/structures/chasm_bridge_rail.glb",
	"heli_pad": "res://assets/models/fiordland/structures/heli_pad.glb",
	"wharf": "res://assets/models/fiordland/structures/wharf.glb",
	"bush_plane": "res://assets/models/fiordland/vehicles/bush_plane.glb",
	"coach_fiordland": "res://assets/models/fiordland/vehicles/coach_fiordland.glb",
	"cruise_boat": "res://assets/models/fiordland/vehicles/cruise_boat.glb",
	# --- reuse, inregistrate in Track16.tscn ---
	"fern_cluster": "res://assets/models/plants/fern_cluster.glb",
	"nerpa_seal": "res://assets/models/baikal/props/nerpa_seal.glb",
	"tree_fern": "res://assets/models/machupicchu/plants/tree_fern.glb",
	"moss_boulder_a": "res://assets/models/machupicchu/rocks/moss_boulder_a.glb",
	"moss_boulder_b": "res://assets/models/machupicchu/rocks/moss_boulder_b.glb",
	"moss_boulder_c": "res://assets/models/machupicchu/rocks/moss_boulder_c.glb",
	"chevron_sign": "res://assets/models/signs/chevron_sign.glb",
	"wooden_pier": "res://assets/models/structures/wooden_pier.glb",
	# --- Jodhpur (Track17), cele 50 de piese ale kitului (fundatia POI) ---
	# `euphorbia` are acelasi stem ca piesa Serengeti; cheia de vitrina e
	# `jodhpur_euphorbia` (WorldProp decide clasa dupa FISIER, nu dupa cheie).
	"baraat_horse": "res://assets/models/jodhpur/animals/baraat_horse.glb",
	"black_kite_bird": "res://assets/models/jodhpur/animals/black_kite_bird.glb",
	"langur": "res://assets/models/jodhpur/animals/langur.glb",
	"peacock_closed": "res://assets/models/jodhpur/animals/peacock_closed.glb",
	"peacock_fanned": "res://assets/models/jodhpur/animals/peacock_fanned.glb",
	"zebu_cow": "res://assets/models/jodhpur/animals/zebu_cow.glb",
	"blue_house_a": "res://assets/models/jodhpur/buildings/blue_house_a.glb",
	"blue_house_b": "res://assets/models/jodhpur/buildings/blue_house_b.glb",
	"blue_house_c": "res://assets/models/jodhpur/buildings/blue_house_c.glb",
	"blue_house_d": "res://assets/models/jodhpur/buildings/blue_house_d.glb",
	"blue_house_e": "res://assets/models/jodhpur/buildings/blue_house_e.glb",
	"ghanta_ghar": "res://assets/models/jodhpur/buildings/ghanta_ghar.glb",
	"haveli_facade": "res://assets/models/jodhpur/buildings/haveli_facade.glb",
	"jodhpur_euphorbia": "res://assets/models/jodhpur/plants/euphorbia.glb",
	"khejri_tree": "res://assets/models/jodhpur/plants/khejri_tree.glb",
	"neem_tree": "res://assets/models/jodhpur/plants/neem_tree.glb",
	"baraat_band": "res://assets/models/jodhpur/props/baraat_band.glb",
	"chai_stall": "res://assets/models/jodhpur/props/chai_stall.glb",
	"diya": "res://assets/models/jodhpur/props/diya.glb",
	"floating_diya": "res://assets/models/jodhpur/props/floating_diya.glb",
	"marigold_garland": "res://assets/models/jodhpur/props/marigold_garland.glb",
	"rampart_cannon": "res://assets/models/jodhpur/props/rampart_cannon.glb",
	"rooftop_clutter": "res://assets/models/jodhpur/props/rooftop_clutter.glb",
	"rooftop_tank": "res://assets/models/jodhpur/props/rooftop_tank.glb",
	"spice_sacks": "res://assets/models/jodhpur/props/spice_sacks.glb",
	"stall_canopy_a": "res://assets/models/jodhpur/props/stall_canopy_a.glb",
	"stall_canopy_b": "res://assets/models/jodhpur/props/stall_canopy_b.glb",
	"stall_canopy_c": "res://assets/models/jodhpur/props/stall_canopy_c.glb",
	"textile_strip": "res://assets/models/jodhpur/props/textile_strip.glb",
	"thela_cart": "res://assets/models/jodhpur/props/thela_cart.glb",
	"zipline_rider": "res://assets/models/jodhpur/props/zipline_rider.glb",
	"jodhpur_horizon": "res://assets/models/jodhpur/rocks/jodhpur_horizon.glb",
	"rhyolite_boulder_a": "res://assets/models/jodhpur/rocks/rhyolite_boulder_a.glb",
	"rhyolite_boulder_b": "res://assets/models/jodhpur/rocks/rhyolite_boulder_b.glb",
	"rhyolite_boulder_c": "res://assets/models/jodhpur/rocks/rhyolite_boulder_c.glb",
	"rock_slab": "res://assets/models/jodhpur/rocks/rock_slab.glb",
	"fort_bastion": "res://assets/models/jodhpur/structures/fort_bastion.glb",
	"fort_gate_fateh": "res://assets/models/jodhpur/structures/fort_gate_fateh.glb",
	"fort_gate_jai": "res://assets/models/jodhpur/structures/fort_gate_jai.glb",
	"fort_gate_loha": "res://assets/models/jodhpur/structures/fort_gate_loha.glb",
	"fort_wall_segment": "res://assets/models/jodhpur/structures/fort_wall_segment.glb",
	"fort_wall_turret": "res://assets/models/jodhpur/structures/fort_wall_turret.glb",
	"jaswant_thada": "res://assets/models/jodhpur/structures/jaswant_thada.glb",
	"market_gate": "res://assets/models/jodhpur/structures/market_gate.glb",
	"palace_facade_a": "res://assets/models/jodhpur/structures/palace_facade_a.glb",
	"palace_facade_b": "res://assets/models/jodhpur/structures/palace_facade_b.glb",
	"stepwell_corner": "res://assets/models/jodhpur/structures/stepwell_corner.glb",
	"stepwell_flight_module": "res://assets/models/jodhpur/structures/stepwell_flight_module.glb",
	"stepwell_pavilion": "res://assets/models/jodhpur/structures/stepwell_pavilion.glb",
	"tuktuk": "res://assets/models/jodhpur/vehicles/tuktuk.glb",
}

func _vec3(text: String) -> Vector3:
	var p := text.split(",")
	if p.size() != 3:
		return Vector3.ZERO
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func _ready() -> void:
	var track_index := 0
	var zoom_frac := -1.0 # >= 0: prim-plan la fractia respectiva din traseu
	var span_at := -1.0   # >= 0: faza pasajului rotativ (0 = deschis)
	var zoom_size := 60.0
	var driver_view := false
	var rain_force := -1.0 # >= 0: RainCycle.force_factor() dupa doua cadre
	var rain_clock := -1.0 # >= 0: RainCycle.force_clock() dupa doua cadre
	var dusk_force := -1.0 # >= 0: DuskCycle.force_value() dupa doua cadre
	var torrent_at := -1.0 # >= 0: TorrentCycle.force_clock() (secunde in ciclu)
	var shishi_phase := -1.0 # >= 0: ShishiOdoshiHazard.force_clock(faza * ciclu), faza 0..1
	var daruma_phase := -1.0 # >= 0: DarumaOtoshiHazard.force_clock(faza * ciclu mare)
	var daruma_clock := -1.0 # >= 0: la fel, direct in secunde
	var daruma_dist := -1.0 # > 0: camera de joc la atatia metri inaintea turnului
	var leaf_passes := -1 # >= 0: LeafCarpet cu N treceri simulate ale plutonului; -2 = covor si frunze OFF
	var leaf_fall := true # --no-leaf-fall: stinge doar frunzele care cad
	var shishi_backdrop := false # SONDA: panou verde inchis in spatele tubului (simuleaza padurea)
	var overdraw := false
	# --cine: dupa captura, listeaza CE obiect cade pe fiecare coloana de ecran.
	# Sonda de silueta raporteaza conuri dupa X; asta spune al cui e conul.
	var cine := false
	var hide_terrain := false
	var no_fog := false
	var game_cam := false
	## --cave: aplica presetul si intunericul celei mai apropiate [CameraZone].
	##
	## Fara el, orice captura din subteran MINTE. Zona se aprinde cand masina
	## jucatorului intra in ea, iar Snapshot nu instantiaza nicio masina — deci
	## sala apare cu ambientul si ceata de la suprafata, adica luminata de
	## soarele de zori. Exact asa a iesit prima runda a POI-ului F: o hala
	## portocalie in loc de o caverna. Acelasi motiv pentru care exista
	## `--train-at` si `--rock-at`: ce are ceas sau declansator trebuie ADUS in
	## starea in care il vede jucatorul, altfel poza arata alt joc.
	var cave_view := false
	var free_cam := false
	var eye_pos := Vector3.ZERO
	var look_pos := Vector3.ZERO
	var landmark_id := -1
	var landmark_dist := 30.0
	var train_at := -1.0
	var bridge_at := -1.0
	var typhoon_at := -1.0
	var wave_at := -1.0
	var dirt_ranges: Array[Vector2] = []
	var rock_at := -1.0
	var avalanche_at := -1.0
	var door_at := -1.0
	var herd_at := -1.0
	var hippo_at := -1.0
	var rope_load := -1.0
	var rope_u := 0.5
	var cloud_at := -1.0
	var haboob_at := -1.0
	var no_haboob := false
	var rim_at := -1.0
	var rim_hit := false
	var bus_at := -1.0
	var tuk_at := ""
	var cow_mode := ""
	var cross_at := -1.0
	var cross_phase := 0.0
	var burner_at := -1.0
	# Teatrul bastionului (Jodhpur, POI F): ceasurile BastionTheatre, inghetate.
	var salute_at := -1.0
	var zip_at := -1.0
	var fireworks_at := -1.0
	var balloon_at := -1.0
	var lava_stage := -1
	var route_idx := 0
	var hide_node := ""
	# --car: masina jucatorului (Muscle) INGHETATA pe punctul de focus, ca in
	# cadrul de joc — referintele de diorama au masina in prim-plan, iar o
	# captura fara ea compara un peisaj cu o scena. Fara fizica (on_start_grid).
	var show_car := false
	var car_player := false
	var car_data_name := "muscle"
	# --wipers-demo: instantiaza WindshieldWipers (brief Fiordland pasul 4) si
	# il umple cu N picaturi FORTATE pentru o captura de verificare — Race nu
	# ruleaza aici (Snapshot nu porneste o cursa), deci nu exista alt mod de-a
	# vedea overlay-ul decat sa-l declansezi manual.
	var wipers_demo := -1
	# --vitrina=<stem>: instantiaza piesa de kit <stem>.glb (cautata in
	# _VITRINA_MODEL_PATHS) prin ACEEASI cale prin care DecorManual pune
	# nodurile din Track16.tscn — un Node3D cu WorldProp deasupra unei
	# instante de PackedScene, ca sa primeasca clasa de textura si coliziunea
	# din world_prop.gd — asezata pe teren, lateral fata de axa. Camera de joc
	# (--gamecam implicit) prinde si masina jucatorului in cadru, ca sa aiba
	# piesa o scara de referinta (4,0 x 1,8 x 1,5 m).
	var vitrina_stem := ""
	var vitrina_side := 10.0
	var vitrina_yaw := 0.0
	# --vitrina-anim=<clip>: forteaza un AnimationPlayer gasit in piesa pe
	# clipul dat si il seeks la ULTIMUL cadru (poza intinsa/deschisa) inainte
	# de captura. Piesa asezata prin --vitrina e statica (WorldProp), nu un
	# PathMover — fara asta, un model cu AnimationPlayer (kea: Idle/Open)
	# ramane in bind pose brut, care nu e starea din joc (vezi inventarul:
	# bind pose = aripi intinse, contrar intentiei).
	var vitrina_anim := ""
	# --vitrina-ahead=<m>: piesa se aseaza si INAINTE pe drum, nu doar
	# lateral — piesele mari (portile de 32,7 m, fatadele de 40-45 m) puse
	# langa masina ies din cadrul camerei de joc (jumatate de cadru ~50 grade).
	var vitrina_ahead := 0.0
	var vitrina_step := 8.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--vitrina="):
			vitrina_stem = arg.trim_prefix("--vitrina=")
			continue
		if arg.begins_with("--vitrina-side="):
			vitrina_side = float(arg.trim_prefix("--vitrina-side="))
			continue
		if arg.begins_with("--vitrina-yaw="):
			vitrina_yaw = float(arg.trim_prefix("--vitrina-yaw="))
			continue
		if arg.begins_with("--vitrina-anim="):
			vitrina_anim = arg.trim_prefix("--vitrina-anim=")
		if arg.begins_with("--vitrina-ahead="):
			vitrina_ahead = float(arg.trim_prefix("--vitrina-ahead="))
			continue
		if arg.begins_with("--vitrina-step="):
			vitrina_step = float(arg.trim_prefix("--vitrina-step="))
			continue
		if arg == "--car":
			show_car = true
			continue
		# Stopurile si farurile (CarLights): `--brake` aprinde stopurile ca la
		# franare, `--car-player` face masina JUCATORUL (farul real, optiunea D,
		# daca GameState.real_headlight), `--car-data=taxi` alege presetarea.
		if arg == "--brake":
			CarLights.force_brake = true
			continue
		if arg == "--car-player":
			car_player = true
			continue
		if arg.begins_with("--car-data="):
			car_data_name = arg.trim_prefix("--car-data=")
			continue
		if arg.begins_with("--wipers-demo="):
			wipers_demo = int(arg.trim_prefix("--wipers-demo="))
			continue
		elif arg == "--wipers-demo":
			wipers_demo = 24
			continue
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--span-at="):
			span_at = float(arg.trim_prefix("--span-at="))
		elif arg.begins_with("--frac="):
			zoom_frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--hide="):
			hide_node = arg.trim_prefix("--hide=")
		elif arg.begins_with("--size="):
			zoom_size = float(arg.trim_prefix("--size="))
		elif arg.begins_with("--landmark="):
			landmark_id = int(arg.trim_prefix("--landmark="))
		elif arg.begins_with("--dist="):
			landmark_dist = float(arg.trim_prefix("--dist="))
		elif arg.begins_with("--train-at="):
			train_at = float(arg.trim_prefix("--train-at="))
		elif arg.begins_with("--bridge-at="):
			bridge_at = float(arg.trim_prefix("--bridge-at="))
		elif arg.begins_with("--typhoon-at="):
			typhoon_at = float(arg.trim_prefix("--typhoon-at="))
		elif arg.begins_with("--wave-at="):
			wave_at = float(arg.trim_prefix("--wave-at="))
		elif arg.begins_with("--dirt="):
			for seg in arg.trim_prefix("--dirt=").split(";"):
				var ab := seg.split(",")
				if ab.size() == 2:
					dirt_ranges.append(Vector2(float(ab[0]), float(ab[1])))
		elif arg.begins_with("--daruma-phase="):
			daruma_phase = float(arg.trim_prefix("--daruma-phase="))
		elif arg.begins_with("--daruma-clock="):
			daruma_clock = float(arg.trim_prefix("--daruma-clock="))
		elif arg.begins_with("--daruma-dist="):
			daruma_dist = float(arg.trim_prefix("--daruma-dist="))
		elif arg.begins_with("--leaf-wear="):
			leaf_passes = int(arg.trim_prefix("--leaf-wear="))
		elif arg == "--no-leaves":
			leaf_passes = -2
		elif arg == "--no-leaf-fall":
			leaf_fall = false
		elif arg == "--shishi-backdrop":
			shishi_backdrop = true
		elif arg.begins_with("--shishi-phase="):
			shishi_phase = float(arg.trim_prefix("--shishi-phase="))
		elif arg.begins_with("--rock-at="):
			rock_at = float(arg.trim_prefix("--rock-at="))
		elif arg.begins_with("--avalanche-at="):
			avalanche_at = float(arg.trim_prefix("--avalanche-at="))
		elif arg.begins_with("--door-at="):
			door_at = float(arg.trim_prefix("--door-at="))
		elif arg.begins_with("--herd-at="):
			herd_at = float(arg.trim_prefix("--herd-at="))
		elif arg.begins_with("--hippo-at="):
			hippo_at = float(arg.trim_prefix("--hippo-at="))
		elif arg.begins_with("--cloud-at="):
			cloud_at = float(arg.trim_prefix("--cloud-at="))
		elif arg.begins_with("--haboob-at="):
			haboob_at = float(arg.trim_prefix("--haboob-at="))
		elif arg == "--no-haboob":
			no_haboob = true
		elif arg.begins_with("--rim-at="):
			rim_at = float(arg.trim_prefix("--rim-at="))
		elif arg == "--rim-hit":
			rim_hit = true
		elif arg.begins_with("--bus-at="):
			bus_at = float(arg.trim_prefix("--bus-at="))
		elif arg.begins_with("--tuk-at="):
			tuk_at = arg.trim_prefix("--tuk-at=")
		elif arg.begins_with("--cow="):
			cow_mode = arg.trim_prefix("--cow=")
		elif arg.begins_with("--rope-load="):
			var parts := arg.trim_prefix("--rope-load=").split(",")
			rope_load = float(parts[0])
			if parts.size() > 1:
				rope_u = float(parts[1])
		elif arg.begins_with("--cross-at="):
			cross_at = float(arg.trim_prefix("--cross-at="))
		elif arg.begins_with("--cross-phase="):
			cross_phase = float(arg.trim_prefix("--cross-phase="))
		elif arg.begins_with("--burner-at="):
			burner_at = float(arg.trim_prefix("--burner-at="))
		elif arg.begins_with("--balloon-at="):
			balloon_at = float(arg.trim_prefix("--balloon-at="))
		elif arg.begins_with("--lava-stage="):
			lava_stage = int(arg.trim_prefix("--lava-stage="))
		elif arg.begins_with("--route="):
			route_idx = int(arg.trim_prefix("--route="))
		elif arg == "--cave":
			cave_view = true
		elif arg.begins_with("--eye="):
			eye_pos = _vec3(arg.trim_prefix("--eye="))
			free_cam = true
		elif arg.begins_with("--look="):
			look_pos = _vec3(arg.trim_prefix("--look="))
		elif arg == "--cine":
			cine = true
			driver_view = true
		elif arg == "--driver":
			driver_view = true
		elif arg == "--gamecam":
			driver_view = true
			game_cam = true
		elif arg == "--no-fog":
			# Diagnostic: stinge ceata de adancime. Raspunde la intrebarea
			# „geometria departata lipseste, sau doar e inghitita de ceata?" —
			# doua defecte cu leacuri opuse (populare vs. reglaj de atmosfera).
			no_fog = true
		elif arg.begins_with("--rain="):
			rain_force = float(arg.trim_prefix("--rain="))
		elif arg.begins_with("--rain-clock="):
			rain_clock = float(arg.trim_prefix("--rain-clock="))
		elif arg.begins_with("--dusk="):
			dusk_force = float(arg.trim_prefix("--dusk="))
		elif arg.begins_with("--salute-at="):
			salute_at = float(arg.trim_prefix("--salute-at="))
		elif arg.begins_with("--zip-at="):
			zip_at = float(arg.trim_prefix("--zip-at="))
		elif arg.begins_with("--fireworks-at="):
			fireworks_at = float(arg.trim_prefix("--fireworks-at="))
		elif arg.begins_with("--torrent-at="):
			torrent_at = float(arg.trim_prefix("--torrent-at="))
		elif arg == "--overdraw":
			overdraw = true
		elif arg == "--no-terrain":
			# Diagnostic: ascunde panza de teren, ca sa se vada ce e SUB ea.
			# „Exista in scena" si „se vede in cadru" sunt intrebari diferite —
			# cu terenul stins se afla instant daca o geometrie lipseste sau
			# doar e acoperita.
			hide_terrain = true
	if vitrina_stem != "":
		# --vitrina implica vederea de joc (masina in cadru ca scara) si o
		# masina prezenta, exact ca --gamecam --car; poate fi suprascris
		# explicit (--driver fara --gamecam) daca cineva vrea poza inghetata.
		driver_view = true
		if not ("--driver" in OS.get_cmdline_user_args()):
			game_cam = true
		show_car = true
	if driver_view and zoom_frac < 0.0:
		zoom_frac = 0.0
	# `--track=` accepta si pozitia din lista (Stromboli = 4), si numarul
	# scenei (Track11 = 11) — vezi GameState.resolve_track_index. Inainte era
	# un clampi() tacut, care transforma un numar gresit in alta pista si o
	# captura de "verificare" intr-un fals pozitiv.
	var resolved := GameState.resolve_track_index(track_index)
	if resolved < 0:
		push_error("snapshot: --track=%d nu e nici pozitie in lista (0..%d), nici numar de pista din lista. Vezi GameState.TRACK_SCENES."
			% [track_index, GameState.TRACK_SCENES.size() - 1])
		get_tree().quit(1)
		return
	track_index = resolved
	print("snapshot: pista %s" % GameState.track_label(track_index))

	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	if not dirt_ranges.is_empty():
		# Inainte de add_child: rebuild() ruleaza in _ready si citeste intervalele.
		if "custom_dirt_ranges" in track:
			track.set("custom_dirt_ranges", dirt_ranges)
			print("--dirt: %s" % [dirt_ranges])
		else:
			push_error("snapshot: --dirt cere o pista TrackFromPath (custom_dirt_ranges)")
	add_child(track)
	if no_fog:
		var envs := track.find_children("*", "WorldEnvironment", true, false)
		for e in envs:
			var we := e as WorldEnvironment
			if we.environment != null:
				we.environment.fog_enabled = false
		print("--no-fog: ceata stinsa pe %d WorldEnvironment" % envs.size())
	if hide_terrain:
		var tb := track.get_node_or_null("TerrainBody")
		if tb != null:
			for ch in tb.get_children():
				if ch is MeshInstance3D:
					(ch as MeshInstance3D).visible = false
	if "--smooth" in OS.get_cmdline_user_args():
		_smooth_organics(track)
	if train_at >= 0.0:
		_set_train_phase(track, train_at)
	if door_at >= 0.0:
		await _set_door_phase(track, door_at)
	if herd_at >= 0.0:
		await _set_herd_time(track, herd_at)
	if hippo_at >= 0.0:
		await _set_hippo_phase(track, hippo_at)
	if rope_load >= 0.0:
		await _set_rope_load(track, rope_load, rope_u)
	if cloud_at >= 0.0:
		await _set_cloud_time(track, cloud_at)
	if no_haboob:
		await _remove_haboob(track)
	elif haboob_at >= 0.0:
		await _set_haboob_time(track, haboob_at)
	if rim_at >= 0.0:
		await _set_rim_time(track, rim_at)
	if bus_at >= 0.0:
		await _set_bus_time(track, bus_at)
	if tuk_at != "":
		_place_tuktuks(track, tuk_at)
	if cow_mode != "":
		await _set_cow(track, cow_mode)
	if cross_at >= 0.0:
		await _set_cross_time(track, cross_at, cross_phase)
	if burner_at >= 0.0:
		await _set_burner_phase(track, burner_at)
	if balloon_at >= 0.0:
		await _set_balloon_phase(track, balloon_at)
	if bridge_at >= 0.0:
		_set_bridge_phase(track, bridge_at)
	if span_at >= 0.0:
		_set_span_phase(track, span_at)
	if typhoon_at >= 0.0:
		_set_typhoon_phase(track, typhoon_at)
	if wave_at >= 0.0:
		_set_wave_phase(track, wave_at)
	if rock_at >= 0.0:
		# Metronomul eruptiei isi resincronizeaza bombele AMANAT (dupa ce
		# pista le construieste) si le-ar calca ceasul pus de --rock-at:
		# captura ar prinde bolovanii unde i-a asezat pulsul, nu simularea.
		# Cu grupul golit inainte sa ruleze resync-ul amanat, ceasul ramane
		# al capturii.
		for child in track.get_children():
			if child is EruptionCycle:
				(child as EruptionCycle).hazard_group = &""
		await _set_rock_time(track, rock_at)
	if avalanche_at >= 0.0:
		await _set_avalanche_time(track, avalanche_at)
	# Faza de ploaie (Fiordland). `RainCycle._collect` e amanat cu
	# `call_deferred`, deci `force_factor()` chemat in acelasi cadru ar ateriza
	# pe un nod fara pista (acelasi bug platit de ProbeRace `--rain=`): doua
	# cadre, apoi fortarea.
	if rain_force >= 0.0 or rain_clock >= 0.0:
		await get_tree().process_frame
		await get_tree().process_frame
		var cycles := 0
		for node in get_tree().get_nodes_in_group(&"rain_cycle"):
			if rain_clock >= 0.0 and node.has_method("force_clock"):
				node.call("force_clock", rain_clock)
				cycles += 1
			elif node.has_method("force_factor"):
				node.call("force_factor", rain_force)
				cycles += 1
		if rain_clock >= 0.0:
			print("--rain-clock=%.2f: %d RainCycle fortate" % [rain_clock, cycles])
		else:
			print("--rain=%.1f: %d RainCycle fortate" % [rain_force, cycles])
	# Ceasul de lumina (Jodhpur, DuskCycle). Doua cadre, acelasi motiv ca
	# ploaia (_collect.call_deferred() in DuskCycle._ready): fara asteptare,
	# force_value() ar cadea pe un nod care inca n-a apucat sa-si gaseasca
	# Environment-ul/soarele. DACA pista n-are niciun DuskCycle (orice pista
	# in afara de Jodhpur), Snapshot adauga unul TEMPORAR direct pe track --
	# asa se poate verifica ceasul pe piste existente inainte ca Track17 sa
	# existe (memoria sonda-masura-alt-obiect: fara asta n-ai cum sa dovedesti
	# ca parametrii chiar se misca).
	if dusk_force >= 0.0:
		await get_tree().process_frame
		await get_tree().process_frame
		var dusk_cycles := get_tree().get_nodes_in_group(&"dusk_cycle")
		if dusk_cycles.is_empty():
			var dc: Node = (preload("res://scenes/hazards/dusk_cycle.gd") as GDScript).new()
			track.add_child(dc)
			await get_tree().process_frame
			await get_tree().process_frame
			dusk_cycles = get_tree().get_nodes_in_group(&"dusk_cycle")
			print("--dusk=%.2f: pista fara DuskCycle propriu, adaugat unul temporar" % dusk_force)
		for node in dusk_cycles:
			if node.has_method("force_value"):
				node.call("force_value", dusk_force)
		print("--dusk=%.2f: %d DuskCycle fortate" % [dusk_force, dusk_cycles.size()])
	# Teatrul bastionului (Jodhpur, POI F). Opt-in: fara flag nu se atinge
	# nimic. Ceasul e o functie pura de timp (BastionTheatre), deci se pune
	# direct si se ingheata — fara simulare de cadre.
	if salute_at >= 0.0 or zip_at >= 0.0 or fireworks_at >= 0.0:
		await get_tree().process_frame
		var theatres := get_tree().get_nodes_in_group(&"bastion_theatre")
		for node in theatres:
			if salute_at >= 0.0:
				node.call("force_clock", "salute", salute_at)
			if zip_at >= 0.0:
				node.call("force_clock", "zip", zip_at)
			if fireworks_at >= 0.0:
				node.call("force_clock", "fw", fireworks_at)
		print("--salute-at/--zip-at/--fireworks-at: %d BastionTheatre fortate" % theatres.size())
	# Torentul in pulsuri (Fiordland, scurtatura Chasm): `TorrentCycle._place`
	# e amanat si reincearca pana apar rutele, deci asteptam doua cadre si
	# fortam ceasul pe toate torentele din grup (0 = CALM, period-telegraph-
	# surge = inceputul anuntului, period-surge = inceputul pulsului).
	if torrent_at >= 0.0:
		await get_tree().process_frame
		await get_tree().process_frame
		var torrents := 0
		for node in get_tree().get_nodes_in_group(&"torrents"):
			if node.has_method("force_clock"):
				node.call("force_clock", torrent_at)
				torrents += 1
		print("--torrent-at=%.2f: %d TorrentCycle fortate" % [torrent_at, torrents])
	# Shishi-odoshi (Kyoto, POI F): ceasul tubului e UNGHIUL, deci o captura fara
	# asta prinde tubul in faza in care a pornit pista. Faza e fractia din ciclu
	# (16,6 s): ~0.02 = sus (inceput de umplere), ~0.72 = aproape orizontal
	# (~85% din umplere), ~0.90 = lovit (gura pe drum).
	if shishi_phase >= 0.0:
		await get_tree().process_frame
		await get_tree().process_frame
		var tubs := 0
		for node in get_tree().get_nodes_in_group(&"shishi_odoshi"):
			if node.has_method("force_clock"):
				node.call("force_clock", shishi_phase * float(node.call("cycle_seconds")))
				tubs += 1
		print("--shishi-phase=%.2f: %d ShishiOdoshiHazard fortate" % [shishi_phase, tubs])
		if shishi_backdrop:
			# Panou doar de masurare (NU in scena): 60x40 m, 6 m dincolo de tub pe sensul
			# de mers, verde inchis de pin la umbra: contrastul se masoara si pe fundal
			# de padure, nu doar pe ceata.
			for node in get_tree().get_nodes_in_group(&"shishi_odoshi"):
				var q := MeshInstance3D.new()
				var qm := QuadMesh.new()
				qm.size = Vector2(60.0, 40.0)
				q.mesh = qm
				var bm := StandardMaterial3D.new()
				bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				bm.cull_mode = BaseMaterial3D.CULL_DISABLED
				bm.albedo_color = Color(0.13, 0.24, 0.13)
				q.material_override = bm
				q.position = Vector3(0.0, 8.0, -6.0)
				node.add_child(q)
			print("--shishi-backdrop: panou adaugat")
	# Daruma-otoshi (Kyoto, POI F): tot ce se vede e o functie pura de ceasul mare,
	# deci faza se fixeaza direct (`force_clock` opreste avansul).
	if daruma_phase >= 0.0 or daruma_clock >= 0.0:
		await get_tree().process_frame
		await get_tree().process_frame
		var darumas := 0
		# acelasi flag fixeaza si carul Gion Matsuri (care a inlocuit daruma pe pista)
		for node in get_tree().get_nodes_in_group(&"daruma_otoshi") + get_tree().get_nodes_in_group(&"gion_matsuri"):
			if node.has_method("force_clock"):
				var secs := daruma_clock
				if secs < 0.0:
					secs = daruma_phase * float(node.call("total_seconds"))
				node.call("force_clock", secs)
				darumas += 1
		print("--daruma: %d DarumaOtoshiHazard fortate la ceasul %.2f s" % [darumas,
			daruma_clock if daruma_clock >= 0.0 else daruma_phase * 71.0])
	# Covorul de frunze (Kyoto): `--no-leaves` = fara covor si fara frunzele care
	# cad (starea "inainte"); `--leaf-wear=N` = N treceri simulate ale plutonului
	# pe linia de cursa (starea "dupa N tururi"). Fara flag: covorul proaspat.
	var leaf_carpet := track.get_node_or_null("CovorFrunze") as LeafCarpet
	var leaf_node := track.get_node_or_null("FrunzeCazatoare") as Node3D
	if leaf_carpet != null:
		if leaf_passes == -2:
			leaf_carpet.visible = false
			if leaf_node != null:
				leaf_node.queue_free()
			print("--no-leaves: covorul si frunzele stinse")
		else:
			if not leaf_fall and leaf_node != null:
				leaf_node.queue_free()
			if leaf_passes > 0:
				for _i in 20:
					await get_tree().process_frame
					if leaf_carpet.built:
						break
				await leaf_carpet.simulate_passes(leaf_passes)
				for _i in 3:
					await get_tree().process_frame
				print("--leaf-wear=%d: %d stampile in foaie" % [leaf_passes, leaf_carpet.stamps_received])
	if daruma_dist > 0.0:
		for node in get_tree().get_nodes_in_group(&"daruma_otoshi") + get_tree().get_nodes_in_group(&"gion_matsuri"):
			var rt := track.route_at(0)
			var ti := track.closest_index_global((node as Node3D).global_position, 0)
			var acc := 0.0
			var bi := ti
			var m := rt.baked.size()
			# camera de joc sta cu DEFAULT_DISTANCE in spatele masinii pusa la `--frac`
			var want := daruma_dist - ChaseCamera.DEFAULT_DISTANCE
			while acc < want:
				var nb := (bi - 1 + m) % m
				acc += (rt.baked[bi] as Vector3).distance_to(rt.baked[nb])
				bi = nb
			zoom_frac = float(bi) / float(m)
			print("--daruma-dist=%.0f: masina la %.0f m inaintea turnului (frac %.4f)" % [daruma_dist, acc, zoom_frac])
	if overdraw:
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
	# Stadiul limbii de lava (Stromboli): 0 = turul 1 ... 2 = zid. Fara el,
	# captura prinde mereu stadiul 1 — exact starea in care gimmick-ul nu se
	# vede (aceeasi clasa de capcana ca la --bridge-at).
	if lava_stage >= 0:
		for child in track.get_children():
			if child is LavaFlowHazard:
				var lf := child as LavaFlowHazard
				while lf.current_stage() < lava_stage:
					lf.on_lap_completed()
				print("--lava-stage=%d: %s" % [lava_stage, lf.name])
	# `--hide` se aplica DUPA doua cadre, nu la `add_child`.
	#
	# Hazardele isi construiesc geometria AMANAT (`call_deferred` in
	# `RotatingSpanHazard._ready`, ca sa apuce pista sa-si coaca rutele), deci
	# in `_ready`-ul capturii nodurile lor inca nu exista in arbore. Cautate
	# atunci, `Deck`/`Span`/`SpanRoad` dau „nu am gasit" — si asta a costat o
	# runda intreaga: A/B-ul care trebuia sa arate CE deseneaza dala tan a
	# raportat „ascunderea nu schimba nimic", fiindca nu ascunsese nimic.
	#
	# `owned=false` din acelasi motiv: mesh-urile construite in cod n-au
	# `owner`, iar cele din GLB-urile instantiate stau sub radacina scenei lor.
	if hide_node != "":
		await get_tree().process_frame
		await get_tree().process_frame
		# ADITIV (POI D, runda 4): un `*` la coada ascunde TOATE nodurile al
		# caror nume incepe cu prefixul. Fara asta nu se poate face A/B-ul de
		# atribuire pe o CLASA de piese (ceata, coroane) — doar pe un nod.
		if hide_node.ends_with("*"):
			var pref := hide_node.substr(0, hide_node.length() - 1)
			var cnt := 0
			for nd in track.find_children("%s*" % pref, "Node3D", true, false):
				(nd as Node3D).visible = false
				cnt += 1
			print("snapshot: ascunse %d noduri cu prefixul %s" % [cnt, pref])
		else:
			var h := track.find_child(hide_node, true, false) as Node3D
			if h != null:
				h.visible = false
				print("snapshot: ascuns %s (%s)" % [hide_node, h.get_path()])
			else:
				print("snapshot: nu am gasit %s" % hide_node)

	# Ceata se stinge doar pentru vederile DE SUS (ansamblul ortografic), unde
	# camera e la sute de metri si ceata ar spala tot intr-o pata uniforma.
	#
	# Pentru vederile DE JOC (--driver, --gamecam, --landmark, camera libera)
	# ceata TREBUIE sa ramana: ea e ce vede jucatorul, si fara ea capturile mint
	# exact despre fundal — siluetele de orizont stau la 190-300 m, adica in
	# plina ceata, si pe captura ieseau la contrast plin. Runda 34: 13 runde de
	# reglaje pe Erciyes s-au judecat pe capturi fara ceata, deci pe o imagine
	# pe care jucatorul n-o vede niciodata.
	var keep_fog := driver_view or game_cam or free_cam or landmark_id >= 0
	if not keep_fog:
		for child in track.get_children():
			if child is WorldEnvironment:
				(child as WorldEnvironment).environment.fog_enabled = false

	# Incadram pista (nu terenul urias): bounds din punctele coapte.
	var bmin := track.baked[0]
	var bmax := track.baked[0]
	for p in track.baked:
		bmin = bmin.min(p)
		bmax = bmax.max(p)
	var center := (bmin + bmax) * 0.5
	var extent_x := bmax.x - bmin.x + 90.0
	var extent_z := bmax.z - bmin.z + 90.0
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / viewport_size.y
	var cam := Camera3D.new()
	add_child(cam)
	if free_cam:
		# CAMERA LIBERA: ochi + punct privit in coordonate de lume. Pentru
		# lucruri care nu se vad nici de pe sosea, nici de sus: un viaduct se
		# judeca din lateral, de pe gheata, si nicio fractie nu te duce acolo.
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = ChaseCamera.BASE_FOV
		cam.far = 600.0
		cam.position = eye_pos
		cam.look_at(look_pos, Vector3.UP)
		cam.current = true
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var fimg := get_viewport().get_texture().get_image()
		var fdir := ProjectSettings.globalize_path("res://snapshots")
		DirAccess.make_dir_recursive_absolute(fdir)
		var fout := "%s/%s_liber.png" % [fdir, GameState.TRACK_NAMES[track_index].to_lower()]
		fimg.save_png(fout)
		print("SNAPSHOT: ", fout)
		get_tree().quit()
		return
	if landmark_id >= 0:
		await _shoot_landmark(track, cam, track_index, landmark_id, landmark_dist)
		return
	if driver_view:
		# Perspectiva de la inaltimea camerei de urmarire. Doua variante:
		#   --driver  = poza INGHETATA de masurare (MEASURE_*, vezi antetul)
		#   --gamecam = parametrii REALI ai camerei, pentru compozitie
		var dist := MEASURE_DIST
		var cam_h := MEASURE_HEIGHT
		var fov := MEASURE_FOV
		var look_ahead := MEASURE_LOOK_AHEAD
		var look_h := MEASURE_LOOK_HEIGHT
		if game_cam:
			dist = ChaseCamera.DEFAULT_DISTANCE
			cam_h = ChaseCamera.DEFAULT_HEIGHT
			fov = ChaseCamera.BASE_FOV
			look_ahead = ChaseCamera.LOOK_AHEAD
			look_h = ChaseCamera.LOOK_HEIGHT
		# Banda ceruta (0 = soseaua): pe o scurtatura fractia e din lungimea
		# EI si nu se infasoara — capatul benzii e capat, nu tur.
		var route := track.route_at(clampi(route_idx, 0, track.routes.size() - 1))
		var pts := route.baked
		var n := pts.size()
		var idx := int(zoom_frac * float(n)) % n
		var focus: Vector3 = pts[idx]
		if cave_view:
			# Presetul de camera si intunericul zonei, aplicate MANUAL: vezi
			# `cave_view` pentru de ce o captura din subteran fara ele minte.
			#
			# Fractia se trece prin `frac_at`, nu se da bruta: pe o banda
			# secundara `zoom_frac` e din lungimea EI (0.25 din ocol), dar
			# zonele pe interval lucreaza cu fractia BUCLEI (0.718 acolo) —
			# exact cum o citeste jocul din `Car.road_index` in
			# `CameraZone._player_in_frac_span`. Cu fractia bruta, captura de
			# pe ocol alegea zona dupa distanta (Sala2, alt tavan, alt preset)
			# si masura o camera care nu exista in joc. Pe ruta 0 `frac_at`
			# intoarce chiar `zoom_frac`, deci nimic nu se schimba acolo.
			var zone := _nearest_cave_zone(track, focus, route.frac_at(idx))
			if zone != null:
				var solved := ChaseCamera.solve_preset(
					zone.height, zone.look_height, dist, look_ahead,
					fov + zone.fov_bonus, zone.ceiling, zone.ceiling_dist)
				cam_h = solved[0]
				fov = solved[1]
				look_h = zone.look_height
				cam.fov = fov
				zone.force_dark()
				await get_tree().process_frame
				print("--cave: zona %s, tavan %.1f m -> h %.2f fov %.1f"
					% [zone.name, zone.ceiling, cam_h, fov])
			else:
				print("--cave: nicio CameraZone langa frac %.3f" % zoom_frac)
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		if show_car:
			var car := (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
			car.track = track
			add_child(car)
			car.apply_data(load("res://scenes/cars/data/%s.tres" % car_data_name) as CarData)
			car.is_player = car_player
			car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
				focus + Vector3.UP * 0.45)
			car.road_index = idx
			car.on_start_grid = true
			_seat_car_on_rope_bridge(track, car)
			if rim_hit:
				# `--car --rim-at=T --rim-hit`: masina sta pe punctul de impact al
				# bolovanului de pe buza, strivita + directie inversata (starea de
				# dupa lovitura, cu turtirea si "<=>" deasupra).
				var rims := track.find_children("*", "RimBoulderHazard", true, false)
				if not rims.is_empty():
					var rz := rims[0] as RimBoulderHazard
					car.global_transform = Transform3D(car.global_transform.basis,
						rz.global_position + Vector3.UP * 0.45)
					car.crush(RimBoulderHazard.CRUSH_SECONDS, RimBoulderHazard.CRUSH_FACTOR,
						RimBoulderHazard.CRUSH_SQUASH, RimBoulderHazard.CRUSH_KEEP_SPEED,
						true, true)
					for _rf in 12:
						await get_tree().physics_frame
					print("--rim-hit: masina strivita, inversare %.2f s" % car.steer_invert_left)
			if haboob_at >= 0.0:
				# `--car --haboob-at`: masina e JUCATORUL (ceata de joc se aplica doar
				# lui) si hazardul o vede dupa cateva cadre de fizica.
				car.is_player = true
				for _hf in 6:
					await get_tree().physics_frame
			if vitrina_stem != "":
				# Lista cu virgula (`--vitrina=momiji_a,momiji_b`): piesele se
				# aseaza una dupa alta pe drum, la `--vitrina-step` metri, ca un
				# rand de kit intr-o singura captura (int-a, Kyoto).
				var stems := vitrina_stem.split(",", false)
				for si in stems.size():
					_place_vitrina(track,
						focus + dir * (vitrina_ahead + float(si) * vitrina_step),
						dir, stems[si], vitrina_side, vitrina_yaw, vitrina_anim)
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = fov
		cam.far = 400.0
		var want := focus - dir * dist + Vector3.UP * cam_h
		if game_cam:
			# ANTI-CLIPPING, ca in joc. Fara el captura minte exact acolo unde
			# conteaza: pe portiunea prin holul blocului Liziba camera de joc e
			# trasa in fata plafonului (`ChaseCamera._unclip`), dar captura o
			# lasa in plansee si iese un cadru negru — adica poza arata un
			# defect pe care jocul nu-l are, sau ascunde unul pe care il are.
			var look := focus + Vector3.UP * ChaseCamera.LOOK_HEIGHT
			var space := get_viewport().world_3d.direct_space_state
			var q := PhysicsRayQueryParameters3D.create(look, want,
				Track.CAMERA_BLOCKER_LAYER)
			var hit := space.intersect_ray(q)
			if not hit.is_empty():
				want = (hit["position"] as Vector3).move_toward(look,
					ChaseCamera.CLIP_MARGIN)
		cam.position = want
		cam.look_at(focus + dir * look_ahead + Vector3.UP * look_h, Vector3.UP)
		cam.current = true
		if wipers_demo >= 0:
			_show_wipers_demo(wipers_demo)
		# DECORUL CARE SE CONSTRUIESTE SINGUR are nevoie de cadre inainte de
		# poza. FlamingoFlock (si orice alt decor cu `_build.call_deferred()`)
		# asteapta doua cadre de proces PLUS doua de fizica, ca terenul sa fie
		# in serverul de fizica; cu doar doua `process_frame` poza se facea
		# INAINTE ca stolurile sa existe. Masurat in runda 4 pe POI G:
		# `_ready` al stolurilor rula, `_build` nu apuca niciodata, deci nici
		# un flamingo din MultiMesh nu aparea in capturi — pe TOATE rundele de
		# pana acum, nu doar pe inel. Asteptarea e de cateva cadre si face
		# captura sa arate ce vede jucatorul, nu o stare intermediara.
		for _i in 8:
			await get_tree().process_frame
			await get_tree().physics_frame
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_print_render_info()
		var dimg := get_viewport().get_texture().get_image()
		var ddir := ProjectSettings.globalize_path("res://snapshots")
		DirAccess.make_dir_recursive_absolute(ddir)
		var vitrina_suffix := "_%s" % vitrina_anim.to_lower() if vitrina_anim != "" else ""
		var dout := "%s/vitrina_%s%s.png" % [ddir, vitrina_stem, vitrina_suffix] \
			if vitrina_stem != "" \
			else "%s/%s_%s%s%s.png" % [ddir,
				GameState.TRACK_NAMES[track_index].to_lower(),
				"joc" if game_cam else "sofer",
				"" if route_idx == 0 else "_ruta%d" % route_idx,
				"_overdraw" if overdraw else ""]
		dimg.save_png(dout)
		print("SNAPSHOT: ", dout)
		if cine:
			_cine_e_in_cadru(track, cam)
		get_tree().quit()
		return
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	if zoom_frac >= 0.0:
		# Prim-plan inclinat la un punct de pe traseu (vezi si inaltimile).
		var idx := int(zoom_frac * float(track.baked.size())) % track.baked.size()
		var focus: Vector3 = track.baked[idx]
		cam.size = zoom_size
		cam.position = focus + Vector3(0, zoom_size * 0.9, zoom_size * 0.6)
		cam.look_at(focus, Vector3.UP)
	else:
		# `size` e extinderea VERTICALA; orizontala = size * aspect.
		# Cu --size fortezi cadrul (ex. 950 ca sa vezi si zidul lumii).
		cam.size = zoom_size if zoom_size > 100.0 else maxf(extent_z, extent_x / aspect)
		cam.position = center + Vector3.UP * 400.0
		cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.far = 1000.0
	cam.current = true

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var out := "%s/%s.png" % [dir, GameState.TRACK_NAMES[track_index].to_lower()]
	img.save_png(out)
	print("SNAPSHOT: ", out)
	get_tree().quit()


## Desenele/primitivele/obiectele din ULTIMUL cadru randat (RenderingServer
## raporteaza cadrul precedent, de aceea se cheama dupa `frame_post_draw`).
## Cifra de buget pe care o compara A/B-ul ploaie on/off: cate desene in plus
## aduce un strat transparent, nu doar cate instante exista in scena.
func _print_render_info() -> void:
	var vp := get_viewport().get_viewport_rid()
	var t := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE
	print("RENDER: obiecte %d, primitive %d, desene %d" % [
		RenderingServer.viewport_get_render_info(vp, t,
			RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME),
		RenderingServer.viewport_get_render_info(vp, t,
			RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME),
		RenderingServer.viewport_get_render_info(vp, t,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)])
	_print_halo_stats()


## Costul halourilor false (LampHalo, Jodhpur) pe CADRUL capturat: cate
## instante cad in frustum, cate au haloul intreg (< 45 m), si cati pixeli
## acopera patratele lor — adica overdraw-ul aditiv, socotit cu ACEEASI
## formula de raza ca shaderul (lamp_halo.gdshader), nu estimat.
func _print_halo_stats() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or LampHalo.built.is_empty():
		return
	var vp_h := float(get_viewport().get_visible_rect().size.y)
	var px_per_rad := vp_h / (2.0 * tan(deg_to_rad(cam.fov) * 0.5))
	var far_b := 45.0
	var far_e := 60.0
	var min_core := 0.0022
	var pull_frac := 0.8
	var pull_max := 1.2
	var tot := 0
	var vis := 0
	var full := 0
	var px := 0.0
	var per := {}
	for mmi: MultiMeshInstance3D in LampHalo.built:
		if not is_instance_valid(mmi) or not mmi.is_visible_in_tree():
			continue
		var mm := mmi.multimesh
		var gx := mmi.global_transform
		var v_n := 0
		var v_px := 0.0
		for i in mm.instance_count:
			tot += 1
			var p: Vector3 = gx * mm.get_instance_transform(i).origin
			var cd := mm.get_instance_custom_data(i)
			var d := cam.global_position.distance_to(p)
			var core := maxf(cd.r, d * min_core)
			var keep := 1.0 - smoothstep(far_b, far_e, d)
			var st := maxf(cd.b, 1.0)
			var halo := lerpf(core * st, maxf(cd.g, core * st), keep)
			var r := maxf(halo, core * st)
			if not cam.is_position_in_frustum(p):
				# patratul poate intra in cadru cu marginea; ignorat (sub-estimare mica)
				continue
			var dd := maxf(d - minf(r * pull_frac, pull_max), 0.3)
			var rpx := r / dd * px_per_rad
			var a := 4.0 * rpx * rpx
			vis += 1
			v_n += 1
			if d < far_b:
				full += 1
			px += a
			v_px += a
		per[mmi.name] = "%d vizibile, %.0f px" % [v_n, v_px]
	var area := get_viewport().get_visible_rect().size.x * vp_h
	print("HALO: %d instante, %d in cadru, %d cu halou intreg (<45 m), %.0f px acoperiti = %.2f ecrane de overdraw aditiv" % [
		tot, vis, full, px, px / area])
	print("HALO per strat: ", per)


## Un landmark anume, vazut de pe sosea (--landmark=, vezi antetul).
##
## Camera sta pe axa drumului, la inaltimea camerei de urmarire, cu `dist`
## metri inainte de dreptul propului — adica exact de unde il vezi conducand,
## nu de sus si nu din lateral.
func _shoot_landmark(track: Track, cam: Camera3D, track_index: int,
		id: int, dist: float) -> void:
	# Cautare pe eticheta `shot_id`, nu pe grup: prop-urile hero care nu sunt in
	# `_LANDMARKS` (portalul de mina) trebuie sa poata fi cerute la fel.
	var target: Node3D = null
	for node in track.get_children():
		if node is Node3D and node.get_meta("shot_id", -1) == id:
			target = node as Node3D
			break
	if target == null:
		push_error("Snapshot: pista %d n-are prop cu shot_id %d" % [track_index, id])
		get_tree().quit(1)
		return
	# Ceata ramane STINSA (o taie apelantul mai sus) — la 30 m n-ar face nimic,
	# dar la un prop mai indepartat ar spala tocmai suprafata de verificat.
	var aabb := Track.model_aabb(target)
	var focus := aabb.position + aabb.size * 0.5
	# Punctul de pe traseu cel mai apropiat de prop, si directia de mers acolo.
	var best := 0
	var best_d := INF
	for i in track.baked.size():
		var d: float = track.baked[i].distance_squared_to(focus)
		if d < best_d:
			best_d = d
			best = i
	var n := track.baked.size()
	var here: Vector3 = track.baked[best]
	var dir := (track.baked[(best + 6) % n] - here).normalized()
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = 400.0
	cam.position = here - dir * dist + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	cam.look_at(focus, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var dir_out := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir_out)
	var out := "%s/%s_landmark%d.png" % [dir_out,
		GameState.TRACK_NAMES[track_index].to_lower(), id]
	get_viewport().get_texture().get_image().save_png(out)
	print("SNAPSHOT: ", out)
	get_tree().quit()


## EXPERIMENT (--smooth): normale netede pe geometria organica, pentru A/B.
##
## Ipoteza "arata ca Minecraft" are o cauza precisa de verificat: NIMIC din
## pipeline nu face shade_smooth, deci fiecare fateta e o placa uniforma de
## lumina. Aici rebuild-uim normalele prin mediere pe pozitie — echivalentul
## la runtime al lui shade_smooth din Blender — DOAR ca sa comparam capturi.
## Reparatia reala, daca ipoteza tine, e in exportul Blender, nu aici.
## Instantiaza WindshieldWipers si il umple cu `count` picaturi fortate
## (brief Fiordland pasul 4, `--wipers-demo`). Snapshot nu porneste o cursa
## (nu exista `Race`), deci verificarea overlay-ului n-are alt punct de
## intrare — aici e cel mai apropiat de contractul real: acelasi CanvasLayer,
## acelasi pool, doar cu picaturile create direct in loc de prin `configure()`
## + starea unui `WaterfallHazard`/`RainCycle` reali.
func _show_wipers_demo(count: int) -> void:
	var w := WindshieldWipers.new()
	add_child(w)
	w.force_spawn_demo(count)
	print("--wipers-demo=%d: WindshieldWipers instantiat, %d picaturi fortate" % [count, count])


## Muta ceasul trenului la o fractie din ciclul lui, ca sa apuce sa fie IN cadru
## cand se face poza.
##
## Fara asta trenul e nefotografiabil: la pornire ciclul e la 0 (avertizare), iar
## captura are loc dupa doua cadre — deci in orice snapshot garnitura e parcata
## in afara hartii si invizibila. 0.55 il prinde pe la mijlocul traversarii.
func _set_train_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.find_children("*", "TrainHazard", true, false):
		var train := node as TrainHazard
		if train == null:
			continue
		# `_time` e privat prin conventie, nu prin limbaj; sonda are voie, exact
		# ca sa nu adaugam un export doar de dragul unei poze.
		train.set("_time", train.period * clampf(at, 0.0, 0.999))
		train._physics_process(0.0)
		found += 1
	# POI H (Fiordland): avionul si vaporasul sunt PathMover generic, nu
	# TrainHazard — acelasi tipar de ceas, extins la orice PathMover din
	# scena (bucla: fractia*lungime; dus-intors: la fel, pe sensul curent).
	for node in root.find_children("*", "PathMover", true, false):
		var mover := node as PathMover
		if mover == null or mover.curve == null:
			continue
		var length := mover.curve.get_baked_length()
		if length < 0.5:
			continue
		mover.set("_started", true)
		mover.set("_dist", length * clampf(at, 0.0, 0.999))
		# `_body` e AnimatableBody3D cu `sync_to_physics = true`: scrierea lui
		# `global_transform` din `_physics_process` (path_mover.gd) trece prin
		# starea de fizica si nu se reflecta imediat in `global_position` cand
		# e apelata manual, in afara unui tick real de fizica (verificat: doua
		# apeluri succesive la `_physics_process(0.0)` tot au aratat corpul la
		# originea curbei, desi `_dist`/`sample_baked` erau deja corecte).
		# `TrainHazard` scapa de asta fiindca scrie `.position` local pe un
		# Node3D simplu, nu `global_transform` pe un corp sincronizat cu
		# fizica. Fix local: opreste sincronizarea CAT TIMP se scrie transful,
		# ca scrierea sa fie directa pe Node3D (CPU), apoi o repune — corpul
		# ramane sincronizat normal in cursa reala, doar captura foloseste
		# ocolul.
		var body: Node3D = mover.call("body")
		if body != null and body.has_method("set"):
			body.set("sync_to_physics", false)
			mover._physics_process(0.0)
			body.set("sync_to_physics", true)
		else:
			mover._physics_process(0.0)
		found += 1
	print("--train-at=%.2f: %d treceri (tren/PathMover) mutate in ciclu" % [at, found])


## Muta cosurile care urca la o fractie din ciclul lor (toate la aceeasi faza,
## ca sa poti fotografia unul anume in maturare fara sa-i calculezi defazajul).
func _set_balloon_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.find_children("*", "BalloonHazard", true, false):
		var b := node as BalloonHazard
		b.set("_started", true)
		b.set("_time", b.period * clampf(at, 0.0, 0.999))
		found += 1
	for i in 4:
		await get_tree().physics_frame
	print("--balloon-at=%.2f: %d cosuri mutate in ciclu" % [at, found])


## Muta arzatorul la o fractie din ciclul lui si lasa cateva cadre sa treaca,
## ca particulele de praf sa apuce sa se nasca (GPUParticles nu are „salt in
## timp": se emit de la zero).
func _set_burner_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.find_children("*", "BurnerHazard", true, false):
		var b := node as BurnerHazard
		b.set("_started", true)
		# `_time` al arzatorului include deja defazajul (porneste din
		# phase*period), deci fractia se pune direct, fara sa se scada phase.
		b.set("_time", b.period * clampf(at, 0.0, 0.999))
		found += 1
	# Putine cadre: fereastra aprinsa e de 1.8 s din 17 (0.00-0.106 din ciclu),
	# iar 30 de cadre (0.5 s) dupa un --burner-at=0.08 o depaseau — captura
	# iesea cu arzatorul STINS si a fost citita ca „nu se vede nimic".
	for i in 4:
		await get_tree().physics_frame
	print("--burner-at=%.2f: %d arzatoare mutate in ciclu" % [at, found])


## Muta usa de piatra la o fractie din ciclul ei (vezi `--door-at` in antet).
##
## Cursa si perioada usii se deduc la primul tick, nu in _ready (pista pune
## `travel` dupa add_child), deci se ruleaza un pas de zero secunde intai, ca
## `door_cycle()` sa aiba o perioada. `phase` se scade ca 0 sa insemne
## „inceputul starii deschise", indiferent de defazajul pistei.
func _set_door_phase(root: Node, at: float) -> void:
	var found := 0
	# Un pas de fizica intai: `sync_to_physics` scrie transformul in server
	# si il citeste inapoi abia dupa un pas, iar cursa usii se taie la primul
	# tick — fara asteptare, pozitia citita e (0,0,0) si cursa nelimitata.
	await get_tree().physics_frame
	await get_tree().physics_frame
	for node in root.get_children():
		var door := node as SlidingHazard
		if door == null or door.motion != SlidingHazard.Motion.USA:
			continue
		var cycle: float = door.door_cycle()
		door.set("_time", cycle * (clampf(at, 0.0, 0.999) - door.phase))
		door._physics_process(0.0)
		found += 1
		print("--door-at=%.2f: usa la %s, cursa %.2f m, inchisa=%s" % [at,
			door.center + door.travel * door.call("_offset_now"),
			door.travel.length(), door.door_closed_now()])
	if found == 0:
		print("--door-at=%.2f: NICIO usa de piatra pe pista asta" % at)


## Aduce turma de gnu la `seconds` in ciclul pulsului (vezi `--herd-at`).
##
## Turma e un camp de curgere: pozitia fiecarui animal e FUNCTIE de `_time`,
## deci nu trebuie simulata cadru cu cadru (spre deosebire de bolovani) — se
## pune ceasul si se cere o plasare vizuala. Apoi se INGHEATA: pana la captura
## mai trec cadre si pulsul ar fugi de pe drum. Hazardele stau sub `Hazarduri`,
## nu direct sub pista, deci cautarea e recursiva.
func _set_herd_time(root: Node, seconds: float) -> void:
	await get_tree().physics_frame
	var found := 0
	for node in root.find_children("*", "HerdHazard", true, false):
		var herd := node as HerdHazard
		herd.set("_time", seconds)
		herd.call("_advance_animals", 0.0)
		herd.call("_place_visuals")
		herd.set_physics_process(false)
		found += 1
		var on_road := 0
		var pos: PackedVector3Array = herd.get("_pos")
		for p in pos:
			var rel: Vector3 = p - herd.global_position
			if absf(rel.dot(herd.flow_dir)) < HerdHazard.ROAD_ZONE:
				on_road += 1
		print("--herd-at=%.2f: %s, %d animale, %d in zona drumului, culoar liber=%s, perioada %.1f s"
			% [seconds, herd.name, herd.count(), on_road, herd.window_open_now(), herd.period()])
		for lot: Variant in [herd.get("_mmi"), herd.get("_mmi_zebra")]:
			var mmi := lot as MultiMeshInstance3D
			print("  lot %s: %d instante, cutie %s" % [mmi.name,
				mmi.multimesh.instance_count, str(mmi.get_aabb())])
	if found == 0:
		print("--herd-at=%.2f: NICIO turma pe pista asta" % seconds)


## Aduce obstacolele care TRAVERSEAZA la `seconds` absolute in ciclul lor
## (vezi `--cross-at`). Cursa si perioada se configureaza la primul tick
## (`_configure`, dupa ce pista a pus `travel`), deci se cere un cadru de
## fizica inainte; apoi se INGHEATA, ca la turma.
func _set_cross_time(root: Node, seconds: float, anim_phase: float = 0.0) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var found := 0
	for node in root.find_children("*", "SlidingHazard", true, false):
		var hz := node as SlidingHazard
		if hz == null or hz.motion != SlidingHazard.Motion.TRAVERSARE:
			continue
		hz.set("_time", seconds)
		hz._physics_process(0.0)
		hz.set_physics_process(false)
		found += 1
		if hz._anim != null:
			# Model cu schelet: animatia dupa viteza REALA din acest moment (ca
			# in joc), pusa pe faza ceruta si inghetata.
			var v := absf(hz._offset_at(seconds + 0.05) - hz._offset_at(seconds)) 				/ 0.05 * hz.travel.length()
			hz._animate(v)
			var cur := hz._anim.get_animation(hz._anim.current_animation)
			hz._anim.speed_scale = 1.0
			# fara amestec: cu ANIM_BLEND poza ceruta ar ramane pe jumatate
			# amestecata cu repausul
			hz._anim.play(hz._anim.current_animation, 0.0)
			hz._anim.seek(cur.length * anim_phase, true)
			hz._anim.advance(0.0)
			hz._anim.pause()
			print("--cross-at: %s anim '%s' la faza %.2f (viteza %.2f m/s)"
				% [hz.name, hz._anim.assigned_animation, anim_phase, v])
		var off: float = hz.call("_offset_now")
		var lateral := off * hz.travel.length()
		var hw := hz.road_half_width
		var body_half: float = hz.get("_half_extent")
		var on_road := absf(lateral) - body_half < hw
		print("--cross-at=%.2f: %s la (%.1f, %.1f, %.1f), offset %.2f (%.1f m de ax, banda %.1f), pe carosabil=%s, perioada %.1f s, ciclu %.1f s"
			% [seconds, hz.name, hz.global_position.x, hz.global_position.y,
			hz.global_position.z, off, lateral, hw, on_road, hz.period,
			2.0 * (SlidingHazard.CROSS_WAIT + SlidingHazard.CROSS_TELEGRAPH
				+ hz.period * 0.5)])
	if found == 0:
		print("--cross-at=%.2f: NICIUN obstacol care traverseaza pe pista asta" % seconds)


## Muta hipopotamii la o fractie din ciclul lor (vezi `--hippo-at`). Toti la
## aceeasi faza, ca in captura sa se vada starea, nu defazajul. Un cadru de
## fizica intai, ca `_rest` sa fie citit din pozitia reala (sync_to_physics).
## Norul: la N secunde in ciclu, cu ceasul lui oprit pe durata pozei.
func _set_cloud_time(root: Node, at: float) -> void:
	await get_tree().physics_frame
	var found := 0
	for node in root.find_children("*", "CloudRiseHazard", true, false):
		var cloud := node as CloudRiseHazard
		cloud.set_cycle_time(at)
		cloud.set_physics_process(false)
		found += 1
		print("--cloud-at=%.1f: %s acoperire %.2f, panza la y=%.1f (local)"
			% [at, cloud.name, cloud.cover(), cloud.get_node("Cloud").position.y])
	if found == 0:
		print("--cloud-at: NICIUN nor pe pista asta")


## Haboob-ul: la N secunde in ciclu, cu ceasul INGHETAT (`force_clock`: fizica
## continua sa ruleze, deci ceata si praful se aplica, dar timpul nu avanseaza).
## Un process_frame in plus, ca la `--bus-at`: hazardurile cu `call_deferred` in
## `_ready` nu exista inca la primul physics_frame.
func _set_haboob_time(root: Node, at: float) -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	var found := 0
	for node in root.find_children("*", "HaboobHazard", true, false):
		var hb := node as HaboobHazard
		hb.force_clock = at
		hb.set_cycle_time(at)
		found += 1
		var w := hb.wall()
		print("--haboob-at=%.1f: %s acoperire %.2f, front la %.0f m pe cale, zid la %s (vizibil=%s)"
			% [at, hb.name, hb.cover(), hb.front_distance_at(at),
				str(w.global_position) if w != null else "?",
				str(w.visible) if w != null else "?"])
	if found == 0:
		print("--haboob-at: NICIUN haboob pe pista asta")


## `--rim-at=T`: bolovanul de pe buza (RimBoulderHazard) cu ceasul INGHETAT la T
## secunde din ciclul de 19 s (0-15.9 liniste, ~15.95-17.35 telegraf, ~17.35-18.35
## cade, 18.35-18.7 pe asfalt, apoi se sparge). Ca la haboob, deferit.
func _set_rim_time(root: Node, at: float) -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	var found := 0
	for node in root.find_children("*", "RimBoulderHazard", true, false):
		var rz := node as RimBoulderHazard
		rz.force_clock = at
		found += 1
		print("--rim-at=%.2f: %s faza %d, impact la %s" % [at, rz.name,
			rz.phase_at(at), str(rz.global_position)])
	# Praful cere timp de incalzire: ceasul e inghetat, dar particulele curg.
	for _i in 100:
		await get_tree().physics_frame
	if found == 0:
		print("--rim-at: NICIUN RimBoulderHazard pe pista asta")


## `--no-haboob`: scos din scena (si din grupul AI) INAINTE de captura.
func _remove_haboob(root: Node) -> void:
	await get_tree().process_frame
	var n := 0
	for node in root.find_children("*", "HaboobHazard", true, false):
		node.remove_from_group(HaboobHazard.AI_SPEED_GROUP)
		node.get_parent().remove_child(node)
		node.free()
		n += 1
	print("--no-haboob: %d haboob-uri scoase din scena" % n)


## Autobuzul: la N secunde de coborare pe curba lui, cu botul pe directia de
## mers si ceasul oprit. `_dist`/`_yaw` sunt private prin conventie, ca la
## tren; `_has_prev` se stinge ca primul tick sa nu citeasca teleportarea ca
## pe o miscare (si sa roteasca botul dupa ea).
func _set_bus_time(root: Node, at: float) -> void:
	# `BusHazard` la Fiordland nu e declarat in .tscn: `TunnelSignalHazard`
	# il construieste in `_build_bus.call_deferred()` din `_ready()` (brief
	# §2E: lampa+autobuzul se construiesc, geometria tunelului ramane cod).
	# Un `find_children` chemat prea devreme (un singur physics_frame, ca la
	# `--cloud-at`) nu il gaseste inca — call_deferred ruleaza la finalul
	# frame-ului IDLE curent, nu neaparat inaintea urmatorului tick de
	# fizica. Un process_frame in plus lasa coada de deferred sa se goleasca
	# inainte de cautare (masurat: fara el, "--bus-at: NICIUN autobuz pe
	# pista asta" pe Track16, desi SemaforTunel avea deja bus_model setat).
	await get_tree().process_frame
	await get_tree().physics_frame
	var found := 0
	for node in root.find_children("*", "BusHazard", true, false):
		var bus := node as BusHazard
		if bus == null or bus.curve == null:
			continue
		var length: float = bus.curve.get_baked_length()
		var d: float = clampf(at * bus.speed, 0.0, length - 0.1)
		bus.set("_started", true)
		bus.set("_dist", d)
		bus.set("_has_prev", false)
		var pos: Vector3 = bus.to_global(bus.curve.sample_baked(d, true))
		bus.set("_yaw", bus.call("_travel_yaw", length, pos))
		# `--bus-at` cere autobuzul VIZIBIL la pozitia data, indiferent de
		# ciclul lui ascuns/vizibil (TunnelSignalHazard/SemaforTunel il
		# porneste ASCUNS pana la inceputul tranzitului — vezi
		# `_force_hidden_until_transit` in tunnel_signal_hazard.gd). Fara
		# `_show()` explicit, `_set_dist`/`_set_yaw` de mai sus repozitioneaza
		# corpul, dar `_body.visible` ramane fals si captura iese cu autobuzul
		# invizibil desi coordonatele sunt corecte (masurat pe Fiordland POI E,
		# --bus-at=12 pe Track16: pozitia raportata era in gura tunelului, dar
		# nimic randat acolo).
		if bus.call("is_hidden"):
			bus.call("_show")
		found += 1
		for _i in 3:
			await get_tree().physics_frame
		bus.set_physics_process(false)
		var body: Node3D = bus.body()
		print("--bus-at=%.1f: %s la %.0f m din %.0f pe curba, corp la (%.1f, %.1f, %.1f)"
			% [at, bus.name, d, length, body.global_position.x, body.global_position.y,
				body.global_position.z])
	if found == 0:
		print("--bus-at: NICIUN autobuz pe pista asta")


## `--cow=stand|lie` (Jodhpur, D′): vaca din ulicioara (`CowGate`) INGHETATA
## in pozitia ceruta, fara telegraph: `lie` = culcata in gura (scurtatura
## inchisa), `stand` = in picioare pe prag (deschisa). Snapshot nu ruleaza
## ceasul portii, deci fara flag vaca e pe prag, adica jumatate din gimmick
## nu se vede niciodata. Opreste `_physics_process` al portii (lume
## inghetata), pune starea si transformul corpului, apoi cere `CowPose` sa
## aplice poza finala a clipului. Fara `CowGate` pe pista: nimic.
func _set_cow(track: Track, mode: String) -> void:
	var gate: CowGate = null
	for n in get_tree().get_nodes_in_group(Track.BRANCH_GATE_GROUP):
		if n is CowGate:
			gate = n as CowGate
			break
	if gate == null:
		print("--cow: pista fara CowGate")
		return
	for i in 60:
		if bool(gate.get("_placed")):
			break
		await get_tree().process_frame
	var lie := mode == "lie"
	gate.set_physics_process(false)
	gate.set("_state", CowGate.State.LYING_IN_MOUTH if lie else CowGate.State.ON_THRESHOLD)
	gate.set("_walk_t", 1.0 if lie else 0.0)
	gate.set("_clock", 0.0)
	var body := gate.get_node_or_null("CowBody") as Node3D
	var xf: Transform3D = gate.get("_mouth_xf") if lie else gate.get("_threshold_xf")
	if body != null:
		body.global_transform = xf
	var posed := 0
	# Duck typing, nu `is CowPose`: o clasa noua intra in cache-ul de clase
	# globale abia la urmatorul --import, iar pana atunci snapshot.gd nu se
	# mai compileaza deloc (Snapshot sta cu fereastra goala, fara eroare vizibila).
	for n in track.find_children("*", "Node", true, false):
		if n.has_method("snap_to_state") and n.has_method("is_bound"):
			for i in 60:
				if bool(n.call("is_bound")):
					break
				await get_tree().process_frame
			n.call("snap_to_state")
			posed += 1
	print("--cow=%s: vaca %s la (%.1f, %.1f, %.1f), CowPose %d"
		% [mode, "culcata in gura" if lie else "pe prag", xf.origin.x, xf.origin.y,
			xf.origin.z, posed])


## `--tuk-at`: tuk-tuk-uri inghetate pe banda stanga a buclei (ruta 0), la
## fractiile date (pe index, ca `--frac`). Aceeasi asezare ca
## `Race._spawn_traffic` (axa + side_at * offset, botul pe sensul de mers),
## dar cu corpul inghetat: poza arata traficul acolo unde il cere captura,
## nu unde l-ar fi dus fizica in cele cateva cadre de asteptare.
func _place_tuktuks(track: Track, spec: String) -> void:
	var route := track.route_at(0)
	if route == null or route.count() == 0:
		print("--tuk-at: pista fara ruta 0")
		return
	var n := route.count()
	var data := load("res://scenes/cars/data/tuktuk.tres") as CarData
	var placed := 0
	for item in spec.split(",", false):
		var parts := item.split(":")
		var frac := float(parts[0])
		var lat := TrafficController.LANE_OFFSET_M
		if parts.size() > 1:
			lat = float(parts[1])
		var idx := int(frac * float(n)) % n
		var dir := route.baked[route.wrap_index(idx + 1)] - route.baked[idx]
		dir.y = 0.0
		if dir.length_squared() < 0.001:
			dir = Vector3.FORWARD
		dir = dir.normalized()
		var pos := route.baked[idx] + route.side_at(idx) * lat + Vector3.UP * 0.45
		var car := (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
		car.track = track
		add_child(car)
		car.apply_data(data)
		car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), pos)
		car.route = 0
		car.road_index = idx
		car.on_start_grid = true
		placed += 1
		print("--tuk-at: tuk-tuk la frac %.3f (idx %d), lat %.1f, (%.1f, %.1f, %.1f)"
			% [frac, idx, lat, pos.x, pos.y, pos.z])
	print("--tuk-at: %d tuk-tuk-uri inghetate" % placed)


## Podul de franghie: o incarcare fantoma la fractia u din pod, cu sageata
## adusa la echilibru — apoi tick-ul podului e oprit, ca poza sa nu-l prinda
## in mijlocul unei oscilatii.
func _set_rope_load(root: Node, mass_factor: float, u: float) -> void:
	await get_tree().physics_frame
	var found := 0
	for node in root.find_children("*", "RopeBridgeHazard", true, false):
		var bridge := node as RopeBridgeHazard
		bridge.preview_loads.append(Vector3(u, 0.0, mass_factor))
		bridge.settle_now()
		found += 1
		print("--rope-load=%.1f,%.2f: %s sageata %.2f m la mijloc (%.2f la u=%.2f), balans %.2f"
			% [mass_factor, u, bridge.name, bridge.sag_at(0.5), bridge.sag_at(u), u, bridge.sway()])
	if found == 0:
		print("--rope-load: NICIUN pod de franghie pe pista asta")


## `--car` pe un pod de franghie: masina inghetata se aseaza PE tablierul
## afundat, nu la cota soselei, si isi lasa si ea greutatea (masina Muscle,
## mass_factor-ul ei) — altfel pluteste cu sageata deasupra scandurilor.
func _seat_car_on_rope_bridge(root: Node, car: Car) -> void:
	for node in root.find_children("*", "RopeBridgeHazard", true, false):
		var bridge := node as RopeBridgeHazard
		var dc := bridge.deck_coords(car.global_position)
		if dc.z <= 0.0 or dc.z >= 1.0 or absf(dc.x) > bridge.deck_width * 0.5 + 1.0:
			continue
		bridge.preview_loads.append(Vector3(dc.z, dc.x, car.mass_factor))
		bridge.settle_now()
		dc = bridge.deck_coords(car.global_position)
		car.global_position -= Vector3.UP * (dc.y - 0.45)
		print("--car pe %s: u=%.2f, x=%.2f, coborata cu %.2f m pe tablier" % [bridge.name, dc.z, dc.x, dc.y - 0.45])
		bridge.set_physics_process(false)
		return


## --vitrina: instantiaza piesa de kit <stem>.glb pe ACEEASI cale prin care
## DecorManual pune nodurile din Track16.tscn — un Node3D cu WorldProp
## (world_prop.gd) deasupra unei instante de PackedScene, ca sa primeasca
## clasa de textura si coliziunea din world_prop.gd, nu decor "gol" fara
## materialul de joc.
##
## Pozitia: `focus` (punctul de pe axa la fractia ceruta) + `side` metri pe
## DREAPTA (dir.cross(Vector3.UP), aceeasi conventie ca Track._side_at),
## asezata pe teren cu Track._terrain_mesh_y (aceeasi interpolare pe care o
## foloseste generatorul, nu un raycast fizic separat), rotita cu `yaw_deg`
## fata de directia drumului (`dir`).
## Calea unui stem de vitrina: din tabel, iar pentru kitul Kyoto (assets/models/
## kyoto/<categorie>/<stem>.glb) cautata pe disc, ca sa nu tina cineva un tabel
## de 60 de piese la zi. Gol daca nu o gaseste.
func _vitrina_path(stem: String) -> String:
	if _VITRINA_MODEL_PATHS.has(stem):
		return String(_VITRINA_MODEL_PATHS[stem])
	var root := "res://assets/models/kyoto"
	var d := DirAccess.open(root)
	if d == null:
		return ""
	for sub in d.get_directories():
		var cand := "%s/%s/%s.glb" % [root, sub, stem]
		if ResourceLoader.exists(cand):
			return cand
	return ""


func _place_vitrina(track: Track, focus: Vector3, dir: Vector3, stem: String,
		side: float, yaw_deg: float, anim_name: String = "") -> void:
	var path := _vitrina_path(stem)
	if path.is_empty():
		push_error("--vitrina=%s: stem necunoscut. Vezi _VITRINA_MODEL_PATHS in tools/snapshot.gd."
			% stem)
		return
	if not ResourceLoader.exists(path):
		push_error("--vitrina=%s: fisierul nu exista: %s" % [stem, path])
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("--vitrina=%s: nu s-a putut incarca %s" % [stem, path])
		return
	# Container WorldProp, EXACT ca ZoneX din DecorManual (Track16.tscn):
	# scriptul aplica textura de clasa si coliziunea in _ready, pe baza
	# numelui fisierului .glb al copilului — deci copilul (instanta GLB)
	# TREBUIE sa existe sub holder INAINTE ca holder sa intre in arbore.
	# `_ready` ruleaza la `add_child`, nu amanat: cu ordinea inversa (holder
	# adaugat, apoi copilul), `_collect_models` gaseste zero modele si piesa
	# iese fara clasa de textura si fara coliziune — exact bug-ul gasit prin
	# masurare (prima varianta a acestei functii): copacul aparea alb, plat,
	# fara material.
	var holder := Node3D.new()
	holder.name = "Vitrina_%s" % stem
	var inst := packed.instantiate() as Node3D
	inst.name = stem
	holder.add_child(inst)
	var right := dir.cross(Vector3.UP).normalized()
	var pos := focus + right * side
	pos.y = track._terrain_mesh_y(pos.x, pos.z)
	var basis := Basis.looking_at(dir, Vector3.UP).rotated(Vector3.UP,
		deg_to_rad(yaw_deg))
	holder.transform = Transform3D(basis, pos)
	holder.set_script(load("res://scenes/props/world_prop.gd"))
	add_child(holder)
	print("--vitrina=%s: %s la (%.2f, %.2f, %.2f), side=%.1f yaw=%.1f"
		% [stem, path, pos.x, pos.y, pos.z, side, yaw_deg])
	if anim_name != "":
		var players := inst.find_children("*", "AnimationPlayer", true, false)
		if players.is_empty():
			print("--vitrina-anim=%s: %s n-are AnimationPlayer" % [anim_name, stem])
			return
		var ap := players[0] as AnimationPlayer
		if not ap.has_animation(anim_name):
			print("--vitrina-anim=%s: %s nu are clipul (are: %s)"
				% [anim_name, stem, ", ".join(ap.get_animation_list())])
			return
		var anim := ap.get_animation(anim_name)
		# Seek la ULTIMUL cadru (poza deschisa/intinsa), nu la primul (bind
		# pose brut sau prima cheie, care pentru kea Idle e pozitia STRANSA —
		# vezi inventarul, exact ce vrem cand cerem Idle. Open cere ultimul
		# cadru pentru anvergura maxima, contract 1.0 m). `advance` cu
		# lungimea intreaga a clipului muta la ultimul cadru fara sa redea
		# bucla.
		ap.play(anim_name)
		ap.advance(anim.length)
		ap.seek(anim.length, true)
		print("--vitrina-anim=%s: %s la cadrul final (t=%.3f)"
			% [anim_name, stem, anim.length])


func _set_hippo_phase(root: Node, at: float) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var found := 0
	for node in root.find_children("*", "HippoHazard", true, false):
		var hippo := node as HippoHazard
		hippo.set("_time", clampf(at, 0.0, 0.999) * hippo.period)
		hippo._physics_process(0.0)
		hippo.set_physics_process(false)
		found += 1
		print("--hippo-at=%.2f: %s la y=%.2f (ridicare %.2f m din %.2f), sus=%s"
			% [at, hippo.name, hippo.global_position.y, hippo.lift_at(hippo.get("_time")),
			hippo.rise_m, hippo.is_up()])
	if found == 0:
		print("--hippo-at=%.2f: NICIUN hipopotam pe pista asta" % at)


## Aduce bolovanii cu traseu la `seconds` de la desprindere, simuland cadrele.
##
## Nu se poate sari direct la un timp: cu `stick_to_ground`, cota vine din
## raycast pe teren si dintr-o cadere libera care are memorie (viteza
## verticala) — deci se ruleaza `_physics_process` de la zero, cu pasul
## fizicii, DUPA ce serverul de fizica a apucat sa vada terenul (un cadru).
func _set_rock_time(root: Node, seconds: float) -> void:
	await get_tree().physics_frame
	var found := 0
	var step := 1.0 / 60.0
	for node in root.get_children():
		var rock := node as RockfallHazard
		if rock == null:
			continue
		rock.set("_time", 0.0)
		rock.set("_last_phase", 3)
		var t := 0.0
		while t < seconds:
			rock._physics_process(step)
			t += step
		# INGHETAT dupa simulare: pana la captura mai trec cadre (fizica ruleaza
		# normal) si piatra ar ajunge in alt loc decat cel tiparit — la vitezele
		# bombelor Stromboli, dincolo de capatul traseului, adica ASCUNSA.
		rock.set_physics_process(false)
		found += 1
		var body := rock.get("_rock") as Node3D
		var bp := body.global_position if body != null else rock.global_position
		print("--rock-at=%.2f: bolovan la (%.1f, %.1f, %.1f), trecere peste sosea la %.2f s, o trecere = %.2f s"
			% [seconds, bp.x, bp.y, bp.z,
			rock.get("_cross_time"), rock.get("_route_travel")])
	print("--rock-at=%.2f: %d bolovani mutati" % [seconds, found])


## Aduce avalansa (`AvalancheHazard`) la `seconds` de la INCEPUTUL ciclului
## (telegraf inclus), simuland cadrele — pe tiparul `_set_rock_time`.
##
## Nu se poate sari direct la faza `sweep`: gramada e NOUA corpuri
## `AnimatableBody3D` cu `sync_to_physics=true`, pozitionate din `_place_shards`
## in fiecare `_physics_process`, deci starea vizuala exista doar dupa ce
## simularea a rulat pasii ei, nu prin scrierea unui singur camp.
##
## `AvalansaF` e copil al nodului `Hazarduri`, nu al radacinii pistei (spre
## deosebire de `RockfallHazard`, gasit cu `root.get_children()`) — de aceea
## cautarea e recursiva, ca la `_set_hippo_phase`/`TrainHazard`.
func _set_avalanche_time(root: Node, seconds: float) -> void:
	await get_tree().physics_frame
	var found := 0
	var step := 1.0 / 60.0
	for node in root.find_children("*", "AvalancheHazard", true, false):
		var ava := node as AvalancheHazard
		if ava == null:
			continue
		ava.set("_time", 0.0)
		ava.set("_last_phase", -1)
		var t := 0.0
		while t < seconds:
			ava._physics_process(step)
			t += step
		# INGHETATA dupa simulare, ca la bolovan: fizica normala care mai ruleaza
		# pana la captura ar re-avansa ciclul si poza n-ar mai arata momentul cerut.
		ava.set_physics_process(false)
		found += 1
		var mass := ava.get("_mass") as Node3D
		var mp := mass.global_position if mass != null else ava.global_position
		var phase := "telegraf"
		if seconds >= AvalancheHazard.TELEGRAPH + AvalancheHazard.SWEEP:
			phase = "retragere"
		elif seconds >= AvalancheHazard.TELEGRAPH:
			phase = "traversare"
		# Cate bucati au trecut de axa drumului (X local < 0, coborand spre vale
		# pe +X local -> -X): contractul POI F cere sa se verifice in log ca
		# toate cele 9 bucati ajung la rau, nu doar ca masa containerului a plecat.
		#
		# NU se citeste `body.global_position`: bucatile sunt AnimatableBody3D cu
		# `sync_to_physics=true`, iar `_place_shards` scrie `.position` in
		# spatiul pe care serverul de fizica il aplica abia la urmatorul pas
		# REAL de fizica (nota din cod) — apelurile directe la `_physics_process`
		# de aici nu avanseaza acel server, deci pozitia citita ar fi veche.
		# Se recalculeaza cu ACEEASI formula ca `_place_shards`: centru + offset
		# (offset-ul nu se roteste, gramada isi pastreaza forma).
		var mass_local: Vector3 = mass.position if mass != null else Vector3.ZERO
		var shards: Array = ava.get("_shards")
		var past_road := 0
		for sh in shards:
			var off: Vector3 = sh.get("offset")
			if mass_local.x + off.x < 0.0:
				past_road += 1
		print("--avalanche-at=%.2f: %s, masa la (%.1f, %.1f, %.1f), faza %s, %d/%d bucati au trecut de axa drumului"
			% [seconds, ava.name, mp.x, mp.y, mp.z, phase, past_road, shards.size()])
	print("--avalanche-at=%.2f: %d avalanse mutate" % [seconds, found])


## Muta tromba intr-un moment ales din traversarea ei.
##
## Fractia e din ciclul complet dus-intors: 0.00 o pune pe axa soselei venind
## dinspre `travel_dir`, 0.25 la capatul maturarii, 0.50 din nou pe axa in sens
## invers. Fara steagul asta, captura o prinde la inceputul ciclului — adica taman
## in mijlocul drumului, ceea ce e util, dar niciodata nu poti fotografia
## traversarea in curs.
##
## `_apply_cycle(0.0)` cu delta zero: aseaza pozitia si inclinarea fara sa mai
## invarta palnia cu un pas de care nu are nevoie o poza.
func _set_typhoon_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.get_children():
		var typhoon := node as TyphoonHazard
		if typhoon == null:
			continue
		typhoon.set("_time", TyphoonHazard.PERIOD * clampf(at, 0.0, 0.999))
		typhoon.call("_apply_cycle", 0.0)
		found += 1
	print("--typhoon-at=%.2f: %d trombe mutate in ciclu" % [at, found])


## Muta valul intr-un moment ales din traversarea lui.
##
## Fractia e din ciclul complet: 0 il pune la marginea dinspre larg (abia intrat
## in cadru, telegrafierea), ~0.30 pe axa soselei, iar peste `ON_ROAD_FRAC +
## LEAD_TIME/PERIOD` valul e in larg si INVIZIBIL. Fara steag, captura il prinde
## unde s-a nimerit, si de cele mai multe ori asta inseamna „nicaieri" — exact
## felul in care o poza poate arata un hazard care lipseste ca pe unul in regula.
##
## `_advance(0.0)` cu delta zero: aseaza pozitia si vizibilitatea fara sa mai
## inainteze ceasul cu un pas de care o poza n-are nevoie.
func _set_wave_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.get_children():
		var wave := node as WaveSurge
		if wave == null:
			continue
		# Scazut defazajul: `at` inseamna acelasi lucru pe orice val de pe pista,
		# nu „at plus cat s-a nimerit sa fie faza fractiei lui".
		wave.set("_time", WaveSurge.PERIOD * (clampf(at, 0.0, 0.999) - wave.phase))
		wave.call("_advance", 0.0)
		found += 1
	print("--wave-at=%.2f: %d valuri mutate in ciclu" % [at, found])


## Muta podul mobil intr-un moment ales din ciclul lui.
##
## Ceasul podului merge pe bucla CORABIILOR (de doua ori mai lunga decat a
## traveei, vezi LiftBridgeHazard.SHIP_PERIOD), fiindca doar asa se stie care
## dintre cele doua corabii e in dreptul golului. Fractia ceruta e din bucla aia:
## 0.24 pune traveea sus cu prima corabie in gol, 0.74 la fel cu a doua.
## Muta pasajul rotativ intr-un punct din ciclul lui. Fara asta capturile ies
## in ce stare o fi nimerit ceasul — si acceptarea din brief cere anume starea
## DESCHISA („continua rampa"), care e cea de la faza 0.
func _set_span_phase(root: Node, at: float) -> void:
	var found := 0
	for node in root.get_children():
		var span := node as RotatingSpanHazard
		if span == null:
			continue
		span.set("clock_running", false)
		span.set("_started", true)
		span.set("_time", span.period * clampf(at, 0.0, 0.999))
		span.call("_apply_cycle", 0.0)
		found += 1
	print("--span-at=%.2f: %d pasaje rotative mutate in ciclu" % [at, found])


func _set_bridge_phase(root: Node, at: float) -> void:
	var found := 0
	# Recursiv: barnele din Machu Picchu stau sub un Node3D „Hazarduri", si
	# ritmul e al nodului (`period`), nu constanta clasei.
	for node in root.find_children("*", "LiftBridgeHazard", true, false):
		var bridge := node as LiftBridgeHazard
		if bridge == null:
			continue
		var t: float = float(bridge.call("_ship_period")) * clampf(at, 0.0, 0.999)
		bridge.set("_time", t)
		bridge.call("_apply_cycle", fposmod(t, bridge.period))
		found += 1
	print("--bridge-at=%.2f: %d poduri mobile mutate in ciclu" % [at, found])


func _smooth_organics(root: Node) -> void:
	const PREFIXES := ["cliff", "butte", "mesa", "cluster", "arch", "boulder",
		"rock", "pebbles", "bush", "portal", "dino", "bone"]
	var count := 0
	for node in _walk_meshes(root):
		var nm := String(node.name).to_lower()
		var hit := false
		for p in PREFIXES:
			if nm.begins_with(p):
				hit = true
				break
		if not hit or node.mesh == null:
			continue
		node.mesh = _smoothed(node.mesh)
		count += 1
	print("--smooth: %d mesh-uri organice cu normale netede" % count)


func _walk_meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var mi := node as MeshInstance3D
	if mi != null:
		out.append(mi)
	for c in node.get_children():
		out.append_array(_walk_meshes(c))
	return out


## Normale medii pe pozitie cuantizata: toate fetele care impart un varf isi
## amesteca normalele, deci suprafata curge in loc sa fie placi.
func _smoothed(mesh: Mesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for si in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(si)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var acc := {}
		var tri_count := idx.size() / 3 if idx.size() > 0 else verts.size() / 3
		for t in tri_count:
			var i0: int = idx[t * 3] if idx.size() > 0 else t * 3
			var i1: int = idx[t * 3 + 1] if idx.size() > 0 else t * 3 + 1
			var i2: int = idx[t * 3 + 2] if idx.size() > 0 else t * 3 + 2
			var fn := (verts[i1] - verts[i0]).cross(verts[i2] - verts[i0])
			for i in [i0, i1, i2]:
				var key := (verts[i] * 200.0).round()
				acc[key] = acc.get(key, Vector3.ZERO) + fn
		var normals := PackedVector3Array()
		normals.resize(verts.size())
		for i in verts.size():
			var key := (verts[i] * 200.0).round()
			normals[i] = (acc[key] as Vector3).normalized()
		arrays[Mesh.ARRAY_NORMAL] = normals
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out



## Ce obiect cade pe fiecare coloana din cadru, cu aceeasi camera ca poza.
##
## De ce e nevoie. `skyline_cones.py` raporteaza siluete dupa coloana X si
## atat. Cand reglezi un parametru de horn si cifra conului din stanga-fata nu
## se misca, sunt doua explicatii — parametrul n-are efect, sau conul ala nu e
## un horn. Fara lista asta se poate itera la nesfarsit pe prima.
func _cine_e_in_cadru(track: Node, cam: Camera3D) -> void:
	var rows: Array = []
	_proiecteaza(track, cam, rows)
	rows.sort_custom(func(a, b): return a[1] < b[1])
	print("CINE: obiecte cu peste 40 px inaltime, sortate pe coloana:")
	var spans: Array = []
	for r in rows:
		print("  x=%5d  h=%4d px  d=%5.1f m  %-24s %s"
			% [r[1], r[2], r[4], r[0], r[3]])
		var b: Rect2 = r[5]
		spans.append({
			"nume": r[0], "script": r[3], "x": r[1], "h_px": r[2],
			"d": snappedf(r[4], 0.1),
			"x0": int(floor(b.position.x)), "x1": int(ceil(b.end.x)),
			"y0": int(floor(b.position.y)), "y1": int(ceil(b.end.y)),
		})
	# Sidecar cu intervalele de coloane, ca sonda de pixeli sa poata masura
	# profilul DOAR inauntrul hornului numit. Fara el orice cifra de contur e
	# neatribuibila: runda 20 a demonstrat ca cel mai mare con din cadru e
	# TEREN de la 380 m, nu horn.
	var jdir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(jdir)
	var jout := "%s/cine_spans.json" % jdir
	var f := FileAccess.open(jout, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"view": [get_viewport().size.x, get_viewport().size.y],
			"obiecte": spans}, "  "))
		f.close()
		print("CINE-SPANS: ", jout)


func _proiecteaza(n: Node, cam: Camera3D, out: Array) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null and mi.is_visible_in_tree():
		var ab: AABB = mi.global_transform * mi.mesh.get_aabb()
		var ctr := ab.get_center()
		if not cam.is_position_behind(ctr):
			var p := cam.unproject_position(ctr)
			if p.x > -300.0 and p.x < 1580.0:
				var top := cam.unproject_position(
					Vector3(ctr.x, ab.position.y + ab.size.y, ctr.z))
				var bot := cam.unproject_position(
					Vector3(ctr.x, ab.position.y, ctr.z))
				var hpx := int(absf(bot.y - top.y))
				if hpx > 40:
					var own := n
					while own != null and own.get_script() == null:
						own = own.get_parent()
					var scr := "-"
					var nm := String(mi.name)
					if own != null:
						scr = String(own.get_script().resource_path.get_file())
						nm = String(own.name)
					var box := _cutie_ecran(ab, cam)
					out.append([nm, int(p.x), hpx, scr,
						cam.global_position.distance_to(ctr), box])
	for c in n.get_children():
		_proiecteaza(c, cam, out)


## Cutia pe ecran a unui AABB din lume: TOATE cele 8 colturi proiectate.
##
## De ce 8 colturi si nu centrul. Coloana de ecran a unui obiect e ce trebuie sa
## stie sonda de silueta ca sa masoare NUMAI hornul si nu vecinul; un singur
## punct (centrul) da o coloana, nu un interval, si atunci sonda tot ghiceste
## unde se termina obiectul. Un colt in spatele camerei ar da o proiectie
## intoarsa, deci se sare peste el si cutia ramane a colturilor vizibile.
func _cutie_ecran(ab: AABB, cam: Camera3D) -> Rect2:
	var r := Rect2()
	var first := true
	for i in 8:
		var c := ab.position + Vector3(
			ab.size.x if (i & 1) != 0 else 0.0,
			ab.size.y if (i & 2) != 0 else 0.0,
			ab.size.z if (i & 4) != 0 else 0.0)
		if cam.is_position_behind(c):
			continue
		var q := cam.unproject_position(c)
		if first:
			r = Rect2(q, Vector2.ZERO)
			first = false
		else:
			r = r.expand(q)
	return r


## Cea mai apropiata [CameraZone] de un punct de pe traseu, sau null.
##
## Cauta pe TOT arborele pistei fiindca zonele stau grupate intr-un nod propriu
## in .tscn (ZoneCamera/...), nu direct sub radacina.
func _nearest_cave_zone(track: Node, at: Vector3,
		frac: float = -1.0) -> CameraZone:
	var best: CameraZone = null
	var best_d := INF
	for node in track.find_children("*", "Area3D", true, false):
		var z := node as CameraZone
		if z == null:
			continue
		# INTERVALUL DE FRACTIE BATE DISTANTA, cand zona il declara. O zona pe
		# interval (gatul, elicea) are cutia redusa la un marcaj de 2 m, deci
		# „cea mai apropiata" ar alege-o aproape niciodata — si mai rau, pe
		# elice distanta e ambigua prin constructie: cele doua ture trec prin
		# acelasi loc in plan. Fractia raspunde exact, si e chiar criteriul pe
		# care il foloseste zona in joc, deci captura si jocul nu pot diverge.
		if z.frac_to > z.frac_from and frac >= 0.0:
			var inside := (frac >= z.frac_from and frac <= z.frac_to) 				if z.frac_from <= z.frac_to 				else (frac >= z.frac_from or frac <= z.frac_to)
			if inside:
				return z
			continue
		# Zona pe CUTIE: se ia doar daca punctul e chiar in cutia ei (cu o
		# marja de 3 m), exact cum o decide `Area3D`-ul in joc. Prima versiune
		# lua „cea mai apropiata sub 120 m", si la frac 0.93 pe elice (40 m de
		# Sala 2, dar in afara cutiei ei) captura primea presetul salii cu
		# tavan de 18 m — o camera care in joc nu exista acolo. Masurat pe
		# 3 sep 2026; captura fusese citita ca „butoi inchis".
		var lp := z.to_local(at)
		var half := z.size * 0.5
		var inside_box := absf(lp.x) <= half.x + 3.0 and absf(lp.z) <= half.z + 3.0 			and lp.y >= -3.0 and lp.y <= z.size.y + 3.0
		if not inside_box:
			continue
		var d := z.global_position.distance_to(at)
		if d < best_d:
			best_d = d
			best = z
	return best
