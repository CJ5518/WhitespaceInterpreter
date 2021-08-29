--Whitespace interpreter
--Labels have not yet been tested
--[[
Program:
{
	"01201", "012010", 234, "0112"
}
The commands are encoded according to the SPACE, LF, and TAB constants, if an instruction needs a number after it, it'll be there
If an instruction uses a label, it will be there in number form, check the 'label number' for each entry in Labels
Labels:
{
	{idx of command in program, label number (identifier)}, {idx, num}
}
]]

--#region TokenDefinitions
tokenType = {
	space = 0, --0 and 1 for easy binary-nes
	tab = 1, --If these are changed, anarchy will ensue
	linefeed = 2 --This one too
}

SPACE = tokenType.space;
TAB = tokenType.tab;
LINEFEED = tokenType.linefeed;
LF = LINEFEED;

--#endregion

--#region LookupTables
--From char byte to token type
local lookupTable = {}
lookupTable[string.byte(" ")] = tokenType.space;
lookupTable[string.byte("	")] = tokenType.tab;
lookupTable[string.byte("\n")] = tokenType.linefeed;

--Turns argsToCommand(SPACE, SPACE) into "00", entirely here for convenience
function argsToCommand(...)
	local tab = {...};
	local ret = "";
	for i, v in pairs(tab) do
		ret = ret .. tostring(v);
	end
	return ret;
end

--Tables of actions
local actionsWithNumbers = {
	argsToCommand(SPACE, SPACE), argsToCommand(SPACE, TAB, SPACE), argsToCommand(SPACE, TAB, LF)
}
local actionsWithLabels = {
	argsToCommand(LF, SPACE, SPACE), argsToCommand(LF, SPACE, TAB),
	argsToCommand(LF, SPACE, LF), argsToCommand(LF, TAB, SPACE),
	argsToCommand(LF, TAB, TAB)
}
--The one command that's not a command it just defines a label and so doesn't need to be in the output as a command
local labelDefAction = argsToCommand(LF, SPACE, SPACE);
local actionsWithoutArgs = {
	argsToCommand(SPACE, LF, SPACE), argsToCommand(SPACE, LF, TAB),
	argsToCommand(SPACE, LF, LF), argsToCommand(TAB, SPACE, SPACE, SPACE),
	argsToCommand(TAB, SPACE, SPACE, TAB), argsToCommand(TAB, SPACE, SPACE, LF),
	argsToCommand(TAB, SPACE, TAB, SPACE), argsToCommand(TAB, SPACE, TAB, TAB),
	argsToCommand(TAB, TAB, SPACE), argsToCommand(TAB, TAB, TAB),
	argsToCommand(LF, TAB, LF), argsToCommand(LF, LF, LF),
	argsToCommand(TAB, LF, SPACE, SPACE), argsToCommand(TAB, LF, SPACE, TAB),
	argsToCommand(TAB, LF, TAB, SPACE), argsToCommand(TAB, LF, TAB, TAB)
}
--Returns true or false if x is in table t
local function isInTable(t, x)
	for i, v in pairs(t) do
		if v == x then return true end;
	end
	return false;
end
--#endregion

--Takes a string in the form "101001010" and returns the number in decimal
local function binaryStringToInt(str)
	local ret = 0;
	for q = 1, str:len() do
		if str:sub(q,q) == "1" then
			ret = ret + math.pow(2, str:len() - q);
		end
	end
	return ret;
end

--Gets a number from a whitespace str, assumes that index is the start of the number
--Also returns the new index in the string
local function getNumber(str, index)
	local number = "";
	local sign = "";
	--Go over the chars starting at index
	for q = index, str:len() do
		index = q;
		local token = lookupTable[str:sub(q,q):byte()];
		if token == LF then break; end
		if token and q > 1 then
			number = number .. tostring(token);
		elseif q == 1 and token == TAB then --Set the sign for the first "bit"
			sign = "-";
		end
	end
	return binaryStringToInt(sign .. number), index;
end

local module = {};

--Parse the input file (in whitespace)
function module.parse(filename)
	--Array of stuff to return
	local output = {};
	--Array of labels
	local labels = {};

	--Read the file
	local file = io.open(filename, "r");
	local text = file:read("*a");
	local currentAction = "";

	--For every char
	local q = 1;
	while true do
		if q > text:len() then break end;
		local token = lookupTable[text:sub(q,q):byte()];
		--If it's not in the lookup table, ignore it
		if token then
			currentAction = currentAction .. tostring(token);
			if currentAction:len() >= 5 then
				error("Current action is 5 or greater");
			end
			--Check if we've found an action
			if currentAction then
				if isInTable(actionsWithNumbers, currentAction) then
					output[#output+1] = currentAction;
					local num;
					num, q = getNumber(text, q + 1);
					output[#output+1] = num;
					currentAction = "";
				elseif isInTable(actionsWithLabels, currentAction) then
					local num;
					num, q = getNumber(text, q + 1);
					--If just a label definition
					if currentAction == labelDefAction then
						labels[#labels+1] = {#output + 1, num}
					else --We do something with the label
						output[#output+1] = currentAction;
						output[#output+1] = num;
					end
					currentAction = "";
				elseif isInTable(actionsWithoutArgs, currentAction) then
					output[#output+1] = currentAction;
					currentAction = "";
				end
			end
		end
		q = q + 1;
	end
	file:close();
	return output, labels;
end

return module;