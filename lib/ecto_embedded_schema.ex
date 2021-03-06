defmodule Deftype.EctoEmbeddedSchema do
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

      embedded_schema do
        for {name, type, metas} <- attrs do
          case {type, Deftype.EctoUtil.get_relation(metas)} do
            {{:list, list_of}, {:field, opts}} ->
              if Deftype.EctoUtil.is_type?(list_of) do
                field(name, {:array, list_of}, opts)
              else
                embeds_many(name, list_of, opts)
              end

            {type, {:field, opts}} ->
              field(name, type, opts)

            {related_to, {:embeds_one, related_to, opts}} ->
              embeds_one(name, related_to, opts)

            {{:list, related_to}, {:embeds_many, related_to, opts}} ->
              embeds_many(name, related_to, opts)

            {bad_type, {card, related_to, opts}} ->
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

  def is_module(m) when is_atom(m) do
  end
end
