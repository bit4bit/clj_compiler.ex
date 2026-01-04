defmodule CljCompiler.Runtime do
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

  def dissoc(map, key) do
    Map.delete(map, key)
  end

  def dissoc(map, key1, key2) do
    map
    |> Map.delete(key1)
    |> Map.delete(key2)
  end

  def dissoc(map, key1, key2, key3) do
    map
    |> Map.delete(key1)
    |> Map.delete(key2)
    |> Map.delete(key3)
  end
end
