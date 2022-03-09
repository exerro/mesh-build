
local function fs_normalise(path)
	local parts = {}
	local i = 1

	for part in path:gmatch "[^/]+" do
		parts[i] = part
		i = i + 1
	end

	local i = 1

	while i < #parts do
		if parts[i + 1] == ".." then
			table.remove(parts, i + 1)
			table.remove(parts, i)
			i = i - 2
		elseif parts[i] == "." then
			table.remove(parts, i)
		end
		i = i + 1
	end

	while i > 1 do
		if parts[i] == ".." then
			table.remove(parts, i)
			table.remove(parts, i - 1)
			i = i - 1
		elseif parts[i] == "." then
			table.remove(parts, i)
		end
		i = i - 1
	end

	return table.concat(parts, "/")
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
