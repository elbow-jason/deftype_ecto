defmodule Deftype.EctoType do
  @behaviour Deftype.Plugin

  def call(_cfg, _plugins, _metas, _attrs) do
    quote do
      use Ecto.Type

      def type, do: :map

      def cast(data) when is_map(data) do
        data
        |> changeset()
        |> Deftype.EctoUtil.changeset_to_result()
      end

      def dump(%__MODULE__{} = data) when is_map(data) do
        {:ok, Map.drop(data, [:__struct__, :__meta__])}
      end

      def load(data) when is_map(data) do
        data
        |> changeset()
        |> Deftype.EctoUtil.changeset_to_result()
      end

      @before_compile Deftype.EctoType
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def cast(_), do: :error

      def load(_), do: :error

      def dump(_), do: :error

      if !Module.defines?(__MODULE__, {:changeset, 1}) do
        raise CompileError,
          description:
            "Deftype.EctoType requires the definition of changeset/1. Try adding `plugin(Deftype.EctoChangeset)` to the `deftype` block."
      end
    end
  end
end
