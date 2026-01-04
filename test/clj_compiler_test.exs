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

end
