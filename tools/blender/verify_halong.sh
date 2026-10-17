#!/usr/bin/env bash
# Verifica tot kitul Ha Long fata de contractul din
# docs/asset_briefs/halong_kit.md §1.1-§1.9.
# Ca `verify_machupicchu.sh`: o rulare, un verdict, exceptiile DECLARATE aici.
#
#     bash tools/blender/verify_halong.sh
#
# DOUA straturi de verificare, si al doilea e specific pistei:
#
#   1. `verify_glb.py` — contractul generic (nume de noduri, buget de
#      triunghiuri, sloturi legale, AO copt, origine, orientare);
#   2. `verify_karst_profile.py` — SILUETA turnurilor. Contractul care face
#      roca sa citeasca "Ha Long" si nu "deal tropical": nisa de val la baza,
#      cu peretele iesit in consola deasupra ei. `verify_glb.py` ar trece
#      fara sa clipeasca peste un con perfect, fiindca forma nu e in contractul
#      lui generic.
#
# Scris INAINTE de prima piesa din Blender, cum cere brief §3: o garda adaugata
# dupa ce piesele exista ajunge sa fie reglata pe ele.
#
# Exceptii, fiecare cu motivul:
#
#   --allow-car-slots   slotul 15 (CAR_BLUE) pe BUTOAIELE de plastic de sub
#                       plute si tarcuri. Brief §0.4 il declara explicit: e
#                       singurul albastru saturat din atlas, iar butoaiele sunt
#                       accentul care spune "sat plutitor vietnamez" (promptul
#                       de diorama le numeste "the single strongest accent").
#                       Masurat pe plansa: 1,07% din pixelii de obiect, adica
#                       exact "in petice mici".
#
#   --allow-slots=7     slotul 7 (KERB_RED) pe VELA joncii. Accent declarat in
#                       brief §0.4; jonca e hazardul de la canal, deci vela e
#                       semnal de gameplay, nu decor. 1,63% din plansa.
#
#   --origin=assembly   piesele COMPUSE la care nu tot ce e in GLB atinge solul:
#                       floating_house_* (puntea si plasele incep peste nivelul
#                       plutei), fish_farm (ramele plutesc pe butoaie),
#                       fishing_junk si sampan_a (carena are chila sub linia de
#                       plutire, catargul si copertina sus), belvedere_pavilion
#                       (acoperisul e un nod separat care incepe la ~2,5 m),
#                       karst_horizon_* (siluete de fundal, corpuri suprapuse),
#                       macaque (doua poze in acelasi GLB, a doua nu e sub
#                       prima).
#                       Pe ele, offsetul de origine se ia O DATA pe ansamblu:
#                       altfel `finish` re-centreaza fiecare nod pe bbox-ul LUI
#                       si piesa se desface (memoria
#                       `finish-recentreaza-fiecare-nod-separat`).
#
#   MODULARE            coast_parapet, stone_dike, stone_quay si fish_farm au
#                       capete plane la x = ±jumatate, ca sa se insiruie. Trec
#                       pe --origin=base cu un AVERTISMENT de necentrare, care
#                       e corect si intentionat; avertismentul nu pica scriptul.
#
# CE NU SE VERIFICA AICI, fiindca nu se exporta deloc (brief §1.10): tablierul
# de ponton si butoaiele lui (le face `_build_visual()` + pontoon_road.gdshader),
# terasa de abraziune (TrackBranch), foaia de maree (TideHazard), masa
# turnurilor si a insulei (TerrainPeak), suprafata marii (tema). Din kit vine
# SILUETA, nu volumul.

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/halong"

fail=0
check() {  # check <cale> <buget> [flag...]
  local f="$ROOT/$1"; local budget="$2"; shift 2
  if [ ! -f "$f" ]; then
    printf "%-38s LIPSESTE\n" "$(basename "$f")"; fail=1; return
  fi
  local out verdict tris
  out=$(python tools/blender/verify_glb.py "$f" "$budget" "$@" 2>&1)
  verdict=$(printf '%s' "$out" | grep -o "VERDICT: [A-Z]*" | head -1)
  tris=$(printf '%s' "$out" | grep -o "TOTAL: [0-9]* tris" | grep -o "[0-9]*")
  printf "%-38s %-16s %8s tris\n" "$(basename "$f")" "${verdict:-FARA VERDICT}" "${tris:-?}"
  printf '%s' "$out" | grep -q "VERDICT: OK" || { fail=1; printf '%s\n' "$out" | grep "!!"; }
}

