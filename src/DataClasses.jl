module DataClasses

export AbstractDataClass

abstract type AbstractDataClass end

function from_dict(type::Type{T}, d::Dict) where T <: AbstractDataClass
    for (attrname, attrtype) in zip(fieldnames(type), fieldtypes(type))
        println((attrname, attrtype))
    end
end

end