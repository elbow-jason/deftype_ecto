defmodule Deftype.EctoUtil do
  @moduledoc false

  alias Ecto.Changeset

  def is_schema?(module) when is_atom(module) do
    loaded? = Code.ensure_loaded?(module)
    loaded? && function_exported?(module, :__schema__, 1)
  end

  def is_schema?(_) do
    false
  end

  def is_type?(module) when is_atom(module) do
    loaded? = Code.ensure_loaded?(module)
    type0? = function_exported?(module, :type, 0)
    type1? = function_exported?(module, :type, 1)
    has_type? = type0? || type1?
    has_cast? = has_type_fun?(module, :cast)
    has_load? = has_type_fun?(module, :load)
    has_dump? = has_type_fun?(module, :dump)
    loaded? && has_type? && has_cast? && has_load? && has_dump?
  end

  def is_type?(_) do
    false
  end

  defp has_type_fun?(module, fun) do
    function_exported?(module, fun, 1) || function_exported?(module, fun, 2)
  end

  def changeset_to_result(%Changeset{} = cs) do
    cs
    |> Changeset.apply_action(nil)
    |> case do
      {:ok, _} = okay ->
        okay

      {:error, cs} ->
        {:error, changeset_errors(cs)}
    end
  end

  def changeset_errors(cs) do
    Changeset.traverse_errors(cs, fn e -> e end)
  end

  @cardinalities [:belongs_to, :has_one, :has_many, :many_to_many, :embeds_one, :embeds_many]

  def get_relation(metas) do
    metas
    |> Keyword.take(@cardinalities)
    |> Map.new()
    |> case do
      m when map_size(m) == 0 ->
        {:field, metas}

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

  # https://hexdocs.pm/ecto/Ecto.Schema.html#embeds_one/3
  @embeds_one_opts [
    :on_replace,
    :source
  ]

  # https://hexdocs.pm/ecto/Ecto.Schema.html#embeds_many/3
  @embeds_many_opts [
    :on_replace,
    :source
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
  def cardinality_opts(:belongs_to), do: @belongs_to_opts
  def cardinality_opts(:has_one), do: @has_one_opts
  def cardinality_opts(:has_many), do: @has_many_opts
  def cardinality_opts(:many_to_many), do: @many_to_many_opts
  def cardinality_opts(:embeds_one), do: @embeds_one_opts
  def cardinality_opts(:embeds_mansy), do: @embeds_many_opts
end
