--/General Notes
--//FIRST_RESERVED
-- + First Res is not required, as tokens are manipulated as strings
--//TOKEN_LEN
-- + Token Length deleted; maximum length of a reserved word is not needed
--//ORDER RESERVED
-- + "ORDER RESERVED" deleted; enumeration in one place: luaX.ReservedWords

--/Requires Component Modules
local luaX = {}
local luaZ = require(script.Parent:WaitForChild('BufferedStreams'))

--/Terminal Symbols
-------------------
-- + Terminal symbols denoted by reserved words: TK_AND to TK_WHILE
-- + Other terminal symbols: TK_NAME to TK_EOS
-- + NUM_RESERVED is not required; number of reserved words
luaX.ReservedWords = [[
TK_AND and
TK_BREAK break
TK_DO do
TK_ELSE else
TK_ELSEIF elseif
TK_END end
TK_FALSE false
TK_FOR for
TK_FUNCTION function
TK_IF if
TK_IN in
TK_LOCAL local
TK_NIL nil
TK_NOT not
TK_OR or
TK_REPEAT repeat
TK_RETURN return
TK_THEN then
TK_TRUE true
TK_UNTIL until
TK_WHILE while
TK_CONCAT ..
TK_DOTS ...
TK_EQ ==
TK_GE >=
TK_LE <=
TK_NE ~=
TK_NAME <name>
TK_NUMBER <number>
TK_STRING <string>
TK_EOS <eof>]]

--/Miscellaneous
-- @ Functions & data that didn't really fit anywhere else
-- @ luaX.MAX_SIZET = 4294967293 deleted
-----------------
luaX.MAXSRC = 80
luaX.MAX_INT = 2147483645 -- Constants from elsewhere (see above)
luaX.LUA_QS = "'%s'"
luaX.LUA_COMPAT_LSTR = 1

--/Initialize
-- + Initializes Lexer
-- * luaX.tokens (was luaX_tokens) is now a hash
-- * Original luaX_init has code to create & register token strings
-- * luaX.tokens: TK_* -> token
-- * luaX.enums:  token -> TK_* (used in luaX:Analyze)
-- * SemInfo struct no longer needed, a mixed-type value is used
-- * Token is table of lexState.t and lexState.lookahead
-- * Instead of passing semantics info, the Token table (lexState.t) is passed
--   so that Lexer functions can use its table element, lexState.t.seminfo
-- + ----------------
-- + TOKEN STRUCTURE:
-- + ----------------
-- + token: token symbol
-- + seminfo: semantics information
-- + -------------------
-- + LEXSTATE STRUCTURE:
-- + -------------------
-- * THIS IS NOT LUASTATE!!
-- + current: current character (charint)
-- + linenumber: input line counter
-- + lastline: line of last token :consumed"😋
-- + t: current token (table: Token)
-- + lookahead: look ahead token (table: Token)
-- + fs: "FunctionState" is private to the parser
-- + L: LuaState
-- + z: input stream
-- + buff: buffer for tokens
-- + source: current source namecurrent source name
-- + decpoint: locale decimal point
-- + nestlevel: level of nested non-terminals
function luaX:Initialize()
	local tokens,enums = {},{}
	for value in string.gmatch(self.ReservedWords,'[^\n]+') do
		local _,_,token,str = string.find(value,'(%S+)%s+(%S+)')
		tokens[token] = str
		enums[str] = token
	end
	self.Tokens = tokens
	self.Enums = enums
end

--/ChunkID
-- + Returns a suitably-formatted chunk name or ID
-- * From lobject.c, used in llex.c and ldebug.c
-- * The result, out, is returned (was first argument)
function luaX:ChunkID(source,bufferLength)
	local out
	local first = string.sub(source,1,1)
	if first == '=' then
		out = string.sub(source,2,bufferLength) -- Remove first character
	else -- out = 'source', or '...source'
		if first == '@' then
			source = string.sub(source,2) -- Skip the @
			bufferLength = bufferLength - #' \'...\' ' -- " '...' "
			local sourceLength = #source
			out = ''
			if sourceLength > bufferLength then
				source = string.sub(source,1+sourceLength-bufferLength) -- Get last part of file name
				out = out..'...'
			end
			out = out..source
		else -- out = [string 'string']
			local length = string.find(source,'[\n\r]') -- Stop at first newline
			length = length and (length-1) or #source
			bufferLength = bufferLength-#(' [string "..."] ')
			if length > bufferLength then
				length = bufferLength
			end
			out = '[string "'
			if length < #source then -- Must truncate?
				out = out..string.sub(source,1,length)..'...'
			else
				out = out..source
			end
			out = out..'"]'
		end
	end
	return out
