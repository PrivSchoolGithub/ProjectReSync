--/General Notes
--//C Code
-- + Some unused C code that wasn't converted has been kept as comments

--/Requires Component Modules
local luaY = {}
local luaX = require(script.Parent:WaitForChild('LexicalAnalyzer'))
local luaK = require(script.Parent:WaitForChild('CodeGenerator'))(luaY)
local luaP = require(script.Parent:WaitForChild('MachineOpcodes'))

--/Constants
------------
--//Constants used by Parser
-- + Picks up duplicate values from the Lexer if required
-- + I mostly left this as is because I didn't understand most of it
-- + The majority of these come straight from the C libraries of Lua's core
--	 programming.

luaY.LUA_QS = luaX.LUA_QS or "'%s'"  -- (from luaconf.h)

luaY.SHRT_MAX = 32767 -- (supposedly from <limits.h>, but I couldn't find
-- anything in there :/)
luaY.LUAI_MAXVARS = 200  -- (from luaconf.h)
luaY.LUAI_MAXUPVALUES = 60  -- (from luaconf.h)
luaY.MAX_INT = luaX.MAX_INT or 2147483645  -- (from llimits.h)
-- * INT_MAX-2 for 32-bit systems
luaY.LUAI_MAXCCALLS = 200  -- (from luaconf.h)

luaY.VARARG_HASARG = 1  -- (from lobject.h)
-- NOTE: HASARG_MASK is value-specific
luaY.HASARG_MASK = 2 -- This was added for a bitop in Parameters()
luaY.VARARG_ISVARARG = 2
-- NOTE: there is some value-specific code that involves VARARG_NEEDSARG
luaY.VARARG_NEEDSARG = 4

luaY.LUA_MULTRET = -1  -- (from lua.h)

--/Miscellaneous
-- @ Functions that didn't really fit anywhere else
-----------------
--//QuoteElement
-- + Describes how error messages quote program elements
-- + Can be changed for a different appearance.
-- * From luaconf.h
function luaY:QuoteElement(programElement)
  return "'"..programElement.."'"
end

--//GrowVector
-- + This is a stripped-down luaM_growvector (from lmem.h) which is a macro based
--   on luaM_growaux (in lmem.c); all the following does is reproduce the size
--   limit checking logic of the original function so that error behavior is
--   identical; all arguments preserved for convenience, even those which are
--   unused.
-- + Set the t field to nil, since this originally does a sizeof(t)
-- + Renamed t to someUnusedCThing, will likely destroy it in the future
-- + size (originally a pointer) is never updated, their final values are set by
--   luaY:CloseFunction(), so overall things should still work.
-- * Contains elements from lmem.h & lmem.c
function luaY:GrowVector(luaState,value,numberOfElements,size,someUnusedCThing,limit,errorMessage)
	if numberOfElements >= limit then
		error(errorMessage) -- Was luaG_runerror
	end
end

--//NewFunctionProto
-- + Initializes a new function prototype structure (from lfunc.c)
-- + Removed ls parameter since it wasn't used in the construct
-- * Used only in OpenFunction()
function luaY:NewFunctionProto()
  -- luaC_link(L, obj2gco(f), LUA_TPROTO); /* GC */
	return { -- Proto
		k = {},
		sizek = 0,
		p = {},
		sizep = 0,
		code = {},
		sizecode = 0,
		sizelineinfo = 0,
		sizeupvalues = 0,
		nups = 0,
		upvalues = {},
		numparams = 0,
		is_vararg = 0,
		maxstacksize = 0,
		lineinfo = {},
		sizelocalvars = 0,
		locvars = {},
		lineDefined = 0,
		lastlinedefined = 0,
		source = nil,
	}
end

--//IntegerToFPB
-- + Converts an integer to a "floating point byte," represented as (eeeeexxx),
--   where the real value is (1xxx) * 2^(eeeee - 1) if eeeee != 0 and (xxx)
--   otherwise.
-- ^ The above statement is from the original structure. I don't know what it
--   means or what an fpb is used for, but I assume it's necessary for the program
--   to run.
function luaY:IntegerToFPB(x)
	-- NOTE: x starts as an integer and turns into an fpb, which is why I named
	-- it as x, it's just a generic number
	local exponent = 0
	while x >= 16 do
		x = math.floor((x + 1)/2)
		exponent = exponent + 1
	end
	if x < 8 then
		return x
	else
		return ((exponent + 1) * 8) + (x - 8)
	end
end

--/Parser Functions
-------------------
--//CheckMultipleReturnValues
-- + True of the kind of expression produces multiple return values
-- + I believe that this basically checks if an item has multiple return
--   values or not, so I've renamed "k" to "value" 
function luaY:CheckMultipleReturnValues(value)
	return value == 'VCALL' or value == 'VVARARG'
end

--//GetLocalVariable
-- + Convenience function to access active local iteration, returns entry
function luaY:GetLocalVariable(functionState,iteration)
	return functionState.f.locvars[functionState.actvar[iteration]]
end

--//PErr_Limit
-- + Prepares error message for display for limits exceeded
-- * Used only in CheckLimit()
function luaY:PErr_Limit(functionState,limit,issue)
	local message = (functionState.f.linedefined == 0) and string.format('main function has more than %d %s',limit,issue) or string.format('function at line %d has more than %d %s',functionState.f.linedefined,limit,issue)
	luaX:CodeFailure(functionState.ls,message,0)
end

--//CheckLimit
-- + Check a limit
-- + String problem provided as an error message
function luaY:CheckLimit(functionState,value,limit,problem)
	if value > limit then
		self:PErr_Limit(functionState,limit,problem)
	end
end

--//???
-- + Prototypes for recursive non-terminal functions
-- | Prototypes deleted; not required in Lua

--//AnchorToken
-- + Reanchor if last token is has a constant string, see CloseFunction()
-- ^ No, I do not know what that meant. It was in the og documentation.
-- * Used only in CloseFunction()
function luaY:AnchorToken(luaState)
	if luaState.t.token == 'TK_NAME' or luaState.t.token == 'TK_STRING' then
		-- Not relevent to Lua implementation of parser
		-- local ts = ls.t.seminfo
		-- luaX_newstring(ls,getstr(ts),ts->tsv.len); /* C */
	end
end

--//TErr_Token
-- + Throws a syntax error if token expected is not there
-- * Used in CheckTokenExistence(), CheckTokenMatch()
function luaY:TErr_Token(luaState,token)
	luaX:SyntaxError(luaState,string.format(self.LUA_QS..' expected',luaX:TokenToString(luaState,token)))
end

--//TestNextToken
-- + Tests for a token, returns outcome
-- + Return value changed to boolean (In C it was a 1 or 0)
function luaY:TestNextToken(luaState,token)
	if luaState.t.token == token then
		luaX:RetrieveNextToken(luaState)
		return true
	else
		return false
	end
end

--//CheckTokenExistence
-- + Check for existence of a token, throws error if not found
function luaY:CheckTokenExistence(luaState,token)
	if luaState.t.token ~= token then
		self:TErr_Token(luaState,token)
	end
end

--//SkipNextToken
-- + Verifies the existence of a token, then skips it
function luaY:SkipNextToken(luaState,token)
	self:CheckTokenExistence(luaState,token)
	luaX:RetrieveNextToken(luaState)
end

--//CheckCondition
-- + Throws error if condition is not matched
function luaY:CheckCondition(luaState,token,errorMessage)
	if not token then
		luaX:SyntaxError(luaState,errorMessage)
	end
end

--//VerifyConditions
-- + Verifies token conditions are met or else throws error
function luaY:VerifyConditions(luaState,what,who,where)
	if not self:TestNextToken(luaState,what) then
		if where == luaState.linenumber then
			self:TErr_Token(luaState,what)
		else
			luaX:SyntaxError(luaState,string.format(self.LUA_QS..' expected (to close'..self.LUA_QS..' at line %d)',luaX:TokenToString(luaState,what),luaX:TokenToString(luaState,who),where))
		end
	end
end

--//GetTokenName
-- + Expect that the token is a name; return the name
function luaY:GetTokenName(luaState)
	self:CheckTokenExistence(luaState,'TK_NAME')
	local semantics = luaState.t.seminfo
	luaX:RetrieveNextToken(luaState)
	return semantics
end

--//InitializeExpDesc
-- + Initializes an expression description data structure
-- + ExpDesc in Lua 5.1.x has a union u and another table s;
--	 this Lua implementation ignores all instances of u and s usage
-- + ----------
-- + STRUCTURE:
-- + ----------
-- + k: (enum : expkind)
-- + info,aux: (int,int)
-- + nval: (lua_Number)
-- + t: patch list of 'exit when true'
-- + f: patch list of 'exit when false'
function luaY:InitializeExpDesc(expression,expressionKind,info)
	expression.f,expression.t = luaK.NO_JUMP,luaK.NO_JUMP
	expression.k = expressionKind
	expression.info = info
