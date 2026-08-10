"""Kitul alpin — CONIFERELE (#222).

  Pine_A  trees/alpine_pines.glb   ~2.6 x 2.6 x 7 m   <= 400
  Pine_B  (acelasi GLB)            ~3.2 x 3.2 x 10 m  <= 500
  Pine_C  (acelasi GLB)            ~3.8 x 3.8 x 13 m  <= 600
  Pine_D  (acelasi GLB)            ~2.2 x 2.2 x 5 m   <= 300  (pui, tufa de sub)

Trei variante de talie plus un pui, ca padurea sa aiba silueta neregulata:
un rand de conifere identice citeste ca gard de brazi de Craciun. Toate in
ACELASI GLB, copii directi ai radacinii — vezi §"GLB-uri cu variante" din
blender_export.md; asa TrackDecor le poate alege cu `pick_from_glb`.

DE CE CONURI SUPRAPUSE, si nu un con: un molid are etaje de crengi, iar
silueta lui reala e o stiva de conuri care se ingusteaza spre varf. Un
singur con da un brad de plastic. Doua-patru etaje sunt destule la 60 km/h
(style_bible §3: fara detaliu de frecventa inalta) si costa ~3x mai putin
decat crengile individuale.

INALTIMEA E DERIVATA, NU ALEASA. Plafonul din frustumul lui ChaseCamera
(vezi memoria "inaltimea-obiectelor-si-camera") cere ca un obiect lipit de
drum sa nu depaseasca ~12 m, altfel varful iese din cadru si obiectul devine
un zid. Pinul mare (13 m) e DELIBERAT peste plafon: el nu se pune langa
asfalt, ci pe flancuri si in banda departata, unde distanta il aduce inapoi
in cadru. Cine il pune la 2 m de sosea greseste, si se vede imediat.

CULOAREA: verdele conifer nu are slot propriu in atlas (24..31 raman
magenta, vezi kit-alpin). CACTUS_GREEN e verde oliv sters — exact tenta unui
molid batut de vant la altitudine — iar tint_gradient il duce spre inchis la
baza (unde crengile se umbresc reciproc) si spre deschis la varf (unde
lujerii tineri prind soare). WOOD pentru trunchi.
"""

import math

# Talia si numarul de etaje. Raportul inaltime/latime (~2.7) e cel al unui
# molid de munte, nu al unui pin mediteraneean — la altitudine coroana e
# ingusta fiindca zapada trebuie sa alunece de pe ea.
PINES = (
    # nume,    h_total, r_baza, etaje, trunchi_h, seed
    ("Pine_A",  7.0,   1.30,  3,  1.15,  5),
    ("Pine_B", 10.0,   1.60,  4,  1.45, 13),
    ("Pine_C", 13.0,   1.90,  4,  1.80, 23),
    ("Pine_D",  5.0,   1.10,  2,  0.80, 31),
)


def build_pine(h_total, r_base, tiers, trunk_h, seed):
    b = Builder()
    # Trunchiul: se subtiaza vizibil (0.55x sus). Un cilindru drept citeste a
    # stalp, iar la un copac tocmai conicitatea spune "e viu".
    r_trunk = r_base * 0.115
    b.frustum((0.0, 0.0, trunk_h * 0.5), r_trunk, r_trunk * 0.55,
              trunk_h, WOOD, segments=6)

    # Etajele de crengi: conuri care se suprapun pe verticala.
    #
    # Suprapunerea (0.34 din inaltimea etajului) NU e ornament: fara ea, intre
    # conuri raman inele de trunchi gol si copacul citeste ca o stiva de palarii.
    # Cu ea, silueta e continua si crestaturile dintre etaje se vad doar in
    # contur — exact cum arata un molid.
    canopy_h = h_total - trunk_h
    tier_h = canopy_h / (tiers - 0.34 * (tiers - 1))
    z = trunk_h
    for i in range(tiers):
        t = i / float(max(tiers - 1, 1))
        # Raza scade spre varf; ultimul etaj se termina in ascutis (r_top=0).
        r_bot = r_base * (1.0 - 0.42 * t)
        r_top = r_bot * (0.0 if i == tiers - 1 else 0.34)
        # Segmente PUTINE si impare (7): fatetele late sunt intentia
        # (style_bible §3), iar numarul impar rupe simetria stanga-dreapta
        # care, la doi copaci vecini, se citeste ca acelasi model copiat.
        segs = 7 if i % 2 == 0 else 6
        b.frustum((0.0, 0.0, z + tier_h * 0.5), r_bot, r_top, tier_h,
                  CACTUS_GREEN, segments=segs)
        z += tier_h * 0.66
    return b


# ------------------------------------------------------------------ build
AO_PINE = dict(samples=20, dist=2.0, gradient="vertical", low=0.42, high=1.0,
               power=0.85, floor=0.16)

clear_built("Pine")
pine_objs = []
for name, h_total, r_base, tiers, trunk_h, seed in PINES:
    b = build_pine(h_total, r_base, tiers, trunk_h, seed)
    obj = b.to_object(name)
    # Bevel MIC (0.02): la un con de 2 m diametru, o tesitura mai mare rotunjeste
    # varfurile de etaj si coniferul isi pierde exact ce il face conifer.
    stats = finish(obj, bevel=0.02, bevel_angle=40.0, ao=AO_PINE,
                   smooth_angle=50.0)
    # Baza spre umbra rece (crengile de jos stau in propria umbra), varful spre
    # lujer tanar — acelasi tratament ca la AlpineShrub, si din acelasi motiv:
    # fara el masa verde e plata si padurea citeste ca fetru.
    tint_gradient(obj, base=(0.46, 0.56, 0.46), tip=(1.08, 1.02, 0.82))
    me = obj.data
    dims = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices)
            for i in range(3)]
    print("%-8s %5d tris | %.1f x %.1f x %.1f m | AO %.2f..%.2f"
          % (name, stats["tris"], dims[0], dims[1], dims[2],
             stats["ao_min"], stats["ao_max"]))
    obj.location = (0.0, 0.0, 0.0)
    pine_objs.append(obj)

print("GLB:   %s (%d B)" % export_glb(pine_objs, "trees/alpine_pines.glb"))
print("BLEND: %s (%d B)" % save_blend(pine_objs, "alpine_pines.blend"))
