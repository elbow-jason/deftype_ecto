defmodule Deftype.EctoTesting.Pet7 do
  use Deftype

  alias Deftype.EctoTesting.Person7

  deftype do
    plugin(Deftype.EctoSchema, source: "pet7s")
    attr(:owner, Person7, belongs_to: Person7)
    attr(:lname, :string, required: true)
    attr(:age, :integer)
    attr(:boots, :boolean, permitted: false)
  end
end
