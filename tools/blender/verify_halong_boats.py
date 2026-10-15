"""Orientarea si cotele barcilor Ha Long, masurate pe GLB.

    python tools/blender/verify_halong_boats.py
    python tools/blender/verify_halong_boats.py --sabotaj

EXISTA FIINDCA AM SCOS O ASERTIUNE
----------------------------------
`verify_halong.sh` rula initial jonca si sampanul cu `--front=-Z`, adica o
asertiune DURA pe orientare. Am trecut-o pe `--origin=waterline`, fiindca
`--front` nu se poate aplica unei carene: testul din `verify_glb.py` compara
ARIA fetelor orientate pe X cu cea pe Z (verify_glb.py:388-390), iar la o barca
bordurile lungi privesc pe +/-X si capetele ascutite pe +/-Z. O barca CORECT
orientata raporteaza deci mereu "plan dominant X" si pica.

Dar brief §1.4 cere explicit "prova pe +Y Blender (= -Z Godot)", iar pe Machu
Picchu orientarea greita a unui tren a costat o runda intreaga (memoria
`machu-picchu-assets-kit`). Deci contractul rtamane, si trebuie masurat ALTFEL —
nu pe arie, ci pe GEOMETRIE:

  1. LUNGIMEA e pe Z, nu pe X. O barca rotita 90° ar avea lungimea pe X, si
     asta prinde exact accidentul de care se teme brief-ul.
  2. PROVA e ASCUTITA si e pe -Z Godot. Masurat: semilatimea maxima a carenei
     in treimea dinspre -Z fata de cea din treimea dinspre +Z. La o barca,
     prova (ascutita) e mult mai ingusta decat pupa (lata), deci raportul
     spune in ce sens sta.
  3. COTELE din tabelul brief §1.4: jonca 12 m, sampanul 7 m, barca-cos 2 m.
     Masurate pe GLB, cu toleranta de 5%.

Un GLB Godot are Y in sus si -Z "inainte"; exportul din Blender face deja
rotatia (Blender +Y -> Godot -Z), deci masuratoarea de aici e pe axele GODOT.

Garda se ARMEAZA cu `--sabotaj`: roteste virtual barcile 90° si verifica ca
testul pica. Fara asta, o garda care trece mereu nu masoara nimic (memoria
`garda-fara-linie-de-baza-iese-zero`).
"""

import json
import os
import struct
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")

# piesa -> (lungime ceruta in m, toleranta fractionala)
CONTRACT = {
    "fishing_junk": (12.0, 0.05),
    "sampan_a": (7.0, 0.05),
    "basket_boat": (2.0, 0.08),   # un cos rotund: toleranta mai larga
}

# Barca-cos e ROTUNDA, deci n-are prova si nu intra in testele de orientare.
ROUND = {"basket_boat"}


def read_positions(path):
    """Toate pozitiile din GLB, in coordonate Godot (Y sus, -Z inainte)."""
    d = open(path, "rb").read()
    j_len = struct.unpack("<I", d[12:16])[0]
    j = json.loads(d[20:20 + j_len])
    bin_off = 20 + j_len + 8
    out = []
    for mesh in j["meshes"]:
        for prim in mesh["primitives"]:
            acc = j["accessors"][prim["attributes"]["POSITION"]]
            view = j["bufferViews"][acc["bufferView"]]
            off = bin_off + view.get("byteOffset", 0) + acc.get("byteOffset", 0)
            for i in range(acc["count"]):
                x, y, z = struct.unpack_from("<3f", d, off + i * 12)
                out.append((x, y, z))
    return out


