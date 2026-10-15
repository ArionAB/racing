"""Garda de SILUETA pentru turnurile de carst (Ha Long, Track22).

Contractul e in `docs/asset_briefs/halong_kit.md` §1.1 si e singurul lucru care
face roca sa citeasca "Ha Long" si nu "deal tropical": un turn de carst e
**cel mai ingust la linia apei**, fiindca valurile i-au mancat o nisa in baza,
iar peretele de deasupra iese IN CONSOLA peste apa.

De ce o garda separata, si nu `verify_glb.py`: aceea verifica sapte lucruri
GENERICE (nume de noduri, buget, sloturi, AO, origine, orientare) si ar trece
fara sa clipeasca peste un con perfect. Forma e un contract al PISTEI, deci se
masoara aici.

Istoric, ca pragurile sa nu para arbitrare:
  * la pasul 7 al pistei, turnurile aveau h/r = 0,57-0,74 si interiorul buclei
    citea ca o masa continua de uscat — exact pe dos fata de brief §0.1. De
    acolo vine pragul h/r;
  * prima plansa de inventar (`halong_assets_v1.jpg`, randul 1) desena turnuri
    care se LARGESC spre baza: masurat pe `karst_tower_a`, 84 px la mijloc si
    148 px la baza, adica raport 1,76 in loc de 0,62. A fost regenerata
    (`halong_assets_v2_row1.jpg`: 0,48 / 0,64 / 0,42). Garda asta exista ca
    acelasi defect sa nu intre in GLB, unde ar costa mult mai mult.

Se masoara pe FELII ORIZONTALE prin norul de vertecsi: pentru fiecare felie,
raza = jumatate din intinderea maxima pe X/Z. Nu pe AABB (memoria
`cota-de-contract-se-masoara-ca-gol`: o caseta nu vede profilul) si nu pe
imagine.

    python tools/blender/verify_karst_profile.py assets/models/halong/rocks/karst_tower_a.glb
    python tools/blender/verify_karst_profile.py <glb> --notch=0.70 --hr=2.5
    python tools/blender/verify_karst_profile.py <glb> --sabotaj

`--sabotaj` inlocuieste norul cu un CON (larg la baza, ingust sus) si cere ca
garda sa PICE. Fara el, o garda care trece din constructie e indistinguibila de
una care masoara (memoria `garda-fara-linie-de-baza-iese-zero`).
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor  # noqa: E402

# Pragurile din brief §1.1. Tinta profilului e 0,62; pragul lasa o marja de
# constructie, dar nu atat cat sa treaca un perete vertical (1,00).
NOTCH_MAX = 0.70
HR_MIN = 2.5
# Nisa se cauta in treimea de jos: peste atat nu mai e "linia apei".
NOTCH_ZONE = (0.02, 0.33)
# 80 de felii, nu 40: la 40 pasul e 0,025 in z, iar nisa (z = 0,06) cade INTRE
# esantioane. Masurat pe un turn sintetic construit chiar pe profilul din brief,
# raportul real 0,620 iesea 0,699 — adica piesa corecta trecea LA LIMITA pragului
# de 0,70, si orice fatetare din Blender ar fi impins-o peste. Garda masura
# propriul filtru, nu forma (aceeasi familie cu memoria
# `sonda-masoara-propriul-artefact-de-pornire`).
SLICES = 80
# Vegetatia de pe varf nu e roca si nu intra in silueta: nodurile care se
# numesc *_Scrub / *_Veg se sar. Asta e si motivul pentru care piesa se exporta
# pe doua noduri (brief §0.6).
SKIP_SUFFIXES = ("_Scrub", "_Veg", "_Vegetation", "_Plants")


def node_world_offset(gltf, idx):
    """Translatia acumulata pana la nod. Turnurile n-au rotatii/scale in
    ierarhie (brief §0.4: scara metrica, origine la baza), deci translatia
    ajunge; daca apare scale, garda o semnaleaza in loc s-o ignore."""
    parent = {}
    for i, n in enumerate(gltf.get("nodes", [])):
        for c in n.get("children", []):
            parent[c] = i
    off = [0.0, 0.0, 0.0]
    seen = set()
    cur = idx
    while cur is not None and cur not in seen:
        seen.add(cur)
        n = gltf["nodes"][cur]
        if "scale" in n and any(abs(s - 1.0) > 1e-4 for s in n["scale"]):
            print("  [atentie] nodul %s are scale %s: silueta masurata poate "
                  "diferi de cea din joc" % (n.get("name", cur), n["scale"]))
        t = n.get("translation", [0.0, 0.0, 0.0])
        off = [off[k] + t[k] for k in range(3)]
        cur = parent.get(cur)
    return off


def gather_points(path):
    """Toti vertecsii de ROCA, in coordonatele piesei."""
    gltf, blob, _, _ = load_glb(path)
    pts = []
    skipped = []
    for idx, node in enumerate(gltf.get("nodes", [])):
        if "mesh" not in node:
            continue
        name = node.get("name", "node%d" % idx)
        if name.endswith(SKIP_SUFFIXES):
            skipped.append(name)
            continue
        off = node_world_offset(gltf, idx)
        for prim in gltf["meshes"][node["mesh"]].get("primitives", []):
            attrs = prim.get("attributes", {})
            if "POSITION" not in attrs:
                continue
            for p in read_accessor(gltf, blob, attrs["POSITION"]):
                pts.append((p[0] + off[0], p[1] + off[1], p[2] + off[2]))
    return pts, skipped


def radius_profile(pts, slices=SLICES):
    """Raza pe felii orizontale: jumatate din intinderea maxima pe X/Z.

    Pe X si pe Z separat, apoi maximul — un turn inclinat (`karst_tower_c`) nu
    e centrat pe axa, deci o raza calculata fata de origine ar minti.
    """
    ys = [p[1] for p in pts]
    y0, y1 = min(ys), max(ys)
    h = y1 - y0
    if h <= 0:
        return None, 0.0, 0.0
    prof = []
    for k in range(slices + 1):
        zf = k / float(slices)
        yc = y0 + zf * h
        # Felie INGUSTA: o felie lata mediaza peste nisa si o umple. Cu 0,75
        # din pas, acelasi turn sintetic dadea 0,699 in loc de 0,620.
        band = h / float(slices) * 0.35
        sel = [p for p in pts if abs(p[1] - yc) <= band]
        if len(sel) < 3:
            prof.append((zf, None))
            continue
        xs = [p[0] for p in sel]
        zs = [p[2] for p in sel]
        r = max(max(xs) - min(xs), max(zs) - min(zs)) / 2.0
        prof.append((zf, r))
    return prof, h, y0


def evaluate(path, notch_max, hr_min, verbose=True):
    pts, skipped = gather_points(path)
    if not pts:
        print("PICA: n-am gasit vertecsi de roca in %s" % path)
        return False
    prof, h, _ = radius_profile(pts)
    if prof is None:
        print("PICA: piesa are inaltime zero")
        return False
    vals = [(zf, r) for zf, r in prof if r]
    # Raza de referinta: MEDIANA pe o fereastra LARGA (0,35-0,70), nu maximul
    # pe una ingusta.
    #
    # Prima versiune lua max pe 0,45-0,55, adica pe ~3 felii din 80 — in
    # practica O SINGURA felie (variatie masurata: 0%). Cu `jag` 0,13-0,15 raza
    # oscileaza pe verticala, deci acel numar era de noroc: pe `karst_tower_b`
    # iesea 13,82 fata de 16,16 mediana, umfland raportul de la 0,62 la 0,73 si
    # picand o piesa CORECTA. Masurat atunci pe toate trei turnurile: fata de
    # raza maxima, rapoartele erau 0,58 / 0,62 / 0,61 — adica exact tinta.
    # Peretele unui turn de carst e drept pe toata inaltimea mijlocie, deci o
    # mediana pe fereastra larga e si mai aproape de ce vede ochiul.
    mid = sorted(r for zf, r in vals if 0.35 <= zf <= 0.70)
    if not mid:
        print("PICA: nu pot masura raza la mijloc")
        return False
    r_mid = mid[len(mid) // 2]
    notch = [(zf, r) for zf, r in vals if NOTCH_ZONE[0] <= zf <= NOTCH_ZONE[1]]
    if not notch:
        print("PICA: nu pot masura raza in zona nisei")
        return False
    z_notch, r_notch = min(notch, key=lambda t: t[1])
    ratio = r_notch / r_mid
    hr = h / r_mid

    if verbose:
        print("  %s" % os.path.basename(path))
        if skipped:
            print("    (sarite, nu sunt roca: %s)" % ", ".join(skipped))
        print("    inaltime        %.2f m" % h)
        print("    raza la mijloc  %.2f m" % r_mid)
        print("    NISA            %.2f m la z=%.2f" % (r_notch, z_notch))
        print("    nisa/mijloc = %.2f   (prag <= %.2f)" % (ratio, notch_max))
        print("    h/r         = %.2f   (prag >= %.2f)" % (hr, hr_min))

    ok = True
    if ratio > notch_max:
        print("    PICA: nisa/mijloc %.2f > %.2f — turnul nu e mancat la baza, "
              "deci citeste ca DEAL, nu ca turn de carst" % (ratio, notch_max))
        ok = False
    if hr < hr_min:
        print("    PICA: h/r %.2f < %.2f — prea indesat" % (hr, hr_min))
        ok = False
    # Nisa trebuie sa fie cel mai ingust punct AL PERETELUI (z 0,33-0,90), nu
    # al intregii piese.
    #
    # Prima versiune compara cu tot ce e peste nisa si respingea orice turn
    # normal: profilul din brief se termina la 0,70 din raza (varful cu tufe),
    # iar pe `notch_rock_a` varful masoara 0,56 m fata de 1,28 m la nisa. Garda
    # raporta "nisa nu e punctul cel mai ingust" aratand spre COROANA — adica
    # cerea un turn care se LARGESTE spre varf, exact pe dos fata de contract.
    # Prins pe un GLB real inainte sa existe vreo piesa Ha Long.
    # Fereastra se opreste la 0,80, nu la 0,90: peste atat incepe CREASTA, iar
    # pe un turn cu creasta dubla (`karst_tower_b`) o felie poate cadea in saua
    # dintre varfuri si masoara aer. Masurat acolo: 14,48 -> 4,65 -> 13,59 pe
    # trei felii consecutive, adica garda raporta "perete subtire de 4,65 m"
    # aratand spre golul dintre creste.
    wall = [r for zf, r in vals if 0.33 <= zf <= 0.80]
    if wall and r_notch > min(wall):
        print("    PICA: peretele e mai ingust (%.2f m) decat nisa (%.2f m) — "
              "nisa nu e stransura de la baza" % (min(wall), r_notch))
        ok = False
    if ok and verbose:
        print("    [OK] silueta de turn de carst")
    return ok


def sabotage_check(notch_max, hr_min):
    """Un CON (larg jos, ingust sus) trebuie sa PICE. Fara proba asta, garda
    n-ar fi distinsa de una care intoarce mereu OK."""
    print("\n--- SABOTAJ: un con in locul turnului ---")
    pts = []
    H = 50.0
    for k in range(60):
        zf = k / 59.0
        y = zf * H
        r = 20.0 * (1.0 - 0.6 * zf)   # 20 m la baza -> 8 m sus
        for a in range(16):
            th = a * math.tau / 16.0
            pts.append((r * math.cos(th), y, r * math.sin(th)))
    prof, h, _ = radius_profile(pts)
    vals = [(zf, r) for zf, r in prof if r]
    r_mid = max(r for zf, r in vals if 0.45 <= zf <= 0.55)
    notch = [(zf, r) for zf, r in vals if NOTCH_ZONE[0] <= zf <= NOTCH_ZONE[1]]
    z_notch, r_notch = min(notch, key=lambda t: t[1])
    ratio = r_notch / r_mid
    print("  con: nisa/mijloc = %.2f (prag <= %.2f)" % (ratio, notch_max))
    if ratio > notch_max:
        print("  [OK] sabotajul PICA, cum trebuia: garda chiar masoara forma")
        return True
    print("  SABOTAJUL N-A PRINS: garda trece peste un con, deci nu masoara "
          "nimic")
    return False


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    notch_max = NOTCH_MAX
    hr_min = HR_MIN
    for f in flags:
        if f.startswith("--notch="):
            notch_max = float(f.split("=", 1)[1])
        elif f.startswith("--hr="):
            hr_min = float(f.split("=", 1)[1])
    if "--sabotaj" in flags:
        sys.exit(0 if sabotage_check(notch_max, hr_min) else 1)
    if not args:
        print(__doc__)
        sys.exit(2)
    print("=== silueta turnurilor de carst (brief halong_kit.md §1.1) ===")
    all_ok = True
    for path in args:
        if not os.path.isfile(path):
            print("  PICA: lipseste %s" % path)
            all_ok = False
            continue
        if not evaluate(path, notch_max, hr_min):
            all_ok = False
    print()
    print("VERDICT SILUETA: %s" % ("OK" if all_ok else "PICAT"))
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