end

--//CodeString
-- + Adds given string "inserting" in string pool, sets e as VK
-- + I do not know what e or VK represents, but I think VK MAY represent expkind.
function luaY:CodeString(luaState,e,inserting)
	self:InitializeExpDesc(e,'VK',luaK:stringK(luaState.fs,inserting))
end

--//CheckName
-- + Consumes a name token, adds it to string pool, sets e as VK
-- + Still don't know what e or VK are :(
function luaY:CheckName(luaState,e)
	self:CodeString(luaState,e,self:GetTokenName(luaState))
end

--//RegisterLocalVariable
-- + Creates struct entry for a local variable
-- + I believe in Lua "struct" translates to "table"
-- * Used only in NewLocalVariable()
function luaY:RegisterLocalVariable(luaState,variableName)
	local functionState = luaState.fs
	local header = functionState.f
	self:GrowVector(luaState.L,header.locvars,functionState.nlocvars,header.sizelocvars,nil,self.SHRT_MAX,'too many local variables')
	-- Loop to initialize empty header.locvar positions not required
	header.locvars[functionState.nlocvars] = {} -- LocVar
	header.locvars[functionState.nlocvars].varname = variableName
	-- luaC_objbarrier(ls.L, f, varname) /* GC */
	local numberOfLocalVariables = functionState.nlocvars
	functionState.nlocvars = functionState.nlocvars + 1
	return numberOfLocalVariables
end

--//NewLocalVariableLiteral
-- + Creates a new local variable given a name and an offset from nactvar
-- * Used in ForNumber(), ForList(), Parameters(), FunctionBody()
function luaY:NewLocalVariableLiteral(luaState,name,offset)
  self:NewLocalVariable(luaState,name,offset)
end

--//NewLocalVariable
-- + Registers a new local variable and sets it in the active variable list
function luaY:NewLocalVariable(ls, name, n)
  local fs = ls.fs
  self:CheckLimit(fs, fs.nactvar + n + 1, self.LUAI_MAXVARS, "local variables")
	fs.actvar[fs.nactvar + n] = self:RegisterLocalVariable(ls, name)
end

--//AdjustLocalVariables
-- + Adds numberOfVariables number of the new local variables
-- + Also sets debug information
function luaY:AdjustLocalVariables(luaState,numberOfVariables)
	local functionState = luaState.fs
	functionState.nactvar = functionState.nactvar + numberOfVariables
	for iteration = numberOfVariables,1,-1 do
		self:GetLocalVariable(functionState,functionState.nactvar-iteration).startpc = functionState.pc
	end
end

--//RemoveLocals
-- + Removes a number of locals and sets debug information
function luaY:RemoveLocals(luaState,toLevel)
	local functionState = luaState.fs
	while functionState.nactvar > toLevel do
		functionState.nactvar = functionState.nactvar - 1
		self:GetLocalVariable(functionState,functionState.nactvar).endpc = functionState.pc
	end
end

--//IndexUpvalue
-- + Returns an existing upvalue index based on the given name, or creates a new
--	 upvalue struct entry and returns the new index
-- * Used only in ProcessValues()
function luaY:IndexUpvalue(functionState,name,value)
	local header = functionState.f
	for iteration = 0,functionState.nups - 1 do
		-- Longest line in Parser O.0
		if functionState.upvalues[iteration].k == value.k and functionState.upvalues[iteration].info == value.info then
			assert(header.upvalues[iteration] == name)
			return iteration
		end
	end
	-- New one
	self:CheckLimit(functionState,header.nups + 1,self.LUAI_MAXUPVALUES,'upvalues')
	self:GrowVector(functionState.L,header.upvalues,header.nups,header.sizeupvalues,nil,self.MAX_INT,'')
	-- Loop to initialize empty header.upvalue positions not required
	header.upvalues[header.nups] = name
	-- luaC_objbarrier(fs->L, f, name); /* GC */
	assert(value.k == 'VLOCAL' or value.k == 'VUPVAL')
	-- This is a partial copy; only k & info fields used
	functionState.upvalues[header.nups] = {
		k = value.k,
		info = value.info
	}
	local numberOfUpvalues = header.nups
	header.nups = header.nups + 1
	return numberOfUpvalues
end

--//SearchLocalVariable
-- + Searches the local variable namespace of the given function state for a
--	 match
-- * Used only in ProcessValues()
function luaY:SearchLocalVariable(functionState,number)
	for iteration = functionState.nactvar - 1,0,-1 do
		if number == self:GetLocalVariable(functionState,iteration).varname then
			return iteration
		end
	end
	return -1 -- Not found
end

--//MarkUpvalueFlags
-- + Marks upvalue flags in function states up to a given level
-- * Used only in ProcessValues()
function luaY:MarkUpvalueFlags(functionState,level)
	local blockChain = functionState.bl
	while blockChain and blockChain.nactvar > level do
		blockChain = blockChain.previous
	end
	if blockChain then
		blockChain.upval = true
	end
end

--//ProcessValues
-- + Handles locals, globals, and upvalues related to processing
-- + Search mechanism is recursive, calls itself to search parents
-- * Used only in SingleVariable()
function luaY:ProcessValues(functionState,number,variable,base)
	if functionState == nil then -- No more levels?
		self:InitializeExpDesc(variable,'VGLOBAL',luaP.InvalidRegister) -- Default is global variable
		return 'VGLOBAL'
	else
		local result = self:SearchLocalVariable(functionState,number) -- Look up at current level
		if result >= 0 then
			self:InitializeExpDesc(variable,'VLOCAL',result)
			if base == 0 then
				self:MarkUpvalueFlags(functionState,result) -- Local will be used as an upvalue
			end
			return 'VLOCAL'
		else -- Not found at current level; try upper one
			if self:ProcessValues(functionState.prev,number,variable,0) == 'VGLOBAL' then
				return 'VGLOBAL'
			end
			variable.info = self:IndexUpvalue(functionState,number,variable) -- Else was LOCAL or UPVAL
			variable.k = 'VUPVAL' -- Upvalue in this level
			return 'VUPVAL'
		end -- if result (v)
	end -- if functionState (fs)
end

--//SingleVariable
-- + Consumes a name token and creates a variable (global|local|upvalue)
-- * Used in PrefixExpression(), NameFunction()
function luaY:SingleVariable(luaState,variable)
	local variableName = self:GetTokenName(luaState)
	local functionState = luaState.fs
	if self:ProcessValues(functionState,variableName,variable,1) == 'VGLOBAL' then
		variable.info = luaK:stringK(functionState,variableName) -- info points to global name
	end
end

--//AdjustRightHandSide
-- + Adjusts RHS to match LHS in an argument
-- + Not sure if "e" represents "expression," but I renamed it anyway
-- * Used in AssignVariable(), ForList(), DeclareLocalVariable()
function luaY:AdjustAssignment(luaState,numberOfVariables,numberOfExpressions,expressionDescriptionDataStructure)
	local functionState = luaState.fs
	local extra = numberOfVariables - numberOfExpressions
	if self:CheckMultipleReturnValues(expressionDescriptionDataStructure.k) then
		extra = extra + 1 -- Includes the call itself
		if extra <= 0 then
			extra = 0
		end
		luaK:setreturns(functionState,expressionDescriptionDataStructure,extra) -- Last exp. provides the difference
		if extra > 1 then
			luaK:reserveregs(functionState,extra - 1)
		end
	else
		if expressionDescriptionDataStructure.k ~= 'VVOID' then
			luaK:exp2nextreg(functionState,expressionDescriptionDataStructure) -- Close last expression
		end
		if extra > 0 then
			local firstFreeRegister = functionState.freereg
			luaK:reserveregs(functionState,extra)
			luaK:_nil(functionState,firstFreeRegister,extra)
		end
	end
end

--//EnterLevel
-- + Tracks and limits parsing depth; asserts check at end of parsing
function luaY:EnterLevel(luaState)
	luaState.L.nCcalls = luaState.L.nCcalls + 1
	if luaState.L.nCcalls > self.LUAI_MAXCCALLS then
		luaX:lexerror(luaState,'chunk has too many syntax levels',0)
	end
end

--//LeaveLevel
-- + Tracks parsing depth; a pair with luaY:EnterLevel()
function luaY:LeaveLevel(luaState)
	luaState.L.nCcalls = luaState.L.nCcalls - 1
end