end

--/Support Functions for Lexer
-- * All Lexer errors eventually reach CodeFailure:
--	 SyntaxError -> CodeFailure
------------------------------
--//TokenToString
-- + Looks up token and returns keyword if found (Also called by Parser)
function luaX:TokenToString(luaState,token)
	if string.sub(token,1,3) ~= 'TK_' then
		if string.find(token,'%c') then
			return string.formar('char(%d)',string.byte(token))
		end
		return token
		else
	end
	return self.Tokens[token]
end

--//CodeFailure
-- + Throws a Lexer error
-- * txtToken has been made local to luaX:CodeFailure
-- * can't communicate LUA_ERRSYNTAX, so it is unimplemented
function luaX:CodeFailure(luaState,errorMessage,token)
	local function textToken(ls,tk)
		if tk == 'TK_NAME' or tk == 'TK_STRING' or tk == 'TK_NUMBER' then
			return ls.buff
		else
			return self:TokenToString(ls,tk)
		end
	end
	
	local buffer = self:ChunkID(luaState.source,self.MAXSRC)
	-- local msg = string.format("%s:%d: %s", buff, ls.linenumber, msg)
	local message = string.format('%s','Internal error: '..errorMessage)
	if token then
		message = string.format('%s near '..self.LUA_QS,message,textToken(luaState,token))
	end
	-- luaD_throw(ls->L,LUA_ERRSYNTAX)
	error(message)
end

--//SyntaxError
-- + Throws a syntax error (Mainly called by Parser)
-- * ls.t.token has to be set by the function calling luaX:Analyze
--   (see luaX:next and luaX:FillLABuffer elsewhere in this file)
function luaX:SyntaxError(luaState,message)
	self:CodeFailure(luaState,message,luaState.t.token)
end

--/Move on to Next Line
--//CurrentIsNewLine
function luaX:CurrentIsNewLine(luaState)
	return luaState.current == '\n' or luaState.current == '\r'
end

--//InclineNumber
function luaX:InclineNumber(luaState)
	local former = luaState.current
	-- lua_assert(CurrentIsNewLine(ls))
	self:NextCharacter(luaState) -- Skip \n or \r
	if self:CurrentIsNewLine(luaState) and luaState.current ~= former then
		self:NextCharacter(luaState) -- Skip \n\r or \r\n
	end
	luaState.linenumber += 1
	if luaState.linenumber >= self.MAX_INT then
		self:syntaxerror(luaState,'chunk has too many lines')
	end
end

--//SetInput
-- + Initializes an input string for lexing
-- * If ls (the lexer state) is passed as a table, then it is filled in,
--   otherwise it has to be retrieved as a return value
-- * LUA_MINBUFFER not used; buffer handling not required any more
function luaX:SetInput(luaState,lexState,ZIO,sourceName)
	if not lexState then
		lexState = {} -- Create struct
	end
	if not lexState.lookahead then
		lexState.lookahead = {}
	end
	if not lexState.t then
		lexState.t = {}
	end
	lexState.decpoint = '.'
	lexState.L = luaState
	lexState.lookahead.token = 'TK_EOS' -- No look-ahead token
	lexState.z = ZIO
	lexState.fs = nil
	lexState.linenumber = 1
	lexState.lastline = 1
	lexState.source = sourceName
	self:NextCharacter(lexState) -- Read first character
end

--/Lexical Analyzer
--//CheckNext
-- + Checks if current character read is found in the set "set"
function luaX:CheckNext(lexState,set)
	if not string.find(set,lexState.current,1,1) then
		return false
	end
	self:SaveAndNext(lexState)
	return true
end

