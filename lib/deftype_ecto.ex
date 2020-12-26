defmodule Deftype.EctoSchema do

  @behaviour Deftype.Plugin

  @cardinalities [:belongs_to, :has_one, :has_many, :many_to_many]

  def get_relation(metas) do
    metas
    |> Keyword.take(@cardinalities)
    |> Map.new()
    |> case do
      m when map_size(m) == 0 ->
        opts = Keyword.take(metas, cardinality_opts(:field))
        {:field, opts}
      m when map_size(m) == 1 ->
        {cardinality, related_to} =
          m
          |> Enum.to_list()
          |> hd()
        opts = Keyword.take(metas, cardinality_opts(cardinality))
        {cardinality, related_to, opts}
      m when map_size(m) > 1 ->
        raise "More than one relationship was defined #{inspect(m)}"
    end
  end

  # https://hexdocs.pm/ecto/Ecto.Schema.html#field/3
  @field_opts [:default, :source, :autogenerate, :read_after_writes, :virtual, :primary_key, :load_in_query, :redact]

  # https://hexdocs.pm/ecto/Ecto.Schema.html#belongs_to/3
  @belongs_to_opts [:foreign_key, :references, :define_field, :type, :on_replace, :defaults, :primary_key, :source, :where]

  # https://hexdocs.pm/ecto/Ecto.Schema.html#has_one/3
  @has_one_opts [:foreign_key, :references, :through, :on_delete, :on_replace, :defaults, :where]

  # https://hexdocs.pm/ecto/Ecto.Schema.html#has_many/3
  @has_many_opts [:foreign_key, :references, :through, :on_delete, :on_replace, :defaults, :where]

  # https://hexdocs.pm/ecto/Ecto.Schema.html#many_to_many/3
  @many_to_many_opts [:join_through, :join_keys, :on_delete, :on_replace, :defaults, :join_defaults, :unique, :where, :join_where]


  def cardinality_opts(:field), do: @field_opts
  def cardinality_opts(:belongs_to), do: @belongs_to_opts
  def cardinality_opts(:has_one), do: @has_one_opts
  def cardinality_opts(:has_many), do: @has_many_opts
  def cardinality_opts(:many_to_many), do: @many_to_many_opts


  def call(cfg, _type_metas, attrs) do
    quote do
      use Ecto.Schema
      alias Deftype.EctoSchema

      cfg = unquote(cfg)
      attrs = unquote(attrs)

      schema Keyword.fetch!(cfg, :source) do
        for {name, type, metas} <- attrs do
          case {type, EctoSchema.get_relation(metas)} do
            {_, {:field, opts}} ->
              field(name, type, opts)

            {_, {:belongs_to, related_to, opts}} ->
              belongs_to(name, related_to, opts)

            {_, {:has_one, related_to, opts}} ->
              has_one(name, related_to, opts)

            {{:list, related_to}, {:has_many, related_to, opts}} ->
              has_many(name, related_to, opts)

            {{:list, related_to}, {:many_to_many, related_to, opts}} ->
              many_to_many(name, related_to, opts)

            {bad_type, {card, related_to, opts}} when card in [:has_many, :many_to_many, :embeds_many] ->
              c = inspect(card)
              r = inspect(related_to)
              b = inspect(bad_type)
              raise CompileError, description: "Deftype.EctoSchema `#{c}` relationship requires type `{:list, #{r}}` but got `#{b}`"
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
          EctoChangeset.base_changeset({data, @typemap}, params, @permitted, @required)
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
