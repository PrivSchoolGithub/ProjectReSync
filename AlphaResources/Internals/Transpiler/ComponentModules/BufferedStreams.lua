--/Initial Module Definition
local luaZ = {
	ChunkReader = {},
	Input = {},
}

--/ChunkReader
--------------
--//CreateFromSourceString
-- + Creates a chunk reader from a source string
-- + reader() should return a string or nil if nothing else to parse.
--   Additional data can be set only during stream initialization.
-- + Readers are handled in luaxlib.c, see luaL_load(file|buffer|string)
-- + LUAL_BUFFERSIZE=BUFSIZ=512 in make_getF() (located in luaconf.h)
-- + Original Reader typedef:
--	 const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);
-- + This Lua chunk reader implementation:
--	 returns string or nil, no arguments to function
function luaZ.ChunkReader:CreateFromSourceString(sourceString)
	local buffer = sourceString
	return function() -- Chunk reader anonymous function here
		if not buffer then
			return nil
		end
		local newData = buffer
		buffer = nil
		return newData
	end
end

--//make_getF
-- | make_getF deleted; Roblox has removed the file library

--/Input
--------
--//CreateZIOStream
-- + Creates a ZIO input stream
-- + Returns the ZIO structure
-- + Current position, p, is now last read index instead of a pointer
-- + ---------
-- + STRUCTURE
-- + ---------
-- + n: bytes still unread
-- + p: last read position position in buffer
-- + reader: chunk reader function
-- + data: additional data
function luaZ.Input:CreateZIOStream(reader,data,name)
	if not reader then
		return
	end
	local ZIO = {}
	ZIO.reader = reader
	ZIO.data = data or ''
	ZIO.name = name
	-- Set up additional data for reading
	if not data or data == '' then
		ZIO.n = 0
	else
		ZIO.n = #data
	end
	ZIO.p = 0
	return ZIO
end

--//FillBuffer
-- + Fills up the input buffer
function luaZ.Input:FillBuffer(ZIO)
	local buffer = ZIO.reader()
	ZIO.data = buffer
	if not buffer or buffer == '' then
		return 'EOZ'
	end
	ZIO.n,ZIO.p = #buffer - 1,1
	return string.sub(buffer,1,1)
end

--//GetNextCharacter
-- + Retrieves the next character from the input stream
-- + Local n & p are used to optimize code generation
function luaZ:GetNextCharacter(ZIO)
	local unread,lastPos = ZIO.n,ZIO.p+1
	if unread > 0 then
		ZIO.n,ZIO.p = unread-1,lastPos
		return string.sub(ZIO.data,lastPos,lastPos)
	else
		return self.Input:FillBuffer(ZIO)
	end
end

return luaZ

--/Notes by the original author that will be murdered soon

--[[--------------------------------------------------------------------

  lzio.lua
  Lua buffered streams in Lua
  This file is part of Yueliang.

  Copyright (c) 2005-2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Notes:
-- * EOZ is implemented as a string, "EOZ"
-- * Format of z structure (ZIO)
--     z.n       -- bytes still unread
--     z.p       -- last read position position in buffer
--     z.reader  -- chunk reader function
--     z.data    -- additional data
-- * Current position, p, is now last read index instead of a pointer
--
-- Not implemented:
-- * luaZ_lookahead: used only in lapi.c:lua_load to detect binary chunk
-- * luaZ_read: used only in lundump.c:ezread to read +1 bytes
-- * luaZ_openspace: dropped; let Lua handle buffers as strings (used in
--   lundump.c:LoadString & lvm.c:luaV_concat)
-- * luaZ buffer macros: dropped; buffers are handled as strings
-- * lauxlib.c:getF reader implementation has an extraline flag to
--   skip over a shbang (#!) line, this is not implemented here
--
-- Added:
-- (both of the following are vaguely adapted from lauxlib.c)
-- * luaZ:make_getS: create Reader from a string
-- * luaZ:make_getF: create Reader that reads from a file
--
-- Changed in 5.1.x:
-- * Chunkreader renamed to Reader (ditto with Chunkwriter)
-- * Zio struct: no more name string, added Lua state for reader
--   (however, Yueliang readers do not require a Lua state)
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- create a chunk reader from a source file
------------------------------------------------------------------------
--[[
function luaZ:make_getF(filename)
  local LUAL_BUFFERSIZE = 512
  local h = io.open(filename, "r")
  if not h then return nil end
  return function() -- chunk reader anonymous function here
    if not h or io.type(h) == "closed file" then return nil end
    local buff = h:read(LUAL_BUFFERSIZE)
    if not buff then h:close(); h = nil end
    return buff
  end
end
--]]
