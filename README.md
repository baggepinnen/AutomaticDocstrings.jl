# AutomaticDocstrings
[![Build Status](https://travis-ci.org/baggepinnen/AutomaticDocstrings.jl.svg?branch=master)](https://travis-ci.org/baggepinnen/AutomaticDocstrings.jl)
[![codecov](https://codecov.io/gh/baggepinnen/AutomaticDocstrings.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/baggepinnen/AutomaticDocstrings.jl)

This small package automatically generates docstring stubs for you to fill in.

Place the macro call `@autodoc` above the function that you want to generate a docstring for:
```julia
using AutomaticDocstrings

@autodoc
function f(x::A, b=5; c=LinRange(1,2,10)) where A
    5
end
```
When you execute the macro, e.g. by ctrl-enter in Juno, the macro is replaced by a docstring
```julia
"""
    f(x::A, b=5; c=LinRange(1,2,10)) where A

FUNCTION DESCRIPTION

#Arguments:
- `x`: DESCRIPTION
- `b`: DESCRIPTION
- `c`: DESCRIPTION
"""
function f(x::A, b=5; c=LinRange(1,2,10)) where A
    5
end
```
Before modifying your file, a backup is saved.
```julia-repl
[ Info: Saved a backup to /tmp/jl_VQvgbW/backup
```
If you don't like the docstring or if something went wrong, ctrl-z (undo) works fine as well.

# Limitations
- If a file with multiple `@autodoc` are `include`ed, then only the first will be executed and then an error is thrown. Instead of `include(file)` call `autodoc(file)`.
- Make sure the file is saved before you try to generate any docstrings.
- Short-form function definitions with `where`, e.g., `f(a::A) where A`, does not work.
