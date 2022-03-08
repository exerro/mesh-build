
local util = require "util"
local create_configuration = require "create_configuration"
local create_tasks = require "create_tasks"
local create_environment = require "create_environment"

local args = { ... }

local fs_normalise = util.fs_normalise
local shared_print = util.shared_print
local run_with_stacktrace = util.run_with_stacktrace

--------------------------------------------------------------------------------
-- Show help if requested

if args[1] == "--help" or args[1] == "-h" then
	local function opt(name, description)
		term.setTextColour(colours.lightBlue)
		term.write " "
		term.write(name)
		term.setTextColour(colours.grey)
		term.write " - "
		term.setTextColour(colours.lightGrey)
		print(description)
	end

	term.setTextColour(colours.cyan)
	term.write "mesh-build "
	term.setTextColour(colours.lightGrey)
	term.write "[<"
	term.setTextColour(colours.white)
	term.write "options"
	term.setTextColour(colours.lightGrey)
	term.write "...>] <"
	term.setTextColour(colours.white)
	term.write "task"
	term.setTextColour(colours.lightGrey)
	term.write "> [<"
	term.setTextColour(colours.white)
	term.write "args"
	term.setTextColour(colours.lightGrey)
	print "...>]"
	print "> Run a task from a build file."

	opt("--root-dir, -r", "Set build root directory")
	opt("--build-file, -b", "Specify path to build file")
	opt("--verbose, -v", "Show debug output")
	opt("--no-remotes", "Block using remote scripts")
	opt("--unsafe-parent-environment, -u", "Allow access to all variables")

	return result
end

--------------------------------------------------------------------------------
-- Main script

local build_file = "build.mesh.lua"
local root_dir = "."
local allow_unsafe = false
local allow_remote = true
local verbose = false
local task = "build"

while #args > 0 do
	if not args[1]:find "^%-" then
		break
	end

	local argument = table.remove(args, 1)

	if argument == "--unsafe-parent-environment" or argument == "-u" then
		allow_unsafe = true
	elseif argument == "--no-remotes" then
		allow_remote = false
	elseif argument == "--verbose" or argument == "-v" then
		verbose = true
	elseif argument == "--build-file" or argument == "-b" then
		build_file = table.remove(args, 1) or error("No build file given", 0)
	elseif argument == "--root-dir" or argument == "--root-directory" or argument == "-r" then
		root_dir = table.remove(args, 1) or error("No root directory given", 0)
	elseif argument == "--" then
		break
	else
		printError("Unknown option '" .. argument .. "'\n > Hint: Pass '--' to stop passing options")
		return
	end
end

task = table.remove(args, 1) or "build"
build_file = fs_normalise(shell.resolve(build_file))
root_dir = fs_normalise(shell.resolve(root_dir))

if verbose and task ~= "tasks" then
	local function option(name, value)
		term.setTextColour(colours.lightGrey)
		term.write(name)
		term.setTextColour(colours.grey)
		term.write(": ")
		term.setTextColour(colours.cyan)
		print(value)
	end

	local function path_option(name, value)
		local cwd = shell.dir()
		if value:sub(1, #cwd + 1) == cwd .. "/" then
			value = "./" .. value:sub(#cwd + 2)
		elseif value == cwd then
			value = "."
		elseif cwd ~= "" then
			value = "/" .. value
		end
		return option(name, value)
	end

	option("Task", task)
	path_option("Build file", build_file)
	path_option("Root directory", root_dir)
	option("Allow unsafe environment", allow_unsafe)
	option("Allow remote scripts", allow_remote)
end

local env = create_environment(allow_unsafe, allow_remote, verbose, root_dir, args)
local h = io.open(build_file)
if not h then h = io.open(build_file .. ".lua") end
local content = h and h:read "*a"
	or error("Failed to open build file '" .. build_file .. "'", 0)
h:close()

local fsrc = fs.getName(build_file)
local f, err = load(content, fsrc, nil, env.environment)
if not f then error("Syntax error in build file '" .. build_file .. "': " .. tostring(err), 0) end

term.setTextColour(colours.white)

if not run_with_stacktrace(f, args, nil, 0, function(err)
	printError("Error loading build file: " .. tostring(err))
end) then error() end

if task == "tasks" then
	for i = 1, #env.tasks do
		print(env.tasks[i].name)
	end
	return
end

if env.cancel_build then
	printError("Build canceled")
	return
end

local tasks_to_run = {}
local queue = { task }

-- TODO: this doesn't work
-- A: B, C ; C: B
-- order: A, B, C not A, C, B
while #queue > 0 do
	local t = table.remove(queue, 1)
	
	if not tasks_to_run[t] then
		local td = env.tasks[t]

		if not td then
			error("No such task '" .. t .. "'", 0)
		end

		for i = 1, #td.depends_on do
			table.insert(queue, td.depends_on[i])
		end

		table.insert(tasks_to_run, td)
		tasks_to_run[t] = true
	end
end

for i = 1, #tasks_to_run do
	env.tasks_length = math.max(env.tasks_length, #tasks_to_run[i].name)

	if not tasks_to_run[i].runnable then
		error("Cannot run task '" .. tasks_to_run[i].name .. "'", 0)
	end
end

for i = #tasks_to_run, 1, -1 do
	local t = tasks_to_run[i]
	local ctx = {
		config = t.configuration
	}
	env.current_task = t.name

	for j = 1, #t.on_run do
		term.setBackgroundColour(colours.black)
		term.setTextColour(colours.white)
		if not run_with_stacktrace(t.on_run[j], { ctx }, t.name, env.tasks_length, function(err)
			shared_print(t.name, env.tasks_length, colours.red, tostring(err))
		end) then error() end

		if env.cancel_build then
			shared_print(t.name, env.tasks_length, colours.red, "Build canceled")
			return
		end
	end
end
