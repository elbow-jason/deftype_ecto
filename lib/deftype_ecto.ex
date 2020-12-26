defmodule Deftype.EctoSchema do

  @behaviour Deftype.Plugin

  def call(cfg, _type_metas, attrs) do
    quote do
      use Ecto.Schema
      cfg = unquote(cfg)
      attrs = unquote(attrs)

      schema Keyword.fetch!(cfg, :source) do
        for {name, type, metas} <- attrs do
          cond do
            relational_t = Keyword.get(metas, :belongs_to, false) ->
              # https://hexdocs.pm/ecto/Ecto.Schema.html#belongs_to/3
              allowed_metas = [:foreign_key, :references, :define_field, :type, :on_replace, :defaults, :primary_key, :source, :where]
              kept_metas = Keyword.take(metas, allowed_metas)
              belongs_to(name, relational_t, kept_metas)
            relational_t = Keyword.get(metas, :has_many, false) ->
              # https://hexdocs.pm/ecto/Ecto.Schema.html#has_many/3
              allowed_metas = [:foreign_key, :references, :through, :on_delete, :on_replace, :defaults, :where]
              kept_metas = Keyword.take(metas, allowed_metas)
              has_many(name, relational_t, kept_metas)
            true ->
              # non-relational attrs are feilds
              allowed_metas = [:default, :source, :autogenerate, :read_after_writes, :virtual, :primary_key, :load_in_query, :redact]
              kept_metas = Keyword.take(metas, allowed_metas)
              field(name, type, kept_metas)
          end
        end
      end
    end
  end
end

defmodule Deftype.EctoChangeset do
  alias Deftype.Attr
  alias Ecto.Changeset

  @behaviour Deftype.Plugin

  def call(cfg, _type_metas, attrs) do
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

      @typemap Map.new(attrs, fn attr -> {Attr.key(attr), Attr.type(attr)} end)

      try do
        @doc """
        Basic permitted and required validations for the given struct.

        - permitted: `#{inspect(@permitted)}`

        - required: `#{inspect(@required)}`

        - types: `#{inspect(@typemap, pretty: true)}`
        """
        def changeset(%__MODULE__{} = data \\ %__MODULE__{}, params) do
          EctoChangeset.base_changeset(data, params, @permitted, @required)
        end

      rescue CompileError ->
        @doc """
        Basic permitted and required validations for the defined type.

        - permitted: `#{inspect(@permitted)}`

        - required: `#{inspect(@required)}`

        - types: `#{inspect(@typemap, pretty: true)}`
        """

        def changeset(data \\ %{}, params) do
          EctoChangeset.base_changeset({data, @typemap}, params, @permitted, @required)
        end

      end
    end
  end

  def base_changeset(data, params, permitted, required) do
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
end
