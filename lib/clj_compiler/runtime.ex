defmodule CljCompiler.Runtime do
  def call_with_fallback(parent_module, function, args) do
    arity = length(args)

    if function_exported?(parent_module, function, arity) do
      apply(parent_module, function, args)
    else
      apply(Kernel, function, args)
    end
  end
end
