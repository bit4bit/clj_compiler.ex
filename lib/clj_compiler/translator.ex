# LLM-Assisted

defmodule CljCompiler.Translator do
  def translate(forms) do
    forms
    |> Enum.map(&translate_form/1)
    |> List.flatten()
  end

  defp translate_form({:list, [{:symbol, "defn"}, {:symbol, name}, {:vector, params} | body]}) do
    function_name = String.to_atom(name)
    param_vars = Enum.map(params, fn {:symbol, p} -> {String.to_atom(p), [], nil} end)
    body_ast = translate_body(body)

    quote do
      def unquote(function_name)(unquote_splicing(param_vars)) do
        unquote(body_ast)
      end
    end
  end

  defp translate_form(_), do: []

  defp translate_body([{:string, value}]) do
    value
  end

  defp translate_body([form]) do
    translate_expr(form)
  end

  defp translate_body([]), do: nil

  defp translate_expr({:string, value}), do: value
  defp translate_expr({:number, value}), do: value
  defp translate_expr({:symbol, name}), do: {String.to_atom(name), [], nil}

  defp translate_expr({:list, [{:symbol, "str"} | args]}) do
    translated_args = Enum.map(args, &translate_expr/1)

    quote do
      Enum.join([unquote_splicing(translated_args)], "")
    end
  end

  defp translate_expr({:list, [{:symbol, "if"}, condition, then_expr, else_expr]}) do
    cond_ast = translate_expr(condition)
    then_ast = translate_expr(then_expr)
    else_ast = translate_expr(else_expr)

    quote do
      if unquote(cond_ast) do
        unquote(then_ast)
      else
        unquote(else_ast)
      end
    end
  end

  defp translate_expr({:list, [{:symbol, "let"}, {:vector, bindings}, body]}) do
    binding_pairs = Enum.chunk_every(bindings, 2)

    binding_asts = Enum.map(binding_pairs, fn [{:symbol, var_name}, value_expr] ->
      var_ast = {String.to_atom(var_name), [], nil}
      value_ast = translate_expr(value_expr)

      quote do
        unquote(var_ast) = unquote(value_ast)
      end
    end)

    body_ast = translate_expr(body)

    quote do
      (fn ->
        unquote_splicing(binding_asts)
        unquote(body_ast)
      end).()
    end
  end

  defp translate_expr({:list, [{:symbol, fn_name} | args]}) do
    translated_args = Enum.map(args, &translate_expr/1)

    if String.contains?(fn_name, "/") do
      [module_name, function_name] = String.split(fn_name, "/")
      module_alias = Module.concat([module_name])
      function_atom = String.to_atom(function_name)

      quote do
        unquote(module_alias).unquote(function_atom)(unquote_splicing(translated_args))
      end
    else
      function_atom = String.to_atom(fn_name)

      quote do
        unquote(function_atom)(unquote_splicing(translated_args))
      end
    end
  end

  defp translate_expr(_), do: nil
end
