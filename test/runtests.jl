using Test, AutomaticDocstrings, DeepDiffs

function testdoc(input, output)
    # Test function autodoc
    path, io = mktemp()
    write(io, input)
    close(io)
    autodoc(path)
    result = reduce(*, readlines(path, keep=true))
    if !occursin(output, result)
        println("Autodoc failed, input:   =====================================")
        println(input)
        # println("Result:     ==================================================")
        # println(result)
        # println("Expected:   ==================================================")
        # println(output)
        println("Diff:       ==================================================")
        println(deepdiff(output, result))
        return false
    end

    # Test macro @autodoc
    write(io, input)
    close(io)
    include(path)
    result = reduce(*, readlines(path, keep=true))
    occursin(output, result)
end

restore_defaults()

@testset "AutomaticDocstrings" begin
    @info "Testing AutomaticDOcstrings"


@test testdoc(
"""
@autodoc
function f(a, b; c)
end
""",
"""
\"\"\"
    f(a, b; c)

DOCSTRING

# Arguments:
- `a`: DESCRIPTION
- `b`: DESCRIPTION
- `c`: DESCRIPTION
\"\"\"
function f(a, b; c)
end
""")


@test testdoc(
"""
@autodoc
function f(a,
    b;
    c)
end
""",
"""
\"\"\"
    f(a, b; c)

DOCSTRING

# Arguments:
- `a`: DESCRIPTION
- `b`: DESCRIPTION
- `c`: DESCRIPTION
\"\"\"
function f(a,
    b;
    c)
end
""")


@test testdoc(
"""
@autodoc
f(a::A, b; c) where A = 5
""",
"""
\"\"\"
    f(a::A, b; c)

DOCSTRING

# Arguments:
- `a`: DESCRIPTION
- `b`: DESCRIPTION
- `c`: DESCRIPTION
\"\"\"
f(a::A, b; c) where A = 5
""")


@test testdoc(
"""
@autodoc
function f(a::A, b; c) where A
    5
end
""",
"""
\"\"\"
    f(a::A, b; c)

DOCSTRING

# Arguments:
- `a`: DESCRIPTION
- `b`: DESCRIPTION
- `c`: DESCRIPTION
\"\"\"
function f(a::A, b; c) where A
    5
end
""")

AutomaticDocstrings.options[:arg_types_in_header] = false
AutomaticDocstrings.options[:defaults_in_header] = false


@test testdoc(
"""
@autodoc
function f(a=4, b=LinRange(1,2,3); c="hello")
end
""",
"""
\"\"\"
    f(a, b; c)

DOCSTRING

# Arguments:
- `a`: DESCRIPTION
- `b`: DESCRIPTION
- `c`: DESCRIPTION
\"\"\"
function f(a=4, b=LinRange(1,2,3); c="hello")
end
""")



# Fewer that min_args
@test testdoc(
"""
@autodoc
function f(a=4, b=LinRange(1,2,3))
end
""",
"""
\"\"\"
    f(a, b)

DOCSTRING
\"\"\"
function f(a=4, b=LinRange(1,2,3))
end
""")



restore_defaults()
@test AutomaticDocstrings.options[:arg_types_in_header]
@test AutomaticDocstrings.options[:defaults_in_header]

# Struct

@test testdoc(
"""
@autodoc
struct Workspace{T1,T2,T3,T4,T5,T6}
    simple_input::T1
    simple_result::T2
    result::T3
    buffersetter::T4
    resultsetter::T5
    f::T6
    N::Int
end
""",
"""
\"\"\"
    Workspace{T1, T2, T3, T4, T5, T6}

DOCSTRING

# Fields:
- `simple_input::T1`: DESCRIPTION
- `simple_result::T2`: DESCRIPTION
- `result::T3`: DESCRIPTION
- `buffersetter::T4`: DESCRIPTION
- `resultsetter::T5`: DESCRIPTION
- `f::T6`: DESCRIPTION
- `N::Int`: DESCRIPTION
\"\"\"
struct Workspace{T1,T2,T3,T4,T5,T6}
    simple_input::T1
    simple_result::T2
    result::T3
    buffersetter::T4
    resultsetter::T5
    f::T6
    N::Int
end
""")

@static if VERSION >= v"1.3"
import Base.@kwdef

@test testdoc(
"""
@autodoc
@kwdef struct Workspace{T1,T2,T3,T4,T5,T6}
    simple_input::T1
    simple_result::T2
    result::T3
    buffersetter::T4
    resultsetter::T5
    f::T6
    N::Int = 2
end
""",
"""
\"\"\"
    Workspace{T1, T2, T3, T4, T5, T6}

DOCSTRING

# Fields:
- `simple_input::T1`: DESCRIPTION
- `simple_result::T2`: DESCRIPTION
- `result::T3`: DESCRIPTION
- `buffersetter::T4`: DESCRIPTION
- `resultsetter::T5`: DESCRIPTION
- `f::T6`: DESCRIPTION
- `N::Int = 2`: DESCRIPTION
\"\"\"
@kwdef struct Workspace{T1,T2,T3,T4,T5,T6}
    simple_input::T1
    simple_result::T2
    result::T3
    buffersetter::T4
    resultsetter::T5
    f::T6
    N::Int = 2
end
""")
end

restore_defaults()
AutomaticDocstrings.options[:arg_types_in_desc] = true
AutomaticDocstrings.options[:arg_types_in_header] = false

@test testdoc(
"""
@autodoc
function f(x::A, b=5; c = LinRange(1,2,10)) where A
    5
end
""",
"""
\"\"\"
    f(x, b = 5; c = LinRange(1, 2, 10))

DOCSTRING

# Arguments:
- `x::A`: DESCRIPTION
- `b`: DESCRIPTION
- `c`: DESCRIPTION
\"\"\"
function f(x::A, b=5; c = LinRange(1,2,10)) where A
    5
end
""")


end
