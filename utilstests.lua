require("lexer")
require("parser")
require("busted.runner")

function CreateProgram(input)
    local lexer = Lexer { input = input }
    local parser = Parser { lexer = lexer }
    local program = parser:parseProgram()
    CheckParserErrors(parser)
    return program
end

function CheckParserErrors(parser)
    local errors = parser:getErrors()
    if #errors ~= 0 then
        error(string.format("parser has %s errors: %s\n", #errors, table.concat(errors, "\n")))
    end
end

function CountStatement(i, program, assert)
    local size = #program.statements
    assert.are.same(i, size)
end

function AssertLetStatement(statement, expectedIdentifier, assert)
    assert.are.same("let", statement:getTokenLiteral())
    assert.are.same(expectedIdentifier, statement.name.value)
    assert.are.same(expectedIdentifier, statement.name:getTokenLiteral())
end

function AssertLiteralExpression(value, expectedValue, assert)
    local expectedType = type(expectedValue)
    if expectedType == "boolean" then
        AssertBoolean(value, expectedValue, assert)
    elseif expectedType == "number" then
        AssertIntegerLiteral(value, expectedValue, assert)
    elseif expectedType == "string" then
        AssertIdentifier(value, expectedValue, assert)
    else
        error(string.format("type of value not handled. got=%s", expectedType))
    end
end

function AssertIntegerLiteral(expression, expectedValue, assert)
    assert.are.same(expectedValue, expression.value)
    assert.are.same(tostring(expectedValue), expression:getTokenLiteral())
end

AssertBoolean = AssertIntegerLiteral

function AssertIdentifier(expression, expectedValue, assert)
    assert.are.same(expectedValue, expression.value)
    assert.are.same(expectedValue, expression:getTokenLiteral())
end

function AssertInfixExpression(expression, leftValue, operator, rightValue, assert)
    AssertLiteralExpression(expression.left, leftValue, assert)
    assert.are.same(operator, expression.operator)
    AssertLiteralExpression(expression.right, rightValue, assert)
end

function ForEachTests(array, params, body)
    local switch = {
        [2] = function(entry)
            body(entry[1], entry[2])
        end,
        [3] = function(entry)
            body(entry[1], entry[2], entry[3])
        end,
        [4] = function(entry)
            body(entry[1], entry[2], entry[3], entry[4])
        end
    }

    ForEach(array, switch[params])
end

