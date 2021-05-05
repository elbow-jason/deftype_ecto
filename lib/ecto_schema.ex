defmodule Deftype.EctoSchema do
  @behaviour Deftype.Plugin

  @cardinalities [:belongs_to, :has_one, :has_many, :many_to_many]

  @doc false
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
  @field_opts [
    :default,
    :source,
    :autogenerate,
    :read_after_writes,
    :virtual,
    :primary_key,
    :load_in_query,
    :redact
  ]

  # https://hexdocs.pm/ecto/Ecto.Schema.html#belongs_to/3
  @belongs_to_opts [
    :foreign_key,
    :references,
    :define_field,
    :type,
    :on_replace,
    :defaults,
    :primary_key,
    :source,
    :where
  ]

  # https://hexdocs.pm/ecto/Ecto.Schema.html#has_one/3
  @has_one_opts [:foreign_key, :references, :through, :on_delete, :on_replace, :defaults, :where]

  # https://hexdocs.pm/ecto/Ecto.Schema.html#has_many/3
  @has_many_opts [:foreign_key, :references, :through, :on_delete, :on_replace, :defaults, :where]

  # https://hexdocs.pm/ecto/Ecto.Schema.html#many_to_many/3
  @many_to_many_opts [
    :join_through,
    :join_keys,
    :on_delete,
    :on_replace,
    :defaults,
    :join_defaults,
    :unique,
    :where,
    :join_where
  ]

  @doc false
  def cardinality_opts(:field), do: @field_opts
  def cardinality_opts(:belongs_to), do: @belongs_to_opts
  def cardinality_opts(:has_one), do: @has_one_opts
  def cardinality_opts(:has_many), do: @has_many_opts
  def cardinality_opts(:many_to_many), do: @many_to_many_opts

  @impl Deftype.Plugin
  def call(cfg, _plugins, _type_metas, attrs) do
    cfg = Macro.escape(cfg)
    attrs = Macro.escape(attrs)

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

            {bad_type, {card, related_to, opts}}
            when card in [:has_many, :many_to_many, :embeds_many] ->
              c = inspect(card)
              r = inspect(related_to)
              b = inspect(bad_type)

              raise CompileError,
                description:
                  "Deftype.EctoSchema `#{c}` relationship requires type `{:list, #{r}}` but got `#{
                    b
                  }`"
          end
        end
      end
    end
  end
end
