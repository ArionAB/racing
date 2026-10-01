#!/usr/bin/env bash
# Verifica kitul Jodhpur fata de contractul din
# docs/asset_briefs/jodhpur_kit.md. Ca `verify_fiordland.sh`: o rulare, un
# verdict, exceptiile DECLARATE aici.
#
#     bash tools/blender/verify_jodhpur.sh
#
# Structura: fiecare val al brief-ului (§3) adauga liniile lui aici. Valul 1
# (pilotul, §1.1) e primul si singurul complet la scrierea asta.
#
# Exceptii, fiecare cu motivul:
#
#   --origin=assembly   ghanta_ghar: 3 noduri (Tower_Stone, Clock_Glow,
#                       Tower_Glow) cu origine COMUNA -- Clock_Glow/
#                       Tower_Glow sunt geometrie mica, ingropata in peretii
#                       lui Tower_Stone, si nu ating solul separat prin
#                       constructie (aceeasi capcana ca la Machu Picchu/
#                       Fiordland: `finish()` per nod le-ar re-centra
#                       independent si ansamblul s-ar desface).
#
#                       blue_house_a: 3 noduri (House_Wall, House_Trim,
#                       House_Rail) cu acelasi motiv -- House_Trim (usa,
#                       obloanele) si House_Rail (balustrada scarii) nu ating
#                       solul la baza LOR proprie de bounding box.
#
#                       fort_gate_jai/fateh/loha: 2 noduri (*_Stone, *_Doors)
#                       -- canaturile deschise (*_Doors) nu ating solul la
#                       baza lor proprie de bounding box (balamale sus pe
#                       perete, canatul se roteste deschis). rampart_cannon:
#                       2 noduri (Cannon_Metal, Cannon_Wood) -- teava e
#                       inclinata ~10 deg si nu atinge solul la baza proprie.
#
#                       fort_gate_*: runda fort3 adauga *_Glow (fante, nise,
#                       puncte de merlon) -- tot origine comuna.
#
#                       fort_wall_turret (runda fort2): 2 noduri (Turret_Stone,
#                       Turret_Glow) -- fantele de tragere (Turret_Glow) sunt
#                       geometrie mica, la ~11 m inaltime pe corp, nu ating
#                       solul separat, acelasi motiv ca fort_wall_segment.

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/jodhpur"

fail=0
check() {  # check <cale> <buget> [flag...]
  local f="$ROOT/$1"; local budget="$2"; shift 2
  if [ ! -f "$f" ]; then
    printf "%-38s LIPSESTE\n" "$(basename "$f")"; fail=1; return
  fi
  local out verdict
  out=$(python tools/blender/verify_glb.py "$f" "$budget" "$@" 2>&1)
  verdict=$(printf '%s' "$out" | grep -o "VERDICT: [A-Z]*" | head -1)
  local tris
  tris=$(printf '%s' "$out" | grep -o "TOTAL: [0-9]* tris" | grep -o "[0-9]*")
  printf "%-38s %-16s %8s tris\n" "$(basename "$f")" "${verdict:-FARA VERDICT}" "${tris:-?}"
  printf '%s' "$out" | grep -q "VERDICT: OK" || { fail=1; printf '%s\n' "$out" | grep "!!"; }
}

echo "== pilotul (brief §1.1, val 1) =="
# Bugetele au crescut fata de v1 (5200/1800) odata cu rescrierea pe
# vocabularul de forme (arcade/dome/chhatri/solid_stair reale, nu cutii
# tesite). v3 (runda 3 -- forme corectate dupa critic+sef) a scazut fata
# de v2 (8154 vs 10156 turn): panourile "box-margin" (fix runda 3) sunt mai
# ieftine decat inelul radial vechi.
check "buildings/ghanta_ghar.glb"   8600 --origin=assembly
check "buildings/blue_house_a.glb"  5300 --origin=assembly

