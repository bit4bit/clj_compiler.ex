defmodule CljCompiler.Translator do
  @built_in_ops ~w(+ - * / < > <= >= = == != and or not)

  def translate(forms, use_clauses, parent_module, file) do
    attr_names = extract_attr_names(forms)
    local_functions = extract_function_names(forms)
    namespace_uses = extract_use_module_names(use_clauses)

    forms
    |> Enum.map(
      &translate_form(&1, parent_module, attr_names, [], local_functions, namespace_uses, file)
    )
    |> List.flatten()
  end

  defp translate_form(
         {:list, [{:symbol, "ns"} | _], _line},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ) do
    []
  end

  defp translate_form(
         {:list, [{:symbol, "ns"} | _]},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ) do
    []
  end

  defp translate_form(
         {:list, [{:symbol, "def"}, {:symbol, name}, value], _line},
         parent_module,
         attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         file
       ) do
    attr_name = name |> String.replace("-", "_") |> String.to_atom()
    value_ast = translate_expr(value, parent_module, attr_names, [], [], [], file)

    {:@, [file: to_charlist(file), line: 1], [{attr_name, [], [value_ast]}]}
  end

  defp translate_form(
         {:list, [{:symbol, "def"}, {:symbol, name}, value]},
         parent_module,
         attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         file
       ) do
    attr_name = name |> String.replace("-", "_") |> String.to_atom()
    value_ast = translate_expr(value, parent_module, attr_names, [], [], [], file)

    {:@, [file: to_charlist(file), line: 1], [{attr_name, [], [value_ast]}]}
  end

  defp translate_form(
         {:list, [{:symbol, "defn"}, {:symbol, name}, {:vector, params} | body], line},
         parent_module,
         attr_names,
         _param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    function_name = name |> String.replace("-", "_") |> String.to_atom()

    param_names = Enum.map(params, fn {:symbol, p} -> p end)

    param_vars =
      Enum.map(params, fn {:symbol, p} ->
        {String.to_atom(p), [file: to_charlist(file), line: line], nil}
      end)

    body_ast =
      translate_body(
        body,
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )

    {:def, [file: to_charlist(file), line: line],
     [
       {function_name, [file: to_charlist(file), line: line], param_vars},
       [do: body_ast]
     ]}
  end

  defp translate_form(
         {:list, [{:symbol, "defn"}, {:symbol, name}, {:vector, params} | body]},
         parent_module,
         attr_names,
         _param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    function_name = name |> String.replace("-", "_") |> String.to_atom()

    param_names = Enum.map(params, fn {:symbol, p} -> p end)

    param_vars =
      Enum.map(params, fn {:symbol, p} ->
        {String.to_atom(p), [file: to_charlist(file), line: 1], nil}
      end)

    body_ast =
      translate_body(
        body,
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )

    {:def, [file: to_charlist(file), line: 1],
     [
       {function_name, [file: to_charlist(file), line: 1], param_vars},
       [do: body_ast]
     ]}
  end

  defp translate_form(
         {:list, [{:symbol, unknown_symbol} | _], line},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         file
       ) do
    raise CompileError,
      file: file,
      line: line,
      description: "Unable to resolve symbol: #{unknown_symbol} in this context"
  end

  defp translate_form(
         {:list, [{:symbol, unknown_symbol} | _]},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         file
       ) do
    raise CompileError,
      file: file,
      line: 1,
      description: "Unable to resolve symbol: #{unknown_symbol} in this context"
  end

  defp translate_form(_, _, _, _, _, _, _), do: []

  defp extract_attr_names(forms) do
    forms
    |> Enum.flat_map(fn
      {:list, [{:symbol, "def"}, {:symbol, name}, _], _line} -> [name]
      {:list, [{:symbol, "def"}, {:symbol, name}, _]} -> [name]
      _ -> []
    end)
    |> MapSet.new()
  end

  defp translate_body(
         [{:string, value}],
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ) do
    value
  end

  defp translate_body(
         [form],
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    translate_expr(
      form,
      parent_module,
      attr_names,
      param_names,
      local_functions,
      namespace_uses,
      file
    )
  end

  defp translate_body(
         [],
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ),
       do: nil

  defp translate_expr(
         {:string, value},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ),
       do: value

  defp translate_expr(
         {:number, value},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ),
       do: value

  defp translate_expr(
         {:keyword, atom},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ),
       do: atom

  defp translate_expr(
         {:symbol, "true"},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ),
       do: true

  defp translate_expr(
         {:symbol, "false"},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ),
       do: false

  defp translate_expr(
         {:symbol, name},
         _parent_module,
         attr_names,
         param_names,
         _local_functions,
         _namespace_uses,
         _file
       ) do
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

  defp translate_expr(
         {:map, elements},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    pairs = Enum.chunk_every(elements, 2)

    map_pairs =
      Enum.map(pairs, fn [key, value] ->
        key_ast =
          translate_expr(
            key,
            parent_module,
            attr_names,
            param_names,
            local_functions,
            namespace_uses,
            file
          )

        value_ast =
          translate_expr(
            value,
            parent_module,
            attr_names,
            param_names,
            local_functions,
            namespace_uses,
            file
          )

        {key_ast, value_ast}
      end)

    {:%{}, [], map_pairs}
  end

  defp translate_expr(
         {:vector, elements},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    translated =
      Enum.map(
        elements,
        &translate_expr(
          &1,
          parent_module,
          attr_names,
          param_names,
          local_functions,
          namespace_uses,
          file
        )
      )

    translated
  end

  defp translate_expr(
         {:list, [{:symbol, "str"} | args]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    translated_args =
      Enum.map(
        args,
        &translate_expr(
          &1,
          parent_module,
          attr_names,
          param_names,
          local_functions,
          namespace_uses,
          file
        )
      )

    quote do
      Enum.join([unquote_splicing(translated_args)], "")
    end
  end

  defp translate_expr(
         {:list, [{:symbol, "if"}, condition, then_expr, else_expr]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    cond_ast =
      translate_expr(
        condition,
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )

    then_ast =
      translate_expr(
        then_expr,
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )

    else_ast =
      translate_expr(
        else_expr,
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )

    quote do
      if unquote(cond_ast) do
        unquote(then_ast)
      else
        unquote(else_ast)
      end
    end
  end

  defp translate_expr(
         {:list, [{:symbol, "let"}, {:vector, bindings}, body]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    binding_pairs = Enum.chunk_every(bindings, 2)

    # Extract variable names from bindings to add to param_names
    bound_var_names =
      Enum.map(binding_pairs, fn [{:symbol, var_name}, _value_expr] ->
        var_name
      end)

    # Add bound variables to param_names for body translation
    new_param_names = param_names ++ bound_var_names

    binding_asts =
      Enum.map(binding_pairs, fn [{:symbol, var_name}, value_expr] ->
        var_ast = {String.to_atom(var_name), [], nil}

        value_ast =
          translate_expr(
            value_expr,
            parent_module,
            attr_names,
            param_names,
            local_functions,
            namespace_uses,
            file
          )

        quote do
          unquote(var_ast) = unquote(value_ast)
        end
      end)

    body_ast =
      translate_expr(
        body,
        parent_module,
        attr_names,
        new_param_names,
        local_functions,
        namespace_uses,
        file
      )

    quote do
      (fn ->
         unquote_splicing(binding_asts)
         unquote(body_ast)
       end).()
    end
  end

  defp translate_expr(
         {:list, [{:symbol, "fn"}, {:vector, params} | body]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    # Extract parameter names as symbols
    param_symbols =
      Enum.map(params, fn
        {:symbol, name} -> String.to_atom(name)
        _ -> raise "fn parameters must be symbols"
      end)

    # Create parameter AST nodes
    param_asts = Enum.map(param_symbols, fn name -> {name, [], nil} end)

    # Add parameters to the param_names context for body translation
    new_param_names = param_names ++ Enum.map(param_symbols, &Atom.to_string/1)

    # Translate the body (support single expression for now)
    body_ast =
      case body do
        [single_expr] ->
          translate_expr(
            single_expr,
            parent_module,
            attr_names,
            new_param_names,
            local_functions,
            namespace_uses,
            file
          )

        [] ->
          nil

        _ ->
          raise "fn body must have exactly one expression"
      end

    # Generate Elixir anonymous function AST
    quote do
      fn unquote_splicing(param_asts) -> unquote(body_ast) end
    end
  end

  # Handle calling an expression directly, e.g., ((fn [x] (* x 2)) 5)
  defp translate_expr(
         {:list, [{:list, _} = fn_expr | args]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    # Translate the function expression (could be a fn or any expression that returns a function)
    fn_ast =
      translate_expr(
        fn_expr,
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )

    # Translate arguments
    translated_args =
      Enum.map(
        args,
        &translate_expr(
          &1,
          parent_module,
          attr_names,
          param_names,
          local_functions,
          namespace_uses,
          file
        )
      )

    # Generate anonymous function call syntax
    quote do
      unquote(fn_ast).(unquote_splicing(translated_args))
    end
  end

  defp translate_expr(
         {:list, [{:keyword, keyword} | args]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    case args do
      [map_expr] ->
        map_ast =
          translate_expr(
            map_expr,
            parent_module,
            attr_names,
            param_names,
            local_functions,
            namespace_uses,
            file
          )

        quote do
          Map.get(unquote(map_ast), unquote(keyword))
        end

      _ ->
        nil
    end
  end

  defp translate_expr(
         {:list, [{:symbol, fn_name} | args], line},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    validate_function_call!(
      fn_name,
      parent_module,
      attr_names,
      param_names,
      local_functions,
      namespace_uses,
      file,
      line
    )

    translated_args =
      Enum.map(
        args,
        &translate_expr(
          &1,
          parent_module,
          attr_names,
          param_names,
          local_functions,
          namespace_uses,
          file
        )
      )

    original_fn_name = fn_name
    fn_name = String.replace(fn_name, "-", "_")

    if String.contains?(fn_name, "/") do
      [module_name, function_name] = String.split(fn_name, "/")
      module_alias = Module.concat([module_name])
      function_atom = String.to_atom(String.replace(function_name, "-", "_"))

      quote do
        unquote(module_alias).unquote(function_atom)(unquote_splicing(translated_args))
      end
    else
      function_atom = String.to_atom(fn_name)

      cond do
        # Check if calling a variable (could be an anonymous function)
        fn_name in param_names or String.replace(fn_name, "-", "_") in param_names ->
          var_ast = {function_atom, [], nil}

          quote do
            unquote(var_ast).(unquote_splicing(translated_args))
          end

        fn_name in @built_in_ops ->
          quote do
            unquote(function_atom)(unquote_splicing(translated_args))
          end

        original_fn_name in @built_in_ops ->
          function_atom = String.to_atom(original_fn_name)

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

  defp translate_expr(
         {:list, [{:symbol, fn_name} | args]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    validate_function_call!(
      fn_name,
      parent_module,
      attr_names,
      param_names,
      local_functions,
      namespace_uses,
      file,
      1
    )

    translated_args =
      Enum.map(
        args,
        &translate_expr(
          &1,
          parent_module,
          attr_names,
          param_names,
          local_functions,
          namespace_uses,
          file
        )
      )

    original_fn_name = fn_name
    fn_name = String.replace(fn_name, "-", "_")

    if String.contains?(fn_name, "/") do
      [module_name, function_name] = String.split(fn_name, "/")
      module_alias = Module.concat([module_name])
      function_atom = String.to_atom(String.replace(function_name, "-", "_"))

      quote do
        unquote(module_alias).unquote(function_atom)(unquote_splicing(translated_args))
      end
    else
      function_atom = String.to_atom(fn_name)

      cond do
        # Check if calling a variable (could be an anonymous function)
        fn_name in param_names or String.replace(fn_name, "-", "_") in param_names ->
          var_ast = {function_atom, [], nil}

          quote do
            unquote(var_ast).(unquote_splicing(translated_args))
          end

        fn_name in @built_in_ops ->
          quote do
            unquote(function_atom)(unquote_splicing(translated_args))
          end

        original_fn_name in @built_in_ops ->
          function_atom = String.to_atom(original_fn_name)

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

  defp translate_expr(
         _,
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ),
       do: nil

  defp extract_function_names(forms) do
    forms
    |> Enum.flat_map(fn
      {:list, [{:symbol, "defn"}, {:symbol, name}, {:vector, _} | _], _line} ->
        [String.replace(name, "-", "_")]

      {:list, [{:symbol, "defn"}, {:symbol, name}, {:vector, _} | _]} ->
        [String.replace(name, "-", "_")]

      _ ->
        []
    end)
    |> MapSet.new()
  end

  defp extract_use_module_names(use_clauses) do
    Enum.map(use_clauses, fn {module_name, _opts} -> module_name end)
  end

  defp validate_function_call!(
         fn_name,
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file,
         line
       ) do
    normalized = String.replace(fn_name, "-", "_")

    cond do
      fn_name in @built_in_ops or normalized in @built_in_ops ->
        :ok

      fn_name in ~w(str if let fn) ->
        :ok

      String.starts_with?(fn_name, ":") ->
        :ok

      String.contains?(fn_name, "/") ->
        :ok

      fn_name in param_names or normalized in param_names ->
        :ok

      MapSet.member?(attr_names, fn_name) or MapSet.member?(attr_names, normalized) ->
        :ok

      MapSet.member?(local_functions, normalized) ->
        :ok

      "CljCompiler.Compat" in namespace_uses and is_compat_function?(normalized) ->
        :ok

      not Enum.empty?(namespace_uses) ->
        :ok

      true ->
        raise_undefined_function_error!(
          fn_name,
          parent_module,
          local_functions,
          namespace_uses,
          file,
          line
        )
    end
  end

  defp is_compat_function?(fn_name) do
    normalized = String.replace(fn_name, "-", "_")
    normalized in ~w(conj dissoc assoc get assoc_in)
  end

  defp raise_undefined_function_error!(
         fn_name,
         parent_module,
         local_functions,
         namespace_uses,
         file,
         line
       ) do
    normalized = String.replace(fn_name, "-", "_")
    local_list = format_function_list(local_functions)
    uses_list = format_module_list(namespace_uses)

    message = """
    Undefined function: #{fn_name}

    Available options:
    - Local functions: #{local_list}
    - Parent module: qualify with #{inspect(parent_module)}/#{normalized}
    - Imported modules: #{uses_list}
    - Elixir interop: Module/function (e.g., Enum/map)
    - Built-in operators: +, -, *, /, <, >, <=, >=, =, ==, !=, and, or, not
    """

    raise CompileError,
      file: file,
      line: line,
      description: String.trim(message)
  end

  defp format_function_list(functions) do
    case MapSet.to_list(functions) do
      [] -> "(none defined)"
      list -> Enum.join(list, ", ")
    end
  end

  defp format_module_list(modules) do
    case modules do
      [] -> "(none imported)"
      list -> Enum.join(list, ", ")
    end
  end
end
