module AutomaticDocstrings
using CSTParser
export @autodoc, autodoc

macro autodoc()
    quote
        file = $(esc(String(__source__.file)))
        li = $(esc(__source__.line))
        autodoc(file, li)
    end
end


function autodoc(file, li)
    docstring = generate_docstring(file,li)
    save_backup(file)
    print_docstring(file, li, docstring)
    "Success"
end

function autodoc(file)
    lines = readlines(file, keep=true)
    li = 1
    while li <= length(lines)
        line = lines[li]
        if line[1] != '#' && occursin("@autodoc", line) && !occursin("@autodocf", line)
            docstring = generate_docstring(file,li)
            lines[li] = docstring
        end
        li += 1
    end
    save_backup(file)
    printlines(file, lines)
    "Success"
    # error("autodoc was successful. This error is just to stop execution of the file.")
end

function generate_docstring(file,li)
    fundef, parseddef = get_function_definition(file,li)
    argnames = get_args(parseddef)
    build_docstring(fundef, argnames)
end


function get_function_definition(file,li)
    lines = readlines(file, keep=true)
    alllines = reduce(*, lines[li+1:end])
    CSTParser.defines_function(CSTParser.parse(alllines)) || error("I did not find a function definition. Place `@autodoc` right above a function definition. Line number: $li")
    fundef = Meta.parse(alllines,1)[1]
    fundef = String(split(string(fundef), '\n')[1])
    parseddef = CSTParser.parse(fundef)
    fundef = strip_function_keyword(fundef)
    fundef, parseddef
end

function get_args(parseddef)
    args = CSTParser.get_args(parseddef)
    argnames = CSTParser.str_value.(args)
end

function build_docstring(fundef, argnames)
    str = "\"\"\"\n    $fundef\n\nFUNCTION DESCRIPTION\n"
    if !isempty(argnames)
        str = string(str, "\n#Arguments:\n")
        for argname in argnames
            argstr = "- `$argname`: DESCRIPTION\n"
            str = string(str, argstr)
        end
    end
    str = str*"\"\"\"\n"
    str
end

function save_backup(src)
    path = mktempdir()
    cp(src, path*"/backup.jl")
    @info "Saved a backup to $(path)/backup"
end

function printlines(file, lines)
    path,io = mktemp()
    foreach(l->write(io,l), lines)
    close(io)
    cp(path, file, force=true)
end

function print_docstring(file, li, docstring)
    lines = readlines(file, keep=true)
    lines[li] = docstring
    printlines(file, lines)
end

function strip_function_keyword(fundef)
    length(fundef) > 9 && fundef[1:8] == "function" ? fundef[10:end] : fundef
end

end # module
