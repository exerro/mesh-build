
require "include.core"
require "include.lua"

tasks.setup:extends_from "mesh:copy" {
	from = MESH_ROOT_PATH / "src",
	to = MESH_ROOT_PATH / "build/src",
}

tasks.check:depends_on(tasks.setup)
tasks.check:extends_from "lua:check_syntax" {
	files = MESH_ROOT_PATH / "build/src/**.lua",
}

tasks.minify:depends_on(tasks.check)
tasks.minify:extends_from "lua:minify" {
	files = MESH_ROOT_PATH / "build/src/**.lua",
}

tasks.build:depends_on(tasks.minify)
tasks.build:extends_from "lua:assemble" {
	require_path = MESH_ROOT_PATH / "build/src",
	output_path = MESH_ROOT_PATH / "build/mesh-build.lua",
	entry_path = MESH_ROOT_PATH / "build/src/mesh-build.lua",
}

tasks.clean:extends_from "mesh:clean" {
	path = MESH_ROOT_PATH / "build"
}
