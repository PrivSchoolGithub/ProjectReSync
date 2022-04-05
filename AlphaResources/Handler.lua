-- Prototype Build

local function run(main,test,...)
  print(main..test)
end

local parameters = {'Text','Text'}

local splitString = {'TestA','TestB'}

for iteration,split in next,splitString do
  -- control here
end

if #splitString == 1 then
    run(splitString[1])
else
    run(splitString[1],splitString[2])
end
