# AutomaticDocstrings
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
    function f(x::A, b=5; c=LinRange(1,2,10)) where A

FUNCTION DESCRIPTION

#Arguments:
- `x`: Description
- `b`: Description
- `c`: Description
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
Currently, only single-line function definitions are supported.
