"""Garzile structurilor Carrara (kit §1.3, grupa crr-b), MASURATE pe GLB-ul exportat.

Axele glTF: X lateral, Y sus, Z adancime (= -Y Blender). Toate nodurile se citesc
cu transformarea lor (scara/rotatia/translatia din fisier), deci o scala uitata pe
o radacina se vede in cifra (memoria scala-glb-neaplicata-la-radacina).

  deck <glb>      viaductul `ponti_di_vara`: asfaltul e din cod, la Y = 0.
                  * deck_max: cota maxima a ORICARUI triunghi (taiat la marginea
                    benzii) din |x| <= --half (4,6), pe toate nodurile in afara de
                    --parapet (Viaduct_Parapet); trebuie <= --limit (-0,05);
                  * vert_max: acelasi lucru pe varfuri (dublura ieftina);
                  * acoperire: cat din banda are tablier dedesubt (grila 0,25 m),
                    >= 99%;
                  * parapetul: nodul exista, sta in --parapet-band (4,7..5,3) pe
                    AMBELE parti si are 0,85..0,95 m peste drum.
  gap <glb>       portalurile: golul MASURAT CA GOL (proiectie pe planul fetei,
                  grila 5 cm, ca measure_gap.py). Tipareste toate ferestrele
                  (memoria golul-se-masoara-pe-fereastra-lui):
                  * caroseria 0,15-2,0 m: golul lateral si inaltimea libera pe el;
                  * dreptunghiul de contract --rect=L,H: golul lateral liber pe
                    TOATA banda 0..H (adica un dreptunghi LxH centrat trece);
                  * --crown=C: inaltimea libera la mijloc (|x| <= 0,5) >= C;
                  * --floor=m: ignora triunghiurile cu varful sub m (sinele de pe
                    drum, declarate in verify_carrara.sh).
  sabotage <in> <out> --node=N (--translate=x,y,z | --scale=sx,sy,sz)
                  scrie o COPIE a GLB-ului cu nodul N mutat/scalat (doar JSON-ul;
                  bufferul ramane identic), ca sa se dovedeasca ca garzile pica.

    python tools/blender/measure_crr_structures.py deck assets/models/carrara/structures/ponti_di_vara.glb
    python tools/blender/measure_crr_structures.py gap  <glb> --rect=10.0,10.5
    python tools/blender/measure_crr_structures.py gap  <glb> --rect=10.0,6.0 --crown=8.5 --floor=0.1
Iese 1 daca un contract e incalcat.
"""
import json
import os
import struct
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import measure_gap as mg  # noqa: E402
import measure_tf_deck as td  # noqa: E402
from verify_glb import load_glb, read_accessor  # noqa: E402


def gather_nodes(path):
    """{nume nod: triunghiuri (n, 3, 3) in lume}."""
    gltf, blob, _, _ = load_glb(path)
    nodes = gltf["nodes"]
    parent = {}
    for i, n in enumerate(nodes):
        for c in n.get("children", []):
            parent[c] = i

    def world(i):
        m = mg.node_matrix(nodes[i])
        while i in parent:
            i = parent[i]
            m = mg.node_matrix(nodes[i]) @ m
        return m

    out = {}
    for i, n in enumerate(nodes):
        if "mesh" not in n:
            continue
        m = world(i)
        tris = []
        for prim in gltf["meshes"][n["mesh"]]["primitives"]:
            pos = np.array(read_accessor(gltf, blob, prim["attributes"]["POSITION"]))
            pos = (m[:3, :3] @ pos.T).T + m[:3, 3]
            if "indices" in prim:
                idx = np.array(read_accessor(gltf, blob, prim["indices"])).reshape(-1)
            else:
                idx = np.arange(len(pos))
            tris.append(pos[idx].reshape(-1, 3, 3))
        out[n.get("name", "nod%d" % i)] = np.concatenate(tris)
    return out


# --- deck -----------------------------------------------------------------------

