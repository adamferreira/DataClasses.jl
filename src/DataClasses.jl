module DataClasses
import Base

abstract type AbstractDataClass end

# TODO : Make user choose if he wants structs to be mutable
# help : e = Meta.parse("mutable struct TestDataClass <: AbstractDataClass TestDataClass() = new() end")
# dump(e)


# Macro to define an AbstractDataClass subtype with a single line
macro quickdataclass(T, stmts...)
    # Only support attribute declaration expression in quickdataclass macro
    for stmt in stmts
        @assert isa(stmt, Expr)
    end
    local kwargs = [stmt for stmt in stmts if (isa(stmt, Expr) && stmt.head == Symbol("="))]
    # Escapes declaration so field::type does not become
    # field::DataClasses.<type> at macro resolution
    local decls = [esc(stmt) for stmt in stmts if (isa(stmt, Expr) && stmt.head == Symbol("="))]
    return quote
        mutable struct $(esc(T)) <: AbstractDataClass
            # Struct parameters
            $(decls...)
            # Incomplete constructor pattern
            $(T)() = new()
        end
    end
end

# Macro to define an AbstractDataClass subtype with a block
macro dataclass(T, block)
    # Make sure the macro is given a block as input
    @assert block.head == :block
    # Filter declarations
    #local decls = [stmt for stmt in block.args if (isa(stmt, Expr) && stmt.head == Symbol("::"))]
    # Escapes block content as it should not be resolved as belonging to DataClasses module
    # Otherwise every user types in the block will becone DataClasses.<type>
    local clean_statements = [esc(stmt) for stmt in block.args]
    return quote
        mutable struct $(esc(T)) <: AbstractDataClass
            # Block content
            $(clean_statements...)
            # Incomplete constructor pattern
            $(T)() = new()
        end
    end
end


#magicdataclass Dict("class" => "MyDataClass","fields" => Dict("field1" => 10, "field2" => 1.618, "field3" => "toto"))
# Macro to create an AbstractDataClass Structure definition from a Dict
macro magicdataclass(d)
    # Evaluate the dict and check it
    local dval = eval(:($(d)))
    @assert isa(dval, Dict{String, Any})
    @assert haskey(dval, "class")
    @assert isa(dval["class"], String)
    @assert haskey(dval, "fields")
    @assert isa(dval["fields"], Dict)
    # Define the new DataClass type and create it
    # List of Expr reprensting declaration of fields
    local decls = [:($(field)::$(typeof(value))) for (field, value) in dval["fields"]]
    #@quickdataclass(Symbol(dval["class"]), decls)
    return :(from_dict($(esc(Symbol(dval["class"]))), $(dval["fields"])))
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


# Equavalent to :(update!($(esc(a)), $(esc(b))))
macro update(a, b)
    return Expr(
        :call, :update!, esc(a), esc(b)
    )
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
export @dataclass, @quickdataclass, @update, @mytest
export from_dict, update!, to_dict

end