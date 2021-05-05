defmodule Deftype.EctoSchema do
  @behaviour Deftype.Plugin

  @impl Deftype.Plugin
  def call(cfg, _plugins, _type_metas, attrs) do
    quote do
      use Ecto.Schema

      cfg = unquote(cfg)
      attrs = unquote(attrs)

      case Keyword.fetch(cfg, :primary_key) do
        {:ok, false} ->
          @primary_key false

        {:ok, {name, type, opts}} ->
          @primary_key {name, type, opts}

        _ ->
          []
      end

      schema Keyword.fetch!(cfg, :source) do
        for {name, type, metas} <- attrs do
          case {type, Deftype.EctoUtil.get_relation(metas)} do
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