--//EnterUnit
-- + Enters a code unit and initializes elements
-- + Name changed from "enterblock"
-- + ------
-- + NODES:
-- + ------
-- + previous: chain (table: BlockCnt)
-- + breaklist: list of jumps out of this loop
-- + nactvar: # active local variables in the block is an upvalue (boolean)
-- + upval: true if some variable in the block is an upvalue (boolean)
-- + isbreakable: true if 'block' is a loop (boolean)
function luaY:EnterUnit(functionState,block,canBreak)
	block.breaklist = luaK.NO_JUMP
	block.isbreakable = canBreak
	block.nactvar = functionState.nactvar
	block.upval = false
	block.previous = functionState.bl
	functionState.bl = block
	assert(functionState.freereg == functionState.nactvar)
end

--//LeaveUnit
-- + Exits a code unit and closes any upvalues
-- + Name changed from "leaveblock"
function luaY:LeaveUnit(functionState)
	local block = functionState.bl
	functionState.bl = block.previous
	self:RemoveLocals(functionState.ls,block.nactvar)
	if block.upval then
		luaK:codeABC(functionState,'OP_CLOSE',block.nactvar,0,0)
	end
	-- A block either controls scope or breaks (never both)
	assert(not block.isbreakable or not block.upval)
	assert(block.nactvar == functionState.nactvar)
	functionState.freereg = functionState.nactvar -- Free registers
	luaK:patchtohere(functionState,block.breaklist)
end

--//PushClosure
-- + Implements the instantiation of a function prototype
-- + Appends a list of upvalues after the instantiation instruction
-- + I'm assuming "v" represents "expression" here
-- * Used only in FunctionBody()
function luaY:PushClosure(luaState,run,expression)
	local functionState = luaState.fs
	local header = functionState.f
	self:GrowVector(luaState.L,header.p,functionState.np,header.sizep,nil,luaP.Limits.Bx,'constant table overflow')
	-- Loop to initialize empty header.p positions not required
	header.p[functionState.np] = run.f
	functionState.np = functionState.np + 1
	-- luaC_objbarrier(ls->L, f, func->f); /* C */
	self:InitializeExpDesc(expression,'VRELOCABLE',luaK:codeABx(functionState,'OP_CLOSURE',0,functionState.np - 1))
	for iteration = 0,run.f.nups - 1 do
		-- I think o might be TValue but I'm not messing with CodeGen yet
		local o = (run.upvalues[iteration].k == 'VLOCAL') and 'OP_MOVE' or 'OP_GETUPVAL'
		luaK:codeABC(functionState,o,0,run.upvalues[iteration].info,0)
	end
end

--//OpenFunction
-- + The opening of a function (duh...)
-- + Major modifications have been made to the original function's structure
function luaY:OpenFunction(luaState,initialFunctionState)
	local copy = luaState.L
	local proto = self:NewFunctionProto()
	
	local mainFunctionStateStructure,zeroes = {
		f = proto,
		prev = luaState.fs, -- Linked list of function states
		ls = luaState,
		L = copy,
		lasttarget = -1,
		jpc = luaK.NO_JUMP,
		bl = nil,
		h = {}, -- Constant table; was luaH_new call
		-- Anchor table of constants and prototype (to avoid being collected)
		-- sethvalue2s(L, L->top, fs->h); incr_top(L); /* C */
		-- setptvalue2s(L, L->top, f); incr_top(L);
	},{
		'pc',
		'freereg',
		'nk',
		'np',
		'nlocvars',
		'nactvar',
	}
	
	for key,value in pairs(mainFunctionStateStructure) do
		initialFunctionState[key] = value
	end
	for iteration,zeroKey in pairs(zeroes) do
		initialFunctionState[zeroKey] = 0
	end
	
	proto.source = luaState.source
	proto.maxstacksize = 2 -- Registers 0/1 are always valid

	luaState.fs = initialFunctionState
end

--//CloseFunction
-- + The closing of a function
function luaY:CloseFunction(luaState)
	local copy = luaState.L
	local functionState = luaState.fs
	local header = functionState.f -- The prototype structure/proto table
	
	self:RemoveLocals(luaState,0)
	luaK:ret(functionState,0,0) -- Final return
	-- luaM_reallocvector deleted for f->code, f->lineinfo, f->k, f->p,
	-- f->locvars, f->upvalues; not required for Lua table arrays
	
	local finalStructure = {
		sizecode = functionState.pc,
		sizelineinfo = functionState.pc,
		sizek = functionState.nk,
		sizep = functionState.np,
		sizelocvars = functionState.nlocvars,
		sizeupvalues = header.nups,
	}
	
	for key,value in pairs(finalStructure) do
		header[key] = value
	end
	
	-- assert(luaG_checkcode(header)) -- Currently not implemented
	assert(functionState.bl == nil)
	
	luaState.fs = functionState.prev
	-- The following is not required for this implementation, but it was kept
	-- here for completeness
	-- C reference:
	-- L->top -= 2;  /* remove table and prototype from the stack */
	-- last token read was anchored in defunct function; must reanchor it
	if functionState then
		self:AnchorToken(luaState)
	end
end

--//Parse
-- + Parser initialization function
-- + Note additional sub-tables needed for LexState & FuncState
function luaY:Parse(luaState,ZIO,buffer,name)
	local lexicalState = {} -- LexState
	lexicalState.t = {}
	lexicalState.lookahead = {}
	local functionState = {} -- FuncState
	functionState.upvalues = {}
	functionState.actvar = {}
	-- The following nCcalls initialization added for convenience
	luaState.nCcalls = 0
	lexicalState.buff = buffer
	luaX:SetInput(luaState,lexicalState,ZIO,name)
	self:OpenFunction(lexicalState,functionState)
	functionState.f.is_vararg = self.VARARG_ISVARARG -- Main function. Is always
	-- vararg.
	luaX:RetrieveNextToken(lexicalState) -- Read first token
	self:Chunk(lexicalState)
	self:CheckTokenExistence(lexicalState,'TK_EOS')
	self:CloseFunction(lexicalState)
	assert(functionState.prev == nil)
	assert(functionState.f.nups == 0)
	assert(lexicalState.fs == nil)
	return functionState.f
end

--/Grammar Rules
-- @ Most of the work is done here
----------------
--//FunctionName
-- + Parses a function name suffix, for function call specifications
-- * Used in PrimaryExpression(), NameFunction()
function luaY:FunctionName(luaState,value)
	-- field -> ['.' | ':'] NAME
	local functionState = luaState.fs
	local key = {} -- expressionDescriptionDataStructure
	luaK:exp2anyreg(functionState,value)
	luaX:RetrieveNextToken(luaState) -- Skip the dot or colon
	self:CheckName(luaState,key)
	luaK:indexed(functionState,value,key)
end

--//TableIndex
-- + Parses a table indexing suffix, for constructors, expressions
-- * Used in recfield(), PrimaryExpression()
function luaY:TableIndex(luaState,variable) -- Should rename var to index??
	-- index -> '[' expr ']'
	luaX:RetrieveNextToken(luaState) -- Skip the '['
	self:Expression(luaState,variable)
	luaK:exp2val(luaState.fs,variable)
	self:SkipNextToken(luaState,']')
end

--/Rules for Constructors
-------------------------
--//TableRecordField
-- + Parses a table record (hash) field
-- * Used in Constructor()
function luaY:TableRecordField(luaState,constructControl)
	-- recfield -> (NAME | '['exp1']') = exp1
	local functionState = luaState.fs
	local freeRegister = luaState.fs.freereg
	local key,value = {},{} -- expressionDescriptionDataStructure
	if luaState.t.token == 'TK_NAME' then
		self:CheckLimit(functionState,constructControl.nh,self.MAX_INT,'items in a constructor')
		self:CheckName(luaState,key)
	else
		self:TableIndex(luaState,key)
	end
	constructControl.nh = constructControl.nh + 1
	self:SkipNextToken(luaState,'=')
	local RKKey = luaK:exp2RK(functionState,key)
	self:Expression(luaState,value)
	luaK:codeABC(functionState,'OP_SETTABLE',constructControl.t.info,RKKey,luaK:exp2RK(functionState,value))
	functionState.freereg = freeRegister -- Free registers
end

--//CloseListField
-- + Emits a set list instruction if enough elements (LFIELDS_PER_FLUSH)
-- * Used in Constructor()
function luaY:CloseListField(functionState,constructControl)
	if constructControl.v.k == 'VVOID' then
		return -- There is no list item
	end
	luaK:exp2nextreg(functionState,constructControl.v)
	constructControl.v.k = 'VVOID'
	if constructControl.tostore == luaP.LFIELDS_PER_FLUSH then
		luaK:setlist(functionState,constructControl.t.info,constructControl.na,constructControl.tostore) -- Flush
		constructControl.tostore = 0 -- No more items pending
	end
end

