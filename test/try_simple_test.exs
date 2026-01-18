defmodule TrySimpleTest do
  use ExUnit.Case

  defmodule TrySimpleProject do
    use CljCompiler, dir: "test/fixtures/lib/clj/test_try_simple"
  end

  test "basic try/catch" do
    assert TrySimpleProject.TestTrySimple.Core.basic_try() == :success
  end

  test "try with finally" do
    assert TrySimpleProject.TestTrySimple.Core.try_with_finally() == :result
  end

  test "try/catch with exception" do
    assert TrySimpleProject.TestTrySimple.Core.safe_divide(1, 0) == :infinity
  end

  test "try/catch with normal execution" do
    assert TrySimpleProject.TestTrySimple.Core.safe_divide(10, 2) == 5.0
  end
end
