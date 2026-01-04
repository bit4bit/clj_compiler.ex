defmodule CljCompiler.Runtime do
  @runtime_functions ~w(conj get assoc dissoc)

  def runtime_functions, do: @runtime_functions

  def call_with_fallback(parent_module, function, args) do
    arity = length(args)

    if function_exported?(parent_module, function, arity) do
      apply(parent_module, function, args)
    else
      apply(Kernel, function, args)
    end
  end

  def conj(collection, item) do
    [item | collection]
  end

  def get(map, key) do
    Map.get(map, key)
  end

  def get(map, key, default) do
    Map.get(map, key, default)
  end

  def assoc(map, key, value) do
    Map.put(map, key, value)
  end

  def dissoc(map, keys) when is_list(keys) do
    Enum.reduce(keys, map, fn key, acc -> Map.delete(acc, key) end)
  end
end
