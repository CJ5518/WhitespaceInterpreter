local interpreter = require("interpreter");

local whitespace = interpreter:new("test.ws");
--Empty loop
while whitespace:execute() do
end