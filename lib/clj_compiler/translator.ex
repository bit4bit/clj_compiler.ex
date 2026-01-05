defmodule CljCompiler.Translator do
  @built_in_ops ~w(+ - * / < > <= >= = == != and or not)
  @runtime_functions CljCompiler.Runtime.runtime_functions()

  def translate(forms, parent_module, file) do
    function_names = extract_function_names(forms)
    attr_names = extract_attr_names(forms)

    forms
    |> Enum.map(&translate_form(&1, parent_module, function_names, attr_names, [], file))
    |> List.flatten()
  end

  defp translate_form({:list, [{:symbol, "ns"} | _], _line}, _parent_module, _function_names, _attr_names, _param_names, _file) do
    []
  end

  defp translate_form({:list, [{:symbol, "ns"} | _]}, _parent_module, _function_names, _attr_names, _param_names, _file) do
    []
  end

  defp translate_form({:list, [{:symbol, "def"}, {:symbol, name}, value], _line}, parent_module, function_names, attr_names, _param_names, file) do
    attr_name = name |> String.replace("-", "_") |> String.to_atom()
    value_ast = translate_expr(value, parent_module, function_names, attr_names, [], file)

    {:@, [file: to_charlist(file), line: 1], [{attr_name, [], [value_ast]}]}
  end

  defp translate_form({:list, [{:symbol, "def"}, {:symbol, name}, value]}, parent_module, function_names, attr_names, _param_names, file) do
    attr_name = name |> String.replace("-", "_") |> String.to_atom()
    value_ast = translate_expr(value, parent_module, function_names, attr_names, [], file)

    {:@, [file: to_charlist(file), line: 1], [{attr_name, [], [value_ast]}]}
  end

  defp translate_form({:list, [{:symbol, "defn"}, {:symbol, name}, {:vector, params} | body], line}, parent_module, function_names, attr_names, _param_names, file) do
    function_name = name |> String.replace("-", "_") |> String.to_atom()

    param_names = Enum.map(params, fn {:symbol, p} -> p end)
    param_vars = Enum.map(params, fn {:symbol, p} ->
      {String.to_atom(p), [file: to_charlist(file), line: line], nil}
    end)

    body_ast = translate_body(body, parent_module, function_names, attr_names, param_names, file)

    {:def, [file: to_charlist(file), line: line], [
      {function_name, [file: to_charlist(file), line: line], param_vars},
      [do: body_ast]
    ]}
  end

  defp translate_form({:list, [{:symbol, "defn"}, {:symbol, name}, {:vector, params} | body]}, parent_module, function_names, attr_names, _param_names, file) do
    function_name = name |> String.replace("-", "_") |> String.to_atom()

    param_names = Enum.map(params, fn {:symbol, p} -> p end)
    param_vars = Enum.map(params, fn {:symbol, p} ->
      {String.to_atom(p), [file: to_charlist(file), line: 1], nil}
    end)

    body_ast = translate_body(body, parent_module, function_names, attr_names, param_names, file)

    {:def, [file: to_charlist(file), line: 1], [
      {function_name, [file: to_charlist(file), line: 1], param_vars},
      [do: body_ast]
    ]}
  end

  defp translate_form({:list, [{:symbol, unknown_symbol} | _], line}, _parent_module, _function_names, _attr_names, _param_names, file) do
    raise CompileError,
      file: file,
      line: line,
      description: "Unable to resolve symbol: #{unknown_symbol} in this context"
  end

  defp translate_form({:list, [{:symbol, unknown_symbol} | _]}, _parent_module, _function_names, _attr_names, _param_names, file) do
    raise CompileError,
      file: file,
      line: 1,
      description: "Unable to resolve symbol: #{unknown_symbol} in this context"
  end

  defp translate_form(_, _, _, _, _, _), do: []

  defp extract_function_names(forms) do
    forms
    |> Enum.flat_map(fn
      {:list, [{:symbol, "defn"}, {:symbol, name} | _], _line} -> [name]
      {:list, [{:symbol, "defn"}, {:symbol, name} | _]} -> [name]
      _ -> []
    end)
    |> MapSet.new()
  end

  defp extract_attr_names(forms) do
    forms
    |> Enum.flat_map(fn
      {:list, [{:symbol, "def"}, {:symbol, name}, _], _line} -> [name]
      {:list, [{:symbol, "def"}, {:symbol, name}, _]} -> [name]
      _ -> []
    end)
    |> MapSet.new()
  end

  defp translate_body([{:string, value}], _parent_module, _function_names, _attr_names, _param_names, _file) do
    value
  end

  defp translate_body([form], parent_module, function_names, attr_names, param_names, file) do
    translate_expr(form, parent_module, function_names, attr_names, param_names, file)
  end

  defp translate_body([], _parent_module, _function_names, _attr_names, _param_names, _file), do: nil

  defp translate_expr({:string, value}, _parent_module, _function_names, _attr_names, _param_names, _file), do: value
  defp translate_expr({:number, value}, _parent_module, _function_names, _attr_names, _param_names, _file), do: value
  defp translate_expr({:keyword, atom}, _parent_module, _function_names, _attr_names, _param_names, _file), do: atom
  defp translate_expr({:symbol, "true"}, _parent_module, _function_names, _attr_names, _param_names, _file), do: true
  defp translate_expr({:symbol, "false"}, _parent_module, _function_names, _attr_names, _param_names, _file), do: false

  defp translate_expr({:symbol, name}, _parent_module, _function_names, attr_names, param_names, _file) do
    normalized_name = String.replace(name, "-", "_")
    cond do
      MapSet.member?(attr_names, name) ->
        {:@, [], [{String.to_atom(normalized_name), [], nil}]}

      name in param_names ->
        {String.to_atom(name), [], nil}

      true ->
        {String.to_atom(name), [], nil}
    end
  end

  defp translate_expr({:map, elements}, parent_module, function_names, attr_names, param_names, file) do
    pairs = Enum.chunk_every(elements, 2)

    map_pairs = Enum.map(pairs, fn [key, value] ->
      key_ast = translate_expr(key, parent_module, function_names, attr_names, param_names, file)
      value_ast = translate_expr(value, parent_module, function_names, attr_names, param_names, file)
      {key_ast, value_ast}
    end)

    {:%{}, [], map_pairs}
  end

  defp translate_expr({:vector, elements}, parent_module, function_names, attr_names, param_names, file) do
    translated = Enum.map(elements, &translate_expr(&1, parent_module, function_names, attr_names, param_names, file))
    translated
  end

  defp translate_expr({:list, [{:symbol, "str"} | args]}, parent_module, function_names, attr_names, param_names, file) do
    translated_args = Enum.map(args, &translate_expr(&1, parent_module, function_names, attr_names, param_names, file))

    quote do
      Enum.join([unquote_splicing(translated_args)], "")
    end
  end

  defp translate_expr({:list, [{:symbol, "if"}, condition, then_expr, else_expr]}, parent_module, function_names, attr_names, param_names, file) do
    cond_ast = translate_expr(condition, parent_module, function_names, attr_names, param_names, file)
    then_ast = translate_expr(then_expr, parent_module, function_names, attr_names, param_names, file)
    else_ast = translate_expr(else_expr, parent_module, function_names, attr_names, param_names, file)

    quote do
      if unquote(cond_ast) do
        unquote(then_ast)
      else
        unquote(else_ast)
      end
    end
  end

  defp translate_expr({:list, [{:symbol, "let"}, {:vector, bindings}, body]}, parent_module, function_names, attr_names, param_names, file) do
    binding_pairs = Enum.chunk_every(bindings, 2)

    binding_asts = Enum.map(binding_pairs, fn [{:symbol, var_name}, value_expr] ->
      var_ast = {String.to_atom(var_name), [], nil}
      value_ast = translate_expr(value_expr, parent_module, function_names, attr_names, param_names, file)

      quote do
        unquote(var_ast) = unquote(value_ast)
      end
    end)

    body_ast = translate_expr(body, parent_module, function_names, attr_names, param_names, file)

    quote do
      (fn ->
        unquote_splicing(binding_asts)
        unquote(body_ast)
      end).()
    end
  end

  defp translate_expr({:list, [{:keyword, keyword} | args]}, parent_module, function_names, attr_names, param_names, file) do
    case args do
      [map_expr] ->
        map_ast = translate_expr(map_expr, parent_module, function_names, attr_names, param_names, file)
        quote do
          Map.get(unquote(map_ast), unquote(keyword))
        end
      _ ->
        nil
    end
  end

  defp translate_expr({:list, [{:symbol, fn_name} | args]}, parent_module, function_names, attr_names, param_names, file) do
    translated_args = Enum.map(args, &translate_expr(&1, parent_module, function_names, attr_names, param_names, file))

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
        fn_name in @runtime_functions ->
          translate_runtime_call(fn_name, translated_args)

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
            unquote(function_atom)(unquote_splicing(translated_args))
          end
      end
    end
  end

  defp translate_expr(_, _parent_module, _function_names, _attr_names, _param_names, _file), do: nil

  defp translate_runtime_call(fn_name, translated_args) do
    normalized_name = fn_name |> String.replace("-", "_") |> String.to_atom()
    quote do
      apply(CljCompiler.Runtime, unquote(normalized_name), unquote(translated_args))
    end
  end
end
