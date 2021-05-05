defmodule Deftype.EctoChangeset do
  alias Deftype.Attr
  alias Ecto.Changeset

  @behaviour Deftype.Plugin

  def call(cfg, _plugins, _type_metas, attrs) do
    cfg = Macro.escape(cfg)
    attrs = Macro.escape(attrs)

    quote do
      use Ecto.Schema

      @__deftype_ecto_changeset_cfg unquote(cfg)
      @__deftype_ecto_changeset_attrs unquote(attrs)

      @before_compile Deftype.EctoChangeset
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      alias Deftype.EctoChangeset

      cfg =
        Module.get_attribute(__MODULE__, :__deftype_ecto_changeset_cfg) ||
          raise("no ecto changeset config")

      attrs =
        Module.get_attribute(__MODULE__, :__deftype_ecto_changeset_attrs) ||
          raise("no ecto changeset attr")

      @permitted Keyword.get_lazy(cfg, :permitted, fn ->
                   EctoChangeset.permitted_fields_from_attrs(attrs)
                 end)

      @required Keyword.get_lazy(cfg, :required, fn ->
                  EctoChangeset.required_fields_from_attrs(attrs)
                end)

      @typemap EctoChangeset.typemap_from_attrs(attrs)

      if Module.defines?(__MODULE__, {:__schema__, 2}, :def) do
        @doc false
        def typemap do
          fields = __MODULE__.__schema__(:fields)

          fields
          |> Enum.flat_map(fn f ->
            case __MODULE__.__schema__(:type, f) do
              t when is_atom(t) ->
                [{f, t}]

              {:array, _} = t ->
                [{f, t}]

              {:parameterized, Ecto.Embedded, emb} ->
                []
            end
          end)
          |> Map.new()
        end

        @doc false
        def permitted do
          Enum.filter(@permitted, fn f ->
            EctoChangeset.schema_field_is_permitted?(__MODULE__, f)
          end)
        end

        @doc false
        def required, do: @required
      else
        @doc false
        def typemap, do: @typemap

        @doc false
        def permitted, do: @permitted

        @doc false
        def required, do: @required
      end

      if !Module.defines?(__MODULE__, {:__changeset__, 0}, :def) do
        def __changeset__, do: typemap()
      end

      try do
        @doc """
        Basic permitted and required validations for the given struct.
        """
        def changeset(%__MODULE__{} = data \\ %__MODULE__{}, params) do
          EctoChangeset.changeset({data, typemap()}, params, permitted(), required())
        end
      rescue
        CompileError ->
          @doc """
          Basic permitted and required validations for the defined type.
          """

          def changeset(data \\ %{}, params) do
            EctoChangeset.changeset({data, typemap()}, params, permitted(), required())
          end
      end
    end
  end

  @doc false
  def schema_field_is_permitted?(module, field) do
    tmap = module.typemap()

    case module.__schema__(:type, field) do
      t when is_atom(t) ->
        Map.has_key?(tmap, field)

      {:array, _} ->
        Map.has_key?(tmap, field)

      {:parameterized, Ecto.Embedded, _emb} ->
        false
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