echo "== reperele (brief §1.3, val 2b) =="
# market_gate: 3 noduri (Gate_Stone, Gate_Doors, Gate_Glow) -- origine comuna
# pe ansamblu, ca la pilot (canaturile/fantele nu ating solul separat).
# stepwell_pavilion, jaswant_thada: idem (Well_Glow/Thada_Glow ingropate).
# stepwell_flight_module/_corner: decor pur, un singur nod, origine simpla la
# baza (brief §1.3: "fara coliziune, coliziunea e a terenului").
# market_gate 10500 -> 21500 (escaladare Opus): 21048 masurat. Panoul e acum
# o prisma manifold cu gol real (nu 4 dreptunghiuri), chhatri-urile au 24 de
# arcade reale, iar `densify_for_ao` taie fetele de 12 m (~4400 tri) ca AO-ul
# copt pe varf sa nu le innegreasca -- o singura instanta pe pista.
check "structures/market_gate.glb"             21500 --origin=assembly
check "structures/stepwell_flight_module.glb"   3600
check "structures/stepwell_corner.glb"          2400
check "structures/stepwell_pavilion.glb"       12000 --origin=assembly
check "structures/jaswant_thada.glb"           15000 --origin=assembly
echo "== cetatea (brief §1.2, val 2a) =="
# Bugetele: masurate dupa build, cu marja mica pentru iteratii ulterioare de
# fidelitate (crenelurile marite de doua ori dupa --compare au crescut usor
# tri-count-ul fata de prima versiune). rampart_cannon a primit buget mai
# mare (3000 -> 3300) dupa rescrierea rotii cu spite vizibile (janta+butuc+
# bare, nu disc plin fara relief).
check "structures/fort_wall_segment.glb"  3000 --origin=assembly
check "structures/fort_wall_turret.glb"   2900 --origin=assembly
check "structures/fort_bastion.glb"       5500 --origin=assembly
# Portile, runda fort3 (rescrise pe decupare): 3 noduri (*_Stone, *_Doors,
# *_Glow -- fantele, nisele si punctele merlonilor au iesit din *_Stone in
# nod GLOW propriu, regula GLOW, ca la zid/turn). Bugetul e PE NOD.
# Jai/Loha *_Stone 10280/10184 (turnuri octogonale cu 16 merloni kangura
# fiecare, cortina-grila de 5 m adancime, densify_for_ao pe fetele de 11 m).
# Fateh 12600 -> 14600: chhatri-ul peste arc costa singur ~4000 tri
# (6 arce deschise + cupola, din vocabular); masurat 14324.
check "structures/fort_gate_jai.glb"      10600 --origin=assembly
check "structures/fort_gate_fateh.glb"    14600 --origin=assembly
check "structures/fort_gate_loha.glb"     10600 --origin=assembly
# palace_facade_a/b: bugetul a crescut fata de val 2a/escaladare (a 11128->
# 13148, b 17292->19312) dupa runda de corectii fort2 -- vocabularul reparat
# (arch_opening pe gol real, nu "T") a mutat Palace_Stone la 17072 tri
# INAINTE de aceasta runda (deja documentat in inventar), iar fix-ul
# ferestrelor fatadei B (pozitie + sticla vizibila) a adaugat geometrie
# LEGITIMA: placa de sticla era o singura fata (normala gresita, randa
# invizibila) si a devenit o placa subtire inchisa (fata+spate+laturi) ca
# `recalc_face_normals` sa o orienteze corect -- cost mic, cerut de
# contractul vizual (geamuri inchise REALE), nu geometrie de umplutura.
# Runda fort3 (fatadele rescrise pe perete-grila, dupa verdictul "A aproape
# goala, B ferestre rare"): a 15000 -> 17000 (masurat 16772), b 20000 ->
# 20500 (masurat 19990), cu bevel 0 (bevel-ul de 3,5 cm dubla cifra la
# 39k/45k pe ramele si baluștrii ferestrelor). Costul e densitatea ceruta de
# decupare: A are 26 de goluri pe fatada + 6 arce mari + 2 jharokha, B 28 de
# goluri + 6 edicule + 2 jharokha + 3 cupole; `facade_bays` sparge peretele
# in travee ca grila sa nu propage fiecare coloana pe toata lungimea.
check "structures/palace_facade_a.glb"    17000 --origin=assembly
check "structures/palace_facade_b.glb"    20500 --origin=assembly
check "props/rampart_cannon.glb"          4200 --origin=assembly

