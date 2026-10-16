#!/usr/bin/env bash
#
# setup_script.sh
#
# Set up VS Code + Blender Python debugging
#
# What it does:
#   1. Finds Blender and checks version, Python version and
#      user modules folder.
#   2. Creates (or reuses) the shared virtual environment in
#      ~/Projects/dev/blender-python-env/.venv
#   3. Installs dependencies into that venv (for VS Code autocomplete only):
#        - fake-bpy-module-X.Y  (matching your Blender version)
#        - debugpy
#   4. Installs debugpy for Blender's OWN Python, into
#        ~/.config/blender/X.Y/scripts/modules
#      (Blender ignores the venv, so this step is what makes
#       `import debugpy` work inside Blender.)
#   5. Checks that Blender can import debugpy.
#
# Safe to re-run at any time
# e.g. after Blender updates to a new version.
#
# Usage:
# 1. Open a terminal.
# 2. Run the script: ./tools/setup_script.sh
#
# Options (environment variables):
#   BLENDER=/path/to/blender   use a specific Blender version instead of the one on PATH
#   VENV_ROOT=/some/dir        venv preferred directory (default: ~/Projects/dev/blender-python-env)
#
# Requirements: python3 with the venv module (sudo apt install python3-venv),
#               Blender installed (snap, tarball or apt).

set -euo pipefail

BLENDER="${BLENDER:-blender}"
VENV_ROOT="${VENV_ROOT:-$HOME/Projects/dev/blender-python-env}"
VENV="$VENV_ROOT/.venv"
VENV_PY="$VENV/bin/python"

info() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '    \033[1;32m✔\033[0m %s\n' "$*"; }
warn() { printf '    \033[1;33m!\033[0m %s\n' "$*"; }
die() {
	printf '\n\033[1;31m✘ %s\033[0m\n' "$*" >&2
	exit 1
}

# ---------------------------------------------------------------------------
# 1. Find Blender and ask it about itself
# ---------------------------------------------------------------------------
info "Looking for Blender"

command -v "$BLENDER" >/dev/null 2>&1 ||
	die "Blender not found ('$BLENDER'). Install it, or run: BLENDER=/path/to/blender bash $0"
ok "Using: $(command -v "$BLENDER")"

