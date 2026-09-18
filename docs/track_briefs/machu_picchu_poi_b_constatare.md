# POI B (Drumul Incas) — ce s-a construit si ce a ramas deschis

> Constatare de constructor, 18 sep 2026, branch `feat/mp-poi-b`, 4 commit-uri.
> Zona plecase de la **0 noduri**; are acum **331**.

## 1. Premisa din prompt era gresita, si masuratoarea o arata

Prompt-ul spunea, citand `SvMpBuza`: „pe dreapta prima cadere de 3 m e la
17,5 m dincolo de asfalt". Survey-ul pe intervalul real spune altceva. Cotele
fata de drum, la +2 / +4 / +8 m lateral **de muchie**:

```
0.075   -0.9   -1.5   -2.9      <- aici chiar e platou
0.080   -5.2   -6.8  -13.6
0.085  -15.1  -21.4  -34.4
0.100  -26.1  -40.3  -59.3
0.140  -40.2  -55.8  -65.6
0.190  -38.7  -51.9  -64.1
```

Unghiul sub orizontala **din ochiul camerei** (10 m peste drum), la 4/8/15 m:

```
0.040    3.7    1.7    0.7      <- platou
0.080   59.7   59.6   47.6
0.100   84.3   82.3   75.9
0.190   85.6   82.9   78.8
```

