"""Verifica un GLB fata de contractul din docs/blender_export.md.

Independent de Blender si de Godot — citeste direct containerul glTF, ca sa
confirme ce a ajuns efectiv in fisier, nu ce credem ca am exportat.

Verifica:
  1. numele nodurilor (Godot cauta noduri dupa nume, ex. "Blades")
  2. numarul de triunghiuri fata de buget
  3. UV-urile: toate colapsate pe centre de slot din atlas -> ce sloturi foloseste
  4. sloturile sunt LEGALE (0-13). 14-16 sunt accente de masina, 17-31 se
     randeaza magenta in joc — vezi LEGAL_SLOTS mai jos.
     Piesele declarate cu --class-parts= poarta o textura de CLASA
     (assets/textures/classes/), deci au UV-uri REALE si nu li se aplica
     regula slotului. Pe ele verificarea se inverseaza: UV-urile trebuie sa
     ACOPERE o suprafata. Colapsate, ar citi un singur texel si textura ar fi
     invizibila — vezi style_bible §13.6, bug-ul care a costat trei luni.
  5. COLOR_0 prezent (AO copt) + intervalul de valori
  6. bounding box: originea la baza (min Y ~ 0), centrata in XZ. Cu
     --origin=center se cere in schimb bbox centrat pe Y (obiecte care se
     rostogolesc — exceptia declarata din #45). Cu --origin=assembly se verifica
     doar ca ANSAMBLUL atinge solul: piesele unui obiect compus (arcada din #C1)
     isi pastreaza pozitiile relative, deci traversa chiar pluteste la 9 m
  7. orientarea: pe ce parte sta masa geometriei (avertisment; cu --front=-Z
     devine aserttiune dura)

Rulare:
    python tools/blender/verify_glb.py assets/models/cactus.glb [buget_tris]
    python tools/blender/verify_glb.py assets/models/route66_sign.glb 260 --front=-Z
    python tools/blender/verify_glb.py assets/models/boulder_roller.glb 220 --origin=center
    python tools/blender/verify_glb.py assets/models/rock_arch.glb 1000 --origin=assembly
    python tools/blender/verify_glb.py assets/models/windmill.glb 3000 \
        --class-parts=Mill_Wood,Mill_Metal,Blades
"""

import json
import struct
import sys
import os

SLOTS = 32
SLOT_NAMES = [
    "sand_light", "sand_mid", "sand_shadow", "rock_light", "rock_dark",
    "asphalt", "asphalt_edge", "kerb_red", "concrete", "wood_weathered",
    "rust_metal", "painted_metal", "cactus_green", "dry_vegetation",
    "car_red", "car_blue", "car_yellow",
    "reef_shallow", "sea_deep", "coral_sand", "volcanic_black",
    "tropical_green", "foam_white", "tile_terracotta",
]

# Sloturile pe care le poate folosi un asset de decor.
#
# 14-16 sunt accentele de masina (scripts/palette.gd:43 le declara explicit
# interzise in decor: masinile trebuie sa ramana singurele suprafete saturate
# din cadru, style_bible §1). 24-31 nu sunt definite — atlasul le lasa
# INTENTIONAT magenta (tools/generate_palette_atlas.gd, _base_color), ca o
# greseala de UV sa sara in ochi.
#
# Pana la garda asta, un asset care cauta o culoare pe care paleta n-o are
# (sticla, metal inchis) nimerea slotul 17, trecea verificarea cu OK si ajungea
# magenta in joc. Nimic nu-l prindea inainte de primul screenshot.
#
# Intervalul legal e discontinuu de cand mediul insular (17-23) a ocupat din
# rezerva: 0-13 desert, GAURA la 14-16 pentru masini, 17-23 insula. De-asta e
# frozenset, nu range — un `range(0, 24)` ar fi legalizat in tacere accentele
# de masina in decor.
LEGAL_SLOTS = frozenset(list(range(0, 14)) + list(range(17, 24)))
CAR_SLOTS = frozenset(range(14, 17))

COMPONENT = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
             5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load_glb(path):
    with open(path, "rb") as fh:
        data = fh.read()
    magic, version, _ = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, "nu e un GLB valid"
    off, js, bin_chunk = 12, None, b""
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(chunk.decode("utf-8"))
        elif ctype == 0x004E4942:
            bin_chunk = chunk
        off += 8 + clen + ((4 - clen % 4) % 4 if clen % 4 else 0)
    return js, bin_chunk, len(data), version


