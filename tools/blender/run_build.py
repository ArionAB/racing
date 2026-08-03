"""Runner headless pentru scripturile de build: ruleaza dio_lib + build-uri
intr-un Blender fara interfata, cu acelasi contract ca rularea prin MCP.

    blender --background --factory-startup --python tools/blender/run_build.py \
        -- build_cliff_wall.py [build_butte.py ...]

Scripturile de build NU importa dio_lib — se asteapta ca numele lui (Builder,
finish, export_glb...) sa existe deja in namespace, fiindca prin MCP totul se
executa cu exec() in aceeasi sesiune. Runner-ul reproduce exact acel mediu:
un singur namespace, `__file__` setat pe dio_lib.py ca PROJECT/MODELS sa se
rezolve fata de checkout-ul curent (vezi dio_lib.py:40), apoi build-urile pe
rand. Fiecare script isi face singur curatenie prin clear_built().
"""

import os
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
scripts = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if not scripts:
    raise SystemExit("niciun script de build dat dupa --")

ns = {"__name__": "__main__", "__file__": os.path.join(BASE, "dio_lib.py")}
with open(ns["__file__"], encoding="utf8") as f:
    exec(compile(f.read(), ns["__file__"], "exec"), ns)

for script in scripts:
    path = os.path.join(BASE, os.path.basename(script))
    print("\n=== %s ===" % os.path.basename(script))
    ns["__file__"] = path
    with open(path, encoding="utf8") as f:
        exec(compile(f.read(), path, "exec"), ns)
