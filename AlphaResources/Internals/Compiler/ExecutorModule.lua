--[[
                          _____    _____  _____              
                         |  __ \  / ____||_   _|              
                         | |__) || (___    | |
                         |  _  /  \___ \   | |
                         | | \ \  ____) | _| |_
                         |_|  \_\|_____/ |_____|
                         =======================
                            ReSync Internals
                            ================
                          	 >> Sezei.me <<
                            
    ------------------------------------------------------------------------------
    
    This Script
    -----------
    Authors                 MasterScootScoot, Kein-Hong Man (Yueliang),
    						Fabien Fleutot (MetaLua), Stravant, cntkillme,
    						Rerumu (FiOne), einsteinK, AtomicRoomba (SyncAdmin),
    						AtAltitude (SyncAdmin), Polymatic Labs Inc. (SyncAdmin)
    Description             Custom loadstring module with JSON support
    ------------------------------------------------------------------------------

    >> IMPORTANT <<
	Your use of this code is subject to ReSync's Terms of Use & Service.
	See the "About" script in the main model for detailed information regarding
	the TOS.
	
	>> WARNINGS <<
	- Making changes to this script may make ReSync unstable or completely break it
	  altogether. 
	- No support will be made for custom modifications made to this
	  script.
	- Do not steal this and attempt to publish it under your name. Doing so will
	  make you subject to the penalties outlined in the TOS.
	  
]]

--//Initialization
local dependencies = {
	Interpreter = 'Interpreter',
	LuaK = 'CodeGenerator',
	LuaP = 'MachineOpcodes',
	LuaU = 'ChunkStorage',
	LuaX = 'LexicalAnalyzer',
	LuaY = 'Parser',
	LuaZ = 'BufferedStreams',
}

local modules = {}

for knownAs,moduleName in pairs(dependencies) do
	modules[moduleName] = require(script:WaitForChild(moduleName))
end

modules.LexicalAnalyzer:Initialize()
local luaState = {}

local httpService = game:GetService('HttpService')

--//JSON Functions
local function JavaScriptObjectNotationToLuaProto(decode,JSONString)
	local convertedTable = JSONString
	if decode then
		convertedTable = httpService:JSONDecode(JSONString)
	end
	
	local function fix(parent,key,array)
		local minimum = array.R.N
		local maximum = array.R.M
		local values = array.V
		
		local offset = 1 - minimum
		
		local fixed = {}
		for iteration = minimum,maximum do
			fixed[iteration] = values[iteration+offset]
		end
		
		parent[key] = fixed
	end
	
	local done = {} -- Otherwise it will loop FOREVER and cause stack overflow
	
	local function addNilValues(luaTable)
		for key,value in pairs(luaTable) do
			if type(value) == 'table' and not done[value] then
				done[value] = true
				addNilValues(luaTable)
				if value.R then
					fix(luaTable,key,value)
					value.R = nil
					value.V = nil
				end
			end
		end
	end
	
	addNilValues(convertedTable)
	return convertedTable
end

local function formatProtoForExtraction(proto)
	proto.ZeroIndexes = {}
	for key,value in pairs(proto) do
		if type(value) == 'table' then
			if value[0] then
				proto.ZeroIndexes[key] = value[0]
			end
		end
	end
	return proto
end

local function formatProtoForRead(proto)
	for key,value in pairs(proto.ZeroIndexes) do
		proto[key][0] = value
		proto.ZeroIndexes[key] = nil
	end
	return proto
end

--//Lua Execution Functions
local function createProto(source,name)
	local ZIO = modules.BufferedStreams.Input:CreateZIOStream(modules.BufferedStreams.ChunkReader:CreateFromSourceString(source),nil)
	if not ZIO then
		return error()
	end
	return modules.Parser:Parse(luaState,ZIO,nil,name)
end

local function readProto(proto,environment)
	if not environment then
		environment = getfenv(0)
	end
	local writer,buffer = modules.ChunkStorage:Create_ToString()
	modules.ChunkStorage:Dump(luaState,proto,writer,buffer)
	local luaFunc = modules.Interpreter.wrap_lua(modules.Interpreter.stm_lua(buffer.data),environment)
	return luaFunc,buffer.data
end

local function readLua(source,data)
	-- Get the information we passed in
	data = data or {}
	local environment = data.Environment or getfenv(2)
	local name = data.SourceName or (environment.script and environment.script:GetFullName())
	
	-- Convert code to Proto
	local ok,response = pcall(createProto,source,name)
	if not ok then
		return false,response
	end
	
	-- Read the proto and convert to function
	-- luafunc OR error, but I didn't feel like making a very long variable
	local good,luaFunc = pcall(readProto,response,environment)
	
	return good,luaFunc
end

--//Main Module
local executorModule = { -- This ModuleScript
	ProtoCode = {},
}

--/Proto Functions
function executorModule.ProtoCode:Create(luaCode,scriptName)
	local protoOut
	local success,issue = pcall(function()
		protoOut = createProto(luaCode,scriptName)
	end)
	return success,issue or protoOut
end

function executorModule.ProtoCode:ExportJSON(proto)
	local formattedIn,JSONOut
	local success,problem = pcall(function()
		formattedIn = formatProtoForExtraction(proto)
	end)
	if not success then
		return false,problem
	end
	local ok,issue = pcall(function()
		JSONOut = httpService:JSONEncode(formattedIn)
	end)
	return ok,issue or JSONOut
end

function executorModule.ProtoCode:ImportJSON(decodeJSON,JSON)
	-- Can't use "in" as a variable due to it being a keyword
	local protoIn,protoOut
	local success,problem = pcall(function()
		protoIn = JavaScriptObjectNotationToLuaProto(decodeJSON,JSON)
	end)
	if not success then
		return false,problem
	end
	local ok,issue = pcall(function()
		protoOut = formatProtoForRead(protoIn)
	end)
	return ok,protoOut
end

function executorModule.ProtoCode:Load(proto,environment)
	local wrap
	local success,problem = pcall(function()
		wrap = readProto(proto,environment)
	end)
	if not success then
		return false,problem
	end
	return success,wrap
end

--/Direct Execution
function executorModule:LoadString(luaString,dataTable)
	local success,readSuccess,functionOut = pcall(readLua,luaString,dataTable)
	if not success then
		return false,readSuccess
	end
	return readSuccess,functionOut
end

return executorModule
