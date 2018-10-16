defmodule ABI.SpecTest do
  use ExUnit.Case, async: true
  alias ABI.Spec

  @abi_json """
  [
    {
      "type": "event",
      "name": "Failure",
      "inputs": [
        {
          "type": "uint256",
          "name": "error",
          "indexed": false
        },
        {
          "type": "uint256",
          "name": "info",
          "indexed": false
        },
        {
          "type": "uint256",
          "name": "detail",
          "indexed": false
        }
      ],
      "anonymous": false
    },
    {
      "type": "function",
      "stateMutability": "view",
      "payable": false,
      "outputs": [
        {
          "type": "uint256",
          "name": ""
        },
        {
          "type": "uint256",
          "name": ""
        }
      ],
      "name": "getSupplyRate",
      "inputs": [
        {
          "type": "address",
          "name": "_asset"
        },
        {
          "type": "uint256",
          "name": "cash"
        },
        {
          "type": "uint256",
          "name": "borrows"
        }
      ],
      "constant": true
    },
    {
      "type": "function",
      "stateMutability": "view",
      "payable": false,
      "outputs": [
        {
          "type": "uint256",
          "name": ""
        },
        {
          "type": "uint256",
          "name": ""
        }
      ],
      "name": "getBorrowRate",
      "inputs": [
        {
          "type": "address",
          "name": "_asset"
        },
        {
          "type": "uint256",
          "name": "cash"
        },
        {
          "type": "uint256",
          "name": "borrows"
        }
      ],
      "constant": true
    }
  ]
  """

  @expected {:ok,
             [
               %ABI.Spec{
                 abi_type: :function,
                 constant: true,
                 inputs: [
                   %{indexed: false, name: "_asset", type: "address"},
                   %{indexed: false, name: "cash", type: "uint256"},
                   %{indexed: false, name: "borrows", type: "uint256"}
                 ],
                 name: "getBorrowRate",
                 outputs: [
                   %{indexed: false, name: "", type: "uint256"},
                   %{indexed: false, name: "", type: "uint256"}
                 ],
                 payable: false,
                 state_mutability: :view
               },
               %ABI.Spec{
                 abi_type: :function,
                 constant: true,
                 inputs: [
                   %{indexed: false, name: "_asset", type: "address"},
                   %{indexed: false, name: "cash", type: "uint256"},
                   %{indexed: false, name: "borrows", type: "uint256"}
                 ],
                 name: "getSupplyRate",
                 outputs: [
                   %{indexed: false, name: "", type: "uint256"},
                   %{indexed: false, name: "", type: "uint256"}
                 ],
                 payable: false,
                 state_mutability: :view
               },
               %ABI.Spec{
                 abi_type: :event,
                 constant: false,
                 inputs: [
                   %{indexed: false, name: "error", type: "uint256"},
                   %{indexed: false, name: "info", type: "uint256"},
                   %{indexed: false, name: "detail", type: "uint256"}
                 ],
                 name: "Failure",
                 outputs: [],
                 payable: false,
                 state_mutability: nil
               }
             ]}

  test "load/1" do
    abi = Poison.decode!(@abi_json)

    assert Spec.load_specs(abi) == @expected
  end

  test "input_function_selector/1" do
    spec = %ABI.Spec{
      abi_type: :function,
      constant: true,
      inputs: [
        %{indexed: false, name: "_asset", type: "address"},
        %{indexed: false, name: "cash", type: "uint256"},
        %{indexed: false, name: "borrows", type: "uint256"}
      ],
      name: "getBorrowRate",
      outputs: [
        %{indexed: false, name: "", type: "uint256"},
        %{indexed: false, name: "", type: "uint256"}
      ],
      payable: false,
      state_mutability: :view
    }

    assert Spec.input_function_selector(spec) == %ABI.FunctionSelector{
      function: "getBorrowRate",
      returns: nil,
      types: [:address, {:uint, 256}, {:uint, 256}]
    }
  end

  test "output_function_selector/1" do
    spec = %ABI.Spec{
      abi_type: :function,
      constant: true,
      inputs: [
        %{indexed: false, name: "_asset", type: "address"},
        %{indexed: false, name: "cash", type: "uint256"},
        %{indexed: false, name: "borrows", type: "uint256"}
      ],
      name: "getBorrowRate",
      outputs: [
        %{indexed: false, name: "", type: "uint256"},
        %{indexed: false, name: "", type: "uint256"}
      ],
      payable: false,
      state_mutability: :view
    }

    assert Spec.output_function_selector(spec) == %ABI.FunctionSelector{
      returns: nil,
      types: [{:uint, 256}, {:uint, 256}]
    }
  end
end
