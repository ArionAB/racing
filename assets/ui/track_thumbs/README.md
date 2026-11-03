# Imagini pentru "CURSA RAPIDA"

Un fisier per pista, cu numele SCENEI (nu al pistei):

| Pista        | Fisier         |
|--------------|----------------|
| Dunele       | `Track01.png`  |
| Okinawa      | `Track08.png`  |
| Alpii        | `Track09.png`  |
| Baikal       | `Track10.png`  |
| Stromboli    | `Track11.png`  |
| Chongqing    | `Track12.png`  |
| Cappadocia   | `Track13.png`  |
| Serengeti    | `Track14.png`  |
| Machu Picchu | `Track15.png`  |
| Fiordland    | `Track16.png`  |

Se accepta si `.jpg` / `.webp`. Format recomandat: 16:9, ~960x540 (imaginea
e decupata "cover", deci marginile pot fi taiate usor). Cat timp fisierul
lipseste, cartonasul arata un placeholder cu calea asta.

Dupa ce adaugi imaginile, deschide editorul Godot o data (sau ruleaza
`--headless --import`) ca sa fie importate.

**Comite imaginea IMPREUNA cu `.import`-ul ei.** Build-ul de iOS se face pe
GitHub din checkout: o imagine care exista doar pe discul tau apare in joc pe
desktop, dar pe telefon cartonasul arata placeholder-ul. `tools/verify_local.sh`
pica daca gaseste assets necomise.
