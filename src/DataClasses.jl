module DataClasses

abstract type AbstractDataClass end

function from_dict(T::Type, d::Dict)
    println(T)
end

end