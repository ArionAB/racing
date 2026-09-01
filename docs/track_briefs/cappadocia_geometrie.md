# Cappadocia — geometrie verificata inainte de constructie (masurata, nu presupusa)

## Elicea din stanca goala (POI G) — cifra care decide gimmickul
- raza 28 m, 2 ture, urcare 12 -> 50 m (38 m)
- lungimea REALA de drum = arcul = 2*pi*28*2 = **351.9 m** (nu coarda de frac)
- panta medie = 38 / 351.9 = **10.8%**  -> sub pragul de 13% al briefului. OK.
- pas pe tura = 19.0 m -> separare verticala intre ture 19 m
  - regula de design a briefului: >= 12 m  OK
  - pragul ProbeLayout STACK_MIN_DY = 14.0  OK
- marja: raza poate cobori pana la **23.3 m** inainte sa atinga 13%.

## CAPCANA de traseu (gasita inainte sa se deseneze ceva)
Briefull aloca elicei frac 0.84–0.98 = 0.14 dintr-un tur de 2000 m = 280 m.
Dar arcul cere 352 m. Daca elicea primeste 280 m, panta iese **13.6% — PESTE prag**.
=> elicea trebuie sa primeasca arcul ei real (~0.17 dintr-un tur de ~2072 m),
   iar celelalte fractiuni se re-deriva dupa aceea.

## Profil pe restul traseului (toate confortabile)
A->B 0%, B->C -1.8%, C cornisa -3.6%, D canion **-7.5%** (cea mai abrupta coborare),
E vie -0.8%, F subteran -0.3%. Nimic peste 8% in afara elicei.

## Corectie la brief §2
Briefull spune ca o elice intr-un horn de 24 m diametru ar da 42%. Masurat: la 2 ture
da **25%**. (42% ar fi cu o singura tura.) Decizia NU se schimba — 25% e tot
inutilizabil, deci stanca de 70 m ramane justificata.

## Constrangeri descoperite de sonde (nu erau in brief) — obligatorii la constructie

### C — cornisa: baloanele au nevoie de POLITA, nu de fundul vaii
Masurat pe geometria reala (ProbeBalloon, verdictele vi + viii, LASATE ROSII
intentionat pana se rezolva terenul):
- o rapa `custom_ravines` are peretele IN PANTA, nu vertical: terenul tine cota
  soselei 7 m, coboara 7 m, si abia la ~13-14 m ajunge la podea;
- un balon ancorat pe fundul vaii urca DREPT si intra in peretele inclinat:
  masurat pe colturile cosului de 4.8 m, se infunda la y=-29 dupa **1 m** din
  cei 30 de cursa (pe ax singur parea 9 m — colturile sunt mai rele);
- ajunge, in cel mai bun caz, la **9.6 m** de marginea asfaltului.
=> Tarusul trebuie pe o **polita in peretele falezei, la <= 9.4 m de axul benzii**,
   cu coloana de 30 m libera, SAU faleza de sub cornisa se taie **verticala** acolo.
   ProbeBalloon iese cu 1 pana atunci — e o constrangere, nu un bug.

### F — subteran: `CameraZone.ceiling` se pune PE SALA
Implicitul e 15.0 (sala-test), dar sălile briefului sunt 16 m si 18 m. Masurat,
cu implicitul lasat pe loc tavanul de 16 m intra la 25.1 m si cel de 18 m la
30.3 m — amandoua peste pragul de 25 m, chiar pe sliderele implicite.
=> pe fiecare CameraZone, `ceiling` = cota reala a salii. Solverul tinteste
   pragul cu marja zero, deci nu-i mai lasa si o eroare de cota.

### G — stanca goala: golul se DECLARA
`custom_overpass_ranges` scoate elicea din media terenului (corect), dar nu spune
nimic despre ce e SUB ea — iar campul se umple din ALT drum, chiar din cel de
iesire de pe platou (y~48) care traverseaza gura stancii. Rezultat masurat:
99/492 puncte ingropate, cel mai adanc +37.4 m.
=> nod `TerrainHollow` (perechea pe minus a lui TerrainPeak): cilindru cu podea,
   perete care se stinge neted pe `wall_m` ca exteriorul masivului sa ramana intreg.
