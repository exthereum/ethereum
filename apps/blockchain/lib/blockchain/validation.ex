defmodule Blockchain.Block.Validation do
  @moduledoc """
  This module provides functions to validate a block.
  """
  alias Blockchain.Block

  @doc """
  Determines whether or not a block is valid. This is
  defined in Eq.(29) of the Yellow Paper.

  Note, this is a serious intensive operation, and not
  faint of heart (since we need to run all transaction
  in the block to validate the block).

  ## Examples

      iex> db = MerklePatriciaTree.Test.random_ets_db()
      iex> chain = Blockchain.Test.ropsten_chain()
      iex> beneficiary = <<0x05::160>>
      iex> private_key = <<1::256>>
      iex> sender = <<126, 95, 69, 82, 9, 26, 105, 18, 93, 93, 252, 183, 184, 194, 101, 144, 41, 57, 91, 223>> # based on simple private key
      iex> machine_code = EVM.MachineCode.compile([:push1, 3, :push1, 5, :add, :push1, 0x00, :mstore, :push1, 0, :push1, 32, :return])
      iex> trx = %Blockchain.Transaction{nonce: 5, gas_price: 3, gas_limit: 100_000, to: <<>>, value: 5, init: machine_code}
      ...>       |> Blockchain.Transaction.Signature.sign_transaction(private_key)
      iex> state = MerklePatriciaTree.Trie.new(db)
      ...>         |> Blockchain.Account.put_account(sender, %Blockchain.Account{balance: 400_000, nonce: 5})
      iex> parent_block = %Blockchain.Block{header: %EVM.Block.Header{number: 50, state_root: state.root_hash, difficulty: 50_000, timestamp: 9999, gas_limit: 125_001}}
      iex> block = Blockchain.Block.gen_child_block(parent_block, chain, beneficiary: beneficiary, timestamp: 10000, gas_limit: 125_001)
      ...>         |> Blockchain.Block.add_transactions_to_block([trx], db)
      ...>         |> Blockchain.Block.add_rewards_to_block(db)
      iex> Blockchain.Block.Validation.is_holistic_valid?(block, chain, parent_block, db)
      :valid

      iex> db = MerklePatriciaTree.Test.random_ets_db()
      iex> chain = Blockchain.Test.ropsten_chain()
      iex> beneficiary = <<0x05::160>>
      iex> private_key = <<1::256>>
      iex> sender = <<126, 95, 69, 82, 9, 26, 105, 18, 93, 93, 252, 183, 184, 194, 101, 144, 41, 57, 91, 223>> # based on simple private key
      iex> machine_code = EVM.MachineCode.compile([:push1, 3, :push1, 5, :add, :push1, 0x00, :mstore, :push1, 0, :push1, 32, :return])
      iex> trx = %Blockchain.Transaction{nonce: 5, gas_price: 3, gas_limit: 100_000, to: <<>>, value: 5, init: machine_code}
      ...>       |> Blockchain.Transaction.Signature.sign_transaction(private_key)
      iex> state = MerklePatriciaTree.Trie.new(db)
      ...>         |> Blockchain.Account.put_account(sender, %Blockchain.Account{balance: 400_000, nonce: 5})
      iex> parent_block = %Blockchain.Block{header: %EVM.Block.Header{number: 50, state_root: state.root_hash, difficulty: 50_000, timestamp: 9999, gas_limit: 125_001}}
      iex> block = Blockchain.Block.gen_child_block(parent_block, chain, beneficiary: beneficiary, timestamp: 10000, gas_limit: 125_001)
      ...>         |> Blockchain.Block.add_transactions_to_block([trx], db)
      iex> %{block | header: %{block.header | state_root: <<1,2,3>>, ommers_hash: <<2,3,4>>, transactions_root: <<3,4,5>>, receipts_root: <<4,5,6>>}}
      ...> |> Blockchain.Block.Validation.is_holistic_valid?(chain, parent_block, db)
      {:invalid, [:state_root_mismatch, :ommers_hash_mismatch, :transactions_root_mismatch, :receipts_root_mismatch]}
  """
  @spec is_holistic_valid?(Block.t(), Chain.t(), Block.t() | nil, DB.db()) ::
          :valid | {:invalid, [atom()]}
  def is_holistic_valid?(block, chain, parent_block, db) do
    base_block =
      if parent_block |> is_nil do
        Block.gen_genesis_block(chain, db)
      else
        Block.gen_child_block(
          parent_block,
          chain,
          beneficiary: block.header.beneficiary,
          timestamp: block.header.timestamp,
          gas_limit: block.header.gas_limit,
          extra_data: block.header.extra_data
        )
      end

    child_block =
      base_block
      |> Block.add_transactions_to_block(block.transactions, db)
      |> Block.add_ommers_to_block(block.ommers)
      |> Block.add_rewards_to_block(db, chain.params[:block_reward])

    # The following checks Holistic Validity, as defined in Eq.(29)
    errors =
      [] ++
        if child_block.header.state_root == block.header.state_root,
          do: [],
          else:
            [:state_root_mismatch] ++
              if(
                child_block.header.ommers_hash == block.header.ommers_hash,
                do: [],
                else:
                  [:ommers_hash_mismatch] ++
                    if(
                      child_block.header.transactions_root == block.header.transactions_root,
                      do: [],
                      else:
                        [:transactions_root_mismatch] ++
                          if(
                            child_block.header.receipts_root == block.header.receipts_root,
                            do: [],
                            else: [:receipts_root_mismatch]
                          )
                    )
              )

    if errors == [], do: :valid, else: {:invalid, errors}
  end
end
