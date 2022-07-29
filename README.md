# AutomaticDocstrings
[![CI](https://github.com/baggepinnen/AutomaticDocstrings.jl/workflows/CI/badge.svg)](https://github.com/baggepinnen/AutomaticDocstrings.jl/actions)
[![codecov](https://codecov.io/gh/baggepinnen/AutomaticDocstrings.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/baggepinnen/AutomaticDocstrings.jl)

This small package automatically generates docstring stubs for you to fill in.

Install using `import Pkg; Pkg.add("AutomaticDocstrings")`

# Usage
Place the macro call `@autodoc` above the function or struct definition that you want to generate a docstring for:
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
    f(x::A, b=5; c=LinRange(1,2,10))

DOCSTRING

# Arguments:
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

# Options
You may modify the `AutomaticDocstrings.options::Dict` to change some default values:
- `:min_args = 3`: Minimum number of arguments to print the argument list of function
- `:args_header = "# Arguments:"`: Printed above the argument list of function
- `:kwargs_header = nothing`: Printed above the keyword argument list of function
- `:struct_fields_header = "# Fields:"`: Printed above the fields list of a struct
- `:full_def = true`: Include the full function signature, if false, only include function and argument name
- `:arg_types_in_desc = false`: Include the argument types in the description
- `:defaults_in_desc = false`: Include the default values in the description

You can always call `restore_defaults()` to restore the default options.
