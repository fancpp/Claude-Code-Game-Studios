# GUT (Godot Unit Test) Runner — Entry Point
# Placeholder — requires Godot project + gut addon to be functional
#
# To make tests run:
# 1. Create project.godot (godot --headless --export-pack for the project)
# 2. Add gut addon: git clone https://github.com/bitbeans/gut.git addons/gut
# 3. Enable in Project Settings → Plugins
# 4. Replace this with actual test files

extends SceneTree

func _init() -> void:
    print("GUT runner placeholder — gut addon and project.godot required")
    print("See tests/README.md for setup instructions")
    quit(1)  # Exit with error until real project exists