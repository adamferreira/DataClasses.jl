module DataClasses
import Base

abstract type AbstractDataClass end

# Default values for primitive type is Base.zero
default(::Type{T}) where T <: Union{Number, AbstractString} = Base.zero(T)
# Strings
default(::Type{String}) = ""
# Special case of tuples
default(::Type{T}) where T <: Tuple{Vararg} = Tuple(default.(T.parameters))
# Default values for structures is the default constructor of the type
default(::Type{T}) where T = T()

# Macro to define an AbstractDataClass subtype with a single line
# The type is made mutable if ismutable is 'true'
macro __dataclass(T, ismutable, stmts...)
    # Filter declarations, Expr of form <Var>::<Type>
    local decls = [stmt for stmt in stmts if (isa(stmt, Expr) && stmt.head == Symbol("::"))]
    # Create the Expr '<Var>::<Type> = default(<Type>)' that can be read by Base.@kwdef
    # And will create the kwargs constructor <T>(; <Var>::<Type> = default(<Type>))
    # The trick here is that we call default(<Type>) as default value for <Type>
    # Thus default(<Type>) should be defined
    local default_decls = [:($(decl) = DataClasses.default($(decl.args[2]))) for decl in decls]
    local block = quote
        # Struct definition
        struct $(T) <: DataClasses.AbstractDataClass
            # Struct parameters (Base.@kwdef style : '<Var>::<Type> = default_value')
            $(default_decls...)
        end
    end 
    # block.args[2] is the struct definition expression node
    # block.args[2].args[1] is the boolean telling if the struct is mutable or not
    block.args[2].args[1] = ismutable

    # Using Base.@kwdef to create kwargs constructor
    return :(Base.@kwdef $(block.args[2])) |> esc
end

# Macro to define an AbstractDataClass subtype with a single line
macro dataclass(T, stmts...)
    # Equivalent to quote @__dataclass $(T) false $(stmts...) end |> esc
    return :(@__dataclass $(T) false $(stmts...)) |> esc
end

# Macro to define an AbstractDataClass subtype with a block
macro dataclass(T, block)
    # Make sure the macro is given a block as input
    @assert block.head == :block
    return :(@__dataclass $(T) false $(block.args...)) |> esc
end

# Macro to define a mutable AbstractDataClass subtype with a single line
macro mutable_dataclass(T, stmts...)
    return :(@__dataclass $(T) true $(stmts...)) |> esc
end

# Macro to define a mutable AbstractDataClass subtype with a block
macro mutable_dataclass(T, block)
    # Make sure the macro is given a block as input
    @assert block.head == :block
    return :(@__dataclass $(T) true $(block.args...)) |> esc
end

# Updates the fiels of the AbstractDataClass 'dc'
# With the given Dict 'd'
# Any key of 'd' that is not a field of 'dc' will raise and error
function update!(dc::AbstractDataClass, d::Dict)
    for (attrname, attrval) in d
        if hasfield(typeof(dc), Symbol(attrname))
            field = getfield(dc, Symbol(attrname))
            setfield!(dc, Symbol(attrname), convert(typeof(field), attrval))
        else
            # TODO have specific exeption types ?
            error("Cannot update field $attrname of type $(typeof(dc))")
        end
    end
end

# Updates the elements of the given Dict 'd'
# with the fields names and values of the AbstractDataClass 'dc'
# If the field of 'dc' is not present in 'd' it will be created
function update!(d::Dict, dc::AbstractDataClass)
    for (attr::Symbol, attrtype::DataType) in zip(fieldnames(typeof(dc)), fieldtypes(typeof(dc)))
        d[String(attr)] = getfield(dc, attr)
    end
end


# Equivalent to :(update!($(esc(a)), $(esc(b))))
macro update(a, b)
    return Expr(
        :call, :update!, esc(a), esc(b)
    )
end


# Construct an AbstractDataClass object of type 'T' with the given Dict 'd'
function from_dict(type::Type{T}, d::Dict)::T where T <: AbstractDataClass
    # Usage:
    # dict = Dict(:a => 1, :b => 5, :c => 6)
    # u = (; dict...) -----> (a = 1, b = 5, c = 6)
    # typeof(u) -> NamedTuple{(:a, :b, :c), Tuple{Int64, Int64, Int64}}
    kwargs = Dict(Symbol(k) => v for (k,v) in d)
    # This implemention of from_dict should work even if T is immutable
    return T(; kwargs...)
end

# Construct a Dict 'd' with the given AbstractDataClass object of type 'T'
function to_dict(dc::AbstractDataClass)::Dict
    # Create an empty dict and update it
    d = Dict()
    @update d dc
    return d
end

# Cast overload
Base.convert(::Type{T}, x::Dict) where T <: AbstractDataClass = from_dict(T, x)
Base.convert(::Type{Dict}, x::T) where T <: AbstractDataClass = to_dict(x)
# Default constructor from dict
# TODO : implement and test
#(::Type{T})(x::Dict) where T <: AbstractDataClass = from_dict(T, x)

export AbstractDataClass, default
export @__dataclass, @dataclass, @mutable_dataclass, @update
export from_dict, update!, to_dict

end