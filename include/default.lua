
require "./core"
require "./lua"

tasks.setup:extends_from "mesh:copy"
tasks.setup.config {
	from = MESH_ROOT_PATH / "src",
	to = MESH_ROOT_PATH / "build/src",
}

tasks.check:extends_from "lua:check_syntax"
tasks.check:depends_on(tasks.setup)
tasks.check.config {
	include = MESH_ROOT_PATH / "build/src/**.lua",
}

tasks.minify:extends_from "lua:minify"
tasks.minify:depends_on(tasks.check)
tasks.minify.config {
	include = MESH_ROOT_PATH / "build/src/**.lua",
}

tasks.build:extends_from "lua:assemble"
tasks.build:depends_on(tasks.minify)
tasks.build.config {
	require_path = MESH_ROOT_PATH / "build/src",
	entry_path = MESH_ROOT_PATH / "build/src/main.lua",
	output_path = MESH_ROOT_PATH / "build/main.lua",
}

tasks.run:extends_from "lua:run"
tasks.run:depends_on(tasks.build)
tasks.run.config {
	script_path = MESH_ROOT_PATH / "build/main.lua"
}

tasks.clean:extends_from "mesh:clean"
tasks.clean.config {
	path = MESH_ROOT_PATH / "build"
}
