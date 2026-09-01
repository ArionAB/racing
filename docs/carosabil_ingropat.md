# Carosabilul îngropat — de ce au trecut toate sondele

Pe Cappadocia, elicea care urcă pe interiorul stâncii goale — **chiar gimmick-ul
pistei** — a stat îngropată sub 38 m de tuf. Măsurat: 196 din 984 de puncte
coapte sub teren, cel mai adânc `+38.40 m`. Mașina ar fi intrat într-un perete
plin exact acolo unde pista își are momentul memorabil.

A trecut prin **toate** sondele existente. Nu fiindcă vreuna era stricată — ci
fiindcă niciuna nu punea întrebarea.

## 1. De ce n-a prins-o nimic

| sondă | ce măsoară | de ce a trecut |
|---|---|---|
| `probe_layout` | lungime, rază, pantă, separare — **din curbă** | Nu știe că există teren. Curba e impecabilă și îngropată la fel de impecabil. |
| `probe_capp_peaks` | că masivele declarate **urcă** | Verifică *dacă* se ridică, nu *pe unde*. Un masiv care urcă **prin** drum trece la fel de bine ca unul care urcă pe lângă el. |
| `probe_helix` | panta medie, lungimea de arc, numărul de ture | Panta rămâne 9.52 % și când spirala e săpată în piatră plină. Geometria drumului nu se schimbă cu nimic dacă e umplut. |
| `probe_capp_mesh` | teren **sub** asfalt (raycast în jos) | Pornea *de sub* asfalt și trăgea în jos. Întreba „am pe ce călca?", nu „am ce mă strivește?". Pe pista **stricată** raporta `OK`. |
| `probe_decor`, `probe_overpass` | materiale/triunghiuri, respectiv etajele pasajului | Alte axe. Pasajul chiar funcționa — masca de pasaj era cauza, nu simptomul. |

Tiparul: fiecare sondă măsura **o proprietate a unui singur sistem**, iar
îngroparea e o **relație între două sisteme** (drumul și terenul). Nimeni nu era
responsabil de relație, deci nimeni n-o verifica.

Al doilea tipar, mai neplăcut: `probe_capp_mesh` era *aproape* întrebarea bună.
Diferența dintre „trag o rază în jos" și „trag o rază în sus" e un semn, și
semnul ăla a costat un gimmick.

## 2. Ce acoperă garda acum

`tools/ProbeBuried.tscn` + `tools/probe_buried.gd`.

```
godot --headless --fixed-fps 60 --path . res://tools/ProbeBuried.tscn
godot --headless --fixed-fps 60 --path . res://tools/ProbeBuried.tscn -- --track=6
```

Fără `--track` baleiază **toate** pistele din `GameState.TRACK_SCENES` și
raportează, ieșind mereu cu 0 — inventar. Cu `--track=N` verifică una singură și
**iese cu 1** dacă e îngropată: forma în care se pune în CI.

Pentru fiecare punct copt al fiecărei rute raportează câte puncte sunt îngropate
peste 1 m, cel mai adânc cu fracția lui, și **intervalele** în fracții — ca să se
vadă dintr-o privire dacă e o cusătură izolată sau o porțiune întreagă.

### Regula, și de ce nu e „e ceva deasupra mașinii?"

Răspunsul corect la „e ceva deasupra?" e **uneori da**: un tunel are tavan, un
pasaj are tablier, iar orașul subteran din brieful Cappadociei e o cavernă
întreagă peste care stă stânca. *O gardă care țipă la tunel nu e folosită de
nimeni, deci nu apără nimic.*

Regula are două condiții, amândouă plătite cu măsurători:

**(a) Se întreabă doar TERENUL** (nodul `TerrainBody`), nu orice corp fizic.

Prima versiune întreba orice solid și a raportat „îngropare" pe **toate cele 7
piste**. Verificate una câte una, niciuna nu era teren: poarta de start de pe
Dunele, tablierul mobil `LiftSpan` de pe Okinawa, trenul `PathMover` de pe
Baikal, poarta pasajului rotativ de pe Chongqing, iar pe Cappadocia chiar fusta
spiralei de deasupra. Alea sunt obstacole și suprafețe de drum — le ocolești,
treci pe sub ele, sau te lovești de ele ca de un obstacol cinstit. O gardă care
le numără pe toate ar fi fost roșie din prima zi și stinsă în a doua.

