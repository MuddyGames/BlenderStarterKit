"""
Blender debug script (hello_debug.py) for testing and debugging Blender scripts in VSCode.

Which .blend file this runs in is set in .vscode/tasks.json:
    "${workspaceFolder}/blend/starter.blend"
To use a different .blend, change that path (in both the debug and run tasks).
"""

import bpy


def main():
    
    print("Blender version:", bpy.app.version_string)
    print("Open .blend file:", bpy.data.filepath or "(unsaved default scene)")

    # set a breakpoint on the next line to pause execution and inspect the scene
    # on left set breakpoint in VSCode, then run the debug task (F5) to start debugging
    bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 0))
    cube = bpy.context.object
    print("Added:", cube.name, "at", tuple(cube.location))

    print("Script finished.")


if __name__ == "__main__":
    main()