defmodule CljCompiler.Compat do
  @runtime_functions ~w(conj get assoc dissoc assoc_in)

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  def runtime_functions, do: @runtime_functions

  def call_with_fallback(parent_module, function, args) do
    arity = length(args)

    if function_exported?(parent_module, function, arity) do
      apply(parent_module, function, args)
    else
      apply(Kernel, function, args)
    end
  end

  defmacro conj(collection, item) do
    quote do
      [unquote(item) | unquote(collection)]
    end
  end

  defmacro get(map, key) do
    quote do
      Map.get(unquote(map), unquote(key))
    end
  end

  defmacro get(map, key, default) do
    quote do
      Map.get(unquote(map), unquote(key), unquote(default))
    end
  end

  defmacro assoc(map, key, value) do
    quote do
      Map.put(unquote(map), unquote(key), unquote(value))
    end
  end

  defmacro dissoc(map, keys) do
    quote do
      Enum.reduce(unquote(keys), unquote(map), fn key, acc -> Map.delete(acc, key) end)
    end
  end

  defmacro assoc_in(map, keys, value) do
    quote do
      put_in(unquote(map), unquote(keys), unquote(value))
    end
  end
end
