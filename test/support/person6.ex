defmodule Deftype.EctoTesting.Person6 do
  use Deftype

  alias Deftype.EctoTesting.Pet6

  deftype do
    plugin(Deftype.EctoSchema, source: "person6s")
    plugin(Deftype.EctoChangeset)
    attr(:pets, {:list, Pet6}, has_many: Pet6, foreign_key: :owner_id)
    attr(:lname, :string, required: true)
    attr(:age, :integer)
    attr(:boots, :boolean, permitted: false)
  end
end
