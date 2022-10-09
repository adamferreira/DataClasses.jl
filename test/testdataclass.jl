using DataClasses
using Test

@testset "From Dict Basic" begin
    mutable struct TestDataClass <: AbstractDataClass
        field1::Int
        field2::Float64
        # Incomplete constructor pattern
        TestDataClass() = new(5, 3.14)
    end
    data = TestDataClass()
    @test data.field1 == 5
    @test data.field2 == 3.14
end

@testset "Quick Data Class" begin
    @dataclass TestQuickDataClass field1::Int field2::Float64
    data = DataClasses.from_dict(TestQuickDataClass, Dict("field1" => 5, "field2" => 3.14))
    @test data.field1 == 5
    @test data.field2 == 3.14
end

@testset "Data Class" begin
    @dataclass TestDataClass2 begin
        field1::Int
        field2::Float64
    end

    data = DataClasses.from_dict(TestDataClass2, Dict("field1" => 5, "field2" => 3.14))
    @test data.field1 == 5
    @test data.field2 == 3.14
end

@testset "Using convert from dict to Data Class" begin
    @dataclass TestDataClassConvert field1::Int field2::Float64
    data = convert(TestDataClassConvert, Dict("field1" => 5, "field2" => 3.14))
    @test data.field1 == 5
    @test data.field2 == 3.14
end

@testset "Nested DataClasses" begin
    @dataclass TestDataClassInner subfield1::Vector{Int64} subfield2::Tuple{Int, Int}
    @dataclass TestDataClassNested begin
        field1::Int
        field2::Float64
        field3::TestDataClassInner
    end

    d = Dict(
        "field1" => 5, 
        "field2" => 3.14,
        "field3" => Dict(
            "subfield1" => [1,2,3,4],
            "subfield2" => (1,2)
        )
    )

    data = DataClasses.from_dict(TestDataClassNested, d)
    @test data.field1 == 5
    @test data.field2 == 3.14
    @test data.field3.subfield1 == [1,2,3,4]
    @test data.field3.subfield2 == (1,2)
end

@testset "Test update from dict" begin
    @mutable_dataclass TestDataClass3 field1::Int field2::Float64
    data = convert(TestDataClass3, Dict("field1" => 5, "field2" => 3.14))
    @update data Dict("field2" => 1.618)
    @test data.field1 == 5
    @test data.field2 == 1.618
end

@testset "Test update from dict error" begin
    @mutable_dataclass TestDataClass4 field1::Int field2::Float64
    data = convert(TestDataClass4, Dict("field1" => 5, "field2" => 3.14))
    @test_throws(ErrorException, @update data Dict("field3" => 1.618))
    @test data.field1 == 5
    @test data.field2 == 3.14
end

@testset "Test update dict" begin
    @mutable_dataclass TestDataClass5 field1::Int field2::Float64
    data = TestDataClass5()
    data.field1 = 10
    data.field2 = 1.618
    d = Dict("field1" => 5, "field2" => 3.14, "field3" => "toto")
    @update d data
    @test d == Dict("field1" => 10, "field2" => 1.618, "field3" => "toto")
end

@testset "Test to_dict" begin
    @mutable_dataclass TestDataClassToDict field1::Int field2::Float64 field3::String
    data = TestDataClassToDict()
    data.field1 = 10
    data.field2 = 1.618
    data.field3 = "toto"
    @test to_dict(data) == Dict("field1" => 10, "field2" => 1.618, "field3" => "toto")
end

@testset "Test convert to dict" begin
    @mutable_dataclass TestDataClassToDict2 field1::Int field2::Float64 field3::String
    data = TestDataClassToDict2()
    data.field1 = 10
    data.field2 = 1.618
    data.field3 = "toto"
    @test convert(Dict, data) == Dict("field1" => 10, "field2" => 1.618, "field3" => "toto")
end