# Each value is printed on its own line with a prefix, so Blender's own
# startup messages can't get mixed up with them.
BLENDER_INFO=$("$BLENDER" --background --factory-startup --python-expr '
import sys, bpy
print("BINFO_VER=%d.%d" % bpy.app.version[:2])
print("BINFO_PYVER=%d.%d" % sys.version_info[:2])
print("BINFO_PY=" + sys.executable)
print("BINFO_MODULES=" + bpy.utils.user_resource("SCRIPTS", path="modules"))
' 2>/dev/null || true)

get() { printf '%s\n' "$BLENDER_INFO" | sed -n "s/^BINFO_$1=//p" | head -1; }
BLENDER_VER=$(get VER)
BLENDER_PYVER=$(get PYVER)
BLENDER_PY=$(get PY)
BLENDER_MODULES=$(get MODULES)

[ -n "$BLENDER_VER" ] && [ -n "$BLENDER_MODULES" ] ||
	die "Couldn't get version info from Blender. Try running: $BLENDER --background --version"

ok "Blender $BLENDER_VER  (Python $BLENDER_PYVER)"
ok "Blender's Python:  $BLENDER_PY"
ok "User modules dir:  $BLENDER_MODULES"

# ---------------------------------------------------------------------------
# 2. Shared virtual environment (for VS Code)
# ---------------------------------------------------------------------------
info "Shared virtual environment: $VENV"

mkdir -p "$VENV_ROOT"
if [ -x "$VENV_PY" ]; then
	ok "Already exists — reusing it"
else
	python3 -m venv "$VENV" ||
		die "Couldn't create the venv. On Ubuntu/Pop!_OS: sudo apt install python3-venv"
	ok "Created"
fi

# No need to 'activate' — calling the venv's python directly does the same job
# inside a script (and 'activate' wouldn't carry over to your terminal anyway).
"$VENV_PY" -m pip install --quiet --upgrade pip
ok "pip upgraded"

# ---------------------------------------------------------------------------
# 3. Autocomplete stubs + debugpy in the venv
# ---------------------------------------------------------------------------
info "Installing VS Code helpers into the venv"

# Remove stubs for any other Blender version so autocomplete matches this one.
OLD_STUBS=$("$VENV_PY" -m pip list --format=freeze 2>/dev/null |
	sed -n 's/^\(fake-bpy-module[^=]*\)==.*/\1/p' |
	grep -vx "fake-bpy-module-$BLENDER_VER" || true)
if [ -n "$OLD_STUBS" ]; then
	# shellcheck disable=SC2086
	"$VENV_PY" -m pip uninstall --quiet -y $OLD_STUBS
	ok "Removed old stubs: $(echo $OLD_STUBS)"
fi

if "$VENV_PY" -m pip install --quiet "fake-bpy-module-$BLENDER_VER"; then
	ok "fake-bpy-module-$BLENDER_VER"
else
	warn "No fake-bpy-module-$BLENDER_VER on PyPI — falling back to the latest 'fake-bpy-module'"
	"$VENV_PY" -m pip install --quiet fake-bpy-module
	ok "fake-bpy-module (latest)"
fi

"$VENV_PY" -m pip install --quiet debugpy
ok "debugpy (for VS Code)"

# ---------------------------------------------------------------------------
# 4. debugpy for Blender's own Python
# ---------------------------------------------------------------------------
info "Installing debugpy for Blender's Python"

mkdir -p "$BLENDER_MODULES"

installed=0
# First choice: Blender's own pip, so the exact right build is chosen.
if [ -n "$BLENDER_PY" ] && [ -x "$BLENDER_PY" ] &&
	"$BLENDER_PY" -m pip --version >/dev/null 2>&1; then
	if "$BLENDER_PY" -m pip install --quiet --upgrade \
		--target "$BLENDER_MODULES" debugpy 2>/dev/null; then
		installed=1
		ok "Installed with Blender's pip"
	fi
fi

# Fallback: the venv's pip, fetching the build for Blender's Python version.
if [ "$installed" -eq 0 ]; then
	warn "Blender's pip not usable — using the venv's pip for Python $BLENDER_PYVER instead"
	"$VENV_PY" -m pip install --quiet --upgrade \
		--target "$BLENDER_MODULES" \
		--python-version "$BLENDER_PYVER" --only-binary=:all: \
		debugpy
	ok "Installed with the venv's pip"
fi

# ---------------------------------------------------------------------------
# 5. Check Blender can import it
# ---------------------------------------------------------------------------
info "Checking Blender can import debugpy"

CHECK=$("$BLENDER" --background --python-expr \
	'import debugpy; print("BINFO_DEBUGPY=" + debugpy.__file__)' 2>&1 || true)
DEBUGPY_PATH=$(printf '%s\n' "$CHECK" | sed -n 's/^BINFO_DEBUGPY=//p' | head -1)

if [ -n "$DEBUGPY_PATH" ]; then
	ok "debugpy found at $DEBUGPY_PATH"
else
	printf '%s\n' "$CHECK" | tail -n 15 >&2
	die "Blender still can't import debugpy — see the output above."
fi

# ---------------------------------------------------------------------------
cat <<EOF

$(printf '\033[1;32m')All done.$(printf '\033[0m')

  Venv for VS Code:   $VENV_PY
  Blender:            $BLENDER_VER (Python $BLENDER_PYVER)

Next:
  1. Open the StarterKit in VS Code:   code .
  2. If autocomplete doesn't work: Ctrl+Shift+P → "Python: Select Interpreter"
     → enter $VENV_PY
  3. Open a script in scripts/, set a breakpoint, press F5.

Re-run this script whenever Blender updates to a new version.
EOF
