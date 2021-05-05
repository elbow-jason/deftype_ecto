defmodule Deftype.EctoTesting.PersonPkFalse do
  use Deftype

  deftype do
    plugin(Deftype.EctoEmbeddedSchema, primary_key: false)
    attr(:age, :integer)
  end
end

defmodule Deftype.EctoTesting.PersonPkSpecified do
  use Deftype

  deftype do
    plugin(Deftype.EctoEmbeddedSchema, primary_key: {:id, :binary_id, []})
    attr(:age, :integer)
  end
end

defmodule Deftype.EctoTesting.PersonPkNotSpecified do
  use Deftype

  deftype do
    plugin(Deftype.EctoEmbeddedSchema)
    attr(:age, :integer)
  end
end
