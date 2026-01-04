# LLM-Assisted

defmodule CljCompiler do
  defmacro __using__(_opts) do
    quote do
      @before_compile CljCompiler
    end
  end

  defmacro __before_compile__(env) do
    module_name = env.module |> Atom.to_string()
    clj_file = "test/fixtures/#{module_name}.clj"

    Module.put_attribute(env.module, :external_resource, clj_file)

    content = File.read!(clj_file)

    ast = CljCompiler.Reader.parse(content)
    functions = CljCompiler.Translator.translate(ast)

    functions
  end
end
