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
          machine_code: MachineCode.t(),
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

  @doc """
  Creates an execution environment for a create contract call.

  This is defined in Eq.(88), Eq.(89), Eq.(90), Eq.(91), Eq.(92),
  Eq.(93), Eq.(94) and Eq.(95) of the Yellow Paper.

  ## Examples

      iex> db = MerklePatriciaTree.Test.random_ets_db(:create_contract_exec_env)
      iex> state = MerklePatriciaTree.Trie.new(db)
      iex> EVM.ExecEnv.create_contract_exec_env([address: <<0x01::160>>, originator: <<0x02::160>>, gas_price: 5, sender: <<0x03::160>>, value_in_wei: 6, machine_code: <<1, 2, 3>>, stack_depth: 14, block_header: %EVM.Block.Header{nonce: 1}, state: state], Blockchain.Interface.BlockInterface, Blockchain.Interface.AccountInterface)
      %EVM.ExecEnv{
        address: <<0x01::160>>,
        originator: <<0x02::160>>,
        gas_price: 5,
        data: <<>>,
        sender: <<0x03::160>>,
        value_in_wei: 6,
        machine_code: <<1, 2, 3>>,
        stack_depth: 14,
        block_interface: %Blockchain.Interface.BlockInterface{block_header: %EVM.Block.Header{nonce: 1}, db: {MerklePatriciaTree.DB.ETS, :create_contract_exec_env}},
        account_interface: %Blockchain.Interface.AccountInterface{state: %MerklePatriciaTree.Trie{db: {MerklePatriciaTree.DB.ETS, :create_contract_exec_env}, root_hash: <<86, 232, 31, 23, 27, 204, 85, 166, 255, 131, 69, 230, 146, 192, 248, 110, 91, 72, 224, 27, 153, 108, 173, 192, 1, 98, 47, 181, 227, 99, 180, 33>>}}
      }
  """

  @spec create_contract_exec_env(
          Keyword.t(),
          EVM.Interface.BlockInterface.t(),
          EVM.Interface.AccountInterface.t()
        ) :: EVM.ExecEnv.t()
  def create_contract_exec_env(
        param = [
          address: _contract_address,
          originator: _originator,
          gas_price: _gas_price,
          sender: _sender,
          value_in_wei: _endowment,
          machine_code: _init_code,
          stack_depth: _stack_depth,
          block_header: block_header,
          state: state
        ],
        block_interface,
        account_interface
      ) do
    struct(
      __MODULE__,
      Keyword.merge(param,
        data: <<>>,
        block_interface: block_interface.new(block_header, state.db),
        account_interface: account_interface.new(state)
      )
    )
  end

  @doc """
  Creates an execution environment for a message call.

  This is defined in Eq.(107), Eq.(108), Eq.(109), Eq.(110),
  Eq.(111), Eq.(112), Eq.(113) and Eq.(114) of the Yellow Paper.

  ## Examples

      iex> db = MerklePatriciaTree.Test.random_ets_db(:create_message_call_exec_env)
      iex> state = MerklePatriciaTree.Trie.new(db)
      iex> EVM.ExecEnv.create_message_call_exec_env([sender: <<0x01::160>>, originator: <<0x02::160>>, address: <<0x03::160>>, gas_price: 4, value_in_wei: 5, data: <<1, 2, 3>>, stack_depth: 14, machine_code: <<2, 3, 4>>, block_header: %EVM.Block.Header{nonce: 1}, state: state], Blockchain.Interface.BlockInterface, Blockchain.Interface.AccountInterface)
      %EVM.ExecEnv{
        address: <<0x03::160>>,
        originator: <<0x02::160>>,
        gas_price: 4,
        data: <<1, 2, 3>>,
        sender: <<0x01::160>>,
        value_in_wei: 5,
        machine_code: <<2, 3, 4>>,
        stack_depth: 14,
        block_interface: %Blockchain.Interface.BlockInterface{block_header: %EVM.Block.Header{nonce: 1}, db: {MerklePatriciaTree.DB.ETS, :create_message_call_exec_env}},
        account_interface: %Blockchain.Interface.AccountInterface{state: %MerklePatriciaTree.Trie{db: {MerklePatriciaTree.DB.ETS, :create_message_call_exec_env}, root_hash: <<86, 232, 31, 23, 27, 204, 85, 166, 255, 131, 69, 230, 146, 192, 248, 110, 91, 72, 224, 27, 153, 108, 173, 192, 1, 98, 47, 181, 227, 99, 180, 33>>}}
      }
  """

  @spec create_message_call_exec_env(
          Keyword.t(),
          EVM.Interface.BlockInterface.t(),
          EVM.Interface.AccountInterface.t()
        ) :: EVM.ExecEnv.t()
  def create_message_call_exec_env(
        param = [
          sender: _sender,
          originator: _originator,
          address: _recipient,
          gas_price: _gas_price,
          value_in_wei: _apparent_value,
          data: _data,
          stack_depth: _stack_depth,
          machine_code: _machine_code,
          block_header: block_header,
          state: state
        ],
        block_interface,
        account_interface
      ) do
    struct(
      __MODULE__,
      Keyword.merge(param,
        block_interface: block_interface.new(block_header, state.db),
        account_interface: account_interface.new(state)
      )
    )
  end
end
