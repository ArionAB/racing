#!/usr/bin/env bash
# Verificarea de dinainte de merge, LOCAL — inlocuieste CI-ul de pe GitHub.
#
# De ce local (oct 2026): CI-ul pe Linux rula la fiecare push, pe orice ramura,
# plus inca o data pe fiecare PR, fara limita de timp. In septembrie a ars
# ~36.800 de minute — 90 de joburi au stat cate 6 ore agatate intr-o sonda — si
# a epuizat bugetul comun cu build-ul de iOS. Aceleasi verificari ruleaza aici
# pe Godot-ul de Windows, gratis, cu limita de timp pe fiecare pas.
#
# Se ruleaza din radacina worktree-ului care urmeaza sa intre in main (dupa ce
# ai adus main-ul in ramura), INAINTE de merge-ul PR-ului:
#
#   bash tools/verify_local.sh             # import + toate verificarile
#   bash tools/verify_local.sh --no-import # sare peste import (cache proaspat)
#
# Iese cu 0 doar daca toate verificarile trec. Log-urile raman in
# $VERIFY_LOGS (implicit un folder temporar), numite dupa pas.
#
# Godot: variabila GODOT, altfel calea standard de pe masina de dezvoltare.

set -uo pipefail

GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
LOGS="${VERIFY_LOGS:-${TMPDIR:-/tmp}/verify_local}"
STEP_TIMEOUT="${STEP_TIMEOUT:-900}"   # secunde pe pas; un pas agatat pica, nu blocheaza
DO_IMPORT=1
for a in "$@"; do
	case "$a" in
		--no-import) DO_IMPORT=0 ;;
		*) echo "argument necunoscut: $a"; exit 2 ;;
	esac
done

if [ ! -f project.godot ]; then
	echo "Ruleaza din radacina proiectului (unde e project.godot)."
	exit 2
fi
if [ ! -x "$GODOT" ] && [ ! -f "$GODOT" ]; then
	echo "Nu gasesc Godot la $GODOT — seteaza GODOT=..."
	exit 2
