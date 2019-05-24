module AutomaticDocstrings
using CSTParser
export @autodoc

macro autodoc()
    quote
        file = $(esc(String(__source__.file)))
        line = $(esc(__source__.line))
        generate_docstring(file,line)
    end
end

function generate_docstring(file,line)
    fundef, parseddef = get_function_definition(file,line)
    argnames = get_args(parseddef)
    docstring = build_docstring(fundef, argnames)
    save_backup(file)
    print_docstring(file, line, docstring)
    error()
end

function get_function_definition(file,line)
    lines = readlines(file)
    fundef = lines[line+1] # TODO: replace with CSTParser to handle multiline defs
    parseddef = CSTParser.parse(fundef)
    CSTParser.defines_function(parseddef) || error("I did not find a function definition. Place `@autodoc` right above a function definition.")
    fundef, parseddef
end

function get_args(parseddef)
    args = CSTParser.get_args(parseddef)
    argnames = CSTParser.str_value.(args)
end

function build_docstring(fundef, argnames)
    str = "\"\"\"\n    $fundef\n\nFUNCTION DESCRIPTION\n\n#Arguments:\n"
    for argname in argnames
        argstr = "- `$argname`: Description\n"
        str = string(str, argstr)
    end
    str = str*"\"\"\"\n"
    str
end

function save_backup(src)
    path = mktempdir()
    cp(src, path*"/backup.jl")
    @info "Saved a backup to $(path)/backup"
end

function print_docstring(file, line, docstring)
    lines = readlines(file, keep=true)
    deleteat!(lines, line) # Remove macro call
    insert!(lines, line, docstring)
    path,io = mktemp()
    foreach(l->write(io,l), lines)
    close(io)
    cp(path, file, force=true)
end

end # module
