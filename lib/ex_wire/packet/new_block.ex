defmodule ExWire.Packet.NewBlock do
  @moduledoc """
  Eth Wire Packet for advertising new blocks.

  ```
  **NewBlock** [`+0x07`, [`blockHeader`, `transactionList`, `uncleList`], `totalDifficulty`]

  Specify a single block that the peer should know about. The composite item in
  the list (following the message ID) is a block in the format described in the
  main Ethereum specification.

  * `totalDifficulty` is the total difficulty of the block (aka score).
  ```
  """

  require Logger

  alias Block.Header
  alias ExWire.Struct.Block

  @behaviour ExWire.Packet

  @type t :: %__MODULE__{
    block_header: Header.t,
    block: Block.t,
    total_difficulty: integer()
  }

  defstruct [
    :block_header,
    :block,
    :total_difficulty
  ]

  @doc """
  Given a NewBlock packet, serializes for transport over Eth Wire Protocol.

  ## Examples

      iex> %ExWire.Packet.NewBlock{
      ...>   block_header: %Block.Header{parent_hash: <<1::256>>, ommers_hash: <<2::256>>, beneficiary: <<3::160>>, state_root: <<4::256>>, transactions_root: <<5::256>>, receipts_root: <<6::256>>, logs_bloom: <<>>, difficulty: 5, number: 1, gas_limit: 5, gas_used: 3, timestamp: 6, extra_data: "Hi mom", mix_hash: <<7::256>>, nonce: <<8::64>>},
      ...>   block: %ExWire.Struct.Block{transaction_list: [], uncle_list: []},
      ...>   total_difficulty: 100_000
      ...> }
      ...> |> ExWire.Packet.NewBlock.serialize
      [
        [<<1::256>>, <<2::256>>, <<3::160>>, <<4::256>>, <<5::256>>, <<6::256>>, <<>>, 5, 1, 5, 3, 6, "Hi mom", <<7::256>>, <<8::64>>],
        [],
        [],
        100000
      ]
  """
  @spec serialize(t) :: ExRLP.t
  def serialize(packet=%__MODULE__{}) do
    [trx_list, uncle_list] = Block.serialize(packet.block)

    [
      Header.serialize(packet.block_header),
      trx_list,
      uncle_list,
      packet.total_difficulty
    ]
  end

  @doc """
  Given an RLP-encoded NewBlock packet from Eth Wire Protocol,
  decodes into a NewBlock struct.

  ## Examples

      iex> [
      ...>   [<<1::256>>, <<2::256>>, <<3::160>>, <<4::256>>, <<5::256>>, <<6::256>>, <<>>, <<5>>, <<1>>, <<5>>, <<3>>, <<6>>, "Hi mom", <<7::256>>, <<8::64>>],
      ...>   [],
      ...>   [],
      ...>   <<10>>
      ...> ]
      ...> |> ExWire.Packet.NewBlock.deserialize()
      %ExWire.Packet.NewBlock{
        block_header: %Block.Header{parent_hash: <<1::256>>, ommers_hash: <<2::256>>, beneficiary: <<3::160>>, state_root: <<4::256>>, transactions_root: <<5::256>>, receipts_root: <<6::256>>, logs_bloom: <<>>, difficulty: 5, number: 1, gas_limit: 5, gas_used: 3, timestamp: 6, extra_data: "Hi mom", mix_hash: <<7::256>>, nonce: <<8::64>>},
        block: %ExWire.Struct.Block{transaction_list: [], uncle_list: []},
        total_difficulty: 10
      }
  """
  @spec deserialize(ExRLP.t) :: t
  def deserialize(rlp) do
    [
      block_header,
      trx_list,
      uncle_list,
      total_difficulty
    ] = rlp

    %__MODULE__{
      block_header: Header.deserialize(block_header),
      block: Block.deserialize([trx_list, uncle_list]),
      total_difficulty: total_difficulty |> :binary.decode_unsigned
    }
  end

  @doc """
  Handles a NewBlock message. Right now, we ignore these advertisements.

  ## Examples

      iex> %ExWire.Packet.NewBlock{
      ...>   block_header: %Block.Header{parent_hash: <<1::256>>, ommers_hash: <<2::256>>, beneficiary: <<3::160>>, state_root: <<4::256>>, transactions_root: <<5::256>>, receipts_root: <<6::256>>, logs_bloom: <<>>, difficulty: 5, number: 1, gas_limit: 5, gas_used: 3, timestamp: 6, extra_data: "Hi mom", mix_hash: <<7::256>>, nonce: <<8::64>>},
      ...>   block: %ExWire.Struct.Block{transaction_list: [], uncle_list: []},
      ...>   total_difficulty: 100_000
      ...> }
      ...> |> ExWire.Packet.NewBlock.handle()
      :ok
  """
  @spec handle(ExWire.Packet.packet) :: ExWire.Packet.handle_response
  def handle(packet=%__MODULE__{}) do
    Logger.debug("[Packet] Peer sent new block with hash #{packet.block_header |> Header.hash |> ExthCrypto.Math.bin_to_hex}")

    :ok
  end

end
