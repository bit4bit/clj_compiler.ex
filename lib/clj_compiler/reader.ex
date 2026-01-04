# LLM-Assisted

defmodule CljCompiler.Reader do
  def parse(source) do
    source
    |> String.trim()
    |> remove_comments()
    |> tokenize()
    |> parse_tokens()
  end

  defp remove_comments(source) do
    source
    |> String.split("\n")
    |> Enum.map(fn line ->
      case String.split(line, ";", parts: 2) do
        [code, _comment] -> code
        [code] -> code
      end
    end)
    |> Enum.join("\n")
  end

  defp tokenize(source) do
    tokenize_with_strings(source, [], "", false)
  end

  defp tokenize_with_strings("", acc, current, _in_string) do
    acc = if current != "", do: [current | acc], else: acc
    Enum.reverse(acc)
  end

  defp tokenize_with_strings("\"" <> rest, acc, current, false) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_with_strings(rest, acc, "\"", true)
  end

  defp tokenize_with_strings("\"" <> rest, acc, current, true) do
    tokenize_with_strings(rest, [current <> "\"" | acc], "", false)
  end

  defp tokenize_with_strings(<<char::utf8, rest::binary>>, acc, current, true) do
    tokenize_with_strings(rest, acc, current <> <<char::utf8>>, true)
  end

  defp tokenize_with_strings("(" <> rest, acc, current, false) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_with_strings(rest, ["(" | acc], "", false)
  end

  defp tokenize_with_strings(")" <> rest, acc, current, false) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_with_strings(rest, [")" | acc], "", false)
  end

  defp tokenize_with_strings("[" <> rest, acc, current, false) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_with_strings(rest, ["[" | acc], "", false)
  end

  defp tokenize_with_strings("]" <> rest, acc, current, false) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_with_strings(rest, ["]" | acc], "", false)
  end

  defp tokenize_with_strings(<<char::utf8, rest::binary>>, acc, current, false) when char in [?\s, ?\n, ?\t, ?\r] do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_with_strings(rest, acc, "", false)
  end

  defp tokenize_with_strings(<<char::utf8, rest::binary>>, acc, current, false) do
    tokenize_with_strings(rest, acc, current <> <<char::utf8>>, false)
  end

  defp parse_tokens(tokens) do
    {forms, _rest} = parse_forms(tokens, [])
    forms
  end

  defp parse_forms([], acc), do: {Enum.reverse(acc), []}

  defp parse_forms(["(" | rest], acc) do
    {form, remaining} = parse_list(rest, [])
    parse_forms(remaining, [{:list, form} | acc])
  end

  defp parse_forms([token | rest], acc) do
    parse_forms(rest, [parse_atom(token) | acc])
  end

  defp parse_list([")" | rest], acc), do: {Enum.reverse(acc), rest}

  defp parse_list(["(" | rest], acc) do
    {nested, remaining} = parse_list(rest, [])
    parse_list(remaining, [{:list, nested} | acc])
  end

  defp parse_list(["[" | rest], acc) do
    {vector, remaining} = parse_vector(rest, [])
    parse_list(remaining, [{:vector, vector} | acc])
  end

  defp parse_list([token | rest], acc) do
    parse_list(rest, [parse_atom(token) | acc])
  end

  defp parse_vector(["]" | rest], acc), do: {Enum.reverse(acc), rest}

  defp parse_vector(["(" | rest], acc) do
    {nested, remaining} = parse_list(rest, [])
    parse_vector(remaining, [{:list, nested} | acc])
  end

  defp parse_vector(["[" | rest], acc) do
    {nested_vector, remaining} = parse_vector(rest, [])
    parse_vector(remaining, [{:vector, nested_vector} | acc])
  end

  defp parse_vector([token | rest], acc) do
    parse_vector(rest, [parse_atom(token) | acc])
  end

  defp parse_atom("\"" <> _ = token) do
    value = String.slice(token, 1..-2//1)
    {:string, value}
  end

  defp parse_atom(token) do
    case Integer.parse(token) do
      {num, ""} -> {:number, num}
      _ -> {:symbol, token}
    end
  end
end
