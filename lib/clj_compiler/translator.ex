defmodule CljCompiler.Translator do
  @built_in_ops ~w(+ - * / < > <= >= = == != and or not)

  defp symbol_to_atom(name) when is_binary(name) do
    name |> String.replace("-", "_") |> String.to_atom()
  end

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

  # Handle ns declaration (no-op at translation level)
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
         {:list, [{:symbol, "def"}, {:symbol, name}, value], _line},
         parent_module,
         attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         file
       ) do
    attr_name = symbol_to_atom(name)
    value_ast = translate_expr(value, parent_module, attr_names, [], [], [], file)

    {:@, [file: to_charlist(file), line: 1], [{attr_name, [], [value_ast]}]}
  end

  # Multi-arity defn: (defn name ([params] body) ([params] body) ...)
  # or with docstring: (defn name "doc" ([params] body) ([params] body) ...)
  defp translate_form(
         {:list, [{:symbol, "defn"}, {:symbol, name} | rest], line},
         parent_module,
         attr_names,
         _param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    function_name = symbol_to_atom(name)

    # Check if this is multi-arity by examining the first element after name
    {docstring, arity_clauses} = extract_docstring_and_clauses(rest)

    case detect_defn_type(arity_clauses) do
      :multi_arity ->
        # Generate multiple def clauses, one for each arity
        arities =
          Enum.map(arity_clauses, fn
            {:list, [{:vector, params} | _body], _line} -> length(params)
            {:list, [{:vector, params} | _body]} -> length(params)
          end)

        # Check for duplicate arities
        if length(arities) != length(Enum.uniq(arities)) do
          raise CompileError,
            file: file,
            line: line,
            description: "Duplicate arity clauses in defn #{name}"
        end

        # Validate that each arity clause has a body
        Enum.each(arity_clauses, fn clause ->
          case clause do
            {:list, [{:vector, _params}], _line} ->
              raise CompileError,
                file: file,
                line: line,
                description:
                  "Invalid arity clause in defn #{name}: each arity must have a body expression"

            {:list, [{:vector, _params}]} ->
              raise CompileError,
                file: file,
                line: line,
                description:
                  "Invalid arity clause in defn #{name}: each arity must have a body expression"

            _ ->
              :ok
          end
        end)

        # Generate a def for each arity clause
        defs =
          Enum.map(arity_clauses, fn clause ->
            {params, body, clause_line} =
              case clause do
                {:list, [{:vector, p} | b], l} -> {p, b, l}
                {:list, [{:vector, p} | b]} -> {p, b, line}
              end

            param_names = Enum.map(params, fn {:symbol, p} -> p end)

            param_vars =
              Enum.map(params, fn {:symbol, p} ->
                {String.to_atom(p), [file: to_charlist(file), line: clause_line], nil}
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

            {:def, [file: to_charlist(file), line: clause_line],
             [
               {function_name, [file: to_charlist(file), line: clause_line], param_vars},
               [do: body_ast]
             ]}
          end)

        # If there's a docstring, prepend it as @doc
        if docstring do
          doc_attr = {:@, [file: to_charlist(file), line: line], [{:doc, [], [docstring]}]}
          [doc_attr | defs]
        else
          defs
        end

      :single_arity ->
        # Handle traditional single-arity defn: (defn name [params] body)
        [{:vector, params} | body] = arity_clauses

        # Validate that single-arity defn has at least one body expression
        if body == [] do
          raise CompileError,
            file: file,
            line: line,
            description:
              "Invalid arity clause in defn #{name}: function must have a body expression"
        end

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

        def_clause =
          {:def, [file: to_charlist(file), line: line],
           [
             {function_name, [file: to_charlist(file), line: line], param_vars},
             [do: body_ast]
           ]}

        # If there's a docstring, prepend it as @doc
        if docstring do
          doc_attr = {:@, [file: to_charlist(file), line: line], [{:doc, [], [docstring]}]}
          [doc_attr, def_clause]
        else
          def_clause
        end
    end
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
         {:tuple, elements, _line},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    [
      translate_expr(
        {:tuple, elements},
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )
    ]
  end

  defp translate_form(
         {:tuple, elements},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    [
      translate_expr(
        {:tuple, elements},
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )
    ]
  end

  defp translate_form(_, _, _, _, _, _, _), do: []

  # Helper to extract optional docstring from defn arguments
  defp extract_docstring_and_clauses([{:string, docstring} | rest]) do
    {docstring, rest}
  end

  defp extract_docstring_and_clauses(clauses) do
    {nil, clauses}
  end

  # Helper to detect if this is single-arity or multi-arity defn
  defp detect_defn_type([{:vector, _params} | _body]) do
    # Single-arity: starts with a vector
    :single_arity
  end

  defp detect_defn_type([{:list, [{:vector, _params} | _body], _line} | _rest]) do
    # Multi-arity: starts with a list containing a vector
    :multi_arity
  end

  defp detect_defn_type([{:list, [{:vector, _params} | _body]} | _rest]) do
    # Multi-arity without line metadata
    :multi_arity
  end

  defp detect_defn_type(_) do
    # Default to single-arity for backward compatibility
    :single_arity
  end

  defp extract_attr_names(forms) do
    forms
    |> Enum.flat_map(fn
      {:list, [{:symbol, "def"}, {:symbol, name}, _], _line} -> [name]
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
         forms,
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       )
       when is_list(forms) and length(forms) > 1 do
    translated_forms =
      Enum.map(forms, fn form ->
        translate_expr(
          form,
          parent_module,
          attr_names,
          param_names,
          local_functions,
          namespace_uses,
          file
        )
      end)
      |> Enum.filter(fn expr -> expr != nil end)

    case translated_forms do
      [] -> nil
      [single] -> single
      multiple -> {:__block__, [], multiple}
    end
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
         {:map, elements},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    translate_map(
      elements,
      parent_module,
      attr_names,
      param_names,
      local_functions,
      namespace_uses,
      file
    )
  end

  defp translate_expr(
         {:map, elements, _line},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    translate_map(
      elements,
      parent_module,
      attr_names,
      param_names,
      local_functions,
      namespace_uses,
      file
    )
  end

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

  defp translate_map(
         elements,
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    key_value_pairs =
      Enum.chunk_every(elements, 2)
      |> Enum.map(fn [key, value] ->
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

    quote do
      %{unquote_splicing(key_value_pairs)}
    end
  end

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
         {:symbol, "nil"},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ),
       do: nil

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
         {:tuple, elements},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    translate_tuple(
      elements,
      parent_module,
      attr_names,
      param_names,
      local_functions,
      namespace_uses,
      file
    )
  end

  defp translate_expr(
         {:tuple, elements, _line},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    translate_tuple(
      elements,
      parent_module,
      attr_names,
      param_names,
      local_functions,
      namespace_uses,
      file
    )
  end

  defp translate_tuple(
         elements,
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    translated_elements =
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

    {:{}, [], translated_elements}
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
         {:list, [{:symbol, "throw"}, exception]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    exception_ast =
      translate_expr(
        exception,
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )

    quote do
      raise(unquote(exception_ast))
    end
  end

  defp translate_expr(
         {:list, [{:symbol, "comment"} | _args]},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ),
       do: nil

  defp translate_expr(
         {:list, [{:symbol, "try"}, body | clauses]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    {rescue_clauses, after_clause, body_ast} =
      process_try_clauses(
        clauses,
        body,
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )

    if after_clause != nil and not Enum.empty?(rescue_clauses) do
      quote do
        try do
          unquote(body_ast)
        rescue
          unquote(rescue_clauses)
        after
          unquote(after_clause)
        end
      end
    else
      if after_clause != nil do
        quote do
          try do
            unquote(body_ast)
          after
            unquote(after_clause)
          end
        end
      else
        if not Enum.empty?(rescue_clauses) do
          quote do
            try do
              unquote(body_ast)
            rescue
              unquote(rescue_clauses)
            end
          end
        else
          quote do
            unquote(body_ast)
          end
        end
      end
    end
  end

  defp process_try_clauses(
         clauses,
         body,
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    {rescue_clauses, after_clause} =
      Enum.reduce(clauses, {[], nil}, fn
        clause, {rescue_acc, after_acc} ->
          case clause do
            # Handle catch with exception type and var in list: (catch [ExceptionType var-name] body...)
            {:list,
             [
               {:symbol, "catch"},
               {:list, [{:symbol, exception_type}, {:symbol, var_name}]} | catch_body
             ]} ->
              rescue_clause =
                process_catch_clause(
                  exception_type,
                  var_name,
                  catch_body,
                  parent_module,
                  attr_names,
                  param_names,
                  local_functions,
                  namespace_uses,
                  file
                )

              {[rescue_clause | rescue_acc], after_acc}

            # Handle catch with exception type and var as separate args: (catch ExceptionType var-name body...)
            {:list,
             [{:symbol, "catch"}, {:symbol, exception_type}, {:symbol, var_name} | catch_body]} ->
              rescue_clause =
                process_catch_clause(
                  exception_type,
                  var_name,
                  catch_body,
                  parent_module,
                  attr_names,
                  param_names,
                  local_functions,
                  namespace_uses,
                  file
                )

              {[rescue_clause | rescue_acc], after_acc}

            {:list, [{:symbol, "finally"} | finally_body]} ->
              after_ast =
                translate_body(
                  finally_body,
                  parent_module,
                  attr_names,
                  param_names,
                  local_functions,
                  namespace_uses,
                  file
                )

              {rescue_acc, after_ast}

            _ ->
              {rescue_acc, after_acc}
          end
      end)

    body_ast =
      translate_expr(
        body,
        parent_module,
        attr_names,
        param_names,
        local_functions,
        namespace_uses,
        file
      )

    {Enum.reverse(rescue_clauses), after_clause, body_ast}
  end

  defp process_catch_clause(
         exception_type,
         var_name,
         catch_body,
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    var_ast = {String.to_atom(var_name), [], Elixir}
    exception_module = {:__aliases__, [alias: false], [String.to_atom(exception_type)]}

    catch_ast =
      translate_body(
        catch_body,
        parent_module,
        attr_names,
        param_names ++ [var_name],
        local_functions,
        namespace_uses,
        file
      )

    # Generate proper Elixir rescue clause structure
    {:->, [],
     [
       [
         {:in, [context: Elixir, imports: [{2, Kernel}]], [var_ast, exception_module]}
       ],
       catch_ast
     ]}
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

  # Handle calling an anonymous function directly, e.g., ((fn [x] (* x 2)) 5)
  defp translate_expr(
         {:list, [{:list, [{:symbol, "fn"} | _]} = fn_expr | args]},
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

  # Handle calling the result of a function call, e.g., ((make_adder 5) 3)
  defp translate_expr(
         {:list, [{:list, [{:symbol, _} | _]} = fn_expr | args]},
         parent_module,
         attr_names,
         param_names,
         local_functions,
         namespace_uses,
         file
       ) do
    # Translate the function expression (a function call that returns a function)
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

    # Generate function call syntax
    quote do
      unquote(fn_ast).(unquote_splicing(translated_args))
    end
  end

  # Handle Erlang module function calls: (:module/function args...)
  defp translate_expr(
         {:list, [{:keyword, module_name}, {:symbol, "/" <> function_name} | args]},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ) do
    # Convert module name keyword to atom (e.g., :erlang -> :erlang)
    module_atom = module_name

    # Convert function name (remove leading / and convert hyphens to underscores)
    function_atom =
      function_name
      |> String.replace("-", "_")
      |> String.to_atom()

    # Translate arguments from Clojure data structures to Elixir AST
    translated_args = Enum.map(args, &translate_erlang_arg/1)

    quote do
      unquote(module_atom).unquote(function_atom)(unquote_splicing(translated_args))
    end
  end

  # Handle Erlang module function calls with line info: (:module/function args...)
  defp translate_expr(
         {:list, [{:keyword, module_name}, {:symbol, "/" <> function_name} | args], _line},
         _parent_module,
         _attr_names,
         _param_names,
         _local_functions,
         _namespace_uses,
         _file
       ) do
    # Convert module name keyword to atom (e.g., :erlang -> :erlang)
    module_atom = module_name

    # Convert function name (remove leading / and convert hyphens to underscores)
    function_atom =
      function_name
      |> String.replace("-", "_")
      |> String.to_atom()

    # Translate arguments from Clojure data structures to Elixir AST
    translated_args = Enum.map(args, &translate_erlang_arg/1)

    quote do
      unquote(module_atom).unquote(function_atom)(unquote_splicing(translated_args))
    end
  end

  # Helper to translate Clojure data structures to Elixir AST for Erlang calls
  defp translate_erlang_arg({:vector, elements}) do
    # Clojure vector -> Elixir list
    translated_elements = Enum.map(elements, &translate_erlang_arg/1)

    quote do
      [unquote_splicing(translated_elements)]
    end
  end

  defp translate_erlang_arg({:number, value}), do: value
  defp translate_erlang_arg({:string, value}), do: value
  defp translate_erlang_arg({:keyword, value}), do: value
  defp translate_erlang_arg({:symbol, name}), do: {String.to_atom(name), [], Elixir}

  defp translate_erlang_arg({:map, elements}) do
    # Translate map elements to key-value pairs
    key_value_pairs =
      Enum.chunk_every(elements, 2)
      |> Enum.map(fn [k, v] ->
        key_ast = translate_erlang_arg(k)
        value_ast = translate_erlang_arg(v)
        {key_ast, value_ast}
      end)

    {:%{}, [], key_value_pairs}
  end

  defp translate_erlang_arg(arg), do: arg

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

    build_function_call_ast(
      fn_name,
      translated_args,
      parent_module,
      attr_names,
      param_names,
      local_functions,
      namespace_uses,
      file,
      true
    )
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

    build_function_call_ast(
      fn_name,
      translated_args,
      parent_module,
      attr_names,
      param_names,
      local_functions,
      namespace_uses,
      file,
      true
    )
  end

  defp build_function_call_ast(
         fn_name,
         translated_args,
         _parent_module,
         _attr_names,
         param_names,
         _local_functions,
         _namespace_uses,
         _file,
         include_exception_constructor
       ) do
    original_fn_name = fn_name
    fn_name = String.replace(fn_name, "-", "_")

    if String.contains?(fn_name, "/") and (not include_exception_constructor or fn_name != "/") do
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

        include_exception_constructor and is_exception_constructor?(fn_name) ->
          exception_module = String.to_atom("Elixir." <> String.replace(fn_name, ".", ""))

          quote do
            unquote(exception_module).new(unquote_splicing(translated_args))
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
      {:list, [{:symbol, "defn"}, {:symbol, name} | _rest], _line} ->
        [String.replace(name, "-", "_")]

      {:list, [{:symbol, "defn"}, {:symbol, name} | _rest]} ->
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

      fn_name in ~w(str if let fn try throw comment) or is_exception_constructor?(fn_name) ->
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
    normalized in ~w(conj dissoc assoc get assoc_in nil?)
  end

  defp is_exception_constructor?(fn_name) do
    String.ends_with?(fn_name, ".") and fn_name != "/" and fn_name != "*" and fn_name != "+" and
      fn_name != "-"
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
