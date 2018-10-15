defmodule ABI.Parser do
  @moduledoc false

  @doc false
  def parse!(str, opts \\ []) do
    {:ok, tokens0, _} = str |> String.to_charlist() |> :ethereum_abi_lexer.string()

    tokens =
      case opts[:as] do
        nil -> tokens0
        :type -> [{:"expecting type", 1} | tokens0]
        :selector -> [{:"expecting selector", 1} | tokens0]
      end

    {:ok, ast} = :ethereum_abi_parser.parse(tokens)

    case ast do
      {:type, type} -> type
      {:selector, selector_parts} -> struct!(ABI.FunctionSelector, selector_parts)
    end
  end
end
