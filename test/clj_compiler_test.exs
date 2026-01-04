defmodule CljCompilerTest do
  use ExUnit.Case

  defmodule ClojureProject do
    use CljCompiler, dir: "test/fixtures/lib/clj"

    def do_sum(a, b), do: a + b

    def greet_prefix(name), do: "Mr. #{name}"
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

    error = assert_raise CljCompiler.Reader.ParseError, fn ->
      CljCompiler.Reader.parse(source)
    end

    assert error.line == 4
    assert error.message =~ "Unclosed parenthesis"
  end

  test "creates map with keyword keys" do
    assert ClojureProject.Example.Data.create_person("Alice", 30) == %{name: "Alice", age: 30}
  end

  test "returns map literal" do
    assert ClojureProject.Example.Data.get_config() == %{host: "localhost", port: 8080, debug: true}
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

    ast = CljCompiler.Reader.parse(source, "test_maps.clj")
    assert [{:list, [{:symbol, "ns"}, {:symbol, "test.maps"}]},
            {:list, [{:symbol, "defn"}, {:symbol, "get_user"}, {:vector, []}, {:map, _}]},
            {:list, [{:symbol, "defn"}, {:symbol, "process_map"}, {:vector, [{:symbol, "m"}]}, {:symbol, "m"}]}] = ast
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
    assert function_exported?(CljCompilerTest.UseTestProject.UseExample.WithOptions, :configured, 0)
    assert CljCompilerTest.UseTestProject.UseExample.WithOptions.configured() == true
  end

  test "namespace with multiple :use declarations" do
    assert function_exported?(CljCompilerTest.UseTestProject.UseExample.Multiple, :has_multiple, 0)
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

    error = assert_raise CompileError, fn ->
      CljCompiler.Translator.translate(CljCompiler.Reader.parse(source, "test.clj"), TestModule)
    end

    assert error.description =~ "Unable to resolve symbol: defa"
  end

end