--//LastListField
-- + Emits a set list instruction at the end of parsing list constructor
-- * Used in Constructor()
function luaY:LastListField(functionState,constructControl)
	if constructControl.tostore == 0 then
		return
	end
	if self:CheckMultipleReturnValues(constructControl.v.k) then
		self:setmultret(functionState,constructControl.v)
		luaK:setlist(functionState,constructControl.t.info,constructControl.na,self.LUA_MULTRET)
		constructControl.na = constructControl.na - 1 -- Do not count last expression (Unknown number of elements)
	else
		if constructControl.v.k ~= 'VVOID' then
			luaK:exp2nextreg(functionState,constructControl.v)
		end
		luaK:setlist(functionState,constructControl.t.info,constructControl.na,constructControl.tostore)
	end
end

--//ListField
-- + Parses a table list (array) field
-- * Used in Constructor()
function luaY:ListField(luaState,constructControl)
	self:Expression(luaState,constructControl.v)
	self:CheckLimit(luaState.fs,constructControl.na,self.MAX_INT,'items in a constructor')
	constructControl.na = constructControl.na + 1
	constructControl.tostore = constructControl.tostore + 1
end

--//Constructor
-- + Parses a table constructor
-- + Basically, it creates a table
-- + ----------
-- + STRUCTURE:
-- + ----------
-- + v: last list item read (table: struct expdesc)
-- + t: table descriptor (table: struct expdesc)
-- + nh: total number of 'record' elements
-- + na: total number of array elements
-- + tostore: number of array elements pending to be stored
-- *Used in Arguments(), SimpleExpression()
function luaY:Constructor(luaState,t)
  	-- constructor -> '{' [ field { fieldsep field } [ fieldsep ] ] '}'
  	-- field -> recfield | listfield
	-- fieldsep -> ',' | ';'
	local functionState = luaState.fs
	local line = luaState.linenumber
	local pc = luaK:codeABC(functionState,'OP_NEWTABLE',0,0,0)
	local constructControl = {} -- ConsControl
	constructControl.v = {}
	constructControl.na,constructControl.nh,constructControl.tostore = 0,0,0
	constructControl.t = t
	self:InitializeExpDesc(t,'VRELOCABLE',pc)
	self:InitializeExpDesc(constructControl.v,'VVOID',0) -- No value (yet)
	luaK:exp2nextreg(luaState.fs,t) -- Fix it at stack top (for gc)
	self:SkipNextToken(luaState,'{')
	repeat
		assert(constructControl.v.k == 'VVOID' or constructControl.tostore > 0)
		if luaState.t.token == '}' then
			break
		end
		self:CloseListField(functionState,constructControl)
		local token = luaState.t.token

		if token == 'TK_NAME' then -- May be listfields or recfields
			luaX:FillLABuffer(luaState)
			if luaState.lookahead.token ~= '=' then -- Expression?
				self:ListField(luaState,constructControl)
			else
				self:TableRecordField(luaState,constructControl)
			end
		elseif token == '[' then -- constructor_item -> recfield
			self:TableRecordField(luaState,constructControl)
		else -- constructor_part -> listfield
			self:ListField(luaState,constructControl)
		end
	until not self:TestNextToken(luaState,',') and not self:TestNextToken(luaState,';')
	self:VerifyConditions(luaState,'}','{',line)
	self:LastListField(functionState,constructControl)
	luaP:Set_Argument_B(functionState.f.code[pc],self:IntegerToFPB(constructControl.na)) -- Set initial array size
	luaP:Set_Argument_C(functionState.f.code[pc],self:IntegerToFPB(constructControl.nh)) -- Set initial table size
end

--//Parameters
-- + Parses the arguments (parameters) of a function declaration
-- * Used in FunctionBody()
function luaY:Parameters(luaState)
	-- Parameters -> [ param { ',' param } ]
	-- Parameters -> [ param { ',' param } ]
	local functionState = luaState.fs
	local header = functionState.f
	local numberOfParameters = 0
	header.is_vararg = 0
	if luaState.t.token ~= ')' then -- Is 'Parameters' not empty?
		repeat
			local token = luaState.t.token
			if token == 'TK_NAME' then -- param -> NAME
				self:NewLocalVariable(luaState,self:GetTokenName(luaState),numberOfParameters)
				numberOfParameters = numberOfParameters + 1
			elseif token == 'TK_DOTS' then -- param -> `...'
				luaX:RetrieveNextToken(luaState)
				-- #if defined(LUA_COMPAT_VARARG)
				-- use `arg' as default name
				self:NewLocalVariableLiteral(luaState,'arg',numberOfParameters)
				numberOfParameters = numberOfParameters + 1
				header.is_vararg = self.VARARG_HASARG + self.VARARG_NEEDSARG
				-- #endif
				header.is_vararg = header.is_vararg + self.VARARG_ISVARARG
			else
				luaX:SyntaxError(luaState,'<name> or '..self:QuoteElement('...')..' expected')
			end
		until header.is_vararg ~= 0 or not self:TestNextToken(luaState,',')
	end -- if
	self:AdjustLocalVariables(luaState,numberOfParameters)
	-- NOTE: The following works only when HASARG_MASK is 2!
	header.numparams = functionState.nactvar - (header.is_vararg%self.HASARG_MASK)
	luaK:reserveregs(functionState,functionState.nactvar) -- Reserve register for parameters
end

--//FunctionBody
-- + Parses function declaration body
-- * Used in SimpleExpression(), LocalFunction(), funcstat()
function luaY:FunctionBody(luaState,expressionDescriptionDataStructure,needSelf,line)
	-- body ->  '(' Parameters ')' chunk END
	local newFunctionState = {} -- FuncState
	newFunctionState.upvalues = {}
	newFunctionState.actvar = {}
	self:OpenFunction(luaState,newFunctionState)
	newFunctionState.f.lineDefined = line
	self:SkipNextToken(luaState,'(')
	if needSelf then
		self:NewLocalVariableLiteral(luaState,'self',0)
		self:AdjustLocalVariables(luaState,1)
	end
	self:Parameters(luaState)
	self:SkipNextToken(luaState,')')
	self:Chunk(luaState)
	newFunctionState.f.lastlinedefined = luaState.linenumber
	self:VerifyConditions(luaState,'TK_END','TK_FUNCTION',line)
	self:CloseFunction(luaState)
	self:PushClosure(luaState,newFunctionState,expressionDescriptionDataStructure)
end

--//CommaList
-- + Parses a list of comma-separated expressions
-- * Used in multiple locations😳
function luaY:CommaList(luaState,variable)
	-- Not COMPLETELY sure that "v" represents a variable,
	-- but I believe it does.
	-- explist1 -> expr { ',' expr }
	-- Note to Scoot: idk what to call "n" so i renamed it to "number"
	local number = 1  -- At least one expression
	self:Expression(luaState,variable)
	while self:TestNextToken(luaState,',') do
		luaK:exp2nextreg(luaState.fs,variable)
		self:Expression(luaState,variable)
		number = number + 1
	end
	return number
end

--//Arguments
-- + Parses the parameters/arguments of a function call
-- + Contrast with Parameters(), used in function declarations
-- * Used in PrimaryExpression()
function luaY:Arguments(luaState,run)
	-- Due to "function" being a keyword, I've changed it to "run"
	local functionState = luaState.fs
	local arguments = {} -- expdesc
	local numberOfParameters
	local line = luaState.linenumber
	local token = luaState.t.token
	if token == '(' then -- funcargs -> '(' [ CommaList ] ')'
		if line ~= luaState.lastline then
			luaX:SyntaxError(luaState,'ambiguous syntax (function call x new statement)')
		end
		luaX:RetrieveNextToken(luaState)
		if luaState.t.token == ')' then -- Argument list is empty?
			arguments.k = 'VVOID'
		else
			self:CommaList(luaState,arguments)
			luaK:setmultret(functionState,arguments)
		end
		self:VerifyConditions(luaState,')','(',line)
	elseif token == '{' then -- funcargs -> constructor
		self:Constructor(luaState,arguments)
	elseif token == 'TK_STRING' then -- funcargs -> STRING
		self:CodeString(luaState,arguments,luaState.t.seminfo)
		luaX:RetrieveNextToken(luaState) -- Must use 'seminfo' before 'next'
	else
		luaX:SyntaxError(luaState,'function arguments expected')
		return
	end
	assert(run.k == 'VNONRELOC')
	local base = run.info -- Base register for call
	if self:CheckMultipleReturnValues(arguments.k) then
		numberOfParameters = self.LUA_MULTRET -- Open call
	else
		if arguments.k ~= 'VVOID' then
			luaK:exp2nextreg(functionState,arguments) -- Close last argument
		end
		numberOfParameters = functionState.freereg - (base + 1)
	end
	self:InitializeExpDesc(run,'VCALL',luaK:codeABC(functionState,'OP_CALL',base,numberOfParameters + 1,2))
	luaK:fixline(functionState,line)
	functionState.freereg = base + 1 -- Call remove function, arguments, & leaves
	-- (unless changed) one result
