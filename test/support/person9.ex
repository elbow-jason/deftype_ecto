
  defmodule Deftype.EctoTesting.Person9 do
    @moduledoc """
    A recursive type...
    """

    alias Deftype.EctoTesting.Person9

    use Deftype

    deftype do
      plugin(Deftype.Defstruct)
      plugin(Deftype.EctoChangeset)
      plugin(Deftype.EctoType)
      attr(:knows, Person9)
      attr(:id, :id)
      attr(:name, :string, required: true)
    end
  end
