defmodule CljCompiler.Lexer do
  @moduledoc """
  Lexer module for tokenizing Clojure source code using NimbleParsec.
  """

  import NimbleParsec

  # --- Whitespace ---
  defparsec(
    :ws,
    ascii_char([?\s, ?\t, ?\n, ?\r])
    |> repeat()
    |> ignore()
  )

  # --- String ---
  defparsec(
    :string,
    ignore(ascii_char([?"]))
    |> repeat(lookahead_not(ascii_char([?"])) |> utf8_char([]))
    |> ignore(ascii_char([?"]))
    |> tag(:string)
  )

  # --- Number ---
  defparsec(
    :number,
    optional(ascii_char([?-]))
    |> ascii_char([?0..?9])
    |> repeat(ascii_char([?0..?9]))
    |> optional(
      ascii_char([?.])
      |> ascii_char([?0..?9])
      |> repeat(ascii_char([?0..?9]))
    )
    |> tag(:number)
  )

  # --- Symbol ---
  defparsec(
    :symbol,
    ascii_char([?a..?z, ?A..?Z, ?_, ?-, ?., ?+, ?*, ?/, ?<, ?>, ?=, ?!, ??, ?@])
    |> repeat(
      ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_, ?-, ?., ?+, ?*, ?/, ?<, ?>, ?=, ?!, ??, ?@])
    )
    |> tag(:symbol)
  )

  # --- Keyword ---
  defparsec(
    :keyword,
    ascii_char([?:])
    |> ascii_char([?a..?z, ?A..?Z, ?_, ?-])
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?_, ?-, ?0..?9]))
    |> tag(:keyword)
  )

  # --- Delimiters ---
  defparsec(:paren_open, ascii_char([?(]) |> unwrap_and_tag(:paren_open))
  defparsec(:paren_close, ascii_char([?)]) |> unwrap_and_tag(:paren_close))
  defparsec(:bracket_open, ascii_char([?[]) |> unwrap_and_tag(:bracket_open))
  defparsec(:bracket_close, ascii_char([?]]) |> unwrap_and_tag(:bracket_close))
  defparsec(:brace_open, ascii_char([?{]) |> unwrap_and_tag(:brace_open))
  defparsec(:brace_close, ascii_char([?}]) |> unwrap_and_tag(:brace_close))

  # --- Discard ---
  defparsec(:discard, string("#_") |> tag(:discard))

  # --- Comment ---
  defparsec(
    :comment,
    ascii_char([?;])
    |> repeat(lookahead_not(ascii_char([?\n])) |> utf8_char([]))
    |> ignore()
  )

  # --- Token ---
  defparsec(
    :token,
    parsec(:ws)
    |> choice([
      parsec(:comment),
      parsec(:string),
      parsec(:number),
      parsec(:keyword),
      parsec(:discard),
      parsec(:paren_open),
      parsec(:paren_close),
      parsec(:bracket_open),
      parsec(:bracket_close),
      parsec(:brace_open),
      parsec(:brace_close),
      parsec(:symbol)
    ])
  )

  # --- Main Lexer ---
  defparsec(:lex, repeat(parsec(:token)))

  # --- Public API ---
  def tokenize(source) when is_binary(source) do
    case lex(source) do
      {:ok, tokens, "", _context, _line, _column} ->
        {:ok, normalize_tokens(tokens)}

      {:ok, _tokens, rest, _context, _line, _column} ->
        {:error, "unexpected token: #{inspect(rest)}", 1, 1}

      {:error, reason, _rest, _context, line, column} ->
        {:error, reason, line, column}
    end
  end

  # Convert keyword list format from NimbleParsec to tuple format
  defp normalize_tokens(tokens) do
    Enum.map(tokens, fn
      {tag, value} when is_list(value) ->
        {tag, value}

      {tag, value} ->
        {tag, value}

      other ->
        other
    end)
  end

  def lex_with_positions(source) when is_binary(source) do
    case lex(source) do
      {:ok, tokens} ->
        positions = stream_positions(source)
        {:ok, add_positions(tokens, positions)}

      other ->
        other
    end
  end

  defp stream_positions(source) do
    source
    |> String.graphemes()
    |> Enum.reduce({1, 1, []}, fn
      "\n", {line, _col, acc} -> {line + 1, 1, [{line + 1, 1} | acc]}
      _char, {line, col, acc} -> {line, col + 1, [{line, col} | acc]}
    end)
    |> elem(2)
    |> Enum.reverse()
    |> List.to_tuple()
  end

  defp add_positions(tokens, positions) do
    tokens
    |> Enum.with_index()
    |> Enum.map(fn
      {[{tag, value}], idx} ->
        pos = elem(positions, idx)
        {tag, value, elem(pos, 0), elem(pos, 1)}

      {[tag], idx} when is_atom(tag) ->
        pos = elem(positions, idx)
        {tag, elem(pos, 0), elem(pos, 1)}

      {token, _idx} ->
        token
    end)
  end
end