--//RetrieveNextToken
-- + Retrieves the next token, checking the lookahead buffer if necessary
-- * Note that the macro next(ls) in llex.c is now luaX:NextCharacter
-- * Utilized used in lparser.c (various places)
function luaX:RetrieveNextToken(lexState)
	lexState.lastline = lexState.linenumber
	if lexState.lookahead.token ~= 'TK_EOS' then -- Is there a look-ahead token?
		-- This must be copy-by-value
		lexState.t.seminfo = lexState.lookahead.seminfo -- Use this one
		lexState.t.token = lexState.lookahead.token
		lexState.lookahead.token = 'TK_EOS' -- And discharge it
	else
		lexState.t.token = self:Analyze(lexState,lexState.t) -- Read next token
	end
end

--//FillLABuffer
-- + Fills in the LookAhead buffer
-- * Utilized in lparser.c:constructor
-- * :Constructor()? - Scoot
function luaX:FillLABuffer(lexState)
	-- lua_assert(ls.lookahead.token == "TK_EOS")
	lexState.lookahead.token = self:Analyze(lexState,lexState.lookahead)
end

--//NextCharacter
-- + Gets the next character and returns it
-- * This is the next() macro in llex.c; see notes at beginning
-- * Scoot's note: Notes have been killed for optimal reading :P
function luaX:NextCharacter(lexState)
	local character = luaZ:GetNextCharacter(lexState.z)
	lexState.current = character
	return character
end

--//SaveCharacter
-- + Saves the given character into the token buffer
-- * Buffer handling code removed, not used in this implementation
-- * Test for maximum token buffer length not used, makes things faster
function luaX:SaveCharacter(lexState,character)
	local buffer = lexState.buff
	-- If you want to use this, please uncomment luaX.MAX_SIZET further up
	--[[
	if #buffer > self.MAX_SIZET then
		self:CodeFailure(lexState,'lexical element too long')
	end
	]]
	lexState.buff = buffer..character
end

--//SaveAndNext
-- + Saves current character into token buffer, grabs next character
-- * Like luaX:NextCharacter, returns the character read for convenience
function luaX:SaveAndNext(lexState)
	self:SaveCharacter(lexState,lexState.current)
	return self:NextCharacter(lexState)
end

--//Lua Number
-- + luaX:ReadNumeral is the main lexer function to read a number
-- + luaX:StringToNumber, luaX:ReplaceCharacter, luaX:ConvertDecimal are support functions

--///StringToNumber
-- + String to number converter (was luaO_str2d from lobject.c)
-- * Returns the number, nil if fails (originally returns a boolean)
-- * Conversion function originally lua_str2number(s,p), a macro which
--   maps to the strtod() function by default (from luaconf.h)
function luaX:StringToNumber(str)
	local result = tonumber(str)
	if result then
		return result
	end
	-- Conversion failed
	if string.lower(string.sub(str,1,2)) == '0x' then -- Maybe a hexidecimal constant?
		result = tonumber(str,16)
		if result then
			return result -- Most common case
		end
		-- Was: Invalid trailing characters?
		-- In C, this function then skips over trailing spaces.
		-- true is returned if nothing else is found except for spaces.
		-- If there is still something else, then it returns a false.
		-- All this is not necessary using Lua's tonumber.
	end
	return nil -- Return nothing if all conversions have failed
end

--///ReplaceCharacter
-- + Single-character replacement
-- + For locale-aware decimal points
function luaX:ReplaceCharacter(lexState,from,to)
	local result,buffer = '',lexState.buff
	for place = 1,#buffer do
		local character = string.sub(buffer,place,place)
		if character == from then
			character = to
		end
		result = result..character
	end
	lexState.buff = result
end

--///ConvertDecimal
-- + Attemps to conver a number by translating "." decimal points to the decimal
--   point character used by the current locale. This is not needed in these
--	 modules, as Lua's tonumber() is already locale-aware. Instead, the code is
--	 here in case the user implements localeconv(). Probably not necessary since
--	 Roblox has likely overidden most of the default locale settings, but it's
--	 better to be safe than sorry.
function luaX:ConvertDecimal(lexState,token)
	-- Format error: Try to update decimal point separator
	local old = lexState.decpoint
	-- Translate the following to Lua if you implement localeconv():
	-- struct lconv *cv = localeconv();
	-- ls->decpoint = (cv ? cv->decimal_point[0] : '.');
	self:ReplaceCharacter(lexState,old,lexState.decpoint) -- Try updated decimal separator
	local semInfo = self:StringToNumber(lexState.buff)
	token.seminfo = semInfo
	if not semInfo then
		-- Format error with correct decimal point: No more options
		self:ReplaceCharacter(lexState,lexState.decpoint,'.') -- Undo change (For error message)
		self:CodeFailure(lexState,'malformed number','TK_NUMBER')
	end
