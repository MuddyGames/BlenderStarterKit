#!/usr/bin/env bash

# Run this script to set up a virtual environment for Blender Python development.

# This script creates a virtual environment in ~/Projects/dev/blender-python-env directory 
# and installs  necessary dependencies.  

# Usage:
# 1. Open a terminal.
# 2. Run the script: ./tools/setup_script.sh

# Note: Python 3 and pip must be installed system-wide before running this script.

# make sure the Projects/dev directory exists
mkdir -p ~/Projects/dev/blender-python-env
cd ~/Projects/dev/blender-python-env

# Create a virtual environment in the blender-python-env directory
python3 -m venv .venv
# Activate the virtual environment
source .venv/bin/activate

# Upgrade pip to the latest version
python -m pip install --upgrade pip