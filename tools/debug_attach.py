# This script is used to attach the VS Code debugger virtual environment to Blender.

import sys
import debugpy

debugpy.configure(python=sys.executable)
debugpy.listen(("127.0.0.1", 5678))
print("Waiting for VS Code debugger on 5678...", flush=True)
debugpy.wait_for_client()