end

--///ReadNumeral
-- + Main number conversion function
-- * "^%w$" needed in the scan in order to detect "EOZ"
function luaX:ReadNumeral(lexState,token)
	-- lua_assert(string.find(ls.current, "%d"))
	repeat
		self:SaveAndNext(lexState)
	until string.find(lexState.current,'%D') and lexState.current ~= '.'
	if self:CheckNext(lexState,'Ee') then -- "E"?
		self:CheckNext(lexState,'+-') -- Optional exponent sign
	end
	while string.find(lexState.current,'^%w$') or lexState.current == '_' do
		self:SaveAndNext(lexState)
	end
	self:ReplaceCharacter(lexState,'.',lexState.decpoint) -- Follow locale for decimal point
	local semInfo = self:StringToNumber(lexState.buff)
	token.seminfo = semInfo
	if not semInfo then -- Format error?
		self:ConvertDecimal(lexState,token) -- Try to update decimal point separator
	end
end

--//SkipSeparator
-- + Count separators ("=") in a long string delimiter
-- * Used by luaX:ReadLongString
function luaX:SkipSeparator(lexState)
	local count = 0
	local current = lexState.current
	-- lua_assert(s == "[" or s == "]")
	self:SaveAndNext(lexState)
	while lexState.current == '=' do
		self:SaveAndNext(lexState)
		count += 1
	end
	return (lexState.current == current) and count or (-count)-1
end

--//ReadLong
-- + Reads a long string or long comment
function luaX:ReadLong(lexState,token,separator)
	local cont = 0 -- Would use continue but continue is a special word
	self:SaveAndNext(lexState) -- Skip second "["
	if self:CurrentIsNewLine(lexState) then -- String starts with a newline?
		self:InclineNumber(lexState) -- Skip it
	end
	while true do
		local current = lexState.current
		if current == 'EOZ' then
			self:CodeFailure(lexState,token and 'unfinished long string' or 'unfinished long comment','TK_EOS')
		elseif current == '[' then
			-- Compatibility code start
			if self.LUA_COMPAT_LSTR then
				if self:SkipSeparator(lexState) == separator then
					self:SaveAndNext(lexState) -- Skip second "["
					cont += 1
					-- Compatibility code start
					if self.LUA_COMPAT_LSTR == 1 then
						if separator == 0 then
							self:CodeFailure(lexState,'nesting of [[...]] is deprecated','[')
						end
					end
					-- Compatibility code end
				end
			end
			-- Compatibility code end
		elseif current == ']' then
			if self:SkipSeparator(lexState) == separator then
				self:SaveAndNext(lexState) -- Skip second "["
				-- Compatibility code start
				if self.LUA_COMPAT_LSTR and self.LUA_COMPAT_LSTR == 2 then
					cont = cont - 1
					if separator == 0 and cont >= 0 then break end
				end
				-- Compatibility code end
				break
			end
		elseif self:CurrentIsNewLine(lexState) then
			self:SaveCharacter(lexState,'\n')
			self:InclineNumber(lexState)
			if not token then
				lexState.buff = '' -- Avoid wasting space
			end
		else -- Default
			if token then
				self:SaveAndNext(lexState)
			else
				self:NextCharacter(lexState)
			end
		end --if current
	end --while
	if token then
		local p = 3 + separator
		token.seminfo = string.sub(lexState.buff,p,-p)
	end
end

