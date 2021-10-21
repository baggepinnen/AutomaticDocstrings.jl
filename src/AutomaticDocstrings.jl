module AutomaticDocstrings
using CSTParser
export @autodoc, autodoc, restore_defaults

options = Dict(
:min_args => 3, # Minimum number of arguments to print the argument list
:args_header => "# Arguments:", # Printed above the argument list
:full_def => true # Include the full function signature, if false, only include function and argument name
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
    fundef, argnames = get_function_definition(file,li)
    build_docstring(fundef, argnames)
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
    fundef = Meta.parse(alllines,1)[1]
    if kwdef || CSTParser.defines_struct(parsedlines)
        args = fundef.args[3].args
        args = filter(x->x isa Expr, args)
        return (fundef.args[2]), (args)
    end
    fundef = String(split(string(fundef), '\n')[1])
    parseddef = CSTParser.parse(fundef)
    fundef = strip_function_keyword(fundef)
    argnames = get_args(parseddef)
    fundef, argnames
end

function get_args(parseddef)
    args = CSTParser.get_args(parseddef) # old definition of get_args is copied from CSTParser below
    argnames = CSTParser.str_value.(args)
end

function build_docstring(fundef, argnames)
    if options[:full_def]
        str = "\"\"\"\n    $fundef\n\nDOCSTRING\n"
    else
        funname = split(fundef, '(')[1]
        argstring = replace(string((string.(argnames)...,)), '"'=>"")
        str = "\"\"\"\n    $(funname)$(argstring)\n\nDOCSTRING\n"
    end
    if !isempty(argnames) && length(argnames) >= options[:min_args]
        str = string(str, "\n$(options[:args_header])\n")
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


# This is get_args from cst_parser before they removed it, might become useful
# function get_args(x::EXPR)
#     if isidentifier(x)
#         return EXPR[]
#     elseif defines_anon_function(x) && !(typof(x.args[1]) === TupleH)
#         arg = x.args[1]
#         arg = rem_invis(arg)
#         arg = get_arg_name(arg)
#         return [arg]
#     elseif typof(x) === TupleH
#         args = EXPR[]
#         for i = 2:length(x.args)
#             arg = x.args[i]
#             ispunctuation(arg) && continue
#             typof(arg) === Parameters && continue
#             arg_name = get_arg_name(arg)
#             push!(args, arg_name)
#         end
#         return args
#     elseif typof(x) === Do
#         args = EXPR[]
#         for i = 1:length(x.args[3].args)
#             arg = x.args[3].args[i]
#             ispunctuation(arg) && continue
#             typof(arg) === Parameters && continue
#             arg_name = get_arg_name(arg)
#             push!(args, arg_name)
#         end
#         return args
#     elseif typof(x) === Call || typof(x) === MacroCall
#
#         args = EXPR[]
#         sig = rem_where(x)
#         sig = rem_decl(sig)
#         if typof(sig) === Call || typof(x) === MacroCall
#             for i = 2:length(sig.args)
#                 arg = sig.args[i]
#                 ispunctuation(arg) && continue
#                 if typof(arg) === Parameters
#                     append!(args, get_args(arg))
#                 else
#                     arg_name = get_arg_name(arg)
#                     push!(args, arg_name)
#                 end
#             end
#         else
#             error("not sig: $sig")
#         end
#         return args
#     elseif typof(x) === Parameters
#         args = EXPR[]
#         for i = 1:length(x.args)
#             parg = x.args[i]
#             ispunctuation(parg) && continue
#             parg_name = get_arg_name(parg)
#             push!(args, parg_name)
#         end
#         return args
#     elseif typof(x) === Struct
#         args = EXPR[]
#         for arg in x.args[3]
#             if !defines_function(arg)
#                 arg = rem_decl(arg)
#                 push!(args, arg)
#             end
#         end
#         return args
#     elseif typof(x) === Mutable
#         args = EXPR[]
#         for arg in x.args[4]
#             if !defines_function(arg)
#                 arg = rem_decl(arg)
#                 push!(args, arg)
#             end
#         end
#         return args
#     elseif typof(x) === Flatten
#         return get_args(x.args[1])
#     elseif typof(x) === Generator || typof(x) === Flatten
#         args = EXPR[]
#         if typof(x.args[1]) === Flatten || typof(x.args[1]) === Generator
#             append!(args, get_args(x.args[1]))
#         end
#
#         if typof(x.args[3]) === Filter
#             return get_args(x.args[3])
#         else
#             for i = 3:length(x.args)
#                 arg = x.args[i]
#                 if is_range(arg)
#                     arg = rem_decl(arg.args[1])
#                     arg = flatten_tuple(arg)
#                     arg = rem_decl.(arg)
#                     append!(args, arg)
#                 end
#             end
#             return args
#         end
#     else
#         sig = get_sig(x)
#         sig = rem_where(sig)
#         sig = rem_decl(sig)
#         return get_args(sig)
#     end
# end
