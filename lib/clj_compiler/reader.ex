defmodule CljCompiler.Reader do
  defmodule ParseError do
    defexception [:message, :line, :column, :file]

    def exception(opts) do
      line = Keyword.get(opts, :line, 1)
      column = Keyword.get(opts, :column, 1)
      file = Keyword.get(opts, :file, "unknown")
      reason = Keyword.fetch!(opts, :reason)

      message = """
      Parse error at line #{line}, column #{column} in #{file}:
      #{reason}
      """

      %__MODULE__{message: message, line: line, column: column, file: file}
    end
  end

  def parse(source, file \\ "clj_file") do
    source
    |> String.trim()
    |> remove_comments()
    |> tokenize_with_positions()
    |> parse_tokens(file)
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

  defp tokenize_with_positions(source) do
    tokenize_impl(source, [], "", false, 1, 1, 1, 1)
  end

  defp tokenize_impl("", acc, current, _in_string, _line, _col, _token_line, _token_col) do
    acc = if current != "", do: [current | acc], else: acc
    Enum.reverse(acc)
  end

  defp tokenize_impl("\"" <> rest, acc, current, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_impl(rest, acc, "\"", true, line, col + 1, line, col)
  end

  defp tokenize_impl("\"" <> rest, acc, current, true, line, col, _tl, _tc) do
    tokenize_impl(rest, [current <> "\"" | acc], "", false, line, col + 1, line, col)
  end

  defp tokenize_impl(<<char::utf8, rest::binary>>, acc, current, true, line, col, tl, tc) do
    new_line = if char == ?\n, do: line + 1, else: line
    new_col = if char == ?\n, do: 1, else: col + 1
    tokenize_impl(rest, acc, current <> <<char::utf8>>, true, new_line, new_col, tl, tc)
  end

  defp tokenize_impl("(" <> rest, acc, current, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_impl(rest, [{:paren_open, line, col} | acc], "", false, line, col + 1, line, col)
  end

  defp tokenize_impl(")" <> rest, acc, current, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_impl(rest, [{:paren_close, line, col} | acc], "", false, line, col + 1, line, col)
  end

  defp tokenize_impl("[" <> rest, acc, current, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_impl(rest, [{:bracket_open, line, col} | acc], "", false, line, col + 1, line, col)
  end

  defp tokenize_impl("]" <> rest, acc, current, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_impl(rest, [{:bracket_close, line, col} | acc], "", false, line, col + 1, line, col)
  end

  defp tokenize_impl(<<char::utf8, rest::binary>>, acc, current, false, line, col, _tl, _tc) when char in [?\s, ?\n, ?\t, ?\r] do
    acc = if current != "", do: [current | acc], else: acc
    new_line = if char == ?\n, do: line + 1, else: line
    new_col = if char == ?\n, do: 1, else: col + 1
    tokenize_impl(rest, acc, "", false, new_line, new_col, new_line, new_col)
  end

  defp tokenize_impl(<<char::utf8, rest::binary>>, acc, current, false, line, col, tl, tc) do
    token_line = if current == "", do: line, else: tl
    token_col = if current == "", do: col, else: tc
    tokenize_impl(rest, acc, current <> <<char::utf8>>, false, line, col + 1, token_line, token_col)
  end

  defp parse_tokens(tokens, file) do
    try do
      case parse_forms(tokens, [], file) do
        {forms, []} -> forms
        {_forms, remaining} ->
          {line, col} = get_token_position(hd(remaining))
          raise ParseError, reason: "Unexpected tokens remaining: #{inspect(remaining)}", line: line, column: col, file: file
      end
    catch
      :error, %ParseError{} = e -> reraise e, __STACKTRACE__
    end
  end

  defp get_token_position({:paren_open, line, col}), do: {line, col}
  defp get_token_position({:paren_close, line, col}), do: {line, col}
  defp get_token_position({:bracket_open, line, col}), do: {line, col}
  defp get_token_position({:bracket_close, line, col}), do: {line, col}
  defp get_token_position(_), do: {0, 0}

  defp parse_forms([], acc, _file), do: {Enum.reverse(acc), []}

  defp parse_forms([{:paren_open, line, col} | rest], acc, file) do
    case parse_list(rest, [], file, line, col) do
      {form, remaining} -> parse_forms(remaining, [{:list, form} | acc], file)
    end
  end

  defp parse_forms([token | rest], acc, file) do
    parse_forms(rest, [parse_atom(token) | acc], file)
  end

  defp parse_list([{:paren_close, _line, _col} | rest], acc, _file, _open_line, _open_col), do: {Enum.reverse(acc), rest}

  defp parse_list([], _acc, file, open_line, open_col) do
    raise ParseError, reason: "Unclosed parenthesis", line: open_line, column: open_col, file: file
  end

  defp parse_list([{:paren_open, line, col} | rest], acc, file, _ol, _oc) do
    {nested, remaining} = parse_list(rest, [], file, line, col)
    parse_list(remaining, [{:list, nested} | acc], file, line, col)
  end

  defp parse_list([{:bracket_open, line, col} | rest], acc, file, _ol, _oc) do
    {vector, remaining} = parse_vector(rest, [], file, line, col)
    parse_list(remaining, [{:vector, vector} | acc], file, line, col)
  end

  defp parse_list([token | rest], acc, file, open_line, open_col) do
    parse_list(rest, [parse_atom(token) | acc], file, open_line, open_col)
  end

  defp parse_vector([{:bracket_close, _line, _col} | rest], acc, _file, _open_line, _open_col), do: {Enum.reverse(acc), rest}

  defp parse_vector([], _acc, file, open_line, open_col) do
    raise ParseError, reason: "Unclosed bracket", line: open_line, column: open_col, file: file
  end

  defp parse_vector([{:paren_open, line, col} | rest], acc, file, _ol, _oc) do
    {nested, remaining} = parse_list(rest, [], file, line, col)
    parse_vector(remaining, [{:list, nested} | acc], file, line, col)
  end

  defp parse_vector([{:bracket_open, line, col} | rest], acc, file, _ol, _oc) do
    {nested_vector, remaining} = parse_vector(rest, [], file, line, col)
    parse_vector(remaining, [{:vector, nested_vector} | acc], file, line, col)
  end

  defp parse_vector([token | rest], acc, file, open_line, open_col) do
    parse_vector(rest, [parse_atom(token) | acc], file, open_line, open_col)
  end

  defp parse_atom("\"" <> _ = token) do
    value = String.slice(token, 1..-2//1)
    {:string, value}
  end

  defp parse_atom(token) when is_binary(token) do
    case Integer.parse(token) do
      {num, ""} -> {:number, num}
      _ -> {:symbol, token}
    end
  end

  defp parse_atom(token), do: token
end
