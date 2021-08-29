local parser = require("parser");
local stack = require("stack");

local interpreter = {};

--[[
	https://github.com/vii5ard/whitespace/blob/master/ws_core.js#L381
	      var b = env.stackPop();
      var a = env.stackPop();
      env.stackPush(a-b);
      env.register.IP++;
]]

--Creates a new interpreter
--If you pass a filename, it will initialize it
function interpreter:new(filename)
	local o = {};
	setmetatable(o, self);
	self.__index = self;

	o.stack = stack:new();
	o.callStack = stack:new();
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
	self.stack:push(self.code[self.programCounter]);
	self.programCounter = self.programCounter + 1;
end
-- \n SPACE LF SPACE - Duplicate the top item on the stack
instructions["020"] = function (self)
	self.stack:push(self.stack:peek());
end
-- 	 SPACE TAB SPACE - Copy the nth item on the stack (given by the argument) onto the top of the stack
--We assume 0 means the top, 1 means right under that, etc.
instructions["010"] = function (self)
	local item = self.stack[#self.stack - self.code[self.programCounter]];
	self.stack[#self.stack + 1] = item;
	self.programCounter = self.programCounter + 1;
end
-- \n	SPACE LF TAB - Swap the top two items on the stack
instructions["021"] = function (self)
	local first = self.stack:pop();
	local second = self.stack:pop();
	self.stack:push(first);
	self.stack:push(second);
end
-- \n\nSPACE LF LF - Discard the top item on the stack
instructions["022"] = function (self)
	self.stack:pop();
end
-- 	\nSPACE TAB LF - Slide n items off the stack, keeping the top item
instructions["012"] = function (self)
	local num = self.code[self.programCounter];
	local top = self.stack:pop();
	for q = 1, num do
		self.stack:pop();
	end
	self.stack:push(top);
	self.programCounter = self.programCounter + 1;
end
--	   TAB SPACE SPACE SPACE - Addition
instructions["1000"] = function (self)
	local right = self.stack:pop();
	local left = self.stack:pop();
	self.stack:push(left + right);
end
--	  	TAB SPACE SPACE TAB - Subtraction
instructions["1001"] = function (self)
	local right = self.stack:pop();
	local left = self.stack:pop();
	self.stack:push(left - right);
end
--	  \nTAB SPACE SPACE LF - Multiplicaton
instructions["1002"] = function (self)
	local right = self.stack:pop();
	local left = self.stack:pop();
	self.stack:push(left * right);
end
--	 	 TAB SPACE TAB SPACE - Integer division
instructions["1010"] = function (self)
	local right = self.stack:pop();
	local left = self.stack:pop();
	self.stack:push(math.floor(left / right));
end
--	 		TAB SPACE TAB TAB - Modulo
instructions["1010"] = function (self)
	local right = self.stack:pop();
	local left = self.stack:pop();
	self.stack:push(left % right);
end
--		 TAB TAB SPACE - Store in heap
instructions["110"] = function (self)
	local val = self.stack:pop();
	local addr = self.stack:pop();
	self.heap[addr] = val;
end
--			TAB TAB TAB - Retrieve from heap
instructions["111"] = function (self)
	local addr = self.stack:pop();
	self.stack:push(self.heap[addr]);
end
--\n 	LF SPACE TAB - Call a subroutine
instructions["201"] = function (self)
	self.callStack:push(self.programCounter + 1);
	self.programCounter = self.labels[self.code[self.programCounter]];
end
--\n \nLF SPACE LF - Jump to a label
instructions["202"] = function (self)
	self.programCounter = self.labels[self.code[self.programCounter]];
end
--\n	 LF TAB SPACE - Jump to a label if the top of the stack is zero
instructions["210"] = function (self)
	if self.stack:pop() == 0 then
		self.programCounter = self.labels[self.code[self.programCounter]];
	else
		self.programCounter = self.programCounter + 1;
	end
end
--\n		LF TAB TAB - Jump to a label if the top of the stack is negative
instructions["211"] = function (self)
	if self.stack:pop() < 0 then
		self.programCounter = self.labels[self.code[self.programCounter]];
	else
		self.programCounter = self.programCounter + 1;
	end
end
--\n	\nLF TAB LF - End a subroutine and transfer control back to the caller
instructions["212"] = function (self)
	self.programCounter = self.callStack:pop();
end
--\n\n\nLF LF LF - End the program
instructions["222"] = function (self)
	self.halted = true;
end
--	\n  TAB LF SPACE SPACE - Output the character at the top of the stack
instructions["1200"] = function (self)
	io.write(string.char(self.stack:pop()));
end
--	\n 	TAB LF SPACE TAB - Output the number at the top of the stack
instructions["1201"] = function (self)
	io.write(tostring(self.stack:pop()));
end
--	\n	 TAB LF TAB SPACE - Read a character and place it in the location given by the top of the stack
instructions["1210"] = function (self)
	local addr = self.stack:pop();
	self.heap[addr] = io.read(1):byte();
end
--	\n		TAB LF TAB TAB - Read a number and place it in the location given by the top of the stack
instructions["1211"] = function (self)
	local addr = self.stack:pop();
	self.heap[addr] = tonumber(io.read("*n"));
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