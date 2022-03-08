
local function fs_normalise(path)
	return path
		:gsub("//+", "/")
		:gsub("^/", "")
		:gsub("/$", "")
		:gsub("/%./", "/")
		:gsub("^%./", "")
		:gsub("/%.$", "")
		:gsub("^%.$", "")
		:gsub("/[^/]+/%.%./", "/")
		:gsub("^[^/]+/%.%./", "")
		:gsub("/[^/]+/%.%.$", "")
		:gsub("^[^/]+/%.%.$", "")
		:gsub("/%.%./", "")
		:gsub("^%.%./", "")
		:gsub("/%.%.$", "")
		:gsub("^%.%.$", "")
end

local function shared_print(task, len, colour, ...)
	local text = { ... }
	for i = 1, #text do text[i] = tostring(text[i]) end

	if task then
		term.setTextColour(colours.grey)
		term.write "["
		term.setTextColour(colours.cyan)
		term.write(task)
		term.setTextColour(colours.grey)
		term.write "] "
		term.write((" "):rep(len - #task))
	end

	term.setTextColour(colour)
	print(table.concat(text, " "))
end

local function split_at(text, sep)
	local lines = {}
	for part in text:gmatch("[^" .. sep .. "]+") do
		table.insert(lines, part)
	end
	return lines
end

local function run_with_stacktrace(f, args, task, len, handler)
	local _, depth = xpcall(error, function()
		return #split_at(debug.traceback(), "\n") - 1
	end)
	return xpcall(function()
		return f(table.unpack(args))
	end, function(err, level)
		if type(err) == "string" then
			err = err:gsub("%[string \"(.*)\"%]", "%1")
		end
		handler(err)
		local lines = split_at(debug.traceback(), "\n")
		table.remove(lines, 1)
		table.remove(lines, 1)

		for i = 1, depth do
			lines[#lines] = nil
		end

		for i = 1, #lines do
			local line = tostring(lines[i]):gsub("%[string \"(.*)\"%]", "%1")

			if line:sub(1, 16) ~= "\tmesh-build.lua:" then
				shared_print(task, len, colours.red, ">" .. line)
			end
		end
	end)
end

return {
	fs_normalise = fs_normalise,
	shared_print = shared_print,
	split_at = split_at,
	run_with_stacktrace = run_with_stacktrace,
}
