# Inventar tf-d — barajul și reperele (Transfăgărășan, Track21, valul 2)

Contract: `docs/asset_briefs/transfagarasan_kit.md` §1.2. Build:
`tools/blender/build_tf_landmarks.py` (`TF_ONLY=<piesă>` reface o piesă).
Preview: `tools/blender/preview_tf_d.py` (`--compare`, `--views`, `--chain vidraru_dam`).
Cote MĂSURATE pe GLB-ul exportat (`verify_glb.py`, `measure_tf_deck.py`).
Axe: Blender X lateral, +Y înainte (= −Z Godot), Z sus.

## structures/vidraru_dam.glb

Trei noduri-rădăcină (Empty, scala 1, rotație 0, toate la origine). Originea
fiecăruia e la cota drumului, pe axa drumului. Geometria e poziționată față de
ea: turnul pe −X (lacul), centrala la picior pe +X (hăul). Integrarea pune
`Dam_Tower`/`Dam_PowerHouse` cu **același** transform ca modulul lângă care
stau.

| rădăcină | nod | slot | tri |
|---|---|---|---:|
| `Dam_Module` | `Dam_Module_Concrete` | CONCRETE 8 | 832 |
| | `Dam_Rail` | KERB_RED 7 | 176 |
| `Dam_Tower` | `Dam_Tower_Concrete` | CONCRETE 8 | 808 |
| | `Dam_Tower_Void` | VOLCANIC_BLACK 20 | 132 |
| `Dam_PowerHouse` | `Dam_PowerHouse_Concrete` | CONCRETE 8 | 440 |
| | `Dam_PowerHouse_Void` | VOLCANIC_BLACK 20 | 144 |
| total | | | **2 532** |

### Cote măsurate față de contract

| cotă | contract | GLB |
|---|---|---|
| modul pe Y | 16 m, capete plane la ±8 | 16,00 m (Y −8,00..+8,00) |
| coronament | 14 m (\|x\| ≤ 7) | 14,0 m; cornișa iese 0,6 m peste fața din aval, pe 2,1 m înălțime |
| aval | 40 m | Z −40,00 (piciorul) |
| amonte | 9 m vizibili (fundul lacului la −9) | fața de amonte, verticală la x = −7, coboară până la −40 (sub −9 e îngropată în teren) |
| fața din aval | verticală sus, concavă în ultimii 15 m | verticală la x = 6,4 până la −25, apoi x crește cu pătratul: +9 m la bază (piciorul la x = 15,6) |
| rosturi | canelură de 0,3 m la capete | 0,15 m lățime × 0,15 m adâncime pe fiecare capăt = **0,30 m** între două module |
| benzi de cofraj | 3, trepte de 5 cm | la −8 / −15 / −22 m, câte 5 cm |
| parapet | 1,1 m, 6,25 ≤ \|x\| ≤ 7,0 | **1,100 m** pe ambele părți (măsurat), blocuri de 4 m beton / roșu alternativ (ca pe serpentine), rost de 4 cm |
| turnul | 6 × 6 m, +8 m | Ø 6,6 m (placa acoperișului; cabina Ø 5,6, putul Ø 5,0), vârful la **+8,00**, centrul la x = −16,3; puțul coboară la −10 |
| pasarela | 6 m | de la x = −13,6 la −7,0 (6,6 m), 2,4 m lată, la cota coronamentului |
| centrala | 14 × 9 × 8 m | 14,0 (Y) × 9,0 (X, de la 16,2 la 25,2) × 8,0 (−40..−32) m, plus cornișa acoperișului |

### CONTRACT: nimic pe asfalt (`measure_tf_deck.py`, pe GLB)

Triunghiurile se **taie** la marginea benzii, deci se măsoară exact, nu după
vârfuri. Pe o grilă de 0,25 m se mai caută și suprafața cea mai înaltă de sub
fiecare punct.

| măsură | valoare | contract |
|---|---|---|
| cota maximă în \|x\| ≤ 6,0 | **−0,080 m** | ≤ −0,05 |
| suprafața de sub drum, min / max | −0,080 / −0,080 m | — |
| acoperire (coronamentul ține tot drumul) | 100,0 % | ≥ 99 % |
| parapet −X / +X | 1,100 / 1,100 m | 1,1 |

Sabotaj: cu `--contract=-0.10` iese `INCALCAT`, iar cu banda lărgită la 6,5 m
prinde parapetul (1,100). Deci garda chiar măsoară. Intră automat în
`verify_transfagarasan.sh` (`deck_check`).

`verify_glb.py --origin=rim --rim-above=8.1`: corpul atârnă sub origine
(Y −40,00..+8,00). Peste ea stau doar parapetul și turnul, de aceea s-a
adăugat flagul `--rim-above` (vezi „Fișiere partajate”).

### Fidelitate

Comparațiile:
- piesa izolată: `img/transfagarasan_fidelity/vidraru_dam.png`;
- 4 azimuturi: `vidraru_dam_views.png`;
- **6 module înlănțuite**, cu turnul lângă al doilea și centrala la piciorul
  celui de-al patrulea: `vidraru_dam_chain.png`. Lacul (−4,5 m) și fundul
  hăului (−40 m) sunt doar planuri de preview.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| zidul plin, bej-gri | zid lung, fără ferestre | modul plin, `*_Concrete` (#B8B4AA în preview) | OK |
| rosturi / panouri | ~7 panouri cu caneluri înguste | un modul = un plot, canelura de 0,30 m între module. În lanțul de 6 se citesc 6 panouri | OK |
| cornișa | bandă continuă ieșită, ~1/12 din înălțime | 2,1 m, ieșită 0,6 m (1/19 din 40 m) | OK. Runda 1 o avea prea slabă (1,5 m, ieșită 0,25 m), mărită în runda 2 |
| parapetul | jos, deschis, dungi roșii scurte, distanțate | blocuri de 4 m alternând beton / roșu | abatere asumată: kitul cere stilul serpentinelor. Pe planșă roșul e în liniuțe mici, în diorama e alternanță roșu-alb ca aici |
| profilul | zid aproape vertical, ușoară lărgire la bază | vertical sus, concav în ultimii 15 m (+9 m) | corectura coordonatorului. Pe lanț se citește ca piciorul unui baraj-arc |
| coronamentul în plan | ușor curb | drept | corectura coordonatorului |
| turnul | masiv, la capătul din dreapta, lipit de zid, 3 ferestre sus | cilindru pe partea lacului, cu pasarelă, cabina cu 6 ferestre, casa troliului cu 4 fante | corectura. **Abatere:** văzut din aval (camera din diorama) turnul e în spatele parapetului și citește mic. Pe planșă e reperul dominant al capătului |
| abutmentul din stânga | pilastru gros cu ceva pe el | nu intră | capetele le dă terenul (Prometeu stă pe pinten, piesă separată) |
| centrala | (din dioramă) cutie de beton la picior, apa iese la bază | cutie de 14 × 9 × 8 m, 4 ferestre înalte între 5 pilaștri, 2 ieșiri negre cu copertină, câte 3 ferestre pe laturi | OK |
| drumul | asfalt închis pe coronament | nu intră (cod); coronamentul e la −0,08 | OK |

Runde: 1 (cornișă slabă; planurile de preview ieșeau negre, fiindcă
materialul de preview înmulțește cu AO, iar ele nu aveau strat AO), apoi 2
(cornișă 2,1 m / 0,6 m, planurile reparate).
