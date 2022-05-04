local luaP = {}

--/General Notes
--//About "i"
-- + "i" will always represent "instruction"
-- + I'm just too lazy to write it out and don't want to have another script
--   looking like the Parser's expressionDescriptionDataStructure.

--//Lua VM Opcodes
-- + Lua Virtual Machine opcodes (enum OpCode) below
--[[
Name			Arguments	Description
------------------------------------------------------------------------
OP_MOVE       A B     		R(A) := R(B)
OP_LOADK      A Bx    		R(A) := Kst(Bx)
OP_LOADBOOL   A B C   		R(A) := (Bool)B; if (C) pc++
OP_LOADNIL    A B     		R(A) := ... := R(B) := nil
OP_GETUPVAL   A B     		R(A) := UpValue[B]
OP_GETGLOBAL  A Bx    		R(A) := Gbl[Kst(Bx)]
OP_GETTABLE   A B C   		R(A) := R(B)[RK(C)]
OP_SETGLOBAL  A Bx    		Gbl[Kst(Bx)] := R(A)
OP_SETUPVAL   A B     		UpValue[B] := R(A)
OP_SETTABLE   A B C   		R(A)[RK(B)] := RK(C)
OP_NEWTABLE   A B C   		R(A) := {} (size = B,C)
OP_SELF       A B C   		R(A+1) := R(B); R(A) := R(B)[RK(C)]
OP_ADD        A B C   		R(A) := RK(B) + RK(C)
OP_SUB        A B C   		R(A) := RK(B) - RK(C)
OP_MUL        A B C   		R(A) := RK(B) * RK(C)
OP_DIV        A B C   		R(A) := RK(B) / RK(C)
OP_MOD        A B C   		R(A) := RK(B) % RK(C)
OP_POW        A B C   		R(A) := RK(B) ^ RK(C)
OP_UNM        A B     		R(A) := -R(B)
OP_NOT        A B     		R(A) := not R(B)
OP_LEN        A B     		R(A) := length of R(B)
OP_CONCAT     A B C   		R(A) := R(B).. ... ..R(C)
OP_JMP        sBx     		pc+=sBx
OP_EQ         A B C   		if ((RK(B) == RK(C)) ~= A) then pc++
OP_LT         A B C   		if ((RK(B) <  RK(C)) ~= A) then pc++
OP_LE         A B C   		if ((RK(B) <= RK(C)) ~= A) then pc++
OP_TEST       A C     		if not (R(A) <=> C) then pc++
OP_TESTSET    A B C   		if (R(B) <=> C) then R(A) := R(B) else pc++
OP_CALL       A B C   		R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
OP_TAILCALL   A B C  		 return R(A)(R(A+1), ... ,R(A+B-1))
OP_RETURN     A B     		return R(A), ... ,R(A+B-2)  (see note)
OP_FORLOOP    A sBx   		R(A)+=R(A+2);
                      		if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
OP_FORPREP    A sBx  		 R(A)-=R(A+2); pc+=sBx
OP_TFORLOOP   A C     		R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
                      		if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++
OP_SETLIST    A B C   		R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
OP_CLOSE      A       		close all variables in the stack up to (>=) R(A)
OP_CLOSURE    A Bx    		R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
OP_VARARG     A B     		R(A), R(A+1), ..., R(A+B-1) = vararg
]]

--//About Opcodes
-- + In OP_CALL, if (B == 0) then B = top. C is the number of returns - 1, and
--   can be 0: OP_CALL then sets "top" to last_result+1, so next open instruction
--	 (OP_CALL, OP_RETURN, OP_SETLIST) may use "top"
-- + In OP_VARARG, if (B == 0) then use actual number of varargs and set top
--   (like in OP_CALL with C == 0)
-- + In OP_RETURN, if (B == 0) then return up to "top"
-- + In OP_SETLIST, if (B == 0) then B = "top"; if (C == 0) then next
--	 "instruction" is real C
-- + For comparisons, A specifies what condition the test should accept (true or
--	 false)
-- + All "skips" (pc++) assume that next instruction is a jump

