using DataClasses
using Test

@testset "DataClass Type" begin
    @dataclass TestDataClass field1::Int field2::Float64 field3::Bool
    data = TestDataClass()
    @test isa(data, AbstractDataClass)
end

@testset "DataClass Type" begin
    @dataclass TestDataClass2 begin 
        field1::Int 
        field2::Float64 
        field3::Bool
    end
    data = TestDataClass2()
    @test isa(data, AbstractDataClass)
end