fi
mkdir -p "$LOGS"
rm -f "$LOGS"/*.log

FAILED=()
PASSED=()
ERR_PATTERN='SCRIPT ERROR|Parse Error|Failed to load|Failed to instantiate|Cannot open file'

# run_step <nume> <log> <regex de terminare> -- <argumente godot...>
# Pica daca pasul depaseste STEP_TIMEOUT, daca lipseste linia de terminare
# (sonda a murit inainte de verdict), daca iese cu cod != 0 sau daca scrie
# "VERDICT: PROBLEMA".
run_step() {
	local name="$1" log="$2" done_re="$3"
	shift 4
	local t0=$SECONDS
	printf '%-58s ' "$name"
	timeout "$STEP_TIMEOUT" "$GODOT" "$@" > "$LOGS/$log" 2>&1
	local status=$?
	local dt=$((SECONDS - t0))
	local why=""
	if [ $status -eq 124 ]; then
		why="AGATAT (peste ${STEP_TIMEOUT}s)"
	elif ! grep -qE "$done_re" "$LOGS/$log"; then
		why="n-a ajuns la verdict"
	elif [ $status -ne 0 ]; then
		why="cod de iesire $status"
	elif grep -q 'VERDICT: PROBLEMA' "$LOGS/$log"; then
		why="VERDICT: PROBLEMA"
	fi
	if [ -z "$why" ]; then
		echo "OK   (${dt}s)"
		PASSED+=("$name")
	else
		echo "PICA (${dt}s) — $why — vezi $LOGS/$log"
		FAILED+=("$name")
	fi
}

if [ $DO_IMPORT -eq 1 ]; then
	# Dupa un merge, scenele pot cere resurse inca neimportate (memoria
	# `merge-curat-scena-stricata`). Doua treceri, ca in CI: unele resurse
	# depind de altele.
	printf '%-58s ' "Import resurse"
	timeout "$STEP_TIMEOUT" "$GODOT" --headless --path . --import > "$LOGS/import.log" 2>&1
	timeout "$STEP_TIMEOUT" "$GODOT" --headless --path . --import >> "$LOGS/import.log" 2>&1
	echo "gata"
fi

# Testul de fum: scena principala porneste fara erori de script/parse/load.
printf '%-58s ' "Pornirea jocului (scena principala, 180 de cadre)"
timeout "$STEP_TIMEOUT" "$GODOT" --headless --path . --quit-after 180 > "$LOGS/run.log" 2>&1
smoke_status=$?
if [ $smoke_status -eq 124 ]; then
	echo "PICA — AGATAT"
	FAILED+=("Pornirea jocului")
elif grep -nEi "$ERR_PATTERN" "$LOGS/run.log" ${DO_IMPORT:+"$LOGS/import.log"} 2>/dev/null | head -20 > "$LOGS/erori.txt" && [ -s "$LOGS/erori.txt" ]; then
	echo "PICA — erori de script/parse/load:"
	sed 's/^/    /' "$LOGS/erori.txt"
	FAILED+=("Pornirea jocului")
else
	echo "OK"
	PASSED+=("Pornirea jocului")
fi

# Restul pasilor sunt aceiasi ca in vechiul ci.yml; motivarea fiecaruia e in
# sonda respectiva.
run_step "Garda de draw call-uri (materiale per pista)" probe_decor.log 'VERDICT:' -- \
	--headless --path . --script res://tools/probe_decor.gd
run_step "Anti-blocaj in peretii de canion" cliff.log 'VERDICT:' -- \
	--headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- --mode=cliff --track=0
run_step "Coliziunea stancilor urmareste silueta" rockfit.log 'VERDICT:' -- \
	--headless --fixed-fps 60 --path . --script res://tools/probe_rock_fit.gd -- --no-batch
run_step "Decorul nu intra peste asfalt" overlap.log 'VERDICT:' -- \
	--headless --fixed-fps 60 --path . --script res://tools/probe_decor_overlap.gd -- --no-batch
run_step "Reintrarea pe sosea dupa iesirea pe nisip" reentry.log 'VERDICT:' -- \
	--headless --fixed-fps 60 --path . res://tools/ProbeReentry.tscn -- --mode=drive --track=0
run_step "Camera in caverna (tot intervalul de slidere)" cavecam.log 'TOATE OK|PICAT:' -- \
	--headless --fixed-fps 60 --path . res://tools/ProbeCavecam.tscn
run_step "Strivit: turbo-ul nu scoate masina din strivire" crush_turbo.log 'VERDICT:' -- 	--headless --fixed-fps 60 --path . res://tools/ProbeCrushTurbo.tscn
run_step "Feed-ul de contact: perete, razuire, masina" contact_feed.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeContactFeed.tscn
run_step "Motor cu trepte si sarcina (sunet): caderi la schimbare, zumzet sub gaz" engine_voice.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeEngineVoice.tscn
run_step "Rateuri la ridicarea gazului (sunet): sansa, cooldown, doar turatie mare" lift_pops.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeLiftPops.tscn
run_step "Scrasnet dupa alunecare (sunet): volum/pitch cu unghiul, sisait pe pietris" slip_squeal.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeSlipSqueal.tscn
run_step "Vocile suprafetelor (sunet): iarba/pietris/apa, cross-fade, bordura, pista reala" surface_voice.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeSurfaceVoice.tscn
run_step "Turbo (sunet): click, suvoi cat arde, sisait la capat" turbo_sound.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeTurboSound.tscn
run_step "Vant (sunet): mut sub jumatate din viteza, urca spre plafon" wind.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeWind.tscn
run_step "Sunet de impact: straturi dupa putere, variante, conducta" impact_sound.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeImpactSound.tscn
run_step "Rocket start (sunet): clichet cat tii TURBO, arc la GO doar pe rocket" rocket_start.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeRocketStart.tscn
run_step "Bucle de contact: razuire, frecare, fara hartuiala la palpaire" scrape_loop.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeScrapeLoop.tscn
run_step "Aterizare: bufnitura dupa viteza de cadere, strat greu" land_thud.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeLandThud.tscn
run_step "Impacturi pozitionale: cine m-a lovit, AI-AI, pool de 4" positional_hits.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbePositionalHits.tscn
run_step "Claxon de jucarie: ranchiuna, frecare, pauze, raza" horn.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeHorn.tscn
run_step "Stinger de pozitie: urcare, coborare, coalescare, cablaj" stinger.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeStinger.tscn
run_step "Hazarde mobile: sunet de contact (bariera, autobuz)" hazard_sound.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeHazardSound.tscn
run_step "Decor lovit: sunet de tac, pauza, prioritate" prop_knock.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbePropKnock.tscn
run_step "Volan: se strange cu viteza, drift scutit, netezire" steer_speed.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeSteerSpeed.tscn
run_step "Perete: razuire pastreaza viteza, frontal opreste, anti-lipire" wall_glance.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeWallGlance.tscn
run_step "Rasturnat: se intoarce pe roti pe loc, plasa pentru loc invalid" upright.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeUpright.tscn
run_step "Body jolt: caroseria vizuala la impact, revenire, compunere" body_jolt.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeBodyJolt.tscn
run_step "Scantei de contact: razuire, rafala, frecare intre masini" contact_sparks.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeContactSparks.tscn
run_step "Fum si urme de drift dupa unghiul de alunecare" drift_smoke.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeDriftSmoke.tscn
run_step "Praful de aterizare, colorat dupa suprafata" landing_dust.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeLandingDust.tscn
run_step "Soferul: tresarire, tremur, privire, pumn" driver_react.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeDriverReact.tscn
run_step "Decor lovit: aschii, butoi knockable, plafon" prop_debris.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbePropDebris.tscn
run_step "Tufe: frunze si franare usoara" soft_veg.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeSoftVeg.tscn
run_step "Jucaria: antena cu arc, cheia de intors si zdranganeala pe teren aspru, fara intrari in caroserie" toy_animation.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeToyAnimation.tscn
run_step "Camera la izbituri: kick, hit-stop, atacator" impact_camera.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeImpactCamera.tscn
run_step "Race: ImpactFeel cablat (kick, hit-stop, final)" impact_wiring.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeImpactWiring.tscn
run_step "Tururi si ordine de sosire: repunere langa linie, locul final real" finish_order.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeFinishOrder.tscn
run_step "Popup de pozitie: debounce, numaratoare, final" position_popup.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbePositionPopup.tscn
run_step "AI care reactioneaza: clatinare, ranchiuna, cinstit" ai_react.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeAiReact.tscn
run_step "Vibratie: marime, ritm, setare, cablaj" haptics.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeHaptics.tscn
run_step "Linii de viteza: prag, monotonie, turbo" speed_lines.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeSpeedLines.tscn
run_step "Hazarde mobile: kick de camera, fara hit-stop" hazard_kick.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeHazardKick.tscn
run_step "Spin-out: asistenta intoarce masina, nu strica driftul" spinout.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeSpinout.tscn
run_step "Aer: gazul apleaca botul, frana il ridica, AI neutru" air_control.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeAirControl.tscn
run_step "Slipstream: aspiratie doar in con, fara lipire" slipstream.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeSlipstream.tscn
run_step "Bordura: scutura suspensia doar in viteza" kerb.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeKerb.tscn
run_step "Rezervor sigilat: bara nu se incarca, arderea merge" sealed_turbo.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeSealedTurbo.tscn
run_step "Fantoma: inregistrare, fisier, redare" ghost.log 'VERDICT:' -- --headless --fixed-fps 60 --path . res://tools/ProbeGhost.tscn
run_step "Bolovanul de pe buza + directie inversata" rim_boulder.log 'VERDICT:' -- 	--headless --fixed-fps 60 --path . res://tools/ProbeRimBoulder.tscn
run_step "Registrul MeshCpu (citiri GPU refolosite)" meshcpu.log 'MeshCpu:' -- \
	--headless --path . res://tools/ProbeMeshCpu.tscn
# Maparea atingere -> comanda. Pe iPhone, sageata DREAPTA vira la STANGA:
# butoanele erau desenate amandoua in stanga ecranului, iar directia se decidea
# din `pos.x < size.x/2`. Nicio captura nu putea prinde asta — o captura arata
# unde e desenat butonul, nu ce face. Verifica si ca discurile apasate
# simultan (gaz+drift, gaz+turbo) nu se ating.
run_step "Controale touch: maparea si distantele" touch_zones.log 'VERDICT:' -- \
	--headless --path . res://tools/ProbeTouchZones.tscn

# Garajul: normalizarea barelor pe intervalul REAL al masinilor, masa ca axa
# cu semn (nu bara care se umple), conturul-fantoma bidirectional si
# incadrarea vitrinei 3D. Cifrele brute din vechiul garaj nu spuneau nimic,
# iar o incadrare pe factor fix taia masina de indata ce panoul ii musca
# din latime (prima captura).
run_step "Garajul: bare, masa si incadrarea vitrinei" garage.log 'probe_garage:' -- \
	--headless --path . res://tools/ProbeGarage.tscn -- --check

# Serengeti (#501-#503). Animalele care traverseaza calca pe sol pe toata
# cursa (vacile de pe coama parcau la 5-21 m peste versant) si merg cu fata
# inainte (elefantul avea trompa pe +Z); figurantii si turma de fundal nu stau
# in copaci sau stanci, nici cocotati pe ele (157 din 856 de gnu stateau asa).
run_step "Serengeti: traversarile calca pe sol, cu fata inainte" hazard_ground.log 'VERDICT:' -- \
	--headless --fixed-fps 60 --path . res://tools/ProbeHazardGround.tscn -- --track=7
run_step "Serengeti: animalele nu stau in copaci si stanci" animal_overlap.log 'VERDICT:|PICAT:' -- \
	--headless --fixed-fps 60 --path . res://tools/ProbeAnimalOverlap.tscn -- --track=7 --no-batch
# Cariera pasul 1: config validat (cu sabotaj), persistenta pe pista, stampile
# calculate si gating-ul lumilor, versiune necunoscuta lasata neatinsa,
# regruparea fara pierderi, raftul numarat in scena si lacatul cursei.
run_step "Cariera: config, persistenta, gating, raft" career.log 'VERDICT:' -- \
	--headless --path . res://tools/ProbeCareer.tscn -- --check
# WORLD CUP: cupele (piste valide, fara dubluri, fara cele excluse), adversarii
# trasi fara repetare (garda armata pe lineup-ul vechi cu doua autobuze),
# baremul 6-5-4-3-2-1 si o cursa reala in cupa (grila, titlu, departajare).
run_step "World Cup: cupe, adversari unici, puncte, cursa" world_cup.log 'VERDICT:' -- \
	--headless --fixed-fps 60 --path . res://tools/ProbeWorldCup.tscn

# Decorul asezat pe solul de la generare ramane sub teren cand terenul creste
# dupa aceea: padurea Lerai ajunsese la 20-30 m sub peretele craterului.
run_step "Serengeti: niciun decor ingropat sub teren" decor_buried.log 'VERDICT:|PICAT:' -- \
	--headless --fixed-fps 60 --path . res://tools/ProbeDecorBuried.tscn -- --track=7 --no-batch
# Cariera pasul 4a: provocarea gimmick-ului. Tracker-ul numara doar evenimentele
# jucatorului (cu contra-probe pe alte masini), datele sabotate dau cate o
# problema, foaia pistei se activeaza, pistele reale au sursa semnalului.
run_step "Provocari: tracker-ul numara doar ce trebuie" challenge.log 'VERDICT:' -- 	--headless --path . res://tools/ProbeChallenge.tscn
# Torentul Fiordland (#493): fizica doar in puls + efect mic in CALM (sabotaj: --calm-zero pica).
run_step "Torent Fiordland: CALM simtit, SURGE mai dur" torrent_b.log 'REZULTAT FINAL' -- --headless --fixed-fps 60 --path . res://tools/ProbeFiordTorent.tscn -- --only=b

# Transfagarasan: oile se simt (timp pierdut fata de control, semnal `impact`, nu zid)
# si exista un urs dupa saritura peste parau, care nu arunca masina in aer (#603/#604).
run_step "Transfagarasan: oi si urs (hazarde animale)" tf_hazards.log 'VERDICT:' -- 	--headless --fixed-fps 60 --path . res://tools/ProbeTfHazards.tscn
# Conurile din tunel (road_works) se imprastie, nu sunt zid (#602).
run_step "Transfagarasan: conurile din tunel se imprastie" tf_cones.log 'VERDICT:' -- 	--headless --fixed-fps 60 --path . res://tools/ProbeBumpProps.tscn -- --track=21

echo
if [ ${#FAILED[@]} -eq 0 ]; then
	echo "VERIFICARE LOCALA: OK (${#PASSED[@]} pasi). Log-uri in $LOGS"
	exit 0
fi
echo "VERIFICARE LOCALA: ${#FAILED[@]} PASI PICA:"
for f in "${FAILED[@]}"; do echo "  - $f"; done
exit 1
