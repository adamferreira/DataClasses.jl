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

function from_dict(type::Type{T}, d::Dict) where T <: AbstractDataClass
    # First create an instance of type T
    # TODO : Error if T ahas no empty constructor
    dataclass::T = T()
    for (attr::Symbol, attrtype::DataType) in zip(fieldnames(type), fieldtypes(type))
        if haskey(d, String(attr))
            setfield!(dataclass, attr, Base.convert(attrtype, d[String(attr)]))
        end
    end
    #setfield!(dataclass, Symbol(attrname), convert(symbols[Symbol(attrname)], attrval))
    return dataclass
end


# Cast overload
Base.convert(::Type{T}, x::Dict) where T <: AbstractDataClass = from_dict(T, x)

export AbstractDataClass
export @dataclass, @quickdataclass
export from_dict

end