defmodule ProtectedStruct do
  @moduledoc """
  Protects struct creation/update using struct syntax outside of its module.

  ## Options

  - `:on_violation` (default: `:raise`) - action to take when a struct is created outside of its
    module. One of `:raise` or `:warn`. Due to the nature of tracing, `:warn` will only be logged
    once and won't be logged again until the offending module is recompiled.
  - `:allow_in_evals?` (default: `false`) - allow outside struct creation in eval contexts,
    e.g. in exs scripts or tests. Note that eval block only affects creation, not updates.

  ## Example

      defmodule MyStruct do
        use ProtectedStruct

        defstruct [:name, :age]
        def new(name, age), do: %__MODULE__{name: name, age: age}
      end

      iex> %MyStruct{}
      ** (ProtectedStruct.Error) %MyStruct{} can only be created inside its own module

      iex> val = MyStruct.new("John", 30)
      iex> %MyStruct{val | name: "Jane"}
      ** (ProtectedStruct.Error) %MyStruct{} can only be created inside its own module

  """

  @doc false
  defmacro __using__(opts) do
    opts = Keyword.validate!(opts, on_violation: :raise, allow_in_evals?: false)
    on_violation = Keyword.fetch!(opts, :on_violation)
    allow_in_evals? = Keyword.fetch!(opts, :allow_in_evals?)

    if on_violation not in [:raise, :warn],
      do: raise(ArgumentError, "invalid on_violation: #{inspect(on_violation)}")

    Module.register_attribute(__CALLER__.module, __MODULE__, persist: true)
    Module.put_attribute(__CALLER__.module, __MODULE__, on_violation)

    if not allow_in_evals?,
      do: Module.put_attribute(__CALLER__.module, :before_compile, __MODULE__)

    nil
  end

  @doc false
  defmacro __before_compile__(env) do
    action = Module.get_attribute(env.module, __MODULE__)
    action_quoted = action_quoted(action)

    quote bind_quoted: [module: __MODULE__, action_quoted: Macro.escape(action_quoted)] do
      defoverridable __struct__: 1

      def __struct__(_fields),
        do: unquote(action_quoted)
    end
  end

  defp action_quoted(:raise) do
    quote do
      msg = "#{__MODULE__} can only be created inside its own module"
      raise ProtectedStruct.Error, module: __MODULE__, message: msg
    end
  end

  defp action_quoted(:warn) do
    quote do
      msg = "ProtectedStruct: #{__MODULE__} created outside its own module"
      IO.warn(msg)
    end
  end
end

defmodule ProtectedStruct.Tracer do
  @doc false
  def trace({:struct_expansion, _meta, module, _keys}, env) do
    if module != env.module and not Macro.Env.in_guard?(env) and not Macro.Env.in_match?(env) do
      action =
        if Module.open?(module),
          do: module |> Module.get_attribute(ProtectedStruct),
          else: module.__info__(:attributes)[ProtectedStruct]

      case List.wrap(action) do
        [] ->
          :ok

        [:raise] ->
          msg = "#{inspect(module)} can only be created inside its own module"
          reraise ProtectedStruct.Error, [module: module, message: msg], Macro.Env.stacktrace(env)

        [:warn] ->
          msg = "ProtectedStruct: #{inspect(module)} created outside its own module"
          IO.warn(msg, Macro.Env.stacktrace(env))
      end
    end

    :ok
  end

  def trace(_event, _env),
    do: :ok
end

defmodule ProtectedStruct.Error do
  defexception [:module, :message]
end
