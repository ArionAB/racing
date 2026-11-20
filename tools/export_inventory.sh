#!/usr/bin/env bash
# Inventarul exportului: ce intra in build-ul de magazin, si garda care pica
# daca intra un demo sau o imagine de referinta (#716).
#
# De ce: presetul de iOS exporta `all_resources`, adica TOT ce Godot
# recunoaste ca resursa, minus exclude_filter. Asa au ajuns in build
# road_demos/ (demo-ul addon-ului road-generator, 13 MB, cu propriul buton de
# quit), demo-urile proton_scatter, posterele de referinta de la Okinawa si
# referintele din radacina. Nimeni nu le-a pus acolo cu intentie — au intrat
# fiindca nimic nu se uita.
#
# Modelul (verificat o data cu `--export-pack "iOS"`, nov 2026: aceeasi lista
# de surse ca arhiva reala):
#   fisierele din git (index), minus cele de sub un folder cu .gdignore,
#   minus extensiile pe care Godot nu le exporta (NON_EXPORT de mai jos),
#   plus include_filter, minus exclude_filter — cu potrivirea lui Godot
#   (`*` trece si peste `/`, fara diferenta de majuscule, pe calea cu sau
#   fara res://).
#
# Pica la:
#   - o intrare de top care nu e pe lista ALLOW_TOP (un folder nou de top nu
#     poate intra in build fara sa-l vada cineva);
#   - o cale care arata a demo sau referinta (DENY).
# Tipareste marimea surselor care intra in export, pe folder de top. (In
# pachet merg versiunile importate — texturi comprimate, scene binare — deci
# cifra din .pck difera; aici se vede cine creste.)
#
#   bash tools/export_inventory.sh          # garda + marimi
#   bash tools/export_inventory.sh --list   # plus fisierele, cate unul: LIST<tab>cale
#
# Ultima linie e `VERDICT: OK` sau `VERDICT: PROBLEMA`; codul de iesire e 0
# doar la OK.

set -uo pipefail

LIST=0
for a in "$@"; do
	case "$a" in
		--list) LIST=1 ;;
		*) echo "argument necunoscut: $a"; exit 2 ;;
	esac
done

cd "$(dirname "$0")/.." || exit 2
if [ ! -f export_presets.cfg ]; then
	echo "Lipseste export_presets.cfg in $(pwd)."
	echo "VERDICT: PROBLEMA"
	exit 1
fi

# Ce are voie sa intre in export la nivelul de sus. Continut nou de joc sub
# unul din astea nu cere nimic; un folder NOU de top cere o decizie aici.
# `localization` (nov 2026): traducerile .po, citite din project.godot
# (internationalization/locale/translations) — fara ele jocul exportat ar
# ramane in engleza in orice limba. `toy_racer.pot` e numarat si el aici, desi
# Godot nu-l exporta (nu e resursa): garda greseste spre prudenta.
ALLOW_TOP="addons assets scenes scripts localization project.godot"

# Tipare de cale care nu au ce cauta in build (fara majuscule, glob ca la
# Godot). Imaginile de referinta stau intr-un folder cu .gdignore; demo-urile
# de addon se scot cu exclude_filter. "referinta" ca NUME de fisier e legitim
# (scenes/cars/ai_skill/referinta.tres e profilul AI de baza), de aceea
# referintele se prind doar ca FOLDER.
DENY="*demo* *inspiration* *_ref.* *_ref/* */ref/* */refs/* */reference/* */references/* */referinte/* *chatgpt* *whatsapp* */examples/* */samples/* */screenshots/*"

# Extensii pe care Godot nu le exporta cu all_resources: fisiere text
# (md/txt/cfg/yml), surse fara importer (gif, afdesign, hpp, cs, sh) si
# fisierele-satelit (.import/.uid, care merg remapate odata cu sursa).
# project.godot pleaca separat, ca project.binary. Orice extensie
# necunoscuta e numarata ca exportata: garda greseste spre prudenta.
NON_EXPORT="import uid md txt cfg ini log yml yaml toml sh py gif afdesign hpp cs png~ gitignore gitattributes godot"

git -c core.quotePath=false ls-files --format='%(objectsize)%x09%(path)' > /dev/null 2>&1 || {
	echo "git ls-files --format nu merge (git prea vechi? trebuie >= 2.38)."
	echo "VERDICT: PROBLEMA"
	exit 1
}

