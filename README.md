# Blender Python StarterKit

Write Python scripts for Blender in VS Code, with autocomplete and full breakpoint debugging.

Write plain `bpy` scripts in `scripts/`, open one, and press **F5**. Blender launches, VS Code attaches its debugger, and execution stops at your breakpoints.

---

## How it fits together

- **Blender runs its own Python.** Blenden has its own interpreter. Visual Studio code uses uses a virtual environment for autocomplete. Anything your scripts import inside Blender (here, `debugpy`) has to be installed for *Blender's* Python.
- **VS Code uses the shared virtual environment.** That venv only gives VS Code autocomplete (`fake-bpy-module`) and a Python interpreter for the editor. It never runs your Blender code.
- **Two `--python` scripts run in order.** `tools/debug_attach.py` starts the debugger and waits for VS Code. Then Blender runs whichever script you have open.

```
StarterKit/
├── .vscode/
│   ├── launch.json         ← "Debug current script in Blender" (F5)
│   ├── settings.json       ← points VS Code at the shared venv
│   └── tasks.json          ← starts / runs / stops Blender
├── assets/
│   └── README.txt          ← asset files for project
├── tools/
│   ├── settings.json       ← points VS Code at the shared venv
│   └── debug_attach.py     ← debug helper: do not edit
├── blend/
│   └── starter.blend       ← Blender Files go here
├── scripts/
│   └── main.py             ← Blender Scripts go here
└── README.md               ← Starter Readme
```

---

## 1. Install Blender and VS Code

**Blender**, using either of these:

- Snap: `sudo snap install blender --classic`
  - Check the version with `blender --version`.
  - To pick a version, run `snap info blender` to see the channels, then e.g. `sudo snap refresh blender --channel=latest/stable`.
- Tarball from blender.org: extract it to e.g. `~/Applications/blender-5.0/`, then put it on your PATH:
  ```bash
  mkdir -p ~/.local/bin
  ln -sf ~/Applications/blender-5.0/blender ~/.local/bin/blender
  ```

Check which one is on PATH using:

```bash
which -a blender
blender --version
```

**VS Code extensions**:

```bash
code --install-extension ms-python.python
code --install-extension ms-python.debugpy
```

Or install **Python** and **Python Debugger** (both by Microsoft) from the Extensions panel.

---

## 2. Create the shared Python virtual environment (once per machine)

All your Blender projects share this one venv.

```bash
mkdir -p ~/Projects/dev/blender-python-env
cd ~/Projects/dev/blender-python-env

python3 -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip
```

Install the autocomplete stubs **matching your Blender version** (`X.Y` from `blender --version`, e.g. `3.6` or `5.0`), plus `debugpy` so VS Code can resolve the import:

```bash
python -m pip install fake-bpy-module-X.Y debugpy
```

Using `./tools/setup_script.sh` automates the setup of Python virtual environment

```bash
bash ./tools/setup_script.sh
```

> If you change Blender versions later, swap the stubs to match:
> `python -m pip uninstall -y fake-bpy-module-OLD && python -m pip install fake-bpy-module-NEW`

---

## 3. Install `debugpy` for Blender's own Python (once per Blender version)

This is the step that makes `import debugpy` work **inside Blender**. It installs into your user folder `~/.config/blender/X.Y/scripts/modules`, which Blender adds to its import path automatically. This works for snap, tarball and apt installs.

```bash
# Check Blender version, Python executable and its Python version
BLENDER_VER=$(blender --version | head -1 | awk '{print $2}' | cut -d. -f1,2)
BLENDER_PY=$(blender --background --factory-startup \
  --python-expr "import sys; print('PY=' + sys.executable)" 2>/dev/null | sed -n 's/^PY=//p')
BLENDER_PYVER=$(blender --background --factory-startup \
  --python-expr "import sys; print('PYV=%d.%d' % sys.version_info[:2])" 2>/dev/null | sed -n 's/^PYV=//p')

echo "Blender $BLENDER_VER  |  Python $BLENDER_PYVER  |  $BLENDER_PY"

# Install debugpy where Blender looks for user modules
"$BLENDER_PY" -m pip install --target ~/.config/blender/$BLENDER_VER/scripts/modules debugpy
```