# --origin=assembly pe turnuri: nodul `Tower_Scrub` (tufele de pe creasta)
# incepe prin constructie la cota varfului, nu la 0 — verificat pe GLB,
# `Tower_Rock` merge de la 0,00 la 9,00 iar `Tower_Scrub` de la 9,01 la 9,44.
# Garda per-nod ar raporta "baza nu e la Y=0" aratand spre vegetatie. E exact
# cazul declarat la §0 pentru piesele compuse.
echo "== hero: turnurile de carst =="
check "rocks/karst_tower_a.glb"              900 --origin=assembly
check "rocks/karst_tower_b.glb"              900 --origin=assembly
check "rocks/karst_tower_c.glb"             1000 --origin=assembly
check "rocks/karst_stack_a.glb"              400 --origin=assembly
check "rocks/karst_stack_b.glb"              400 --origin=assembly
check "rocks/shore_boulder.glb"              150

echo
echo "== grota =="
# --origin=assembly: piesa e COMPUSA. `Portal_Rock` atinge solul (min Y = 0,000
# pe GLB), dar `Portal_Dark` — fundul intunecat vizibil prin gol si stalactitele
# scurte — incepe la 0,10 m si NU trebuie sa atinga pragul: ar astupa exact
# golul pe care il incadreaza. Garda per-nod raporta corect "baza nu e la Y=0"
# aratand spre interiorul grotei.
check "structures/grotto_portal.glb"         700 --origin=assembly

echo
echo "== satul plutitor =="
check "buildings/floating_house_a.glb"       600 --origin=assembly --allow-car-slots=House_Drums
check "buildings/floating_house_b.glb"       600 --origin=assembly --allow-car-slots=House_Drums
check "structures/fish_farm.glb"             400 --origin=assembly --allow-car-slots=Farm_Drums
check "props/net_drying_rack.glb"            250
# --origin=assembly: cheiul e si el COMPUS. `Quay_Stone` atinge solul (min Y =
# 0,00 pe GLB), dar `Quay_Fittings` — babalele de pe coronament si cauciucurile
# de amortizare de pe fata dinspre apa — incepe la 0,53 m si NU trebuie sa
# atinga pamantul. Garda per-nod raporta corect "baza nu e la Y=0" aratand spre
# cauciucuri. Flagul verifica in continuare ca ANSAMBLUL atinge solul, deci nu
# slabeste nimic: un chei care ar pluti tot ar pica si acum.
check "structures/stone_quay.glb"            350 --origin=assembly

echo
echo "== barci =="
# --origin=waterline, nu `assembly` + `--front=-Z`, si asta e o CORECTIE a
# garzii, nu o relaxare ca sa treaca piesele:
#
#  1. `waterline` e contractul fizic al unei barci — Y=0 e nivelul marii, chila
#     coboara sub el, puntea sta peste. E MAI STRANS decat `assembly`: o barca
#     exportata cu baza la zero (deci plutind cu totul peste apa, ca o jucarie
#     pe gresie) pica acum, iar cu `assembly` trecea. Exact flagul cu care
#     Okinawa verifica feribotul, cargoul si barca de pescuit
#     (verify_okinawa_v2.sh:118-120).
#  2. `--front=-Z` nu se poate folosi pe o CARENA. Verificarea compara ARIA
#     fetelor orientate pe X cu cea pe Z (verify_glb.py:388-390), ce merge
#     pentru un semn plat. La o barca, bordurile lungi privesc pe +/-X si
#     capetele ascutite pe +/-Z, deci o barca CORECT orientata raporteaza
#     mereu "plan dominant X". Masurat pe GLB-urile de aici: jonca are
#     lungimea pe Z (12,00 m pe Z, 4,60 pe X) si sampanul la fel — orientarea
#     cerut de brief §1.4 e respectata, doar testul masura altceva. Lungimea pe
#     Z e verificata mai jos, pe cifra.
check "vehicles/fishing_junk.glb"            800 --origin=waterline --allow-slots=7
check "vehicles/sampan_a.glb"                400 --origin=waterline
check "vehicles/basket_boat.glb"             200 --origin=waterline

echo
echo "== drum =="
check "structures/coast_parapet.glb"         200
check "structures/stone_dike.glb"            250

echo
echo "== vegetatie =="
# --origin=assembly pe piesele cu FRUNZIS separat, din exact acelasi motiv ca
# la turnuri (`Tower_Scrub`): o planta se sparge in lemn + frunze, fiindca la
# integrare lemnul si frunzisul iau sloturi diferite (brief §0.6). Nodul de
# frunze NU atinge niciodata pamantul — masurat pe GLB, `Ficus_Wood` merge de
# la 0,000 la 5,486 iar `Ficus_Leaf` de la 4,072 la 5,777. O garda per-nod ar
# cere ca frunzele sa stea pe sol, ceea ce ar fi o planta culcata.
# `scrub_tuft` rtamane pe --origin=base: tufa e UN nod (miez + frunze impreuna,
# la 0,8 m nu merita spart), deci regula per-nod i se aplica si trebuie sa stea
# pe sol.
# 500, nu 400: coroana remodelata (lata si joasa, dupa verdictul la volan)
# costa mai mult decat una ingusta pe trunchi lung.
check "plants/karst_ficus_a.glb"             500 --origin=assembly
check "plants/karst_ficus_b.glb"             500 --origin=assembly
check "plants/bamboo_clump.glb"              300 --origin=assembly
check "plants/scrub_tuft.glb"                120