def deck(path, half=4.6, limit=-0.05, parapet="Viaduct_Parapet", band=(4.7, 5.3)):
    nodes = gather_nodes(path)
    ok = True
    print(os.path.basename(path), "| banda drumului |x| <= %.2f m, limita Y <= %.2f" % (half, limit))
    worst = -1e9
    rest = []
    for name, tris in sorted(nodes.items()):
        if name == parapet:
            continue
        rest.append(tris)
        bm = td.band_max(tris, -half, half)
        v = tris.reshape(-1, 3)
        sel = np.abs(v[:, 0]) <= half
        vm = float(v[sel, 1].max()) if sel.any() else float("nan")
        flag = "  !! PESTE" if bm > limit else ""
        fmt = lambda v: ("%8.3f" % v) if np.isfinite(v) and v > -1e8 else "   (gol)"
        print("  %-22s deck_max %s   vert_max %s%s" % (name, fmt(bm), fmt(vm), flag))
        worst = max(worst, bm)
    print("deck_max %.3f" % worst)
    if worst > limit:
        print("   !! ceva in afara de %s trece peste Y = %.2f in |x| <= %.2f" % (parapet, limit, half))
        ok = False
    top = td.top_surface(np.concatenate(rest), half)
    cov = float(np.isfinite(top).mean())
    if np.isfinite(top).any():
        print("tablier sub banda: top %.3f .. %.3f, acoperire %.1f%%" % (
            np.nanmin(top), np.nanmax(top), 100 * cov))
    if cov < 0.99:
        print("   !! tablierul nu acopera banda (%.1f%% < 99%%)" % (100 * cov))
        ok = False
    if parapet not in nodes:
        print("   !! lipseste nodul %s" % parapet)
        ok = False
    else:
        v = nodes[parapet].reshape(-1, 3)
        for side, sel in (("-X", v[:, 0] < 0), ("+X", v[:, 0] > 0)):
            if not sel.any():
                print("   !! parapetul lipseste pe %s" % side)
                ok = False
                continue
            ax = np.abs(v[sel, 0])
            top_y = float(v[sel, 1].max())
            print("parapet %s: |x| %.3f .. %.3f, sus %.3f m, lungime %.2f m" % (
                side, ax.min(), ax.max(), top_y, v[sel, 2].max() - v[sel, 2].min()))
            if ax.min() < band[0] - 0.005 or ax.max() > band[1] + 0.005:
                print("   !! parapetul iese din %.2f..%.2f" % band)
                ok = False
            if not (0.85 <= top_y <= 0.95):
                print("   !! parapetul are %.3f m, nu ~0,9" % top_y)
                ok = False
    print("CONTRACT DRUM %s" % ("OK" if ok else "INCALCAT"))
    return ok


# --- gap ------------------------------------------------------------------------

def _lateral(occ, x0, band):
    step = mg.STEP
    b0 = max(int(band[0] / step), 0)
    b1 = int(band[1] / step)
    blocked = occ[:, b0:b1 + 1].any(axis=1)
    c0 = int((0.0 - x0) / step)
    if blocked[c0]:
        return 0.0, 0.0, 0.0, None
    l = c0
    while l > 0 and not blocked[l - 1]:
        l -= 1
    r = c0
    while r < occ.shape[0] - 1 and not blocked[r + 1]:
        r += 1
    return (r - l + 1) * step, x0 + l * step, x0 + (r + 1) * step, (l, r)


def _clear_over(occ, y0, cols, above):
    step = mg.STEP
    b1 = int(above / step)
    best = 1e9
    for ix in cols:
        hit = np.nonzero(occ[ix, b1 + 1:])[0]
        best = min(best, y0 + (b1 + 1 + (hit[0] if len(hit) else occ.shape[1])) * step)
    return float(best)