def read_accessor(gltf, blob, index):
    acc = gltf["accessors"][index]
    fmt, size = COMPONENT[acc["componentType"]]
    n = NCOMP[acc["type"]]
    count = acc["count"]
    if "bufferView" not in acc:
        return [(0,) * n] * count
    bv = gltf["bufferViews"][acc["bufferView"]]
    base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride") or size * n
    out = []
    for i in range(count):
        out.append(struct.unpack_from("<" + fmt * n, blob, base + i * stride))
    return out


def slot_problem(slot):
    """Motivul pentru care un slot e ilegal, sau None daca e in regula."""
    if slot in LEGAL_SLOTS:
        return None
    if slot in CAR_SLOTS:
        return "REZERVAT MASINILOR"
    return "NEDEFINIT -> MAGENTA IN JOC"


def is_class_part(name, class_parts):
    """Piesa e declarata ca purtatoare de textura de CLASA (UV-uri reale)?"""
    return any(name.startswith(p) for p in class_parts)


def verify(path, budget=None, front=None, origin="base", class_parts=()):
    gltf, blob, total, version = load_glb(path)
    print("=" * 74)
    print("%s  —  %d B, glTF v%d" % (os.path.basename(path), total, version))
    print("=" * 74)

    nodes = gltf.get("nodes", [])
    print("Noduri: %s" % ", ".join("%s" % n.get("name", "?") for n in nodes))

    grand_total = 0
    ok = True
    assembly_lo = 1e9   # cel mai jos punct din TOT fisierul (pentru origin=assembly)

    for node in nodes:
        if "mesh" not in node:
            continue
        mesh = gltf["meshes"][node["mesh"]]
        name = node.get("name", mesh.get("name", "?"))
        tris = 0
        slots_used = set()
        uv_lo, uv_hi = [1e9, 1e9], [-1e9, -1e9]
        col_lo, col_hi = 1e9, -1e9
        has_color = False
        xs, ys, zs = [], [], []

        area = {"+X": 0.0, "-X": 0.0, "+Y": 0.0, "-Y": 0.0, "+Z": 0.0, "-Z": 0.0}

        for prim in mesh["primitives"]:
            attrs = prim["attributes"]
            pos = read_accessor(gltf, blob, attrs["POSITION"])
            if "indices" in prim:
                idx = [i[0] for i in read_accessor(gltf, blob, prim["indices"])]
            else:
                idx = list(range(len(pos)))
            tris += len(idx) // 3

            for p in pos:
                xs.append(p[0]); ys.append(p[1]); zs.append(p[2])

            # Aria proiectata pe fiecare semiaxa. Produsul vectorial e deja
            # scalat cu aria (|a x b| = 2*aria), deci componentele lui insumate
            # dau exact proiectia — fara normalizari si fara atributul NORMAL,
            # care poate lipsi din GLB.
            for t in range(0, len(idx) - 2, 3):
                a, b, c = pos[idx[t]], pos[idx[t + 1]], pos[idx[t + 2]]
                u1 = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
                v1 = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
                n = (u1[1] * v1[2] - u1[2] * v1[1],
                     u1[2] * v1[0] - u1[0] * v1[2],
                     u1[0] * v1[1] - u1[1] * v1[0])
                for k, axis in enumerate("XYZ"):
                    if n[k] >= 0.0:
                        area["+" + axis] += n[k] * 0.5
                    else:
                        area["-" + axis] -= n[k] * 0.5

            if "TEXCOORD_0" in attrs:
                for u, v in read_accessor(gltf, blob, attrs["TEXCOORD_0"]):
                    slot = round(u * SLOTS - 0.5)
                    exact = abs((slot + 0.5) / SLOTS - u) < 1e-4
                    slots_used.add((slot, exact))
                    uv_lo[0] = min(uv_lo[0], u); uv_hi[0] = max(uv_hi[0], u)
                    uv_lo[1] = min(uv_lo[1], v); uv_hi[1] = max(uv_hi[1], v)

            if "COLOR_0" in attrs:
                has_color = True
                for c in read_accessor(gltf, blob, attrs["COLOR_0"]):
                    val = c[0] / 65535.0 if isinstance(c[0], int) else c[0]
                    col_lo, col_hi = min(col_lo, val), max(col_hi, val)

        grand_total += tris
        flag = ""
        if budget is not None:
            flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
            if tris > budget:
                ok = False
        print("\n  %s: %d tris%s" % (name, tris, flag))

        # Piesele cu textura de CLASA au UV-uri REALE (proiectie cubica), deci
        # "u pe centrul unui slot" nu li se aplica — pe ele verificarea se
        # inverseaza: UV-urile trebuie sa ACOPERE o suprafata, nu sa fie
        # colapsate. Un UV colapsat pe o piesa texturata e exact bug-ul din
        # style_bible §13.6: derivata zero, un singur texel citit, textura
        # invizibila. Fara modul asta, garda ar urla la fiecare asset pe clase
        # si oamenii ar invata s-o ignore — ceea ce e mai rau decat sa n-o ai.
        if is_class_part(name, class_parts):
            span_u, span_v = uv_hi[0] - uv_lo[0], uv_hi[1] - uv_lo[1]
            if not slots_used:
                print("    UV clasa   : FARA UV!")
                ok = False
            elif min(span_u, span_v) < 0.02:
                print("    UV clasa   : COLAPSATE (u %.4f, v %.4f) -> textura "
                      "de clasa ar citi UN texel" % (span_u, span_v))
                ok = False
            else:
                print("    UV clasa   : reale, u %.2f..%.2f  v %.2f..%.2f"
                      % (uv_lo[0], uv_hi[0], uv_lo[1], uv_hi[1]))
        else:
            names = []
            illegal = []
            for slot, exact in sorted(slots_used):
                label = (SLOT_NAMES[slot] if 0 <= slot < len(SLOT_NAMES)
                         else "slot%d" % slot)
                names.append(label if exact else "%s(NECENTRAT!)" % label)
                if not exact:
                    ok = False
                why = slot_problem(slot)
                if why:
                    illegal.append((slot, label, why))
            print("    sloturi UV : %s" % (", ".join(names) or "FARA UV!"))
            if not slots_used:
                ok = False
            for slot, label, why in illegal:
                print("    !! slot %d (%s) ILEGAL in decor: %s"
                      % (slot, label, why))
                ok = False

        if has_color:
            print("    COLOR_0    : da, AO %.3f .. %.3f" % (col_lo, col_hi))
        else:
            print("    COLOR_0    : LIPSESTE (AO necopt)")
            ok = False

        tr = node.get("translation", [0.0, 0.0, 0.0])
        print("    bbox X     : %.3f .. %.3f  (centru %+.3f)" % (min(xs), max(xs), (min(xs) + max(xs)) / 2))
        print("    bbox Y     : %.3f .. %.3f  (inaltime %.2f m)" % (min(ys), max(ys), max(ys) - min(ys)))
        print("    bbox Z     : %.3f .. %.3f  (centru %+.3f)" % (min(zs), max(zs), (min(zs) + max(zs)) / 2))
        # Ansamblul se masoara in LUME (bbox + pivot) si INAINTE de lantul de
        # mai jos, nu ca ramura a lui.
        #
        # Era ascuns intr-un `elif` dupa "nodul are pivot propriu", deci un
        # ansamblu ale carui piese au TOATE pivot — exact ce produce
        # `finish(origin="base_axis")` urmat de `obj.location.z = min_z`, adica
        # tiparul folosit de casa de sat incoace — nu ajungea niciodata la
        # verificare si iesea cu "niciun nod cu mesh". O garda care raporteaza
        # ca n-are ce masura, in loc sa masoare, e mai rea decat lipsa ei:
        # arata rosu din alt motiv decat cel adevarat.
        if origin == "assembly":
            assembly_lo = min(assembly_lo, min(ys) + tr[1])
        if any(abs(c) > 1e-6 for c in tr):
            # nod cu pivot propriu (ex. roata morii): coordonatele de mai sus sunt
            # relative la pivot, deci regula "baza la Y=0" nu i se aplica
            print("    pivot      : (%.3f, %.3f, %.3f)  -> in lume Y %.3f .. %.3f"
                  % (tr[0], tr[1], tr[2], min(ys) + tr[1], max(ys) + tr[1]))
        elif origin == "center":
            # Exceptia declarata din #45: obiectul care se rostogoleste. Verificam
            # ce trebuie chiar verificat — bbox-ul centrat pe Y — in loc sa lasam
            # asset-ul cu verdict rosu permanent. O garda despre care stim
            # dinainte ca pica nu mai e o garda: data viitoare cand pica din alt
            # motiv, nimeni nu se uita.
            off = (min(ys) + max(ys)) / 2
            if abs(off) > max(0.01, (max(ys) - min(ys)) * 0.02):
                print("    !! origine ceruta in centru, dar bbox Y e decentrat "
                      "cu %+.3f — exportat cu originea la baza?" % off)
                ok = False
            else:
                print("    origine   : centru confirmat (bbox Y %+.3f, cerut ~0)" % off)
        elif origin == "assembly":
            # Ansamblu cu ORIGINE COMUNA: mai multe noduri care formeaza un
            # singur obiect si trebuie sa-si pastreze pozitiile relative (arcada
            # din #C1: doua picioare, o traversa, doua proxy-uri de coliziune).
            # Regula "baza la Y=0" per nod ar fi gresita — traversa chiar
            # pluteste la 9 m, ala e tot rostul ei. Ce se verifica in schimb e ca
            # ANSAMBLUL atinge solul (acumulat mai sus, in lume).
            pass
        elif abs(min(ys)) > 0.01:
            print("    !! baza nu e la Y=0 (min Y = %.3f)" % min(ys))
            ok = False

        # Centrarea in XZ: se printa de la inceput, dar nu se verifica niciodata.
        # Ramane AVERTISMENT, nu eroare: `finish(origin="base_axis")` decentreaza
        # intentionat (un semn a carui origine trebuie sa stea pe axa stalpului),
        # iar la un ansamblu piesele individuale sunt decentrate prin definitie.
        for axis, vals in (("X", xs), ("Z", zs)):
            if origin == "assembly":
                break
            span = max(vals) - min(vals)
            center = (min(vals) + max(vals)) / 2
            if span > 1e-6 and abs(center) > max(0.05, span * 0.05):
                print("    ~  necentrat pe %s: centru %+.3f din %.2f m deschidere"
                      % (axis, center, span))

        # Orientarea.
        axis_area = {"X": area["+X"] + area["-X"], "Z": area["+Z"] + area["-Z"]}
        dominant = "X" if axis_area["X"] > axis_area["Z"] else "Z"
        lateral = (axis_area["X"] + axis_area["Z"]) or 1.0
        print("    orientare  : plan dominant %s (%.0f%%) | +X %.1f -X %.1f  +Z %.1f -Z %.1f"
              % (dominant, 100.0 * axis_area[dominant] / lateral,
                 area["+X"], area["-X"], area["+Z"], area["-Z"]))

        if front is not None:
            axis = front[1]
            opposite = {"+": "-", "-": "+"}[front[0]] + axis
            # Aserttiunea DURA e doar pe AXA, si asta e o limitare reala, nu o
            # scurtatura. Semnul nu se poate deduce din geometrie: la ecranul de
            # drive-in scheletul sta in SPATE, deci spatele are mai multa arie
            # decat fata; la benzinarie pompele stau in FATA, deci exact invers.
            # Aceeasi masuratoare ar da verdicte opuse pe doua assets corecte.
            #
            # Ce se poate prinde, si e greseala care chiar se face, e confuzia de
            # AXA — un semn exportat privind pe X in loc de Z, adica rotit 90°.
            # Semnul ramane avertisment.
            if dominant != axis:
                print("    !! fata ceruta %s, dar planul dominant e %s "
                      "(%.1f pe %s vs %.1f pe %s) — model rotit 90°?"
                      % (front, dominant, axis_area[dominant], dominant,
                         axis_area[axis], axis))
                ok = False
            else:
                print("    fata %s     : axa confirmata (%.0f%% din aria laterala)"
                      % (front, 100.0 * axis_area[axis] / lateral))
                if area[front] < area[opposite] * 0.75:
                    print("    ~  atentie: %s are mult mai putina arie decat %s "
                          "(%.1f vs %.1f). Normal daca structura de sprijin e in "
                          "spate; suspect altfel."
                          % (front, opposite, area[front], area[opposite]))

    if origin == "assembly":
        if assembly_lo > 1e8:
            print("\n!! origin=assembly, dar niciun nod cu mesh")
            ok = False
        elif abs(assembly_lo) > 0.01:
            print("\n!! ansamblul nu atinge solul: cel mai jos punct e la Y=%.3f "
                  "— exportat plutind sau ingropat?" % assembly_lo)
            ok = False
        else:
            print("\nansamblu : baza confirmata (cel mai jos punct Y=%.3f), "
                  "piesele isi pastreaza pozitiile relative" % assembly_lo)

    print("\nTOTAL: %d tris" % grand_total)
    print("VERDICT: %s" % ("OK" if ok else "PROBLEME — vezi mai sus"))
    return ok


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]

    front = None
    origin = "base"
    class_parts = ()
    for f in flags:
        if f.startswith("--class-parts="):
            class_parts = tuple(p.strip()
                                for p in f.split("=", 1)[1].split(",")
                                if p.strip())
        elif f.startswith("--front="):
            front = f.split("=", 1)[1].strip().upper()
            if front not in ("+X", "-X", "+Z", "-Z"):
                sys.exit("--front asteapta +X, -X, +Z sau -Z (Y e sus)")
        elif f.startswith("--origin="):
            origin = f.split("=", 1)[1].strip().lower()
            if origin not in ("base", "center", "assembly"):
                sys.exit("--origin asteapta base (implicit), center sau assembly")
        else:
            sys.exit("optiune necunoscuta: %s" % f)

    target = args[0]
    budget = int(args[1]) if len(args) > 1 else None
    sys.exit(0 if verify(target, budget, front, origin, class_parts) else 1)
