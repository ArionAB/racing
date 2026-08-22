# Ref — world design: verticalitate și linii de vedere

Nota asta e despre ce face pistele lor memorabile dincolo de hazarduri.
Observația e a dezvoltatorului, după ce a jucat; eu am verificat doar
consecințele tehnice la noi.

## Principiul

Pe fiecare din cele cinci piste, traseul e așezat **pe buza unei denivelări
mari, cu ceva vizibil în adânc**:

- **Templul din junglă** — urci continuu pe arhitectură, și pe măsură ce urci
  se deschide prăpastia. Nu vezi prăpastia dintr-un punct; ți se dezvăluie
  progresiv, pentru că *urci*.
- **Canionul de desert** — mergi pe margine, iar jos de tot se vede un lac
  (un fel de baraj). Nu e o textură de fundal; e o altă parte a lumii, la
  care nu ajungi.
- **Pista de gheață** — poți intra pe o rampă de lemn care te aruncă **peste
  pistă**. Deci pista trece pe lângă sine, cu separare pe verticală.

Numitorul comun: **ceea ce vezi nu e decor, e lume.** Un munte pictat pe
skybox spune „ești undeva". Un lac la 150 m sub tine, pe care îl vezi de pe
buză în timp ce virezi, spune „ești *aici*, și aici e sus".

Și verticalitatea nu e statică — e **dezvăluită de traseu**. Urcarea e ce
transformă un decor într-un moment.

## Ce înseamnă asta la noi, concret

### 1. Camera nu e blocajul (verificat)

`ChaseCamera`: 12.5 m în spate, 10.0 m înălțime, **28.7° în jos**, FOV 68°.
Conul de vedere merge deci de la ~5° **deasupra** orizontalei până la ~63°
**sub** ea. E destul ca să vezi în jos, pe lângă mașină, într-o râpă.

Camera lor e vizibil mai abruptă (estimat 40–55° din cadre), ceea ce le dă
mai multă adâncime pe verticală — dar plătesc pentru asta: **văd mai puțin
înainte**, și de-aia au nevoie de panourile alea mari de semnalizare în HUD
(săgeți galbene/roșii, „Y" verde). Lanțul e coerent:

> cameră abruptă → vezi în jos, în lume → pierzi vizibilitatea înainte →
> compensezi cu semnalizare în HUD

Dacă vreodată înclinăm camera mai jos, **semnalizarea trebuie să vină în
același pachet.** Altfel virajele devin oarbe.

### 2. Ceața e blocajul (verificat)

`FAR_PLANE = 380 m`; `fog_end` per temă între **250 și 370 m**.

Un lac „jos de tot" citește ca adâncime doar dacă e departe — și departe e
exact ce mănâncă ceața. Rezultatul ar fi o râpă care se termină în ceață, nu
o priveliște.

Deci aceeași lecție ca la munte (`munte-flanc-nu-fundal`): **adâncimea se
citește prin proximitate, nu prin distanță.** Un lac la 120 m sub tine și la
200 m lateral, în interiorul lui `fog_end`, funcționează. Unul la 400 m, nu.
Fundul râpei trebuie tras aproape și făcut adânc, nu împins departe.

### 3. Pista peste pistă — mai aproape decât credeam, dar cu o capcană

Ca să sari peste pistă îți trebuie ca pista să treacă pe lângă sine, cu
separare pe verticală. La noi:

- **Merge în regim normal.** `car.gd:398` folosește
  `track.closest_index(road_index, ...)` — căutare *fereastră*, pornind de la
  indexul anterior. Exact ce trebuie: două benzi suprapuse pe verticală nu se
  confundă, pentru că mașina nu poate sări de pe una pe alta în progresie.
- **Se rupe la repunere și la hazarduri.** `car.gd:922`, `race.gd:108` și
  `typhoon_hazard.gd:568` folosesc `closest_index_global(...)` — cel mai
  apropiat punct din toată pista. Cu două etaje suprapuse, alegerea e la
  mila diferenței de cotă. O repunere după accident sub pod te poate agăța
  de banda de deasupra.

Nu e un blocaj de arhitectură, e **trei apeluri de reparat** (fie ponderând
diferența de cotă, fie ținând ultimul index valid și căutând local). Merită
știut înainte, nu după ce se desenează pista.

## Ordinea în care aș ataca asta

1. **O pistă pe buză, cu ceva jos, în interiorul lui `fog_end`.** Nu cere cod
   nou — teren și rutare. Testul e o captură `--driver` din viraj: se vede
   fundul, sau se vede ceață?
2. **Urcare care dezvăluie.** Aceeași priveliște, dar câștigată prin altitudine
   pe parcursul unui sfert de tur.
3. **Pista peste pistă**, după ce se repară cele trei `closest_index_global`.