end

--/Expression Parsing
--//PrefixExpression
-- + Parses an expression in parentheses or a single variable
-- * Used in PrimaryExpression()
function luaY:PrefixExpression(luaState,variable)
	-- Not COMPLETELY sure that "v" represents a variable,
	-- but I believe it does.
	-- prefixexp -> NAME | '(' expr ')'
	local token = luaState.t.token
	if token == '(' then
		local line = luaState.linenumber
		luaX:RetrieveNextToken(luaState)
		self:Expression(luaState,variable)
		self:VerifyConditions(luaState,')','(',line)
		luaK:dischargevars(luaState.fs,variable)
	elseif token == 'TK_NAME' then
		self:SingleVariable(luaState,variable)
	else
		luaX:SyntaxError(luaState,'unexpected symbol')
	end -- if c
	return
end

--//PrimaryExpression
-- + Parses a PrefixExpression or a function call specification
-- * Used in SimpleExpression(), AssignVariable(), FunctionCall()
function luaY:PrimaryExpression(luaState,variable)
	-- Again, not 100% sure that v is variable, but I renamed it because I
	-- think it is?
	-- primaryexp ->
	-- prefixexp { '.' NAME | '[' exp ']' | ':' NAME funcargs | funcargs }
	local functionState = luaState.fs
	self:PrefixExpression(luaState,variable)
	while true do
		local token = luaState.t.token
		if token == '.' then -- Field
			self:FunctionName(luaState,variable)
		elseif token == '[' then -- '[' exp1 ']'
			local key = {}  -- expdesc
			luaK:exp2anyreg(functionState,variable)
			self:TableIndex(luaState,key)
			luaK:indexed(functionState,variable,key)
		elseif token == ':' then -- ':' NAME Arguments
			local key = {} -- expdesc
			luaX:RetrieveNextToken(luaState)
			self:CheckName(luaState,key)
			luaK:_self(functionState,variable,key)
			self:Arguments(luaState,variable)
		elseif token == '(' or token == 'TK_STRING' or token == '{' then -- funcargs
			luaK:exp2nextreg(functionState,variable)
			self:Arguments(luaState,variable)
		else
			return
		end -- if c
	end -- while
end

--//GeneralExpression
-- + Parses general expression types; constants handled here
-- * Used in SubExpression()
function luaY:SimpleExpression(luaState,variable)
  	-- simpleexp -> NUMBER | STRING | NIL | TRUE | FALSE | ... |
	--              constructor | FUNCTION body | primaryexp
	local token = luaState.t.token
	if token == 'TK_NUMBER' then
		self:InitializeExpDesc(variable,'VKNUM',0)
		variable.nval = luaState.t.seminfo
	elseif token == 'TK_STRING' then
		self:CodeString(luaState,variable,luaState.t.seminfo)
	elseif token == 'TK_NIL' then
		self:InitializeExpDesc(variable,'VNIL',0)
	elseif token == 'TK_TRUE' then
		self:InitializeExpDesc(variable,'VTRUE',0)
	elseif token == 'TK_FALSE' then
		self:InitializeExpDesc(variable,'VFALSE',0)
	elseif token == 'TK_DOTS' then -- vararg
		local functionState = luaState.fs
		self:CheckCondition(luaState,functionState.f.is_vararg ~= 0,'cannot use '..self:QuoteElement('...')..' outside a vararg function')
		-- NOTE: The following substitutes for a bitop, but is value-specific
		local isVariadic = functionState.f.is_vararg
		if isVariadic >= self.VARARG_NEEDSARG then
			functionState.f.is_vararg = isVariadic - self.VARARG_NEEDSARG -- Don't need 'arg'
		end
		self:InitializeExpDesc(variable,'VVARARG',luaK:codeABC(functionState,'OP_VARARG',0,1,0))
	elseif token == '{' then -- Constructor
		self:Constructor(luaState,variable)
		return
	elseif token == 'TK_FUNCTION' then
		luaX:RetrieveNextToken(luaState)
		self:FunctionBody(luaState,variable,false,luaState.linenumber)
		return
	else
		self:PrimaryExpression(luaState,variable)
		return
	end -- if c
	luaX:RetrieveNextToken(luaState)
end

--//TranslateUnaryOperator
-- + Translates unary operators tokens if found, otherwise returns OPR_NOUNOPR.
-- + Used in SubExpression()
function luaY:TranslateUnaryOperator(operand)
	if operand == 'TK_NOT' then
		return 'OPR_NOT'
	elseif operand == '-' then
		return 'OPR_MINUS'
	elseif operand == '#' then
		return 'OPR_LEN'
	else
		return 'OPR_NOUNOPR'
	end
end

--//BinaryOperatorTokens
-- + List of all binop tokens
-- * Used in GetBinaryOperator
luaY.BinaryOperatorTokens = {
	['+'] = 'OPR_ADD',
	['-'] = 'OPR_SUB',
	['*'] = 'OPR_MUL',
	['/'] = 'OPR_DIV',
	['%'] = 'OPR_MOD',
	['^'] = 'OPR_POW',
	['<'] = 'OPR_LT',
	['>'] = 'OPR_GT',
	['TK_CONCAT'] = 'OPR_CONCAT',
	['TK_NE'] = 'OPR_NE',
	['TK_EQ'] = 'OPR_EQ',
	['TK_LE'] = 'OPR_LE',
	['TK_GE'] = 'OPR_GE',
	['TK_AND'] = 'OPR_AND',
	['TK_OR'] = 'OPR_OR'
}

--//GetBinaryOperator
-- + Translates binary operator tokens if found, otherwise returns OPR_NOBINOPR.
-- + Code generation uses OPR_* style tokens.
-- * Used in SubExpression()
function luaY:GetBinaryOperator(operand)
	local translatedToken = self.BinaryOperatorTokens[operand]
	if translatedToken then
		return translatedToken
	else
		return 'OPR_NOBINOPR'
	end
end

