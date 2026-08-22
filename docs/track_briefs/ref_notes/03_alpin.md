# Ref — pistă 3: alpin

Tur: **1:17.8**. Cea mai lungă și cea pe care s-a greșit cel mai mult.

## Structura turului

1. **0–5 s — start.** Portic cu banner în carouri, pe zăpadă bătătorită.
   Imediat un **pilon de telescaun** din grinzi metalice negre lângă drum.
2. **5–15 s — serpentine.** Ace de păr strânse pe pantă, cu maluri de zăpadă
   de o parte. Aici jucătorul a ieșit de pe traseu și a primit „WRONG WAY".
3. **15–35 s — coborârea prin defileu.** Pereți de stâncă maro-cenușiu cu
   zăpadă pe muchii, drum alb larg. Ninge — fulgi vizibili peste tot ecranul.
4. **35–55 s — porțiunea rapidă.** Aici s-au citit **242 și 247** cu turbo.
   Drum lat, drept, ușor în pantă. Un tunel scurt la ~30 s.
5. **50–53 s — bolovanii de gheață.** Vezi mai jos.
6. **55–70 s — satul.** Chalet-uri de lemn cu acoperișuri albastre și galbene,
   clădiri cu ferestre, brazi, ornamente. Drumul trece printre ele.
7. **70–78 s — retur.** Încă un pilon de telescaun, iese la portic.

## Hazardurile (confirmate de dezvoltator, nu din cadre)

Cadrele au prins doar consecinta; mecanicile de mai jos vin de la volan.

- **Bolovani care cad** — dinamici. Iti strica masina **si iti inverseaza
  comenzile stanga/dreapta.** Asta e mecanica cea mai interesanta din tot
  materialul si nu putea fi citita din cadre: pedeapsa nu e pierderea de
  viteza, e pierderea *interfetei*. Continui sa conduci, dar creierul tau e
  brusc gresit. Pe o pista alba, cu viraje stranse, cateva secunde de comenzi
  inversate sunt mai scumpe decat o oprire.
- **Avalansa** — dinamica. Iti muta masina din traseu si iti da restart.
- **Tornada** — te ridica in aer si te invarte. Practic identica cu
  `typhoon_hazard` la noi.

Momentul prins la 00:51 (ecranul plin de blocuri palide, vitezometru inghetat
la 048, alta masina circuland printre ele) e deci **avalansa**, nu un camp
de bolovani statici.

**Ce ne priveste:** avem deja echivalentul tornadei. Nu avem nimic din clasa
bolovanilor — un hazard care nu-ti ia viteza, ci iti saboteaza controlul.
E ieftin de implementat (un flag pe controller care schimba semnul virajului,
plus un indicator vizual clar ca sa nu para bug) si e o pedeapsa complet noua
pe axa noastra de dificultate.

## Scurtatura cu rampa de lemn

Pe pista de gheata se poate intra pe o **rampa de lemn care te arunca peste
pista** — sari peste o portiune in loc s-o parcurgi.

Ce o face sa functioneze nu e rampa, e **layout-ul**: pista trece pe langa
sine, cu separare pe verticala. Fara asta nu ai peste ce sa sari. Vezi
[world_design.md](world_design.md) — are consecinte la noi.

## Ce definește pista

Nu un obstacol, ci **suprafața**. Zăpada are două regimuri vizibile: bătătorită
(gri-albăstruie, cu urme adânci de cauciuc, ~140) și afânată (albă curată,
~40–90, cu pană de zăpadă aruncată în spatele mașinii). Linia bună e cea care
stă pe urmele existente, iar urmele sunt desenate în textură.

**Ce ne privește:** avem deja `RoadWear`. Aici urmele nu sunt cosmetice —
sunt informația de traseu. Pe o pistă albă fără margini, urmele *sunt*
semnalizarea. E cea mai bună utilizare a foii de uzură pe care am văzut-o.

Al doilea lucru: **infrastructura de schi ca reper de navigație.** Piloni de
telescaun la intervale mari, vizibili de departe, deasupra siluetei. Pe o
pistă unde totul e alb, ei sunt singurele puncte de orientare. Rezolvă
problema „nu știu unde sunt" fără nicio hartă.

## Palete și materiale

Alb-albăstrui de zăpadă bătătorită · alb pur de zăpadă afânată · maro-cenușiu
de stâncă udă · lemn închis de chalet · albastru și galben de acoperiș ·
negru de grinzi metalice.
