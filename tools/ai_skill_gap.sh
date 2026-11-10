#!/usr/bin/env bash
# Ecartul pe tur dintre nivelurile AI (issue #682): ruleaza ProbeAiSkill pe
# piste x seed-uri x niveluri, in paralel, apoi raportul cu verdictul.
#
# O rulare e o cursa reala de 3 tururi cu 6 masini (~75 s de ceas, headless).
# Matricea completa a issue-ului (3 piste x 16 seed-uri x 5 profiluri = 240 de
# curse) dureaza ~1,5 h pe 4 joburi — de aceea e UNEALTA la cerere, inainte /
# dupa orice retunare a nivelurilor, nu pas din verify_local.sh. Varianta scurta
# din verify (`--short`) masoara o singura pista pe 3 seed-uri.
#
# Rulare din radacina proiectului:
#   bash tools/ai_skill_gap.sh                                   # matricea completa
#   bash tools/ai_skill_gap.sh --tracks="12" --seeds="1 2 3" --jobs=3
#   bash tools/ai_skill_gap.sh --short                            # varianta din verify
#   bash tools/ai_skill_gap.sh --sabotaj=ordine --skills="referinta bronz argint aur"
#   bash tools/ai_skill_gap.sh --report-only                      # doar raportul
#
# Pistele se dau ca POZITIE in GameState.TRACK_SCENES (ca la probe_race);
# eticheta tiparita de sonda spune ce pista a fost de fapt. Implicitul = cele
# trei piste de stil diferit: 12 Monument Valley (drepte lungi), 11 Kyoto
# (serpentine, hazarde), 3 Baikal (sarituri si gheata). Restul pistelor de
# lansare (cariera): 6 7 2 5 8 13 4 10 9.
#
# Rezultatele se ADAUGA in $AISKILL_OUT (implicit $TMPDIR/ai_skill_gap/rezultate.txt):
# rulari succesive pe piste diferite intra in acelasi raport. `--fresh` il goleste.
# Iese cu 0 doar daca raportul da VERDICT: OK.

set -uo pipefail

GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
DIR="${AISKILL_DIR:-${TMPDIR:-/tmp}/ai_skill_gap}"
OUT="${AISKILL_OUT:-$DIR/rezultate.txt}"
RUN_TIMEOUT="${RUN_TIMEOUT:-900}"
TRACKS="12 11 3"
SEEDS="$(seq 1 16 | tr '\n' ' ')"
SKILLS="referinta implicit bronz argint aur"
JOBS=4
LAPS=2
SABOTAJ=""
REPORT_ONLY=0
FRESH=0
for a in "$@"; do
	case "$a" in
		--tracks=*) TRACKS="${a#--tracks=}" ;;
		--seeds=*) SEEDS="${a#--seeds=}" ;;
		--skills=*) SKILLS="${a#--skills=}" ;;
		--jobs=*) JOBS="${a#--jobs=}" ;;
		--laps=*) LAPS="${a#--laps=}" ;;
		--sabotaj=*) SABOTAJ="${a#--sabotaj=}" ;;
		--out=*) OUT="${a#--out=}" ;;
		--report-only) REPORT_ONLY=1 ;;
		--fresh) FRESH=1 ;;
		--short)
			TRACKS="12"; SEEDS="1 2 3"; SKILLS="referinta implicit bronz argint aur"
			FRESH=1 ;;
		*) echo "argument necunoscut: $a"; exit 2 ;;
	esac
done

if [ ! -f project.godot ]; then
	echo "Ruleaza din radacina proiectului (unde e project.godot)."
	exit 2
fi
mkdir -p "$DIR" "$(dirname "$OUT")"
[ $FRESH -eq 1 ] && rm -f "$OUT"

if [ $REPORT_ONLY -eq 0 ]; then
	jobs_file="$DIR/joburi.txt"
	: > "$jobs_file"
	for t in $TRACKS; do
		for s in $SEEDS; do
			for k in $SKILLS; do
				echo "$t $s $k" >> "$jobs_file"
			done
		done
	done
	n=$(wc -l < "$jobs_file")
	echo "ai_skill_gap: $n curse ($JOBS in paralel), rezultate in $OUT"
	t0=$SECONDS
	export GODOT DIR OUT RUN_TIMEOUT LAPS SABOTAJ
	# Un proces Godot per cursa, cu timeout propriu: o cursa agatata pica
	# singura, nu blocheaza matricea. NICIODATA taskkill /IM pe Godot.
	xargs -P "$JOBS" -L 1 bash -c '
		t=$0; s=$1; k=$2
		log="$DIR/t${t}_s${s}_${k}${SABOTAJ:+_$SABOTAJ}.log"
		sab=""; [ -n "$SABOTAJ" ] && sab="--sabotaj=$SABOTAJ"
		timeout "$RUN_TIMEOUT" "$GODOT" --headless --fixed-fps 60 --path . \
			res://tools/ProbeAiSkill.tscn -- --track=$t --seed=$s --skill=$k \
			--laps=$LAPS --out="$OUT" $sab > "$log" 2>&1
		st=$?
		if ! grep -q AISKILL_RESULT "$log"; then
			echo "  pista $t seed $s $k: FARA REZULTAT (cod $st) — $log"
		fi
	' < "$jobs_file"
	echo "ai_skill_gap: gata in $((SECONDS - t0)) s"
fi

timeout 300 "$GODOT" --headless --path . res://tools/ProbeAiSkill.tscn -- \
	--report="$OUT" 2>&1 | grep -vE '^(Godot Engine|WARNING|   at:|$)' | tee "$DIR/raport.txt"
grep -q "VERDICT: OK" "$DIR/raport.txt"
