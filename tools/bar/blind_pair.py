"""Pune doua imagini una langa alta, FARA etichete, in ordine aleatoare.

De ce exista: criticul trebuie sa aleaga fara sa stie care e a noastra. Daca
imaginile ajung la el pe cai diferite ("asta e captura, asta e referinta"), nu
mai e o alegere oarba — e o cerere de aprobare, si primeste aprobare.

Foloseste:
  python tools/bar/blind_pair.py ours.png ref.png out.png --seed 7
Scrie out.png (panourile A si B, doar literele) si out.png.key cu raspunsul.
Cheia NU se da criticului; se citeste dupa ce a raspuns.
"""
import sys, random, argparse, os
from PIL import Image, ImageDraw

def load_fit(p, h):
    im = Image.open(p).convert("RGB")
    w = int(im.width * h / im.height)
    return im.resize((w, h), Image.LANCZOS)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ours"); ap.add_argument("ref"); ap.add_argument("out")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--height", type=int, default=760)
    a = ap.parse_args()

    rnd = random.Random(a.seed)
    ours = load_fit(a.ours, a.height)
    ref  = load_fit(a.ref,  a.height)

    # ordinea e trasa la sorti: altfel "stanga = a noastra" devine un tipar
    swap = rnd.random() < 0.5
    left, right = (ref, ours) if swap else (ours, ref)
    left_is = "REF" if swap else "OURS"
    right_is = "OURS" if swap else "REF"

    gap, pad, band = 18, 22, 40
    W = left.width + right.width + gap + pad * 2
    H = a.height + band + pad * 2
    sheet = Image.new("RGB", (W, H), (24, 24, 26))
    sheet.paste(left, (pad, pad + band))
    sheet.paste(right, (pad + left.width + gap, pad + band))
    d = ImageDraw.Draw(sheet)
    # doar literele. niciun nume de fisier, niciun indiciu.
    d.text((pad + left.width // 2 - 4, pad + 12), "A", fill=(235, 235, 235))
    d.text((pad + left.width + gap + right.width // 2 - 4, pad + 12), "B",
           fill=(235, 235, 235))
    sheet.save(a.out)

    # Amprenta in NUMELE cheii: doua sonde care scriu in acelasi scratchpad si
    # aleg acelasi nume de iesire isi calcau cheia una alteia, si un critic a
    # judecat captura altuia crezand ca e a lui. Cheia poarta acum hash-ul
    # argumentelor, deci o coliziune se vede in loc sa mintă tăcut.
    import hashlib
    sig = hashlib.sha1(
        ("%s|%s|%d" % (a.ours, a.ref, a.seed)).encode("utf-8")).hexdigest()[:8]
    keypath = "%s.%s.key" % (a.out, sig)

    with open(keypath, "w", encoding="utf-8") as f:
        f.write("A=%s\nB=%s\nours=%s\nref=%s\nseed=%d\n"
                % (left_is, right_is, a.ours, a.ref, a.seed))
    # Si o marca vizibila in sheet, ca sa se poata verifica potrivirea fara cheie.
    d.text((pad, H - 16), sig, fill=(90, 90, 96))
    sheet.save(a.out)

    print("wrote %s (%dx%d)  amprenta %s" % (a.out, W, H, sig))
    print("CHEIA: %s" % keypath)
    print("VERIFICA: amprenta tiparita in coltul din stanga-jos al plansei "
          "trebuie sa fie %s. Daca nu e, plansa nu e a ta." % sig)

if __name__ == "__main__":
    main()
