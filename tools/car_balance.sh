#!/usr/bin/env bash
# Matricea de echilibru a garajului — pasul 0 din docs/cariera/mod_cariera.md.
#
# Pune toate cele 6 masini din garaj pe aceeasi grila (jucatorul = Muscle,
# adversarii = restul, prin `ProbeRace --ai-cars=`), acelasi AIController la
# volanul tuturor, viteza egala (`--equal-speed`: fara zarul 0.88..0.97 al
# adversarilor), si masoara pe fiecare pista cel mai bun tur al fiecarei
# masini, plus blocajele si repunerile ei. Matricea raspunde la o singura
# intrebare: e garajul un set de stiluri (fiecare masina cea mai rapida
# undeva, ecart mic pe orice pista) sau o scara de putere (aceeasi ordine
# peste tot, ecart mare)?
#
# De ce bash, nu o sonda GDScript: fiecare pista e o cursa intreaga (240 s
# simulate, ~75 s reale, headless), iar matricea pe 12 piste x 2 seed-uri
# dureaza ~30 de minute — prea mult pentru verify_local.sh (STEP_TIMEOUT 900 s
# pe pas). Deci e unealta la cerere, "inainte / dupa" la orice retuning de
# CarData, nu pas de verificare. ProbeRace e nedeterminista (memoria
# `proberace-nedeterminism`), de aceea implicitul e 2 seed-uri si se tine
# MINIMUL pe seed — potentialul masinii, nu media zgomotului.
#
# Rulare din radacina proiectului (unde e project.godot):
#   bash tools/car_balance.sh                          # 12 piste din cariera, seed 1 si 2
#   bash tools/car_balance.sh --tracks="11 12" --seeds="1"   # rapid, 2 piste
#   bash tools/car_balance.sh --out=docs/cariera/echilibru_garaj_2026-10-17.md
#   bash tools/car_balance.sh --no-equal-speed         # cum vede jocul grila (zarul AI)
#   bash tools/car_balance.sh --reparse                # doar raportul, din log-urile din $BALANCE_LOGS
#
# Pistele se dau ca POZITIE in GameState.TRACK_SCENES (ca la snapshot /
# probe_race), nu ca numar de scena; numele pistei se citeste din log
# ("probe_race: pista Kyoto (Track18)"), deci un swap de index nu strica
# raportul. Implicitul = cele 12 piste din cariera (brief §3), in ordinea
# lumilor: 1: Monument Valley, Kyoto, Cappadocia, Serengeti; 2:
# Transfagarasan, Chongqing, Machu Picchu, Okinawa; 3: Baikal, Stromboli,
# Jodhpur, Fiordland. Ha Long (14) nu e in cariera; se adauga cu --tracks.
#
# Verdict (pragurile din brief §11 pasul 0):
#   VETO    ecartul (cea mai lenta - cea mai rapida) / cea mai rapida > VETO_PCT
#           pe orice pista (8%, provizoriu pana dupa prima runda de retuning);
#   VETO    o masina FARA niciun tur complet pe o pista (se intepeneste pe un
#           gimmick si nu mai iese);
#   RAPORT  blocajele si repunerile per masina si pista ("!" de la 3 blocaje).
#           NU sunt veto: si cea mai rapida masina se blocheaza uneori (Politia
#           are 4 pe Kyoto din linia AI, nu din masina), deci un prag absolut
#           ar fi mereu rosu sau mereu orb — veto-ul pe blocaje se armeaza
#           abia cu linie de baza per pista (memoria `garda-fara-linie-de-baza`);
#   RAPORT  cate piste are fiecare masina pe locul 1 — tinta de design
#           ("fiecare masina prima undeva"), fara veto (lectia plafonului de
#           triunghiuri din CLAUDE.md: un prag atins mereu cere ceremonie).
# Iese cu 0 daca nu e niciun veto; scrie "VERDICT: OK" / "VERDICT: PROBLEMA".

set -uo pipefail

GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
LOGS="${BALANCE_LOGS:-${TMPDIR:-/tmp}/car_balance}"
STEP_TIMEOUT="${STEP_TIMEOUT:-600}"
TRACKS="12 11 6 7 2 5 8 13 3 4 10 9"
SEEDS="1 2"
SECONDS_SIM=240
VETO_PCT=8
EQUAL="--equal-speed"
OUT=""
PLAYER_CAR=0            # Muscle; adversarii = restul garajului, in ordinea CAR_DATA
AI_CARS="1,2,3,4,5"     # Politia, Taxi, Autobuzul, Pompierii, Buggy
REPARSE=0               # --reparse: doar raportul, din log-urile deja existente in $LOGS

