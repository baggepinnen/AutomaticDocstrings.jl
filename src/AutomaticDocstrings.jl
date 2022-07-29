module AutomaticDocstrings
using CSTParser
using MacroTools
export @autodoc, autodoc, restore_defaults

options = Dict(
    :min_args => 3, # Minimum number of arguments to print the argument list
    :args_header => "# Arguments:", # Printed above the argument list
    :kwargs_header => nothing, # Printed above the keyword argument list
    :struct_fields_header => "# Fields:", # Printed above the fields list
    :full_def => true, # Include the full function signature, if false, only include function and argument name
    :arg_types_in_desc => false, # Include the argument types in the description
    :defaults_in_desc => false, # Include the default values in the description
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
    lines = readlines(file, keep=true)
    alllines = reduce(*, lines[li+1:end])
    build_docstring(alllines)
end


function remove_kwdef(str)
    if occursin("@kwdef ", str[1:7])
        return str[8:end], true
    elseif occursin("Base.@kwdef ", str[1:12])
        return str[13:end], true
    else 
        return str, false
    end
end

function getfunstr(fundef)
    str = "$(fundef[:name])("
    if !isempty(fundef[:args])
        str = str * (join(map(fundef[:args]) do f
            get_arg_item_str(f, options[:full_def] && !options[:arg_types_in_desc], options[:full_def])
        end,", "))
    end
    if !isempty(fundef[:kwargs])
        str = str * "; " * (join(map(fundef[:kwargs]) do f
            get_arg_item_str(f, options[:full_def] && !options[:arg_types_in_desc], options[:full_def])
        end,", ")) 
    end
    str = str * ")"
    return str
end

getArgName(e::Expr) = getArgName(e.args[1])
getArgName(e::Symbol) = e

function build_docstring(str)
    cleaned_str, is_kwdef = remove_kwdef(str)
    parsed = CSTParser.parse(cleaned_str)
    mp = Meta.parse(cleaned_str,1)[1]
    doc_str = if CSTParser.defines_function(parsed)
        build_function_doc_string(mp)
    elseif CSTParser.defines_struct(parsed)
        build_struct_doc_string(mp, is_kwdef)
    end
    return doc_str
end

function build_function_doc_string(mp::Expr)
    fundef = MacroTools.splitdef(mp)
    str = """
    \"\"\"
        $(getfunstr(fundef))

    DOCSTRING
    """
    if length(fundef[:args]) + length(fundef[:kwargs]) >= options[:min_args]
        if !isempty(fundef[:args]) || !isempty(fundef[:kwargs])
            str = str * "\n"
        end
        if !isempty(fundef[:args])
            !isnothing(options[:args_header]) && (str = str * "$(options[:args_header])\n")
            str = str * join(map(fundef[:args]) do f
                "- `" * get_arg_item_str(f, options[:arg_types_in_desc], options[:defaults_in_desc]) * "`: DESCRIPTION"
            end, "\n")
        end
        str = str * "\n"
        if !isempty(fundef[:kwargs])
            !isnothing(options[:kwargs_header]) && (str = str * "$(options[:kwargs_header])\n")
            str = str * join(map(fundef[:kwargs]) do f
                str = "- `" * get_arg_item_str(f, options[:arg_types_in_desc], options[:defaults_in_desc]) * "`: DESCRIPTION"
            end, "\n")
            str = str * "\n"
        end
    end
    str = str * "\"\"\"\n"
end

function get_arg_item_str(f, show_arg_types, show_defaults)
    (arg_name, arg_type, is_splat, default) = MacroTools.splitarg(f)
    str = "$arg_name"
    if string(arg_type) != "Any" && show_arg_types
        str = str * "::$arg_type"
    end
    if !isnothing(default) && show_defaults
        if (default isa Expr && default.head == :call) || !(default isa Expr)
            str = str * " = $default"
        end
    end
    return str
end

function get_arg_item_str(f::Tuple, show_arg_types, show_defaults)
    (arg_name, arg_type) = f
    str = "$arg_name"
    if string(arg_type) != "Any" && show_arg_types
        str = str * "::$arg_type"
    end
    return str
end

function build_struct_doc_string(mp::Expr, is_kwdef::Bool)
    structdef = MacroTools.splitstructdef(mp)
    if is_kwdef
        structdef[:fields] = filter(x->x isa Expr, mp.args[3].args)
    end
    str = """
    \"\"\"
        $(getstructstr(structdef))

    DOCSTRING
    """
    if !isempty(structdef[:fields])
        str = str * "\n# Fields:\n"
        str = str * join(map(structdef[:fields]) do f
            "- `" * get_arg_item_str(f, true, true) * "`: DESCRIPTION"
        end, "\n")
    end
    str = str * "\n\"\"\"\n"
end

function getstructstr(structdef)
    str = "$(structdef[:name])"
    if !isempty(structdef[:params])
        str = str * "{$(join(structdef[:params],", "))}"
    end
    return str
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

end # module

