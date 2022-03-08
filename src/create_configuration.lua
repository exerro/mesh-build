
local function create_configuration(configuration, prefix)
	local mt = {}

	function mt:__call(values)
		for k, v in pairs(values) do
			configuration[prefix .. tostring(k)] = v
		end
	end

	function mt:__index(key)
		return create_configuration(configuration, prefix .. tostring(key) .. ".")
	end

	function mt:__newindex(key, value)
		configuration[prefix .. tostring(key)] = value
	end

	return setmetatable({}, mt)
end

return create_configuration
