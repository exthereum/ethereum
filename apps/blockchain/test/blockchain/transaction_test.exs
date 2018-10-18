defmodule Blockchain.TransactionTest do
  use ExUnit.Case, async: true
  use EthCommonTest.Harness
  doctest Blockchain.Transaction

  require Logger

  alias Blockchain.Transaction
  alias Blockchain.Contract
  alias EVM.Block.Header
  alias MerklePatriciaTree.Test
  alias MerklePatriciaTree.Trie
  alias EVM.MachineCode
  alias Blockchain.Transaction.Signature
  alias Blockchain.Account

  # TODO: These eth common test cases have seemed to have moved or no longer
  #       exist. We should add them back when we discover where they moved to.

  # Load filler data
  setup_all do
    # frontier_filler = load_src("TransactionTestsFiller", "ttTransactionTestFiller")
    # homestead_filler = load_src("TransactionTestsFiller/Homestead", "ttTransactionTestFiller")

    # eip155_filler =
    #   load_src("TransactionTestsFiller/EIP155", "ttTransactionTestEip155VitaliksTestsFiller")

    {:ok,
     %{
       # frontier_filler: frontier_filler,
       # homestead_filler: homestead_filler,
       # eip155_filler: eip155_filler
     }}
  end

  # eth_test("TransactionTests", :ttTransactionTest, :all, fn test,
  #                                                           test_subset,
  #                                                           test_name,
  #                                                           %{frontier_filler: filler} ->
  #   trx_data = test["transaction"]
  #   src_data = filler[test_name]
  #   transaction = (trx_data || src_data["transaction"]) |> load_trx

  #   if src_data["expect"] == "invalid" do
  #     # TODO: Include checks of "invalid" tests
  #     Logger.debug(fn ->
  #       "Skipping `invalid` transaction test: TransactionTests - #{test_subset} - #{test_name}"
  #     end)

  #     nil
  #   else
  #     assert transaction |> Transaction.serialize() ==
  #              test["rlp"] |> load_hex |> :binary.encode_unsigned() |> ExRLP.decode()

  #     if test["hash"],
  #       do:
  #         assert(
  #           transaction |> Transaction.serialize() |> ExRLP.encode() |> BitHelper.kec() ==
  #             test["hash"] |> maybe_hex
  #         )

  #     if test["sender"],
  #       do: assert(Signature.sender(transaction) == {:ok, test["sender"] |> maybe_hex})
  #   end
  # end)

  # Test Homestead
  # eth_test("TransactionTests/Homestead", :ttTransactionTest, :all, fn test,
  #                                                                     test_subset,
  #                                                                     test_name,
  #                                                                     %{homestead_filler: filler} ->
  #   trx_data = test["transaction"]
  #   src_data = filler[test_name]
  #   transaction = (trx_data || src_data["transaction"]) |> load_trx

  #   if src_data["expect"] == "invalid" do
  #     # TODO: Include checks of "invalid" tests
  #     Logger.debug(fn ->
  #       "Skipping invalid transaction test: TransactionTests/Homestead - #{test_subset} - #{
  #         test_name
  #       }"
  #     end)

  #     nil
  #   else
  #     assert transaction |> Transaction.serialize() ==
  #              test["rlp"] |> load_hex |> :binary.encode_unsigned() |> ExRLP.decode()

  #     if test["hash"],
  #       do:
  #         assert(
  #           transaction |> Transaction.serialize() |> ExRLP.encode() |> BitHelper.kec() ==
  #             test["hash"] |> maybe_hex
  #         )

  #     if test["sender"],
  #       do: assert(Signature.sender(transaction) == {:ok, test["sender"] |> maybe_hex})
  #   end
  # end)

  # Test EIP155
  # eth_test("TransactionTests/EIP155", :ttTransactionTestEip155VitaliksTests, :all, fn test,
  #                                                                                     test_subset,
  #                                                                                     test_name,
  #                                                                                     %{
  #                                                                                       eip155_filler:
  #                                                                                         filler
  #                                                                                     } ->
  #   trx_data = test["transaction"]
  #   src_data = filler[test_name]
  #   transaction = (trx_data || src_data["transaction"]) |> load_trx
  #   chain_id = 1

  #   if src_data["expect"] == "invalid" do
  #     # TODO: Include checks of "invalid" tests
  #     Logger.debug(fn ->
  #       "Skipping invalid transaction test: TransactionTests/EIP555 - #{test_subset} - #{
  #         test_name
  #       }"
  #     end)

  #     nil
  #   else
  #     assert transaction |> Transaction.serialize() ==
  #              test["rlp"] |> load_hex |> :binary.encode_unsigned() |> ExRLP.decode()

  #     if test["hash"],
  #       do:
  #         assert(
  #           transaction |> Transaction.serialize(chain_id) |> ExRLP.encode() |> BitHelper.kec() ==
  #             test["hash"] |> maybe_hex
  #         )

  #     if test["sender"],
  #       do: assert(Signature.sender(transaction, chain_id) == {:ok, test["sender"] |> maybe_hex})
  #   end
  # end)

  describe "when handling transactions" do
    test "serialize and deserialize" do
      trx = %Transaction{
        nonce: 5,
        gas_price: 6,
        gas_limit: 7,
        to: <<1::160>>,
        value: 8,
        v: 27,
        r: 9,
        s: 10,
        data: "hi"
      }

      assert trx ==
               trx
               |> Transaction.serialize()
               |> ExRLP.encode()
               |> ExRLP.decode()
               |> Transaction.deserialize()
    end

    test "for a transaction with a stop" do
      beneficiary = <<0x05::160>>
      private_key = <<1::256>>
      # based on simple private key
      sender =
        <<126, 95, 69, 82, 9, 26, 105, 18, 93, 93, 252, 183, 184, 194, 101, 144, 41, 57, 91, 223>>

      contract_address = Contract.new_contract_address(sender, 6)
      machine_code = MachineCode.compile([:stop])

      trx =
        %Transaction{
          nonce: 5,
          gas_price: 3,
          gas_limit: 100_000,
          to: <<>>,
          value: 5,
          init: machine_code
        }
        |> Signature.sign_transaction(private_key)

      trie = Trie.new(Test.random_ets_db())

      account =
        Account.put_account(trie, sender, %Account{
          balance: 400_000,
          nonce: 5
        })

      {state, gas_used, logs} =
        Transaction.execute_transaction(account, trx, %Header{
          beneficiary: beneficiary
        })

      assert gas_used == 53004
      assert logs == []

      assert Account.get_accounts(state, [sender, beneficiary, contract_address]) ==
               [
                 %Account{balance: 240_983, nonce: 6},
                 %Account{balance: 159_012},
                 %Account{balance: 5}
               ]
    end
  end
end
