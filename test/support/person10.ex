defmodule Deftype.EctoTesting.Person10 do
  use Deftype

  alias Deftype.EctoTesting.Pet6

  # ecto type
  alias Deftype.EctoTesting.Person9

  deftype do
    plugin(Deftype.EctoEmbeddedSchema)
    plugin(Deftype.EctoChangeset)
    attr(:pets, {:list, Pet6})
    attr(:person9s, {:list, Person9}, required: true)
    attr(:lname, :string, required: true)
    attr(:age, :integer)
    attr(:boots, :boolean, permitted: false)
  end
end
