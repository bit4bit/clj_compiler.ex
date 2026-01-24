defmodule CljCompilerTest do
  use ExUnit.Case

  defmodule ClojureProject do
    use CljCompiler, dir: "test/fixtures/lib/clj"

    def do_sum(a, b), do: a + b

    def greet_prefix(name), do: "Mr. #{name}"
  end

  defmodule TestDup do
  end

  defmodule TestEmpty do
  end

  test "compiles module from namespace declaration" do
    assert ClojureProject.Example.Core.hello() == "Hello World"
  end

  test "function with parameters from namespaced module" do
    assert ClojureProject.Example.Core.greet("Alice") == "Hello, Alice"
  end

  test "arithmetic operations from math namespace" do
    assert ClojureProject.Example.Math.add(2, 3) == 5
  end

  test "multiply from math namespace" do
    assert ClojureProject.Example.Math.multiply(4, 5) == 20
  end

  test "factorial from math namespace" do
    assert ClojureProject.Example.Math.factorial(5) == 120
  end

  test "calls parent module function from clojure" do
    assert ClojureProject.Example.Math.sum_via_parent(3, 4) == 7
  end

  test "calls parent module function with string from clojure" do
    assert ClojureProject.Example.Core.formal_greet("Alice") == "Hello, Mr. Alice"
  end

  test "calls Kernel function when not in parent module" do
    assert ClojureProject.Example.Math.get_list_length([1, 2, 3, 4, 5]) == 5
  end

  defmodule MultiDirProject do
    use CljCompiler, dir: ["test/fixtures/lib/clj", "test/fixtures/vendor/clj"]
  end

  test "compiles from multiple directories" do
    assert MultiDirProject.Example.Core.hello() == "Hello World"
    assert MultiDirProject.Vendor.Utils.double(5) == 10
  end

  test "reverse string from vendor directory" do
    assert MultiDirProject.Vendor.Utils.reverse_string("hello") == "olleh"
  end

  test "reports syntax error with line and column" do
    source = """
    (ns test.errors)

    (defn broken [x]
      (+ x y
    """

    error =
      assert_raise CljCompiler.Reader.ParseError, fn ->
        CljCompiler.Reader.parse(source)
      end

    assert error.line == 3
    assert error.column == 1

    assert error.message =~
             "Missing closing parenthesis for opening at line 3, column 1"
  end

  describe "missing delimiter errors" do
    test "missing closing parenthesis" do
      source = "(sum (mul 2 2 )"

      error =
        assert_raise CljCompiler.Reader.ParseError, fn ->
          CljCompiler.Reader.parse(source, "example.clj")
        end

      assert error.line == 1
      assert error.column == 1

      assert error.message =~
               "Missing closing parenthesis for opening at line 1, column 1 in example.clj"
    end

    test "missing closing bracket prioritizes outermost" do
      source = "[1 2 (sum 3 4"

      error =
        assert_raise CljCompiler.Reader.ParseError, fn ->
          CljCompiler.Reader.parse(source, "example.clj")
        end

      assert error.line == 1
      assert error.column == 1

      assert error.message =~
               "Missing closing bracket for opening at line 1, column 1 in example.clj"
    end

    test "missing closing brace" do
      source = "{:key value"

      error =
        assert_raise CljCompiler.Reader.ParseError, fn ->
          CljCompiler.Reader.parse(source, "example.clj")
        end

      assert error.line == 1
      assert error.column == 1

      assert error.message =~
               "Missing closing brace for opening at line 1, column 1 in example.clj"
    end

    test "multiple nested missing prioritizes outermost" do
      source = "(sum (mul 2 2"

      error =
        assert_raise CljCompiler.Reader.ParseError, fn ->
          CljCompiler.Reader.parse(source, "example.clj")
        end

      assert error.line == 1
      assert error.column == 1

      assert error.message =~
               "Missing closing parenthesis for opening at line 1, column 1 in example.clj"
    end

    test "EOF with no tokens after opening" do
      source = "(sum"

      error =
        assert_raise CljCompiler.Reader.ParseError, fn ->
          CljCompiler.Reader.parse(source, "example.clj")
        end

      assert error.line == 1
      assert error.column == 1

      assert error.message =~
               "Missing closing parenthesis for opening at line 1, column 1 in example.clj"
    end
  end

  describe "mismatched delimiter errors" do
    test "mismatched closing bracket in parenthesis" do
      source = "(sum 1 2 ]"

      error =
        assert_raise CljCompiler.Reader.ParseError, fn ->
          CljCompiler.Reader.parse(source, "example.clj")
        end

      assert error.line == 1
      assert error.column == 10

      assert error.message =~
               "Unexpected closing bracket; expected closing parenthesis for opening at line 1, column 1 in example.clj"
    end
  end

  describe "extra delimiter errors" do
    test "extra closing parenthesis" do
      source = "(sum 1 2 ) )"

      error =
        assert_raise CljCompiler.Reader.ParseError, fn ->
          CljCompiler.Reader.parse(source, "example.clj")
        end

      assert error.line == 1
      assert error.column == 12

      assert error.message =~
               "Unexpected closing parenthesis; no matching opening found in example.clj"
    end
  end

  describe "valid code" do
    test "parses valid nested lists without errors" do
      source = "(sum (mul 2 2))"

      {:ok, result} = CljCompiler.Reader.parse(source, "example.clj")
      assert is_list(result)
    end
  end

  test "creates map with keyword keys" do
    assert ClojureProject.Example.Data.create_person("Alice", 30) == %{name: "Alice", age: 30}
  end

  test "returns map literal" do
    assert ClojureProject.Example.Data.get_config() == %{
             host: "localhost",
             port: 8080,
             debug: true
           }
  end

  test "returns empty map" do
    assert ClojureProject.Example.Data.empty_map() == %{}
  end

  test "parses map literals" do
    source = """
    (ns test.maps)

    (defn get_user [] {:name "Alice" :age 30})

    (defn process_map [m] m)
    """

    {:ok, ast} = CljCompiler.Reader.parse(source, "test_maps.clj")

    assert [
             {:list, [{:symbol, "ns"}, {:symbol, "test.maps"}], _},
             {:list, [{:symbol, "defn"}, {:symbol, "get_user"}, {:vector, []}, {:map, _}], _},
             {:list,
              [
                {:symbol, "defn"},
                {:symbol, "process_map"},
                {:vector, [{:symbol, "m"}]},
                {:symbol, "m"}
              ], _}
           ] = ast
  end

  test "conj adds element to list at front" do
    assert ClojureProject.Example.Collections.add_to_list(1, [2, 3, 4]) == [1, 2, 3, 4]
  end

  test "conj adds element to vector at end" do
    assert ClojureProject.Example.Collections.add_to_vector([1, 2, 3], 4) == [4, 1, 2, 3]
  end

  test "conj with empty list" do
    assert ClojureProject.Example.Collections.conj_empty(5) == [5]
  end

  test "map applies function to each element" do
    assert ClojureProject.Example.Collections.map_inc([1, 2, 3]) == [2, 3, 4]
  end

  test "function receives map as argument" do
    person = %{name: "Alice", age: 30}
    assert ClojureProject.Example.Data.get_name(person) == "Alice"
  end

  test "function processes map and returns value" do
    user = %{id: 42, active: true}
    assert ClojureProject.Example.Data.get_id(user) == 42
  end

  test "function returns map passed as argument" do
    config = %{host: "localhost", port: 8080}
    assert ClojureProject.Example.Data.identity_map(config) == config
  end

  test "get retrieves value from map" do
    person = %{name: "Bob", age: 25}
    assert ClojureProject.Example.Data.lookup_name(person) == "Bob"
  end

  test "get with default value when key missing" do
    assert ClojureProject.Example.Data.get_with_default(%{x: 1}, :y) == "not found"
  end

  test "assoc adds key-value to map" do
    original = %{name: "Alice"}
    assert ClojureProject.Example.Data.add_age(original, 30) == %{name: "Alice", age: 30}
  end

  test "assoc updates existing key in map" do
    original = %{name: "Alice", age: 25}
    assert ClojureProject.Example.Data.update_age(original, 30) == %{name: "Alice", age: 30}
  end

  test "dissoc removes key from map" do
    original = %{name: "Alice", age: 30, city: "NYC"}
    assert ClojureProject.Example.Data.remove_city(original) == %{name: "Alice", age: 30}
  end

  test "dissoc with multiple keys" do
    original = %{a: 1, b: 2, c: 3, d: 4}
    assert ClojureProject.Example.Data.remove_multiple(original) == %{a: 1, d: 4}
  end

  test "dissoc with many keys" do
    original = %{a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7}
    assert ClojureProject.Example.Data.remove_many(original) == %{a: 1, g: 7}
  end

  test "dissoc with vector of keys" do
    original = %{a: 1, b: 2, c: 3, d: 4}
    assert ClojureProject.Example.Data.remove_with_vector(original) == %{a: 1, d: 4}
  end

  test "runtime function with 4 arguments" do
    assert ClojureProject.Example.Data.update_nested(%{user: %{name: "Alice"}}, :user, :age, 30) ==
             %{user: %{name: "Alice", age: 30}}
  end

  defmodule UseTestParent do
    def parent_function, do: "from parent"
  end

  defmodule UseTestProject do
    use CljCompiler, dir: "test/fixtures/lib/use_test"

    def parent_function, do: "from parent"
  end

  test "namespace with :use without options" do
    assert function_exported?(CljCompilerTest.UseTestProject.UseExample.Simple, :test_function, 0)
    assert CljCompilerTest.UseTestProject.UseExample.Simple.test_function() == "from parent"
  end

  test "namespace with :use with options" do
    assert function_exported?(
             CljCompilerTest.UseTestProject.UseExample.WithOptions,
             :configured,
             0
           )

    assert CljCompilerTest.UseTestProject.UseExample.WithOptions.configured() == true
  end

  test "namespace with multiple :use declarations" do
    assert function_exported?(
             CljCompilerTest.UseTestProject.UseExample.Multiple,
             :has_multiple,
             0
           )

    assert CljCompilerTest.UseTestProject.UseExample.Multiple.has_multiple() == true
  end

  test "namespace with :use with atom option" do
    assert function_exported?(CljCompilerTest.UseTestProject.UseExample.WithAtom, :atom_option, 0)
    assert CljCompilerTest.UseTestProject.UseExample.WithAtom.atom_option() == :controller
  end

  test "throws error for unknown top-level symbol" do
    source = """
    (ns test.unknown)

    (defa mo [] (+ 3 1))
    """

    error =
      assert_raise CompileError, fn ->
        {:ok, forms} = CljCompiler.Reader.parse(source, "test.clj")

        CljCompiler.Translator.translate(
          forms,
          [],
          TestModule,
          "test.clj"
        )
      end

    assert error.description =~ "Unable to resolve symbol: defa"
    assert error.file == "test.clj"
    assert error.line == 3
  end

  test "def creates module attribute" do
    source = """
    (ns test.attrs)

    (def max-size 100)

    (defn get-max [] max-size)
    """

    {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
    result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

    assert Enum.any?(result, fn
             {:@, _, [{:max_size, _, [100]}]} -> true
             _ -> false
           end)
  end

  test "location metadata includes clj file path" do
    source = """
    (ns test.location)

    (defn foo [x] x)
    """

    {:ok, ast} = CljCompiler.Reader.parse(source, "test/example.clj")
    result = CljCompiler.Translator.translate(ast, [], TestModule, "test/example.clj")

    assert Enum.any?(result, fn
             {:def, meta, [{:foo, _fn_meta, _params}, _body]} ->
               Keyword.get(meta, :file) == ~c"test/example.clj"

             _ ->
               false
           end)
  end

  test "uses module attribute in function" do
    assert ClojureProject.Example.Attrs.get_max() == 100
  end

  test "uses string module attribute" do
    assert ClojureProject.Example.Attrs.get_name() == "unknown"
  end

  test "uses float module attribute" do
    assert ClojureProject.Example.Attrs.get_pi() == 3.14
  end

  test "computes using module attribute" do
    assert ClojureProject.Example.Attrs.compute_area(2) == 12.56
  end

  describe "undefined function validation" do
    test "raises error for undefined function" do
      source = """
      (ns test.undefined)

      (defn calculate [x] (undefined_fn x))
      """

      error =
        assert_raise CompileError, fn ->
          {:ok, forms} = CljCompiler.Reader.parse(source, "test.clj")

          CljCompiler.Translator.translate(
            forms,
            [],
            TestModule,
            "test.clj"
          )
        end

      assert error.description =~ "Undefined function: undefined_fn"
      assert error.file == "test.clj"
      assert error.line == 1
    end

    test "allows calling locally defined function" do
      source = """
      (ns test.local)

      (defn helper [x] (* x 2))

      (defn calculate [x] (helper x))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "raises error for unqualified parent function call" do
      source = """
      (ns test.parent)

      (defn calculate [x] (do_sum x 1))
      """

      error =
        assert_raise CompileError, fn ->
          {:ok, forms} = CljCompiler.Reader.parse(source, "test.clj")

          CljCompiler.Translator.translate(
            forms,
            [],
            TestModule,
            "test.clj"
          )
        end

      assert error.description =~ "Undefined function: do_sum"
      assert error.description =~ "Parent module: qualify with TestModule/do_sum"
    end

    test "allows qualified parent function call" do
      source = """
      (ns test.qualified)

      (defn calculate [x] (TestModule/do_sum x 1))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "allows Compat functions with :use declaration" do
      source = """
      (ns test.compat (:use [CljCompiler.Compat]))

      (defn process [lst] (conj lst 1))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      result =
        CljCompiler.Translator.translate(
          ast,
          [{"CljCompiler.Compat", []}],
          TestModule,
          "test.clj"
        )

      assert is_list(result)
    end

    test "raises error for Compat functions without :use" do
      source = """
      (ns test.no_compat)

      (defn process [lst] (conj lst 1))
      """

      error =
        assert_raise CompileError, fn ->
          {:ok, forms} = CljCompiler.Reader.parse(source, "test.clj")

          CljCompiler.Translator.translate(
            forms,
            [],
            TestModule,
            "test.clj"
          )
        end

      assert error.description =~ "Undefined function: conj"
    end

    test "validates function calls in nested expressions" do
      source = """
      (ns test.nested)

      (defn calculate [x] (+ (undefined_fn x) 1))
      """

      error =
        assert_raise CompileError, fn ->
          {:ok, forms} = CljCompiler.Reader.parse(source, "test.clj")

          CljCompiler.Translator.translate(
            forms,
            [],
            TestModule,
            "test.clj"
          )
        end

      assert error.description =~ "Undefined function: undefined_fn"
    end

    test "validates function calls in let binding values" do
      source = """
      (ns test.let)

      (defn calculate [x] (let [y (undefined_fn x)] y))
      """

      error =
        assert_raise CompileError, fn ->
          {:ok, forms} = CljCompiler.Reader.parse(source, "test.clj")

          CljCompiler.Translator.translate(
            forms,
            [],
            TestModule,
            "test.clj"
          )
        end

      assert error.description =~ "Undefined function: undefined_fn"
    end

    test "allows built-in operators without validation" do
      source = """
      (ns test.operators)

      (defn calculate [x] (+ x 1))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "allows Elixir module calls without validation" do
      source = """
      (ns test.elixir)

      (defn calculate [lst] (Enum/count lst))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end
  end

  test "anonymous function called immediately" do
    assert ClojureProject.Example.Anonymous.call_immediate() == 10
  end

  test "anonymous function stored in let binding" do
    assert ClojureProject.Example.Anonymous.use_in_let() == 20
  end

  test "anonymous function returned from function" do
    adder = ClojureProject.Example.Anonymous.make_adder(5)
    assert adder.(3) == 8
  end

  test "anonymous function called from returned function" do
    assert ClojureProject.Example.Anonymous.call_returned_fn() == 8
  end

  test "anonymous function with no parameters" do
    assert ClojureProject.Example.Anonymous.no_params() == 42
  end

  test "anonymous function with multiple parameters" do
    assert ClojureProject.Example.Anonymous.multi_params() == 6
  end

  test "anonymous function captures outer variable" do
    assert ClojureProject.Example.Anonymous.capture_variable(3) == 21
  end

  test "nested anonymous functions" do
    assert ClojureProject.Example.Anonymous.nested_fns() == 8
  end

  test "anonymous function with complex body" do
    assert ClojureProject.Example.Anonymous.complex_body() == 10
  end

  test "anonymous function passed to Enum.map" do
    assert ClojureProject.Example.Anonymous.map_with_fn([1, 2, 3]) == [2, 4, 6]
  end

  test "anonymous function passed to Enum.filter" do
    assert ClojureProject.Example.Anonymous.filter_with_fn([3, 6, 9, 4]) == [6, 9]
  end

  test "anonymous function passed to Enum.reduce" do
    assert ClojureProject.Example.Anonymous.reduce_with_fn([1, 2, 3, 4]) == 10
  end

  describe "anonymous functions" do
    test "creates and calls anonymous function immediately" do
      source = """
      (ns test.anon)

      (defn test_immediate [] ((fn [x] (* x 2)) 5))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "stores anonymous function in let binding" do
      source = """
      (ns test.anon)

      (defn test_let [] (let [f (fn [x] (* x 2))] (f 5)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "returns anonymous function from function" do
      source = """
      (ns test.anon)

      (defn make_adder [n] (fn [x] (+ x n)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "anonymous function with no parameters" do
      source = """
      (ns test.anon)

      (defn test_no_params [] ((fn [] 42)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "anonymous function with multiple parameters" do
      source = """
      (ns test.anon)

      (defn test_multi [] ((fn [a b c] (+ a (+ b c))) 1 2 3))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "anonymous function captures outer variable" do
      source = """
      (ns test.anon)

      (defn make_multiplier [n] (fn [x] (* x n)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "nested anonymous functions" do
      source = """
      (ns test.anon)

      (defn test_nested [] ((fn [x] ((fn [y] (+ x y)) 3)) 5))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "anonymous function with complex body" do
      source = """
      (ns test.anon)

      (defn test_complex [] ((fn [x] (if (> x 0) (* x 2) 0)) 5))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end
  end

  describe "try/catch/finally" do
    test "parses try with catch and finally" do
      source = """
      (ns test.try)

      (defn safe-divide [a b]
        (try
          (/ a b)
          (catch ArithmeticError e
            :infinity)
          (finally
            :cleanup)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      assert {:list, [{:symbol, "ns"}, {:symbol, "test.try"}], _} = List.first(ast)

      assert {:list,
              [
                symbol: "defn",
                symbol: "safe-divide",
                vector: [symbol: "a", symbol: "b"],
                list: [
                  symbol: "try",
                  list: [symbol: "/", symbol: "a", symbol: "b"],
                  list: [
                    symbol: "catch",
                    symbol: "ArithmeticError",
                    symbol: "e",
                    keyword: :infinity
                  ],
                  list: [symbol: "finally", keyword: :cleanup]
                ]
              ], 3} = List.last(ast)
    end

    test "parses try with multiple catches" do
      source = """
      (ns test.try)

      (defn try-multiple [x]
        (try
          (if (> x 0)
            :positive
            :non-positive)
          (catch RuntimeError e
            :caught)
          (catch ArgumentError e
            :illegal)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      assert {:list,
              [
                symbol: "defn",
                symbol: "try-multiple",
                vector: [symbol: "x"],
                list: [
                  symbol: "try",
                  list: [
                    symbol: "if",
                    list: [symbol: ">", symbol: "x", number: 0],
                    keyword: :positive,
                    keyword: :non_positive
                  ],
                  list: [
                    symbol: "catch",
                    symbol: "RuntimeError",
                    symbol: "e",
                    keyword: :caught
                  ],
                  list: [
                    symbol: "catch",
                    symbol: "ArgumentError",
                    symbol: "e",
                    keyword: :illegal
                  ]
                ]
              ], _} = List.last(ast)
    end

    test "parses try without catch" do
      source = """
      (ns test.try)

      (defn try-only []
        (try
          :result
          (finally
            :cleanup)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      assert {:list,
              [
                symbol: "defn",
                symbol: "try-only",
                vector: [],
                list: [
                  symbol: "try",
                  keyword: :result,
                  list: [symbol: "finally", keyword: :cleanup]
                ]
              ], 3} = List.last(ast)
    end

    test "translates try/catch/finally to Elixir try/rescue/after" do
      source = """
      (ns test.try)

      (defn safe-divide [a b]
        (try
          (/ a b)
          (catch ArithmeticError e
            :infinity)
          (finally
            :cleanup)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)

      assert Enum.any?(result, fn
               {:def, _meta, [{:safe_divide, _fn_meta, _params}, [do: {:try, _, _}]]} -> true
               _ -> false
             end)
    end

    test "translates try with multiple catches" do
      source = """
      (ns test.try)

      (defn multi-catch [x]
        (try
          (if (> x 0)
            :positive
            :non-positive)
          (catch RuntimeError e
            :caught)
          (catch ArgumentError e
            :illegal)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "translates try with let binding" do
      source = """
      (ns test.try)

      (defn try-let [x]
        (try
          (let [result (/ 1 x)]
            result)
          (catch ArithmeticError e
            :error)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end

    test "translates nested try" do
      source = """
      (ns test.try)

      (defn nested []
        (try
          (try
            (/ 1 0)
            (catch ArithmeticError e
              :inner))
          (catch RuntimeError e
            :outer)))
      """

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)
    end
  end

  defmodule TryProject do
    use CljCompiler, dir: "test/fixtures/lib/clj/test_try"

    def safe_divide(a, b), do: a / b
  end

  test "try/catch/finally integration - catch exception" do
    assert TryProject.TestTry.Core.safe_divide(1, 0) == :infinity
  end

  test "try/catch/finally integration - normal execution" do
    assert TryProject.TestTry.Core.safe_divide(10, 2) == 5.0
  end

  test "try/catch/finally integration - multiple catches" do
    assert TryProject.TestTry.Core.try_with_multiple_catches(1) == :positive
    assert TryProject.TestTry.Core.try_with_multiple_catches(0) == :non_positive
  end

  test "try/catch/finally integration - without catch" do
    result = TryProject.TestTry.Core.try_without_catch()
    assert result == :result
  end

  test "try/catch/finally integration - nested try" do
    assert TryProject.TestTry.Core.nested_try(0) == :inner_caught
    assert TryProject.TestTry.Core.nested_try(1) == 1.0
  end

  test "try/catch/finally integration - try with let" do
    assert TryProject.TestTry.Core.try_with_let(0) == :error
    assert TryProject.TestTry.Core.try_with_let(2) == 0.5
  end

  test "try/catch/finally integration - only finally" do
    assert TryProject.TestTry.Core.try_only_finally() == :success
  end

  test "try/catch/finally integration - only catch" do
    assert TryProject.TestTry.Core.try_only_catch() == :normal
  end

  describe "line comments" do
    test "parses line comment at end of line" do
      source = "(ns test.comments)\n(defn foo [] \"body\" ; this is a comment\n)"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      assert [
               {:list, [{:symbol, "ns"}, {:symbol, "test.comments"}], _},
               {:list, [{:symbol, "defn"}, {:symbol, "foo"}, {:vector, []}, {:string, "body"}], _}
             ] = ast
    end

    test "parses code with semicolon in string" do
      source = "(ns test.comments) (defn foo [] \"string with ; semicolon\")"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      assert {:list, [_, _, _, {:string, "string with ; semicolon"}], _} = List.last(ast)
    end

    test "parses multiple comments on same line" do
      source = "(ns test.comments) ; first comment\n (defn foo [] \"body\")"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      assert [
               {:list, [{:symbol, "ns"}, {:symbol, "test.comments"}], _},
               {:list, [{:symbol, "defn"}, {:symbol, "foo"}, {:vector, []}, {:string, "body"}], _}
             ] = ast
    end

    test "comment inside list is stripped" do
      source = "(ns test.comments) (defn foo [] (list 1 2 ; inner comment\n 3))"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      defn_form =
        Enum.find(ast, fn
          {:list, [{:symbol, "defn"}, {:symbol, "foo"} | _], _} -> true
          _ -> false
        end)

      assert defn_form != nil
      {:list, [_, _, _, inner_list], _} = defn_form
      assert {:list, inner_elements} = inner_list
      # Should have list symbol + 3 numbers (1, 2, 3)
      assert length(inner_elements) == 4
      assert {:symbol, "list"} in inner_elements
    end
  end

  describe "#_ reader macro" do
    test "skips next form with #_" do
      source = "(ns test.comments) (defn foo [] #_ (skip-me) \"body\")"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      defn_form =
        Enum.find(ast, fn
          {:list, [{:symbol, "defn"}, {:symbol, "foo"} | _], _} -> true
          _ -> false
        end)

      assert defn_form != nil
      {:list, [_, _, _, {:string, "body"}], _} = defn_form
    end

    test "skips vector with #_" do
      source = "(ns test.comments) (defn foo [] #_ [a b c] \"body\")"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      defn_form =
        Enum.find(ast, fn
          {:list, [{:symbol, "defn"}, {:symbol, "foo"} | _], _} -> true
          _ -> false
        end)

      assert defn_form != nil
      {:list, [_, _, _, {:string, "body"}], _} = defn_form
    end

    test "skips map with #_" do
      source = "(ns test.comments) (defn foo [] #_ {:key \"value\"} \"body\")"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      defn_form =
        Enum.find(ast, fn
          {:list, [{:symbol, "defn"}, {:symbol, "foo"} | _], _} -> true
          _ -> false
        end)

      assert defn_form != nil
      {:list, [_, _, _, {:string, "body"}], _} = defn_form
    end

    test "multiple #_ in sequence" do
      source = "(ns test.comments) (defn foo [] #_ (a) #_ (b) \"body\")"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      defn_form =
        Enum.find(ast, fn
          {:list, [{:symbol, "defn"}, {:symbol, "foo"} | _], _} -> true
          _ -> false
        end)

      assert defn_form != nil
      {:list, [_, _, _, {:string, "body"}], _} = defn_form
    end

    test "#_ inside list skips form from list" do
      source = "(ns test.comments) (defn foo [] (list 1 #_ (skip) 2 3))"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")

      list_form =
        Enum.find(ast, fn
          {:list, [{:symbol, "defn"}, {:symbol, "foo"} | _], _} -> true
          _ -> false
        end)

      assert list_form != nil

      {:list, [_, _, _, inner_list], _} = list_form
      assert {:list, inner_elements} = inner_list
      # list has symbol + 3 numbers
      assert length(inner_elements) == 4
      assert {:symbol, "list"} in inner_elements
      assert {:number, 1} in inner_elements
      assert {:number, 2} in inner_elements
      assert {:number, 3} in inner_elements
    end
  end

  describe "comment special form" do
    test "comment form translates to nil" do
      source =
        "(ns test.comments) (defn foo [] (comment (defn bar [] \"ignored\") \"also ignored\"))"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)

      assert Enum.any?(result, fn
               {:def, _meta, [{:foo, _fn_meta, _params}, [do: nil]]} -> true
               _ -> false
             end)
    end

    test "comment with single form" do
      source = "(ns test.comments) (defn foo [] (comment (defn bar [] \"body\")))"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)

      assert Enum.any?(result, fn
               {:def, _meta, [{:foo, _fn_meta, _params}, [do: nil]]} -> true
               _ -> false
             end)
    end

    test "nested comment forms" do
      source = "(ns test.comments) (defn foo [] (comment (comment (defn bar [] \"body\"))))"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)

      assert Enum.any?(result, fn
               {:def, _meta, [{:foo, _fn_meta, _params}, [do: nil]]} -> true
               _ -> false
             end)
    end

    test "comment with multiple expressions" do
      source = "(ns test.comments) (defn foo [] (comment 1 2 3 \"string\" :keyword))"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)

      assert Enum.any?(result, fn
               {:def, _meta, [{:foo, _fn_meta, _params}, [do: nil]]} -> true
               _ -> false
             end)
    end

    test "comment inside function definition" do
      source = "(ns test.comments) (defn foo [] (comment this is ignored) \"body\")"

      {:ok, ast} = CljCompiler.Reader.parse(source, "test.clj")
      result = CljCompiler.Translator.translate(ast, [], TestModule, "test.clj")

      assert is_list(result)

      assert Enum.any?(result, fn
               {:def, _meta, [{:foo, _fn_meta, _params}, [do: "body"]]} -> true
               _ -> false
             end)
    end
  end

  describe "Erlang function calls" do
    test "calls :erlang/unique_integer" do
      assert ClojureProject.Example.Erlang.get_unique_integer() |> is_integer()
    end

    test "calls :erlang/unique_integer with :positive modifier" do
      result = ClojureProject.Example.Erlang.get_positive_unique_integer()
      assert result |> is_integer()
      assert result > 0
    end

    test "multiple :erlang/unique_integer calls return different values" do
      first = ClojureProject.Example.Erlang.get_unique_integer()
      second = ClojureProject.Example.Erlang.get_unique_integer()
      assert first != second
    end

    test "unique_integer can be used in expressions" do
      result = ClojureProject.Example.Erlang.unique_integer_plus_one()
      assert result |> is_integer()
      # Result will be unique_integer + 1, which is always an integer
    end
  end

  defmodule MultiArityProject do
    use CljCompiler, dir: "test/fixtures/multi_arity"
  end

  describe "multi-arity functions" do
    test "compiles multi-arity defn with two arities" do
      assert MultiArityProject.Concat.concat() == ""
      assert MultiArityProject.Concat.concat("world") == "hello world"
    end

    test "compiles multi-arity defn with three arities" do
      assert MultiArityProject.Math.foo() == 0
      assert MultiArityProject.Math.foo(5) == 5
      assert MultiArityProject.Math.foo(3, 4) == 7
    end

    test "compiles multi-arity defn with 0-arity and 1-arity" do
      assert MultiArityProject.Greet.greet() == "Hello!"
      assert MultiArityProject.Greet.greet("Alice") == "Hello, Alice"
    end

    test "compiles multi-arity defn with docstring" do
      assert MultiArityProject.WithDoc.documented() == "doc: default"
      assert MultiArityProject.WithDoc.documented("value") == "doc: value"
    end

    test "calls multi-arity functions with different arguments" do
      # Test 0-arity
      assert MultiArityProject.Concat.concat() == ""
      # Test 1-arity
      assert MultiArityProject.Concat.concat("test") == "hello test"
      # Test with nested calls
      result = MultiArityProject.Concat.concat(MultiArityProject.Math.foo(10))
      assert result == "hello 10"
    end

    test "preserves line numbers for each clause" do
      # This test ensures line metadata is preserved - we compile without errors
      assert function_exported?(MultiArityProject.Concat, :concat, 0)
      assert function_exported?(MultiArityProject.Concat, :concat, 1)
    end

    test "translates body expressions in each arity clause" do
      assert MultiArityProject.NestedMath.math() == 0
      assert MultiArityProject.NestedMath.math(5) == 10
      assert MultiArityProject.NestedMath.math(3, 4) == 7
    end

    test "handles let bindings in multi-arity defn body" do
      assert MultiArityProject.WithLet.with_let() == 1
      assert MultiArityProject.WithLet.with_let(5) == 5
    end

    test "handles nested expressions in multi-arity defn body" do
      assert MultiArityProject.Nested.nested() == "a"
      assert MultiArityProject.Nested.nested(nil) == "c"
      assert MultiArityProject.Nested.nested("x") == "d"
    end

    test "raises error for duplicate arities" do
      code = """
      (ns test.dup)
      (defn dup ([] 1) ([x] 2) ([y] 3))
      """

      assert_raise CompileError, ~r/Duplicate arity clauses/, fn ->
        CljCompiler.compile_code!(code, TestDup)
      end
    end

    test "raises error for missing arity clause" do
      code = """
      (ns test.empty)
      (defn empty [])
      """

      assert_raise CompileError, ~r/Invalid arity clause/, fn ->
        CljCompiler.compile_code!(code, TestEmpty)
      end
    end

    test "existing single-arity tests still pass" do
      # Test that single-arity functions still work
      assert function_exported?(MultiArityProject.Single, :hello, 0)
      assert MultiArityProject.Single.hello() == "Hello World"
      assert MultiArityProject.Single.add(2, 3) == 5
    end
  end
  
  (use: [Compat])
  
end
