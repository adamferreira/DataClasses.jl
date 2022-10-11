using DataClasses
using Test

@testset "Test default primitive types" begin
    @dataclass DefaultPrimitiveType field1::Int field2::Float64 field3::Bool
    data = DataClasses.default(DefaultPrimitiveType)
    @test data.field1 == Base.zero(typeof(data.field1))
    @test data.field2 == Base.zero(typeof(data.field2))
end


@testset "Test default primitive types 2" begin
    @dataclass DefaultPrimitiveType2 field1::Float16 field2::Float64
    data = DataClasses.default(DefaultPrimitiveType2)
    for (attr::Symbol, attrtype::DataType) in zip(fieldnames(typeof(data)), fieldtypes(typeof(data)))
        @test getfield(data, attr) == Base.zero(attrtype)
    end
end

@testset "Test default basic types" begin
    @dataclass DefaultBasicType field1::Vector{Float32} field2::Dict{String, Int}
    data = DataClasses.default(DefaultBasicType)
    for (attr::Symbol, attrtype::DataType) in zip(fieldnames(typeof(data)), fieldtypes(typeof(data)))
        @test getfield(data, attr) == attrtype()
    end
end

@testset "Test default advanced types" begin
    @dataclass DefaultAdvancedType field1::Tuple{Tuple{Int, String}, Vector{Float64}, Int, String} field2::Tuple{Number}
    data = DataClasses.default(DefaultAdvancedType)
    for (attr::Symbol, attrtype::DataType) in zip(fieldnames(typeof(data)), fieldtypes(typeof(data)))
        @test getfield(data, attr) == DataClasses.default(attrtype)
    end
end

@testset "Test default mixed types" begin
    @dataclass DefaultMixedType begin
        field1::Int 
        field2::Float64
        field3::Vector{Float32} 
        field4::Dict{String, Int}
        field5::Tuple{Tuple{Int, String}, Vector{Float64}, Int, String} 
        field6::Tuple{Number}
    end
    data = DataClasses.default(DefaultMixedType)
    for (attr::Symbol, attrtype::DataType) in zip(fieldnames(typeof(data)), fieldtypes(typeof(data)))
        @test getfield(data, attr) == DataClasses.default(attrtype)
    end
end

@testset "Test default composed types" begin
    @dataclass DefaultComposedType begin
        field1::DefaultPrimitiveType
        field2::DefaultPrimitiveType2
    end
    data = DataClasses.default(DefaultComposedType)
    for (attr::Symbol, attrtype::DataType) in zip(fieldnames(typeof(data)), fieldtypes(typeof(data)))
        @test getfield(data, attr) === DataClasses.default(attrtype)
    end
end

@testset "Test default constructor" begin
    data = DefaultPrimitiveType()
    data2 = DataClasses.default(DefaultPrimitiveType)
    @test data === data2
    @test DataClasses.default(DefaultPrimitiveType) == DefaultPrimitiveType()
end

@testset "Test partial initialization" begin
    data = DefaultPrimitiveType()
    @test data.field1 == 0
    @test data.field2 == 0.0
    @test data.field3 == false
    data = DefaultPrimitiveType(field3 = true, field1 = 100)
    @test data.field1 == 100
    @test data.field2 == 0.0
    @test data.field3 == true
end

@testset "Test default overload" begin
    DataClasses.default(::Type{DefaultPrimitiveType}) = DefaultPrimitiveType(field3 = true, field1 = 100)
    data = DataClasses.default(DefaultPrimitiveType)
    @test data.field1 == 100
    @test data.field2 == 0.0
    @test data.field3 == true
end

@testset "Test default overload 2" begin
    DataClasses.default(::Type{DefaultPrimitiveType}) = DefaultPrimitiveType(field3 = true, field1 = 100)
    DataClasses.default(::Type{DefaultPrimitiveType2}) = DefaultPrimitiveType2(field2 = 3.14)
    data = DataClasses.default(DefaultComposedType)

    @test data.field1.field1 == 100
    @test data.field1.field2 == 0.0
    @test data.field1.field3 == true

    @test data.field2.field1 == 0.0
    @test data.field2.field2 == 3.14
end
