defmodule CljCompiler.Translator do
  @built_in_ops ~w(+ - * / < > <= >= = == != and or not)

  def translate(forms, parent_module) do
    function_names = extract_function_names(forms)

    forms
    |> Enum.map(&translate_form(&1, parent_module, function_names))
    |> List.flatten()
  end

  defp extract_function_names(forms) do
    forms
    |> Enum.flat_map(fn
      {:list, [{:symbol, "defn"}, {:symbol, name} | _]} -> [name]
      _ -> []
    end)
    |> MapSet.new()
  end

  defp translate_form({:list, [{:symbol, "defn"}, {:symbol, name}, {:vector, params} | body]}, parent_module, function_names) do
    function_name = String.to_atom(name)
    param_vars = Enum.map(params, fn {:symbol, p} -> {String.to_atom(p), [], nil} end)
    body_ast = translate_body(body, parent_module, function_names)

    quote do
      def unquote(function_name)(unquote_splicing(param_vars)) do
        unquote(body_ast)
      end
    end
  end

  defp translate_form(_, _, _), do: []

  defp translate_body([{:string, value}], _parent_module, _function_names) do
    value
  end

  defp translate_body([form], parent_module, function_names) do
    translate_expr(form, parent_module, function_names)
  end

  defp translate_body([], _parent_module, _function_names), do: nil

  defp translate_expr({:string, value}, _parent_module, _function_names), do: value
  defp translate_expr({:number, value}, _parent_module, _function_names), do: value
  defp translate_expr({:symbol, name}, _parent_module, _function_names), do: {String.to_atom(name), [], nil}

  defp translate_expr({:list, [{:symbol, "str"} | args]}, parent_module, function_names) do
    translated_args = Enum.map(args, &translate_expr(&1, parent_module, function_names))

    quote do
      Enum.join([unquote_splicing(translated_args)], "")
    end
  end

  defp translate_expr({:list, [{:symbol, "if"}, condition, then_expr, else_expr]}, parent_module, function_names) do
    cond_ast = translate_expr(condition, parent_module, function_names)
    then_ast = translate_expr(then_expr, parent_module, function_names)
    else_ast = translate_expr(else_expr, parent_module, function_names)

    quote do
      if unquote(cond_ast) do
        unquote(then_ast)
      else
        unquote(else_ast)
      end
    end
  end

  defp translate_expr({:list, [{:symbol, "let"}, {:vector, bindings}, body]}, parent_module, function_names) do
    binding_pairs = Enum.chunk_every(bindings, 2)

    binding_asts = Enum.map(binding_pairs, fn [{:symbol, var_name}, value_expr] ->
      var_ast = {String.to_atom(var_name), [], nil}
      value_ast = translate_expr(value_expr, parent_module, function_names)

      quote do
        unquote(var_ast) = unquote(value_ast)
      end
    end)

    body_ast = translate_expr(body, parent_module, function_names)

    quote do
      (fn ->
        unquote_splicing(binding_asts)
        unquote(body_ast)
      end).()
    end
  end

  defp translate_expr({:list, [{:symbol, fn_name} | args]}, parent_module, function_names) do
    translated_args = Enum.map(args, &translate_expr(&1, parent_module, function_names))

    if String.contains?(fn_name, "/") do
      [module_name, function_name] = String.split(fn_name, "/")
      module_alias = Module.concat([module_name])
      function_atom = String.to_atom(function_name)

      quote do
        unquote(module_alias).unquote(function_atom)(unquote_splicing(translated_args))
      end
    else
      function_atom = String.to_atom(fn_name)

      cond do
        fn_name in @built_in_ops ->
          quote do
            unquote(function_atom)(unquote_splicing(translated_args))
          end

        MapSet.member?(function_names, fn_name) ->
          quote do
            unquote(function_atom)(unquote_splicing(translated_args))
          end

        true ->
          quote do
            CljCompiler.Runtime.call_with_fallback(
              unquote(parent_module),
              unquote(function_atom),
              [unquote_splicing(translated_args)]
            )
          end
      end
    end
  end

  defp translate_expr(_, _parent_module, _function_names), do: nil
end
