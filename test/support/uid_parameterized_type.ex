defmodule Deftype.EctoTesting.UidParameterizedType do
  @moduledoc """
  A composite string of a 4 lowercase letter `namespace` and `number`.
  """
  use Deftype
  alias Deftype.EctoTesting.UidParameterizedType, as: Uid

  deftype do
    plugin(Deftype.Defstruct)
    plugin(Deftype.EctoChangeset)
    plugin(Deftype.EctoParameterizedType, ecto_type: :string)
    attr(:namespace, :string, required: true)
    attr(:number, :string, required: true)
  end

  def init(cfg) do
    namespaces =
      Keyword.get_lazy(cfg, :namespaces, fn ->
        raise """
        Uid requires a :namespaces key in it's configuration.

        got config: #{inspect(cfg)}
        """
      end)

    %{namespaces: namespaces}
  end

  def cast(<<ns::size(4)-binary, "::", number::binary>>, cfg) do
    cast(%{namespace: ns, number: number}, cfg)
  end

  def cast(%{namespace: ns, number: number}, %{namespaces: namespaces}) do
    cond do
      !Enum.member?(namespaces, ns) ->
        {:error, [namespace: "is invalid", allowed: namespaces]}

      !match?({_, ""}, Integer.parse(number)) ->
        {:error, [number: "is invalid"]}

      true ->
        {:ok, %Uid{namespace: ns, number: number}}
    end
  end

  def to_string(%Uid{namespace: ns, number: number}) do
    ns <> "::" <> number
  end

  def dump(%Uid{} = uid, _, cfg) do
    case cast(uid, cfg) do
      {:ok, _} -> Uid.to_string(uid)
      err -> err
    end
  end

  def load(str, _, cfg) when is_binary(str) do
    cast(str, cfg)
  end
end

defmodule Deftype.EctoTesting.PersonWithUid do
  use Deftype

  alias Deftype.EctoTesting.UidParameterizedType, as: Uid
  alias Deftype.EctoTesting.PersonWithUid

  deftype do
    plugin(Deftype.EctoSchema, source: "person_with_uid")
    plugin(Deftype.EctoChangeset)
    attr(:uid, Uid, required: true, namespaces: ["abcd", "efgh"])
  end

  def demo_invalid do
    PersonWithUid.changeset(%{uid: "blep::123"})
  end

  def demo_valid do
    PersonWithUid.changeset(%{uid: "abcd::123"})
  end
end
