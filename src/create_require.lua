
local fs_normalise = require "util" .fs_normalise

local CACHE_ROOT = "/.mesh-build/"

return function(root_dir, env, allow_remote)
	local loaded_modules = {}
	local create_require

	local function load_module_src(module, content, name)
		local module_parent = module:match "(.+)/" or ""
		local module_env = setmetatable({}, { __index = env })
		module_env.require = create_require(module_parent)
		local f, err = load(content, name, nil, module_env)
		if not f then error(err, 4) end
		return f()
	end

	local function load_module(module, relative_to)
		if module:find "^%.+/" then
			-- TODO: gotta think about . replacement etc
			return load_module(fs_normalise(relative_to .. "/" .. module), relative_to)
		elseif module:find "^https?://" then
			if not allow_remote then
				error("Remote scripts are not allowed in this build: " .. module, 3)
			end
			local cache_file_name = module:gsub(
				"[:/]", function(match)
					return "&" .. tostring(match:byte())
				end)
			
			local cache_file_path = CACHE_ROOT .. cache_file_name
			local h = fs.open(cache_file_path, "r") or http.get(module)
				or error("Failed to load module '" .. module .. "'", 3)
			local content = h.readAll()
			h.close()

			return load_module_src(module, content, module)
		elseif module:find "@" then
			local file_part, username, repo, branch = module:match
				"^(.*)@([^:]+):([^:]+):([^:]+)"
			if not file_part then
				error("Malformed GitHub module: expected <path>@<username>:<repo>:<branch>, got '" .. module .. "'", 3)
			end
			local file_path = file_part:gsub("%.", "/") .. ".lua"
			local url = "https://raw.githubusercontent.com/" .. username .. "/" .. repo .. "/" .. branch .. "/" .. file_path
			return load_module(url, TODO())
		else
			local module_path_b = module:gsub("%.", "/") .. ".lua"
			local module_path_a = fs.combine(root_dir, module_path_b)
			local module_path = module_path_a
			local h = fs.open(module_path, "r")
			if not h then
				module_path = module_path_b
				h = fs.open(module_path, "r")
					or error("Failed to load module '" .. module .. "'", 3)
			end
			local content = h.readAll()
			h.close()

			return load_module_src(module_path, content, module)
		end
	end

	function create_require(relative_to)
		return function(module)
			local loaded_module = loaded_modules[module]
			if loaded_module then return loaded_module end

			loaded_module = load_module(module, relative_to)
			loaded_modules[module] = loaded_module

			return loaded_module
		end
	end

	return create_require(root_dir)
end
