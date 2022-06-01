require("eval")
require("lexer")
require("parser")

local function measure(body)
    local startTime = os.time()
    local result = body()
    local endTime = os.time()
    local diff = os.difftime(endTime, startTime)
    print(string.format("%s, duration=%s", result, diff))
end

local function fastInput(size)
    return string.format(
            [[let fibonacci = fn(x) {
        if (x < 2) {
            return x;
        } else {
            fibonacci(x - 1) + fibonacci(x - 2);
        }
    };
    fibonacci(%s);]], size
    )
end

local function parse(input)
    local lexer = Lexer { input = input }
    local parser = Parser { lexer = lexer }
    return parser:parseProgram()
end

measure(function()
    return Eval(parse(fastInput(35)), Environment {})
end)