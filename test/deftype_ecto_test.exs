defmodule DeftypeEctoTest do
  use ExUnit.Case
  doctest Deftype.EctoSchema
  doctest Deftype.EctoChangeset

  defmodule Person do
    use Deftype

    deftype do
      plugin(Deftype.EctoSchema, source: "ecto_persons")

      attr(:fname, :string, required: true)
      attr(:lname, :string, required: true)
      attr(:age, :integer)
    end
  end

  test "using EctoSchema as a plugin defines a schema" do
    assert function_exported?(Person, :__schema__, 1) == true
    assert function_exported?(Person, :__schema__, 2) == true
    assert %Person{}.__meta__ == %Ecto.Schema.Metadata{
      context: nil,
      prefix: nil,
      schema: Person,
      source: "ecto_persons",
      state: :built
    }
  end

  defmodule Person2 do
    use Deftype

    deftype do
      plugin(Deftype.EctoChangeset)
      attr(:fname, :string, required: true)
      attr(:lname, :string, required: true)
      attr(:age, :integer)
      attr(:boots, :boolean, permitted: false)
    end
  end

  describe "using EctoChangeset as a plugin without EctoSchema" do
    test "defines changeset/1 and changeset/2" do
      assert function_exported?(Person2, :changeset, 1) == true
      assert function_exported?(Person2, :changeset, 2) == true
    end

    test "does not define __schema__/1 nor __schema__/2" do
      assert function_exported?(Person2, :__schema__, 1) == false
      assert function_exported?(Person2, :__schema__, 2) == false
    end

    test "`required: true` in the attr's meta work for changeset/1" do
      cs = Person2.changeset(%{})
      assert cs.valid? == false
      assert cs.errors == [
        fname: {"can't be blank", [{:validation, :required}]},
        lname: {"can't be blank", [{:validation, :required}]}
      ]
    end

    test "`required: true` in the attr's meta work for changeset/2" do
      data = %{fname: "jason"}
      cs = Person2.changeset(data, %{})
      assert cs.valid? == false
      assert cs.errors == [lname: {"can't be blank", [{:validation, :required}]}]
    end

    test "`permitted: false` attrs are not in the changes" do
      cs1 = Person2.changeset(%{fname: "m", lname: "h", age: 99, boots: true})
      assert cs1.valid? == true
      assert cs1.errors == []
      assert cs1.changes == %{
        fname: "m",
        lname: "h",
        age: 99
      }
    end
  end

  defmodule Person3 do
    use Deftype

    deftype do
      plugin(Deftype.EctoSchema, source: "person3s")
      plugin(Deftype.EctoChangeset)
      attr(:fname, :string, required: true)
      attr(:lname, :string, required: true)
      attr(:age, :integer)
      attr(:boots, :boolean, permitted: false)
    end
  end

  describe "using EctoChangeset as a plugin with EctoSchema" do
    test "defines changeset/1 and changeset/2" do
      assert function_exported?(Person3, :changeset, 1) == true
      assert function_exported?(Person3, :changeset, 2) == true
    end

    test "defines __schema__/1 and __schema__/2" do
      assert function_exported?(Person3, :__schema__, 1) == true
      assert function_exported?(Person3, :__schema__, 2) == true
    end

    test "works" do
      cs1 = Person3.changeset(%Person3{}, %{fname: "m", lname: "h", age: 99, boots: true})
      assert cs1.valid? == true
      assert cs1.errors == []
      assert cs1.changes == %{
        fname: "m",
        lname: "h",
        age: 99
      }
    end
  end

  defmodule Person4 do
    use Deftype

    deftype do
      plugin(Deftype.Defstruct)
      plugin(Deftype.EctoChangeset, source: "person4s")
      attr(:fname, :string, required: true)
      attr(:lname, :string, required: true)
      attr(:age, :integer)
      attr(:boots, :boolean, permitted: false)
    end
  end

  describe "using EctoChangeset as a plugin with Defstruct" do
    test "works" do
      cs1 = Person4.changeset(%Person4{}, %{fname: "m", lname: "h", age: 99, boots: true, other: :thing})
      assert cs1.valid? == true
      assert cs1.errors == []
      assert cs1.changes == %{
        fname: "m",
        lname: "h",
        age: 99
      }
    end
  end

  defmodule Person5 do
    use Deftype

    deftype do
      plugin(Deftype.EctoChangeset, source: "person5s")
      plugin(Deftype.Defstruct)
      attr(:fname, :string, required: true)
      attr(:lname, :string, required: true)
      attr(:age, :integer)
      attr(:boots, :boolean, permitted: false)
    end
  end

  describe "using EctoChangeset as a plugin with Defstruct (in reverse order)" do
    test "works" do
      cs1 = Person5.changeset(%Person5{}, %{fname: "m", lname: "h", age: 99, boots: true, other: :thing})
      assert cs1.valid? == true
      assert cs1.errors == []
      assert cs1.changes == %{
        fname: "m",
        lname: "h",
        age: 99
      }
    end
  end

  alias Deftype.EctoTesting.Person6
  # alias Deftype.EctoTesting.Pet6

  describe "using :belongs_to + :has_many with EctoSchema" do
    test "works" do
      cs = Person6.changeset(%Person6{}, %{})
      assert cs.valid? == false
      assert cs.errors == [
        {:lname, {"can't be blank", [validation: :required]}}
      ]
    end
  end

  alias Deftype.EctoTesting.Person7
  # alias Deftype.EctoTesting.Pet7

  describe "using :belongs_to + :has_one with EctoSchema" do
    test "works" do
      cs = Person7.changeset(%Person7{}, %{})
      assert cs.valid? == false
      assert cs.errors == [
        {:lname, {"can't be blank", [validation: :required]}}
      ]
    end
  end
end
