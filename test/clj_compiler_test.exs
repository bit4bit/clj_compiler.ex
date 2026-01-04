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
end