--/Code
--//Format
-- + Basic instruction format
-- + We assume that instructions are unsigned numbers.
-- + All instructions have an opcode in the first 6 bits.
-- + Instructions can have the following fields:
--		'A' 	: 	8 bits
--		'B' 	: 	9 bits
--		'C'		:	9 bits
--		'Bx'	:	18 bits ('B' and 'C' together)
--		'sBx'	:	signed Bx
-- + A signed argument is represented in excess K; that is, the number value is
--   the unsigned value minus K. K is exactly the maximum value for that
--   argument (so that -max is represented by 0, and +max is represented by
--	 2*max), which is hald the maximum for the corresponding unsigned argument.
luaP.Format = {
	iABC = 0,
	iABx = 1,
	iAsBx = 2,
}

--//Size/Position
-- + Size & position of opcode arguments
-- * WARNING: Size and position is hard coded elsewhere in this script
luaP.Size,luaP.Position = {},{}

luaP.Size.C = 9
luaP.Size.B = 9
luaP.Size.Bx = luaP.Size.C + luaP.Size.B
luaP.Size.A = 8
luaP.Size.OP = 6

luaP.Position.OP = 0
luaP.Position.A = luaP.Position.OP + luaP.Size.OP
luaP.Position.C = luaP.Position.A + luaP.Size.A
luaP.Position.B = luaP.Position.C + luaP.Size.C
luaP.Position.Bx = luaP.Position.C

--//Limits
-- + Limits for opcode arguments
-- + We use (signed) int to manipulate most arguments, so they must fit in
--	 LUAI_BITSINT-1 bit (-1 for sign)
-- + Removed "#if SIZE_Bx < BITS_INT-1" test, assume this script is running on
-- + a Lua VM with double or int as LUA_NUMBER
luaP.Limits = {}

luaP.Limits.Bx = math.ldexp(1,luaP.Size.Bx) - 1
luaP.Limits.sBx = math.floor(luaP.Limits.Bx/2) -- 'sBx' is signed

luaP.Limits.A = math.ldexp(1,luaP.Size.A) - 1
luaP.Limits.B = math.ldexp(1,luaP.Size.B) - 1
luaP.Limits.C = math.ldexp(1,luaP.Size.C) - 1

--//MASK1
-- + Creates a mask with 'n' 1 bits at position 'p'
-- | MASK1(n,p) deleted, not required

--//MASK0
-- + Creates a mask with 'n' 0 bits at position 'p'
-- | MASK0(n,p) deleted, not required

--//Visual
-- + The following is a note that deals with the above and serves no
--   fuctionality for the system
-- + Visual representation for reference:
--[[
     31    |    |     |            0      bit position
      +-----+-----+-----+----------+
      |  B  |  C  |  A  |  Opcode  |      iABC format
      +-----+-----+-----+----------+
      -  9  -  9  -  8  -    6     -      field sizes
      +-----+-----+-----+----------+
      |   [s]Bx   |  A  |  Opcode  |      iABx | iAsBx format
      +-----+-----+-----+----------+
]]

--//Get/Set/Create
-- + The following macros help to manipulate instructions
-- * Changed to a table object representation, very clean compared to the
--   [nightmare] alternatives of using a number or a string
-- * Bx is a separate element from B and C, since there is never a need to split
--   Bx in the Parser or Code Generator
-- + Using underscores in the place of . since tables didn't work for self

-- These accept or return opcodes in the form of string names
function luaP:Get_Opcode(i)
	return self.ROpcode[i.OP]
end
function luaP:Set_Opcode(i,opcode)
	i.OP = self.Opcode[opcode]
end

function luaP:Get_Argument_A(i)
	return i.A
end
function luaP:Set_Argument_A(i,u)
	i.A = u
end

function luaP:Get_Argument_B(i)
	return i.B
