defmodule Deftype.EctoTesting.Person7 do
  use Deftype

  alias Deftype.EctoTesting.Pet7

  deftype do
    plugin(Deftype.EctoSchema, source: "person7s")
    plugin(Deftype.EctoChangeset)
    attr(:pets, Pet7, has_one: Pet7, foreign_key: :owner_id)
    attr(:lname, :string, required: true)
    attr(:age, :integer)
    attr(:boots, :boolean, permitted: false)
  end
end