echo "== orasul albastru (brief §1.4, val 3) =="
# Casele: origine COMUNA pe ansamblu (--origin=assembly), ca la pilot/
# cetate -- House_Trim (usi), House_Glow (geamuri) si House_Rail
# (balustrade/scari) sunt geometrie mica/suspendata care NU atinge solul la
# baza EI proprie de bounding box (usile sunt goluri in perete la orice
# inaltime, scarile/balustradele incep de la z=0 dar pe un bbox propriu
# offset). haveli_facade: un singur nod compus (House_Wall+House_Trim), tot
# --origin=assembly pentru acelasi motiv (usile arcadelor nu ating solul
# separat).
# haveli_facade 900 -> 912 (runda de corectii dupa verdictul "PICATA"):
# bug real de axa (arcada era pe fata de 6 m, nu pe cei 10 m latime -- brief
# "fatada LATA") plus trecerea de la 3 la 4 arcade/ferestre pe rand (decuparea
# arata 4). Merloanele au fost rarite de 2 ori (176 tri economisiti) ca sa
# incapa cat mai aproape de 900; cei 12 tri ramasi sunt cost ireductibil fara
# sa piarda siluieta crenelata -- vezi jurnalul din build_jodhpur_city.py.
# rooftop_clutter: rufele (Clutter_Laundry) folosesc CAR_YELLOW (14-16,
# excepie pe NUME de nod, --allow-car-slots) si FLAMINGO_PINK=31 (rezerva,
# excepie pe SLOT, --allow-slots -- deja legalizat de Serengeti/palette.gd
# pentru exact acest roz, vezi comentariul din verify_glb.py).
check "buildings/blue_house_b.glb"    6000 --origin=assembly
# blue_house_c 3800 -> 4600 (runda 3, verdict "cub prea mare, golurile in
# colt"): peretii cu goluri sunt acum grila `facade()` (build_jodhpur_city.py)
# pe DOUA fete, cu rame, glafuri si tocuri de lemn, plus parapet adevarat;
# masurat 4430.
check "buildings/blue_house_c.glb"    4600 --origin=assembly
check "buildings/blue_house_d.glb"    6500 --origin=assembly
check "buildings/blue_house_e.glb"    6500 --origin=assembly
# haveli_facade 912 -> 4900 (runda 3, PESTE brief-ul de 900 -- acceptat de
# DEZVOLTATOR 29 sep 2026, cu tenta light): verdictul "arcade in Y, usi maro in loc de geamuri, albastru-
# marin" cerea lista completa de pe decupare: 4 goluri arcuite la parter (2
# arcade mari cu usi de lemn), jharokha cu 3 arce + balcon cu baluștri +
# streasina, 2 ferestre arcuite laterale, latura +X cu fereastra, 2 ferestre
# inalte si balconas, terasa cu baluștri intre stalpi cu varf, chhatri cu
# cupolita. Doar cele 12 goluri arcuite cu rame costa ~1400. Masurat 4796, cu
# bevel 0 (bevel-ul de 2 cm tripla cifra la 11502 pe baluștri si rame).
check "buildings/haveli_facade.glb"   4900 --origin=assembly
check "props/rooftop_tank.glb"         700
check "props/rooftop_clutter.glb"     1400 --origin=assembly --allow-car-slots=Clutter_Laundry --allow-slots=31

