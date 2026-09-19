# POI C (Poarta Soarelui si creasta) — nota de predare, runda 3

## Ce a cerut criticul orb si ce s-a facut

| Reclamatie | Stare | Cum |
|---|---|---|
| "Nu exista niciun element de roca intre carosabil si panta: iarba atinge direct asfaltul" | **reparat** | `_cornisa_umar()` — 16-20 `inca_wall_b` aliniate pe tangenta, infipte 0,55 m in umar, pe 0,208-0,238 (partea plata, masurata per index) |
| "cu cadere vizibila sub ea si norul pe sub buza" | **partial** | `_fata_de_stanca()` — 36 de piese de zidarie la 5-11 m sub sosea. Se vad ca piatra, dar citesc a blocuri razlete, nu a perete. Norul nu s-a obtinut (vezi mai jos) |
| "picioarele portii se termina in aer" | **partial** | `_picior_contrafort()` — 6 piese sub piciorul +1, care atarna peste 35,3 m de aer. Coloana incepe insa sub cota soselei, deci muchia vizibila din masina la 0,21-0,22 tot se termina in aer |
| "condorul e o masa gri fara aripile desfacute" | **partial, cu refuz motivat** | anvergura 6,0 -> 8,5 m. Aripile DESFACUTE nu se pot da: piesa e statica, fara AnimationPlayer, "aripi ca insule de mesh separate" (masuratori §"none"). Nu exista pozitie de deschis |

## Ce a gasit runda in plus, si nu ceruse nimeni

**Casa paznicului lipsea din scena de trei runde.** Brief-ul o cere la ~0,33.
Fragmentul avea 0 noduri `casaPaznic` si 0 `ruinaPaznic`, iar comentariul din
cod sustinea din runda 2 ca e rezolvata. Lantul era cinstit peste tot si tocmai
de aceea mut: `_best_shelf` raporta "-23,52 m", `_place` refuza prin
`DROP_REJECT`, refuzul se aduna intr-un `_skipped` necitit.

`tools/probe_mp_c_umar.gd` a aratat ca umarul nu exista pe 0,29-0,355 pe NICIO
parte (8-35 m sub sosea la 3 m dincolo de muchie). Primul teren pe care se poate
zidi e 0,360-0,365. Casa e acum la 0,3620, pe sol la -0,31 m.

Generatorul are de acum o **verificare de contract**: daca o piesa ceruta de
brief nu ajunge in `_out`, o striga ("PIESA DE CONTRACT LIPSA").

## Ce NU s-a obtinut, si de ce (pentru runda urmatoare)

Bara cere o creasta ingusta cu **nor alb de ambele parti** si silueta pe cer.
Capturile arata creasta corecta ca geometrie, dar **totul e aceeasi iarba
verde-palida**: fata rapei, versantul de dincolo si fundalul au aceeasi culoare,
deci ochiul le uneste intr-un deal. Asta NU se mai poate repara din decorul
POI-ului, si cele doua motive sunt masurate:

1. **Ceata/norul nu e al zonei.** Bara isi ia separarea din norul care umple
   valea. In scena, singurul nor e `NorulDefileului`, un `cloud_rise_hazard`
   legat de alt POI. Ceata de scena vine din tema. Ambele sunt in afara lui
   `ZoneC_PoartaSoarelui`.
2. **Versantul de dincolo e la 80 m si e teren, nu decor.** `probe_mp_c_unghi.gd`:
   la 0,24 solul cade cu 56 grade (-1) si 77 (+1) vazut din ochi — geometria E
   creasta. Verdele care umple cadrul e malul celalalt, care nu e al meu.

Deci diferenta ramasa fata de bara e o decizie de **tema/ceata**, nu de asezare
de piese. Un al treilea POI care ar mai adauga piatra pe umar ar ingrosa un
parapet, nu ar cumpara muchia.

## Cifre (comanda care le-a produs e in mesajele de commit)

- `probe_decor --track=15`: **19 materiale**, neschimbat fata de plecare.
  **Zero materiale noi cerute**: tot ce s-a adaugat refoloseste `inca_stone`.
- `ProbeBuried --track=8`: OK
- `ProbeLaneClear --track=8`: 18, baza 20 (neschimbat)
- `ProbeRace --track=8`: seed 1 -> 0, seed 3 -> 0, seed 2 -> 1.
  Seed 2 nu e regresie: pe **main neatins** acelasi seed da 2 / 0 / 3.
- 187 de piese asezate, 70 refuzate.