--//ReadString
-- + Reads a string (duh)
-- * Has been restructured significantly compared to the original C code
-- * And has been further redesigned by MasterScootScoot
-- * Reading is different from processing; processing is done in other modules
function luaX:ReadString(lexState,delimiter,token)
	self:SaveAndNext(lexState)
	while lexState.current ~= delimiter do
		local currentCharacter = lexState.current
		if currentCharacter == 'EOZ' then
			self:CodeFailure(lexState,'unfinished string','TK_EOS')
		elseif self:CurrentIsNewLine(lexState) then
			self:CodeFailure(lexState,'unfinished string','TK_STRING')
		elseif currentCharacter == "\\" then
			currentCharacter = self:NextCharacter(lexState) -- Do not save the "\"
			if self:CurrentIsNewLine(lexState) then -- Go through
				self:SaveCharacter(lexState,'\n')
				self:InclineNumber(lexState)
			elseif currentCharacter ~= 'EOZ' then -- Will raise an error next loop
				-- Escapes handling greatly simplified here:
				local match = string.find('abfnrtv',currentCharacter,1,1)
				if match then
					self:SaveCharacter(lexState,string.sub('\a\b\f\n\r\t\v',match,match))
					self:NextCharacter(lexState)
				elseif not string.find(currentCharacter,'%d') then
					self:SaveAndNext(lexState) -- Handles \\, \", \', and \?
				else -- \xxx [NO THATS NOT A BAD REFERENCE IT IS A CODE REFERENCE]
					-- get yo mind outta the gutter ;(
					currentCharacter,match = 0,0
					repeat
						currentCharacter = 10*currentCharacter+lexState.current
						self:NextCharacter(lexState)
						match += 1
					until match >= 3 or not string.find(lexState.current,'%d')
					if currentCharacter > 255 then -- UCHAR_MAX
						self:CodeFailure(lexState,'escape sequence too large','TK_STRING')
					end
					self:SaveCharacter(lexState,string.char(currentCharacter))
				end
			end
		else
			self:SaveAndNext(lexState)
		end --if currentCharacter
	end --while
	self:SaveAndNext(lexState) -- Skip delimiter
	token.seminfo = string.sub(lexState.buff,2,-2)
end

--//Analyze
-- Main Lexer function
function luaX:Analyze(lexState,token)
	lexState.buff = ''
	while true do
		local currentChar = lexState.current
		if self:CurrentIsNewLine(lexState) then
			self:InclineNumber(lexState)
		elseif currentChar == '-' then
			currentChar = self:NextCharacter(lexState)
			if currentChar ~= '-' then
				return '-'
			end
			-- Else is a comment
			local separator = -1
			if self:NextCharacter(lexState) == '[' then
				separator = self:SkipSeparator(lexState)
				lexState.buff = '' -- "SkipSeparator" may dirty the buffer
			end
			if separator >= 0 then
				self:ReadLong(lexState,nil,separator) -- Long comment
				lexState.buff = ''
			else -- Else short comment
				while not self:CurrentIsNewLine(lexState) and lexState.current ~= 'EOZ' do
					self:NextCharacter(lexState)
				end
			end
		elseif currentChar == '[' then
			local separator = self:SkipSeparator(lexState)
			if separator >= 0 then
				self:ReadLong(lexState,token,separator)
				return 'TK_STRING'
			elseif separator == -1 then
				return '['
			else
				self:CodeFailure(lexState,'invalid long string delimiter','TK_STRING')
			end
		elseif currentChar == '=' then
			currentChar = self:NextCharacter(lexState)
			if currentChar ~= '=' then
				return '='
			else
				self:NextCharacter(lexState)
				return 'TK_EQ'
			end
		elseif currentChar == '<' then
			currentChar = self:NextCharacter(lexState)
			if currentChar ~= '=' then
				return '<'
			else
				self:NextCharacter(lexState)
				return 'TK_LE'
			end
		elseif currentChar == '>' then
			currentChar = self:NextCharacter(lexState)
			if currentChar ~= '=' then
				return '>'
			else
				self:NextCharacter(lexState)
				return 'TK_GE'
			end
		elseif currentChar == '~' then -- Maybe also add "!" for other
									   -- language compatibility?
			currentChar = self:NextCharacter(lexState)
			if currentChar ~= '=' then
				return '~'
			else
				self:NextCharacter(lexState)
				return 'TK_NE'
			end
		elseif currentChar == '"' or currentChar == '\'' then
			self:ReadString(lexState,currentChar,token)
			return 'TK_STRING'
		elseif currentChar == '.' then
			currentChar = self:SaveAndNext(lexState)
			if self:CheckNext(lexState,'.') then
				if self:CheckNext(token,'.') then
					return 'TK_DOTS' -- ...
				else
					return 'TK_CONCAT' -- ..
				end
			elseif not string.find(currentChar,'%d') then
				return '.'
			else
				self:ReadNumeral(lexState,token)
				return 'TK_NUMBER'
			end
		elseif currentChar == 'EOZ' then
			return 'TK_EOS'
		else -- Default
			if string.find(currentChar,'%s') then
				-- lua_assert(self:CurrentIsNewLine(ls))
				self:NextCharacter(lexState)
			elseif string.find(currentChar,'%d') then
				self:ReadNumeral(lexState,token)
				return 'TK_NUMBER'
			elseif string.find(currentChar,'[_%a]') then
				-- Identifier or reserved word
				repeat
					currentChar = self:SaveAndNext(lexState)
				until currentChar == "EOZ" or not string.find(currentChar,'[_%w]')
				local tokenState = lexState.buff
				local reserved = self.Enums[tokenState]
				if reserved then
					return reserved
				end -- Reserved word?
				token.seminfo = tokenState
				return 'TK_NAME'
			else
				self:NextCharacter(lexState)
				return currentChar -- single-char tokens (+ - / ...)
			end
		end --if currentChar
	end --while
end

return luaX

-- OG notes to be deleted

--[[--------------------------------------------------------------------

  Analyze.lua
  Lua lexical analyzer in Lua
  This file is part of Yueliang.

  Copyright (c) 2005-2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Notes:
-- * intended to 'imitate' Analyze.c code; performance is not a concern
-- * tokens are strings; code structure largely retained
-- * deleted stuff (compared to Analyze.c) are noted, comments retained
-- * nextc() returns the currently read character to simplify coding
--   here; next() in Analyze.c does not return anything
-- * compatibility code is marked with "--#" comments
--
-- Added:
-- * luaX:chunkid (function luaO_chunkid from lobject.c)
-- * luaX:StringToNumber (function luaO_StringToNumber from lobject.c)
-- * luaX.LUA_QS used in luaX:CodeFailure (from luaconf.h)
-- * luaX.LUA_COMPAT_LSTR in luaX:ReadLong (from luaconf.h)
-- * luaX.MAX_INT used in luaX:InclineNumber (from llimits.h)
--
-- To use the lexer:
-- (1) luaX:init() to initialize the lexer
-- (2) luaX:SetInput() to set the input stream to lex
-- (3) call luaX:RetrieveNextToken() or luaX:luaX:FillLABuffer() to get tokens,
--     until "TK_EOS": luaX:RetrieveNextToken()
-- * since EOZ is returned as a string, be careful when regexp testing
--
-- Not implemented:
-- * luaX_newstring: not required by this Lua implementation
-- * buffer MAX_SIZET size limit (from llimits.h) test not implemented
--   in the interest of performance
-- * locale-aware number handling is largely redundant as Lua's
--   tonumber() function is already capable of this
--
-- Changed in 5.1.x:
-- * TK_NAME token order moved down
-- * string representation for TK_NAME, TK_NUMBER, TK_STRING changed
-- * token struct renamed to lower case (LS -> ls)
-- * LexState struct: removed nestlevel, added decpoint
-- * error message functions have been greatly simplified
-- * token2string renamed to luaX_tokens, exposed in Analyze.h
-- * lexer now handles all kinds of newlines, including CRLF
-- * shbang first line handling removed from luaX:SetInput;
--   it is now done in lauxlib.c (luaL_loadfile)
-- * next(ls) macro renamed to nextc(ls) due to new luaX_next function
-- * EXTRABUFF and MAXNOCHECK removed due to lexer changes
-- * checkbuffer(ls, len) macro deleted
-- * luaX:ReadNumeral now has 3 support functions: luaX:ConvertDecimal,
--   luaX:ReplaceCharacter and (luaO_StringToNumber from lobject.c) luaX:StringToNumber
-- * luaX:ReadNumeral is now more promiscuous in slurping characters;
--   hexadecimal numbers was added, locale-aware decimal points too
-- * luaX:SkipSeparator is new; used by luaX:ReadLong
-- * luaX:ReadLong handles new-style long blocks, with some
--   optional compatibility code
-- * luaX:Analyze: parts changed to support new-style long blocks
-- * luaX:Analyze: readname functionality has been folded in
-- * luaX:Analyze: removed test for control characters
--
--------------------------------------------------------------------]]
