local stack = {};

--Create a new stack
function stack:new()
	local o = {};
	setmetatable(o, self);
	self.__index = self;
	return o;
end

--Push item onto the stack
function stack:push(item)
	self[#self + 1] = item;
end

--Remove and return the value at the top of the stack
function stack:pop()
	local val = self[#self];
	self[#self] = nil;
	return val;
end

--Return the value at the top of the stack, without removing it
function stack:peek()
	return self[#self];
end

return stack;