--//BinaryPriority
-- + Table consists of pairs of left/right values for binary operators
-- + Was a static const struct in C, I believe; grep for ORDER OPR
-- + No, I do not know what grep means. It was left in the og notes
-- + the following struct is replaced:
--   static const struct {
--     lu_byte left;  /* left priority for each binary operator */
--     lu_byte right; /* right priority */
--   } priority[] = {  /* ORDER OPR */
-- * Used in SubExpression()
luaY.BinaryPriority = {
	{6,6},{6,6},{7,7},{7,7},{7,7}, -- `+' `-' `/' `%'
	{10,9},{5,4}, -- Power & concat (right associative)
	{3,3},{3,3}, -- Equality #BLM xd
	{3,3},{3,3},{3,3},{3,3}, -- Order
	{2,2},{1,1}, -- Logical (and/or)
}

--//UnaryPriority
-- + Priority for unary operators
-- * Used in SubExpression()
luaY.UnaryPriority = 8

--//SubExpression
-- + Parses subexpressions.
-- + Includes handling of unary & binary operators.
-- + A subexpression is given the right-hand side priority level of the operator
--   immediately left of it, if any (limit is -1 if none), and if a binary
--   is found, limit is compared with the left hand side priority level of the
--	 binary operator in order to determine which executes first.
-- + Where 'binaryOperator' is any binary operator with a priority higher than
--   'limit
-- + For priority lookups with self.priority[], 1 = left and 2 = right
-- + Recursively called
-- + C note: subexpr -> (simpleexp | unop subexpr) { binop subexpr }
-- * Used in Expression()
function luaY:SubExpression(luaState,variable,limit)
	self:EnterLevel(luaState)
	local unaryOperator = self:TranslateUnaryOperator(luaState.t.token)
	if unaryOperator ~= 'OPR_NOUNOPR' then
		luaX:RetrieveNextToken(luaState)
		self:SubExpression(luaState,variable,self.UnaryPriority)
		luaK:prefix(luaState.fs,unaryOperator,variable)
	else
		self:SimpleExpression(luaState,variable)
	end
	-- Expand while operators have priorities higher than the limit
	local operator = self:GetBinaryOperator(luaState.t.token)
	while operator ~= 'OPR_NOBINOPR' and self.BinaryPriority[luaK.BinOpr[operator] + 1][1] > limit do
		local expressionDescriptionDataStructure = {}
		luaX:RetrieveNextToken(luaState)
		luaK:infix(luaState.fs,operator,variable)
		-- Read sub-expression with higher priority
		local nextOperator = self:SubExpression(luaState,expressionDescriptionDataStructure,self.BinaryPriority[luaK.BinOpr[operator] + 1][2])
		luaK:posfix(luaState.fs,operator,variable,expressionDescriptionDataStructure)
		operator = nextOperator
	end
	self:LeaveLevel(luaState)
	return operator -- Return first untreated operator
end

--//Expression
-- + Expression parsing starts here.
-- + Function SubExpression is entered with the left operator (which is
--   non-existent) priority of -1, which is lower than all actual operators.
-- + Expression information is returned in parameter v.
-- * Used in multiple locations >_<
function luaY:Expression(luaState,variable)
  self:SubExpression(luaState,variable,0)
end

--/Rules for Statements
--//BlockFollow
-- + Returns boolean instead of 0|1
-- * Used in ReturnStatement(), Chunk()
function luaY:BlockFollow(token)
	if token == 'TK_ELSE' or token == 'TK_ELSEIF' or token == 'TK_END' or token == 'TK_UNTIL' or token == 'TK_EOS' then
		return true
	else
		return false
	end
end

--//CodeBlockOrUnit
-- + Parses a code block or unit
-- * Used in multiple functions
function luaY:CodeBlockOrUnit(luaState)
	-- block -> chunk
	local functionState = luaState.fs
	local currentBlocks = {}
	self:EnterUnit(functionState,currentBlocks,false)
	self:Chunk(luaState)
	assert(currentBlocks.breaklist == luaK.NO_JUMP)
	self:LeaveUnit(functionState)
end

--//CheckConflict
-- + Check whether, in an assignment to a local variable, the locvar is needed in
--   a previous assignment (to a table). If so, save original local value in a
--   safe place and use this safe copy in the previous assignment.
-- * Used in AssignVariable()
function luaY:CheckConflict(luaState,leftSide,localVariable)
	local functionState = luaState.fs
	local extra = functionState.freereg -- Eventual position to save local variable
	local conflict = false
	while leftSide do
		if leftSide.v.k == 'VINDEXED' then
			if leftSide.v.info == localVariable.info then -- Conflict?
				conflict = true
				leftSide.v.info = extra -- Previous assignment will use safe copy
			end
			if leftSide.v.aux == localVariable.info then -- Conflict?
				conflict = true
				leftSide.v.info = extra -- Previous assignment will use safe copy
			end
		end
		leftSide = leftSide.prev
	end
	if conflict then
		luaK:codeABC(functionState,'OP_MOVE',functionState.freereg,localVariable.info,0) -- Make copy
		luaK:reserveregs(functionState,1)
	end
end

--//AssignVariable
-- + Parses a variable assignment sequence
-- + Recursively called
-- + Structure to chain all variables in the left-hand side of an assignment is
-- 	 described below; struct LHS_assign (renamed to assignment):
-- + ----------
-- + STRUCTURE:
-- + ----------
-- + prev: (table: struct LHS_assign)
-- + v: variable (global, local, upvalue, or indexed) (table: expdesc)
-- * Used in FunctionCall()
function luaY:AssignVariable(luaState,leftSide,newVariables)
	local expressionDescriptionDataStructure = {}
	-- Test was: VLOCAL <= lh->v.k && lh->v.k <= VINDEXED
	local condition = leftSide.v.k
	self:CheckCondition(luaState,condition == 'VLOCAL' or condition == 'VUPVAL' or condition == 'VGLOBAL' or condition == 'VINDEXED','syntax error')
	if self:TestNextToken(luaState,',') then -- Assignment _> ',' primaryExpression assignment
		local assignment = {} -- LHS_assign
		assignment.v = {}
		assignment.prev = leftSide
		self:PrimaryExpression(luaState,assignment.v)
		if assignment.v.k == 'VLOCAL' then
			self:check_conflict(luaState,leftSide,assignment.v)
		end
		self:CheckLimit(luaState.fs,newVariables,self.LUAI_MAXCCALLS - luaState.L.nCcalls,'variables in assignment')
		self:AssignVariable(luaState,assignment,newVariables + 1)
	else -- assignment -> '=' CommaList
		self:SkipNextToken(luaState,'=')
		local nexps = self:CommaList(luaState,expressionDescriptionDataStructure)
		if nexps ~= newVariables then
			self:AdjustAssignment(luaState,newVariables,nexps,expressionDescriptionDataStructure)
			if nexps > newVariables then
				luaState.fs.freereg = luaState.fs.freereg - (nexps - newVariables) -- Remove extra values
			end
		else
			luaK:setoneret(luaState.fs,expressionDescriptionDataStructure) -- Close last expression
			luaK:storevar(luaState.fs,leftSide.v,expressionDescriptionDataStructure)
			return -- Avoid default
		end
	end
	self:InitializeExpDesc(expressionDescriptionDataStructure,'VNONRELOC',luaState.fs.freereg - 1) -- Default assignment
	luaK:storevar(luaState.fs,leftSide.v,expressionDescriptionDataStructure)
end

--//Condition
-- + Parses condition in a repeat statement or an if control structure
-- * Used in repearstat() and TestThenBlock()
function luaY:Condition(luaState)
	-- cond -> exp
	local expressionDescriptionDataStructure = {}
	self:Expression(luaState,expressionDescriptionDataStructure) -- Read condition
	if expressionDescriptionDataStructure.k == 'VNIL' then
		expressionDescriptionDataStructure.k = 'VFALSE' -- 'falses' are all equal here
	end
	luaK:goiftrue(luaState.fs,expressionDescriptionDataStructure)
	return expressionDescriptionDataStructure.f
end

--//BreakStatement
-- + Parses a break statement
-- * Used in statements
function luaY:BreakStatement(luaState)
	-- stat -> BREAK
	local functionState = luaState.fs
	local currentBlocks = functionState.bl
	local upvalue = false
	while currentBlocks and not currentBlocks.isbreakable do
		if currentBlocks.upval then
			upvalue = true
		end
		currentBlocks = currentBlocks.previous
	end
	if not currentBlocks then
		luaX:SyntaxError('no loop to break')
	end
	if upvalue then
		luaK:codeABC(functionState,'OP_CLOSE',currentBlocks.nactvar,0,0)
	end
	currentBlocks.breaklist = luaK:concat(functionState,currentBlocks.breaklist,luaK:jump(functionState))
end

--//WhileStatement
-- + Parses a while-do control structure, body processed by block()
-- + With dynamic array sizes, MAXEXPWHILE + EXTRAEXP limits imposed by the
--	 function's implementation can be removed
-- * Used in statements
function luaY:WhileStatement(luaState,line)
	-- whilestat -> WHILE cond DO block END
	local functionState = luaState.fs
	local blockCount = {}
	luaX:RetrieveNextToken(luaState) -- Skip WHILE
	local whileInit = luaK:getlabel(functionState)
	local conditionExit = self:Condition(luaState)
	self:EnterUnit(functionState,blockCount,true)
	self:SkipNextToken(luaState,'TK_DO')
	self:CodeBlockOrUnit(luaState)
	luaK:patchlist(functionState,luaK:jump(functionState),whileInit)
	self:VerifyConditions(luaState,'TK_END','TK_WHILE',line)
	self:LeaveUnit(functionState)
	luaK:patchtohere(functionState,conditionExit) -- False conditions finish the look
end

--//RepeatStatement
-- + Parses a repeat-until control structure, body parsed by Chunk()
-- * Used in statements
function luaY:RepeatStatement(luaState,line)
	-- repeatstat -> REPEAT block UNTIL cond
	local functionState = luaState.fs
	local repeatInit = luaK:getlabel(functionState)
	local loop,scope = {},{} -- BlockCount
	self:EnterUnit(functionState,loop,true) -- Loop block
	self:EnterUnit(functionState,scope,false) -- Scope block
	luaX:RetrieveNextToken(luaState) -- skip REPEAT
	self:Chunk(luaState)
	self:VerifyConditions(luaState,'TK_UNTIL','TK_REPEAT',line)
	local conditionExit = self:Condition(luaState) -- Read condition (inside scope block)
	if not scope.upval then -- No upvalues?
		self:LeaveUnit(functionState) -- Finish scope
		luaK:patchlist(luaState.fs,conditionExit,repeatInit) -- Close the loop
	else -- Complete semantics when there are values
		self:BreakStatement(luaState) -- If condition then break
		luaK:patchtohere(luaState.fs,conditionExit) -- else...
		self:LeaveUnit(functionState) -- Finish scope...
		luaK:patchlist(luaState.fs,luaK:jump(functionState),repeatInit) -- And repeat
	end
	self:LeaveUnit(functionState) -- Finalize & exit loop
end

--//SingleExpression
-- + Parses the single expressions needed in numerical for loops
-- * Used in ForNumber()
function luaY:SingleExpression(luaState)
	local expressionDescriptionDataStructure = {}
	self:Expression(luaState,expressionDescriptionDataStructure)
	local expressionKind = expressionDescriptionDataStructure.k
	luaK:exp2nextreg(luaState.fs,expressionDescriptionDataStructure)
	return expressionKind
end

--//ForBody
-- + Parses a for loop body for both versions of the for loop
-- * Used in ForNumber(),ForList()
function luaY:ForBody(luaState,base,line,numberOfVariables,isNumber)
	-- forbody -> DO block
	local blockCount = {}
	local functionState = luaState.fs
	self:AdjustLocalVariables(luaState,3) -- Control variables
	self:SkipNextToken(luaState,'TK_DO')
	local prep = isNumber and luaK:codeAsBx(functionState,'OP_FORPREP',base,luaK.NO_JUMP) or luaK:jump(functionState)
	self:EnterUnit(functionState,blockCount,false) -- Scope for declared variables
	self:AdjustLocalVariables(luaState,numberOfVariables)
	luaK:reserveregs(functionState,numberOfVariables)
	self:CodeBlockOrUnit(luaState)
	self:LeaveUnit(functionState) -- End of scope for declared variables
	luaK:patchtohere(functionState,prep)
	local endFor = isNumber and luaK:codeAsBx(functionState,'OP_FORLOOP',base,luaK.NO_JUMP) or luaK:codeABC(functionState,'OP_TFORLOOP',base,0,numberOfVariables)
	luaK:fixline(functionState,line) -- Pretend that "OP_FOR" starts the loop
	luaK:patchlist(functionState,isNumber and endFor or luaK:jump(functionState),prep+1)
end

--//ForNumber
-- + Parses a numerical for loop, calls ForBody()
-- * Used in ForStatement()
function luaY:ForNumber(luaState,variableName,line)
	-- fornum -> NAME = exp1,exp1[,exp1] forbody
	local functionState = luaState.fs
	local base = functionState.freereg
	self:NewLocalVariableLiteral(luaState,'(for index)',0)
	self:NewLocalVariableLiteral(luaState,'(for limit)',1)
	self:NewLocalVariableLiteral(luaState,'(for step)',2)
	self:NewLocalVariable(luaState,variableName,3)
	self:SkipNextToken(luaState,'=')
	self:SingleExpression(luaState) -- Initial value
	self:SkipNextToken(luaState,',')
	self:SingleExpression(luaState) -- Limit
	if self:TestNextToken(luaState,',') then
		self:SingleExpression(luaState) -- Optional step
	else -- Default step = 1
		luaK:codeABx(functionState,'OP_LOADK',functionState.freereg,luaK:numberK(functionState,1))
		luaK:reserveregs(functionState,1)
	end
	self:ForBody(luaState,base,line,1,true)
end

--//ForList
-- + Parses a generic for loop, calls ForBody()
-- * Used in ForStatement()
function luaY:ForList(luaState,indexName)
	-- forlist -> NAME {,NAME} IN CommaList forbody
	local functionState = luaState.fs
	local expressionDescriptionDataStructure = {}
	local numberOfVariables = 0
	local base = functionState.freereg
	-- Create control variables
	self:NewLocalVariableLiteral(luaState,'(for generator)',numberOfVariables)
	numberOfVariables = numberOfVariables + 1
	self:NewLocalVariableLiteral(luaState,'(for state)',numberOfVariables)
	numberOfVariables = numberOfVariables + 1
	self:NewLocalVariableLiteral(luaState,'(for control)',numberOfVariables)
	numberOfVariables = numberOfVariables + 1
	-- Create declared variables
	self:NewLocalVariable(luaState,indexName,numberOfVariables)
	numberOfVariables = numberOfVariables + 1
	while self:TestNextToken(luaState,',') do
		self:NewLocalVariable(luaState,self:GetTokenName(luaState),numberOfVariables)
		numberOfVariables = numberOfVariables + 1
	end
	self:SkipNextToken(luaState,'TK_IN')
	local line = luaState.linenumber
	self:AdjustAssignment(luaState,3,self:CommaList(luaState,expressionDescriptionDataStructure),expressionDescriptionDataStructure)
	luaK:checkstack(functionState,3) -- Extra space to call generator
	self:ForBody(luaState,base,line,numberOfVariables - 3,false)
end

--//ForStatement
-- + Initial parsing for a for loop, calls ForNumber() or ForList()
-- * Used in statements
function luaY:ForStatement(luaState,line)
	-- forstat -> FOR (fornum | forlist) END
	local functionState = luaState.fs
	local blockCount = {}
	self:EnterUnit(functionState,blockCount,true) -- Scope for loop & control variables
	luaX:RetrieveNextToken(luaState) -- Skip "for"
	local variableName = self:GetTokenName(luaState) -- First variable name
	local token = luaState.t.token
	if token == '=' then
		self:ForNumber(luaState,variableName,line)
	elseif token == ',' or token == 'TK_IN' then
		self:ForList(luaState,variableName)
	else
		luaX:SyntaxError(luaState,self:QuoteElement('=')..' or '..self:QuoteElement('in')..' expected')
	end
	self:VerifyConditions(luaState,'TK_END','TK_FOR',line)
	self:LeaveUnit(functionState) -- Loop scope ("break" jumps to this point)
end

--//TestThenBlock
-- + Parses part of an if control structure, including the condition
-- * Used in IfStatement()
function luaY:TestThenBlock(luaState)
	-- test_then_block -> [IF | ELSEIF] cond THEN block
	luaX:RetrieveNextToken(luaState) -- Skip IF or ELSEIF
	local conditionExit = self:Condition(luaState)
	self:SkipNextToken(luaState,'TK_THEN')
	self:CodeBlockOrUnit(luaState) -- "then" part
	return conditionExit
end

--//IfStatement
-- + Parses an if control structure
-- * Used in statements
function luaY:IfStatement(luaState,line)
	-- ifstat -> IF cond THEN block {ELSEIF cond THEN block} [ELSE block] END
	local functionState = luaState.fs
	local escapeList = luaK.NO_JUMP
	local blockList = self:TestThenBlock(luaState) -- IF condition THEN block
	while luaState.t.token == 'TK_ELSEIF' do
		escapeList = luaK:concat(functionState,escapeList,luaK:jump(functionState))
		luaK:patchtohere(functionState,blockList)
		blockList = self:TestThenBlock(luaState) -- ELSEIF condition THEN block
	end
	if luaState.t.token == 'TK_ELSE' then
		escapeList = luaK:concat(functionState,escapeList,luaK:jump(functionState))
		luaK:patchtohere(functionState,blockList)
		luaX:RetrieveNextToken(luaState) -- Skip ELSE (After patch, for correct line info)
		self:CodeBlockOrUnit(luaState) -- "else" part
	else
		escapeList = luaK:concat(functionState,escapeList,blockList)
	end
	luaK:patchtohere(functionState,escapeList)
	self:VerifyConditions(luaState,'TK_END','TK_IF',line)
end

--//LocalFunction
-- + Parses a local function statement
-- * Used in statements
function luaY:LocalFunction(luaState)
	local expressionDescriptionDataStructure,body = {},{}
	local functionState = luaState.fs
	self:NewLocalVariable(luaState,self:GetTokenName(luaState),0)
	self:InitializeExpDesc(expressionDescriptionDataStructure,'VLOCAL',functionState.freereg)
	luaK:reserveregs(functionState,1)
	self:AdjustLocalVariables(luaState,1)
	self:FunctionBody(luaState,body,false,luaState.linenumber)
	luaK:storevar(functionState,expressionDescriptionDataStructure,body)
	-- Debug information will only see the variable after this point!
	self:GetLocalVariable(functionState,functionState.nactvar - 1).startpc = functionState.pc
end

--//DeclareLocalVariables
-- + Parses a local variable declaration statement
-- * Used in statements
function luaY:DeclareLocalVariable(luaState)
	-- stat -> LOCAL NAME {',' NAME} ['=' CommaList]
	local numberOfVariables = 0
	local numberOfExpressions
	local expressionDescriptionDataStructure = {}
	repeat
		self:NewLocalVariable(luaState,self:GetTokenName(luaState),numberOfVariables)
		numberOfVariables = numberOfVariables + 1
	until not self:TestNextToken(luaState,',')
	if self:TestNextToken(luaState,'=') then
		numberOfExpressions = self:CommaList(luaState,expressionDescriptionDataStructure)
	else
		expressionDescriptionDataStructure.k = 'VVOID'
		numberOfExpressions = 0
	end
	self:AdjustAssignment(luaState,numberOfVariables,numberOfExpressions,expressionDescriptionDataStructure)
	self:AdjustLocalVariables(luaState,numberOfVariables)
end

--//NameFunction
-- + Parses a function name specification
-- + Custom note: This is different from FunctionName()
-- * Used in FunctionStatement()
function luaY:NameFunction(luaState,value)
  -- funcname -> NAME {field} [':' NAME]
	local needsSelf = false -- Changed from needself
	self:SingleVariable(luaState,value)
	while luaState.t.token == '.' do
		self:FunctionName(luaState,value)
	end
	if luaState.t.token == ':' then
		needsSelf = true
		self:FunctionName(luaState,value)
	end
	return needsSelf
end

--//FunctionStatement
-- + Parses a function statement
-- * Used in statements
function luaY:FunctionStatement(luaState,line)
	-- funcstat -> FUNCTION funcname body
	local value,expressionDescriptionDataStructure = {},{}
	luaX:RetrieveNextToken(luaState) -- Skip FUNCTION
	local needsSelf = self:NameFunction(luaState,value)
	self:FunctionBody(luaState,expressionDescriptionDataStructure,needsSelf,line)
	luaK:storevar(luaState.fs,value,expressionDescriptionDataStructure)
	luaK:fixline(luaState.fs,line) -- Definition "happens/occurs" in the first line
end

--//FunctionCall
-- + Parses a function call with no returns or an assignment statement
-- * Used in statements
function luaY:FunctionCall(luaState) -- Changed from "exprstat"
	-- stat -> func | assignment
	local functionState = luaState.fs
	local leftHandSideAssignmentChain = {}
	leftHandSideAssignmentChain.v = {}
	self:PrimaryExpression(luaState,leftHandSideAssignmentChain.v)
	if leftHandSideAssignmentChain.v.k == 'VCALL' then -- stat -> func
		luaP:Set_Argument_C(luaK:getcode(functionState,leftHandSideAssignmentChain.v),1) -- Call statement uses no results
	else -- stat -> assignment
		leftHandSideAssignmentChain.prev = nil
		self:AssignVariable(luaState,leftHandSideAssignmentChain,1)
	end
end

--//ReturnStatement
-- + Parses a return statement (duh)
-- * Used in statements
function luaY:ReturnStatement(luaState)
	-- stat -> RETURN explist
	local functionState = luaState.fs
	local expressionDescriptionDataStructure = {}
	local first,numberOfRegisters -- Registers with returned values
	luaX:RetrieveNextToken(luaState) -- Skip RETURN
	if self:BlockFollow(luaState.t.token) or luaState.t.token == ';' then
		first,numberOfRegisters = 0,0 -- Returns no values
	else
		numberOfRegisters = self:CommaList(luaState,expressionDescriptionDataStructure) -- Optional return values
		if self:CheckMultipleReturnValues(expressionDescriptionDataStructure.k) then
			luaK:setmultret(functionState,expressionDescriptionDataStructure)
			if expressionDescriptionDataStructure.k == 'VCALL' and numberOfRegisters == 1 then -- Tail call?
				luaP:Set_Opcode(luaK:getcode(functionState,expressionDescriptionDataStructure),'OP_TAILCALL')
				assert(luaP:Get_Argument_A(luaK:getcode(functionState,expressionDescriptionDataStructure)) == functionState.nactvar)
			end
			first = functionState.nactvar
			numberOfRegisters = self.LUA_MULTRET -- Return all values
		else
			if numberOfRegisters == 1 then -- Only one single value?
				first = luaK:exp2anyreg(functionState,expressionDescriptionDataStructure)
			else
				luaK:exp2nextreg(functionState,expressionDescriptionDataStructure) -- Values must go to the "stack"
				first = functionState.nactvar -- Return all "active" values
				assert(numberOfRegisters == functionState.freereg - first)
			end
		end -- if
	end -- if
	luaK:ret(functionState,first,numberOfRegisters)
end

--//Statement
-- + Initial parsing for statements; calls a lot of functions
-- + Returns boolean instead of 0|1
-- + I thought about reordering them, but considered the possibility that it
--   is laid out in this order for a reason, so I decided against it.
-- + C code order:
--		- stat -> ifstat
--	 	- stat -> whilestat
--		- stat -> DO block END
--		- stat -> forstat
--		- stat -> repeatstat
--		- stat -> funcstat
--		- stat -> localstat
--		- stat -> retstat
--		- stat -> breakstat
-- + c variable is token
-- All statements have been tested and run successfully with no errors :D
-- * Used in Chunk()
function luaY:Statement(luaState)
	local line = luaState.linenumber -- May be needed for error messages
	local token = luaState.t.token
	if token == 'TK_IF' then
		self:IfStatement(luaState,line)
		return false
	elseif token == 'TK_WHILE' then
		self:WhileStatement(luaState,line)
		return false
	elseif token == 'TK_DO' then
		luaX:RetrieveNextToken(luaState) -- Skip DO
		self:CodeBlockOrUnit(luaState)
		self:VerifyConditions(luaState,'TK_END','TK_DO',line)
		return false
	elseif token == 'TK_FOR' then
		self:ForStatement(luaState,line)
		return false
	elseif token == 'TK_REPEAT' then
		self:RepeatStatement(luaState,line)
		return false
	elseif token == 'TK_FUNCTION' then
		self:FunctionStatement(luaState,line)
		return false
	elseif token == 'TK_LOCAL' then
		luaX:RetrieveNextToken(luaState) -- Skip LOCAL
		if self:TestNextToken(luaState,'TK_FUNCTION') then -- Local function?
			self:LocalFunction(luaState)
		else
			self:DeclareLocalVariable(luaState)
		end
		return false
	elseif token == 'TK_RETURN' then
		self:ReturnStatement(luaState)
		return true -- Must be last statement
	elseif token == 'TK_BREAK' then
		luaX:RetrieveNextToken(luaState) -- Skip BREAK
		self:BreakStatement(luaState)
		return true -- Must be last statement
	else
		self:FunctionCall(luaState)
		return false -- To avoid warnings
	end -- if c
end

--//Chunk
-- + Parses a chunk, which consists of a bunch of statements
-- + Editor's Note: Largely untested
-- * Used in Parse(), FunctionBody(), block(), and RepeatStatement()
function luaY:Chunk(luaState)
	-- chunk -> { stat [';'] }
	local isLast = false
	self:EnterLevel(luaState)
	while not isLast and not self:BlockFollow(luaState.t.token) do
		isLast = self:Statement(luaState)
		self:TestNextToken(luaState,';')
		assert(luaState.fs.f.maxstacksize >= luaState.fs.freereg and luaState.fs.freereg >= luaState.fs.nactvar)
		luaState.fs.freereg = luaState.fs.nactvar -- Free registers
	end
	self:LeaveLevel(luaState)
end

--/Return
return luaY

--/Notes by the original author that will be murdered soon


--[[--------------------------------------------------------------------
-- Expression descriptor
-- * expkind changed to string constants; luaY:AssignVariable was the only
--   function to use a relational operator with this enumeration
-- VVOID       -- no value
-- VNIL        -- no value
-- VTRUE       -- no value
-- VFALSE      -- no value
-- VK          -- info = index of constant in 'k'
-- VKNUM       -- nval = numerical value
-- VLOCAL      -- info = local register
-- VUPVAL,     -- info = index of upvalue in 'upvalues'
-- VGLOBAL     -- info = index of table; aux = index of global name in 'k'
-- VINDEXED    -- info = table register; aux = index register (or 'k')
-- VJMP        -- info = instruction pc
-- VRELOCABLE  -- info = instruction pc
-- VNONRELOC   -- info = result register
-- VCALL       -- info = instruction pc
-- VVARARG     -- info = instruction pc
} ----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- struct upvaldesc:
--   k  -- (lu_byte)
--   info -- (lu_byte)
----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- state needed to generate code for a given function
-- struct FuncState:
--   f  -- current function header (table: Proto)
--   h  -- table to find (and reuse) elements in 'k' (table: Table)
--   prev  -- enclosing function (table: FuncState)
--   ls  -- lexical state (table: LexState)
--   L  -- copy of the Lua state (table: lua_State)
--   bl  -- chain of current blocks (table: BlockCnt)
--   pc  -- next position to code (equivalent to 'ncode')
--   lasttarget   -- 'pc' of last 'jump target'
--   jpc  -- list of pending jumps to 'pc'
--   freereg  -- first free register
--   nk  -- number of elements in 'k'
--   np  -- number of elements in 'p'
--   nlocvars  -- number of elements in 'locvars'
--   nactvar  -- number of active local variables
--   upvalues[LUAI_MAXUPVALUES]  -- upvalues (table: upvaldesc)
--   actvar[LUAI_MAXVARS]  -- declared-variable stack
----------------------------------------------------------------------]]
