using DataClasses

mutable struct TestDataClass <: DataClasses.AbstractDataClass
    field1::Int
    field2
end

DataClasses.from_dict(TestDataClass, Dict("field1" => 5))