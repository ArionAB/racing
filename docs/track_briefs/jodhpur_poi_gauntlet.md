# Jodhpur — contractul per POI pentru gauntlet

> Fișa de lucru a perechilor constructor/critic pe Track17. Bara e
> `docs/track_briefs/img/jodhpur_diorama_v02.jpg`, decupată per POI în
> `docs/track_briefs/img/bar_jodhpur/bara_poi_<X>.png`
> (`tools/bar/crop_jodhpur_bar.py`, cu justificarea fiecărei cutii). Planul
> real al traseului e `docs/track_briefs/img/jodhpur_plan.png`. Kitul (48 de
> desene) e descris în `docs/asset_briefs/jodhpur_kit.md` (cote și coliziuni)
> și în `docs/asset_briefs/jodhpur_inventory.md` (cotele măsurate din GLB).
> **Sursa de adevăr pentru traseu e măsurătoarea de mai jos
> (`tools/sv_jod_fractii.gd`), nu brief-ul §2**: brief-ul §2 descrie bucla
> dinaintea construcției, iar pista construită e **oglindită** față de el
> (vezi §„Premise din brief găsite false").
>
> Măsurătorile sunt pe `origin/jodhpur/track17` = **4ac84517**, **înaintea
> fundației de decor**. După merge-ul fundației se re-rulează
> `godot --headless --path . res://tools/SvJodFractii.tscn` și se corectează
> tabelul de fracții dacă traseul s-a mișcat.

## Regula care se încalcă cel mai des

**Bara nu e layout, e look.** Diorama e o machetă pictată, văzută de sus, în
care fortul, orașul, fântâna și lacul încap toate într-un cadru. Pista nu face
asta și nu trebuie să facă asta: din mașină **fortul e perete** (brief §2.0),
fântâna e o groapă în care cobori, lacul e o râpă laterală. Criticul compară
**cum arată materia** — varul albastru în două tente, gresia roșie a fortului,
riolitul roz-brun, gresia roz a fântânii, apa verde stătută, marmura albă,
punctele calde de candelă, textilele saturate — nu unde cade fiecare obiect.

Corolar: un critic care spune „la noi pavilionul nu e pe o insulă în mijlocul
apei" sau „la noi nu se vede tot fortul" a comparat layout-ul și a ratat
sarcina. Singura diferență care contează e una pe care o poți repara în
decorul POI-ului.

**Defectele dioramei care NU se iau din imagine** (le-am verificat pe
decupajele mărite 2×; brief §2.0 și §8 le contrazic explicit):

| în dioramă | în joc (brief) | de ce |
|---|---|---|
| porțile E au goluri înguste, cât o mașină, cu canaturi închise la culoare în gol | **7,0 m liber**, măsurat ca GOL pe gabaritul caroseriei, canaturile lipite de ambrazură, în afara golului (kit §1.2) | e dop, nu oprire (brief §8, lecția semaforului Fiordland) |
| bastionul are parapet crenelat cu candele pe tot conturul, iar tunurile trag spre **deșert / soare** | **fără parapet pe vârful bastionului** (căzut = repunere), tunurile trag **spre oraș** | răsplata e orașul sub tine; parapetul ar închide vederea |
| vaca stă culcată într-o **arcadă laterală**, în afara drumului | vaca e culcată **în gura ulicioarei, pe banda de 6,4 m** (2,6–2,9 m de corp), la gura REALĂ (§Fracții) | e poarta scurtăturii (`CowGate`), nu decor |
| procesiunea (caii albi, toboșarii) e pe **carosabilul bazarului** | procesiunea e pe **trotuarul din D**, fără coliziune | teatru, nu obstacol (brief §8: respectul) |
| fortul e o cetate întreagă, cu palatul pe creastă | fortul e **perete**; se judecă doar fațada la înălțimea camerei (primele două etaje) | imposibil geometric: 500 m, dincolo de ceață (§2.0) |
| în fântână pavilionul stă pe o insulă, în mijlocul apei, iar drumul face o buclă mare | pavilionul e la **acul de la fund** (capătul de EST pe pista reală), rampele sunt pe terasament | layout |
| săritura: o mașină zboară de pe o stâncă **în lac** | lacul e o râpă pe **stânga** drumului; saltul (dacă se face) e peste un braț al lui, spre cenotaf | layout; la 4ac84517 kickerul nu există (§G2) |
| artificiile explodează sus, pe fundalul orașului | la **20–35 m peste case**, sub bastion, doar la `dusk ≥ 0,8` | cerul e 7,7% din cadru (§2.0) |

Un critic care cere una din astea a citit diorama, nu pista.

**Diorama e la apus (`dusk = 0`).** Bucla oarbă se judecă pe `--dusk=0`.
Nu există bară pentru `dusk = 0,5` și `dusk = 1`: acolo nu se compară cu
diorama, se verifică la integrare (vezi mai jos).

## Ieșirea din buclă (aceeași ca la Fiordland)

Pe Serengeti 0/8 POI-uri au câștigat orb, pe Machu Picchu 0/3, pe Fiordland
0/8. O dioramă pictată nu se bate orb de un cadru low-poly. Deci:

- **judecata rămâne oarbă** (`blind_pair.py`, o planșă per rundă, A sau B,
  o singură diferență numită);
- **ieșirea din buclă e** una din: (a) criticul alege a noastră orb; (b)
  criticul **nu mai numește nicio diferență reparabilă în decorul POI-ului**;
  (c) criticul numește **aceeași diferență de două ori la rând** — atunci
  cauza e sub decor (relief, lumină, shader, clasă de textură, asset) și se
  **oprește bucla**, cu decizia pusă în fața dezvoltatorului (memoria
  `criticul-cere-ce-zona-nu-poate-da`); verdictele criticilor se pun unul
  lângă altul între runde;
- **acceptarea finală e verdictul dezvoltatorului la volan**, pe scena
  integrată, **pe trei faze de lumină**: `--dusk=0` (apus, turul 1), `0,5`
  (ora albastră, turul 2) și `1` (noapte, turul 3). Sunt trei piste (brief
  §0.1: „dacă una dintre cele trei faze nu citește, pista nu e gata").

**Lumina în buclă.** Constructorul și criticul lucrează pe `--dusk=0`. La
integrare (nu în worktree-ul POI-ului) se fac capturile fiecărui POI și la
`--dusk=0.5` și `--dusk=1`, pe lume înghețată (memoria
`diferenta-on-off-cere-lume-inghetata`), 5 eșantioane (memoria
`o-captura-nu-e-un-verdict`). Testul de noapte e de material, nu de lumină
(brief §4): dacă la `dusk = 1` casele devin o pată indigo, lipsesc ferestrele
luminate și candelele pe parapete, adică decor — **se întoarce la POI-ul
respectiv**, nu se reglează ambientul.

## Ce se măsoară pe scena integrată (niciodată pe worktree-ul POI-ului)

Convenția de indici (memoria `probe-decor-numar-de-scena`): **`probe_decor` și
`probe_manual` iau numărul de SCENĂ (17); toate celelalte iau INDEXUL (10).**
Cu `--track=10` la `probe_decor` măsori Baikal (Track10) și dai verde fals.

| gardă | comandă | prag |
|---|---|---|
| ProbeRace | `res://tools/ProbeRace.tscn -- --mode=race --track=10 --seconds=150 --seed=N` | **16 seed-uri** (1..16), `--dusk=0`; tur minim `<de completat după fundație>`, repuneri pe distribuția bazei `<de completat după fundație>`, **0 `[blocaj]` > 2 s la porți (0.474–0.588)** (brief §2, contractul E, memoria `garda-cu-numele-gimmickului`). Citește `[blocaj]`/lent/invers/carusel, nu doar repuneri (memoria `zero-repuneri-ascunde-blocajul`). Cu trafic (implicit, `traffic_count` 6) și, pentru comparație, `--traffic=0`: diferența e costul traficului (memoria `proberace-nedeterminism`: distribuții, nu o rulare) |
| ProbeRace pe felie | idem + `--slice=A,B` | C: `--slice=0.12,0.28`; D′: `--slice=0.33,0.40`; E: `--slice=0.47,0.59`; G2: `--slice=0.84,0.92` — **înainte ȘI după** orice piesă cu coliziune pe felie |
| probe_decor | `--script res://tools/probe_decor.gd -- --track=17` | **≤ 38 materiale** (garda veto); plafonul brief-ului e **≤ 30**. Azi `<de completat după fundație>`. Un material nou se cere explicit în raport, cu ce cumpără vizual. Particulele de runtime (artificii, flăcări) nu intră în numărătoare: se adună de mână |
| ProbeBuried | `res://tools/ProbeBuried.tscn -- --track=10` | **0** îngropate, **0** tavane. Obligatoriu pe C (fântâna: două brațe la cote diferite pe același câmp de teren) |
| ProbeLaneClear | `res://tools/ProbeLaneClear.tscn -- --track=10` | **pe linia de bază**. **Track17 NU are încă linie de bază** în `tools/probe_lane_clear.gd` `BASELINE` (la 4ac84517): fără ea garda iese zero și pare verde (memoria `garda-fara-linie-de-baza-iese-zero`). Se măsoară și se scrie la fundație, cu fiecare raportare atribuită (porțile de 7 m pe drum de 9 m vor raporta — sunt intenționate), apoi se verifică prin sabotaj. Bază: `<de completat după fundație>` |
| ProbeLayout | `res://tools/ProbeLayout.tscn -- --track=10` | la 4ac84517: **2042,0 m**, rază minimă **7,3 m la 0.20** (acul fântânii), pantă maximă **14,2 % la 0.88** (Devkund; brief-ul cere < 13 %, sonda pică abia la 22 %), apropiere de sine **22,0 m la 0.15**; ulicioara 84,1 m, câștig 24 m (22 %). Verdict OK |
| probe_manual | `--script res://tools/probe_manual.gd -- --track=17` | **0 obiecte de reparat** (plutitoare / îngropate) |
| ProbeJodVaca | `res://tools/ProbeJodVaca.tscn -- --seeds=1,2,...,16 --seconds=150` | **0 contacte vacă–mașină** cu siguranța pornită, și **> 0** la sabotaj (`--ambush --all-shortcut --no-safety`; memoria `banda-inchisa-nu-e-ruta`: 0 / 671). Obligatoriu după orice piesă pusă pe D′ |
| sv_hazard_orient | `--script res://tools/sv_hazard_orient.gd -- --scene=17 --decor` | **0 noduri suspecte** după orice piesă cu axă (porțile, tunurile, poarta ulicioarei) |
| sv_jod_fractii | `res://tools/SvJodFractii.tscn` (headless) | nu e gardă; re-rulat după fundație și după orice atingere a traseului: fracțiile din tabelul de capturi |
| tabelul de frustum | `tools/jodhpur_frustum_table.py` | **nu există încă** (brief §7 pas 4). Până atunci contractele de vizibilitate din §2.0 se verifică doar pe captură |

`--import` înaintea oricărei serii (memoria `import-invechit-falsifica-masuratoarea`)
și după FIECARE merge (memoria `merge-curat-scena-stricata`).

## Captura: ce comandă, pentru care POI

Din mașină, `--gamecam` (camera reală: 10 m sus, 12,5 m spate, fov 68 —
memoria `verifica-cu-parametrii-lui`). **`--dusk=0` explicit** în buclă (e și
implicitul, dar se scrie în comandă, memoria
`unealta-de-captura-e-parte-din-masuratoare`).

```
& $E --rendering-driver vulkan --path <worktree> `
    res://tools/Snapshot.tscn -- --track=10 --frac=<F> --gamecam --dusk=0 [flaguri]
```

Snapshot **nu merge headless** (memoria `snapshot-nu-merge-headless`); capturile
se fac **serial**, gărzile în paralel (memoria `capturile-nu-se-paralelizeaza`).
Fracțiile de mai jos sunt **pe index** (cele pe care le ia `--frac`); pe
Track17 divergența index–lungime e de cel mult **1,9 m**, deci nu contează aici.

**Flagurile care există azi în `tools/snapshot.gd`:** `--dusk`, `--route`,
`--frac`, `--gamecam`, `--eye/--look`, `--landmark`, `--hide`, plus cele ale
altor piste (`--rock-at`, `--bus-at`, `--train-at` etc.). **Nu există nimic
pentru Jodhpur în afară de `--dusk`.** Mai mult: Snapshot încarcă doar
pista, nu cursa, deci **tuk-tuk-urile nu apar deloc în captură**
(`race.gd::_spawn_traffic`). Flagurile lipsă sunt sarcina constructorului
POI-ului care le consumă, în **prima rundă**, pe tiparul `--rock-at` /
`--avalanche-at` (mută ceasul hazardului la o valoare fixă, lume înghețată):

| flag lipsă | ce face | cine îl scrie |
|---|---|---|
| `--tuk-at=<frac>[:<lat>],...` | așază tuk-tuk-uri (`Car.tscn` + `tuktuk.tres`, controller oprit) la fracțiile date, pe banda stângă (lat −2,2 implicit) | **B** (îl folosesc și A, H) |
| `--cow=stand\|lie` | forțează starea `CowGate` (pe prag / culcată în gură), fără telegraph | **D** (D′ e în contractul lui D) |
| `--baraat-at=<s>` | ceasul procesiunii (`PathMover`) | **D** |
| `--salute-at=<s>` | ceasul tunurilor de salut (salva la fază fixă) | **F** |
| `--zip-at=<s>` | poziția siluetei pe cablul tirolienei | **F** |
| `--fireworks-at=<s>` | explozii la fază fixă (cer `dusk ≥ 0,8`; fără flag nu se pot judeca) | **F** (îl folosesc G, H) |

Tunurile, tiroliana, procesiunea și artificiile **nu există încă în cod** la
4ac84517 (nicio clasă în `scenes/hazards/`, `DuskCycle` doar le pomenește).
Construirea lor e parte din POI-ul care le deține; flagul vine odată cu ele.

| POI | frac de captură | flaguri | bară |
|---|---|---|---|
| A Start | 0.000, 0.020; plus 0.970 (privind turnul din H) | `--tuk-at` pentru tuk-tuk-urile parcate | `bara_poi_A` + `bara_poi_TURN` |
| B Bazar | 0.040, 0.080, 0.115 | `--tuk-at=0.05,0.09` | `bara_poi_B` |
| C Fântâna | 0.130 (buza, după viraj), 0.160 (rampa de intrare), 0.198 (acul), 0.230 (rampa de ieșire), 0.260 | — | `bara_poi_C` |
| D Orașul | 0.280, 0.320, 0.420, 0.460 | `--baraat-at` | `bara_poi_D` |
| D′ Ulicioara | `--route=1 --frac=0.345`, `--route=1 --frac=0.360`; de pe buclă 0.340 (furca) | `--cow=lie` și `--cow=stand` | `bara_poi_D2` |
| E Porțile | 0.480, 0.505, 0.530, 0.555, 0.575 | `--tuk-at` într-o poartă (opțional) | `bara_poi_E` |
| F Bastionul | 0.600 (fațada), 0.630, 0.650 (brațul care privește orașul), 0.666 (vârful), 0.680 | `--salute-at`, `--zip-at`; `--fireworks-at` doar la integrare cu `--dusk=1` | `bara_poi_F` + `bara_poi_PALAT` |
| G Coborârea | 0.720, 0.770, 0.820 | — | `bara_poi_G` |
| G2 Devkund | 0.850, 0.875, 0.890 | — | `bara_poi_G2` + `bara_poi_CENOTAF` |
| H Dreapta | 0.910, 0.950, 0.980 | `--tuk-at=0.93,0.96` | `bara_poi_H` + `bara_poi_TURN` |

## Fracțiile reale ale traseului (NU cele din brief §2)

Măsurate pe `Track17.tscn` la 4ac84517 cu `tools/sv_jod_fractii.gd`
(headless): **2042,0 m**, 1019 puncte coapte, pas 2,0 m. Fracții pe index;
pe lungime diferă cu ≤ 0,0009. Re-măsurate pe ramura `jodhpur/poi-relief`
(fântâna strânsă + săritura Devkund): lungimea și toate reperele de mai jos
au rămas la ±0,0002, cu excepția punctului cel mai jos de la Devkund (profilul
G2 refăcut); rândurile noi (apa fântânii, peretele, kickerul) vin de acolo, cu
`tools/SvJodRelief.tscn`.

| reper | frac (index) | cotă | semi | poziție (x, z) |
|---|---|---|---|---|
| grila de start | **0.000** | 0,0 | 6,5 | (−30, 190) |
| primul viraj (V → N) | 0.094 | +2,0 | 6,5 | (−212, 154) |
| **intrarea în pâlnia fântânii / virajul spre ea** (r ≈ 29) | **0.129** | +0,7 | 6,5 | (−219, 85) |
| sfârșitul benzii de 6,5 (bazarul se îngustează la 4,5) | 0.118 | +1,4 | → 4,5 | |
| **buza fântânii** (începe coborârea) | **0.135** | −0,1 | 4,5 | (−209, 77) |
| fundul: palierul de −9 | 0.189 – 0.206 | −9,0 | 4,5 / 5,0 | |
| apa fântânii (între brațe, pe stânga) | cornișa 0.145 – 0.264 (lungime) | apă −9,5, fund −14 | | 20 de celule, repunere cu 14 m |
| peretele exterior (dreapta, debleu 0.135 – 0.264) | | buza 0,0 | | +1 m la 4,5–9,5 m de margine, 90 % la 11–19 m |
| **vârful acului de păr** (capătul de EST) | **0.198** | −9,0 | 5,0 | (−86, 61) |
| **ieșirea din fântână** | **0.264** | −0,2 | 4,5 | (−215, 43) |
| ieșirea din pâlnie (r 72) | 0.267 | 0,0 | 4,6 | |
| viraj D1 (spre NE) | 0.305 | +2,2 | 5,0 | (−228, −38) |
| **furca ulicioarei** (`entry_frac`) | **0.3405** | +6,0 | 5,0 | (−179, −89) |
| **gura REALĂ a ulicioarei** (golul margine–margine > 0) | **25,4 m pe bandă**, lângă bucla la 0.353 | +7,3 | 3,2 | (−152, −85) |
| `CowGate.mouth_position` (`mouth_dist_m` 30) | 29,3 m pe bandă | +7,5 | 3,2 | (−148, −85) |
| `AlleyGate` (poarta de 4 m) | 30 m pe bandă | | | |
| **revenirea ulicioarei** (`exit_frac`) | **0.3935** | +10,0 | 5,0 | (−100, −105) |
| viraje D2 / D3 | 0.340 (+90°), 0.375 (−86°), 0.398 (+62°) | +6 / +9 / +10 | 5,0 | |
| **Jai Pol** (piciorul fortului, prima trecere peste +18) | **0.474** | +18,0 | 5,0 → 4,5 la 0.476 | (54, −152) |
| **acele porților** (≈ 100°, r ≈ 23–29 m pe fereastra de 40 m) | **0.494 (st), 0.518 (dr), 0.541 (st), 0.563 (dr)** | +20,4 / +24,5 / +29,1 / +34,0 | 4,5 | (80, −181) / (61, −222) / (88, −257) / (67, −295) |
| ieșirea din zigzag (viraj de 48°) | 0.588 | +38,2 | 4,5 → 6,0 la 0.582 | (106, −324) |
| fațada palatului (dreapta spre est) | 0.588 – 0.622 | +38 → +40 | 6,0 | |
| colțul bastionului (+85°) | 0.622 | +40,0 | 6,0 | (165, −296) |
| **cota maximă** | 0.625 | **+40,0** | 6,0 | (165, −291) |
| platoul ≥ +39,9 | 0.621 – 0.665 | +40 | 6,0 | |
| **vârful bastionului** (acul lat, −132°, r ≈ 17) | **0.666** | +39,9 | 6,0 | (125, −221) |
| **începutul coborârii** (pantă < −3 %) | **0.691** | +39,2 | 6,0 → 6,5 | (167, −227) |
| ieșirea din fort (viraj +95°) | 0.699 | +38,4 | 6,5 | (182, −230) |
| râpa lacului Devkund (pe lungime 0.860–0.910) | **0.861 – 0.910** | fund −18, apă −4,3 (= canalul) | 6,0 | lateral **stânga** |
| **buza de lansare Devkund** (kicker 1,4 m) | **0.880** | +0,3 | 6,0 | (174, 118) |
| golul Devkund (canal, apă −4,3) | 0.880 – 0.888 (15,4 m) | | | centrul la 0.884 |
| **aterizarea Devkund** (dala de pe mal) | **0.888** | −1,1 | 6,0 | (172, 133) |
| punctul cel mai jos la Devkund | 0.892 | −1,4 | 6,0 | (170, 142) |
| intrarea pe dreapta H (viraj +73°) | **0.906** | +0,3 | 7,0 | (160, 166) |
| capătul dreptei H | 0.999 | 0,0 | 7,0 | (−28, 190) |

**Semilățimile** (`custom_width_segments`, fracții pe index): 0–0.118 **6,5**
(A și B; brief-ul cerea 8 pe A); 0.118–0.197 **4,5** (rampa de intrare);
0.197–0.203 **5,0** (acul); 0.203–0.265 **4,5** (rampa de ieșire);
0.265–0.476 **5,0** (D); 0.476–0.582 **4,5** (porțile: drum de 9 m, poartă de
7 m); 0.582–0.693 **6,0** (F); 0.693–0.829 **6,5** (G); 0.829–0.900 **6,0**
(G2); 0.900–1.0 **7,0** (H). Ulicioara: 3,2 (6,4 m), 84,1 m, 22 % câștig.

**Față de brief §2:**

| POI | brief | măsurat | |
|---|---|---|---|
| A | 0.00–0.05 | grila 0.000; A se termină la primul viraj, 0.094 | |
| B | 0.05–0.17 | ~0.03–0.129 (virajul spre fântână) | **se termină cu 0.04 mai devreme** |
| C | 0.17–0.29 | 0.129–0.267 (buza 0.135, acul 0.198, ieșirea 0.264) | **începe cu 0.04 mai devreme** |
| D | 0.29–0.46 | 0.267–0.474 | |
| D′ | 0.33–0.41 | furca 0.3405, gura reală la 0.353 (25 m pe bandă), revenirea 0.3935 | |
| E | 0.46–0.58 | 0.474–0.588, **patru** ace (0.494, 0.518, 0.541, 0.563) | brief: trei ace |
| F | 0.58–0.70 | 0.588–0.699, vârful la 0.666 | |
| G | 0.70–0.84 | 0.699–0.861 | |
| G2 | 0.84–0.87 | râpa 0.861–0.910, cel mai jos la 0.891 | **se termină cu 0.04 mai târziu** |
| H | 0.87–1.00 | 0.906–1.000 | **începe cu 0.036 mai târziu** |

Azimutul reperelor față de direcția de mers (doar axa laterală, ±50°; fără
verticală și fără ocluzie — acelea sunt ale tabelului de frustum):

| interval | țintă | în cadru | azimut | distanță |
|---|---|---|---|---|
| B 0.05–0.135 | centrul fântânii | **10 %** | +13…+87° (dreapta) | 63–129 m |
| D 0.264–0.474 | stânca fortului | **73 %** (brief: ≥ 80 %) | −73…+100° | 150–473 m |
| F fațada 0.588–0.622 | centroidul orașului | **0 %** | +57…+114° | 306–315 m |
| **F brațul de intrare 0.622–0.666** | centroidul orașului | **98 %** | −15…+52° | 222–306 m |
| F brațul de intrare | fântâna | 93 % | −3…+63° | **396–478 m** |
| **F brațul de ieșire 0.666–0.699** | centroidul orașului | **0 %** | +54…+173° | 219–262 m |
| G 0.699–0.861 | centroidul orașului | **0 %** | +55…+119° (dreapta) | 186–265 m |
| H 0.906–1.0 | grila (turnul lângă ea) | 100 % | −41…+35° | 9–192 m |

## Premise din brief găsite false (la 4ac84517)

Nu sunt defecte de POI; sunt fapte despre pistă pe care constructorii trebuie
să le știe înainte să citească brief-ul §2 / §2.0, și câteva decizii care
aparțin coordonatorului sau dezvoltatorului, nu unui POI.

1. **Bucla e oglindită față de brief.** Brief-ul: invers acelor, A spre est,
   fortul în NV, soarele din vest. Pista: **în sensul acelor** (A spre vest,
   apoi nord, est, sud), fortul în **NE** (`FortRock` la (135, −275)), soarele
   din dreapta planului (`custom_sun_rotation_deg` (−8, 90, 0)). Diorama v02 e
   orientată ca pista reală, nu ca brief-ul. Toate „stânga/dreapta" din
   brief §2 trebuie citite de pe planul real.
2. **Fântâna: acul e la capătul de EST, nu de vest.** Se intră pe brațul de
   sud spre est, se iese pe brațul de nord spre vest. `stepwell_pavilion` („de
   la capătul de vest", kit §1.3) se pune la **est**, la (−86, 61).
3. **Fântâna: ÎNCHISĂ pe `jodhpur/poi-relief`** (era: rampe pe terasament
   peste o podea plată la −9, pereții la 40–60 m). Acum `TerrainHollow` e
   scos; groapa e făcută din două piese de relief care urmăresc drumul: pe
   **stânga** (interiorul acului, între brațe) o cornișă (`custom_ravines`
   0.145–0.264, fund −14) cu **apă la −9,5** și `RespawnZone`; pe **dreapta**
   un debleu (`custom_cuttings`, buza la 0,0): peretele urcă de la un umăr de
   6,5 m, trece de +1 m la 4,5–9,5 m de marginea asfaltului și ajunge la buză
   la 11–19 m. Umărul de 6,5 m nu e de gust: e grila de teren de 7,9 m (sub
   ~5 m, coarda dintre noduri urcă peste asfalt). **Treptele nu sunt teren**
   (grila nu poate reda trepte de 0,3 m și etaje de 3 m pe 2,5 m): modulele
   `stepwell_flight_module` / `stepwell_corner` (decor fără coliziune) se
   așază pe peretele de teren de pe dreapta, trei etaje. Apa se vede doar
   unde fundul trece sub −9,5 (≈ 0.15–0.25); în capul rampelor fanta e uscată.
4. **Buza fântânii nu e „în față" din bazar.** Pe B centrul fântânii e la
   +13…+87° pe dreapta (în cadru pe 10 % din B); frontală devine abia după
   virajul de la 0.129, cu ~13 m înainte de buză.
5. **Raza acului de la fund: 7,3 m** (ProbeLayout), nu 10. Semilățimea acolo
   e 5,0, deci regula „rază > semilățime" ține.
6. **Porțile: patru ace de ~100°, nu trei unghiuri drepte; raza ~23–29 m**
   (estimare pe o fereastră de 40 m), la 47–50 m unul de altul. Pe unde stau
   cele trei porți decide constructorul E (propunere: Jai Pol la piciorul
   stâncii, pe dreapta de 0.476–0.49 dinaintea primului ac, Fateh Pol după
   acul 0.518, Loha Pol după acul 0.563; fiecare la ~15–20 m după vârful
   acului, pe porțiunea dreaptă). Drumul are 9 m,
   poarta 7 m: poarta strâmtează cu 1 m pe fiecare parte, intenționat.
7. **Pe porți nu există nici zid, nici cădere în teren.** Profilul transversal
   e plat pe ±14 m; stânca urcă doar la +15 m la 40 m pe dreapta pe acele spre
   NV. Zidul de 14 m și căderea cu parapet sunt **decor**, nu relief.
8. **Bastionul: orașul se vede de pe brațul de INTRARE, nu de ieșire.**
   Brief §2.0 cere orașul „în față pe brațul de ieșire, ≥ 70 %". Pe pista
   reală: brațul de intrare 0.622–0.666 (spre SV) are orașul în cadru pe
   **98 %** din puncte; brațul de ieșire 0.666–0.699 (spre est) pe **0 %**;
   fațada 0.588–0.622 pe 0 % (orașul e pe dreapta, la 57–114°).
9. **Fântâna nu se vede de pe bastion: e la 396–478 m**, dincolo de
   `fog_end` (300 ziua, 240 noaptea). Brief-ul cere ≤ 260 m și își scrie
   singur regula: „dacă fântâna iese peste 260 m, se mută fântâna spre
   interiorul buclei, nu se rărește ceața". Asta e o decizie de traseu
   (coordonator/dezvoltator), **nu** a POI-ului F. Până atunci contractul lui F
   e doar „orașul sub tine", fără pătratul fântânii.
10. **Vârful bastionului nu are cădere lângă drum.** La 0.666 terenul e plat
    până la ±9 m, coboară −2,5 la 14 m, −6,4 la 20 m, −13 la 30 m (spre oraș).
    „Fără parapet, căzut = repunere" cere o cornișă (`custom_ravines` +
    `RespawnZone`) — relief, nu decor.
11. **Coborârea G: orașul e pe DREAPTA (în afara cadrului), lacul și cenotaful
    pe STÂNGA.** Brief-ul: „orașul stânga-față, cenotaful dreapta-față". Râpa
    lacului e pe stânga (`w = −1`; −13…−15 m la 30 m stânga pe 0.875–0.895).
12. **G2 are săritură pe `jodhpur/poi-relief`** (era: niciun kicker). Nodul
    `KickerDevkund` (`TrackChannel`, `jump`) taie drumul pe 15,4 m între
    0.880 și 0.888, cu trambulina portocalie de 1,4 m la buză, apă la −4,3
    în canal și în lac (`custom_ravine_water` −4,32, aceeași cotă ca apa canalului, altfel cusătură de 0,3 m între suprafețe), repunere cu 70 m de elan.
    Profilul coborârii refăcut: panta maximă 14,2 % → **12,8 %** (acum la
    0.77), aterizarea cu 1,4 m sub buză. Brațul de apă e **perpendicular** pe
    drum (canal), lacul rămâne pe **stânga**; pe dreapta canalul se stinge în
    45 m. Tuk-tuk-urile își iau elan pe ultimii 40 m (`TrafficController`).
    Dala de aterizare și cenotaful rămân decor (POI-ul G2); orice piesă cu
    coliziune pe 0.87–0.90 cere ProbeRace `--slice=0.84,0.92` înainte și după.
13. **D: fortul e în cadru pe 73 % din urcare** (azimut), sub contractul de
    80 % din §2.0; cu verticala și ocluzia cifra poate doar scădea.
14. **Lungimea e 2042 m**, nu ~2,1 km.
15. **Lipsesc din scena de bază:** linia de bază ProbeLaneClear. (`CameraFantana`
    — height 13, look 0.4, fov_bonus 4, ceiling 0, pe fracții 0.135–0.264 —,
    `RespawnZone` în apa fântânii și a lacului și kickerul G2 vin de pe
    `jodhpur/poi-relief`.) `<de completat după fundație>`
    care din ele a adus-o fundația.

## Fapte din fundație

`<de completat>` — de coordonator, după merge-ul fundației
(`wt-jod-poi-base`): commit-ul fundației; ce e montat per zonă (noduri
`Zone*`); cifrele de plecare ale gărzilor (probe_decor, ProbeLaneClear cu
baza scrisă, probe_manual, ProbeBuried, ProbeRace pe 16 seed-uri); ce s-a
schimbat în traseu (re-rulează `SvJodFractii.tscn`); cotele reale ale pieselor
din kit în joc (măsurătorile kitului); ce premise din lista de mai sus au fost
închise de fundație.

## Contractele per POI

Fiecare: **ce se vede în decupaj** (obligația vizuală) + **ce cere brief-ul**
(obligația de gameplay) + **ce nu se atinge** + **piesele** + **coliziunea** +
**capcana**.

Piese comune: `blue_house_a…e`, `haveli_facade`, `rooftop_tank`,
`rooftop_clutter` (orașul, oriunde e oraș), `diya` pe `FlockProp` (pe praguri
și parapete, peste tot), `marigold_garland`, sforile de becuri (cod,
MultiMesh pe catenară), `neem_tree`, `khejri_tree`, reuse
`stromboli/props/bougainvillea.glb`, `stromboli/buildings/street_shrine.glb`,
`chongqing/props/laundry_line.glb`. Coliziuni (brief §5.6): case și ziduri
`mesh`/`hull` pe primul rând lângă drum, `stall_canopy_*: hull`,
`fort_gate_*: mesh`, `neem_tree`/`khejri_tree: trunk`,
`peacock_*`/`langur`/`floating_diya`/`textile_strip`/`marigold_garland`/
`zipline_rider`/`baraat_*: none`. **Casele dincolo de ~40 m de drum sunt
MultiMesh feliat, nu noduri** (memoria `decor-in-masa-cere-multimesh`: peste
~1000 de piese încărcarea se blochează) — decizia de mecanism se ia **la
fundație, o dată**, nu per POI.

Tiparele de scatter care au picat toate rundele pe Serengeti se evită de la
început (memoria `aranjamentul-bate-numarul`): **nu grilă** (jitter ≥ 0,5 din
pas, yaw variat, corpuri care se ocluzionează), densitatea **crește spre
drum**, se populează **interiorul** suprafeței, nu doar un tiv. La verdictul de
fidelitate liderul mărește decupajele la rezoluție plină (memoria
`numaratoarea-trece-amplasarea-nu`).

### A — Startul sub Ghanta Ghar (frac 0.000–0.094)

Din decupaj (`bara_poi_A`, `bara_poi_TURN`): **turnul cu ceas** de gresie
roz-portocalie cu 4 cadrane albe, **rangoli** mare, multicolor, pe caldarâmul
grilei, **arcada porții pieței** în spatele turnului, tuk-tuk-uri negru-galben
la bordură, ghirlande și sfori de becuri, oameni pe trotuar.

Brief: grila pe caldarâm, rangoli **decal** pe start (nu pe sosire), turnul la
30–50 m spate-stânga (pe pista reală: lângă capătul dreptei H, care ajunge la
grilă dinspre est), arcada peste grilă, rând de tuk-tuk-uri parcate (**corpuri
`Car` oprite, se împing**; primele 3 pornesc cu cursa).

Nu se atinge: tuk-tuk-urile parcate sunt trafic (cod), nu decor; grila.
Piese: `ghanta_ghar` (reperul lui H, se judecă și din H), `market_gate` (golul
≥ 18 m peste un drum de 13 m, cheia ≥ 11 m pentru cameră), decalul rangoli
(cod, sloturile din brief §4), `marigold_garland`, `diya`, case pe margini.
Coliziune: turnul și soclul porții `mesh`; ghirlandele `none`.

Capcana: `market_gate` e peste grilă, deci camera trece prin ea: golul se
măsoară ca GOL, pe gabaritul camerei (memoria `cota-de-contract-se-masoara-ca-gol`).
Turnul se vede întreg abia de la 130 m pe H: pe A e doar baza, asta se acceptă
(§2.0). Memoria `corp-cinematic-aparut-in-masina`: tuk-tuk-urile parcate nu
se pun pe grilă.

### B — Bazarul Sardar (frac ~0.03–0.129)

Din decupaj: **tarabe cu copertine de pânză saturate** (galben, roz, verde,
roșu), **fâșii de textile PESTE stradă**, saci de condimente, mulțime pe
trotuar, tuk-tuk-uri pe bandă, case albastre deasupra tarabelor.

Brief: stradă dreaptă cu o cotitură (pe pista reală: dreapta spre vest,
virajul 0.094 spre nord, apoi virajul 0.129 spre fântână), fâșiile la
**7–9 m** (sub marginea de sus a cadrului), tarabele sunt **pereți cu masă**,
nu decor fantomă. Tuk-tuk-urile circulă pe banda stângă la 14 m/s.
Singurul loc cu textile saturate (brief §4).

Nu se atinge: traficul (cod), banda de 13 m (0–0.118) — tarabele stau în
afara ei. Piese: `stall_canopy_a/b/c` (`hull`), `textile_strip` (`none`, sfoara
legată de case, nu de stâlpi), `spice_sacks`, `thela_cart`, `chai_stall`,
reuse scuter/bicicletă/scaune. Procesiunea **nu** e aici (defect declarat al
dioramei). Flagul `--tuk-at` e al lui B.

Capcana: memoria `obstacol-pe-drum-poate-fi-gimmick` — AI-ul nu vede decor
static: nicio tarabă, niciun sac pe asfalt. ProbeLaneClear pe bază. Fâșiile
sus nu se văd dacă sunt peste +9 m la distanța de citire (memoria
`inaltimea-obiectelor-si-camera`).

### C — Fântâna în trepte (frac 0.129–0.267)

Din decupaj: **gresie roz-piersică**, **fluxuri de trepte în V** pe etaje,
**apă verde-închis** cu **candele plutitoare**, **pavilionul cu coloane și
cupolă**, candele pe fiecare treaptă, drumul care coboară în groapă.

Brief: groapă cu trei etaje de trepte, rampe la 10 %, ac de păr la fund cu
pavilionul, apa = repunere, **fără parapet spre apă**, `CameraZone` ridicată
(height 13, ceiling 0, fov_bonus 4), copii pe trepte (teatru). Drift
obligatoriu în ac (bara de turbo se încarcă).

Geometria reală (§Premise 2, 3, 5): acul la **est** (0.198, r 7,3), rampele pe
terasament peste podeaua de −9, pereții gropii la 40–60 m.
Nu se atinge: relieful gropii (`TerrainHollow`, râpa 0.141–0.253), rampele.
Dacă trebuie `CameraZone`/`RespawnZone` și nu le-a pus fundația, le pune C, cu
ProbeRace pe felie înainte și după.
Piese: `stepwell_flight_module` (**decor pur, fără coliziune**, capete plane
la ±6, trei etaje), `stepwell_corner`, `stepwell_pavilion` (la acul de EST),
`floating_diya` (MultiMesh pe apă), `diya` pe trepte. **Copiii nu există în
kit** — fie se renunță, fie e cerere de asset (se scrie în raport).

Capcana: **fântâna e cea mai scumpă zonă pentru gărzi**: ProbeBuried (două
brațe la cote diferite pe același câmp de teren), ProbeLaneClear (banda
rampei liberă 9 m + 0,5 m pe fiecare parte, brief §5.2), ProbeRace
`--slice=0.12,0.28`. Treptele primesc umbră din **geometrie** (0,3 m pe
treaptă), nu din textură (memoria `silueta-inainte-de-umbrire`). Apa verde,
nu albastră (memoriile `apa-stilizata-de-noapte`, `apa-iluminata-v12`,
`celula-de-apa-plana-peste-mal`). Camera în ac se decide pe 5 eșantioane
(memoria `o-captura-nu-e-un-verdict`). Dacă criticul cere de două ori
„treptele lângă drum", e relief: **(c)**.

### D — Orașul albastru (frac 0.267–0.474)

Din decupaj: **case cub de 2–4 etaje în două tente** (albastru deschis și
indigo), ~1 din 8 ocru, **rezervoare negre pe terase**, candele pe fiecare
parapet, ferestre luminate, copaci rari, drumul care urcă printre case.

Brief: urcare 5,3 % prin ulițe de 9–10 m cu S-uri (pe pista reală: virajele
0.305, 0.340, 0.375, 0.398), scări exterioare, havele, altar alb cu steag,
păuni pe ziduri, **procesiunea de nuntă pe trotuarul din stânga**, în sens
invers, fără coliziune; **fortul crește în parbriz** (73 % în cadru pe
azimut — §Premise 13). Primul contact cu varul albastru: aici se verifică
tentele `blue_lime_light` / `blue_lime_indigo` **după remap, în joc** (memoria
`monocromia-se-masoara-dupa-remap`).

Nu se atinge: traficul; tenta clasei `village_plaster` (brief §4: recolorează
Stromboli). Piese: `blue_house_a…e`, `haveli_facade`, `rooftop_tank`,
`rooftop_clutter`, `street_shrine` (reuse), `peacock_closed/fanned` (`none`,
5–7 pe tur), `baraat_horse` + `baraat_band` (`PathMover` pe trotuar, `none`),
`neem_tree`, `laundry_line`. Flagul `--baraat-at` e al lui D.

Capcana: memoria `decor-in-masa-cere-multimesh` (primul rând lângă drum e
`DecorManual` cu coliziune, restul MultiMesh); memoria `aranjamentul-bate-numarul`
(casele nu pe grilă); noaptea casele trebuie să citească prin ferestre și
candele, nu prin ambient (brief §4).

### D′ — Ulicioara și vaca (furca 0.3405, gura 25 m, revenirea 0.3935) — parte din contractul lui D

Din decupaj (`bara_poi_D2`): **arcadă de gresie** în zid albastru, **vaca
zebu albă culcată** (coarne portocalii, ghirlandă), fâșii de textile, ziduri
albastre înalte, candele pe praguri.

Brief: bandă de 3,2 m semi (6,4 m) între ziduri albastre, rufe întinse,
candele pe praguri; vaca **în gura ulicioarei**; tuk-tuk-urile nu intră
niciodată.

Nu se atinge, sub nicio formă: `CowGate` (`mouth_dist_m` 30,
`threshold_offset_m` 2,5, siguranța), `AlleyGate` (poarta de 4 m la 30 m pe
bandă), `TrackBranch` (entry/exit), logica `branch_is_open`. **Gura reală e la
25,4 m pe bandă**, la (−152, −85): în primii 25 m banda stă pe asfaltul buclei
(pleacă tangent) — memoria `banda-inchisa-nu-e-ruta`. **Nimic cu coliziune pe
primii 25 m de bandă** (e bucla principală) și nimic pe cei 6,4 m ai benzii
după gură. Pragul vacii e pe partea departe de buclă: nu se pune decor acolo.
Piese: case albastre ca **ziduri** ale benzii (coliziune `mesh`/`hull`, la
≥ 3,2 m + marjă de axa benzii), `laundry_line`, `diya` pe praguri,
`zebu_cow` (dacă nu l-a montat fundația: export `model` pe `CowGate`, AABB
2,6–2,9 m). Flagul `--cow=stand|lie` e al lui D.

Capcana: ProbeJodVaca după **orice** piesă (0 contacte, sabotajul > 0) și
ProbeRace `--slice=0.33,0.40` cu `[blocaj]` citit (memoria
`zero-repuneri-ascunde-blocajul`: 23–45 repuneri/cursă înainte de fix).
Memoria `suprafete-cu-goluri-si-praguri`: nimic cu prag > 0,3 m pe bandă.

### E — Porțile fortului (frac 0.474–0.588)

Din decupaj: drum în **zigzag** pe stânca roz-brună, **ziduri de gresie roșie
crenelate** cu candele, **porți cu turnuri rotunde** și canaturi de lemn
închis, chhatri pe ziduri, casele albastre la picior.

Brief: trei porți (Jai Pol, Fateh Pol, Loha Pol), fiecare după un ac,
canaturi deschise bătute cu țepi, zidul de 14 m pe o parte, căderea spre oraș
cu parapet crenelat pe cealaltă, languri pe parapet. **Golul de 7,0 m**
măsurat ca GOL. **Niciun `[blocaj]` > 2 s la porți pe 16 seed-uri.**

Geometria reală (§Premise 6, 7): patru ace de ~100°, drum de 9 m, teren plat
lateral — zidul și căderea sunt decor. Nu se atinge: traseul, lățimea de 4,5.
Piese: `fort_gate_jai`, `fort_gate_fateh`, `fort_gate_loha` (`mesh`, originea
centrată pe axul golului, pusă pe axa drumului), `fort_wall_segment`
(capete plane la ±6, se înlănțuie; `mesh`), `fort_wall_turret`, `langur`
(`none`), bougainvillea, `rhyolite_boulder_*` la piciorul zidului.

Capcana: poarta de 7 m pe drum de 9 m — ProbeLaneClear **va** raporta porțile;
raportările intră în linia de bază cu atribuire, ca kickerul Bowen la
Fiordland; orice raportare **laterală** în plus e coliziune reală. Golul se
măsoară pe fereastra lui (memoria `golul-se-masoara-pe-fereastra-lui`: arcul e
ascuțit, gabaritul caroseriei). Poarta se pune pe o porțiune **dreaptă** după
ac, altfel golul drept pe drum curb taie asfaltul (lecția podului Fiordland:
„măsoară săgeata înainte de gap"). `sv_hazard_orient` după fiecare poartă.
ProbeRace `--slice=0.47,0.59`, 16 seed-uri, înainte și după.

### F — Bastionul și fațada palatului (frac 0.588–0.699)

Din decupaj (`bara_poi_F`, `bara_poi_PALAT`): **bastion rotund de gresie
roșie** pe stâncă, **tunuri pe metereze cu fum alb**, **tiroliana** cu silueta
pe cablu, **ulii negri SUB bastion**, lumina joasă aurie; palatul cu
**jharokha**, chhatri și cupole.

Brief: fațada Moti Mahal la 10–18 m, detaliul pe **primele două etaje**
(înălțimea camerei); bastionul-limbă cu orașul sub tine; tunuri de salut
(ciclu 31 s, 5 salve la 0,8 s, fum și flacără **spre oraș**, fără forță),
tiroliana (~23 s), ulii în buclă, artificiile la `dusk ≥ 0,8` **sub tine,
peste case**. **Fără parapet pe vârful bastionului.**

Geometria reală (§Premise 8, 9, 10): orașul se vede de pe **brațul de intrare**
(0.622–0.666), nu de pe cel de ieșire; fântâna e prea departe; vârful n-are
cădere lângă drum. Pe dreapta spre est a fațadei (0.588–0.622) stânca urcă pe
**dreapta** (+11…+13 m la 30–40 m), deci fațada palatului stă pe dreapta, pe
stâncă, iar orașul e dincolo de ea (nu se vede de acolo, 0 %). Tunurile și
vederea spre oraș se pun pe brațul de intrare, unde orașul e în față.
Nu se atinge: traseul, relieful stâncii (`TerrainPeak`); dacă se vrea căderea
de la vârf, e cerere de relief.
Piese: `palace_facade_a` (40 m), `palace_facade_b` (44 m), `fort_bastion`,
`fort_wall_segment`, `rampart_cannon` (kitul zice `none`, brief-ul `hull` pe
metereze, în afara benzii — se alege `hull` dacă sunt la îndemâna mașinii),
`zipline_rider` (`PathMover`, `stick_to_ground=false`, originea în scripete;
cablul îl trage codul), `black_kite_bird` (`PathMover` în cerc, acțiunea
`Fly`), `peacock`. Tunurile, tiroliana și artificiile **nu există în cod**:
F le construiește, cu flagurile `--salute-at`, `--zip-at`, `--fireworks-at`.

Capcana: memoria `perete-paralel-nu-se-vede` / `masoara-inainte-nu-langa` —
se pune ce trebuie văzut **în față** pe brațul de intrare, nu lateral.
Memoria `inaltimea-obiectelor-si-camera`: creasta palatului e tăiată de cadru,
nu se detaliază. Artificiile: memoria `particule-muchia-nu-numarul` (panza
billboard + textură cu cădere continuă), plafon 3 simultane (overdraw).
Memoria `corp-cinematic-aparut-in-masina`: curba tirolienei pornește departe
de mașini. Memoria `caster-departat-fura-umbra`: fumul și uliii fără umbră.

### G — Coborârea pe stâncă (frac 0.699–0.861)

Din decupaj: drum pe marginea **stâncii de riolit roz-brun în blocuri mari
fațetate**, arbuști și copaci de deșert, candele pe margine.

Brief: stâncă goală, euforbii și tufe uscate, două S-uri largi, 10 % în jos;
**bolovani `hull` pe marginea dreaptă** (coliziune reală). Singurul loc fără
oraș.

Geometria reală (§Premise 11): orașul e pe dreapta (în afara cadrului), lacul
pe stânga spre final. Terenul e plat lateral pe ±40 m pe 0.72–0.80: „stânca
goală" e clasa de suprafață (`rhyolite`) + bolovani, nu relief.
Nu se atinge: traseul. Piese: `rhyolite_boulder_a/b/c` (`hull`), `rock_slab`,
`euphorbia`, `khejri_tree`, reuse `cappadocia/plants/shrub_dry.glb`.

Capcana: bolovanii `hull` pe margine — memoria `amprenta-hull-nu-raza-nominala`
(gabaritul hull-ului e mai mare decât raza nominală) și ProbeLaneClear;
memoria `garzile-se-uitau-doar-la-carosabil`. Dacă criticul cere de două ori
„stânca în relief", e teren: **(c)**.

### G2 — Devkund și cenotaful (frac 0.861–0.910)

Din decupaj (`bara_poi_G2`, `bara_poi_CENOTAF`): **apă verde-închis** cu
candele plutitoare, **cenotaful de marmură albă** (cupolă centrală, patru
chhatri, soclu în trepte) pe stâncă roz, malul de riolit în blocuri.

Brief: kicker de stâncă peste brațul lacului (16 m de apă), cenotaful întreg
de la ~110 m, aterizare pe dala de pe mal, repunere în apă; noaptea candele la
baza cenotafului, reflexia în lac.

Geometria reală (§Premise 11, 12): lacul e pe **stânga**; **nu există
kicker**. Ce poate G2 livra fără kicker: lacul (apa, malul, candelele),
cenotaful pe stânga, la distanța și azimutul la care intră întreg în cadru
(14 m pe soclu de +6 → vârf la +20: întreg de la ~110 m, §2.0). Kickerul,
`RespawnZone` și aterizarea sunt fundație/traseu; dacă nu există la pornirea
valului, **G2 nu intră în val**.
Piese: `jaswant_thada` (`mesh`), `floating_diya`, `rhyolite_boulder_*`,
`rock_slab` (dala de aterizare).

Capcana: saltul (când va exista) e reglat pe ProbeRace; orice piesă pe
traiectoria de zbor sau pe aterizare schimbă distribuția: `--slice=0.84,0.92`
obligatoriu. Panta de 14,2 % la 0.88 e peste ținta brief-ului. Apa: memoriile
de apă de la C.

### H — Dreapta de întoarcere (frac 0.906–1.000)

Din decupaj: asfalt lat, **felinare pe stâlpi și sfori de becuri calde**, case
albastre cu parterul luminat, tuk-tuk, zidul de stâncă cu candele pe marginea
din față.

Brief: cea mai lungă dreaptă (turbo), **turnul cu ceas în capăt, pe ax**
(pe pista reală H merge spre vest și turnul e lângă grilă: în cadru pe
azimut 100 %), sfori de becuri, balcoane cu candele, tuk-tuk-urile reintră de
pe o stradă laterală; în turul 3 artificiile în spatele turnului.

Nu se atinge: traficul și intrarea lui laterală, banda de 14 m. Turnul e al
lui A (se așază o dată); H îl judecă. Piese: case albastre, `haveli_facade`,
sforile de becuri, `diya`, `marigold_garland`, felinare (reuse sau cod).

Capcana: nimic cu coliziune pe dreapta de turbo (ProbeLaneClear); sforile de
becuri sub +9 m la 50 m (altfel ies din cadru). Memoria `efecte-de-fundal-cote-legate`
dacă intră orizontul (`FarCity_A` cu ferestre) în capăt.

## Bucla oarbă

1. Constructorul (Sonnet, memoria `coordonator-fable-constructori-sonnet`)
   lucrează în `D:/GameDev/wt-jod-poi-<x>` pe `jodhpur/poi-<x>`, plecat din
   ramura fundației după merge; `--import` la creare; comite după fiecare pas
   care trece o gardă; **prima rundă începe cu `git status` / `git diff`**;
   **niciodată `git stash`** (memoria `git-stash-partajat-intre-sesiuni`).
2. Face captura din mașină la fracțiile din tabel, cu `--gamecam --dusk=0` și
   flagurile de hazard (le scrie în prima rundă dacă lipsesc).
3. Criticul, **context proaspăt**, primește planșa din
   `python tools/bar/blind_pair.py "<captura>" "docs/track_briefs/img/bar_jodhpur/bara_poi_<X>.png" "<out>.png" --seed <N>`.
   **O singură planșă per rundă.**
4. Criticul **deschide** planșa, alege A sau B, **apoi** citește cheia și
   raportează cinstit dacă a nimerit.
5. Numește **o singură** diferență care contează, reparabilă în decorul
   POI-ului.
6. Ieșirea din buclă: (a)/(b)/(c). La (a) sau (b): gărzile pe scena integrată,
   apoi merge. La (c): oprire și decizie.

Seed-ul planșei și numele fișierului se schimbă la fiecare rundă (memoria
`critic-orb-coliziune-de-plansa`).

## Valurile (câte 3 POI-uri, niciodată 8)

Memoria `valuri-de-trei-nu-opt-agenti`. Regula de compunere: **două POI-uri
care se calcă pe decor nu merg în același val** — un worktree nu vede ce pune
celălalt, iar la integrare două seturi de piese pe același teren se bat
(ziduri dublate, case suprapuse, coliziuni pe bandă).

**Propunerea coordonatorului: val 1 = C, E, F. O contrazic pentru perechea
E–F.** E și F stau pe aceeași stâncă (`TerrainPeak` r 100 la (135, −275)):
acul porților de la 0.541 e la (88, −257), vârful bastionului la (125, −221),
brațul de intrare al lui F (165, −296) → (125, −221) trece la 40–70 m de
zigzagul lui E. **Zidul de 14 m „pe dreapta" al porților e zidul de sprijin al
platoului lui F**, iar `fort_wall_segment` / `fort_bastion` sunt cerute de
amândouă. În același val, cei doi constructori zidesc același perete din
două părți.

**Propunerea mea:**

| val | POI-uri | de ce |
|---|---|---|
| **1** | **C, E, H** | C și E sunt identitatea (plonjonul, dopul) și riscul de gărzi cel mai mare (ProbeBuried, `[blocaj]` pe 16 seed-uri) — se află devreme. H e departe de amândouă (≥ 100 m de marginea pâlniei fântânii, pe altă latură decât E) și aduce turnul ca reper. Nicio pereche nu împarte teren |
| **2** | **F, D (+D′), A** | F pleacă după ce E a pus zidurile de pe fața stâncii. D e la ≥ 150 m de F; A e la capătul opus al buclei. D ține și ulicioara (ProbeJodVaca, cea mai fragilă gardă) |
| **3** | **B, G (+G2)** + reluarea celui mai slab | B și G sunt pe laturi opuse. **G2 intră doar dacă există kickerul**; altfel G ia doar lacul și cenotaful |

Perechi adiacente care NU ajung în același val: B–C și C–D (marginea de vest a
pâlniei fântânii, la x ≈ −219, e atinsă de B la 0.129 și de D la 0.267, la
46 m una de alta), D–E (Jai Pol, 0.474), E–F (stânca), F–G (ieșirea din fort,
0.699), G–G2, H–A (grila).

**Dacă se ține totuși val 1 = C, E, F** (identitate întâi), atunci granița se
scrie în promptul ambilor constructori, ca cifră: **E deține tot ce e la
x < 100 și sub +38 m (zidurile de pe fața de vest a stâncii, porțile); F
deține tot ce e la x ≥ 100 sau peste +38 m (fațada, bastionul, meterezele)**,
iar `fort_wall_segment`-urile de pe muchia platoului sunt ale lui F. Fără
graniță scrisă, perechea se calcă garantat.

Integrarea într-un worktree dedicat (memoria `orchestrare-agenti-worktree-frate`);
gărzile **doar pe scena integrată**; tenta de clasă se decide la integrare
(memoria `tenta-de-clasa-se-decide-la-integrare`); după fiecare merge,
verifică ramura înainte de commit (memoria `merge-ul-lasa-tree-ul-pe-main`) și
că reparațiile de pe ramuri chiar au ajuns (memoria
`reparat-pe-ramura-nu-inseamna-livrat`).
