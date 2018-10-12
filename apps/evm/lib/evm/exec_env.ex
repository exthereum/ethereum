defmodule EVM.ExecEnv do
  alias EVM.Interface.AccountInterface

  @moduledoc """
  Stores information about the execution environment which led
  to this EVM being called. This is, for instance, the sender of
  a payment or message to a contract, or a sub-contract call.

  We've added our interfaces for interacting with contracts
  and accounts to this struct as well.

  This generally relates to `I` in the Yellow Paper, defined in
  Section 9.3.
  """
  # a
  defstruct address: nil,
            # o
            originator: nil,
            # p
            gas_price: nil,
            # d
            data: nil,
            # s
            sender: nil,
            # v
            value_in_wei: nil,
            # b
            machine_code: <<>>,
            # e
            stack_depth: 0,
            # h (wrapped in interface)
            block_interface: nil,
            account_interface: nil

  @type t :: %__MODULE__{
          address: EVM.address(),
          originator: EVM.address(),
          gas_price: EVM.Gas.gas_price(),
          data: binary(),
          sender: EVM.address(),
          value_in_wei: EVM.Wei.t(),
          machine_code: EVM.MachineCode.t(),
          stack_depth: integer(),
          block_interface: EVM.Interface.BlockInterface.t(),
          account_interface: EVM.Interface.AccountInterface.t()
        }

  @spec put_storage(t(), integer(), integer()) :: t()
  def put_storage(
        exec_env = %{account_interface: account_interface, address: address},
        key,
        value
      ) do
    account_interface =
      account_interface
      |> AccountInterface.put_storage(address, key, value)

    Map.put(exec_env, :account_interface, account_interface)
  end

  @spec get_storage(t(), integer()) :: {:ok, integer()} | :account_not_found | :key_not_found
  def get_storage(_exec_env = %{account_interface: account_interface, address: address}, key) do
    AccountInterface.get_storage(account_interface, address, key)
  end

  @spec suicide_account(t()) :: t()
  def suicide_account(exec_env = %{account_interface: account_interface, address: address}) do
    account_interface =
      account_interface
      |> AccountInterface.suicide_account(address)

    Map.put(exec_env, :account_interface, account_interface)
  end

  def tranfer_wei_to(exec_env, to, value) do
    account_interface =
      exec_env.account_interface
      |> AccountInterface.transfer(exec_env.address, to, value)

    %{exec_env | account_interface: account_interface}
  end
end
