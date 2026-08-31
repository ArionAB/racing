"""Cat din variatia de valoare pe orizontala se intampla PE MUCHIE?

De ce exista: criticul orb a spus doua runde la rand "model fatetat randat ca si
cum ar fi neted". Geometria era corecta (53/55 hornuri deindexate, normale pe
fata) — semnalul PICTAT peste ea era neted si domina. Cifra de mai jos separa
cele doua cazuri, ceea ce ochiul face instant si o sonda de geometrie nu.

  python tools/bar/facet_edges.py captura.png --box 0.12,0.30,0.25,0.55
  python tools/bar/facet_edges.py captura.png --ref docs/.../B_chimneys.png

Tinta (masurata pe referinta): peste 40% muchii, amplitudine peste 140.
"""
import sys, argparse
from PIL import Image


def analyse(path, box, rows=5):
    im = Image.open(path).convert("L")
    w, h = im.size
    px = im.load()
    x0, x1 = int(box[0] * w), int(box[1] * w)
    y0, y1 = int(box[2] * h), int(box[3] * h)
    out = []
    for k in range(rows):
        y = y0 + (y1 - y0) * k // max(rows - 1, 1)
        row = [px[x, y] for x in range(x0, x1)]
        if len(row) < 8:
            continue
        d = [abs(row[i + 1] - row[i]) for i in range(len(row) - 1)]
        n = len(d)
        edges = sum(1 for v in d if v >= 8) / n * 100.0
        grad = sum(1 for v in d if 1 <= v < 8) / n * 100.0
        flat = sum(1 for v in d if v == 0) / n * 100.0
        # Cate procente din piatra sunt INCHISE. Fara garda asta, muchiile se pot
        # obtine innegrind roca: runda 14 a atins 41.6% muchii cu 23.9% pixeli
        # inchisi, iar conurile citeau a funingine. Referinta are 6.6%.
        dark = sum(1 for v in row if v < 70) / len(row) * 100.0
        # ATENTIE la citirea lui `dark` (runda 15): caseta implicita nu contine
        # numai piatra. Masurat pe captura de la frac 0.06, ea prinde fereastra
        # neagra a conului mare (y~223), palaria de bazalt (y~86) si solul umbrit
        # cu poala de moloz (y~360) — 17.5% din pixelii randurilor sunt lucruri
        # care TREBUIE sa fie inchise. Randurile curate de piatra dau 0.0-6.0%,
        # adica exact cat are referinta (5.7%).
        #
        # Deci un `inchis` de ~17% pe caseta asta NU inseamna funingine; se
        # verifica pe o banda numai de piatra inainte de a acuza pigmentul.
        # Aceeasi lectie ca la muchii: caseta masoara ce e in ea, nu ce crezi.
        out.append((y, edges, grad, flat, max(row) - min(row), dark))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--ref", default=None)
    ap.add_argument("--box", default="0.12,0.30,0.25,0.55",
                    help="l,r,t,b ca fractii din imagine")
    a = ap.parse_args()
    box = [float(v) for v in a.box.split(",")]

    def report(path, label):
        rows = analyse(path, box)
        if not rows:
            print("%s: caseta e prea mica" % label)
            return 0.0, 0.0
        print("%s  (%s)" % (label, path))
        me = ms = 0.0
        md = 0.0
        for y, e, g, f, sp, dk in rows:
            print("   y=%4d  muchii=%5.1f%%  gradient=%5.1f%%  plat=%5.1f%%  "
                  "amplitudine=%3d  inchis=%4.1f%%" % (y, e, g, f, sp, dk))
            me += e; ms += sp; md += dk
        return me / len(rows), ms / len(rows), md / len(rows)

    e, s, dk = report(a.image, "AL NOSTRU")
    if a.ref:
        report(a.ref, "REFERINTA")
    print("")
    print("MEDIA noastra: muchii %.1f%%  amplitudine %.0f  inchis %.1f%%"
          % (e, s, dk))
    ok = e >= 40.0 and s >= 140.0 and dk <= 12.0
    print("VERDICT: %s (tinta: muchii >= 40%%, amplitudine >= 140, "
          "inchis <= 12%% — referinta are 6.6%%)" % ("OK" if ok else "PICAT"))
    if e >= 40.0 and dk > 12.0:
        print("  ATENTIE: muchiile sunt luate prin INNEGRIREA rocii, nu prin "
              "fatetare. Tuful e piatra PALIDA; contrastul se ia din lumina, "
              "nu din funingine.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
