defmodule CljCompilerTest.TestUseModule do
  defmacro __using__(_opts) do
    quote do
      def test_function do
        "from parent"
      end
    end
  end
end

defmodule CljCompilerTest.TestUseModuleWithOptions do
  defmacro __using__(opts) do
    quote do
      def configured do
        unquote(Keyword.get(opts, :enabled, false))
      end
    end
  end
end

defmodule CljCompilerTest.TestUseModuleA do
  defmacro __using__(_opts) do
    quote do
      def from_a, do: true
    end
  end
end

defmodule CljCompilerTest.TestUseModuleB do
  defmacro __using__(_opts) do
    quote do
      def from_b, do: true

      def has_multiple do
        from_a() and from_b()
      end
    end
  end
end

defmodule CljCompilerTest.TestUseModuleWithAtom do
  defmacro __using__(opt) when is_atom(opt) do
    quote do
      def atom_option do
        unquote(opt)
      end
    end
  end
end
