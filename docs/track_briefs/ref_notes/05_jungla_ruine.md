# Ref — pistă 5: junglă + ruine

Tur: **1:16.1**.

## Structura turului

1. **0–7 s — start în canion.** Drum de pământ deschis la culoare între pereți
   de stâncă stratificată, vegetație verde-închis pe muchii. Îmbrânceli
   imediate — două mașini au explodat în primele 6 s.
2. **7–11 s — cascada.** Vezi mai jos.
3. **11–15 s — podul suspendat.** Punte de scânduri cu **cabluri și stâlpi de
   lemn**, peste o râpă verde. Îngustă — o mașină lată. Panou verde „Y" chiar
   înainte, deci există o rută alternativă.
4. **15–27 s — canionul rapid.** 140–145 constant, viraje largi, pereți
   înalți.
5. **27–33 s — prima platformă de ruine.** Mașina urcă pe o **structură de
   piatră în trepte**, cu model geometric în textură. Vezi mai jos.
6. **33–58 s — junglă.** Drum de pământ printre pereți acoperiți de mușchi,
   gropi întunecate în stâncă, un bazin circular palid.
7. **58–70 s — templul cu fețe.** Vezi mai jos.
8. **70–76 s — retur.** Drum lat prin vegetație, sosire.

## Gimmick: ruinele ca și carosabil

Ăsta e lucrul cel mai transferabil din toate cele cinci piste.

La 00:27 și la 01:08, **traseul urcă direct pe arhitectură**: trepte late de
piatră, platforme, și la 01:08 **o rampă flancată de două fețe sculptate
rotunde** (stil mezoamerican). Mașina trece peste ele la 103–107 km/h.

Nu e decor pe margine. Nu e o scurtătură. **E carosabilul.** Ruina nu e ceva
pe lângă care treci, e ceva pe care conduci.

**Ce ne privește:** noi tratăm decorul și carosabilul ca două categorii
separate — `DecorManual` pune obiecte lângă drum, `Track` generează asfalt.
Aici cele două se suprapun, și ăsta e exact „fiecare pistă = lume inedită" din
memorie, dus mai departe decât l-am dus noi.

Atenție tehnică: la noi, trepte pe carosabil ar cădea direct în capcana
documentată — **raza roții cade în orice gol, pragurile laterale peste 0.3 m
sunt ziduri.** Trepte de piatră conduse la 100 km/h cer margini în pantă și
o înălțime de treaptă sub pragul ăla, altfel suspensia pe raycast le va citi
ca perete. Fezabil, dar nu gratis.

## Cascada

O cascadă albă cade de pe perete **peste drum**, transversal.

Viteze măsurate: intrare **143**, în cascadă **134**, ieșire **137 → 146**.
**Cost efectiv: zero.** Mașina aruncă spray alb, ecranul se albește parțial
pentru ~0.5 s, și atât.

E cel mai bun exemplu de **hazard fals** din material: arată periculos, sună
periculos, nu costă nimic. Prima dată frânezi. A doua oară treci prin ea cu
turbo și te simți deștept.

Merită introdus la noi **exact pentru asta** — ca să existe și hazarduri pe
care înveți să le ignori. Dacă tot ce arată periculos chiar e periculos,
jucătorul nu are ce învăța.

## Podul suspendat

Scânduri transversale, două cabluri laterale, stâlpi de lemn la capete.
Lățime: aproximativ o mașină și jumătate. Viteza la intrare: 077 — deci se
frânează pentru el.

Nu am prins pe cameră dacă se leagănă sau dacă se poate cădea de pe el.

## Palete și materiale

Verde-închis saturat de vegetație (foarte închis, aproape negru la umbră) ·
bej-gri de drum de pământ · gri-maroniu de stâncă stratificată · alb de
cascadă · piatră cenușie cu mușchi verde pentru ruine.
