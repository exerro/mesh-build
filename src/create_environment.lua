
local create_path = require "create_path"
local create_require = require "create_require"
local create_tasks = require "create_tasks"
local shared_print = require "util" .shared_print

return function(allow_unsafe, allow_remote, verbose, root_dir, args)
	local tasks_interface, task_list = create_tasks()
	local env = {}
	local result = {
		environment = env,
		tasks = task_list,
		current_task = nil,
		tasks_length = 0,
		cancel_build = false,
	}

	------------------------------------------------------------
	-- Debug printing

	function env.print(...)
		return shared_print(result.current_task, result.tasks_length, colours.white, ...)
	end

	function env.print_error(...)
		return shared_print(result.current_task, result.tasks_length, colours.red, ...)
	end

	function env.print_warning(...)
		return shared_print(result.current_task, result.tasks_length, colours.yellow, ...)
	end

	function env.print_info(...)
		return shared_print(result.current_task, result.tasks_length, colours.lightGrey, ...)
	end

	function env.print_debug(...)
		if not verbose then return end
		return shared_print(result.current_task, result.tasks_length, colours.grey, ...)
	end

	function env.cancel_build()
		result.cancel_build = true
	end

	------------------------------------------------------------
	-- Mesh APIs

	env.MESH_ARGS = args
	env.MESH_BUILD_ENV = env
	env.MESH_ROOT_PATH = create_path(root_dir)("")
	env.MESH_MISSING_ENV = {}

	env.tasks = tasks_interface
	env.require = create_require(root_dir, env, allow_remote)

	env.Configuration = create_configuration
	env.Path = create_path(root_dir)

	function env.mesh_get_parent_environment()
		if not allow_unsafe then
			error("Parent environment is not accessible in this build\nTry running with --unsafe-parent-environment", 2)
			return
		end
		return _ENV
	end

	-- TODO: multi-project builds

	------------------------------------------------------------
	-- Lua APIs

	env.__inext = __inext
	env._ENV = env
	env._G = env
	env._VERSION = _VERSION
	env.assert = assert
	env.bit = bit
	env.bit32 = bit32
	env.coroutine = coroutine
	env.error = error
	env.getmetatable = getmetatable
	env.ipairs = ipairs
	env.load = load
	env.pairs = pairs
	env.pcall = pcall
	env.math = math
	env.next = next
	env.rawequal = rawequal
	env.rawget = rawget
	env.rawlen = rawlen
	env.rawset = rawset
	env.select = select
	env.setmetatable = setmetatable
	env.string = string
	env.table = table
	env.tonumber = tonumber
	env.tostring = tostring
	env.type = type
	env.utf8 = utf8
	env.xpcall = xpcall

	------------------------------------------------------------
	-- CC native APIs

	env._HOST = _HOST
	env.colors = colors
	env.colours = colours
	env.keys = keys
	env.parallel = parallel
	env.textutils = textutils
	env.vector = vector

	------------------------------------------------------------
	-- Put missing environment keys in a variable

	for k in pairs(_G) do
		if not env[k] then
			table.insert(env.MESH_MISSING_ENV, tostring(k))
		end
	end

	return result
end
