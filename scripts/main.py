import bpy

from pathlib import Path

# BlenderStarterKit/output
# Resolve the path to the output directory relative to this script
OUTPUT = Path(__file__).resolve().parent.parent / "output"

def main():
     print("Fetch Blender version:", bpy.app.version_string)
     bpy.ops.mesh.primitive_cube_add(location=(0, 0, 0))
     cube = bpy.context.object
     cube.name = "DebugCube"
     print("Created:", cube.name)

	# Create the output directory if it doesn't exist
     OUTPUT.mkdir(exist_ok=True)
     
     # Save current Blender file to output directory
     # Note: The 'copy=True' argument ensures that the original file remains unchanged
     # gitignore: BlenderStarterKit/output/ directory is ignored in .gitignore to avoid 
	# committing generated files
     bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT / "output.blend"), copy=True)

if __name__ == "__main__":
       main()