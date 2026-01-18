defmodule CljCompiler.Reader do
  @moduledoc """
  Reader module for parsing Clojure source code into forms.

  Uses NimbleParsec-based Lexer and Parser for efficient, composable parsing.
  """

  defmodule ParseError do
    defexception [:message, :line, :column, :file, :reason]

    def exception(opts) do
      line = Keyword.get(opts, :line, 1)
      column = Keyword.get(opts, :column, 1)
      file = Keyword.get(opts, :file, "unknown")
      reason = Keyword.get(opts, :reason, "parse error")

      message = """
      Parse error at line #{line}, column #{column} in #{file}:
      #{reason}
      """

      %__MODULE__{message: message, line: line, column: column, file: file, reason: reason}
    end
  end

  @doc """
  Parse Clojure source code into forms.
  """
  def parse(source, file \\ "clj_file") when is_binary(source) do
    source
    |> String.trim()
    |> do_parse(file)
  end

  @doc """
  Parse tokens into forms (public API for token lists).
  """
  def parse_tokens(tokens, file \\ "clj_file") when is_list(tokens) do
    case do_parse_tokens(tokens, file, []) do
      {:ok, forms} -> {:ok, forms}
      {:error, %ParseError{} = e} -> {:error, e}
    end
  end

  # --- Private helper functions ---

  defp do_parse(source, file) do
    case CljCompiler.Lexer.tokenize(source) do
      {:ok, tokens} ->
        # Add line and column positions to tokens
        tokens_with_pos = add_token_positions(tokens, source)
        do_parse_tokens(tokens_with_pos, file, [])

      {:error, reason, line, column} ->
        raise ParseError, reason: reason, line: line, column: column, file: file
    end
  end

  defp add_token_positions(tokens, source) do
    # Split source into lines and track line/column for each token
    lines = String.split(source, "\n", parts: :infinity)

    {tokens_with_pos, _} =
      Enum.reduce(tokens, {[], {1, 1, 0, lines}}, fn token,
                                                     {acc, {line, col, char_offset, src_lines}} ->
        # Find the next non-whitespace/comment character position in source
        {new_line, new_col, new_offset} =
          find_next_token_position(source, char_offset, line, col, src_lines)

        token_with_pos =
          case token do
            {tag, value} when is_list(value) ->
              {tag, value, new_line, new_col}

            {tag, value} ->
              {tag, value, new_line, new_col}

            tag when is_atom(tag) ->
              {tag, nil, new_line, new_col}

            other ->
              other
          end

        # Advance offset by approximate token length
        token_length = estimate_token_length(token)
        next_offset = new_offset + token_length

        {next_line, next_col} =
          advance_position(source, new_offset, next_offset, new_line, new_col)

        {[token_with_pos | acc], {next_line, next_col, next_offset, src_lines}}
      end)

    Enum.reverse(tokens_with_pos)
  end

  defp find_next_token_position(source, offset, line, col, _lines) do
    # Skip whitespace and comments to find next token
    case String.slice(source, offset..-1//1) do
      "" ->
        {line, col, offset}

      rest ->
        skip_result = skip_whitespace_and_comments(rest, 0, line, col)

        case skip_result do
          {new_line, new_col, skip_count} ->
            {new_line, new_col, offset + skip_count}
        end
    end
  end

  defp skip_whitespace_and_comments(str, count, line, col) do
    case str do
      <<?\s, rest::binary>> ->
        skip_whitespace_and_comments(rest, count + 1, line, col + 1)

      <<?\t, rest::binary>> ->
        skip_whitespace_and_comments(rest, count + 1, line, col + 1)

      <<?\r, rest::binary>> ->
        skip_whitespace_and_comments(rest, count + 1, line, col)

      <<?\n, rest::binary>> ->
        skip_whitespace_and_comments(rest, count + 1, line + 1, 1)

      <<?;, rest::binary>> ->
        # Skip until end of line
        {skip_len, new_line, new_col} = skip_until_newline(rest, 0, line, col + 1)

        skip_whitespace_and_comments(
          String.slice(rest, skip_len..-1//1),
          count + 1 + skip_len,
          new_line,
          new_col
        )

      _ ->
        {line, col, count}
    end
  end

  defp skip_until_newline(str, count, line, col) do
    case str do
      <<?\n, _::binary>> -> {count + 1, line + 1, 1}
      <<_, rest::binary>> -> skip_until_newline(rest, count + 1, line, col + 1)
      "" -> {count, line, col}
    end
  end

  defp estimate_token_length({_tag, value}) when is_list(value), do: length(value)
  defp estimate_token_length({_tag, value}) when is_integer(value), do: 1
  defp estimate_token_length({_tag, _value}), do: 1
  defp estimate_token_length(_), do: 1

  defp advance_position(source, from_offset, to_offset, line, col) do
    slice = String.slice(source, from_offset, to_offset - from_offset)

    String.graphemes(slice)
    |> Enum.reduce({line, col}, fn
      "\n", {l, _c} -> {l + 1, 1}
      _, {l, c} -> {l, c + 1}
    end)
  end

  defp do_parse_tokens(tokens, file, acc) do
    do_parse_tokens(tokens, file, acc, [])
  end

  defp do_parse_tokens(tokens, file, acc, stack) do
    case tokens do
      [] ->
        # Check if there are unclosed delimiters
        case stack do
          [] ->
            {:ok, Enum.reverse(acc)}

          _stack ->
            # Report the outermost (last) unclosed delimiter
            {delimiter_type, open_line, open_col} = List.last(stack)

            delimiter_name =
              case delimiter_type do
                :paren -> "parenthesis"
                :bracket -> "bracket"
                :brace -> "brace"
              end

            raise ParseError,
              reason:
                "Missing closing #{delimiter_name} for opening at line #{open_line}, column #{open_col} in #{file}",
              line: open_line,
              column: open_col,
              file: file
        end

      [{:discard, _value, _line, _col} | rest] ->
        {_skip, remaining} = skip_next_form(rest, stack)
        do_parse_tokens(remaining, file, acc, stack)

      [{:paren_open, _value, line, col} | rest] ->
        new_stack = [{:paren, line, col} | stack]
        {form, remaining, final_stack} = parse_list(rest, [], false, new_stack, file)
        do_parse_tokens(remaining, file, [{:list, form, line} | acc], final_stack)

      [{:bracket_open, _value, line, col} | rest] ->
        new_stack = [{:bracket, line, col} | stack]
        {form, remaining, final_stack} = parse_vector(rest, [], false, new_stack, file)
        do_parse_tokens(remaining, file, [{:vector, form, line} | acc], final_stack)

      [{:brace_open, _value, line, col} | rest] ->
        new_stack = [{:brace, line, col} | stack]
        {form, remaining, final_stack} = parse_map(rest, [], false, new_stack, file)
        do_parse_tokens(remaining, file, [{:map, form, line} | acc], final_stack)

      [{:paren_close, _value, line, col} | _rest] ->
        case stack do
          [] ->
            raise ParseError,
              reason: "Unexpected closing parenthesis; no matching opening found in #{file}",
              line: line,
              column: col,
              file: file

          [{open_type, open_line, open_col} | _] ->
            expected =
              case open_type do
                :paren -> "closing parenthesis"
                :bracket -> "closing bracket"
                :brace -> "closing brace"
              end

            raise ParseError,
              reason:
                "Unexpected closing parenthesis; expected #{expected} for opening at line #{open_line}, column #{open_col} in #{file}",
              line: line,
              column: col,
              file: file
        end

      [{:bracket_close, _value, line, col} | _rest] ->
        case stack do
          [] ->
            raise ParseError,
              reason: "Unexpected closing bracket; no matching opening found in #{file}",
              line: line,
              column: col,
              file: file

          [{open_type, open_line, open_col} | _] ->
            expected =
              case open_type do
                :paren -> "closing parenthesis"
                :bracket -> "closing bracket"
                :brace -> "closing brace"
              end

            raise ParseError,
              reason:
                "Unexpected closing bracket; expected #{expected} for opening at line #{open_line}, column #{open_col} in #{file}",
              line: line,
              column: col,
              file: file
        end

      [{:brace_close, _value, line, col} | _rest] ->
        case stack do
          [] ->
            raise ParseError,
              reason: "Unexpected closing brace; no matching opening found in #{file}",
              line: line,
              column: col,
              file: file

          [{open_type, open_line, open_col} | _] ->
            expected =
              case open_type do
                :paren -> "closing parenthesis"
                :bracket -> "closing bracket"
                :brace -> "closing brace"
              end

            raise ParseError,
              reason:
                "Unexpected closing brace; expected #{expected} for opening at line #{open_line}, column #{open_col} in #{file}",
              line: line,
              column: col,
              file: file
        end

      [token | rest] ->
        do_parse_tokens(rest, file, [parse_atom(token) | acc], stack)
    end
  end

  # --- Skip next form (handles #_ discard) ---
  defp skip_next_form([{:paren_open, _value, line, col} | rest], stack) do
    new_stack = [{:paren, line, col} | stack]
    {_form, remaining, _final_stack} = parse_list(rest, [], false, new_stack, "clj")
    {:skip, remaining}
  end

  defp skip_next_form([{:bracket_open, _value, line, col} | rest], stack) do
    new_stack = [{:bracket, line, col} | stack]
    {_form, remaining, _final_stack} = parse_vector(rest, [], false, new_stack, "clj")
    {:skip, remaining}
  end

  defp skip_next_form([{:brace_open, _value, line, col} | rest], stack) do
    new_stack = [{:brace, line, col} | stack]
    {_form, remaining, _final_stack} = parse_map(rest, [], false, new_stack, "clj")
    {:skip, remaining}
  end

  defp skip_next_form([_token | rest], _stack), do: {:skip, rest}

  # --- List parsing ---
  defp parse_list([], _acc, _nested, stack, file) do
    # EOF with unclosed list - report outermost delimiter
    {delimiter_type, open_line, open_col} = List.last(stack)

    delimiter_name =
      case delimiter_type do
        :paren -> "parenthesis"
        :bracket -> "bracket"
        :brace -> "brace"
      end

    raise ParseError,
      reason:
        "Missing closing #{delimiter_name} for opening at line #{open_line}, column #{open_col} in #{file}",
      line: open_line,
      column: open_col,
      file: file
  end

  defp parse_list([{:paren_close, _value, _line, _col} | rest], acc, _nested, stack, _file) do
    # Pop the matching delimiter from stack
    case stack do
      [{:paren, _open_line, _open_col} | remaining_stack] ->
        {Enum.reverse(acc), rest, remaining_stack}

      _ ->
        {Enum.reverse(acc), rest, stack}
    end
  end

  defp parse_list([{:bracket_close, _value, line, col} | _rest], _acc, _nested, stack, file) do
    case stack do
      [{:paren, open_line, open_col} | _] ->
        raise ParseError,
          reason:
            "Unexpected closing bracket; expected closing parenthesis for opening at line #{open_line}, column #{open_col} in #{file}",
          line: line,
          column: col,
          file: file

      _ ->
        raise ParseError,
          reason: "mismatched bracket in list",
          line: line,
          column: col,
          file: file
    end
  end

  defp parse_list([{:brace_close, _value, line, col} | _rest], _acc, _nested, stack, file) do
    case stack do
      [{:paren, open_line, open_col} | _] ->
        raise ParseError,
          reason:
            "Unexpected closing brace; expected closing parenthesis for opening at line #{open_line}, column #{open_col} in #{file}",
          line: line,
          column: col,
          file: file

      _ ->
        raise ParseError, reason: "mismatched brace in list", line: line, column: col, file: file
    end
  end

  defp parse_list([{:discard, _value, _line, _col} | rest], acc, nested, stack, file) do
    {_skip, remaining} = skip_next_form(rest, stack)
    parse_list(remaining, acc, nested, stack, file)
  end

  defp parse_list([{:paren_open, _value, line, col} | rest], acc, nested, stack, file) do
    new_stack = [{:paren, line, col} | stack]
    {nested_list, remaining, final_stack} = parse_list(rest, [], true, new_stack, file)
    parse_list(remaining, [{:list, nested_list} | acc], nested, final_stack, file)
  end

  defp parse_list([{:bracket_open, _value, line, col} | rest], acc, nested, stack, file) do
    new_stack = [{:bracket, line, col} | stack]
    {nested_vector, remaining, final_stack} = parse_vector(rest, [], true, new_stack, file)
    parse_list(remaining, [{:vector, nested_vector} | acc], nested, final_stack, file)
  end

  defp parse_list([{:brace_open, _value, line, col} | rest], acc, nested, stack, file) do
    new_stack = [{:brace, line, col} | stack]
    {nested_map, remaining, final_stack} = parse_map(rest, [], true, new_stack, file)
    parse_list(remaining, [{:map, nested_map} | acc], nested, final_stack, file)
  end

  defp parse_list([token | rest], acc, nested, stack, file) do
    parse_list(rest, [parse_atom(token) | acc], nested, stack, file)
  end

  # --- Vector parsing ---
  defp parse_vector([], _acc, _nested, stack, file) do
    # EOF with unclosed vector - report outermost delimiter
    {delimiter_type, open_line, open_col} = List.last(stack)

    delimiter_name =
      case delimiter_type do
        :paren -> "parenthesis"
        :bracket -> "bracket"
        :brace -> "brace"
      end

    raise ParseError,
      reason:
        "Missing closing #{delimiter_name} for opening at line #{open_line}, column #{open_col} in #{file}",
      line: open_line,
      column: open_col,
      file: file
  end

  defp parse_vector([{:bracket_close, _value, _line, _col} | rest], acc, _nested, stack, _file) do
    case stack do
      [{:bracket, _open_line, _open_col} | remaining_stack] ->
        {Enum.reverse(acc), rest, remaining_stack}

      _ ->
        {Enum.reverse(acc), rest, stack}
    end
  end

  defp parse_vector([{:paren_close, _value, line, col} | _rest], _acc, _nested, stack, file) do
    case stack do
      [{:bracket, open_line, open_col} | _] ->
        raise ParseError,
          reason:
            "Unexpected closing parenthesis; expected closing bracket for opening at line #{open_line}, column #{open_col} in #{file}",
          line: line,
          column: col,
          file: file

      _ ->
        raise ParseError,
          reason: "mismatched paren in vector",
          line: line,
          column: col,
          file: file
    end
  end

  defp parse_vector([{:brace_close, _value, line, col} | _rest], _acc, _nested, stack, file) do
    case stack do
      [{:bracket, open_line, open_col} | _] ->
        raise ParseError,
          reason:
            "Unexpected closing brace; expected closing bracket for opening at line #{open_line}, column #{open_col} in #{file}",
          line: line,
          column: col,
          file: file

      _ ->
        raise ParseError,
          reason: "mismatched brace in vector",
          line: line,
          column: col,
          file: file
    end
  end

  defp parse_vector([{:discard, _value, _line, _col} | rest], acc, nested, stack, file) do
    {_skip, remaining} = skip_next_form(rest, stack)
    parse_vector(remaining, acc, nested, stack, file)
  end

  defp parse_vector([{:paren_open, _value, line, col} | rest], acc, nested, stack, file) do
    new_stack = [{:paren, line, col} | stack]
    {nested_list, remaining, final_stack} = parse_list(rest, [], true, new_stack, file)
    parse_vector(remaining, [{:list, nested_list} | acc], nested, final_stack, file)
  end

  defp parse_vector([{:bracket_open, _value, line, col} | rest], acc, nested, stack, file) do
    new_stack = [{:bracket, line, col} | stack]
    {nested_vector, remaining, final_stack} = parse_vector(rest, [], true, new_stack, file)
    parse_vector(remaining, [{:vector, nested_vector} | acc], nested, final_stack, file)
  end

  defp parse_vector([{:brace_open, _value, line, col} | rest], acc, nested, stack, file) do
    new_stack = [{:brace, line, col} | stack]
    {nested_map, remaining, final_stack} = parse_map(rest, [], true, new_stack, file)
    parse_vector(remaining, [{:map, nested_map} | acc], nested, final_stack, file)
  end

  defp parse_vector([token | rest], acc, nested, stack, file) do
    parse_vector(rest, [parse_atom(token) | acc], nested, stack, file)
  end

  # --- Map parsing ---
  defp parse_map([], _acc, _nested, stack, file) do
    # EOF with unclosed map - report outermost delimiter
    {delimiter_type, open_line, open_col} = List.last(stack)

    delimiter_name =
      case delimiter_type do
        :paren -> "parenthesis"
        :bracket -> "bracket"
        :brace -> "brace"
      end

    raise ParseError,
      reason:
        "Missing closing #{delimiter_name} for opening at line #{open_line}, column #{open_col} in #{file}",
      line: open_line,
      column: open_col,
      file: file
  end

  defp parse_map([{:brace_close, _value, _line, _col} | rest], acc, _nested, stack, _file) do
    case stack do
      [{:brace, _open_line, _open_col} | remaining_stack] ->
        {Enum.reverse(acc), rest, remaining_stack}

      _ ->
        {Enum.reverse(acc), rest, stack}
    end
  end

  defp parse_map([{:paren_close, _value, line, col} | _rest], _acc, _nested, stack, file) do
    case stack do
      [{:brace, open_line, open_col} | _] ->
        raise ParseError,
          reason:
            "Unexpected closing parenthesis; expected closing brace for opening at line #{open_line}, column #{open_col} in #{file}",
          line: line,
          column: col,
          file: file

      _ ->
        raise ParseError, reason: "mismatched paren in map", line: line, column: col, file: file
    end
  end

  defp parse_map([{:bracket_close, _value, line, col} | _rest], _acc, _nested, stack, file) do
    case stack do
      [{:brace, open_line, open_col} | _] ->
        raise ParseError,
          reason:
            "Unexpected closing bracket; expected closing brace for opening at line #{open_line}, column #{open_col} in #{file}",
          line: line,
          column: col,
          file: file

      _ ->
        raise ParseError,
          reason: "mismatched bracket in map",
          line: line,
          column: col,
          file: file
    end
  end

  defp parse_map([{:discard, _value, _line, _col} | rest], acc, nested, stack, file) do
    {_skip, remaining} = skip_next_form(rest, stack)
    parse_map(remaining, acc, nested, stack, file)
  end

  defp parse_map([{:paren_open, _value, line, col} | rest], acc, nested, stack, file) do
    new_stack = [{:paren, line, col} | stack]
    {nested_list, remaining, final_stack} = parse_list(rest, [], true, new_stack, file)
    parse_map(remaining, [{:list, nested_list} | acc], nested, final_stack, file)
  end

  defp parse_map([{:bracket_open, _value, line, col} | rest], acc, nested, stack, file) do
    new_stack = [{:bracket, line, col} | stack]
    {nested_vector, remaining, final_stack} = parse_vector(rest, [], true, new_stack, file)
    parse_map(remaining, [{:vector, nested_vector} | acc], nested, final_stack, file)
  end

  defp parse_map([{:brace_open, _value, line, col} | rest], acc, nested, stack, file) do
    new_stack = [{:brace, line, col} | stack]
    {nested_map, remaining, final_stack} = parse_map(rest, [], true, new_stack, file)
    parse_map(remaining, [{:map, nested_map} | acc], nested, final_stack, file)
  end

  defp parse_map([token | rest], acc, nested, stack, file) do
    parse_map(rest, [parse_atom(token) | acc], nested, stack, file)
  end

  # --- Atom parsing ---
  defp parse_atom({:string, value, _line, _col}) do
    {:string, to_string(value)}
  end

  defp parse_atom({:number, value, _line, _col}) do
    str_value = to_string(value)

    case Integer.parse(str_value) do
      {num, ""} ->
        {:number, num}

      _ ->
        case Float.parse(str_value) do
          {num, ""} -> {:number, num}
          _ -> {:number, str_value}
        end
    end
  end

  defp parse_atom({:symbol, value, _line, _col}) do
    {:symbol, to_string(value)}
  end

  defp parse_atom({:keyword, value, _line, _col}) do
    str_value = to_string(value)
    # Remove leading colon if present
    normalized =
      str_value
      |> String.trim_leading(":")
      |> String.replace("-", "_")

    {:keyword, String.to_atom(normalized)}
  end

  defp parse_atom(token), do: token
end
