defmodule CaseStyle.SnakeCase do
  @moduledoc """
  Module for converting from and to snake_case
  """
  defstruct tokens: []

  @behaviour CaseStyle

  alias CaseStyle.Tokens

  alias CaseStyle.Tokens.{
    AfterSpacingChar,
    AfterSpacingDigit,
    Char,
    Digit,
    End,
    FirstLetter,
    Literal,
    Spacing,
    Start
  }

  @type t :: %__MODULE__{tokens: Tokens.t()}

  use AbnfParsec,
    abnf_file: "priv/case_style/snake_case.abnf",
    unbox: [
      "lowerchar",
      "upperchar",
      "char",
      "case",
      "string",
      "digit",
      "spacing-char",
      "double-underscore"
    ],
    parse: :case,
    transform: %{
      "case" => {:post_traverse, :post_processing}
    }

  @external_resource "priv/case_style/snake_case.abnf"

  defp post_processing(a, b, c, _d, _e) do
    tokens = [%End{}] ++ Enum.flat_map(b, &parse_token/1) ++ [%Start{}]
    {a, tokens, c}
  end

  defp parse_token({:first_char, s}), do: [%FirstLetter{value: s}]
  defp parse_token({:lowercase, s}), do: [%Char{value: s}]
  defp parse_token({:lowercase_spacing, [_, s]}), do: [%AfterSpacingChar{value: [s]}, %Spacing{}]
  defp parse_token({:uppercase, s}), do: [%Char{value: s}]
  defp parse_token({:uppercase_spacing, [_, s]}), do: [%AfterSpacingChar{value: [s]}, %Spacing{}]
  defp parse_token({:digitchar, s}), do: [%Digit{value: s}]
  defp parse_token({:digitchar_spacing, [_, s]}), do: [%AfterSpacingDigit{value: [s]}, %Spacing{}]
  defp parse_token({:string, [s]}), do: [%Literal{value: s}]
  defp parse_token({:literal, ["__"]}), do: [%Literal{value: "__"}]
  defp parse_token({:literal, s}), do: [%Literal{value: s}]
  defp parse_token("_"), do: [%Spacing{}]

  @impl true
  def to_string(%CaseStyle{tokens: tokens}) do
    Enum.map_join(tokens, &stringify_token/1)
  end

  @spec stringify_token(Tokens.possible_tokens()) :: charlist
  defp stringify_token(%module{}) when module in [Start, End], do: ~c""
  defp stringify_token(%Spacing{}), do: ~c"_"

  defp stringify_token(%module{value: [x]})
       when module in [FirstLetter, Char, AfterSpacingChar] and x in ?A..?Z,
       do: [x + 32]

  defp stringify_token(%module{value: x}) when module in [FirstLetter, Char, AfterSpacingChar],
    do: x

  defp stringify_token(%module{value: x}) when module in [Digit, AfterSpacingDigit], do: x
  defp stringify_token(%Literal{value: x}), do: x

  @deprecated "use matches?/1 instead"
  defdelegate might_be?(input), to: __MODULE__, as: :matches?

  @lowercase_digits_and_underscore Enum.concat([?a..?z, ?0..?9, ~c"_"])
  @impl true
  def matches?(input) do
    input
    |> String.to_charlist()
    |> Enum.all?(fn x -> x in @lowercase_digits_and_underscore end)
  end
end