echo "== bazarul (brief §1.5, val 3b) =="
# Toate cu origine COMUNA pe ansamblu (--origin=assembly): copertinele au
# Canopy/Goods geometrie mica ce nu atinge solul la baza EI proprie; sacii au
# conurile de condiment deasupra gurii sacului; caruciorul are rotile pe axa
# proprie; ceainaria are oalele pe tejghea; ghirlanda atarna intreaga sub z=0
# relativ la un capat, origine comuna pastreaza catenara intacta.
# Sloturi de accent (marfa/condimente/fructe): CAR_RED/CAR_YELLOW (14-16,
# excepie pe NUME de nod, --allow-car-slots) + LAVA_ORANGE=30 (legal, 24-29
# Baikal + 30 Stromboli deja in LEGAL_SLOTS -- fara nevoie de exceptie).
# textile_strip: FLAMINGO_PINK=31 pe 2 din cele 7 panze (--allow-slots=31,
# acelasi caz ca rooftop_clutter).
check "props/stall_canopy_a.glb"      1600 --origin=assembly --allow-car-slots=Goods
check "props/stall_canopy_b.glb"      1600 --origin=assembly --allow-car-slots=Goods
check "props/stall_canopy_c.glb"      1600 --origin=assembly --allow-car-slots=Goods
check "props/textile_strip.glb"       1600 --origin=assembly --allow-car-slots=Cloth --allow-slots=31
check "props/spice_sacks.glb"         1400 --origin=assembly --allow-car-slots=Spice
# thela_cart 3100 -> 3288 (runda de corectii, "PICATA"): rotile erau
# ingropate in disc (spoke_y < half-thickness -- fix in _wheel, tools/blender/
# build_jodhpur_bazaar.py) si fructele un rand subtire, nu o gramada. Vezi
# jurnalul de la emit() din build_jodhpur_bazaar.py.
# thela_cart 3288 -> 3700 (runda 3, "fructe-cuburi, roti-discuri la
# colturi"): roti DESCHISE (janta din 14 grinzi + 10 spite + butuc) sub tava,
# gramada bombata din fructe sferice pe 3 zone; bevel 0. Masurat 3632.
check "props/thela_cart.glb"          3700 --origin=assembly --allow-car-slots=Cart_Fruit
# chai_stall 1600 (runda 3, refacuta dupa "tejghele stivuite"): doua
# tejghele alaturate, masuta, 4 oale, copertina inclinata cu volan; bevel 0.
check "props/chai_stall.glb"          1600 --origin=assembly
check "props/marigold_garland.glb"     800

echo "== traficul (brief §1.5, val 4a) =="
# tuktuk: contract `Car` (car.gd:2431-2470). --origin=assembly: rotile sunt
# noduri cu PIVOT in centrul osiei (translation != 0, baza identitate), deci
# nu au baza la Y=0 pe nodul lor; ansamblul atinge solul prin talpa rotilor.
# --allow-car-slots: CAR_YELLOW pe acoperis si cowl, CAR_RED pe stopuri --
# exceptia declarata de brief. Fara --front: la un vehicul latura (X) are
# mereu mai multa arie decat botul (Z); orientarea botului (+Z in GLB, -Z in
# joc dupa model_rotation_deg 180) e verificata in Godot, nu aici.
# runda 2 (plan trapez, acoperis curbat, carena rotunjita): 3632 -> 5060 tri.
check "vehicles/tuktuk.glb"           5200 --origin=assembly --allow-car-slots=Tuktuk_Roof,Tuktuk_Body

echo "== teatrul mobil (brief §1.6, val 4 grupa C) =="
# Bugetul e PE NOD (verify_glb compara fiecare nod cu el).
# baraat_horse: schelet + actiunile Walk/Idle; 3 noduri skinnuite (Horse,
# Saddle, Rider) cu origine COMUNA -- valtrapul si mirele nu ating solul.
# Exceptii: Saddle (valtrap rosu/albastru/galben, panglici) si Rider
# (turbanul si pelerina mirelui) pe sloturile de masina -- declarate de
# brief §1.6; FLAMINGO_PINK=31 pe panglicile cozii si ciucuri (--allow-slots,
# acelasi caz ca rooftop_clutter). Cel mai mare nod: Saddle ~950.
check "animals/baraat_horse.glb"   1000 --origin=assembly --allow-car-slots=Saddle,Rider --allow-slots=31
# baraat_band: 4 noduri, cate unul pe figura, ca bugetul de <= 400 tri pe
# figura (brief) sa fie verificat de garda, nu doar declarat. Turbanele,
# pelerinele, esarfele (CAR_RED) si trompeta (CAR_YELLOW) sunt accente de
# masina -> exceptie pe prefixul Band.
check "props/baraat_band.glb"       400 --origin=assembly --allow-car-slots=Band
# zipline_rider: ORIGINEA IN SCRIPETE (brief §1.6) -- figura ATARNA sub Y=0
# si atinge 0 in varful rotitei, adica exact contractul --origin=rim.
# Casca CAR_YELLOW si bluza CAR_RED pe nodul Zip_Rider. Cota scripete-talpi
# e 1,65 m (lonja scurta ca pe decupare; brief §1.6), nu 2,2 m -- garda nu
# are prag pe inaltime, doar pe ancorare.
check "props/zipline_rider.glb"     500 --origin=rim --allow-car-slots=Zip_Rider

