using DataClasses
using Test


@testset "Test simple from_dict" begin
    @dataclass TestDataClass field1::Int field2::Float64 field3::Bool
    data = DataClasses.from_dict(TestDataClass, Dict("field1" => 5, "field2" => 3.14))
    @test data.field1 == 5
    @test data.field2 == 3.14
    @test data.field3 == false
end

@testset "Test simple from_dict wrong fields" begin
    @test_throws MethodError data = DataClasses.from_dict(TestDataClass, Dict("field1" => 5, "field4" => 3.14))
end

@testset "Using convert from dict to Data Class" begin
    data = convert(TestDataClass, Dict("field1" => 5, "field2" => 3.14))
    @test data.field1 == 5
    @test data.field2 == 3.14
    @test data.field3 == false
end

@testset "Nested Dict" begin
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
    @mutable_dataclass MutableTestDataClass field1::Int field2::Float64 field3::Bool
    data = convert(MutableTestDataClass, Dict("field1" => 5, "field2" => 3.14))

    update!(data, Dict("field2" => 1.618))
    @test data.field1 == 5
    @test data.field2 == 1.618
    @test data.field3 == false
end

@testset "Test update from dict with operator" begin
    @mutable_dataclass MutableTestDataClass field1::Int field2::Float64 field3::Bool
    data = convert(MutableTestDataClass, Dict("field1" => 5, "field2" => 3.14))

    data ← Dict("field2" => 1.618)
    @test data.field1 == 5
    @test data.field2 == 1.618
    @test data.field3 == false

    data ← Dict("field1" => 100, "field3" => true)
    @test data.field1 == 100
    @test data.field2 == 1.618
    @test data.field3 == true
end

@testset "Test update from Iterable" begin
    @mutable_dataclass MutableTestDataClass field1::Int field2::Float64 field3::Bool
    data = convert(MutableTestDataClass, Dict("field1" => 5, "field2" => 3.14))

    # Tuple
    data ← (100, 1.618)
    @test data.field1 == 100
    @test data.field2 == 1.618
    @test data.field3 == false

    # Vector
    data ← (5, 3.14, true)
    @test data.field1 == 5
    @test data.field2 == 3.14
    @test data.field3 == true
end

@testset "Test update from Iterable error" begin
    @mutable_dataclass MutableTestDataClass field1::Int field2::Float64 field3::Bool
    data = convert(MutableTestDataClass, Dict("field1" => 5, "field2" => 3.14))

    @test_throws UndefVarError data ← (100, 1.618, true, true)

end

@testset "Test update dict" begin
    @mutable_dataclass MutableTestDataClass2 field1::Int field2::Float64
    data = MutableTestDataClass2()
    data.field1 = 10
    data.field2 = 1.618
    d = Dict("field1" => 5, "field2" => 3.14, "field3" => "toto")
    d ← data
    @test d == Dict("field1" => 10, "field2" => 1.618, "field3" => "toto")
end

@testset "Test update dict with new parameters" begin
    data = MutableTestDataClass2()
    data.field1 = 10
    data.field2 = 1.618
    d = Dict{Any, Any}("field3" => "toto")
    d ← data
    @test d == Dict("field1" => 10, "field2" => 1.618, "field3" => "toto")
end

@testset "Test update dict with new parameters, errors" begin
    data = MutableTestDataClass2()
    data.field1 = 10
    data.field2 = 1.618
    # Cannot convert field1::Int64 to String
    d = Dict{String, String}("field3" => "toto")
    @test_throws MethodError d ← data
    # Same error
    d2 = Dict("field3" => "toto")
    @test_throws MethodError d ← data
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