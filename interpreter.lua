local parser = require("parser");

local interpreter = {};

--Creates a new interpreter
--If you pass a filename, it will initialize it
function interpreter:new(filename)
	local o = {};
	setmetatable(o, self);
	self.__index = self;

	o.stack = {};
	o.heap = {};
	o.programCounter = 1;
	o.halted = false;
	if filename then
		o:init(filename);
	end

	return o;
end

--Initialize the interpreter based on a file
function interpreter:init(filename)
	local code, labels = parser.parse(filename);
	self.code = code;
	self.labels = labels;
end

--#region Instructions
local instructions = {};

--  SPACE SPACE - Push the number onto the stack
instructions["00"] = function (self)
	self.stack[#self.stack+1] = self.code[self.programCounter];
	self.programCounter = self.programCounter + 1;
end
-- \n SPACE LF SPACE - Duplicate the top item on the stack
instructions["020"] = function (self)
	self.stack[#self.stack + 1] = self.stack[#self.stack];
end
-- 	 SPACE TAB SPACE - Copy the nth item on the stack (given by the argument) onto the top of the stack
--We assume 0 means the top, 1 means right under that, etc.
instructions["010"] = function (self)
	local item = self.stack[#self.stack - self.code[self.programCounter]];
	self.stack[#self.stack + 1] = item;
end
-- \n	SPACE LF TAB - Swap the top two items on the stack
instructions["021"] = function (self)
	local temp = self.stack[#self.stack];
	self.stack[#self.stack] = self.stack[#self.stack - 1];
	self.stack[#self.stack - 1] = temp;
end
-- \n\nSPACE LF LF - Discard the top item on the stack
instructions["022"] = function (self)
	self.stack[#self.stack] = nil;
end



--	\n  TAB LF SPACE SPACE - Output the character at the top of the stack
instructions["1200"] = function (self)
	io.write(string.char(self.stack[#self.stack]));
end


--\n\n\nLF LF LF - End the program
instructions["222"] = function (self)
	self.halted = true;
end

interpreter.instructions = instructions;
--#endregion

--Returns true if there is more code to run, false if the program has halted
function interpreter:execute()
	local instruction = self.code[self.programCounter];
	self.programCounter = self.programCounter + 1;

	if not self.instructions[instruction] then
		print("Missing instruction: ", instruction);
		self.halted = true;
	else
		self.instructions[instruction](self);
	end

	return not self.halted;
end

return interpreter;