
defmodule Deftype.EctoChangeset do
  alias Deftype.Attr
  alias Ecto.Changeset

  @behaviour Deftype.Plugin

  def call(cfg, _plugins, _type_metas, attrs) do
    quote do
      use Ecto.Schema

      alias Deftype.EctoChangeset

      cfg = unquote(cfg)
      attrs = unquote(attrs)

      @permitted Keyword.get_lazy(cfg, :permitted, fn ->
        EctoChangeset.permitted_fields_from_attrs(attrs)
      end)

      @required Keyword.get_lazy(cfg, :required, fn ->
        EctoChangeset.required_fields_from_attrs(attrs)
      end)

      @typemap EctoChangeset.typemap_from_attrs(attrs)

      if !Module.defines?(__MODULE__, {:__changeset__, 0}, :def) do
        def __changeset__, do: @typemap
      end

      try do
        @doc """
        Basic permitted and required validations for the given struct.

        - permitted: `#{inspect(@permitted)}`

        - required: `#{inspect(@required)}`

        - types: `#{inspect(@typemap, pretty: true)}`
        """
        def changeset(%__MODULE__{} = data \\ %__MODULE__{}, params) do
          EctoChangeset.changeset({data, @typemap}, params, @permitted, @required)
        end

      rescue CompileError ->
        @doc """
        Basic permitted and required validations for the defined type.

        - permitted: `#{inspect(@permitted)}`

        - required: `#{inspect(@required)}`

        - types: `#{inspect(@typemap, pretty: true)}`
        """

        def changeset(data \\ %{}, params) do
          EctoChangeset.changeset({data, @typemap}, params, @permitted, @required)
        end

      end
    end
  end

  @doc false
  def changeset(data, params, permitted, required) do
    data
    |> Changeset.cast(params, permitted)
    |> Changeset.validate_required(required)
  end

  @doc false
  def permitted_fields_from_attrs(attrs) do
    attrs
    |> Enum.filter(fn attr ->
      attr
      |> Attr.meta()
      |> Keyword.get(:permitted, true)
      |> Kernel.==(true)
    end)
    |> Enum.map(&Attr.key/1)
  end

  @doc false
  def required_fields_from_attrs(attrs) do
    attrs
    |> Enum.filter(fn attr ->
      attr
      |> Attr.meta()
      |> Keyword.get(:required, false)
      |> Kernel.==(true)
    end)
    |> Enum.map(&Attr.key/1)
  end

  @doc false
  def typemap_from_attrs(attrs) do
    Map.new(attrs, fn attr -> {Attr.key(attr), Attr.type(attr)} end)
  end
end