end
function luaP:Set_Argument_B(i,b)
	i.B = b
end

function luaP:Get_Argument_C(i)
	return i.C
end
function luaP:Set_Argument_C(i,b)
	i.C = b
end

function luaP:Get_Argument_Bx(i)
	return i.Bx
end
function luaP:Set_Argument_Bx(i,b)
	i.Bx = b
end

function luaP:Get_Argument_sBx(i)
	return i.Bx - self.Limits.sBx
end
function luaP:Set_Argument_sBx(i,b)
	i.Bx = b + self.Limits.sBx
end

function luaP:Create_ABC(opcode,a,b,c)
	return {
		OP = self.Opcode[opcode],
		A = a,
		B = b,
		C = c,
	}
end

function luaP:Create_ABx(opcode,a,bc)
	return {
		OP = self.Opcode[opcode],
		A = a,
		Bx = bc,
	}
end

--//Create_Instruction
-- + Creates an instruction from a number
-- * For OP_SETLIST
-- + Kept separate from the above functions
function luaP:Create_Instruction(c)
	local opcode = c%64
	c = (c-0)/64
	local a = c%256
	c = (c-a)/265
	return self:Create_ABx(opcode,a,c)
end

--//FieldToChar
-- + Returns a 4-char string little-endian encoded form of an instruction
-- + Converts field elements to a 4-char string
function luaP:FieldToChar(i)
	if i.Bx then
		-- Change to OP/A/B/C format
		i.C = i.Bx%512
		i.B = (i.Bx-i.C)/512
	end
	local newInstruction = i.A*64+i.OP
	local c0 = newInstruction%256
	newInstruction = i.C*64+(newInstruction-c0)/256 -- 6 bits of A left
	local c1 = newInstruction%256
	newInstruction = i.B*128+(newInstruction-c1)/256 -- 7 bits of C left
	local c2 = newInstruction%256
	local c3 = (newInstruction-c2)/256
	return string.char(c0,c1,c2,c3)
end

--//CharToField
-- + Decodes a 4-char little-endian string into an instruction table
-- + Converts a 4-char string into field elements
-- + Technically not necessary but I'm keeping it anyway
function luaP:CharToField(x)
	local byte = string.byte
	local i = {}
	local newInstruction = byte(x,1)
	local opcode = newInstruction%64
	i.OP = opcode
	newInstruction = byte(x,2)*4+(newInstruction-opcode)/64 -- 2 bits of c0 left
	local a = newInstruction%256
	i.A = a
	newInstruction = byte(x,3)*4+(newInstruction-a)/256 -- 2 bits of c1 left
	local c = newInstruction%512
	i.C = c
	i.B = byte(x,4)*2+(newInstruction-c)/512 -- 1 bit of c2 left
	local opMode = self.Format[tonumber(string.sub(self.opmodes[opcode+1],7,7))]
	if opMode ~= 'iABC' then
		i.Bx = i.B*512+i.C
	end
	return i
end

--//BitRK/TestConstant/GetConstantIndex/CodeConstantIndexAsRK
-- + Macros to operate RK indices
-- * These use arithmetic instead of bit ops

-- This bit 1 means constant (0 means register)
luaP.BitRK = math.ldexp(1,luaP.Size.B-1)

-- This tests whether the value is a constant or not
-- Could also use "CheckConstant" as name
function luaP:TestConstant(x)
	return x >= self.BitRK
end

-- This gets the index of the constant
function luaP:GetConstantIndex(x)
	return x - self.BitRK
end

luaP.MaxIndexRK = luaP.BitRK-1

-- This codes a constant index as an RK value
-- (A RK value?) Real K maybe? idk
function luaP:CodeConstantIndexAsRK(x)
	return x + self.BitRK
end

--//InvalidRegister
-- + Invalid register that fits 8 bits
luaP.InvalidRegister = luaP.Limits.A

