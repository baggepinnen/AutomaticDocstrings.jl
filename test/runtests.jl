using Test, AutomaticDocstrings

function testdoc(input, output)
    # Test function autodoc
    path, io = mktemp()
    write(io, input)
    close(io)
    autodoc(path)
    result = reduce(*, readlines(path, keep=true))
    occursin(output, result) || return false

    # Test macro @autodoc
    write(io, input)
    close(io)
    include(path)
    result = reduce(*, readlines(path, keep=true))
    occursin(output, result)
end

@test testdoc(
"""
@autodoc
function f(a, b; c)
end
""",
"""
\"\"\"
    f(a, b; c)

FUNCTION DESCRIPTION

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

FUNCTION DESCRIPTION

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

FUNCTION DESCRIPTION

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

FUNCTION DESCRIPTION

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

FUNCTION DESCRIPTION

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

FUNCTION DESCRIPTION
\"\"\"
function f(a=4, b=LinRange(1,2,3))
end
""")



restore_defaults()
@test AutomaticDocstrings.options[:full_def]
