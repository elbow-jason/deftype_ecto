defmodule Deftype.EctoParameterizedType do
  @behaviour Deftype.Plugin

  def call(cfg, _plugins, _metas, _attrs) do
    quote do
      use Ecto.ParameterizedType

      cfg = unquote(cfg)

      case Keyword.fetch(cfg, :ecto_type) do
        :error ->
          :ok

        {:ok, t} ->
          @__configured_ecto_type t

          def type(_), do: @__configured_ecto_type
      end

      @before_compile Deftype.EctoParameterizedType
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      if !Module.defines?(__MODULE__, {:init, 1}) do
        def init(cfg) do
          cfg
        end
      end

      if !Module.defines?(__MODULE__, {:type, 1}) do
        def type(_cfg), do: :map
      end

      if !Module.defines?(__MODULE__, {:cast, 2}) do
        raise CompileError,
          description:
            "Deftype.EctoParameterizedType requires the definition of" <>
              " a success-case `cast/2` to function properly."
      end

      if !Module.defines?(__MODULE__, {:load, 3}) do
        def load(val, _loader, cfg) do
          cast(val, cfg)
        end
      end

      if !Module.defines?(__MODULE__, {:dump, 3}) do
        def dump(val, _dumper, cfg) do
          cast(val, cfg)
        end
      end

      def cast(_, _), do: :error

      def load(_, _, _), do: :error

      def dump(nil, _dumper, _cfg) do
        if Deftype.EctoParameterizedType.call_is_during_default_validation?() do
          {:ok, ""}
        else
          :error
        end
      end

      if !Module.defines?(__MODULE__, {:changeset, 1}) do
        raise CompileError,
          description:
            "Deftype.EctoParameterizedType requires the definition of" <>
              " changeset/1. Try adding `plugin(Deftype.EctoChangeset)`" <>
              " to the `deftype` block."
      end
    end
  end

  @doc false
  def call_is_during_default_validation? do
    # biggest hack in history.

    # expected stacktrace
    # [
    #   {Process, :info, 2, [file: 'lib/process.ex', line: 766]},
    #   {MyApp.MyTyp, :dump, 3, [file: 'lib/myapp/type/mytype.ex', line: 108]},
    #   {Ecto.Schema, :validate_default!, 2, [file: 'lib/ecto/schema.ex', line: 2125]},
    #   {Ecto.Schema, :__field__, 4, [file: 'lib/ecto/schema.ex', line: 1864]},

    # ]

    # Please forgive me, future developer.
    {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)

    matcher = fn item ->
      match?({Ecto.Schema, :validate_default!, 2, _}, item)
    end

    Enum.find(stacktrace, matcher) != nil
  end
end
