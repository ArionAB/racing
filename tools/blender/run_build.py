"""Ruleaza un build script de asset headless, fara sesiune interactiva.

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_veg_set.py [build_X.py ...]

Un SINGUR script poate primi propriile argumente dupa un AL DOILEA `--`
(Blender nu mai taie nimic dupa primul, deci al doilea ajunge intact in
`sys.argv` — vezi preview_jodhpur.py, care isi citeste argumentele dupa
`--compare`/`--sheet`/`--group`):

    ... -- preview_jodhpur.py -- --compare ghanta_ghar

Cu al doilea `--`, doar UN script se ruleaza (cel dinaintea lui); ambiguu sa
inlantui mai multe build-uri cu argumente separate per script.

Exista fiindca reteta documentata (exec cu globale partajate, vezi
assets/blender/README.md) presupunea consola din Blender sau MCP-ul — adica un
om la butoane. Scriptul asta face exact acelasi exec, cu `__file__` setat pe
dio_lib ca PROJECT sa iasa CHECKOUT-UL CURENT (worktree-ul din care rulezi),
nu un drum absolut incremenit.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

if "--" not in sys.argv:
    raise SystemExit("folosire: blender --background --python run_build.py -- build_X.py ...")
after = sys.argv[sys.argv.index("--") + 1:]
if not after:
    raise SystemExit("niciun build script cerut")

if "--" in after:
    # al doilea `--`: totul dupa el sunt argumentele scriptului, nu alte
    # scripturi de rulat. `sys.argv` ramane setat pentru scriptul executat,
    # ca sa-si citeasca argumentele exact cum ar face un `python x.py -- ...`.
    sep = after.index("--")
    scripts = after[:sep]
    sys.argv = [after[0]] + after[sep:]
else:
    scripts = after

if not scripts:
    raise SystemExit("niciun build script cerut")

for script in scripts:
    path = script if os.path.isabs(script) else os.path.join(HERE, script)
    if not os.path.exists(path):
        raise SystemExit("nu exista: " + path)
    # Globale PROASPETE per script: build-urile nu au voie sa depinda una de
    # starea alteia (clear_built stabilizeaza doar numele de noduri).
    g = {"__name__": "__main__", "__file__": os.path.join(HERE, "dio_lib.py")}
    exec(compile(open(os.path.join(HERE, "dio_lib.py")).read(),
        "dio_lib.py", "exec"), g)
    print("== run_build: %s ==" % os.path.basename(path))
    exec(compile(open(path).read(), os.path.basename(path), "exec"), g)
print("== run_build: gata ==")
