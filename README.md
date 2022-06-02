# Julieta

[Lua](https://www.lua.org/) implementation of the [Monkey Language](https://monkeylang.org/)

Julieta has many sibling implementations

* Kotlin: [monkey.kt](https://github.com/MarioAriasC/monkey.kt)
* Crystal: [Monyet](https://github.com/MarioAriasC/monyet)
* Scala 3: [Langur](https://github.com/MarioAriasC/langur)
* Ruby 3: [Pepa](https://github.com/MarioAriasC/pepa)
* Python 3: [Bruno](https://github.com/MarioAriasC/bruno)

## Status

The book ([Writing An Interpreter In Go](https://interpreterbook.com/)) is fully implemented. Julieta will not have a
compiler implementation

## Commands

Before running the tests you must install [busted](olivinelabs.com/busted/) from LuaRocks

```shell
luarocks install busted
```

| Script                               | Description                                        |
|--------------------------------------|----------------------------------------------------|
| [`./tests.sh`](tests.sh)             | Run tests                                          |
| [`lua benchmarks.py`](benchmarks.py) | Run the classic monkey benchmark (`fibonacci(35)`) |
| [`lua repl.py`](repl.py)             | Run the Julieta REPL                               |

You can run the benchmarks and repl files with either Lua or LuaJit. I didn't try any other Lua interprete

## Acknowlegments 

Julieta uses the [lua-oo](https://github.com/limadm/lua-oo) library from Daniel Lima 