Deci de la frac 0.080 in sus dreapta e **prapastie verticala**, nu umar.
Cifra de 17,5 m era media pe tot intervalul 0.04-0.20, diluata de prima
treime, care chiar e platou. **Capcana 3 din prompt** („peretii verticali apar
la 28-35 grade, e o limita de rezolutie a grilei") **nu se aplica aici**:
unghiul real e 59-86 grade, cu mult peste `scarp_slope_deg` 28, deci tenta de
stanca se aplica si se vede.

Lectia de proces: `SvMpBuza` da o cifra pe POI, dar POI-ul B are doua regimuri
(platou pana la 0.078, faleza dupa). O medie pe un interval neomogen minte.

## 2. Ce a lipsit de fapt: PIATRA, nu vegetatie

Contractul listeaza piesele incepand cu bromelii, ferigi si orhidee. Masurat
pe pixeli, deficitul e invers. Clasificare pe familii (verde = iarba, luminos
si nesaturat = cer, restul = mineral):

| sursa | mineral | iarba |
|---|---:|---:|
| **BARA** | **84,9 %** | **6,1 %** |
| 0.14 zona goala | 32,5 % | 27,6 % |
| 0.14 dupa runda 3 | **40,8 %** | **19,8 %** |
| 0.08 zona goala | 44,6 % | 41,4 % |
| 0.08 dupa runda 3 | 45,4 % | 40,6 % |

## 3. Trei greseli facute si reparate, toate utile altui POI

**(a) `moss_boulder_*` marit NU citeste a stanca.** Runda 1 a pus ~200 de
bolovani la 4-13 m pe buza si a cumparat **0,1 puncte** de roca, adaugand
iarba. Pe captura se vedeau ca niste carapace verzi — umbrele tropicale.
Cauza era deja in inventar (§2, tabelul ACCENT_SPLIT) si n-am citit-o la timp:
pe `Moss_Boulder_C` muschiul (slot 12) ocupa **68 % din inaltime, partea de
sus**. Fractia e **invarianta la scara** — marind piesa maresti capacul.
Ce citeste a piatra: `Inca_Wall_A` 93,7 % piatra, `Inca_Wall_C` 91,5 %,
`Trail_Marker` piatra curata.

**(b) Orice marime trasa la zar PER PIESA da zimti.** Inaltimea era
`randf_range(0.9, 1.7)` independent per piesa: doi vecini la 2,8 m ieseau la
0,9 si 1,7 — treapta de 0,8 m intre blocuri lipite. Dupa ce am netezit
inaltimea, sirul tot citea „scara de cutii", fiindca **retragerea** fata de
muchie avea aceeasi problema. Reparatia: amandoua din functii netede de
pozitie (doua sinusoide, lungime de unda 25-40 m).

**(c) Clasificatorul meu masura altceva decat vedeam.** Prima versiune numara
drept „roca" doar pixelii **cenusii** (satur < 0,14). Piatra lui `inca_wall` e
tan **calda**, deci cadea in galeata „drum": vedeam zidarie pe captura si
cifra spunea 0,5 %. Reclasificat pe familii. Memoria
`procent-de-culoare-nu-e-dovada`, in ambele sensuri.

## 4. Ce a ramas deschis — nu e mascat cu decor

- **Nu exista piesa de TUNEL in kit.** Contractul cere „gura de tunel cu arc
  de piatra"; cele 39 de GLB-uri n-au nici arc, nici gura. N-am fabricat-o din
  `inca_wall_*` (un arc din trei lespezi citeste a poarta prabusita, si POI C
  are deja poarta). **Cere o piesa noua**, sau contractul se schimba.
- **Sirul de zidarie are aspect de trepte pe rampa.** Piesele sunt orizontale,
  drumul urca cu 11,4 %. O piesa dreapta pe o rampa da o treapta. Ar cere
  inclinarea piesei pe panta longitudinala in generator, nu mai multe piese.
- **La frac 0.18 nu se vede nimic din decorul meu, si e corect.** E un ac
  strans: camera priveste pe INTERIORUL virajului, iar buza (cu 19 piese acolo,
  verificat pe coordonate) e in spate si sub ea. Cifra identica la bit fata de
  zona goala nu inseamna ca lipseste ceva, inseamna ca nu e in cadru.
  Daca se vrea materie in cadrul de la 0.18, ea trebuie pusa pe **interiorul**
  acului, si aia e pajiste reala (platou la -0,3 m), nu faleza.
- **Stanga e platou pe aproape tot intervalul** (-0,3 m pana la 40 m lateral),
  cu exceptia flancului 0.105-0.152. N-am pus stanca pe platou: ar fi fost
  „o piatra pe pajiste", greseala din constatarea valului 2.

## 5. Coama de la frac 0.186 — masurata A/B, neatinsa

Contractul cere ProbeRace `--seed=2` de patru ori, inainte si dupa.

```
la mine (331 piese)   0 / 0 / 0 / 0 repuneri   offroad 2,3 % pe toate patru
pe MAIN, azi          0 / 0 / 0 / 0 repuneri   offroad 0,1 / 2,3 / 0,1 / 2,3 %
```

Cifra **0/1/1/2** din nota de predare **nu se reproduce azi nici pe main**.
Diferenta nu vine din zona mea. N-am atins traseul si n-am incercat sa repar
coama cu decor.

## 6. Garzile, pe scena integrata

```
probe_decor --track=15    19 materiale (neschimbat), 9649 prop, 1 185 548 tri
ProbeBuried --track=8     0 ingropate, 0 tavane
ProbeLaneClear --track=8  18 blocate, linia de baza 20 (neschimbat fata de main)
ProbeRace seed 1 si 3     0 repuneri, 0,0 % offroad
```

**Zero materiale noi.** Toata zidaria intra pe clasa `inca_stone` existenta.
Coliziunea e `none` pe TOT decorul: contractul cere explicit „pe dreapta fara
parapet, defileul", iar un zid cu corp la 0,5 m de muchie, pe o banda de 6 m,
ar fi exact parapetul interzis.

## 7. Criteriul de terminare NU e atins

POI-ul n-a fost dus la critic orb. Mineralul la 0.14 e 40,8 % fata de 84,9 %
in bara — jumatate. Urmatorul pas util e o runda de critic orb pe captura
`B_r4_f0.14.png`, si daca verdictul cere iar „stanca", intrebarea e daca mai
poate da zona ceva sau e o limita de kit (vezi §4).
