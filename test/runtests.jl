using Test, AutomaticDocstrings

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
        println("Result:     ==================================================")
        println(result)
        println("Expected:   ==================================================")
        println(output)
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

#Arguments:
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

#Arguments:
- `a`: DESCRIPTION
- `b`: DESCRIPTION
- `c`: DESCRIPTION
\"\"\"
function f(a,
    b;
    c)
end
""")


@test_broken testdoc(
"""
@autodoc
f(a::A, b; c) where A = 5
""",
"""
\"\"\"
f(a, b; c) where A

DOCSTRING

#Arguments:
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
    f(a::A, b; c) where A

DOCSTRING

#Arguments:
- `a`: DESCRIPTION
- `b`: DESCRIPTION
- `c`: DESCRIPTION
\"\"\"
function f(a::A, b; c) where A
    5
end
""")



AutomaticDocstrings.options[:full_def] = false


@test testdoc(
"""
@autodoc
function f(a=4, b=LinRange(1,2,3); c="hello")
end
""",
"""
\"\"\"
    f(a, b, c)

DOCSTRING

#Arguments:
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
@test AutomaticDocstrings.options[:full_def]

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
    struct Workspace{T1, T2, T3, T4, T5, T6}

DOCSTRING

#Arguments:
- `simple_input`: DESCRIPTION
- `simple_result`: DESCRIPTION
- `result`: DESCRIPTION
- `buffersetter`: DESCRIPTION
- `resultsetter`: DESCRIPTION
- `f`: DESCRIPTION
- `N`: DESCRIPTION
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






using CSTParser

tests = "struct Workspace{T1,T2,T3,T4,T5,T6}
    simple_input::T1
    simple_result::T2
    result::T3
    buffersetter::T4
    resultsetter::T5
    f::T6
    N::Int
end"

parseddef = CSTParser.parse(tests)
args = CSTParser.get_args(parseddef)
argnames = CSTParser.str_value.(args)
