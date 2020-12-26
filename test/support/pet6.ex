defmodule Deftype.EctoTesting.Pet6 do
  use Deftype

  alias Deftype.EctoTesting.Person6

  deftype do
    plugin(Deftype.EctoSchema, source: "pet6s")
    attr(:owner, Person6, belongs_to: Person6)
    attr(:lname, :string, required: true)
    attr(:age, :integer)
    attr(:boots, :boolean, permitted: false)
  end
end