echo "== animalele (brief §1.6, val 4 grupa B) =="
# build_jodhpur_animals.py. Bugetele = masurat + marja mica (fara plafon in
# brief; animalele nu sunt multiplicate in masa).
# zebu_cow: 2 noduri pielite pe acelasi schelet (Cow_Body + Bell) cu origine
# COMUNA (--origin=assembly): clopotelul atarna la piept si nu atinge solul.
# --allow-car-slots=Bell: clopotelul e CAR_YELLOW (brief §1.6, exceptie
# declarata acolo). --allow-slots=31: ugerul roz (FLAMINGO_PINK, slotul
# pistei, palette.gd:140) -- e pe decupare.
check "animals/zebu_cow.glb"          2900 --origin=assembly --allow-car-slots=Bell --allow-slots=31
# black_kite_bird: originea in CENTRUL corpului (--origin=center, brief:
# zboara pe curba cu stick_to_ground = false). --allow-car-slots=Kite:
# ciocul e CAR_YELLOW, cerut de tabelul §1.6.
check "animals/black_kite_bird.glb"    600 --origin=center --allow-car-slots=Kite
# paunii: gat/piept CAR_BLUE, ochii trenei CAR_BLUE pe CAR_YELLOW (brief
# §1.6, --allow-car-slots=Peacock).
check "animals/peacock_closed.glb"    3000 --allow-car-slots=Peacock
check "animals/peacock_fanned.glb"    4800 --allow-car-slots=Peacock
check "animals/langur.glb"            1100

echo "== fundalul (brief §1.7, val 5 grupa fundal) =="
# build_jodhpur_horizon.py. UN GLB, 4 noduri radacina la origine (conventia
# fiordland_horizon): UmaidBhawan_A, FarCity_A (+ copiii FarCity_A_Beige,
# FarCity_A_Glow), DesertRidge_A, DesertRidge_B. Bugetul e PE NOD; plafonul
# brief-ului (<= 5.000 tri TOTAL) il verifica build-ul (masurat 4752).
# --origin=assembly: FarCity_A_Glow (geamurile, 4,8-9,2 m) nu atinge solul
# pe nodul lui -- origine COMUNA cu FarCity_A. Nicio exceptie de slot.
check "rocks/jodhpur_horizon.glb"    2100 --origin=assembly

echo "== natura si candelele (brief §1.7, val 5 grupa natura) =="
# build_jodhpur_nature.py. Bugetele sunt plafoanele BRIEF-ului (contract, nu
# estimare): stanca <= 200, euforbia <= 300, copacii <= 400, diya <= 24,
# floating_diya <= 40. verify_glb compara bugetul PE NOD; la copaci (Trunk +
# Crown) totalul de <= 400 il verifica build-ul (`bugete depasite: 0`).
# Copacii: --origin=assembly -- Crown nu atinge solul la baza lui proprie.
# Candelele: O SINGURA plasa (FlockProp ia primul MeshInstance3D); TILE_TERRACOTTA
# e interzis pe gresie, dar corect pe lut ars (brief §1.7).
check "rocks/rhyolite_boulder_a.glb"    200
check "rocks/rhyolite_boulder_b.glb"    200
check "rocks/rhyolite_boulder_c.glb"    200
check "rocks/rock_slab.glb"             200
check "plants/euphorbia.glb"            300
check "plants/neem_tree.glb"            400 --origin=assembly
check "plants/khejri_tree.glb"          400 --origin=assembly
check "props/diya.glb"                   24
check "props/floating_diya.glb"          40

echo
total=$(find "$ROOT" -name '*.glb' 2>/dev/null | wc -l)
echo "GLB-uri in $ROOT: $total"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
