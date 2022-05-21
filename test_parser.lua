require("utilstests")
require 'busted.runner'()

describe("A parser", function()
    describe("should", function()
        describe("parse", function()
            it("let statements", function()
                local tests = {
                    { "let x = 5;", "x", 5 },
                    { "let y = true;", "y", true },
                    { "let foobar = y;", "foobar", "y" },
                }
                for i = 1, #tests do
                    local input = tests[i][1]
                    local expectedIdentifier = tests[i][2]
                    local expectedValue = tests[i][3]
                    local program = CreateProgram(input)
                    CountStatement(1, program, assert)
                    local statement = program.statements[1]
                    AssertLetStatement(statement, expectedIdentifier, assert)
                    local value = statement.value
                    AssertLiteralExpression(value, expectedValue, assert)
                end
            end)
            it("return statements", function()
                local tests = {
                    { "return 5;", 5 },
                    { "return true;", true },
                    { "return foobar;", "foobar" }
                }
                for i = 1, #tests do
                    local input = tests[i][1]
                    local expectedIdentifier = tests[i][2]
                    local program = CreateProgram(input)
                    CountStatement(1, program, assert)
                    local statement = program.statements[1]
                    assert.are.same("return", statement:getTokenLiteral())
                    AssertLiteralExpression(statement.returnValue, expectedIdentifier, assert)
                end
            end)
            it("identifier expression", function()
                local input = "foobar;"
                local program = CreateProgram(input)
                CountStatement(1, program, assert)
                local statement = program.statements[1]
                local identifier = statement.expression
                assert.are.same("foobar", identifier.value)
                assert.are.same("foobar", identifier:getTokenLiteral())
            end)
            it("integer literals", function()
                local input = "5;"
                local program = CreateProgram(input)
                CountStatement(1, program, assert)
                local statement = program.statements[1]
                local expression = statement.expression
                if expression:is(IntegerLiteral) then
                    assert.are.same(5, expression.value)
                    assert.are.same("5", expression:getTokenLiteral())
                else
                    error(string.format("statement.expression not IntegerLiteral. got=%s", tostring(statement)))
                end
            end)
            it("prefix expression", function()
                local tests = {
                    { "!5;", "!", 5 },
                    { "-15;", "-", 15 },
                    { "!true;", "!", true },
                    { "!false;", "!", false },
                }
                for i = 1, #tests do
                    local input = tests[i][1]
                    local operator = tests[i][2]
                    local value = tests[i][3]
                    local program = CreateProgram(input)
                    CountStatement(1, program, assert)
                    local statement = program.statements[1]
                    local expression = statement.expression
                    assert.are.same(operator, expression.operator)
                    AssertLiteralExpression(expression.right, value, assert)
                end
            end)
        end)
    end)
end)