luaP.OpNames = {}  -- opcode names
luaP.Opcode = {}   -- lookup name -> number
luaP.ROpcode = {}  -- lookup number -> name

--//Order OP
-- + Properly orders the opcodes
local iteration = 0
for value in string.gmatch([[
MOVE LOADK LOADBOOL LOADNIL GETUPVAL
GETGLOBAL GETTABLE SETGLOBAL SETUPVAL SETTABLE
NEWTABLE SELF ADD SUB MUL
DIV MOD POW UNM NOT
LEN CONCAT JMP EQ LT
LE TEST TESTSET CALL TAILCALL
RETURN FORLOOP FORPREP TFORLOOP SETLIST
CLOSE CLOSURE VARARG
]],'%S+') do
	local number = 'OP_'..value
	luaP.OpNames[iteration] = value
	luaP.Opcode[number] = iteration
	luaP.ROpcode[iteration] = number
	iteration += 1
end
luaP.TotalOpcodes = iteration

--//Masks
-- + Masks for instruction properties. The format is:
--		Bits 0-1	:	Op mode
--		Bits 2-3	:	C argument mode
--		Bits 4-5	:	B argument mode
--		Bit  6		:	Instruction set register A
--		Bit 7		:	Operator is a test
-- + For OpArgumentMask:
--		OAM_N				-	Argument is not used
--		OAM_U				-	Argument is used
--		OAM_REG_JMP			-	Argument is a register or a jump offset
--		OAM_CONST_REGCONST	-	Argument is a constant or register/constant

-- Was enum OpArgMask
luaP.OpArgumentMask = {
	OAM_N = 0,
	OAM_U = 1,
	OAM_REG_JMP = 2,
	OAM_CONST_REGCONST = 3,
}

--//Get Modes
-- + Example: To compare with symbols, luaP:GetOpMode(...) == luaP.Opcode.iABC
-- * Accepts opcode parameter as strings; example: "OP_MOVE"
function luaP:GetOpMode(mode)
	return self.OpModes[self.Opcode[mode]]%4
end

function luaP:GetBMode(mode)
	return math.floor(self.OpModes[self.Opcode[mode]]/16)%4
end

function luaP:GetCMode(mode)
	return math.floor(self.OpModes[self.Opcode[mode]]/4)%4
end

function luaP:TestAMode(mode)
	return math.floor(self.OpModes[self.Opcode[mode]]/64)%2
end

function luaP:TestTMode(mode)
	return math.floor(self.OpModes[self.Opcode[mode]]/128)
end

-- luaP_opnames[] is set above, as the luaP.OpNames table

-- Number of list items to accumulate before a SETLIST instruction
luaP.ListItemsPerFlush = 50

--//Build Op Modes
-- + Build instruction properties array
-- * Deliberately coded to look like the C equivalent
local function opMode(t,a,b,c,mode)
	local luaP = luaP
	return t*128+a*64+luaP.OpArgumentMask[b]*16+luaP.OpArgumentMask[c]*4+luaP.Format[mode]
end

