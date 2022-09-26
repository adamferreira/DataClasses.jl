module DataClasses
import Base

abstract type AbstractDataClass end

# Macro to define an AbstractDataClass subtype with a single line
macro quickdataclass(T, stmts...)
    # Only support attribute declaration expression in quickdataclass macro
    for stmt in stmts
        @assert isa(stmt, Expr)
        @assert stmt.head == Symbol("::")
    end
    # Escapes declaration so field::type does not become
    # field::DataClasses.<type> at macro resolution
    clean_statements = [esc(stmt) for stmt in stmts]
    return quote
        mutable struct $(esc(T)) <: AbstractDataClass
            # Struct parameters
            $(clean_statements...)
            # Incomplete constructor pattern
            $(T)() = new()
        end
    end
end

# Macro to define an AbstractDataClass subtype with a block
macro dataclass(T, block)
    # Make sure the macro is given a block as input
    @assert block.head == :block
    # Escapes block content as it should not be resolved as belonging to DataClasses module
    # Otherwise every user types in the block will becone DataClasses.<type>
    clean_statements = [esc(stmt) for stmt in block.args]
    return quote
        mutable struct $(esc(T)) <: AbstractDataClass
            # Block content
            $(clean_statements...)
            # Incomplete constructor pattern
            $(T)() = new()
        end
    end
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

macro update(a, b)
    return :(update!($(esc(a)),$(esc(b))))
end

# Construct an AbstractDataClass object of type 'T' with the given Dict 'd'
function from_dict(type::Type{T}, d::Dict)::T where T <: AbstractDataClass
    # First create an instance of type T
    # TODO : Error if T ahas no empty constructor
    dataclass::T = T()
    for (attr::Symbol, attrtype::DataType) in zip(fieldnames(type), fieldtypes(type))
        if haskey(d, String(attr))
            setfield!(dataclass, attr, Base.convert(attrtype, d[String(attr)]))
        end
        # TODO : raise when symbol is not in dict
    end
    return dataclass
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

export AbstractDataClass
export @dataclass, @quickdataclass, @update
export from_dict, update!, to_dict

end