for a in "$@"; do
	case "$a" in
		--tracks=*) TRACKS="${a#--tracks=}" ;;
		--seeds=*) SEEDS="${a#--seeds=}" ;;
		--seconds=*) SECONDS_SIM="${a#--seconds=}" ;;
		--veto=*) VETO_PCT="${a#--veto=}" ;;
		--out=*) OUT="${a#--out=}" ;;
		--no-equal-speed) EQUAL="" ;;
		--reparse) REPARSE=1 ;;
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
if [ $REPARSE -eq 1 ]; then
	rm -f "$LOGS"/rows.tsv
else
	rm -f "$LOGS"/t*_s*.log "$LOGS"/rows.tsv
fi

# ---------------------------------------------------------------- rulari
# Un rand TSV per (pista, seed, masina): index, nume pista, seed, masina,
# cel mai bun tur (s, 0 = niciun tur complet), ture complete, blocaje, repuneri.
echo "Matricea de echilibru: piste [$TRACKS], seed-uri [$SEEDS], ${SECONDS_SIM}s/cursa, ${EQUAL:-zarul AI 0.88..0.97}"
for t in $TRACKS; do
	for s in $SEEDS; do
		log="$LOGS/t${t}_s${s}.log"
		printf '  pista %-3s seed %-2s ' "$t" "$s"
		t0=$SECONDS
		if [ $REPARSE -eq 1 ]; then
			status=0
			if [ ! -f "$log" ]; then
				echo "fara log in $LOGS (ruleaza fara --reparse)"
				continue
			fi
		else
			timeout "$STEP_TIMEOUT" "$GODOT" --headless --fixed-fps 60 --path . \
				res://tools/ProbeRace.tscn -- --mode=race --track="$t" \
				--seconds="$SECONDS_SIM" --seed="$s" --car="$PLAYER_CAR" \
				--ai-cars="$AI_CARS" $EQUAL > "$log" 2>&1
			status=$?
		fi
		dt=$((SECONDS - t0))
		if [ $status -eq 124 ]; then
			echo "AGATAT (peste ${STEP_TIMEOUT}s) — vezi $log"
			continue
		fi
		if ! grep -q -- '--- ture (s)' "$log"; then
			echo "fara raport de ture (cod $status) — vezi $log"
			continue
		fi
		name=$(sed -n 's/^probe_race: pista \(.*\) (Track[0-9]*)$/\1/p' "$log" | head -1)
		[ -z "$name" ] && name="pista $t"
		# Blocul "--- ture (s)" are o linie per masina: "    Tu (Muscle)  3  min 65.52  med 68.27".
		awk -v t="$t" -v name="$name" -v s="$s" '
			/^--- ture \(s\)/ { inblock = 1; next }
			/^--- / { inblock = 0 }
			inblock && match($0, /\(([^)]*)\)[ \t]+([0-9]+)[ \t]+min[ \t]+([0-9.]+)/, m) {
				car = m[1]; laps = m[2]; best = (laps > 0) ? m[3] : 0
				printf "%s\t%s\t%s\t%s\t%s\t%s\n", t, name, s, car, best, laps
			}
		' "$log" | while IFS=$'\t' read -r ti tn si car best laps; do
			bl=$(grep -c "^\[blocaj\].*($car)" "$log")
			rp=$(grep -c "^\[repunere\].*($car)" "$log")
			printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$ti" "$tn" "$si" "$car" "$best" "$laps" "$bl" "$rp" >> "$LOGS/rows.tsv"
		done
		echo "ok (${dt}s) — $name"
	done
done

if [ ! -s "$LOGS/rows.tsv" ]; then
	echo "Nicio cursa cu raport de ture. VERDICT: PROBLEMA"
	exit 1
fi

