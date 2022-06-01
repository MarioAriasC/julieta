require "busted.runner"()
require("utilstests")
require("eval")
require("objects")
describe("Eval", function()
    describe("should evaluate", function()
        local function eval(input)
            local program = CreateProgram(input)
            return Eval(program, Environment {})
        end

        local function assertIntegerObject(evaluated, expected)
            if evaluated:is(MInteger) then
                assert.are.same(expected, evaluated.value)
            else
                error(string.format("obj is not MInteger, got %s, %s", evaluated.className, evaluated))
            end
        end

        local function assertInteger(input, expected)
            local evaluated = eval(input)
            assertIntegerObject(evaluated, expected)
        end

        local function assertBoolean(input, expected)
            local evaluated = eval(input)
            if evaluated:is(MBoolean) then
                assert.are.same(expected, evaluated.value)
            else
                error(string.format("obj is not MBoolean, got %s, %s", evaluated.className, evaluated))
            end
        end

        local function assertNilObject(evaluated)
            assert.are.same(M_NULL, evaluated)
        end

        local function assertString(input, expected)
            local evaluated = eval(input)
            if evaluated:is(MString) then
                assert.are.same(expected, evaluated.value)
            else
                error(string.format("obj is not MString, got %s, %s", evaluated.className, evaluated))
            end
        end

        it("integer expressions", function()
            local tests = {
                { "5", 5 },
                { "10", 10 },
                { "-5", -5 },
                { "-10", -10 },
                { "5 + 5 + 5 + 5 - 10", 10 },
                { "2 * 2 * 2 * 2 * 2", 32 },
                { "-50 + 100 + -50", 0 },
                { "5 * 2 + 10", 20 },
                { "5 + 2 * 10", 25 },
                { "20 + 2 * -10", 0 },
                { "50 / 2 * 2 + 10", 60 },
                { "2 * (5 + 10)", 30 },
                { "3 * 3 * 3 + 10", 37 },
                { "3 * (3 * 3) + 10", 37 },
                { "(5 + 10 * 2 + 15 / 3) * 2 + -10", 50 },
            }
            ForEachTests(tests, 2, function(input, expected)
                assertInteger(input, expected)
            end)
        end)
        it("boolean expression", function()
            local tests = {
                { "true", true },
                { "false", false },
                { "1 < 2", true },
                { "1 > 2", false },
                { "1 < 1", false },
                { "1 > 1", false },
                { "1 == 1", true },
                { "1 != 1", false },
                { "1 == 2", false },
                { "1 != 2", true },
                { "true == true", true },
                { "false == false", true },
                { "true == false", false },
                { "true != false", true },
                { "false != true", true },
                { "(1 < 2) == true", true },
                { "(1 < 2) == false", false },
                { "(1 > 2) == true", false },
                { "(1 > 2) == false", true },
            }
            ForEachTests(tests, 2, function(input, expected)
                assertBoolean(input, expected)
            end)
        end)
        it("bang operator", function()
            local tests = {
                { "!true", false },
                { "!false", true },
                { "!5", false },
                { "!!true", true },
                { "!!false", false },
                { "!!5", true },
            }
            ForEachTests(tests, 2, function(input, expected)
                assertBoolean(input, expected)
            end)
        end)
        it("if else expression", function()
            local tests = {
                { "if (true) { 10 }", 10 },
                { "if (false) { 10 }", nil },
                { "if (1) { 10 }", 10 },
                { "if (1 < 2) { 10 }", 10 },
                { "if (1 > 2) { 10 }", nil },
                { "if (1 > 2) { 10 } else { 20 }", 20 },
                { "if (1 < 2) { 10 } else { 20 }", 10 },
            }
            ForEachTests(tests, 2, function(input, expected)
                local evaluated = eval(input)
                if expected == nil then
                    assertNilObject(evaluated)
                else
                    assertIntegerObject(evaluated, expected)
                end
            end)
        end)
        it("return statements", function()
            local tests = {
                { "return 10;", 10 },
                { "return 10; 9;", 10 },
                { "return 2 * 5; 9;", 10 },
                { "9; return 2 * 5; 9;", 10 },
                {
                    [[
                      if (10 > 1) {
            if (10 > 1) {
            return 10;
            }

            return 1;
            }
                    ]], 10
                },
                {
                    [[let f = fn(x) {
                return x;
                x + 10;

            };
            f(10);
            ]],
                    10,
                },
                {
                    [[let f = fn(x) {
            let
            result = x + 10;
            return result;
            return 10;
            };
            f(10);
            ]],
                    20,
                }
            }
            ForEachTests(tests, 2, function(input, expected)
                assertInteger(input, expected)
            end)
        end)
        it("error handling", function()
            local tests = {
                { "5 + true;", "type mismatch: MInteger + MBoolean" },
                { "5 + true; 5;", "type mismatch: MInteger + MBoolean" },
                { "-true", "unknown operator: -MBoolean" },
                { "true + false;", "unknown operator: MBoolean + MBoolean" },
                { "true + false + true + false;", "unknown operator: MBoolean + MBoolean" },
                { "5; true + false; 5", "unknown operator: MBoolean + MBoolean" },
                { "if (10 > 1) { true + false; }", "unknown operator: MBoolean + MBoolean" },
                {
                    [[
            if (10 > 1) {
            if (10 > 1) {
            return true + false;
            }

            return 1;}]],
                    "unknown operator: MBoolean + MBoolean",
                },
                { "foobar", "identifier not found: foobar" },
                { '("Hello" - "World")', "unknown operator: MString - MString" },
                { '{"name": "Monkey"}[fn(x) {x}];', "unusable as a hash key: MFunction" },
            }
            ForEachTests(tests, 2, function(input, expected)
                local error = eval(input)
                assert.are.same(expected, error.message)
            end)
        end)
        it("let statements", function()
            local tests = {
                { "let a = 5; a;", 5 },
                { "let a = 5 * 5; a;", 25 },
                { "let a = 5; let b = a; b;", 5 },
                { "let a = 5; let b = a; let c = a + b + 5; c;", 15 },
            }
            ForEachTests(tests, 2, function(input, expected)
                assertInteger(input, expected)
            end)
        end)
        it("function object", function()
            local input = "fn(x) { x + 2; };"
            local fn = eval(input)
            local parameters = fn.parameters
            assert.are.same(1, Len(parameters))
            assert.are.same("x", tostring(parameters[1]))
            assert.are.same("(x + 2)", tostring(fn.body))
        end)
        it("function application", function()
            local tests = {
                { "let identity = fn(x) { x; }; identity(5);", 5 },
                { "let identity = fn(x) { return x; }; identity(5);", 5 },
                { "let double = fn(x) { x * 2; }; double(5);", 10 },
                { "let add = fn(x, y) { x + y; }; add(5, 5);", 10 },
                { "let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20 },
                { "fn(x) { x; }(5)", 5 },
            }
            ForEachTests(tests, 2, function(input, expected)
                assertInteger(input, expected)
            end)
        end)
        it("enclosing environments", function()
            local input = [[let first = 10;
    let second = 10;
    let third = 10;

    let ourFunction = fn(first) {
      let second = 20;

      first + second + third;
    };

    ourFunction(20) + first + second;
            ]]
            assertIntegerObject(eval(input), 70)
        end)
        it("string literal", function()
            assertString('"Hello World!"', "Hello World!")
        end)
        it("string concatenation", function()
            assertString('"Hello" + " " + "World!"', "Hello World!")
        end)
        it("builtin functions", function()
            local tests = {
                { 'len("")', 0 },
                { 'len("four")', 4 },
                { 'len("hello world")', 11 },
                { "len(1)", "argument to `len` not supported, got MInteger" },
                { 'len("one", "two")', "wrong number of arguments. got=2, want=1" },
                { "len([1, 2, 3])", 3 },
                { "len([])", 0 },
                { "push([], 1)", { 1 } },
                { "push(1, 1)", "argument to `push` must be ARRAY, got MInteger" },
                { "first([1, 2, 3])", 1 },
                { "first([])", nil },
                { "first(1)", "argument to `first` must be ARRAY, got MInteger" },
                { "last([1, 2, 3])", 3 },
                { "last([])", nil },
                { "last(1)", "argument to `last` must be ARRAY, got MInteger" },
                { "rest([1, 2, 3])", { 2, 3 } },
                { "rest([])", nil },
            }
            ForEachTests(tests, 2, function(input, expected)
                local evaluated = eval(input)
                if expected == nil then
                    assertNilObject(evaluated)
                elseif type(expected) == "number" then
                    assertIntegerObject(evaluated, expected)
                elseif type(expected) == "string" then
                    assert.are.same(expected, evaluated.message)
                else
                    assert.are.same(Len(expected), Len(evaluated.elements))
                    ForEachIndexed(expected, function(i, element)
                        assertIntegerObject(evaluated.elements[i], element)
                    end)
                end


            end)
        end)
        it("array literal", function()
            local result = eval("[1, 2 * 2, 3 + 3]")
            assert.are.same(3, Len(result.elements))
            ForEachIndexed({ 1, 4, 6 }, function(i, value)
                assertIntegerObject(result.elements[i], value)
            end)
        end)
        it("array index expression", function()
            local test = {
                { "[1, 2, 3][0]", 1 },
                { "[1, 2, 3][1]", 2 },
                { "[1, 2, 3][2]", 3 },
                { "let i = 0; [1][i];", 1 },
                { "[1, 2, 3][1 + 1];", 3 },
                { "let myArray = [1, 2, 3]; myArray[2];", 3 },
                { "let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];", 6 },
                { "let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]", 2 },
                { "[1, 2, 3][3]", nil },
                { "[1, 2, 3][-1]", nil },
            }
            ForEachTests(test, 2, function(input, expected)
                local evaluated = eval(input)
                if type(expected) == "number" then
                    assertIntegerObject(evaluated, expected)
                else
                    assertNilObject(evaluated)
                end
            end)
        end)
        it("hash literal", function()
            local input = [[let two = "two";
    {
    "one": 10 - 9,
    two: 1 + 1,
    "thr" + "ee": 6 / 2,
    4: 4,
    true: 5,
    false: 6
    }]]
            local result = eval(input)
            local expected = {
                [tostring(MString { value = "one" }:hashKey())] = 1,
                [tostring(MString { value = "two" }:hashKey())] = 2,
                [tostring(MString { value = "three" }:hashKey())] = 3,
                [tostring(MInteger { value = 4 }:hashKey())] = 4,
                [tostring(M_TRUE:hashKey())] = 5,
                [tostring(M_FALSE:hashKey())] = 6,
            }
            assert.are.same(Len(result.entries), Len(expected))
            for key, value in pairs(expected) do
                local entry = result.entries[key]
                assert.is_not_nil(entry)
                assertIntegerObject(entry.value, value)
            end
        end)
        it("hash index expressions", function()
            local tests = {
                { '{"foo": 5, "bar": 7}["foo"]', 5 },
                { '{"foo": 5}["bar"]', nil },
                { 'let key = "foo";{"foo": 5}[key]', 5 },
                { '{}["foo"]', nil },
                { "{5:5}[5]", 5 },
                { "{true:5}[true]", 5 },
                { "{false:5}[false]", 5 },
            }
            ForEachTests(tests, 2, function(input, expected)
                local evaluated = eval(input)
                if expected == nil then
                    assertNilObject(evaluated)
                else
                    assertIntegerObject(evaluated, expected)
                end
            end)
        end)
        it("recursive fibonacci", function()
            local input = [[let fibonacci = fn(x) {
        	if (x == 0) {
        		return 0;
        	} else {
        		if (x == 1) {
        			return 1;
        		} else {
        			fibonacci(x - 1) + fibonacci(x - 2);
        		}
        	}
        };
        fibonacci(15);]]
            local evaluated = eval(input)
            assertIntegerObject(evaluated, 610)
        end)
    end)
end)