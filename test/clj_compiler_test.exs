# LLM-Assisted

defmodule CljCompilerTest do
  use ExUnit.Case

  defmodule Example do
    use CljCompiler
  end

  test "hello world function" do
    assert Example.hello() == "Hello World"
  end

  test "function with parameters" do
    assert Example.greet("Alice") == "Hello, Alice"
  end

  test "arithmetic operations" do
    assert Example.add(2, 3) == 5
  end

  test "if expression" do
    assert Example.is_positive(5) == "positive"
    assert Example.is_positive(-3) == "negative"
  end

  test "let bindings" do
    assert Example.compute(10) == 35
  end

  test "recur tail recursion" do
    assert Example.factorial(5) == 120
  end

  test "elixir interop" do
    assert Example.list_length([1, 2, 3, 4]) == 4
  end
end
