defmodule CljCompiler do
  defmacro __using__(opts) do
    dir = Keyword.fetch!(opts, :dir)

    quote do
      @clj_dir unquote(dir)
      @before_compile CljCompiler
    end
  end

  defmacro __before_compile__(env) do
    dir = Module.get_attribute(env.module, :clj_dir)
    parent_module = env.module
    clj_files = Path.wildcard("#{dir}/**/*.clj")

    modules =
      Enum.flat_map(clj_files, fn file ->
        Module.put_attribute(env.module, :external_resource, file)
        content = File.read!(file)
        compile_file(content, parent_module)
      end)

    quote do
      (unquote_splicing(modules))
    end
  end

  defp compile_file(content, parent_module) do
    ast = CljCompiler.Reader.parse(content)
    extract_modules(ast, parent_module)
  end

  defp extract_modules(forms, parent_module) do
    {ns, functions} = extract_namespace_and_functions(forms)
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

  defp extract_namespace_and_functions(forms) do
    {ns_form, rest} = extract_ns_form(forms)
    ns = extract_namespace(ns_form)
    {ns, rest}
  end

  defp extract_ns_form([{:list, [{:symbol, "ns"}, {:symbol, ns}]} | rest]) do
    {ns, rest}
  end

  defp extract_ns_form([_ | rest]) do
    extract_ns_form(rest)
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
