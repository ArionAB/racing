# Brief asset — Baraca minerului (`miner_shack.glb`)

Brief auto-conținut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Sursa reproductibilă: [tools/blender/build_miner_shack.py](../../tools/blender/build_miner_shack.py).

Referință vizuală: conceptul „Canyon Circuit", panoul **MINING SET DRESSING** —
baraca de lemn de lângă tabăra minieră.

---

## 1. Ce construiești

O baracă mică de miner, low-poly și stilizată, pentru un joc de curse cu
mașinuțe de jucărie în stil diorámă de deșert (ton *Art of Rally*). Rezultat:
un `.glb` cu **trei piese** care formează UN ansamblu.

## 2. Rolul lui în cadru

Landmark **secundar**: nu domină, dar dă o cotă umană lângă gura de mină și
spune că locul a fost locuit. Se vede de la ~60 m, din chase cam.

Testul care spune că a reușit: de la 60 m distingi **ușa** ca pată închisă pe
peretele spălat de soare. Dacă ușa se topește în perete, obiectul a devenit o
cutie.

## 3. Formă și dimensiuni

Unitate: 1 = 1 m; mașina de referință = 4.2 m.

- Corp **4.0 × 3.0 m**, înălțime la streașină **2.35 m** — mai mică decât casa
  de sat (≈4 m), ca să citească a adăpost, nu a casă.
- **Acoperiș într-o apă**, urcând 0.72 m spre spate, cu streașină de 0.28 m.
- Ușă 0.95 × 1.85 m și geam 0.80 × 0.62 m, ambele pe fața dinspre drum.
- Coș scurt, ușor strâmb; o scândură desprinsă sprijinită de peretele lateral.

**Pereții urmează panta acoperișului.** Cutia dreaptă + acoperiș înclinat =
pinion deschis; peretele trebuie să fie un **ic**.

## 4. Orientare

Fața cu ușa privește spre **-Z în Godot**, adică spre **+Y în Blender** —
exportatorul glTF face `(x, y, z) -> (x, z, -y)`.

## 5. Culoare și clase de suprafață

Trei piese, fiindcă au trei tratamente diferite:

| nod | suprafață | UV |
|---|---|---|
| `Shack_Wood` | clasa `wood` | proiecție cubică 1.2 m |
| `Shack_Roof` | clasa `rust_metal` | proiecție cubică 2.2 m |
| `Shack_Trim` | **atlas** | colapsat pe centrul slotului |

Trim-ul (ușă, geam, prag) rămâne pe atlas **dinadins**: ușa și geamul sunt cele
mai închise suprafețe din obiect, iar contrastul lor cu lemnul spălat de soare
e tot ce face silueta să se citească. O textură de lemn peste ele le-ar aduce
la valoarea peretelui.

Sloturi folosite de trim: `asphalt` (5) pentru gol, `sand_light` (0) pentru
rame, `concrete` (8) pentru prag.

## 6. Vertex colors = AO copt

Gradient vertical 0.45 → 1.0, `floor` 0.15, 28 de eșantioane. Întunecă sub
streașină și în pragul ușii.

## 7. Scară, origine, bevel

- Piesele sunt UN ansamblu: `finish(origin="base_axis")` + restaurarea cotei
  (`obj.location.z = min_z`), ca la casa de sat. Fără asta fiecare piesă ar fi
  așezată separat pe podea și acoperișul ar cădea pe fundație.
- Bevel 0.04 (corp, acoperiș) / 0.03 (trim).

## 8. Buget de triunghiuri

**≤ 1500**, măsurat după bevel.

## 9. Export

glTF Binary, `miner_shack.glb`, trei noduri: `Shack_Wood`, `Shack_Roof`,
`Shack_Trim`, copii direcți ai rădăcinii. Mesh + UV + Vertex Colors + Normals.

---

## 10. Note pentru noi

**Măsurat:** `Shack_Wood` 264 + `Shack_Roof` 220 + `Shack_Trim` 220 = **704
de triunghiuri** din 1500. bbox ≈ 4.6 × 3.6 m, înălțime 3.1 m cu coșul.

Integrat ca `_LANDMARKS[12]` (gap 12 m, coliziune box din AABB) și plasat pe
Dunele la fracția **0.178**, aceeași latură ca gura de mină (0.155) — cele două
se citesc ca o singură poveste.

## 11. Abateri de la brieful original și de ce

- **Acoperișul e o singură placă înclinată cu nervuri deasupra, nu trei plăci.**
  Prima versiune a făcut trei plăci separate, fiecare rotită în jurul centrului
  **ei** și toate la aceeași cotă — adică trei trepte plutind peste baracă, nu
  o pantă. Când piesele trebuie să formeze un plan, planul se face întâi și se
  împarte după, nu invers.
- **Pereții sunt un ic făcut din vârfuri, nu un pinion din piese.** Ridicarea
  vârfurilor de sus costă **zero** triunghiuri; un pinion construit ar fi
  costat patru piese. Fără el, acoperișul plutea cu 30 cm de cer sub el.
- **Ușa și geamul sunt plăci lipite de perete, nu decupaje.** Un decupaj real
  ar fi cerut spargerea peretelui în patru cutii; la distanța de joc diferența
  dintre o gaură și o pată închisă nu există.
- **Scândura desprinsă are 10 cm grosime, nu 4.** Sub 5 cm dispare la 40 m și
  lasă în siluetă o zgârietură, nu un obiect (style_bible §3).

## 12. Dependențe și compoziție

- Ajutoare din `dio_lib`: `Builder.box`, `retag`, `cube_uvs`, `finish`.
- Clasele `wood` și `rust_metal` **existau deja** pe pistă, deci baraca adaugă
  zero materiale la bugetul de draw call-uri.
