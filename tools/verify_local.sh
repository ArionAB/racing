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

echo
if [ ${#FAILED[@]} -eq 0 ]; then
	echo "VERIFICARE LOCALA: OK (${#PASSED[@]} pasi). Log-uri in $LOGS"
	exit 0
fi
echo "VERIFICARE LOCALA: ${#FAILED[@]} PASI PICA:"
for f in "${FAILED[@]}"; do echo "  - $f"; done
exit 1