def gap(path, rect, crown=None, floor=None):
    tris = np.concatenate(list(gather_nodes(path).values()))
    if floor is not None:
        tris = tris[tris[:, :, 1].max(axis=1) >= floor]
    occ, x0, y0 = mg.raster(tris)
    ok = True
    print(os.path.basename(path), "| proiectie pe planul fetei, grila %.2f m, floor %s" % (mg.STEP, floor))
    windows = [("caroserie 0,15-2,0", (0.15, 2.0)), ("0-2,0", (0.0, 2.0)),
               ("la 1 m", (1.0, 1.05)), ("la 4 m", (4.0, 4.05)), ("la 6 m", (6.0, 6.05)),
               ("la 8 m", (8.0, 8.05)), ("la 10 m", (10.0, 10.05)),
               ("contract 0-%.1f" % rect[1], (0.0, rect[1]))]
    res = {}
    for label, band in windows:
        g, xl, xh, lr = _lateral(occ, x0, band)
        res[label] = (g, xl, xh, lr)
        print("  %-20s gol %6.2f m  (x %6.2f .. %6.2f)" % (label, g, xl, xh))
    g, xl, xh, lr = res["caroserie 0,15-2,0"]
    if lr:
        cm = _clear_over(occ, y0, range(lr[0], lr[1] + 1), 2.0)
        print("  inaltime libera pe golul caroseriei: min %.2f m" % cm)
    c0 = int((0.0 - x0) / mg.STEP)
    half = int(0.5 / mg.STEP)
    center = _clear_over(occ, y0, range(c0 - half, c0 + half + 1), 2.0)
    print("crown %.2f   (inaltimea libera la mijloc, |x| <= 0,5)" % center)
    gc = res["contract 0-%.1f" % rect[1]][0]
    print("gap_rect %.2f  (dreptunghi cerut %.1f x %.1f)" % (gc, rect[0], rect[1]))
    if gc < rect[0]:
        print("   !! golul pe 0-%.1f m are %.2f < %.2f" % (rect[1], gc, rect[0]))
        ok = False
    if crown is not None and center < crown:
        print("   !! cheia/buiandrugul la %.2f < %.2f" % (center, crown))
        ok = False
    print("CONTRACT GOL %s" % ("OK" if ok else "INCALCAT"))
    return ok


# --- sabotage -------------------------------------------------------------------

def sabotage(src, dst, node, translate=None, scale=None):
    with open(src, "rb") as fh:
        data = fh.read()
    gltf, blob, _, _ = load_glb(src)
    hit = False
    for n in gltf["nodes"]:
        if n.get("name") == node:
            hit = True
            if translate:
                t = n.get("translation", [0.0, 0.0, 0.0])
                n["translation"] = [t[k] + translate[k] for k in range(3)]
            if scale:
                n["scale"] = list(scale)
    if not hit:
        sys.exit("nu exista nodul %s" % node)
    js = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    js += b" " * ((4 - len(js) % 4) % 4)
    bin_pad = blob + b"\0" * ((4 - len(blob) % 4) % 4)
    out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(bin_pad))
    out += struct.pack("<II", len(js), 0x4E4F534A) + js
    out += struct.pack("<II", len(bin_pad), 0x004E4942) + bin_pad
    with open(dst, "wb") as fh:
        fh.write(out)
    print("sabotaj scris: %s (%s: translate %s scale %s)" % (dst, node, translate, scale))


def _vec(a):
    return tuple(float(v) for v in a.split("=", 1)[1].split(","))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    mode = sys.argv[1]
    pos = [a for a in sys.argv[2:] if not a.startswith("--")]
    opt = [a for a in sys.argv[2:] if a.startswith("--")]
    if mode == "deck":
        kw = {}
        for a in opt:
            if a.startswith("--half="):
                kw["half"] = float(a[7:])
            elif a.startswith("--limit="):
                kw["limit"] = float(a[8:])
            elif a.startswith("--parapet="):
                kw["parapet"] = a[10:]
        sys.exit(0 if deck(pos[0], **kw) else 1)
    elif mode == "gap":
        rect, crown, floor = (10.0, 10.5), None, None
        for a in opt:
            if a.startswith("--rect="):
                rect = _vec(a)
            elif a.startswith("--crown="):
                crown = float(a[8:])
            elif a.startswith("--floor="):
                floor = float(a[8:])
        sys.exit(0 if gap(pos[0], rect, crown, floor) else 1)
    elif mode == "sabotage":
        node, tr, sc = None, None, None
        for a in opt:
            if a.startswith("--node="):
                node = a[7:]
            elif a.startswith("--translate="):
                tr = _vec(a)
            elif a.startswith("--scale="):
                sc = _vec(a)
        sabotage(pos[0], pos[1], node, tr, sc)
    else:
        sys.exit(__doc__)
