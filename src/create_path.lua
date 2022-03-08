
local fs_normalise = require "util" .fs_normalise
local split_at = require "util" .split_at

local PATH_TYPE = "$Path"

local function create_path(root_dir, path)
	local p = {}
	local mt = {}

	if path:sub(1, 1) == "/" then
		path = fs_normalise(path)
	else
		path = fs_normalise(root_dir .. "/" .. path)
	end

	mt.__path = path

	------------------------------------------------------------
	-- Path functions

	function p.create_file(err)
		local h = io.open(path, "w")
		if h then h:close() end
		if not h and err then error("Failed to create file '" .. tostring(p) .. "'", 2) end
		return h ~= nil
	end

	function p.create_directory()
		if not fs.exists(path) then
			fs.makeDir(path)
		elseif not fs.isDir(path) then
			error("Failed to create directory '" .. tostring(p) .. "'", 2)
		end
	end

	function p.move_to(destination)
		-- TODO
	end

	function p.copy_to(destination)
		-- TODO: typecheck destination
		-- TODO: proper copying
		fs.delete(destination.absolute_path())
		fs.copy(path, destination.absolute_path())
	end

	function p.exists()
		return fs.exists(path)
	end

	function p.is_directory()
		return fs.isDir(path)
	end

	function p.is_file()
		return fs.exists(path) and not fs.isDir(path)
	end

	function p.read(err)
		local h = io.open(path)
		local content = h and h:read "*a"
		if h then h:close() end
		if not content and err then
			error("Failed to read file '" .. tostring(p) .. "'", 2)
		end
		return content or nil
	end

	function p.lines(err)
		local lines = {}
		for line in p.lines_iterator() do
			table.insert(lines, line)
		end
		return lines
	end

	function p.lines_iterator(err)
		local f = io.lines(path)
		if not f and err then
			error("Failed to read file '" .. tostring(p) .. "'", 2)
		end
		return f or function() end
	end

	function p.list()
		if fs.isDir(path) then
			local children = fs.list(path)

			for i = 1, #children do
				children[i] = p .. ("/" .. children[i])
			end

			return children
		else
			error("'" .. tostring(p) .. "' is not a directory", 2)
		end
	end

	function p.list_iterator(...)
		return ipairs(p.list(...))
	end

	function p.tree(on_child, ...)
		local files = {}

		for path in p.tree_iterator(...) do
			table.insert(files, path)
		end

		return files
	end

	function p.tree_iterator(include_directories)
		local queue = { p }

		local function next()
			local path = table.remove(queue, 1)

			if not path then
				return nil
			end

			if path.is_directory() then
				local children = path.list()
				local first_index = include_directories and 1 or 2

				for i = first_index, #children do
					table.insert(queue, i - first_index + 1, children[i])
				end

				return include_directories and path or children[1] or next()
			elseif path.exists() then
				return path
			end
		end

		return next
	end

	function p.find(...)
		local files = {}

		for path in p.find_iterator(...) do
			table.insert(files, path)
		end

		return files
	end

	function p.find_iterator(...)
		if not path:find "%*" then
			return function()
				return p.exists() and p or nil
			end
		end

		local parts = split_at(path, "/")
		local wildcard_idx = 1

		while wildcard_idx < #parts and not parts[wildcard_idx]:find "%*" do
			wildcard_idx = wildcard_idx + 1
		end

		local base_path = table.concat(parts, "/", 1, wildcard_idx - 1)
		local pattern = table.concat(parts, "/", wildcard_idx)
			:gsub("[.%+-?$^*()[%]]", "%%%1")
			:gsub("%%%*%%%*", "++")
			:gsub("%%%*", "[^/]*")
			:gsub("%+%+", ".*")
		
		pattern = "^" .. pattern .. "$"

		local tree_iterator = create_path(root_dir, "/" .. base_path)
			.tree_iterator(...)

		local function next()
			local path = tree_iterator()
			if not path then return nil end
			if tostring(path):find(pattern) then
				return path
			else
				return next()
			end
		end
		
		return next
	end

	function p.write(content, append)
		local h = io.open(path, append and "a" or "w")
		if h then
			h:write(content)
			h:close()
		else
			error("Failed to write to file '" .. tostring(p) .. "'", 2)
		end
	end

	function p.delete()
		fs.delete(path)
	end

	function p.absolute_path()
		return "/" .. path
	end

	------------------------------------------------------------
	-- Path metamethods

	function mt:__concat(other)
		if type(other) == "string" then
			return create_path(root_dir, "/" .. path .. other)
		elseif type(other) == "table" then
			local mt = getmetatable(other)
			if mt and mt.__type == PATH_TYPE then
				return create_path(root_dir, "/" .. path .. mt.__path)
			end
		end

		error("Expected a path or string, got " .. tostring(other), 3)
	end

	function mt:__div(other)
		return self .. "/" .. other
	end

	function mt:__tostring()
		if path:sub(1, #root_dir + 1) == root_dir .. "/" or path == root_dir then
			if #path > #root_dir + 1 then
				return path:sub(#root_dir + 2)
			else
				return "."
			end
		else
			return "/" .. path
		end
	end

	return setmetatable(p, mt)
end

return function(root_dir)
	return function(path)
		-- TODO: accept paths

		if type(path) ~= "string" then
			error("Expected a string path", 2)
		end

		return create_path(root_dir, path)
	end
end