{
	# Prima sectiune: presetele, una pe linie.
	awk '
		/^\[preset\.[0-9]+\]/ { sec = 1; n++; next }
		/^\[/ { sec = 0; next }
		sec && match($0, /^(name|export_filter|include_filter|exclude_filter)="/) {
			k = substr($0, 1, index($0, "=") - 1)
			v = substr($0, index($0, "=") + 2); sub(/"[[:space:]]*\r?$/, "", v)
			p[n, k] = v
		}
		END {
			for (i = 1; i <= n; i++)
				printf "PRESET\t%s\t%s\t%s\t%s\n", p[i, "name"], p[i, "export_filter"], p[i, "include_filter"], p[i, "exclude_filter"]
		}
	' export_presets.cfg
	# A doua: fisierele din git, cu marime.
	git -c core.quotePath=false ls-files --format='%(objectsize)%x09%(path)' | sed 's/^/FILE\t/'
} | awk -F'\t' -v want_list="$LIST" -v allow="$ALLOW_TOP" -v deny="$DENY" -v nonexp="$NON_EXPORT" '
	function glob_re(g,   i, c, r) {
		r = "^"
		for (i = 1; i <= length(g); i++) {
			c = substr(g, i, 1)
			if (c == "*") r = r ".*"
			else if (c == "?") r = r "."
			else if (index("\\.^$+(){}[]|/", c)) r = r "\\" c
			else r = r c
		}
		return r "$"
	}
	# Potrivirea lui Godot (_edit_files_with_filter): pe "res://cale" sau pe "cale".
	function filt_match(path, list, cnt,   i, lp) {
		lp = tolower(path)
		for (i = 1; i <= cnt; i++)
			if (lp ~ list[i] || ("res://" lp) ~ list[i]) return 1
		return 0
	}
	function split_filter(s, list,   parts, n, i, t, k) {
		n = split(s, parts, ",")
		k = 0
		for (i = 1; i <= n; i++) {
			t = parts[i]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
			if (t != "") list[++k] = glob_re(tolower(t))
		}
		return k
	}
	# ".mcp.json" -> json, ".gitignore" -> gitignore, "LICENSE" -> ""
	function ext_of(path,   b, hidden) {
		b = path; sub(/.*\//, "", b)
		hidden = (b ~ /^\./); sub(/^\./, "", b)
		if (b ~ /\./) { sub(/.*\./, "", b); return tolower(b) }
		return hidden ? tolower(b) : ""
	}
	function under_gdignore(path,   d) {
		d = path
		while (sub(/\/[^\/]*$/, "", d)) if (d in gdig) return 1
		return 0
	}
	function human(b) { return sprintf("%.1f MB", b / 1048576) }
	BEGIN {
		na = split(allow, a, " "); for (i = 1; i <= na; i++) allowed[a[i]] = 1
		nd = split(deny, dd, " "); for (i = 1; i <= nd; i++) { deny_glob[i] = dd[i]; deny_re[i] = glob_re(dd[i]) }
		nn = split(nonexp, ne, " "); for (i = 1; i <= nn; i++) skip_ext[ne[i]] = 1
		skip_ext[""] = 1
	}
	$1 == "PRESET" { np++; pname[np] = $2; pmode[np] = $3; pinc[np] = $4; pexc[np] = $5; next }
	$1 == "FILE" {
		nf++; fsize[nf] = $2; fpath[nf] = $3
		if ($3 ~ /(^|\/)\.gdignore$/) { d = $3; sub(/\/?\.gdignore$/, "", d); gdig[d] = 1 }
		next
	}
	END {
		bad = 0
		if (np == 0) { print "PICA: niciun [preset.N] in export_presets.cfg"; bad = 1 }
		for (p = 1; p <= np; p++) {
			printf "Preset \"%s\": export_filter=%s\n", pname[p], pmode[p]
			printf "  include_filter=\"%s\"\n  exclude_filter=\"%s\"\n", pinc[p], pexc[p]
			if (pmode[p] != "all_resources") {
				printf "PICA: presetul \"%s\" are export_filter=%s; garda modeleaza doar all_resources — actualizeaz-o in tools/export_inventory.sh.\n", pname[p], pmode[p]
				bad = 1; continue
			}
			delete inc; delete exc
			ni = split_filter(pinc[p], inc); nx = split_filter(pexc[p], exc)
			delete top_n; delete top_b; delete top_ex; total_n = 0; total_b = 0; nbad_deny = 0
			for (i = 1; i <= nf; i++) {
				f = fpath[i]
				if (under_gdignore(f)) continue
				inres = !(ext_of(f) in skip_ext)
				if (!inres && !(ni && filt_match(f, inc, ni))) continue
				if (nx && filt_match(f, exc, nx)) continue
				if (want_list) printf "LIST\t%s\n", f
				t = f; sub(/\/.*/, "", t)
				top_n[t]++; top_b[t] += fsize[i]; total_n++; total_b += fsize[i]
				if (!(t in top_ex)) top_ex[t] = f
				for (k = 1; k <= nd; k++) {
					if (tolower(f) ~ deny_re[k]) {
						nbad_deny++
						if (nbad_deny <= 20)
							printf "PICA: %s intra in export si arata a demo/referinta (tiparul %s). Imagine de referinta -> mut-o intr-un folder cu .gdignore (vezi assets/dunele_inspiration/); demo de addon -> adauga folderul in exclude_filter din export_presets.cfg.\n", f, deny_glob[k]
						bad = 1
						break
					}
				}
			}
			if (nbad_deny > 20) printf "PICA: ... si inca %d cai de demo/referinta.\n", nbad_deny - 20
			for (t in top_n) {
				if (!(t in allowed)) {
					printf "PICA: intrarea de top \"%s\" intra in export (%d fisiere, %s; ex: %s). Daca e continut de joc, adaug-o in ALLOW_TOP din tools/export_inventory.sh; altfel pune-o in exclude_filter din export_presets.cfg sau pune un .gdignore in folder.\n", t, top_n[t], human(top_b[t]), top_ex[t]
					bad = 1
				}
			}
			printf "Marimea surselor care intra in export (\"%s\"), pe intrare de top:\n", pname[p]
			# sortare dupa marime, descrescator
			m = 0; for (t in top_n) order[++m] = t
			for (i = 1; i <= m; i++) for (j = i + 1; j <= m; j++)
				if (top_b[order[j]] > top_b[order[i]]) { tmp = order[i]; order[i] = order[j]; order[j] = tmp }
			for (i = 1; i <= m; i++)
				printf "export  %-16s %6d fisiere %10s\n", order[i], top_n[order[i]], human(top_b[order[i]])
			printf "export  %-16s %6d fisiere %10s\n", "TOTAL", total_n, human(total_b)
			delete order
		}
		print (bad ? "VERDICT: PROBLEMA" : "VERDICT: OK")
		exit bad
	}
'
