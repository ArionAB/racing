#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# gh_setup_board.sh — creeaza board-ul Kanban + Issues (Milestone A + B) pentru
# ArionAB/racing, le leaga de proiect, seteaza branch protection pe main.
#
# PREREQ (o singura data, in terminalul tau):
#   gh auth login                # login prin browser
#   gh auth refresh -s project   # adauga scope-ul "project" (necesar pt Projects v2)
#
# Ruleaza:  bash scripts/gh_setup_board.sh
# E idempotent: rulat de mai multe ori NU creeaza dubluri.
# ---------------------------------------------------------------------------
set -euo pipefail

# gh nu e mereu in PATH-ul bash pe Windows:
export PATH="$PATH:/c/Program Files/GitHub CLI"

OWNER="ArionAB"
REPO="racing"
REPO_FULL="$OWNER/$REPO"
PROJECT_TITLE="Toy Racer Roadmap"

# --- Assignees --------------------------------------------------------------
# Completeaza cu username-urile GitHub reale ale celor 3. Lasa gol => neasignat.
ASSIGN_P1=""   # layout + gimmick semnatura + fly-off/respawn
ASSIGN_P2=""   # Blender MCP + props
ASSIGN_P3=""   # branch protection + CI + bump-props + tunare AI/masa

APPLY_BRANCH_PROTECTION="true"   # pune "false" ca sa sari peste pasul de protection

