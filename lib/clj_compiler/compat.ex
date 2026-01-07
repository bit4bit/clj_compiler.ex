defmodule CljCompiler.Compat do
  @moduledoc """
  This module provides compatibility functions inspired by the Clojure standard library.
  """

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
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

  def dissoc(map, keys) do
    Enum.reduce(keys, map, fn key, acc -> Map.delete(acc, key) end)
  end

  def assoc_in(map, keys, value) do
    put_in(map, keys, value)
  end
end
