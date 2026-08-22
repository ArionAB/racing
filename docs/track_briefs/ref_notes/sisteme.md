# Note de referință — sisteme (Ignition, 1997)

Extrase din 5 capturi video de gameplay (21 aug 2026), prin eșantionare de
cadre la 0.5 fps + rafale la 3 fps pe momentele-cheie. **Sunt note de analiză,
nu geometrie.** Nimic de aici nu se copiază ca asset sau traseu; ce ne
interesează sunt numerele și deciziile de design din spate.

Avertisment de citire: totul e măsurat din cadre statice. Vitezele și timpii
sunt citite direct de pe HUD, deci exacte. Tot ce ține de senzație (câtă
tracțiune, cât airtime, cât de brusc virează) e dedus, nu măsurat.

## 1. Viteze și turbo

| mărime | valoare citită |
|---|---|
| viteză de croazieră, asfalt/pământ bătut | 130–150 |
| viteză de croazieră, nisip adânc / zăpadă afânată | 30–100 |
| **vârf cu turbo** | **204, 213, 227, 242, 247, 248** |
| ieșire din viraj strâns | 60–90 |

**Turbo-ul dă ~+65% peste viteza de croazieră** (140 → ~230). Nu e un boost
cosmetic de 10%; e o schimbare de regim care se vede și se aude. Bara verticală
din dreapta se golește vizibil în timpul arderii și se reîncarcă din mers.
Pictograma fulger de deasupra barei se aprinde roșu când e plină.

Asta validează modelul nostru de turbo (M2.5) și dă o țintă numerică:
**dacă turbo-ul nostru nu mută viteza cu ~60%, e prea timid.**

## 2. Durata turului

| pistă | tur măsurat |
|---|---|
| V1 fermă/carieră | 1:23 (dar ~14 s pierdute la tren) → ~1:09 curat |
| V2 desert/oraș | 1:06.9 |
| V3 alpin | 1:17.8 |
| V4 coastă | 1:09.5 |
| V5 junglă/ruine | 1:16.1 |

**Tur = 65–80 secunde.** Trei tururi = ~3.5 minute de cursă. Exact fereastra
din CLAUDE.md („curse de 2-3 minute"). Confirmă că pistele noastre nu trebuie
să fie mai lungi de atât.

## 3. Costul greșelilor (ăsta e numărul important)

Măsurat cadru cu cadru la 3 fps:

- **Distrugerea mașinii** (impact tare, cădere în apă, ieșire în afara lumii):
  explozie galbenă → **~1.5–2.0 s de ecran fără mașină** → reapariție pe
  traseu cu efect de scântei albastre, **la 0 km/h**. Costul real nu e
  blackout-ul, e repornirea din stând. Pe coastă a costat 2 poziții (3 → 5).
- **Trenul la trecerea de cale ferată: ~12–14 s.** Blocaj total, mașina stă
  la 000 km/h. Pe un tur de 70 s asta e **20% din tur**. E cel mai scump
  hazard din tot materialul, cu un ordin de mărime.
- **Cascada peste drum** (V5): viteza intră 143 și iese 137–146.
  **Cost zero.** E pur teatru — spray, sunet, vizibilitate.
- **Ieșirea în nisip adânc / zăpadă afânată:** 140 → 30–70. Se recuperează
  singură, fără eveniment.

Lectia de design: hazardurile lor nu sunt pe o singura scara. Sunt
**patru clase distincte**, iar noi avem doar doua din ele:

| clasa | exemplu | ce iti ia | avem? |
|---|---|---|---|
| teatru | cascada peste drum | nimic | nu |
| frecare | nisip adanc, zapada afanata | viteza, continuu | **da** (iarba lenta) |
| oprire | trenul la trecere | timp, brutal | nu |
| sabotaj de control | bolovani care cad | **comenzile inversate** | nu |
| aruncare | tornada, avalansa | pozitia + restart | **da** (typhoon) |

Clasa care merita cel mai mult atentie e **sabotajul de control**: bolovanii
nu iti iau viteza, iti inverseaza stanga cu dreapta. Continui sa conduci la
viteza intreaga, dar cu interfata gresita. E singura pedeapsa din lista care
nu se poate absorbi prin skill de condus — doar prin adaptare, in timp real.
Si e cel mai ieftin lucru de implementat din tot tabelul.

## 4. Cameră și lizibilitate

Camera e **mult mai sus și mai în spate decât o chase cam modernă** — unghi
de coborâre mare, aproape izometric pe porțiunile plate. Mașina ocupă puțin
din ecran; se vede foarte mult din traseul care urmează.

Asta nu e nostalgie de 1997, e o decizie: pistele lor au viraje oarbe și
hazarduri care cer decizie devreme (unde ard turbo-ul, pe ce bandă intru în
trecerea de cale ferată). Camera plătește pentru asta. **Merită comparat cu
frustumul lui `ChaseCamera` la noi** — vezi nota de memorie despre înălțimea
obiectelor.

## 5. Semnalizarea (cum îți spun ce urmează)

Panouri mari, în partea de sus a ecranului, nu în lume:

- **galben cu săgeată** — viraj la stânga/dreapta care urmează
- **roșu cu săgeată** — viraj strâns / ac de păr
- **verde cu „Y"** — bifurcație: traseul se desparte (ruta alternativă)
- **„WRONG WAY"** roșu, pulsant — ai luat-o invers

Plus, în lume: jaloane cu chevroane roșii/albe pe exteriorul virajelor,
panouri galben-roșii pe stâlp.

**Concluzia care ne privește:** ei rezolvă lizibilitatea cu HUD, nu cu
geometrie. Un panou în colțul de sus e gratis pe mobil și rezolvă problema
virajului oarb fără să lățească pista sau să coboare camera.

## 6. HUD (structură, nu stil)

- stânga sus: TOTAL TIME + LAP TIME (și al treilea rând, turul curent, la
  trecerea liniei)
- stânga jos: **POS** cu o cifră uriașă — cel mai mare element din ecran
  după mașină
- dreapta: bară verticală de turbo + pictogramă fulger; vitezometru analogic
  cu afișaj digital suprapus; indicator de treaptă R / HI / LO

Poziția e ce citește jucătorul cel mai des, și e tratată ca atare. La noi
POS-ul e discret — merită reevaluat.

## 7. Grila și startul

8 mașini, două coloane de câte 4, pe o dreaptă. Semafor cu 3 lumini pe portic
(roșu → roșu+galben → verde). Înainte de start, o cameră scurtă cu vinietă
circulară peste grilă.

## 8. Suprafețe văzute

asfalt cu marcaje · pământ bătut · nisip adânc · zăpadă bătătorită · zăpadă
afânată · noroi · piatră (trepte de templu) · lemn (pod suspendat) · apă
puțin adâncă

Toate cu urme de cauciuc persistente desenate în textura solului — vezi
`RoadWear` la noi, aceeași idee.