**(b) Se întreabă dacă spațiul în care stă CAROSERIA e ocupat de teren** —
`intersect_point` la 1 m peste asfalt, nu numărătoare de fețe.

Asta a fost a doua greșeală, și merită scrisă fiindcă e contraintuitivă. A doua
versiune aduna fețele de teren dintr-un raycast de sus în jos și lua cea mai de
jos. A fost măsurată **greșit chiar pe cazul pentru care exista**: pe elicea
îngropată dădea 6 puncte la `+4.04 m`, când câmpul vedea 150 la `+35.61 m`.
Motivul: acolo unde drumul e în piatră **plină** nu mai există nicio față între
stâncă și asfalt — raza se oprește sus, iar punctul iese „curat". Adică exact
îngroparea gravă scăpa, și garda ar fi fost verde pe propriul ei bug.

### A/B-ul care o validează

Nu „am scris o sondă și zice OK" — asta nu dovedește nimic. Se scoate nodul
`TerrainHollow` din `Track13.tscn` (adică se reintroduce bug-ul) și se compară:

| stare | rezultat |
|---|---|
| fără `TerrainHollow` (bug-ul original) | **153 puncte îngropate, `+35.49 m`**, intervale `0.754-0.840` și `0.854-0.921` — cod de ieșire **1** |
| cu `TerrainHollow` (reparat) | **0 puncte, `+0.00 m`** — cod de ieșire **0** |

Cele 153 la `+35.49 m` se potrivesc independent cu ce raportează
`probe_capp_bury` pe câmp (150 la `+35.61 m`), iar intervalele cad exact pe
elice. **Orice sondă nouă trebuie să treacă un A/B ca ăsta înainte să fie
crezută**; altfel „VERDICT: OK" e doar o propoziție.

## 3. Rezultatul pe pistele existente

Toate cele 7 sunt curate: 0 puncte îngropate. Nicio pistă veche nu e semnalată.

Merită notat că `tavane` iese **0 peste tot**: azi nicio pistă n-are *teren*
deasupra drumului. Stânca goală chiar e goală, iar tablierele Chongqingului sunt
corpuri de șosea, nu teren. Ramura de „boltă" există pentru orașul subteran din
brief — cine îl construiește să se uite întâi la cifra asta: dacă sare de pe
zero, regula ține.

## 4. Limitele, cinstit

1. **Un tunel de teren mai scund de 4.5 m (`CLEAR_M`) iese raportat ca
   îngropare.** Deliberat: mașina are ~1.5 m, deci la 4.5 m trece lejer, iar o
   boltă pe care o freci cu capul e oricum un bug de pistă, doar cu alt nume.
2. **O stâncă sculptată ca PROP** (un GLB, nu câmpul de înălțime) care ar îngropa
   drumul **trece pe lângă gardă.** Consecința lui (a), asumată: accidentul de
   clasă e câmpul de înălțime care umple un volum, fiindcă terenul e singurul
   lucru care se **generează singur** și poate crește peste drum fără ca cineva
   să fi pus ceva acolo. Un prop e întotdeauna așezat de mână, și se vede pe
   snapshot.
3. **Se testează AXA benzii, nu toată lățimea.** O limbă de teren care intră doar
   peste banda din dreapta trece nedetectată.
4. **Măsoară mesh-ul cu coliziune, nu câmpul `ground_y`.** Aia e și ideea: câmpul
   e sursa, dar cu roata intri în triunghiuri. `probe_capp_bury` rămâne pentru
   sursă; `probe_buried` e pentru rezultat.
5. **Ramura de boltă nu e verificată pe date reale** (vezi §3).
6. Se bazează pe faptul că trimesh-ul terenului răspunde la `intersect_point`
   pentru puncte din interiorul lui (măsurat: da, cu `backface_collision`). Dacă
   se schimbă motorul de fizică sau se stinge backface-ul, testul poate deveni
   **tăcut** — atunci A/B-ul din §2 e rețeta de reverificat.

## 5. Lecția

Sondele care măsoară **un** sistem nu prind defecte de **relație** între
sisteme. Când adaugi un mecanism nou care leagă două sisteme care până atunci
nu se atingeau (aici: un drum care trece prin interiorul unui volum de teren),
sondele existente nu se degradează — ele rămân la fel de corecte și devin la fel
de irelevante, și tocmai de-aia verdele lor liniștește pe degeaba.

Și: o sondă care nu a fost văzută **picând** pe bug-ul ei nu e o gardă, e o
speranță.