echo
echo "== belvedere =="
check "structures/belvedere_pavilion.glb"    700 --origin=assembly

echo
echo "== animale =="
check "animals/macaque.glb"                  350 --origin=assembly

echo
echo "== fundal =="
# UN fisier cu TREI noduri, nu trei fisiere — corectat fata de brief §1.9 dupa
# ce s-a citit consumatorul, nu brief-ul (memoria `brief-cere-glb-cod-il-face-
# deja`, care a costat 4 piese fara consumator pe Machu Picchu).
#
# `Track._build_horizon` incarca UN singur `horizon_model` per tema si scoate
# din el cate un nod pe nume, prin `_extract_glb_node` + steagul `horizon_picks`
# (track.gd:6251-6256). Trei fisiere separate ar insemna ca doua dintre ele nu
# s-ar incarca NICIODATA: tema n-are decat o cheie. Acelasi tipar la toate
# pistele cu fundal propriu — `fiordland_horizon.glb` are 4 noduri
# (FarWall_A/B, SnowRidge_A/B), `kyoto_horizon.glb` si `jodhpur_horizon.glb` la
# fel. Bugetul e suma celor trei planuri din brief (600+500+400).
check "rocks/halong_horizon.glb"            1500 --origin=assembly

# --- SILUETA: contractul propriu al pistei -----------------------------------
#
# Se ruleaza DUPA bugete, fiindca o piesa care nici nu exista n-are siluetă de
# masurat, si pe turnurile mari plus stack-uri. `shore_boulder` nu intra: un
# bolovan de 2,5 m n-are nisa de val si nici n-ar trebui sa aiba.
echo
echo "== silueta turnurilor (brief §1.1) =="
PROFILE_TARGETS=""
for p in rocks/karst_tower_a.glb rocks/karst_tower_b.glb rocks/karst_tower_c.glb \
         rocks/karst_stack_a.glb rocks/karst_stack_b.glb; do
  [ -f "$ROOT/$p" ] && PROFILE_TARGETS="$PROFILE_TARGETS $ROOT/$p"
done
if [ -n "$PROFILE_TARGETS" ]; then
  # shellcheck disable=SC2086
  python tools/blender/verify_karst_profile.py $PROFILE_TARGETS || fail=1
else
  echo "  (nicio piesa de turn exportata inca)"
fi

# --- ORIENTAREA BARCILOR: contractul brief §1.4 ------------------------------
#
# Exista separat fiindca `--front=-Z` a fost SCOS de pe jonca si sampan (vezi
# motivul la secttiunea "barci"). Contractul "prova pe -Z Godot" rtamane insa,
# iar pe Machu Picchu orientarea greita a unui tren a costat o runda intreaga.
# Masurat pe geometrie, nu pe arie: lungimea pe Z, prova ascutita la capatul
# -Z, si cotele din tabel (12 / 7 / 2 m).
echo
echo "== orientarea si cotele barcilor (brief §1.4) =="
if [ -f "$ROOT/vehicles/fishing_junk.glb" ]; then
  python tools/blender/verify_halong_boats.py || fail=1
  if python tools/blender/verify_halong_boats.py --sabotaj > /dev/null 2>&1; then
    echo "  [OK] sabotajul (X<->Z) pica, cum trebuie"
  else
    echo "  !! SABOTAJUL N-A PRINS: garda de orientare nu masoara nimic"
    fail=1
  fi
else
  echo "  (nicio barca exportata inca)"
fi

# Garda de siluetă se ARMEAZA la fiecare rulare: daca sabotajul (un con in
# locul turnului) n-ar mai pica, garda ar trece peste orice forma si verdictul
# de mai sus n-ar insemna nimic (memoria `garda-fara-linie-de-baza-iese-zero`).
echo
echo "== armarea garzii de silueta =="
if python tools/blender/verify_karst_profile.py --sabotaj > /dev/null 2>&1; then
  echo "  [OK] sabotajul pica, cum trebuie: garda masoara forma"
else
  echo "  !! SABOTAJUL N-A PRINS: garda de silueta nu mai masoara nimic"
  fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "VERDICT KIT: OK"
else
  echo "VERDICT KIT: PICAT"
fi
exit "$fail"
