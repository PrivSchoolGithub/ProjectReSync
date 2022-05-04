--[[
                           ______________________
                           ___    |__    |___  _/
                           __  /| |_  /| |__  /  
                           _  ___ |  ___ |_/ /   
                           /_/  |_/_/  |_/___/   
                        ========================
                        Advanced Admin Internals
                            ================
                          >>  Sezei.me  <<
    ======================================================================================
    
    This Script
    -----------
    Authors                 MasterScootScoot
    Description             Documentation for Lua loader
    --------------------------------------------------------------------------------------
    
    >> IMPORTANT <<
	Your use of this code is subject to Advanced Admin's Terms of Use & Service.
	Visit the Command Center for detailed information regarding the TOS.
	
	>> WARNINGS <<
	- Making changes to this script may make AAE unstable or completely break it
	  altogether. 
	- No support will be given for custom modifications made to this
	  script.
	- Do not steal this and attempt to publish it under your name. Doing so will
	  make you subject to the penalties outlined in the TOS.
	
	>> NOTICE <<
	Nothing in this script will run. This is for documentation purposes only.
]]

-- NOTE TO SELF: CodeGenerator & Parser talk to each other most

--[[
TABLE OF CONTENTS
-----------------
Preface
I. Requiring the Module
II. Direct Execution
III. Proto Code
IV. Conclusion
Epilogue

--------------------------------------------------------------------------------------
Preface
I typically don't document internal workings, but I decided I wanted this for myself
for future reference. Additionally, for developers who are attempting to perform a
similar functionality for their code, I figured I would incorporate the
documentation for them, as well. I only ask that if you decide to use the work, you
leave credit where credit is due.
There are two ways you can use the module, with those being direct execution and
proto code manipulation. The following chapters will guide you through how to use
the Lua executor.

--------------------------------------------------------------------------------------
I. Requiring the Module
To use the module, it must first be required. I'm sure that if you are looking to
work with an advanced Lua interpreter and modify complex code, you know how to
require a module, but I'm going to put an example here, anyway.
]]
local executor = require(script.Parent)

--[[
--------------------------------------------------------------------------------------
II. Direct Execution
The :LoadString() function works similarly to the global loadstring() function,
which runs a string of code as a function. Because Roblox has disabled loadstring
by default, this is a viable proxy to the loadstring function. If you read into the
actual ANSI C (Commonly known as "C") libraries of Lua's workings, you'll find that
the components of the executor are very similar to Lua's basic structure, with the
only major difference being that the C language cannot be directly accessed from
Lua. Hence, the components that you see here function similarly to the C libraries,
but are written in pure Lua.

Functions
---------
:LoadString(luaString,dataTable)
 Returns boolean readSuccess true/false,functionOut
 Turns luaString into a lua function that can be run.
 Similar to loadstring().
 If the readSuccess value is false, the readSuccess value will be a string
 containing the reason why a failure occurred.
]]
-- EXAMPLE:
local success,luaCode = executor:LoadString('print("HELLO WORLD")',{
	SourceName = script:GetFullName(),
	Environment = getfenv(0)
})
luaCode()
-- RESULT: Outputs "HELLO WORLD" to the console.
-- EXAMPLE 2:
local success,problem = executor:LoadString('This will break!')
print(problem)
-- RESULT: Outputs "Incomplete statement: expected assignment or a function call" to the console.


--[[
--------------------------------------------------------------------------------------
III. Proto Code
The second way to use this module is through proto code manipulation and execution.
Credits for this part go to the SyncAdmin team for the original concept and
MasterScootScoot for revising, editing, and functionality. To understand how to make
use of this part of the module, you first have to understand what a proto is and how
it is used in the executor.

The :LoadString(luaString,dataTable) function works by converting the luaString
down to bytecode in two steps, and then running said bytecode through the FiOne
wrapper to return a runnable Lua function.

The first conversion step is to convert the Lua source code into a table structure
called a proto. This is an intermediate step between the raw source code and
bytecode. This structure is not human-readable, but makes it very easy to modify
the code at compile-time. This is mostly done in the Parser module, which also
invokes the Lexical Analyzer and Code Generator modules.

The second step is to convert the proto to bytecode. The Chunk Storage module is
responsible for this task. The compiled bytecode is then passed directly to the
FiOne interpreter module to be converted to a Lua function.

The executor module contains the necessary functions to halt this process and
return data that can't be directly used, but is caught in that intermediate step
and can be passed on to the other modules in order to complete the interpretation
process. The executor module is also capable of formatting the code as JavaScript
Object Notation (commonly known as "JSON") and then back to Lua.

Functions
---------
.ProtoCode:Create(luaCode,scriptName)
Returns boolean success true/false,protoOut
Converts the raw luaCode source into a proto, but then halts the compilation
process there. If the success result is false, the protoOut value will be a string
containing the error message.
]]
-- EXAMPLE:
local success,proto = executor.ProtoCode:Create('print("Hello, world!")')
-- RESULT: Returns a proto table that, when compiled, will yield a function that
-- will output "Hello, world!" to the console.