# ---------------------------------------------------------------- raport
# Agregare: per (masina, pista) MINIMUL turului pe seed-uri, SUMA blocajelor si
# repunerilor. Ecartul pe pista = (cea mai lenta - cea mai rapida) / cea mai
# rapida, doar intre masinile cu cel putin un tur complet; o masina fara tur
# complet pe 240 s e tratata ca blocata (veto), nu ignorata.
REPORT=$(awk -F'\t' -v veto="$VETO_PCT" -v order="$TRACKS" -v equal="${EQUAL:-zarul AI}" '
	{
		t = $1; name[t] = $2; car = $4; best = $5 + 0; laps = $6 + 0; bl = $7 + 0; rp = $8 + 0
		key = car SUBSEP t
		if (!(car in cars)) { cars[car] = ++ncars; carlist[ncars] = car }
		if (!(t in seen)) { seen[t] = 1 }
		if (laps > 0 && (!(key in bestlap) || best < bestlap[key])) bestlap[key] = best
		lapsum[key] += laps; blocks[key] += bl; resp[key] += rp
	}
	END {
		n = split(order, ord, " ")
		# Ordinea masinilor ca in garaj (CAR_DATA): Muscle, Politia, Taxi, Autobuzul, Pompierii, Buggy.
		split("Muscle Politia Taxi Autobuzul Pompierii Buggy", garage, " ")
		m = 0
		for (i = 1; i <= 6; i++) if (garage[i] in cars) rows[++m] = garage[i]
		for (c = 1; c <= ncars; c++) { found = 0; for (i = 1; i <= m; i++) if (rows[i] == carlist[c]) found = 1; if (!found) rows[++m] = carlist[c] }

		printf "## Cel mai bun tur (s), minimul pe seed-uri — %s\n\n", equal
		printf "| Masina |"; for (i = 1; i <= n; i++) if (ord[i] in seen) printf " %s |", name[ord[i]]; printf " locul 1 |\n"
		printf "|---|"; for (i = 1; i <= n; i++) if (ord[i] in seen) printf "---|"; printf "---|\n"
		problems = 0
		for (i = 1; i <= n; i++) {
			t = ord[i]; if (!(t in seen)) continue
			fast[t] = 0; slow[t] = 0; who[t] = ""
			for (r = 1; r <= m; r++) {
				car = rows[r]; key = car SUBSEP t
				if (!(key in bestlap)) continue
				b = bestlap[key]
				if (fast[t] == 0 || b < fast[t]) { fast[t] = b; who[t] = car }
				if (b > slow[t]) slow[t] = b
			}
		}
		for (r = 1; r <= m; r++) {
			car = rows[r]; wins = 0
			printf "| %s |", car
			for (i = 1; i <= n; i++) {
				t = ord[i]; if (!(t in seen)) continue
				key = car SUBSEP t
				if (key in bestlap) {
					b = bestlap[key]
					if (car == who[t]) { printf " **%.1f** |", b; wins++ }
					else printf " %.1f (+%.0f%%) |", b, (b - fast[t]) / fast[t] * 100
				} else printf " — |"
			}
			printf " %d |\n", wins
		}
		printf "| *ecart* |"
		for (i = 1; i <= n; i++) {
			t = ord[i]; if (!(t in seen)) continue
			if (fast[t] > 0) {
				e = (slow[t] - fast[t]) / fast[t] * 100
				flag = (e > veto) ? " VETO" : ""
				if (e > veto) problems++
				printf " %.0f%%%s |", e, flag
			} else printf " — |"
		}
		printf " |\n\n"

		printf "## Blocaje / repuneri (suma pe seed-uri; raportate, nu veto — \"!\" de la 3 blocaje); fara tur complet = VETO\n\n"
		printf "| Masina |"; for (i = 1; i <= n; i++) if (ord[i] in seen) printf " %s |", name[ord[i]]; printf "\n"
		printf "|---|"; for (i = 1; i <= n; i++) if (ord[i] in seen) printf "---|"; printf "\n"
		for (r = 1; r <= m; r++) {
			car = rows[r]
			printf "| %s |", car
			for (i = 1; i <= n; i++) {
				t = ord[i]; if (!(t in seen)) continue
				key = car SUBSEP t
				bl = blocks[key] + 0; rp = resp[key] + 0
				cell = sprintf("%d / %d", bl, rp)
				if (!(key in bestlap)) { cell = cell " FARA TUR"; problems++ }
				else if (bl >= 3) cell = cell " !"
				printf " %s |", cell
			}
			printf "\n"
		}
		printf "\n"
		if (problems > 0) printf "VERDICT: PROBLEMA (%d veto-uri: ecart peste %s%% sau masina fara tur complet)\n", problems, veto
		else printf "VERDICT: OK (ecart <= %s%% pe toate pistele, toate masinile cu tur complet)\n", veto
	}
' "$LOGS/rows.tsv")

echo
echo "$REPORT"
if [ -n "$OUT" ]; then
	{
		echo "# Echilibrul garajului — $(date +%Y-%m-%d)"
		echo
		echo "\`tools/car_balance.sh\` pe $(git rev-parse --short HEAD 2>/dev/null || echo '?'): piste [$TRACKS], seed-uri [$SEEDS], ${SECONDS_SIM}s/cursa, jucator = CAR_DATA[$PLAYER_CAR], adversari = [$AI_CARS], ${EQUAL:-zarul AI 0.88..0.97}. Minimul pe seed-uri = potentialul masinii, nu media zgomotului."
		echo
		echo "$REPORT"
	} > "$OUT"
	echo "Raport scris in $OUT (log-uri in $LOGS)"
fi
echo "$REPORT" | grep -q 'VERDICT: OK'
