module AutomaticDocstrings
using CSTParser
using MacroTools
export @autodoc, autodoc, restore_defaults

options = Dict(
:min_args => 3, # Minimum number of arguments to print the argument list
:args_header => "# Arguments:", # Printed above the argument list
:full_def => true, # Include the full function signature, if false, only include function and argument name
:arg_types_in_desc => false, # Include the argument types in the description
)

const DEFAULT_OPTIONS = deepcopy(options)
function restore_defaults()
    global options = deepcopy(DEFAULT_OPTIONS)
end

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
    fundef, argnames, argtypes = get_function_definition(file,li)
    build_docstring(fundef, argnames, argtypes)
end


function get_function_definition(file,li)
    lines = readlines(file, keep=true)
    alllines = reduce(*, lines[li+1:end])

    kwdef1 = occursin("@kwdef ", alllines[1:7])
    kwdef2 = occursin("Base.@kwdef ", alllines[1:12])
    kwdef1 && (alllines = alllines[8:end])
    kwdef2 && (alllines = alllines[13:end])
    kwdef = kwdef1 || kwdef2
    

    parsedlines = CSTParser.parse(alllines)
    CSTParser.defines_function(parsedlines) ||
        CSTParser.defines_struct(parsedlines) ||
        error("I did not find a function or struct definition. Place `@autodoc` right above a function or struct definition. Line number: $li")
    fundef0 = Meta.parse(alllines,1)[1]
    fundef0 = rm_where(fundef0)
    if kwdef || CSTParser.defines_struct(parsedlines)
        args = fundef0.args[3].args
        args = filter(x->x isa Expr, args)
        return (fundef0.args[2]), (args), nothing
    end
    fundef = String(split(string(fundef0), '\n')[1])
    fundef = strip_function_keyword(fundef)
    fundef = replace(fundef, "; )" => ")")
    argnames, argtypes = get_args(fundef0)
    return fundef, argnames, argtypes
end

function rm_where(fundef)
    try
        sd = MacroTools.splitdef(fundef)
        sd[:whereparams] = ()
        return MacroTools.combinedef(sd)
    catch
        return fundef
    end
end


function get_args(fundef)
    sd = MacroTools.splitdef(fundef)
    args = String[]
    argtypes = String[]
    for arg in vcat(sd[:args], sd[:kwargs])
        (arg_name, arg_type, is_splat, default) = MacroTools.splitarg(arg)
        push!(args, string(arg_name))
        push!(argtypes, string(arg_type))
    end
    args, argtypes
end

function build_docstring(fundef, argnames, argtypes)
    if options[:full_def]
        if options[:arg_types_in_desc] && !isnothing(argtypes)
            fundef = replace(fundef, r"(::.+?)([,|=| =])" => s"\2")
        end
        str = "\"\"\"\n    $fundef\n\nDOCSTRING\n"
    else
        funname = split(fundef, '(')[1]
        argstring = replace(string((string.(argnames)...,)), '"'=>"")
        str = "\"\"\"\n    $(funname)$(argstring)\n\nDOCSTRING\n"
    end
    if !isempty(argnames) && length(argnames) >= options[:min_args]
        str = string(str, "\n$(options[:args_header])\n")
        for (i, argname) in enumerate(argnames)
            argstr = if options[:arg_types_in_desc] && !isnothing(argtypes) && argtypes[i] != "Any"
                "- `$argname::$(argtypes[i])`: DESCRIPTION\n"
            else
                "- `$argname`: DESCRIPTION\n"
            end
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

