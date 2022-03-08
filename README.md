
> Note: this is a WIP. There's a bunch of extra features that I'd like to add to
> make this fully usable and safe to use. This is available publicly with an
> initial release because it's still a useful system to use, and builds itself
> perfectly.

# `mesh-build`

`mesh-build` provides a command line tool to build projects using a local build
file which defines how to build the project.

Typical usage involves running

	mesh-build <task>

An example `build.mesh.lua` file might look like

```lua
require "lua_run@exerro:mesh-build:main"

function tasks:setup()
	Path("src").move_to("out")
end

function tasks:minify()
	for lua_file in Path("out/**.lua").find_iterator() do
		minify_lua_file(lua_file)
	end
end

function tasks:build()

end

function tasks:clean()
	Path("out").delete()
end

tasks.run:extends_from "lua_run::run"
tasks.run.config { main = "main", root = "build" }
tasks.minify:depends_on(tasks.setup)
tasks.build:depends_on(tasks.minify)
tasks.run:depends_on(tasks.build)
```

You'd run this with

	mesh-build run

Which would automatically handle the `build` step.

## `mesh-build` script environment

### Environment variables

* `MESH_BUILD_ENV` - the environment, which can be freely added to by plugins
* `MESH_ROOT_PATH` - path to the root directory of the build
* `MESH_MISSING_ENV` - list of string keys of values missing in the sandbox environment from the global environment

### `tasks`

The main way you interact with `mesh-build` is through the `tasks` table. This
uses a bunch of metatable magic to automatically declare tasks for you, meaning
you can refer to `tasks.<any task>` and it'll define a task with that name
automatically.

The returned `Task` object has the following properties:

* `config: Configuration` - lets you define task configuration
* `depends_on(other_task: Task | string)` - makes `other_task` *always* run before this one
* `extends_from(base_task: Task | string)` - copies `base_task` into this one

For example

```lua
tasks.myTask.config.a = 0
tasks.myTask.config { a = 0 }
tasks.myTask:depends_on(tasks.otherTask)
tasks.myTask:depends_on "otherTask"
tasks.myTask:extends_from(tasks.baseTask)
tasks.myTask:extends_from "baseTask"
```

Furthermore, you can specify code to run by defining a function like

```lua
function tasks:<task name>()
	-- do stuff when run
end
```

You can do this multiple times and define modular behaviour for tasks, although
it's a good idea to split them up into multiple tasks sometimes - you can always
chain them together with `depends_on`!

### Plugins and external dependencies

You can load plugins and external dependencies using `require`.

`require` accepts either
* a local path (e.g. `"my/script"`) similar to how pure-Lua `require`
works (no `.lua` on end)
* a remote URL (e.g. `"https://github.com/.../abc.lua"`)
* a GitHub reference (e.g. `"exerro.mesh-build.main:lua_run"`)

### Filesystem access

`Path`

### Utilities

#### `mesh_create_configuration`

	mesh_create_configuration(data: table): Configuration

Create a standalone `Configuration` object. Will put config values into the
`data` table.
