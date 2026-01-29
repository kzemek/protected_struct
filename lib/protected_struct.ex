defmodule ProtectedStruct do
  defmacro __using__(opts) do
    on_violation = Keyword.get(opts, :on_violation, :raise)

    if on_violation not in [:raise, :warn],
      do: raise(ArgumentError, "invalid on_violation: #{inspect(on_violation)}")

    Module.register_attribute(__CALLER__.module, __MODULE__, persist: true)
    Module.put_attribute(__CALLER__.module, __MODULE__, on_violation)

    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable __struct__: 1

      def __struct__(fields) do
        unquote(__MODULE__).action_if_protected(__MODULE__)
        super(fields)
      end
    end
  end

  @doc false
  def action_if_protected(module) do
    action =
      if Module.open?(module),
        do: Module.get_attribute(module, __MODULE__),
        else: module.__info__(:attributes)[__MODULE__]

    case List.wrap(action) do
      [] ->
        :ok

      [:raise] ->
        raise ProtectedStruct.Error,
          module: module,
          message: "#{inspect(module)} can only be created inside its own module"

      [:warn] ->
        IO.warn("ProtectedStruct: #{inspect(module)} created outside its own module")
    end
  end
end

defmodule ProtectedStruct.Tracer do
  @doc false
  def trace({:struct_expansion, _meta, module, _keys}, env) do
    if module != env.module,
      do: ProtectedStruct.action_if_protected(module)

    :ok
  end

  def trace(_event, _env),
    do: :ok
end

defmodule ProtectedStruct.Error do
  defexception [:module, :message]
end
