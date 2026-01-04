defmodule CljCompiler do
  defmacro __using__(opts) do
    dirs =
      case Keyword.fetch!(opts, :dir) do
        dir when is_binary(dir) -> [dir]
        dirs when is_list(dirs) -> dirs
      end

    quote do
      @clj_dirs unquote(dirs)
      @before_compile CljCompiler
    end
  end

  defmacro __before_compile__(env) do
    dirs = Module.get_attribute(env.module, :clj_dirs)
    parent_module = env.module

    clj_files =
      Enum.flat_map(dirs, fn dir ->
        Path.wildcard("#{dir}/**/*.clj")
      end)

    modules =
      Enum.flat_map(clj_files, fn file ->
        Module.put_attribute(env.module, :external_resource, file)
        content = File.read!(file)
        compile_file(content, parent_module, file)
      end)

    quote do
      (unquote_splicing(modules))
    end
  end

  defp compile_file(content, parent_module, file) do
    ast = CljCompiler.Reader.parse(content, file)
    extract_modules(ast, parent_module, file)
  end

  defp extract_modules(forms, parent_module, file) do
    {{ns, use_clauses}, functions} = extract_namespace_and_functions(forms, file)
    module_name = namespace_to_module(ns, parent_module)
    translated_functions = CljCompiler.Translator.translate(functions, parent_module, file)
    use_asts = generate_use_asts(use_clauses)

    module_ast =
      quote do
        defmodule unquote(module_name) do
          (unquote_splicing(use_asts))
          (unquote_splicing(translated_functions))
        end
      end

    [module_ast]
  end

  defp generate_use_asts(use_clauses) do
    Enum.map(use_clauses, fn {module_name, opts} ->
      module_alias = Module.concat([module_name])
      if opts == [] do
        quote do
          use unquote(module_alias)
        end
      else
        quote do
          use unquote(module_alias), unquote(opts)
        end
      end
    end)
  end

  defp extract_namespace_and_functions(forms, file) do
    case extract_ns_form(forms) do
      {{ns, use_clauses}, rest} ->
        {{ns, use_clauses}, rest}
      :error ->
        raise CompileError,
          file: file,
          line: 1,
          description: "Missing namespace declaration (ns ...) at the beginning of the file"
    end
  end

  defp extract_ns_form([{:list, ns_elements, _line} | rest]) do
    case ns_elements do
      [{:symbol, "ns"}, {:symbol, ns} | clauses] ->
        use_clauses = extract_use_clauses(clauses)
        {{ns, use_clauses}, rest}
      _ ->
        extract_ns_form(rest)
    end
  end

  defp extract_ns_form([{:list, ns_elements} | rest]) do
    case ns_elements do
      [{:symbol, "ns"}, {:symbol, ns} | clauses] ->
        use_clauses = extract_use_clauses(clauses)
        {{ns, use_clauses}, rest}
      _ ->
        extract_ns_form(rest)
    end
  end

  defp extract_ns_form([_ | rest]) do
    extract_ns_form(rest)
  end

  defp extract_ns_form([]) do
    :error
  end

  defp extract_use_clauses(clauses) do
    Enum.flat_map(clauses, fn
      {:list, [{:keyword, :use} | modules]} ->
        Enum.map(modules, &parse_use_module/1)
      _ ->
        []
    end)
  end

  defp parse_use_module({:vector, [{:symbol, module_name}]}) do
    {module_name, []}
  end

  defp parse_use_module({:vector, [{:symbol, module_name}, {:keyword, atom_opt}]}) do
    {module_name, atom_opt}
  end

  defp parse_use_module({:vector, [{:symbol, module_name}, {:map, opts}]}) do
    parsed_opts = parse_use_options(opts)
    {module_name, parsed_opts}
  end

  defp parse_use_options(opts) do
    opts
    |> Enum.chunk_every(2)
    |> Enum.map(fn [{:keyword, key}, value] ->
      {key, translate_use_option_value(value)}
    end)
  end

  defp translate_use_option_value({:symbol, "true"}), do: true
  defp translate_use_option_value({:symbol, "false"}), do: false
  defp translate_use_option_value({:number, n}), do: n
  defp translate_use_option_value({:string, s}), do: s
  defp translate_use_option_value({:keyword, k}), do: k
  defp translate_use_option_value({:vector, elements}) do
    Enum.map(elements, &translate_use_option_value/1)
  end



  defp namespace_to_module(ns, parent_module) do
    parts =
      ns
      |> String.split(".")
      |> Enum.map(fn part ->
        part
        |> String.split("-")
        |> Enum.map(&String.capitalize/1)
        |> Enum.join("")
      end)

    Module.concat([parent_module | parts])
  end
end