-- ORDER OP
luaP.OpModes = {
	-- T A B C mode opcode
	opMode(0,1,'OAM_CONST_REGCONST','OAM_N','iABx'), -- OP_LOADK
	opMode(0,1,'OAM_U','OAM_U','iABC'), -- OP_LOADBOOL
	opMode(0,1,'OAM_REG_JMP','OAM_N','iABC'), -- OP_LOADNIL
	opMode(0,1,'OAM_U','OAM_N','iABC'), -- OP_GETUPVAL
	opMode(0,1,'OAM_CONST_REGCONST','OAM_N','iABx'), -- OP_GETGLOBAL
	opMode(0,1,'OAM_REG_JMP','OAM_CONST_REGCONST','iABC'), -- OP_GETTABLE
	opMode(0,0,'OAM_CONST_REGCONST','OAM_N','iABx'), -- OP_SETGLOBAL
	opMode(0,0,'OAM_U','OAM_N','iABC'), -- OP_SETUPVAL
	opMode(0,0,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_SETTABLE
	opMode(0,1,'OAM_U','OAM_U','iABC'), -- OP_NEWTABLE
	opMode(0,1,'OAM_REG_JMP','OAM_CONST_REGCONST','iABC'), -- OP_SELF
	opMode(0,1,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_ADD
	opMode(0,1,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_SUB
	opMode(0,1,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_MUL
	opMode(0,1,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_DIV
	opMode(0,1,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_MOD
	opMode(0,1,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_POW
	opMode(0,1,'OAM_REG_JMP','OAM_N','iABC'), -- OP_UNM
	opMode(0,1,'OAM_REG_JMP','OAM_N','iABC'), -- OP_NOT
	opMode(0,1,'OAM_REG_JMP','OAM_N','iABC'), -- OP_LEN
	opMode(0,1,'OAM_REG_JMP','OAM_REG_JMP','iABC'), -- OP_CONCAT
	opMode(0,0,'OAM_REG_JMP','OAM_N','iAsBx'), -- OP_JMP
	opMode(1,0,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_EQ
	opMode(1,0,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_LT
	opMode(1,0,'OAM_CONST_REGCONST','OAM_CONST_REGCONST','iABC'), -- OP_LE
	opMode(1,1,'OAM_REG_JMP','OAM_U','iABC'), -- OP_TEST
	opMode(1,1,'OAM_REG_JMP','OAM_U','iABC'), -- OP_TESTSET
	opMode(0,1,'OAM_U','OAM_U','iABC'), -- OP_CALL
	opMode(0,1,'OAM_U','OAM_U','iABC'), -- OP_TAILCALL
	opMode(0,0,'OAM_U','OAM_N','iABC'), -- OP_RETURN
	opMode(0,1,'OAM_REG_JMP','OAM_N','iAsBx'), -- OP_FORLOOP
	opMode(0,1,'OAM_REG_JMP','OAM_N','iAsBx'), -- OP_FORPREP
	opMode(1,0,'OAM_N','OAM_U','iABC'), -- OP_TFORLOOP
	opMode(0,0,'OAM_U','OAM_U','iABC'), -- OP_SETLIST
	opMode(0,0,'OAM_N','OAM_N','iABC'), -- OP_CLOSE
	opMode(0,1,'OAM_U','OAM_N','iABx'), -- OP_CLOSURE
	opMode(0,1,'OAM_U','OAM_N','iABC'), -- OP_VARARG
}
-- An awkward way to set a zero-indexed table...
luaP.OpModes[0] = opMode(0,1,'OAM_REG_JMP','OAM_N','iABC') -- OP_MOVE

return luaP

--/Notes by the og author to be murdered soon

--[[--------------------------------------------------------------------

  lopcodes.lua
  Lua 5 virtual machine opcodes in Lua
  This file is part of Yueliang.

  Copyright (c) 2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Notes:
-- * an Instruction is a table with OP, A, B, C, Bx elements; this
--   makes the code easy to follow and should allow instruction handling
--   to work with doubles and ints
-- * WARNING luaP:FieldToChar outputs instructions encoded in little-
--   endian form and field size and positions are hard-coded
--
-- Not implemented:
-- *
--
-- Added:
--
-- Changed in 5.1.x:
-- * POS_OP added, instruction field positions changed
-- * some symbol names may have changed, e.g. LUAI_BITSINT
-- * new operators for RK indices: BitRK, TestConstant(x), GetConstantIndex(r), CodeConstantIndexAsRK(x)
-- * OP_MOD, OP_LEN is new
-- * OP_TEST is now OP_TESTSET, OP_TEST is new
-- * OP_FORLOOP, OP_TFORLOOP adjusted, OP_FORPREP is new
-- * OP_TFORPREP deleted
-- * OP_SETLIST and OP_SETLISTO merged and extended
-- * OP_VARARG is new
-- * many changes to implementation of OpMode data
----------------------------------------------------------------------]]
