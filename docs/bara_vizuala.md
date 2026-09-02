# Bara vizuală — cum se compară o captură cu referința

Uneltele din `tools/bar/` există ca să răspundă la o singură întrebare: *cadrul
nostru arată ca referința?* Fiecare a fost scrisă ca reacție la un defect real,
și **fiecare are o limită care a costat runde întregi până s-a înțeles.** Fișierul
ăsta e harta lor, plus limitele — ca nimeni să nu le redescopere.

## Regula zero: captura bate cifra

Toate uneltele de aici sunt ajutoare, nu arbitri. Ordinea corectă e:

1. **Deschide poza.** Ochiul prinde în două secunde ce o statistică de ordin zero
   nu prinde deloc (`statistica-de-ordin-zero-nu-vede-forma`).
2. **Atribuie** ce vezi unui obiect cu nume, înainte să repari
   (`tools/ProbeMasca.tscn`).
3. **Abia apoi** măsoară, ca să ai un înainte/după.

Semnalul că măsori altceva decât crezi: **două reglaje diferite dau cifre
identice la zecimală.** S-a întâmplat de patru ori într-o zi. Când apare, nu
încerca al treilea reglaj — verifică ce măsori.

## Care unealtă, pentru ce

| unealtă | răspunde la | limita ei |
|---|---|---|
| `blind_pair.py` | care panou e mai bun, fără etichete | cheia poartă hash-ul argumentelor; NU refolosi un nume de fișier între runde — doi critici s-au judecat unul pe altul |
| `detaliu_masca.py` | cât detaliu de suprafață are un OBIECT | cere masca din `ProbeMasca`; e varianta corectă, folosește-o pe asta |
| `detaliu_local.py` | cât detaliu are cadrul, pe dale de 20% | pragul 1.63 e calibrat pe o vedere AERIANĂ; pe un cadru de șofer cu cer în rândul 0 **nu e atins niciodată** |
| `cone_profile.py` | silueta unui horn e con sau butoi | măsoară pe captură, deci depinde de unghi; pentru adevăr, măsoară profilul din GLB |
| `cap_silhouette.py` | pălăria e mai lată decât gâtul, și cu cât | — |
| `facet_edges.py` | variația de valoare e pe MUCHIE sau pictată neted | poate fi trecută înnegrind roca; are gardă de întuneric (≤12%), respect-o |
| `umbre_silueta.py` | umbrele au formă, nu doar întunecime | — |
| `satur_adancime.py` | saturația pe benzi de adâncime, cu/fără cer | — |
| `skyline_cones.py` | profilul conurilor de pe cer | — |

## Praguri care NU se pot atinge, și de ce

Notate ca să nu se mai trimită runde după ele:

- **anizotropie ≤ 0.15 în banda de jos.** Solul gol al *referinței* măsoară
  0.30, mai rău decât 0.26 la noi. Cei 0.02 ai ei vin din OBIECTE în bandă, nu
  din calitatea umbrei. Nu e atinsă prin shading, niciodată.
- **`detaliu_local` = 1.63 pe dala r0 c3 a cadrului de șofer.** Dala aia e 36%
  cer (cerul singur dă 0.62), deci muntele ar trebui să dea 2.20 ca dala să dea
  1.63. Pragul e calibrat pe rândul 0 al referinței, care e vedere aeriană cu 0%
  cer. Un cadru de șofer are orizont în rândul 0 prin construcție.
- **`ProbeFerestre` = 0 puncte în aer.** Pragul e 123 și e datorie declarată:
  punctele rămase nu se văd de la volan, și nu se știe dacă sunt geometrie reală
  sau limita sondei. Trei strâmtări au mutat cifra 15% și captura a rămas
  identică la zecimală.

## Capcane de măsurare, toate plătite

- **Caseta dreptunghiulară peste un obiect neregulat conține fundal în proporție
  necunoscută.** O casetă „peste horn" a ieșit 79% cer și a dat „roca noastră are
  un sfert din detaliul referinței" — pe mască, roca noastră îl DEPĂȘEȘTE (4.26
  față de 3.85). Măsoară pe mască, și tipărește ce procent din zonă e obiect.
- **Unealta de captură e parte din măsurătoare.** `snapshot.gd` stingea ceața
  necondiționat, deci și pentru `--driver`: 13 runde s-au judecat pe o lume în
  care muntele de fundal e rocă, când în joc e CER. Verifică abaterile uneltei
  cu un A/B forțat (pune parametrul pe o valoare absurdă: dacă poza nu se
  schimbă, parametrul nu ajunge).
- **Import învechit falsifică orice cifră scoasă din capturi.** Rulează
  `--headless --path . --import` înainte de ORICE serie de măsurat, chiar dacă
  tu n-ai schimbat nimic.
- **O sondă poate fi trecută cu gunoi.** `detaliu_local` a atins 4.22 (peste
  prag) cu scânduri suspendate în cer gol, iar poza era mai proastă. Orice țintă
  pe o axă cere o gardă pe axa pe care poate fi plătită.

## Judecata oarbă

`blind_pair.py` randomizează A/B și șterge etichetele. Ca să nu fie teatru:

- **o singură planșă per rundă.** Patru planșe cu aceeași referință și capturi
  diferite = ghicești din repetiție, nu din judecată. Un critic a declarat
  singur scurgerea asta, corect.
- criticul **deschide** planșa și se uită; nu judecă din raportul
  constructorului și nici din cifre.
- alege ÎNTÂI, citește cheia DUPĂ, și raportează onest dacă a nimerit.
- lauda nu ajută. Dar nici încrâncenarea: dacă a noastră chiar câștigă, asta se
  spune la fel de limpede — miza e să se termine.