def measure(pts, flip=False):
    """Cotele si forma. Cu `flip`, schimba X si Z — sabotajul care simuleaza o
    piesa rotita 90°."""
    if flip:
        pts = [(z, y, x) for x, y, z in pts]
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    zs = [p[2] for p in pts]
    span_x, span_z = max(xs) - min(xs), max(zs) - min(zs)
    # Semilatimea la CAPETE, pe o felie subtire (12% din lungime), nu pe o
    # treime. Prima versiune lua maximul pe treimea dinspre fiecare capat si
    # raporta 0,95 pe o carena corecta: treimea dinspre prova include si zona
    # lata de la mijlocul navei, deci masura semilatimea MAXIMA a corpului, nu
    # ascutimea capatului. Masurat pe felii de 1 m, jonca are semilatime 0,00
    # la Z=-6,00 (prova in punct) si 1,43 la +5..+6 (pupa lata) — adica forma
    # era corecta si testul se uita in locul greit (memoria
    # `caseta-de-masura-exclude-defectul`).
    z_lo, z_hi = min(zs), max(zs)
    cut = (z_hi - z_lo) * 0.12
    bow = [abs(p[0]) for p in pts if p[2] <= z_lo + cut]
    stern = [abs(p[0]) for p in pts if p[2] >= z_hi - cut]
    return {
        "len_z": span_z, "span_x": span_x,
        "y_lo": min(ys), "y_hi": max(ys),
        "bow_half": max(bow) if bow else 0.0,
        "stern_half": max(stern) if stern else 0.0,
    }


def check(name, flip=False):
    path = os.path.join(ROOT, "assets", "models", "halong", "vehicles",
                        name + ".glb")
    if not os.path.isfile(path):
        print("  %-18s LIPSESTE" % name)
        return False
    m = measure(read_positions(path), flip=flip)
    want, tol = CONTRACT[name]
    ok = True
    print("  %s" % name)
    print("    lungime pe Z    %6.2f m   (cerut %.2f +/- %.0f%%)"
          % (m["len_z"], want, tol * 100))
    if abs(m["len_z"] - want) > want * tol:
        print("    !! lungimea nu respecta contractul brief §1.4")
        ok = False
    # 1. lungimea pe Z, nu pe X — doar la barcile ALUNGITE. O barca-cos e
    #    rotunda (X = Z prin definitie), deci "lungimea pe Z" n-are inteles
    #    pentru ea si testul ar da un fals negativ garantat.
    print("    Z vs X          %6.2f vs %5.2f m" % (m["len_z"], m["span_x"]))
    if name not in ROUND and m["len_z"] <= m["span_x"]:
        print("    !! lungimea NU e pe Z — piesa pare rotita 90° "
              "(brief §1.4: prova pe -Z Godot)")
        ok = False
    # 2. prova ascutita pe -Z
    if name not in ROUND:
        r = m["bow_half"] / max(m["stern_half"], 1e-6)
        print("    prova/pupa      %6.2f     (prag <= 0.80: prova ASCUTITA pe -Z)"
              % r)
        if r > 0.80:
            print("    !! capatul dinspre -Z nu e mai ingust decat cel dinspre "
                  "+Z: prova pe partea greita?")
            ok = False
    # 3. incaleca linia apei
    print("    linia apei      %+.2f .. %+.2f m" % (m["y_lo"], m["y_hi"]))
    if m["y_lo"] > -0.01 or m["y_hi"] < 0.01:
        print("    !! nu incaleca Y=0: o barca trebuie sa aiba chila sub apa")
        ok = False
    return ok


if __name__ == "__main__":
    sabotaj = "--sabotaj" in sys.argv
    if sabotaj:
        # Sabotajul: aceleasi piese, dar cu X si Z schimbate. Daca testul tot
        # trece, nu masoara orientarea.
        bad = 0
        # Barca-cos e exclusa din sabotaj: fiind rotunda, un flip X<->Z o lasa
        # IDENTICA, deci n-ar putea pica nici daca garda ar fi stricata.
        for n in CONTRACT:
            if n in ROUND:
                continue
            if not check(n, flip=True):
                bad += 1
        print()
        if bad:
            print("SABOTAJ: a picat pe %d piese, cum trebuie" % bad)
            raise SystemExit(0)
        print("SABOTAJ N-A PRINS: garda de orientare nu masoara nimic")
        raise SystemExit(1)

    print("== orientarea si cotele barcilor (brief §1.4) ==")
    bad = 0
    for n in CONTRACT:
        if not check(n):
            bad += 1
    print()
    print("VERDICT BARCI: %s" % ("OK" if not bad else "PICAT"))
    raise SystemExit(1 if bad else 0)
