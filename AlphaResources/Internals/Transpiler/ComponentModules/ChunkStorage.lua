--/General Notes
-- + Many binary chunk functions have had the size parameter removed, since
--   output is in the form of a string and some sizes are implicit or hard coded

--/Requires Component Modules
local luaU = {}
local luaP = require(script.Parent:WaitForChild('MachineOpcodes'))

--/Mark for Precompiled Code
-- + ('<esc>Lua') (from lua.h)
luaU.LUA_SIGNATURE = '\27Lua'

--/Constants
------------
--//Constants used by Dumper (from lua.h)
luaU.TypeValues = {
	None = -1,
	Nil = 0,
	Boolean = 1,
	Number = 3,
	String = 4,
}

--luaU.LUA_TNUMBER  = 3
--luaU.LUA_TSTRING  = 4
--luaU.LUA_TNIL     = 0
--luaU.LUA_TBOOLEAN = 1
--luaU.LUA_TNONE    = -1

--//Constants for Header of Binary Files
-- + (from lundump.h)
luaU.LUAC_VERSION = 0x51 -- This is Lua 5.1
luaU.LUAC_FORMAT = 0 -- This is the official format
luaU.LUAC_HEADERSIZE = 12 -- Size of header of binary files

--/Chunk Writing Functions
--//Create_ToString
-- + Creates a chunk writer that writes to a string
-- * Returnt the writer function and a table containing the string
-- + To get the final result, look in buffer.data
function luaU:Create_ToString()
	local buffer = {}
	buffer.data = ''
	local writer = function(s,buffer) -- Chunk writer
		if not s then
			return 0
		end
		buffer.data = buffer.data..s
		return 0
	end
	return writer,buffer
end

--//make_setF
-- + Creates a chunk writer that writes to a file
-- * Returns the writer function and table containing the file handle
-- + If a nil value is passed, then writer should close the open file
-- | make_setF has been deleted due to Roblox limitations on LuaU

--//CheckType
-- + Works like the lobject.h version except that TObject used in these
--	 scripts only has a "value" field, no "tt" field (native types used)
-- + Using generic "data" as argument since I can't be bothered to look into
--   it further
function luaU:CheckType(data)
	local typeValue = type(data.value)
	if typeValue == 'number' then
		return self.TypeValues.Number
	elseif typeValue == 'string' then
		return self.TypeValues.String
	elseif typeValue == 'nil' then
		return self.TypeValues.Nil
	elseif typeValue == 'boolean' then
		return self.TypeValues.Boolean
	else
		return self.TypeValues.None -- The rest should not appear
	end
end

--//FromDouble
-- + Converts an IEEE754 double number to an 8-byte little-endian string
-- + luaU:FromDouble() and luaU:FromInteger() are adapted from ChunkBake
-- + Supports +/- Infinity, but not denormals or NaNs
function luaU:FromDouble(double)
	local function grabByte(value)
		local character = value%256 -- Character I THINK
		return (value-character)/256,string.char(character)
	end
	local sign = 0
	if double < 0 then
		sign = 1
		double = -double
	end
	local mantissa,exponent = math.frexp(double)
	if double == 0 then
		mantissa,exponent = 0,0
	elseif double == 1/0 then
		mantissa,exponent = 0,2047
	else
		mantissa = (mantissa*2-1)*math.ldexp(0.5,53)
		exponent = exponent+1022
	end
	local value,byte = '' -- Convert to bytes
	double = math.floor(mantissa)
	for iteration = 1,6 do
		double,byte = grabByte(double)
		value = value..byte -- 47:0
	end
	double,byte = grabByte(exponent*16+double)
	value = value..byte -- 55:48
	double,byte = grabByte(sign*128+double)
	value = value..byte -- 63:56
	return value
end

--//FromInteger
-- + Converts a number to a little-endian 32-bit integer string
-- + Input value assumed to not overflow, can be signed/unsigned
function luaU:FromInteger(int)
	local value = ''
	int = math.floor(int)
	if int < 0 then
		int = 4294967296+int -- ULONG_MAX+1
	end
	for iteration = 1,4 do
		local character = int%256
		value = value..string.char(character)
		int = math.floor(int/256)
	end
	return value
end

--/Binary Chunk Functions
--//Dump Structure
-- + ----------
-- + STRUCTURE:
-- + ----------
-- + L: luaState
-- + writer: Chunk writer function
-- + data: void* (Chunk writer context or data already written)
-- + strip: If true, doesn't write any debug information
-- + status: If non-zero, an error has occurred

