
local create_configuration = require "create_configuration"

local TASK_HANDLE_TYPE = "$TaskHandle"

local function is_task_handle(value)
	if type(value) ~= "table" then return false end
	local mt = getmetatable(value)
	return mt and mt.__type == TASK_HANDLE_TYPE
end

local function assert_task_handle(value)
	if not is_task_handle(value) then
		return error("'" .. tostring(value) .. "' is not a task", 3)
	end
end

local function get_task(handle, task_list)
	if type(handle) == "string" then
		return task_list[handle] or error("No such task '" .. handle .. "'", 2)
	else
		assert_task_handle(handle)
		return task_list[handle]
	end
end

local function create_new_task(task_list, task_name)
	local current_task = task_list[task_name]

	if not current_task then
		current_task = {
			name = task_name,
			runnable = true,
			on_run = {},
			depends_on = {},
			configuration = {},
		}
		task_list[task_name] = current_task
		table.insert(task_list, current_task)
	end

	return current_task
end

local function create_task_handle(task_list, task_name)
	local task = create_new_task(task_list, task_name)
	local handle = {}
	local handle_mt = {}

	task_list[handle] = task
	handle_mt.__type = TASK_HANDLE_TYPE
	handle.config = create_configuration(task.configuration, "")

	function handle:runnable(value)
		task.runnable = value ~= false
	end

	function handle:on_run(do_this)
		table.insert(task.on_run, do_this)
	end

	function handle:depends_on(dependency_task)
		dependency_task = get_task(dependency_task, task_list)
		table.insert(task.depends_on, dependency_task.name)
	end

	function handle:extends_from(base_task)
		base_task = get_task(base_task, task_list)
		
		for i = 1, #base_task.on_run do
			table.insert(task.on_run, base_task.on_run[i])
		end

		for k, v in pairs(base_task.configuration) do
			task.configuration[k] = v
		end

		return handle.config
	end

	return setmetatable(handle, handle_mt)
end

return function()
	local task_list = {}
	local interface = {}
	local interface_mt = {}

	function interface_mt:__index(task_name)
		return create_task_handle(task_list, task_name)
	end

	function interface_mt:__newindex(task_name, on_run)
		local task = create_new_task(task_list, task_name)
		table.insert(task.on_run, on_run)
	end

	setmetatable(interface, interface_mt)

	return interface, task_list
end
