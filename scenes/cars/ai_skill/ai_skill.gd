class_name AiSkill
extends Resource
## Cat de bine conduce un pilot AI (issue #682, docs/monetizare §7.5): nivelurile
## BRONZE / SILVER / GOLD din QUICK RACE si WORLD CUP. Un nivel nou = un .tres nou.
##
## Principiul 5 din CLAUDE.md („AI onest") decide ce are voie sa stea aici:
## DOAR cum se conduce — unde franezi, pe ce linie intri, cand arzi turbo-ul,
## cand tragi frana de mana, ce scurtatura iei, cat de mult ataci, cat de des
## gresesti. NICIUN camp nu atinge masina: nici `max_speed`, nici acceleratia,
## nici grip-ul, nici `speed_scale`, si nu exista catch-up pe viteza. Pilotul de
## Aur nu are o masina mai rapida, o foloseste mai bine; cel de Bronz lasa timp
## pe pista in locuri care se vad (franeaza devreme, intra larg, isi arde turbo-ul
## in viraj, mai rateaza cate o franare). Garda: tools/probe_ai_skill.gd.
##
## Valorile implicite de aici SUNT AI-ul de dinainte de niveluri, bit cu bit
## (fostele constante din `AIController`). Pe ele sunt masurate liniile de baza
## ale garzilor existente (ProbeRace, car_balance.sh, cariera), deci un
## `AiSkill.new()` trebuie sa conduca exact ca inainte — nu le schimba fara sa
## refaci acele masuratori.

## Ce parte din viteza maxima pastreaza intr-un viraj plin (fostul
## CORNER_SPEED_FLOOR). Mai jos = franeaza mai mult si mai devreme.
@export_range(0.2, 0.8, 0.01) var corner_speed_floor: float = 0.44
## Unghiul (rad, la punctul de tintire departat) de la care drumul nu mai e
## „drept" si incepe franarea (fostul CORNER_SOFT). Mai jos = ridica piciorul si
## pentru curbele line, pe care un pilot bun le ia cu tot.
@export_range(0.05, 0.6, 0.01) var corner_soft: float = 0.25
## Ce parte din viteza de varf a masinii lui o tine pe drept: peste ea ridica
## piciorul de pe gaz (nu franeaza). 1 = cu talpa pe podea, pana unde il duce
## masina (profilul implicit: ramura nici nu ruleaza). Plafonul masinii
## (`max_speed * speed_scale`) ramane neatins — doar pilotul apasa mai putin.
@export_range(0.7, 1.0, 0.01) var straight_speed: float = 1.0
## Cat de mult trage linia spre interiorul virajului, in semilatimi (fostul
## INSIDE_BIAS). Mare = taie apexul; mic = intra larg, pe drumul lung.
@export_range(0.0, 0.8, 0.01) var inside_bias: float = 0.55
## Severitatea virajului (0 drept .. 1 cel mai stramt) peste care trage frana de
## mana. Mai jos = drifteaza pe mai multe viraje, deci si bara de turbo se umple
## mai repede (driftul o incarca mult mai repede decat mersul).
@export_range(0.0, 1.0, 0.01) var drift_severity: float = 0.34
## De la ce incarcare a barei incepe sa arda turbo-ul pe drept.
@export_range(0.05, 1.0, 0.01) var turbo_min_charge: float = 0.6
## Severitatea peste care ridica degetul de pe TURBO inaintea virajului. 0.25 =
## il opreste devreme si nu-l aprinde decat pe drept. Peste 0.25 il tine si in
## viraj si il poate aprinde si in curba (aprinderea cere severitate sub
## `turbo_corner_cut - 0.25`): bara se arde unde oricum franezi, adica irosita.
@export_range(0.0, 1.5, 0.01) var turbo_corner_cut: float = 0.25
## Sansa de rocket start la GO (`Race._go`): bara arsa gratuit 0,8 s, ca a
## jucatorului care tine TURBO in ultima secunda.
@export_range(0.0, 1.0, 0.01) var rocket_start_chance: float = 0.45
## Sansa sa ia scurtatura, trasa o data pe cursa (fostul SHORTCUT_CHANCE). O
## pista care isi declara propria sansa (`Track.ai_shortcut_chance`) o pastreaza:
## acolo e decizie de design a pistei, nu de pilot.
@export_range(0.0, 1.0, 0.01) var shortcut_chance: float = 0.4
## Cat de devreme vede si ataca o masina mai lenta din fata: inmulteste fereastra
## de depasire (`AIController.AVOID_WINDOW_*`). Peste 1 = isi muta linia de
## departe si iese curat pe langa; sub 1 = observa tarziu si sta mai mult in
## spatele ei. Nu schimba nicio viteza, doar culoarul.
@export_range(0.3, 2.0, 0.05) var overtake_reach: float = 1.0
## Sansa, la intrarea intr-un viraj, sa faca o greseala VIZIBILA: ori franeaza
## tarziu (intra fierbinte, franeaza in viraj si iese larg), ori rateaza linia
## (intra pe exterior). Onest: e condus prost, fizica e aceeasi. 0 = nu greseste.
@export_range(0.0, 0.6, 0.01) var mistake_chance: float = 0.0


## Profilul AI-ului de dinainte de niveluri (valorile implicite de mai sus).
## Comun tuturor pilotilor care n-au primit alt nivel: resursa nu se modifica
## niciodata in timpul cursei, deci se poate imparti.
static var _implicit: AiSkill = null

static func implicit() -> AiSkill:
	if _implicit == null:
		_implicit = AiSkill.new()
	return _implicit


## Nivelurile de joc, in ordinea din selector. Indexul e ce se persista in
## setari (`GameState.ai_level`).
const LEVEL_PATHS: Array[String] = [
	"res://scenes/cars/ai_skill/bronz.tres",
	"res://scenes/cars/ai_skill/argint.tres",
	"res://scenes/cars/ai_skill/aur.tres",
]
const LEVEL_NAMES: Array[String] = ["BRONZE", "SILVER", "GOLD"]
## Nivelul jocului cand jucatorul n-a ales inca nimic.
const DEFAULT_LEVEL: int = 1
## Referinta sondei (toate butoanele la maximum): nu e nivel de joc, e rigla
## fata de care se masoara ecartul (§7.5: Bronz ~12%, Argint ~6%, Aur ~2%).
const REFERENCE_PATH: String = "res://scenes/cars/ai_skill/referinta.tres"


static func for_level(level: int) -> AiSkill:
	if level < 0 or level >= LEVEL_PATHS.size():
		return implicit()
	return load(LEVEL_PATHS[level]) as AiSkill


## Ce nivel primesc adversarii cursei care tocmai porneste. Cariera ramane pe
## profilul implicit: cum se leaga nivelurile de punctele ei e decizia deschisa
## #676. Orice cursa care nu trece prin QUICK RACE / WORLD CUP (sonde, cariera)
## are `GameState.race_ai_level == -1`, deci tot implicit.
static func for_race() -> AiSkill:
	if Career.active:
		return implicit()
	return for_level(GameState.race_ai_level)
