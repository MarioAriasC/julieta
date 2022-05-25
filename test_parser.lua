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
                ForEachTests(tests, 3, function(input, expectedIdentifier, expectedValue)
                    local program = CreateProgram(input)
                    CountStatement(1, program, assert)
                    local statement = program.statements[1]
                    AssertLetStatement(statement, expectedIdentifier, assert)
                    local value = statement.value
                    AssertLiteralExpression(value, expectedValue, assert)
                end)
            end)
            it("return statements", function()
                local tests = {
                    { "return 5;", 5 },
                    { "return true;", true },
                    { "return foobar;", "foobar" }
                }
                ForEachTests(tests, 2, function(input, expectedIdentifier)
                    local program = CreateProgram(input)
                    CountStatement(1, program, assert)
                    local statement = program.statements[1]
                    assert.are.same("return", statement:getTokenLiteral())
                    AssertLiteralExpression(statement.returnValue, expectedIdentifier, assert)
                end)
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
                ForEachTests(tests, 3, function(input, operator, value)
                    local program = CreateProgram(input)
                    CountStatement(1, program, assert)
                    local statement = program.statements[1]
                    local expression = statement.expression
                    assert.are.same(operator, expression.operator)
                    AssertLiteralExpression(expression.right, value, assert)
                end)
            end)
            it("infix expressions", function()
                local tests = {
                    { "5 + 5;", 5, "+", 5 },
                    { "5 - 5;", 5, "-", 5 },
                    { "5 * 5;", 5, "*", 5 },
                    { "5 / 5;", 5, "/", 5 },
                    { "5 > 5;", 5, ">", 5 },
                    { "5 < 5;", 5, "<", 5 },
                    { "5 == 5;", 5, "==", 5 },
                    { "5 != 5;", 5, "!=", 5 },
                    { "true == true", true, "==", true },
                    { "true != false", true, "!=", false },
                    { "false == false", false, "==", false },
                }
                ForEachTests(tests, 4, function(input, leftValue, operator, rightValue)
                    local program = CreateProgram(input)
                    CountStatement(1, program, assert)
                    AssertInfixExpression(program.statements[1].expression, leftValue, operator, rightValue, assert)
                end)
            end)
            it("operator precedence", function()
                local tests = {
                    {
                        "-a * b",
                        "((-a) * b)",
                    },
                    {
                        "!-a",
                        "(!(-a))",
                    },
                    {
                        "a + b + c",
                        "((a + b) + c)",
                    },
                    {
                        "a + b - c",
                        "((a + b) - c)",
                    },
                    {
                        "a * b * c",
                        "((a * b) * c)",
                    },
                    {
                        "a * b / c",
                        "((a * b) / c)",
                    },
                    {
                        "a + b / c",
                        "(a + (b / c))",
                    },
                    {
                        "a + b * c + d / e - f",
                        "(((a + (b * c)) + (d / e)) - f)",
                    },
                    {
                        "3 + 4; -5 * 5",
                        "(3 + 4)((-5) * 5)",
                    },
                    {
                        "5 > 4 == 3 < 4",
                        "((5 > 4) == (3 < 4))",
                    },
                    {
                        "5 < 4 != 3 > 4",
                        "((5 < 4) != (3 > 4))",
                    },
                    {
                        "3 + 4 * 5 == 3 * 1 + 4 * 5",
                        "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))",
                    },
                    {
                        "true",
                        "true",
                    },
                    {
                        "false",
                        "false",
                    },
                    {
                        "3 > 5 == false",
                        "((3 > 5) == false)",
                    },
                    {
                        "3 < 5 == true",
                        "((3 < 5) == true)",
                    },
                    {
                        "1 + (2 + 3) + 4",
                        "((1 + (2 + 3)) + 4)",
                    },
                    {
                        "(5 + 5) * 2",
                        "((5 + 5) * 2)",
                    },
                    {
                        "2 / (5 + 5)",
                        "(2 / (5 + 5))",
                    },
                    {
                        "(5 + 5) * 2 * (5 + 5)",
                        "(((5 + 5) * 2) * (5 + 5))",
                    },
                    {
                        "-(5 + 5)",
                        "(-(5 + 5))",
                    },
                    {
                        "!(true == true)",
                        "(!(true == true))",
                    },
                    {
                        "a + add(b * c) + d",
                        "((a + add((b * c))) + d)",
                    },
                    {
                        "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
                        "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))",
                    },
                    {
                        "add(a + b + c * d / f + g)",
                        "add((((a + b) + ((c * d) / f)) + g))",
                    },
                    {
                        "a * [1, 2, 3, 4][b * c] * d",
                        "((a * ([1, 2, 3, 4][(b * c)])) * d)",
                    },
                    {
                        "add(a * b[2], b[1], 2 * [1, 2][1])",
                        "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))",
                    },
                }
                ForEachTests(tests, 2, function(input, expected)
                    local program = CreateProgram(input)
                    assert.are.same(expected, tostring(program))
                end)
            end)
            it("boolean expression", function()
                local tests = {
                    { "true", true },
                    { "false", false }
                }
                ForEachTests(tests, 2, function(input, expected)
                    local program = CreateProgram(input)
                    CountStatement(1, program, assert)
                    local booleanLiteral = program.statements[1].expression
                    assert.are.same(expected, booleanLiteral.value)
                end)
            end)
            it("if expression", function()
                local input = "if (x < y) { x }"
                local exp = assertIfExpression(input)
                assert.are.same(nil, exp.alternative)
            end)
            it("if else expression", function()
                local input = "if (x < y) { x } else { y }"
                local exp = assertIfExpression(input)
                assert.are.same(1, Len(exp.alternative.statements))
                local alternative = exp.alternative.statements[1]
                AssertIdentifier(alternative.expression, "y", assert)
            end)
            it("function literal", function()
                local input = "fn(x, y) { x + y;}"
                local program = CreateProgram(input)
                CountStatement(1, program, assert)
                local fun = program.statements[1].expression
                AssertLiteralExpression(fun.parameters[1], "x", assert)
                AssertLiteralExpression(fun.parameters[2], "y", assert)
                assert.are.same(1, Len(fun.body.statements))
                AssertInfixExpression(fun.body.statements[1].expression, "x", "+", "y", assert)
            end)
            it("function parameters", function()
                local tests = {
                    { "fn(){}", {} },
                    { "fn(x){}", { "x" } },
                    { "fn(x, y , z){}", { "x", "y", "z" } },
                }
                ForEachTests(tests, 2, function(input, expectedParams)
                    local program = CreateProgram(input)
                    local fun = program.statements[1].expression
                    assert.are.same(Len(expectedParams), Len(fun.parameters))
                    ForEachIndexed(expectedParams, function(i, param)
                        AssertLiteralExpression(fun.parameters[i], param, assert)
                    end)
                end)
            end)
            it("call expression", function()
                local input = "add(1, 2 * 3, 4+5)"
                local program = CreateProgram(input)
                CountStatement(1, program, assert)
                local exp = program.statements[1].expression
                AssertIdentifier(exp.expression, "add", assert)
                assert.are.same(3, Len(exp.arguments))
                AssertLiteralExpression(exp.arguments[1], 1, assert)
                AssertInfixExpression(exp.arguments[2], 2, "*", 3, assert)
                AssertInfixExpression(exp.arguments[3], 4, "+", 5, assert)
            end)
            it("literal expression", function()
                local input = '"hello world";'
                local program = CreateProgram(input)
                CountStatement(1, program, assert)
                assert.are.same("hello world", program.statements[1].expression.value)
            end)
            it("array literal", function()
                local input = "[1, 2 * 2, 3 + 3]"
                local program = CreateProgram(input)
                local array = program.statements[1].expression
                AssertIntegerLiteral(array.elements[1], 1, assert)
                AssertInfixExpression(array.elements[2], 2, "*", 2, assert)
                AssertInfixExpression(array.elements[3], 3, "+", 3, assert)
            end)
            it("parsing index expression", function()
                local input = "myArray[1 + 1]"
                local program = CreateProgram(input)
                local index = program.statements[1].expression
                AssertIdentifier(index.left, "myArray", assert)
                AssertInfixExpression(index.index, 1, "+", 1, assert)
            end)
            it("hash string keys", function()
                local input = '{"one": 1, "two": 2, "three": 3}'
                local program = CreateProgram(input)
                local hashLiteral = program.statements[1].expression
                assert.are.same(3, Len(hashLiteral.entries))
                local expected = { one = 1, two = 2, three = 3 }
                for key, value in pairs(hashLiteral.entries) do
                    local expectedValue = expected[tostring(key)]
                    AssertLiteralExpression(value, expectedValue, assert)
                end
            end)
        end)
    end)
end)

function assertIfExpression(input)
    local program = CreateProgram(input)
    CountStatement(1, program, assert)
    local exp = program.statements[1].expression
    AssertInfixExpression(exp.condition, "x", "<", "y", assert)
    assert.are.same(1, Len(exp.consequence.statements))
    local consequence = exp.consequence.statements[1]
    AssertIdentifier(consequence.expression, "x", assert)
    return exp
end