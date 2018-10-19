defmodule Blockchain.Block.ValidationCheck do
  @moduledoc """
  This module provides implementations to functions that validate a block.
  Holistic Validity, as defined in Eq.(31), section 4.3.2 of Yellow Paper
  """
  alias Blockchain.Block

  @type errors ::
          list(
            :state_root_mismatch
            | :ommers_hash_mismatch
            | :transactions_root_mismatch
            | :receipts_root_mismatch
          )

  @spec state_root_match(Block.t(), Block.t()) :: :state_root_mismatch | []
  def state_root_match(child_block, block),
    do: do_state_root_match(child_block.header.state_root, block.header.state_root)

  @spec ommers_hash_match(Block.t(), Block.t()) :: :ommers_hash_mismatch | []
  def ommers_hash_match(child_block, block),
    do: do_ommers_hash_match(child_block.header.ommers_hash, block.header.ommers_hash)

  @spec transactions_root_match(Block.t(), Block.t()) :: :transactions_root_mismatch | []
  def transactions_root_match(child_block, block),
    do:
      do_transactions_root_match(
        child_block.header.transactions_root,
        block.header.transactions_root
      )

  @spec receipts_root_match(Block.t(), Block.t()) :: :receipts_root_mismatch | []
  def receipts_root_match(child_block, block),
    do: do_receipts_root_match(child_block.header.receipts_root, block.header.receipts_root)

  defp do_state_root_match(state_root, state_root), do: []
  defp do_state_root_match(_, _), do: :state_root_mismatch

  defp do_ommers_hash_match(ommers_hash, ommers_hash), do: []
  defp do_ommers_hash_match(_, _), do: :ommers_hash_mismatch

  defp do_transactions_root_match(transactions_root, transactions_root), do: []
  defp do_transactions_root_match(_, _), do: :transactions_root_mismatch

  defp do_receipts_root_match(receipts_root, receipts_root), do: []
  defp do_receipts_root_match(_, _), do: :receipts_root_mismatch
end