# ---------------------------------------------------------------------------
say(){ printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

# --- verificari -------------------------------------------------------------
command -v gh >/dev/null || { echo "gh nu e instalat"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Nu esti logat. Ruleaza: gh auth login"; exit 1; }
if ! gh auth status 2>&1 | grep -qi "project"; then
  warn "Scope-ul 'project' pare sa lipseasca. Daca 'gh project' da 403, ruleaza: gh auth refresh -s project"
fi

# --- labels ----------------------------------------------------------------
ensure_label(){ # name color desc
  gh label create "$1" --color "$2" --description "$3" --repo "$REPO_FULL" 2>/dev/null \
    || gh label edit "$1" --color "$2" --description "$3" --repo "$REPO_FULL" >/dev/null 2>&1 || true
}
say "Creez labels…"
ensure_label "milestone-a"   "5319e7" "Proces: CI, branch protection"
ensure_label "milestone-b"   "0e8a16" "Dunele: layout, gimmick, props, tuning"
ensure_label "role:layout"   "1d76db" "Persoana 1"
ensure_label "role:props"    "fbca04" "Persoana 2"
ensure_label "role:process"  "d93f0b" "Persoana 3"

# --- project ---------------------------------------------------------------
say "Verific/creez proiectul \"$PROJECT_TITLE\"…"
PROJ_NUM="$(gh project list --owner "$OWNER" --format json \
  | python -c "import sys,json;print(next((str(p['number']) for p in json.load(sys.stdin)['projects'] if p['title']=='$PROJECT_TITLE'),''))" 2>/dev/null || true)"
if [ -z "${PROJ_NUM:-}" ]; then
  PROJ_NUM="$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json \
    | python -c "import sys,json;print(json.load(sys.stdin)['number'])")"
  say "Proiect creat: #$PROJ_NUM"
else
  say "Proiect existent: #$PROJ_NUM"
fi
# leaga proiectul de repo (pt ca Issues sa apara in contextul repo-ului)
gh project link "$PROJ_NUM" --owner "$OWNER" --repo "$REPO_FULL" >/dev/null 2>&1 || true

# --- issues ----------------------------------------------------------------
# title|labels(comma)|assignee|body-heredoc-file
ensure_issue(){ # title labels assignee body
  local title="$1" labels="$2" assignee="$3" body="$4"
  local existing
  existing="$(gh issue list --repo "$REPO_FULL" --state all --search "\"$title\" in:title" \
    --json number,title --jq ".[] | select(.title==\"$title\") | .number" 2>/dev/null | head -1 || true)"
  if [ -n "$existing" ]; then
    say "Issue exista deja (#$existing): $title"
    gh project item-add "$PROJ_NUM" --owner "$OWNER" \
      --url "https://github.com/$REPO_FULL/issues/$existing" >/dev/null 2>&1 || true
    return
  fi
  local args=(--repo "$REPO_FULL" --title "$title" --body "$body" --project "$PROJECT_TITLE")
  [ -n "$labels" ]   && args+=(--label "$labels")
  [ -n "$assignee" ] && args+=(--assignee "$assignee")
  local url
  url="$(gh issue create "${args[@]}")"
  say "Creat: $url"
}

say "Creez Issues…"

ensure_issue "Branch protection pe main (PR obligatoriu, 1 review)" \
  "milestone-a,role:process" "$ASSIGN_P3" \
"Activeaza branch protection pe \`main\`:
- PR obligatoriu inainte de merge (fara push direct)
- minim 1 review aprobat
- (optional) status checks obligatorii = CI-ul de la issue-ul de CI

Se poate aplica si automat cu \`scripts/gh_setup_board.sh\` (APPLY_BRANCH_PROTECTION=true)."

ensure_issue "CI minimal: workflow headless smoke test" \
  "milestone-a,role:process" "$ASSIGN_P3" \
"Adauga \`.github/workflows/ci.yml\` care ruleaza la push/PR:
- ruleaza Godot headless pe proiect (\`--headless --quit\` / sonda \`--fixed-fps 60\`)
- verifica ca proiectul incarca scena principala fara erori de import/parse
- fail la orice eroare in stderr

Scop: prinde regresii de incarcare/parse inainte de merge. Cache pentru binarul Godot ca sa fie rapid."

ensure_issue "Dunele: lock layout (6-7 momente distincte) pe track_from_path.gd" \
  "milestone-b,role:layout" "$ASSIGN_P1" \
"Fixeaza layout-ul final al pistei Dunele in \`track_from_path.gd\`:
- 6-7 'momente' distincte si memorabile de-a lungul tururui (alternanta drepte/viraje, elevatie)
- respecta principiul: piste scurte cu personalitate, elevatie folosita agresiv
- puncte de control curate ca baza pt gimmick + decor asezat de mana

Deliverable: layout blocat, versionat, peste care se pun gimmick-ul si props-urile."

ensure_issue "Dunele: gimmick semnatura (carusel SAU deviator) + zona fly-off/respawn" \
  "milestone-b,role:layout" "$ASSIGN_P1" \
"Implementeaza gimmick-ul semnatura al pistei (alege unul):
- **carusel** (obstacol rotativ care matura pista), SAU
- **deviator** (bariera/element care schimba traiectoria)

Plus o zona de **fly-off** (creasta care te arunca in aer) cu **respawn** corect daca ratezi aterizarea (repozitionare pe ultimul checkpoint valid, fara a bloca cursa)."

ensure_issue "Dunele: Blender MCP + generare props lipsa" \
  "milestone-b,role:props" "$ASSIGN_P2" \
"Conecteaza Blender MCP si genereaza props-urile lipsa, in stilul diorámă (atlas de paleta, AO in vertex colors — vezi docs/style_bible.md):
- water tower
- gas station
- windmill (animat)
- semn Route 66
- cactusi

Un singur material (atlas), UV spre culoarea din atlas, buget poly mobil respectat."

ensure_issue "Dunele: bidoane/anvelope/lazi -> obiecte fizice bump-abile" \
  "milestone-b,role:process" "$ASSIGN_P3" \
"Transforma bidoanele / anvelopele / lazile din decor static in obiecte fizice care se pot izbi (RigidBody / bump-able):
- masa/frecare tunate ca sa se simta satisfacator la impact
- nu blocheaza cursa (nu raman infipte in masina, nu zboara absurd)
- respecta bugetul: numar limitat de corpuri fizice active."

ensure_issue "Dunele: tunare masa/bumping/AI/SlidingHazard pe layout-ul nou" \
  "milestone-b,role:process" "$ASSIGN_P3" \
"Dupa ce layout-ul e blocat, tuneaza pe pista noua:
- masa & bumping intre masini (grea impinge, usoara zboara)
- liniile AI + anti-blocaj pe noile viraje/scurtaturi
- \`SlidingHazard\` (timing, viteza, pozitionare) sa fie fair, nu frustrant

Verificare: e satisfacator un tur singur, cu drift + saritura + bump?"

# --- branch protection -----------------------------------------------------
if [ "$APPLY_BRANCH_PROTECTION" = "true" ]; then
  say "Aplic branch protection pe main…"
  gh api -X PUT "repos/$REPO_FULL/branches/main/protection" \
    -H "Accept: application/vnd.github+json" --input - >/dev/null <<'JSON' \
    && say "Branch protection aplicat." \
    || warn "Branch protection a esuat (nevoie de plan/permisiuni de admin pe repo)."
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 1 },
  "restrictions": null
}
JSON
fi

say "Gata. Board: https://github.com/users/$OWNER/projects (cauta \"$PROJECT_TITLE\")"