--//DumpBlock
-- + Dumps a block of bytes
-- + lua_unlock(dumpState.L), lua_lock(dumpState.L) unused
function luaU:DumpBlock(bytes,dumpState)
	if dumpState.status == 0 then
		dumpState.status = dumpState.write(bytes,dumpState.data)
	end
end

--//DumpChar
-- + Dumps a character
function luaU:DumpChar(toChar,dumpState)
	self:DumpBlock(string.char(toChar),dumpState)
end

--//DumpInt
-- + Dumps a 32-bit signed or unsigned integer (for int) (hard coded)
function luaU:DumpInt(int,dumpState)
	self:DumpBlock(self:FromInteger(int),dumpState)
end

--//DumpNumber
-- + Dumps a lua_Number (hard-coded as a double)
-- + Number vs. integer is that int cannot be decimal
function luaU:DumpNumber(number,dumpState)
	self:DumpBlock(self:FromDouble(number),dumpState)
end

--//DumpString
-- + Dumps a Lua string (size type is hard coded)
-- + Technically a bad practice to use string as variable but meh it's a small
--   function
function luaU:DumpString(string,dumpState)
	if string == nil then
		self:DumpInt(0,dumpState)
	else
		string = string..'\0' -- Include trailing "\0"
		self:DumpInt(#string,dumpState)
		self:DumpBlock(string,dumpState)
	end
end

--//DumpCode
-- + Dumps an instruction block from function prototype
function luaU:DumpCode(proto,dumpState)
	local size = proto.sizecode
	-- Was DumpVector
	self:DumpInt(size,dumpState)
	for iteration = 0,size-1 do
		self:DumpBlock(luaP:FieldToChar(proto.code[iteration]),dumpState)
	end
end

--//DumpConstants
-- + Dumps constant pool from function prototype
-- * bvalue(o), nvalue(o) and rawtsvalue(o) macros removed
function luaU:DumpConstants(proto,dumpState)
	local size = proto.sizek
	self:DumpInt(size,dumpState)
	for iteration = 0,size-1 do
		local realValue = proto.k[iteration]
		local typeValue = self:CheckType(realValue)
		self:DumpChar(typeValue,dumpState)
		if typeValue == self.TypeValues.Nil then
			-- Do nothing
		elseif typeValue == self.TypeValues.Boolean then
			self:DumpChar(realValue.value and 1 or 0,dumpState)
		elseif typeValue == self.TypeValues.Number then
			self:DumpNumber(realValue.value,dumpState)
		elseif typeValue == self.TypeValues.String then
			self:DumpString(realValue.value,dumpState)
		else
			--lua_assert(0) -- Cannot happen
		end
	end
	size = proto.sizep
	self:DumpInt(size,dumpState)
	for iteration = 0,size-1 do
		self:DumpFunction(proto.p[iteration],proto.source,dumpState)
	end
end

--//DumpDebug
-- + Dumps debugging information
-- + dbInfo is short for "debugInfo"
function luaU:DumpDebug(proto,dumpState)
	-- Dump line information
	local dbInfo = dumpState.strip and 0 or proto.sizelineinfo
	-- Was DumpVector
	self:DumpInt(dbInfo,dumpState)
	for iteration = 0,dbInfo-1 do
		self:DumpInt(proto.lineinfo[iteration],dumpState)
	end
	
	-- Dump local information
	dbInfo = dumpState.strip and 0 or proto.sizelocalvars
	self:DumpInt(dbInfo,dumpState)
	for iteration = 0,dbInfo-1 do
		self:DumpString(proto.locvars[iteration].varname,dumpState)
		self:DumpInt(proto.locvars[iteration].startpc,dumpState)
		self:DumpInt(proto.locvars[iteration].endpc,dumpState)
	end
	
	-- Dump upvalue information
	dbInfo = dumpState.strip and 0 or proto.sizeupvalues
	self:DumpInt(dbInfo,dumpState)
	for iteration = 0,dbInfo-1 do
		self:DumpString(proto.upvalues[iteration],dumpState)
	end
end

--//DumpFunction
-- + Dumps child function prototypes from function prototype
function luaU:DumpFunction(proto,source,dumpState)
	if source == proto.source or dumpState.strip then
		source = nil
	end
	self:DumpString(source,dumpState)
	self:DumpInt(proto.lineDefined,dumpState)
	self:DumpInt(proto.lastlinedefined,dumpState)
	self:DumpChar(proto.nups,dumpState)
	self:DumpChar(proto.numparams,dumpState)
	self:DumpChar(proto.is_vararg,dumpState)
	self:DumpChar(proto.maxstacksize,dumpState)
	self:DumpCode(proto,dumpState)
	self:DumpConstants(proto,dumpState)
	self:DumpDebug(proto,dumpState)
end

--//DumpHeader
-- + Dumps Lua header section (Some sizes hard coded)
function luaU:DumpHeader(dumpState)
	local header = self:MakeHeader()
	assert(#header == self.LUAC_HEADERSIZE) -- Fixed buffer now an assert
	self:DumpBlock(header,dumpState)
end

--//MakeHeader
-- + From lundump.c
-- + Returns the header string
-- + ----------
-- + STRUCTURE:
-- + ----------
-- + 1: x, endianness (1 = little)
-- + 4[1]: sizeof(int)
-- + 4[2]: sizeof(size_t)
-- + 4[3]: sizeof(Instruction)
-- + 8: sizeof(lua_Number)
-- + 0: is lua_Number integral?
function luaU:MakeHeader()
	return self.LUA_SIGNATURE..string.char(self.LUAC_VERSION,self.LUAC_FORMAT,1,4,4,4,8,0)
end

--//Dump
-- Main dump Lua function as precompiled chunk
-- + (lua_State* L, const Proto* f, lua_Writer w, void* data, int strip)
-- * w, data are created from make_setS, make_setF
function luaU:Dump(luaState,proto,writer,void,strip)
	local dumpState = {
		L = luaState,
		write = writer,
		data = void,
		strip = strip,
		status = 0,
	}
	self:DumpHeader(dumpState)
	self:DumpFunction(proto,nil,dumpState)
	-- Added: For a chunk writer writing to a file, this final call with
	-- nil data is to indicate to the writer to close the file.
	-- And removed: Roblox Lua doesn't allow this, so goodbye file writing.
	-- | dumpState.write(nil,dumpState.data)
	return dumpState.status
end

return luaU

--/Notes by og author go bye bye soon

--[[--------------------------------------------------------------------

  ldump.lua
  Save precompiled Lua chunks
  This file is part of Yueliang.

  Copyright (c) 2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Notes:
-- * WARNING! byte order (little endian) and data type sizes for header
--   signature values hard-coded; see luaU:MakeHeader
-- * chunk writer generators are included, see below
-- * one significant difference is that instructions are still in table
--   form (with OP/A/B/C/Bx fields) and luaP:FieldToChar() is needed to
--   convert them into 4-char strings
--
-- Not implemented:
-- * DumpVar, DumpMem has been removed
-- * DumpVector folded into folded into DumpDebug, DumpCode
--
-- Added:
-- * for convenience, the following two functions have been added:
--   luaU:make_setS: create a chunk writer that writes to a string
--   luaU:make_setF: create a chunk writer that writes to a file
--   (lua.h contains a typedef for lua_Writer/lua_Chunkwriter, and
--    a Lua-based implementation exists, writer() in lstrlib.c)
-- * luaU:ttype(o) (from lobject.h)
-- * for converting number types to its binary equivalent:
--   luaU:from_double(x): encode double value for writing
--   luaU:from_int(x): encode integer value for writing
--     (error checking is limited for these conversion functions)
--     (double conversion does not support denormals or NaNs)
--
-- Changed in 5.1.x:
-- * the dumper was mostly rewritten in Lua 5.1.x, so notes on the
--   differences between 5.0.x and 5.1.x is limited
-- * LUAC_VERSION bumped to 0x51, LUAC_FORMAT added
-- * developer is expected to adjust LUAC_FORMAT in order to identify
--   non-standard binary chunk formats
-- * header signature code is smaller, has been simplified, and is
--   tested as a single unit; its logic is shared with the undumper
-- * no more endian conversion, invalid endianness mean rejection
-- * opcode field sizes are no longer exposed in the header
-- * code moved to front of a prototype, followed by constants
-- * debug information moved to the end of the binary chunk, and the
--   relevant functions folded into a single function
-- * luaU:dump returns a writer status code
-- * chunk writer now implements status code because dumper uses it
-- * luaU:endianness removed
----------------------------------------------------------------------]]

