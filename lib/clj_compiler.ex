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
    {ns, functions} = extract_namespace_and_functions(forms, file)
    module_name = namespace_to_module(ns, parent_module)
    translated_functions = CljCompiler.Translator.translate(functions, parent_module)

    module_ast =
      quote do
        defmodule unquote(module_name) do
          (unquote_splicing(translated_functions))
        end
      end

    [module_ast]
  end

  defp extract_namespace_and_functions(forms, file) do
    case extract_ns_form(forms) do
      {ns_form, rest} ->
        ns = extract_namespace(ns_form)
        {ns, rest}
      :error ->
        raise CompileError,
          file: file,
          line: 1,
          description: "Missing namespace declaration (ns ...) at the beginning of the file"
    end
  end

  defp extract_ns_form([{:list, [{:symbol, "ns"}, {:symbol, ns}]} | rest]) do
    {ns, rest}
  end

  defp extract_ns_form([_ | rest]) do
    extract_ns_form(rest)
  end

  defp extract_ns_form([]) do
    :error
  end

  defp extract_namespace(ns) when is_binary(ns), do: ns

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
