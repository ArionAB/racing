# Surse Blender

Fisierele `.blend` din care ies GLB-urile din `assets/models/`. Se comit odata cu
exportul (regula din [ONBOARDING.md](../../ONBOARDING.md)), ca oricine din echipa
sa poata edita ulterior propul.

`.gdignore` opreste Godot din a scana folderul — altfel ar incerca sa importe
`.blend`-urile ca scene si ar cere Blender instalat pe fiecare masina din echipa.

## Sursa reala e scriptul, nu .blend-ul

Assets-urile sunt **generate procedural** de scripturile din
[tools/blender/](../../tools/blender/). `.blend`-ul e un artefact al rularii, util
ca sa deschizi si sa ciupesti ceva de mana; daca vrei sa schimbi forma sau
proportiile, editeaza scriptul si regenereaza — asa raman reproductibile si
verificabile.

```
# in consola Python din Blender (namespace comun, deci merg doua exec separate):
exec(open(r"d:/GameDev/ignition-spike/tools/blender/dio_lib.py").read())
exec(open(r"d:/GameDev/ignition-spike/tools/blender/build_windmill.py").read())
```

Prin **Blender MCP** (`execute_blender_code`) namespace-ul nu e comun, deci cele
doua fisiere trebuie sa imparta explicit acelasi dictionar de globale. Si
`__file__` trebuie pus de mana: `exec(open(...).read())` nu-l defineste, iar
`dio_lib` il foloseste ca sa afle radacina repo-ului.

```python
g = {"__name__": "__main__",
     "__file__": r"d:/GameDev/ignition-spike/tools/blender/dio_lib.py"}
exec(open(r"d:/GameDev/ignition-spike/tools/blender/dio_lib.py").read(), g)
exec(open(r"d:/GameDev/ignition-spike/tools/blender/build_windmill.py").read(), g)
```

Verificarea GLB-ului rezultat, fara Blender si fara Godot:

```
python tools/blender/verify_glb.py assets/models/windmill.glb 1200
```