--[[
.ProtoCode:ExportJSON(proto)
Returns boolean ok true/false,JSONOut
Takes a proto and converts it into a JSON format. JSONOut will be a string that
can then be published to a web server for future retrieval. If the ok result is
false, the JSONOut value will be a string containing the error message.
]]
-- EXAMPLE:
local success,exportedJSON = executor.ProtoCode:ExportJSON(proto)
-- RESULT: Returns a JSON table version of the proto.

--[[
.ProtoCode:ImportJSON(JSON)
Returns boolean ok true/false,protoOut
Takes a JSON proto and converts it back to a Lua proto table state. If the ok
result is false, the protoOut value will be a string containing the error message.
]]
-- EXAMPLE:
-- No, Google does not run on a Lua proto. This is just an example.
local JSONProto = game:GetService('HttpService'):GetAsync('http://google.com')
local success,importedProto = executor.ProtoCode:ImportJSON(JSONProto)
-- RESULT: Returns a proto table that can be compiled

--[[
.ProtoCode:Load(proto,environment)
Returns boolean success true/false,wrap
Finalizes the compilation process by transforming the proto into bytecode and then
running it through the FiOne interpreter to create a wrapped function that can be
executed. The environment is a table of all the variables, functions, and other
data that the proto has access to. If no environment is specified, the global one
will be used.
]]
-- EXAMPLE:
local environment = {
	print = function(str)
		game:GetService('TestService'):Message(str)
	end,
}
local success,luaFunc = executor.ProtoCode:Load(proto,environment)
-- RESULT: Returns a function with access to a modified print statement.
-- EXAMPLE 2:
local function foo()
	bar = 'Hello!!' -- This won't work if it's local
	local success,luaFunc = executor.ProtoCode:Load(proto,getfenv(1))
	luaFunc()
end
foo()
-- RESULT: Returns a function with access to "bar."
-- EXAMPLE 3:
local success,luaFunc = executor.ProtoCode:Load(proto) -- or ,getfenv(0)
-- RESULT: Returns a function with access to the global environment.

--[[
IV. Conclusion
proto cant be httpservicejson encoded must be formatted with protocode:import/xport json

Epilogue
The following is a list of the original components for reference purposes.
The modules essentially reconstruct multiple .c and .h files from the Lua C
library, so I've included all the references inside of each file.
Files surrounded with <> mean that the file could not be found, but one or more
references are made to it in the module:
-------
FORMAT:
CurrentName 	|	LBI/YueliangName 	|	CName(s)
---------------- ----------------------- -----------
BufferedStreams |	LuaZ				| MAIN: lzio.c/lzio.h, INVOKES: lapi.c/lundump.c/lundump.c/lauxlib.c/luaconf.h
Parser 			|	LuaY				| MAIN: lparser.c/lparser.h, INVOKES: lmem.c/lfunc.c/lobject.c/luaconf.h/<limits.h>/llimits.h/lua.h/lmem.h/lcode.h(?)
LexicalAnalyzer |	LuaX				| MAIN: llex.c/llex.h
CodeGenerator 	|	LuaK				| MAIN: lopcodes.h
MachineOpcodes	|	LuaP				| MAIN: lopcodes.c
ChunkStorage	|	LuaU				| ???: lobject.c/lobject.h/lua.h/lundump.h
Interpreter		|	LBI/FiOne[Wrapper]	| N/A (Custom interpreter)

]]
