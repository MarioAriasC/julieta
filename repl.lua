PROMPT = ">>"
require("lexer")
require("parser")
require("eval")

local function main()
    local env = Environment {}
    while true do
        print(PROMPT)
        local input = io.read()
        local lexer = Lexer { input = input }
        local parser = Parser { lexer = lexer }
        local program = parser:parseProgram()
        if #parser:getErrors() > 0 then
            print("Whoops! we ran into some monkey business here")
            print("parser errors:")
            ForEach(parser:getErrors(), function(error)
                print(string.format("\t%s", error))
            end)
        end
        local evaluated = Eval(program, env)
        if evaluated ~= nil then
            print(tostring(evaluated))
        end
    end
end

main()