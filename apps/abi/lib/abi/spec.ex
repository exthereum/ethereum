defmodule ABI.Spec do
  @moduledoc """
  The ABI Specification comes from JSON files generated
  when building an application in Solidity or other EVM-based
  language. ABI Specifications include a list of publically
  accessible functions and their arguments and return values.

  This library parses those specifications, which it assumes
  have already been parsed from JSON.
  """
  alias ABI.FunctionSelector
  @type abi_entry :: %{}
  @type abi_input :: list(abi_entry())

  @type type :: String.t()
  @type state_mutability :: nil | :view | :nonpayable
  @type abi_type :: nil | :event | :function | :constructor | :fallback

  @type io_data_type :: %{
          type: type,
          name: String.t(),
          indexed: boolean()
        }

  @type t :: %{
          constant: boolean(),
          inputs: list(io_data_type()),
          name: String.t(),
          outputs: list(io_data_type()),
          payable: boolean(),
          state_mutability: state_mutability(),
          abi_type: abi_type()
        }

  defstruct constant: false,
            inputs: [],
            name: "",
            outputs: [],
            payable: false,
            state_mutability: nil,
            abi_type: nil

  @doc """
  Parses an ABI specification and returns an ABI.Spec struct
  that can be used with other library functions.
  """
  @spec load_specs(abi_input()) :: {:ok, list(t)} | {:error, any()}
  def load_specs(abi_input) do
    Enum.reduce(abi_input, {:ok, []}, fn
      _el, err = {:error, _} ->
        err

      abi_entry, {:ok, entries} ->
        with {:ok, entry} <- load_spec(abi_entry) do
          {:ok, [entry | entries]}
        end
    end)
  end

  @doc """
  Parses a single ABI specification and returns an ABI.Spec struct.
  """
  @spec load_spec(abi_entry()) :: {:ok, ABI.Spec.t()} | {:error, any()}
  def load_spec(abi_entry) do
    # Note, while this doesn't currently return an errors, it makes sense
    # to create the specification to allow it, since there are plenty
    # of invalid cases that might be swallowed here.

    {:ok,
     %ABI.Spec{
       constant: abi_entry["constant"] == true,
       name: abi_entry["name"],
       inputs: (abi_entry["inputs"] || []) |> Enum.map(&parse_data_type/1),
       outputs: (abi_entry["outputs"] || []) |> Enum.map(&parse_data_type/1),
       payable: abi_entry["payable"] == true,
       state_mutability: get_state_mutability(abi_entry["stateMutability"]),
       abi_type: get_abi_type(abi_entry["type"])
     }}
  end

  @doc """
  Returns a function selector for the input. This can be used with
  the ABI library functions.
  """
  @spec input_function_selector(Spec.t()) :: FunctionSelector.t()
  def input_function_selector(spec) do
    types =
      spec.inputs
      |> Enum.map(fn entry -> entry.type end)
      |> Enum.map(&FunctionSelector.decode_type/1)

    %ABI.FunctionSelector{
      function: spec.name,
      types: types
    }
  end

  @doc """
  Returns a function selector for the output of a function. This can be used with
  the ABI library functions.
  """
  @spec output_function_selector(ABI.Spec.t()) :: FunctionSelector.t()
  def output_function_selector(spec) do
    types =
      spec.outputs
      |> Enum.map(fn entry -> entry.type end)
      |> Enum.map(&FunctionSelector.decode_type/1)

    %FunctionSelector{
      types: types
    }
  end

  @spec parse_data_type(%{}) :: io_data_type()
  defp parse_data_type(data_type) do
    %{
      name: data_type["name"],
      type: data_type["type"],
      indexed: data_type["indexed"] == true
    }
  end

  @spec get_state_mutability(String.t()) :: state_mutability()
  defp get_state_mutability(state_mutability) do
    case state_mutability do
      "view" -> :view
      "nonpayable" -> :nonpayable
      _ -> nil
    end
  end

  @spec get_abi_type(String.t()) :: abi_type()
  defp get_abi_type(type) do
    case type do
      "function" -> :function
      "event" -> :event
      "fallback" -> :fallback
      "constructor" -> :constructor
      _ -> nil
    end
  end
end