If that fails with **"No module named pip"**, install from the shared venv instead. Activate the venv first; the `--python-version` flag makes pip fetch the build that matches Blender's Python:

```bash
python -m pip install --target ~/.config/blender/$BLENDER_VER/scripts/modules \
  --python-version $BLENDER_PYVER --only-binary=:all: debugpy
```

**Check it worked:**

```bash
blender --background --python-expr 'import debugpy; print("debugpy:", debugpy.__file__)'
```

You should see a path under `~/.config/blender/X.Y/scripts/modules/`.

> **Snap users:** the snap auto-updates. When Blender moves to a new version (e.g. 5.0 → 5.1), it looks in a new `~/.config/blender/5.1/` folder, so rerun this step.

---

## 4. Open the StarterKit in VS Code

```bash
cd ~/Projects/StarterKit
code .
```

`.vscode/settings.json` already points VS Code to the shared venv. If VS Code doesn't pick it up:

1. **Ctrl+Shift+P** → **Python: Select Interpreter**
2. Choose **Enter interpreter path…** and enter
   `~/Projects/dev/blender-python-env/.venv/bin/python`

`import bpy` should now autocomplete without warnings.

---

## 5. Daily workflow

| Goal | Action |
|---|---|
| **Debug a script** | Open it in `scripts/`, click in the left margin to set a breakpoint, press **F5**. Blender opens and stops at your breakpoint. |
| Step through code | **F10** step over, **F11** step into, **F5** continue. Hover variables or use the *Variables* panel. |
| **Finish debugging** | **Shift+F5** (stops the debugger and closes Blender) |
| **Run without debugger** | **Ctrl+Shift+B**. Blender opens with your script's result. |
| **New script** | Create `scripts/anything.py`, open it, press F5. No extra setup. |

Example script (`scripts/main.py`):

```python
import bpy

def main():
    print("Blender version:", bpy.app.version_string)
    bpy.ops.mesh.primitive_cube_add(location=(0, 0, 0))
    cube = bpy.context.object
    cube.name = "MyDebugCube"
    print("Created:", cube.name)

if __name__ == "__main__":
    main()
```

Your scripts **don't** import `debugpy`, because `tools/debug_attach.py` handles that.

> **Each run starts fresh from `starter.blend`, and Shift+F5 closes Blender without saving.**
> To keep a result, save from inside Blender before stopping, or end your script with:
> ```python
> bpy.ops.wm.save_as_mainfile(filepath="//output.blend")
> ```

---

## Troubleshooting

| Problem | Cause / fix |
|---|---|
| `ModuleNotFoundError: No module named 'debugpy'` (in Blender's output) | Step 3 hasn't been done for **this** Blender version. Check `blender --version` and rerun step 3. |
| `connect ECONNREFUSED 127.0.0.1:5678` | Blender wasn't running or waiting when VS Code tried to attach. Use the **Debug current script in Blender** config, which launches Blender for you. Check the terminal panel for a Python error before the "Waiting…" line. |
| `Address already in use` / port 5678 | A previous Blender is still running. Run the task **Blender: stop** (*Terminal → Run Task…*) or close Blender. |
| Breakpoints show as hollow / never hit | Make sure the breakpoint is in the script you launched (F5 runs the *currently open* file) and on a line that actually runs. |
| F5 starts the wrong file | `${file}` is whatever editor tab is focused, so click into your script before pressing F5. |
| Autocomplete is missing or wrong | Wrong interpreter selected (step 4), or `fake-bpy-module-X.Y` doesn't match your Blender version (step 2). |
| `blender: command not found` in VS Code | Blender isn't on your PATH (step 1). Restart VS Code after changing PATH. |