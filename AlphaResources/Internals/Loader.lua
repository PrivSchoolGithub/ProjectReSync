
local sysFiles,currentlyOpen = {}

-- Repurposed Operating System library for ReSync
-- Based on the original Lua os untouched by Roblox

-- Because the os library cannot be written over by default, it must be
-- copied over this way. Very highly inefficient but whatever.
local MasterEnvironment = require(script.GlobalEnvironment)

function MasterEnvironment.os.tmpname(style)
	local GUID = game:GetService('HttpService'):GenerateGUID(false)
	if style == 'win' then
		local firstSub = string.sub(GUID,8,12)
		return firstSub..'.'
	elseif style == 'debian' or style == 'linux' or style:lower() == 'gnu' then
		local secondSub = string.sub(GUID,1,6)
		return 'rs_'..tostring(math.random(0,9))..secondSub
	end
end

function MasterEnvironment.os.exit(code)
	error(code or '')
end

function MasterEnvironment.os.remove(filename)
	if not sysFiles[filename] then
		error('No file named "'..tostring(filename)..'" exists.')
	end
	sysFiles[filename] = nil
end

function MasterEnvironment.os.rename(oldname,newname)
	if not sysFiles[oldname] then
		error('No file named "'..tostring(oldname)..'" exists.')
	end
	if sysFiles[newname] then
		error('File "'..newname..'" already exists.')
	end
	sysFiles[newname] = sysFiles[oldname]
	sysFiles[oldname] = nil
end

function MasterEnvironment.os.execute(command)
	local dot = string.find(command,'%.')
	if not dot then
		error('File must have a valid extension.')
	end
	local extension = string.sub(command,dot)
	if extension:sub(1,4) == '.sys' then
		if not MasterEnvironment.os[command:sub(1,dot+3)] then
			error('No file named "'..tostring(command:sub(1,dot+4))..'" exists.')
		end
		error('Files in the system directory are read-only.')
	elseif extension:sub(1,6) == '.index' then
		if not sysFiles[command:sub(1,dot+5)] then
			error('No file named "'..tostring(command:sub(1,dot+6))..'" exists.')
		end
		error('index files cannot be executed.')
	elseif extension:sub(1,4) == '.exe' then
		if not sysFiles[command:sub(1,dot+3)] then
			error('No file named "'..tostring(command:sub(1,dot+3))..'" exists.')
		end
		local slash = string.sub(command,dot+4,dot+4)
		if slash == '' then
			local file = command:sub(1,dot+5)
			if type(file) ~= 'function' then
				error('File "'..command:sub(1,dot+3)..'" has subdirectories and cannot be directly executed.')
			end
			sysFiles[file]()
		elseif slash == '/' then
			local file = sysFiles[command:sub(1,dot+3)]
			local path = string.sub(command,dot+5)
			if type(file) ~= 'table' or not file[path] then
				error('Path "'..tostring(path)..'"" does not exist in file '..command:sub(1,dot+3)..'.')
			end
			if type(file[path]) ~= 'function' then
				error('Path "'..tostring(path)..'" is malformed in file '..command:sub(1,dot+3)..'.')
			end
			file[path]()
		else
			error('Malformed method string when attempting to execute "'..tostring(command)..'."')
		end
	else
		error('Unrecognized file extension type "'..tostring(extension)..'."')
	end
end

-- Recreating bits of the io library from Lua 5.1 for ReSync
local inputOutput = {
	open = function(filename)
		if sysFiles[filename] then
			currentlyOpen = {filename,sysFiles[filename]}
		elseif MasterEnvironment.os[filename] then
			currentlyOpen = {filename,MasterEnvironment.os[filename]}
		else
			local dot = string.find(filename,'%.')
			if not dot then
				error('File must have a valid extension.')
			end
			local extension = string.sub(filename,dot)
			if extension == '.sys' then
				MasterEnvironment.os[filename] = {}
				currentlyOpen = {filename,MasterEnvironment.os[filename]}
			elseif extension == '.index' then
				sysFiles[filename] = {}
				currentlyOpen = {filename,sysFiles[filename]}
			elseif extension == '.exe' then
				sysFiles[filename] = function()end
				currentlyOpen = {filename,sysFiles[filename]}
			else
				error('Unrecognized file extension type "'..tostring(extension)..'."')
			end
		end
	end,
	write = function(output) -- Different from file:write()
		print(output)
	end,
	flush = function() -- Save & keep open
		if not currentlyOpen then
			error('No file is currently open.')
		end
		local dot = string.find(currentlyOpen[1],'%.')
		if not dot then
			error('File must have a valid extension.')
		end
		local extension = string.sub(currentlyOpen[1],dot)
		if extension == '.sys' then
			MasterEnvironment.os[currentlyOpen[1]] = currentlyOpen[2]
		else
			sysFiles[currentlyOpen[1]] = currentlyOpen[2]
		end
		-- currentlyOpen = nil
	end,
	close = function() -- Closes without saving
		if not currentlyOpen then
			error('No file is currently open.')
		end
		currentlyOpen = nil
	end,
	read = function(osfile)
		if MasterEnvironment.os[osfile] then
			return MasterEnvironment.os[osfile]
		else
			error('No file named "'..tostring(osfile)..'" exists in the current OS. Perhaps it\'s a standard system file?')
		end
	end,
}

-- It's different in pure Lua, but here it will be the same
inputOutput.input = inputOutput.open

-- Another recreation of Lua's original libraries for ReSync's internals
local fileStream = {}

function fileStream:close()
	inputOutput.close()
end

function fileStream:flush()
	inputOutput:flush()
end

function fileStream:read(filename)
	if sysFiles[filename] then
		return sysFiles[filename]
	else
		error('No file named "'..tostring(filename)..'" exists in the system files directory. Maybe it\'s an os file?')
	end
end

function fileStream:write(edit)
	if not currentlyOpen then
		error('No file is currently open.')
	end
	-- Had file mismatch detection, but due to .exes being able to be both
	-- functions and tables, I removed it
	currentlyOpen[2] = edit
end

MasterEnvironment.io = inputOutput
MasterEnvironment.file = fileStream

--//CHANGE THIS TO LOADSTRING
local module = require(script.ModuleScript)
setfenv(module,MasterEnvironment)
module()
