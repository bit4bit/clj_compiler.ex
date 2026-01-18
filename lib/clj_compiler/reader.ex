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
    |> tokenize_with_positions()
    |> parse_tokens(file)
  end

  defp tokenize_with_positions(source) do
    tokenize_impl(source, [], "", false, false, 1, 1, 1, 1)
  end

  defp tokenize_impl(
         "",
         acc,
         _current,
         _in_string,
         true,
         _line,
         _col,
         _token_line,
         _token_col
       ) do
    Enum.reverse(acc)
  end

  defp tokenize_impl(
         "",
         acc,
         _current,
         _in_string,
         _in_comment,
         _line,
         _col,
         _token_line,
         _token_col
       ) do
    Enum.reverse(acc)
  end

  defp tokenize_impl(
         <<char::utf8, rest::binary>>,
         acc,
         _current,
         false,
         true,
         line,
         col,
         _tl,
         _tc
       ) do
    if char == ?\n do
      tokenize_impl(rest, acc, "", false, false, line + 1, 1, line + 1, 1)
    else
      tokenize_impl(rest, acc, "", false, true, line, col + 1, line, col)
    end
  end

  defp tokenize_impl("\n" <> rest, acc, current, in_string, _in_comment, line, _col, _tl, _tc) do
    if in_string do
      tokenize_impl(rest, [], "", true, false, line + 1, 1, line + 1, 1)
    else
      acc = if current != "", do: [current | acc], else: acc
      tokenize_impl(rest, acc, "", false, false, line + 1, 1, line + 1, 1)
    end
  end

  defp tokenize_impl(";" <> rest, acc, current, true, false, line, col, tl, tc) do
    tokenize_impl(rest, acc, current <> ";", true, false, line, col + 1, tl, tc)
  end

  defp tokenize_impl(";" <> rest, acc, "", false, false, line, col, _tl, _tc) do
    tokenize_impl(rest, acc, "", false, true, line, col + 1, line, col)
  end

  defp tokenize_impl(";" <> rest, acc, current, false, false, line, col, tl, tc) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_impl(rest, acc, "", false, true, line, col + 1, tl, tc)
  end

  defp tokenize_impl("#_" <> rest, acc, "", false, false, line, col, _tl, _tc) do
    tokenize_impl(rest, [{:skip, line, col} | acc], "", false, false, line, col + 2, line, col)
  end

  defp tokenize_impl("#_" <> rest, acc, current, false, false, line, col, tl, tc) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_impl(rest, [{:skip, line, col} | acc], "", false, false, line, col + 2, tl, tc)
  end

  defp tokenize_impl("\"" <> rest, acc, current, false, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_impl(rest, acc, "\"", true, false, line, col + 1, line, col)
  end

  defp tokenize_impl("\"" <> rest, acc, current, true, false, line, col, _tl, _tc) do
    tokenize_impl(rest, [current <> "\"" | acc], "", false, false, line, col + 1, line, col)
  end

  defp tokenize_impl(<<char::utf8, rest::binary>>, acc, current, true, false, line, col, tl, tc) do
    tokenize_impl(rest, acc, current <> <<char::utf8>>, true, false, line, col + 1, tl, tc)
  end

  defp tokenize_impl(
         <<char::utf8, rest::binary>>,
         acc,
         _current,
         false,
         true,
         line,
         col,
         _tl,
         _tc
       ) do
    if char == ?\n do
      tokenize_impl(rest, acc, "", false, false, line + 1, 1, line + 1, 1)
    else
      tokenize_impl(rest, acc, "", false, true, line, col + 1, line, col)
    end
  end

  defp tokenize_impl("(" <> rest, acc, current, false, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc

    tokenize_impl(
      rest,
      [{:paren_open, line, col} | acc],
      "",
      false,
      false,
      line,
      col + 1,
      line,
      col
    )
  end

  defp tokenize_impl(")" <> rest, acc, current, false, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc

    tokenize_impl(
      rest,
      [{:paren_close, line, col} | acc],
      "",
      false,
      false,
      line,
      col + 1,
      line,
      col
    )
  end

  defp tokenize_impl("[" <> rest, acc, current, false, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc

    tokenize_impl(
      rest,
      [{:bracket_open, line, col} | acc],
      "",
      false,
      false,
      line,
      col + 1,
      line,
      col
    )
  end

  defp tokenize_impl("]" <> rest, acc, current, false, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc

    tokenize_impl(
      rest,
      [{:bracket_close, line, col} | acc],
      "",
      false,
      false,
      line,
      col + 1,
      line,
      col
    )
  end

  defp tokenize_impl("{" <> rest, acc, current, false, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc

    tokenize_impl(
      rest,
      [{:brace_open, line, col} | acc],
      "",
      false,
      false,
      line,
      col + 1,
      line,
      col
    )
  end

  defp tokenize_impl("}" <> rest, acc, current, false, false, line, col, _tl, _tc) do
    acc = if current != "", do: [current | acc], else: acc

    tokenize_impl(
      rest,
      [{:brace_close, line, col} | acc],
      "",
      false,
      false,
      line,
      col + 1,
      line,
      col
    )
  end

  defp tokenize_impl(
         <<char::utf8, rest::binary>>,
         acc,
         current,
         false,
         false,
         line,
         col,
         _tl,
         _tc
       )
       when char in [?\s, ?\t, ?\r] do
    acc = if current != "", do: [current | acc], else: acc
    tokenize_impl(rest, acc, "", false, false, line, col + 1, line, col + 1)
  end

  defp tokenize_impl(<<char::utf8, rest::binary>>, acc, current, false, false, line, col, tl, tc) do
    token_line = if current == "", do: line, else: tl
    token_col = if current == "", do: col, else: tc

    tokenize_impl(
      rest,
      acc,
      current <> <<char::utf8>>,
      false,
      false,
      line,
      col + 1,
      token_line,
      token_col
    )
  end

  defp parse_tokens(tokens, file) do
    try do
      {forms, remaining_stack} = parse_forms(tokens, [], file, [])

      case remaining_stack do
        [] ->
          forms

        stack ->
          {type, open_line, open_col} = find_outermost(stack)

          raise ParseError,
            reason: get_unclosed_error_message(open_line, open_col, file, type),
            line: open_line,
            column: open_col,
            file: file
      end
    catch
      :error, %ParseError{} = e -> reraise e, __STACKTRACE__
    end
  end

  # Keep for potential future use

  # Stack helper functions for tracking opening delimiters
  defp push_delimiter(stack, type, line, col), do: [{type, line, col} | stack]

  defp pop_delimiter([{type, _open_line, _open_col} | rest], actual_type, _line, _col, _file)
       when type == actual_type,
       do: {:ok, rest}

  defp pop_delimiter([{expected_type, open_line, open_col} | _], actual_type, line, col, _file)
       when expected_type != actual_type,
       do: {:mismatch, actual_type, line, col, expected_type, open_line, open_col}

  defp pop_delimiter([], actual_type, line, col, _file),
    do: {:unmatched, actual_type, line, col}

  defp find_outermost(stack) do
    Enum.min_by(stack, fn {_, line, col} -> {line, col} end)
  end

  defp format_delimiter_type(:paren), do: "parenthesis"
  defp format_delimiter_type(:bracket), do: "bracket"
  defp format_delimiter_type(:brace), do: "brace"

  defp get_unclosed_error_message(open_line, open_col, file, type) do
    "Missing closing #{format_delimiter_type(type)} for opening at line #{open_line}, column #{open_col} in #{file}"
  end

  defp get_mismatch_error_message(
         _close_line,
         _close_col,
         file,
         actual_type,
         expected_type,
         open_line,
         open_col
       ) do
    "Unexpected closing #{format_delimiter_type(actual_type)}; expected closing #{format_delimiter_type(expected_type)} for opening at line #{open_line}, column #{open_col} in #{file}"
  end

  defp get_unmatched_error_message(_line, _col, file, type) do
    "Unexpected closing #{format_delimiter_type(type)}; no matching opening found in #{file}"
  end

  defp parse_forms([], acc, _file, stack), do: {Enum.reverse(acc), stack}

  defp parse_forms([{:skip, _line, _col} | rest], acc, file, stack) do
    {_form, remaining, new_stack} = skip_next_form(rest, file, stack)
    parse_forms(remaining, acc, file, new_stack)
  end

  defp parse_forms([{:paren_open, line, col} | rest], acc, file, stack) do
    {form, remaining, new_stack} =
      parse_list(rest, [], file, push_delimiter(stack, :paren, line, col))

    parse_forms(remaining, [{:list, form, line} | acc], file, new_stack)
  end

  defp parse_forms([{:bracket_open, line, col} | rest], acc, file, stack) do
    {form, remaining, new_stack} =
      parse_vector(rest, [], file, push_delimiter(stack, :bracket, line, col))

    parse_forms(remaining, [{:vector, form, line} | acc], file, new_stack)
  end

  defp parse_forms([{:brace_open, line, col} | rest], acc, file, stack) do
    {form, remaining, new_stack} =
      parse_map(rest, [], file, push_delimiter(stack, :brace, line, col))

    parse_forms(remaining, [{:map, form, line} | acc], file, new_stack)
  end

  defp parse_forms([{:paren_close, line, col} | _rest], _acc, file, _stack) do
    raise ParseError,
      reason: get_unmatched_error_message(line, col, file, :paren),
      line: line,
      column: col,
      file: file
  end

  defp parse_forms([{:bracket_close, line, col} | _rest], _acc, file, _stack) do
    raise ParseError,
      reason: get_unmatched_error_message(line, col, file, :bracket),
      line: line,
      column: col,
      file: file
  end

  defp parse_forms([{:brace_close, line, col} | _rest], _acc, file, _stack) do
    raise ParseError,
      reason: get_unmatched_error_message(line, col, file, :brace),
      line: line,
      column: col,
      file: file
  end

  defp parse_forms([token | rest], acc, file, stack) do
    parse_forms(rest, [parse_atom(token) | acc], file, stack)
  end

  defp skip_next_form([{:paren_open, line, col} | rest], file, stack) do
    {_form, remaining, new_stack} =
      parse_list(rest, [], file, push_delimiter(stack, :paren, line, col))

    {:skip, remaining, new_stack}
  end

  defp skip_next_form([{:bracket_open, line, col} | rest], file, stack) do
    {_form, remaining, new_stack} =
      parse_vector(rest, [], file, push_delimiter(stack, :bracket, line, col))

    {:skip, remaining, new_stack}
  end

  defp skip_next_form([{:brace_open, line, col} | rest], file, stack) do
    {_form, remaining, new_stack} =
      parse_map(rest, [], file, push_delimiter(stack, :brace, line, col))

    {:skip, remaining, new_stack}
  end

  defp skip_next_form([_token | rest], _file, stack), do: {:skip, rest, stack}

  defp parse_list([], _acc, _file, stack) do
    {[], [], stack}
  end

  defp parse_list([{:skip, _line, _col} | rest], acc, file, stack) do
    {_form, remaining, new_stack} = skip_next_form(rest, file, stack)
    parse_list(remaining, acc, file, new_stack)
  end

  defp parse_list([{:paren_open, line, col} | rest], acc, file, stack) do
    {nested, remaining, new_stack} =
      parse_list(rest, [], file, push_delimiter(stack, :paren, line, col))

    parse_list(remaining, [{:list, nested} | acc], file, new_stack)
  end

  defp parse_list([{:bracket_open, line, col} | rest], acc, file, stack) do
    {vector, remaining, new_stack} =
      parse_vector(rest, [], file, push_delimiter(stack, :bracket, line, col))

    parse_list(remaining, [{:vector, vector} | acc], file, new_stack)
  end

  defp parse_list([{:brace_open, line, col} | rest], acc, file, stack) do
    {map, remaining, new_stack} =
      parse_map(rest, [], file, push_delimiter(stack, :brace, line, col))

    parse_list(remaining, [{:map, map} | acc], file, new_stack)
  end

  defp parse_list([{:paren_close, line, col} | rest], acc, file, stack) do
    case pop_delimiter(stack, :paren, line, col, file) do
      {:ok, new_stack} ->
        {Enum.reverse(acc), rest, new_stack}

      {:mismatch, mismatch_actual, close_line, close_col, expected_type, open_line, open_col} ->
        raise ParseError,
          reason:
            get_mismatch_error_message(
              close_line,
              close_col,
              file,
              mismatch_actual,
              expected_type,
              open_line,
              open_col
            ),
          line: close_line,
          column: close_col,
          file: file

      {:unmatched, unmatched_actual, close_line, close_col} ->
        raise ParseError,
          reason: get_unmatched_error_message(close_line, close_col, file, unmatched_actual),
          line: close_line,
          column: close_col,
          file: file
    end
  end

  defp parse_list([{:bracket_close, line, col} | rest], acc, file, stack) do
    case pop_delimiter(stack, :bracket, line, col, file) do
      {:ok, new_stack} ->
        {Enum.reverse(acc), rest, new_stack}

      {:mismatch, mismatch_actual, close_line, close_col, expected_type, open_line, open_col} ->
        raise ParseError,
          reason:
            get_mismatch_error_message(
              close_line,
              close_col,
              file,
              mismatch_actual,
              expected_type,
              open_line,
              open_col
            ),
          line: close_line,
          column: close_col,
          file: file

      {:unmatched, unmatched_actual, close_line, close_col} ->
        raise ParseError,
          reason: get_unmatched_error_message(close_line, close_col, file, unmatched_actual),
          line: close_line,
          column: close_col,
          file: file
    end
  end

  defp parse_list([{:brace_close, line, col} | rest], acc, file, stack) do
    case pop_delimiter(stack, :brace, line, col, file) do
      {:ok, new_stack} ->
        {Enum.reverse(acc), rest, new_stack}

      {:mismatch, mismatch_actual, close_line, close_col, expected_type, open_line, open_col} ->
        raise ParseError,
          reason:
            get_mismatch_error_message(
              close_line,
              close_col,
              file,
              mismatch_actual,
              expected_type,
              open_line,
              open_col
            ),
          line: close_line,
          column: close_col,
          file: file

      {:unmatched, unmatched_actual, close_line, close_col} ->
        raise ParseError,
          reason: get_unmatched_error_message(close_line, close_col, file, unmatched_actual),
          line: close_line,
          column: close_col,
          file: file
    end
  end

  defp parse_list([token | rest], acc, file, stack) do
    parse_list(rest, [parse_atom(token) | acc], file, stack)
  end

  defp parse_vector([], _acc, _file, stack) do
    {[], [], stack}
  end

  defp parse_vector([{:skip, _line, _col} | rest], acc, file, stack) do
    {_form, remaining, new_stack} = skip_next_form(rest, file, stack)
    parse_vector(remaining, acc, file, new_stack)
  end

  defp parse_vector([{:paren_open, line, col} | rest], acc, file, stack) do
    {nested, remaining, new_stack} =
      parse_list(rest, [], file, push_delimiter(stack, :paren, line, col))

    parse_vector(remaining, [{:list, nested} | acc], file, new_stack)
  end

  defp parse_vector([{:bracket_open, line, col} | rest], acc, file, stack) do
    {nested_vector, remaining, new_stack} =
      parse_vector(rest, [], file, push_delimiter(stack, :bracket, line, col))

    parse_vector(remaining, [{:vector, nested_vector} | acc], file, new_stack)
  end

  defp parse_vector([{:brace_open, line, col} | rest], acc, file, stack) do
    {map, remaining, new_stack} =
      parse_map(rest, [], file, push_delimiter(stack, :brace, line, col))

    parse_vector(remaining, [{:map, map} | acc], file, new_stack)
  end

  defp parse_vector([{:paren_close, line, col} | rest], acc, file, stack) do
    case pop_delimiter(stack, :paren, line, col, file) do
      {:ok, new_stack} ->
        {Enum.reverse(acc), rest, new_stack}

      {:mismatch, mismatch_actual, close_line, close_col, expected_type, open_line, open_col} ->
        raise ParseError,
          reason:
            get_mismatch_error_message(
              close_line,
              close_col,
              file,
              mismatch_actual,
              expected_type,
              open_line,
              open_col
            ),
          line: close_line,
          column: close_col,
          file: file

      {:unmatched, unmatched_actual, close_line, close_col} ->
        raise ParseError,
          reason: get_unmatched_error_message(close_line, close_col, file, unmatched_actual),
          line: close_line,
          column: close_col,
          file: file
    end
  end

  defp parse_vector([{:bracket_close, line, col} | rest], acc, file, stack) do
    case pop_delimiter(stack, :bracket, line, col, file) do
      {:ok, new_stack} ->
        {Enum.reverse(acc), rest, new_stack}

      {:mismatch, mismatch_actual, close_line, close_col, expected_type, open_line, open_col} ->
        raise ParseError,
          reason:
            get_mismatch_error_message(
              close_line,
              close_col,
              file,
              mismatch_actual,
              expected_type,
              open_line,
              open_col
            ),
          line: close_line,
          column: close_col,
          file: file

      {:unmatched, unmatched_actual, close_line, close_col} ->
        raise ParseError,
          reason: get_unmatched_error_message(close_line, close_col, file, unmatched_actual),
          line: close_line,
          column: close_col,
          file: file
    end
  end

  defp parse_vector([{:brace_close, line, col} | rest], acc, file, stack) do
    case pop_delimiter(stack, :brace, line, col, file) do
      {:ok, new_stack} ->
        {Enum.reverse(acc), rest, new_stack}

      {:mismatch, mismatch_actual, close_line, close_col, expected_type, open_line, open_col} ->
        raise ParseError,
          reason:
            get_mismatch_error_message(
              close_line,
              close_col,
              file,
              mismatch_actual,
              expected_type,
              open_line,
              open_col
            ),
          line: close_line,
          column: close_col,
          file: file

      {:unmatched, unmatched_actual, close_line, close_col} ->
        raise ParseError,
          reason: get_unmatched_error_message(close_line, close_col, file, unmatched_actual),
          line: close_line,
          column: close_col,
          file: file
    end
  end

  defp parse_vector([token | rest], acc, file, stack) do
    parse_vector(rest, [parse_atom(token) | acc], file, stack)
  end

  defp parse_map([], _acc, _file, stack) do
    {[], [], stack}
  end

  defp parse_map([{:skip, _line, _col} | rest], acc, file, stack) do
    {_form, remaining, new_stack} = skip_next_form(rest, file, stack)
    parse_map(remaining, acc, file, new_stack)
  end

  defp parse_map([{:paren_open, line, col} | rest], acc, file, stack) do
    {nested, remaining, new_stack} =
      parse_list(rest, [], file, push_delimiter(stack, :paren, line, col))

    parse_map(remaining, [{:list, nested} | acc], file, new_stack)
  end

  defp parse_map([{:bracket_open, line, col} | rest], acc, file, stack) do
    {vector, remaining, new_stack} =
      parse_vector(rest, [], file, push_delimiter(stack, :bracket, line, col))

    parse_map(remaining, [{:vector, vector} | acc], file, new_stack)
  end

  defp parse_map([{:brace_open, line, col} | rest], acc, file, stack) do
    {nested_map, remaining, new_stack} =
      parse_map(rest, [], file, push_delimiter(stack, :brace, line, col))

    parse_map(remaining, [{:map, nested_map} | acc], file, new_stack)
  end

  defp parse_map([{:paren_close, line, col} | rest], acc, file, stack) do
    case pop_delimiter(stack, :paren, line, col, file) do
      {:ok, new_stack} ->
        {Enum.reverse(acc), rest, new_stack}

      {:mismatch, mismatch_actual, close_line, close_col, expected_type, open_line, open_col} ->
        raise ParseError,
          reason:
            get_mismatch_error_message(
              close_line,
              close_col,
              file,
              mismatch_actual,
              expected_type,
              open_line,
              open_col
            ),
          line: close_line,
          column: close_col,
          file: file

      {:unmatched, unmatched_actual, close_line, close_col} ->
        raise ParseError,
          reason: get_unmatched_error_message(close_line, close_col, file, unmatched_actual),
          line: close_line,
          column: close_col,
          file: file
    end
  end

  defp parse_map([{:bracket_close, line, col} | rest], acc, file, stack) do
    case pop_delimiter(stack, :bracket, line, col, file) do
      {:ok, new_stack} ->
        {Enum.reverse(acc), rest, new_stack}

      {:mismatch, mismatch_actual, close_line, close_col, expected_type, open_line, open_col} ->
        raise ParseError,
          reason:
            get_mismatch_error_message(
              close_line,
              close_col,
              file,
              mismatch_actual,
              expected_type,
              open_line,
              open_col
            ),
          line: close_line,
          column: close_col,
          file: file

      {:unmatched, unmatched_actual, close_line, close_col} ->
        raise ParseError,
          reason: get_unmatched_error_message(close_line, close_col, file, unmatched_actual),
          line: close_line,
          column: close_col,
          file: file
    end
  end

  defp parse_map([{:brace_close, line, col} | rest], acc, file, stack) do
    case pop_delimiter(stack, :brace, line, col, file) do
      {:ok, new_stack} ->
        {Enum.reverse(acc), rest, new_stack}

      {:mismatch, mismatch_actual, close_line, close_col, expected_type, open_line, open_col} ->
        raise ParseError,
          reason:
            get_mismatch_error_message(
              close_line,
              close_col,
              file,
              mismatch_actual,
              expected_type,
              open_line,
              open_col
            ),
          line: close_line,
          column: close_col,
          file: file

      {:unmatched, unmatched_actual, close_line, close_col} ->
        raise ParseError,
          reason: get_unmatched_error_message(close_line, close_col, file, unmatched_actual),
          line: close_line,
          column: close_col,
          file: file
    end
  end

  defp parse_map([token | rest], acc, file, stack) do
    parse_map(rest, [parse_atom(token) | acc], file, stack)
  end

  defp parse_atom("\"" <> _ = token) do
    value = String.slice(token, 1..-2//1)
    {:string, value}
  end

  defp parse_atom(":" <> rest = token) when is_binary(token) do
    normalized = String.replace(rest, "-", "_")
    {:keyword, String.to_atom(normalized)}
  end

  defp parse_atom(token) when is_binary(token) do
    cond do
      match?({_, ""}, Integer.parse(token)) ->
        {num, ""} = Integer.parse(token)
        {:number, num}

      match?({_, ""}, Float.parse(token)) ->
        {num, ""} = Float.parse(token)
        {:number, num}

      true ->
        {:symbol, token}
    end
  end

  defp parse_atom(token), do: token
end
