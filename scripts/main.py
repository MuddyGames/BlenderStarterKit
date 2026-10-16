import bpy

def main():
    print("Blender version:", bpy.app.version_string)
    bpy.ops.mesh.primitive_cube_add(location=(0, 0, 0))
    cube = bpy.context.object
    cube.name = "MyDebugCube"
    print("Created:", cube.name)

if __name__ == "__main__":
    main()