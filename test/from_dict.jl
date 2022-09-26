using DataClasses
using Test

@testset "From Dict Basic" begin
    mutable struct TestDataClass <: AbstractDataClass
        field1::Int
        field2::Float64
    
        # Incomplete constructor pattern
        TestDataClass() = new()
    end

    data = DataClasses.from_dict(TestDataClass, Dict("field1" => 5, "field2" => 3.14))
    @test data.field1 == 5
    @test data.field2 == 3.14
end

@testset "Quick Data Class" begin
    @quickdataclass TestDataClass field1::Int field2::Float64
    data = DataClasses.from_dict(TestDataClass, Dict("field1" => 5, "field2" => 3.14))
    @test data.field1 == 5
    @test data.field2 == 3.14
end

@testset "Data Class" begin
    @dataclass TestDataClass begin
        field1::Int
        field2::Float64
    end

    data = DataClasses.from_dict(TestDataClass, Dict("field1" => 5, "field2" => 3.14))
    @test data.field1 == 5
    @test data.field2 == 3.14
end

@testset "Using convert from dict to Data Class" begin
    @quickdataclass TestDataClass field1::Int field2::Float64
    data = convert(TestDataClass, Dict("field1" => 5, "field2" => 3.14))
    @test data.field1 == 5
    @test data.field2 == 3.14
end

@testset "From Dict Default fiels" begin
    mutable struct TestDataClassDefault <: AbstractDataClass
        field1::Int
        field2::Float64
        field3::String
        TestDataClassDefault() = new(0, 3.14, "")
    end

    data = DataClasses.from_dict(TestDataClassDefault, Dict("field1" => 5, "field3" => "toto"))
    @test data.field1 == 5
    @test data.field2 == 3.14
    @test data.field3 == "toto"
end

@testset "Nested DataClasses" begin
    mutable struct TestDataClassInner <: AbstractDataClass
        subfield1::Vector{Int64}
        subfield2::Tuple{Int, Int}
        TestDataClassInner() = new()
    end
    mutable struct TestDataClassNested <: AbstractDataClass
        field1::Int
        field2::Float64
        field3::TestDataClassInner
        TestDataClassNested() = new()
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

@testset "Nested DataClasses from macro" begin
    @quickdataclass TestDataClassInner subfield1::Vector{Int64} subfield2::Tuple{Int, Int}
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