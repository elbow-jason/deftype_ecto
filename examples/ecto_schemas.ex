defmodule Deftype.Examples.EctoPerson do
  use Deftype

  deftype do
    plugin(Deftype.EctoSchema, source: "ecto_persons")
    plugin(Deftype.EctoChangeset)
    attr(:fname, :string, required: true)
    attr(:lname, :string, required: true)
    attr(:age, :integer)
  end
end

# defmodule Deftype.Examples.EctoCompany do
#   use Deftype

#   deftype do
#     plugin(Deftype.Ecto.Schema, source: "companies")
#     attr(:name, :string, required: true)
#     attr(:owner, Deftype.Ecto.EctoPerson, belongs_to: Deftype.Ecto.EctoPerson)
#   end
# e
