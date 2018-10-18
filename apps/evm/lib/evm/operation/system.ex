defmodule EVM.Operation.System do
  alias EVM.VM
  alias EVM.Address
  alias EVM.Functions
  alias EVM.MachineState
  alias EVM.Memory
  alias EVM.ExecEnv
  alias EVM.Interface.AccountInterface
  #  alias EVM.Interface.BlockInterface
  #  alias EVM.Helpers
  alias EVM.Address
  alias EVM.Stack
  alias EVM.Operation
  alias Blockchain

  @moduledoc """
    Module provides system EVM OPCODE implementations:
    Return - Halt execution returning output data
    Call - Message-call into an account
    Suicide (SELFDESTRUCT) - Halt execution and register account for later deletion
  """

  @doc """
     Message-call into an account. Transfer `value` wei from callers account to callees account then run the code in that account.

    ## Examples

        iex> account_map = %{
        ...>   <<0::160>> => %{balance: 100, nonce: 5, code: <<>>},
        ...>   <<1::160>> => %{balance: 100, nonce: 5, code: <<>>},
        ...>   <<2::160>> => %{balance: 100, nonce: 5, code: <<>>},
        ...> }
        iex> account_interface = EVM.Interface.Mock.MockAccountInterface.new(account_map)
        iex> exec_env = %EVM.ExecEnv{
        ...>   account_interface: account_interface,
        ...>   sender: <<0::160>>,
        ...>   address: <<0::160>>
        ...> }
        iex> machine_state = %EVM.MachineState{gas: 1000}
        iex> %{machine_state: machine_state, exec_env: exec_env} =
        ...> EVM.Operation.System.call([10, 1, 1, 0, 0, 0, 0],
        ...>   %{exec_env: exec_env, machine_state: machine_state})
        iex> EVM.Stack.peek(machine_state.stack)
        1
        iex> exec_env.account_interface
        ...>   |> EVM.Interface.AccountInterface.get_account_balance(<<0::160>>)
        99
        iex> exec_env.account_interface
        ...>   |> EVM.Interface.AccountInterface.get_account_balance(<<1::160>>)
        101
  """
  @spec call(Operation.stack_args(), Operation.vm_map()) :: Operation.op_result()
  def call([call_gas, to, value, in_offset, in_size, out_offset, _out_size], %{
        exec_env: exec_env,
        machine_state: machine_state
      }) do
    to = if is_number(to), do: Address.new(to), else: to
    {data, machine_state} = Memory.read(machine_state, in_offset, in_size)

    account_balance =
      AccountInterface.get_account_balance(exec_env.account_interface, exec_env.address)

    machine_code = AccountInterface.get_account_code(exec_env.account_interface, to)

    if call_gas <= account_balance && exec_env.stack_depth < Functions.max_stack_depth() do
      exec_env = ExecEnv.tranfer_wei_to(exec_env, to, value)

      {n_gas, _n_sub_state, n_exec_env, n_output} =
        VM.run(
          call_gas,
          Map.merge(exec_env, %{
            # a
            address: to,
            # s
            sender: exec_env.address,
            # d
            data: data,
            # v
            value_in_wei: value,
            # b
            machine_code: machine_code,
            # e
            stack_depth: exec_env.stack_depth + 1
          })
        )

      exec_env = %{exec_env | account_interface: n_exec_env.account_interface}
      # TODO: Set n_account_interface

      machine_state = Memory.write(machine_state, out_offset, n_output)
      machine_state = %{machine_state | gas: machine_state.gas + n_gas}
      # Return 1: 1 = success, 0 = failure
      # TODO Check if the call was actually successful
      machine_state = %{machine_state | stack: Stack.push(machine_state.stack, 1)}

      %{
        machine_state: machine_state,
        exec_env: exec_env
        # TODO: sub_state
      }
    else
      %{
        machine_state: %{machine_state | stack: Stack.push(machine_state.stack, 0)}
      }
    end
  end

  @doc """
  Halt execution returning output data,

  ## Examples

      iex> EVM.Operation.System.return([5, 33], %{machine_state: %EVM.MachineState{active_words: 0}})
      %EVM.MachineState{active_words: 2}

      iex> EVM.Operation.System.return([5, 33], %{machine_state: %EVM.MachineState{active_words: 5}})
      %EVM.MachineState{active_words: 5}
  """
  @spec return(Operation.stack_args(), Operation.vm_map()) :: Operation.op_result()
  def return([_mem_start, mem_end], %{machine_state: machine_state}) do
    # We may have to bump up number of active words
    machine_state |> MachineState.maybe_set_active_words(Memory.get_active_words(mem_end))
  end

  @doc """
  Halt execution and register account for later deletion.

  ## Examples

      iex> address = 0x0000000000000000000000000000000000000001
      iex> suicide_address = 0x0000000000000000000000000000000000000001
      iex> account_map = %{address => %{balance: 5_000, nonce: 5}}
      iex> account_interface = EVM.Interface.Mock.MockAccountInterface.new(account_map)
      iex> account_interface = EVM.Operation.System.suicide([suicide_address], %{stack: [], exec_env: %EVM.ExecEnv{address: address, account_interface: account_interface} })[:exec_env].account_interface
      iex> account_interface |> EVM.Interface.AccountInterface.dump_storage |> Map.get(address)
      nil
  """
  @spec suicide(Operation.stack_args(), Operation.vm_map()) :: Operation.op_result()
  def suicide([_suicide_address], %{exec_env: exec_env}) do
    %{exec_env: ExecEnv.suicide_account(exec_env)}
  end
end
