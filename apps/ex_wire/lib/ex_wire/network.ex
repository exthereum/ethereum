defmodule ExWire.Network do
  @moduledoc """
  This module will handle the business logic for processing
  incoming messages from the network. We will, for instance,
  decide to respond pong to any incoming ping.
  """

  require Logger

  alias ExWire.Config
  alias ExWire.Crypto
  alias ExWire.Handler

  alias ExWire.Protocol
  alias ExWire.Struct.Endpoint
  alias ExthCrypto.Signature
  alias ExthCrypto.Key

  defmodule InboundMessage do
    @moduledoc """
    Struct to define an inbound message from a remote peer
    """

    defstruct data: nil,
              server_pid: nil,
              remote_host: nil,
              timestamp: nil

    @type t :: %__MODULE__{
            data: binary(),
            server_pid: pid(),
            remote_host: Endpoint.t(),
            timestamp: integer()
          }
  end

  @type receiver_handler_action :: {:sent_message, ExWire.Message.handlers()} | :no_action
  @type sender_handler_action :: {:sent_message, ExWire.Message.handlers()}

  @doc """
  Top-level receiver function to process an incoming message.
  We'll first validate the message, and then pass it to
  the appropriate handler.

  ## Examples

      iex> ping_data = [1, [<<1,2,3,4>>, <<>>, <<5>>], [<<5,6,7,8>>, <<6>>, <<>>], 4] |> ExRLP.encode
      iex> payload = <<0x01::8>> <> ping_data
      iex> payload_hash = ExWire.Crypto.hash(payload)
      iex> {signature, _r, _s, recovery_bit} = ExthCrypto.Signature.sign_digest(payload_hash, ExthCrypto.Test.private_key)
      iex> total_payload = signature <> <<recovery_bit::8>> <> payload
      iex> hash = ExWire.Crypto.hash(total_payload)
      iex> ExWire.Network.receive(%ExWire.Network.InboundMessage{
      ...>   data: hash <> total_payload,
      ...>   server_pid: self(),
      ...>   remote_host: nil,
      ...>   timestamp: 123,
      ...> }, nil)
      {:sent_message, ExWire.Message.Pong}

      iex> ping_data = [1, [<<1,2,3,4>>, <<>>, <<5>>], [<<5,6,7,8>>, <<6>>, <<>>], 4] |> ExRLP.encode
      iex> payload = <<0x01::8>> <> ping_data
      iex> payload_hash = ExWire.Crypto.hash(payload)
      iex> {signature, _r, _s, recovery_bit} = ExthCrypto.Signature.sign_digest(payload_hash, ExthCrypto.Test.private_key)
      iex> total_payload = signature <> <<recovery_bit::8>> <> payload
      iex> hash = ExWire.Crypto.hash("hello")
      iex> ExWire.Network.receive(%ExWire.Network.InboundMessage{
      ...>   data: hash <> total_payload,
      ...>   server_pid: self(),
      ...>   remote_host: nil,
      ...>   timestamp: 123,
      ...> }, nil)
      ** (ExWire.Crypto.HashMismatchError) Invalid hash
  """
  @spec receive(InboundMessage.t(), identifier() | nil) :: receiver_handler_action
  def receive(
        inbound_message = %InboundMessage{data: data, server_pid: server_pid},
        discovery_pid
      ) do
    :ok = assert_integrity(data)

    inbound_message
    |> get_params
    |> dispatch_handler(server_pid, discovery_pid)
  end

  '''
  Given the data of an inbound message, we'll run a quick SHA3 sum to verify
  the integrity of the message.

  ## Examples

      iex> ExWire.Network.assert_integrity(ExWire.Crypto.hash("hi mom") <> "hi mom")
      :ok

      iex> ExWire.Network.assert_integrity(<<1::256>> <> "hi mom")
      ** (ExWire.Crypto.HashMismatch) Invalid hash
  '''

  @spec assert_integrity(binary()) :: :ok
  defp assert_integrity(<<hash::size(256), payload::bits>>) do
    Crypto.assert_hash(payload, <<hash::256>>)
  end

  '''
  Returns a Handler Params for the given inbound message.

  ## Examples

      iex> ping_data = [1, [<<1,2,3,4>>, <<>>, <<5>>], [<<5,6,7,8>>, <<6>>, <<>>], 4] |> ExRLP.encode
      iex> payload = <<0x01::8>> <> ping_data
      iex> hash = ExWire.Crypto.hash(payload)
      iex> {signature, _r, _s, recovery_bit} = ExthCrypto.Signature.sign_digest(hash, ExthCrypto.Test.private_key)
      iex> params = ExWire.Network.get_params(%ExWire.Network.InboundMessage{
      ...>   data: hash <> signature <> <<recovery_bit::8>> <> payload,
      ...>   server_pid: self(),
      ...>   remote_host: nil,
      ...>   timestamp: 5,
      ...> })
      iex> params.hash
      <<162, 185, 143, 17, 69, 224, 221, 60, 169, 194, 154, 173, 122, 242, 156, 30, 197, 44, 131, 3, 210, 37, 73, 157, 104, 180, 128, 48, 106, 42, 163, 213>>
      iex> params.node_id
      <<54, 241, 224, 126, 85, 135, 69, 213, 129, 115, 3, 41, 161, 217, 87, 215, 159, 64, 17, 167, 128, 113, 172, 232, 46, 34, 145, 136, 72, 160, 207, 161, 171, 255, 26, 163, 160, 158, 227, 196, 92, 62, 119, 84, 156, 99, 224, 155, 120, 250, 153, 134, 180, 218, 177, 186, 200, 199, 106, 97, 103, 50, 215, 114>>
      iex> params.type
      1

      iex> payload_data = [] |> ExRLP.encode
      iex> payload = <<0xff::8>> <> payload_data
      iex> hash = ExWire.Crypto.hash(payload)
      iex> {signature, _r, _s, recovery_bit} = ExthCrypto.Signature.sign_digest(hash, ExthCrypto.Test.private_key)
      iex> params = ExWire.Network.get_params(%ExWire.Network.InboundMessage{
      ...>   data: hash <> signature <> <<recovery_bit::8>> <> payload,
      ...>   server_pid: self(),
      ...>   remote_host: nil,
      ...>   timestamp: 5,
      ...> })
      iex> params.hash
      <<19, 42, 97, 10, 60, 19, 10, 67, 247, 221, 97, 93, 120, 59, 83, 60, 207, 199, 47, 217, 115, 186, 202, 251, 110, 61, 69, 88, 179, 115, 85, 52>>
      iex> params.node_id
      <<54, 241, 224, 126, 85, 135, 69, 213, 129, 115, 3, 41, 161, 217, 87, 215, 159, 64, 17, 167, 128, 113, 172, 232, 46, 34, 145, 136, 72, 160, 207, 161, 171, 255, 26, 163, 160, 158, 227, 196, 92, 62, 119, 84, 156, 99, 224, 155, 120, 250, 153, 134, 180, 218, 177, 186, 200, 199, 106, 97, 103, 50, 215, 114>>
      iex> params.type
      255
  '''

  @spec get_params(InboundMessage.t()) :: Handler.Params.t()
  defp get_params(%InboundMessage{
         data: <<
           hash::binary-size(32),
           signature::binary-size(64),
           recovery_id::integer-size(8),
           type::binary-size(1),
           data::bitstring
         >>,
         remote_host: remote_host,
         timestamp: timestamp
       }) do
    # Recover public key
    {:ok, node_id} = Signature.recover(Crypto.hash(type <> data), signature, recovery_id)

    %Handler.Params{
      remote_host: remote_host,
      signature: signature,
      recovery_id: recovery_id,
      hash: hash,
      type: type |> :binary.decode_unsigned(),
      data: data,
      timestamp: timestamp,
      node_id: node_id |> Key.der_to_raw()
    }
  end

  '''
  Function to pass message to the appropriate handler. E.g. for a ping
  we'll pass the decoded message to `ExWire.Handlers.Ping.handle/1`.

  ## Examples

      iex> %ExWire.Handler.Params{
      ...>    data: <<210, 1, 199, 132, 1, 2, 3, 4, 128, 5, 199, 132, 5, 6, 7, 8, 6, 128, 4>>,
      ...>    hash: <<162, 185, 143, 17, 69, 224, 221, 60, 169, 194, 154, 173, 122, 242, 156, 30, 197, 44, 131, 3, 210, 37, 73, 157, 104, 180, 128, 48, 106, 42, 163, 213>>,
      ...>    node_id: <<54, 241, 224, 126, 85, 135, 69, 213, 129, 115, 3, 41, 161, 217, 87, 215, 159, 64, 17, 167, 128, 113, 172, 232, 46, 34, 145, 136, 72, 160, 207, 161, 171, 255, 26, 163, 160, 158, 227, 196, 92, 62, 119, 84, 156, 99, 224, 155, 120, 250, 153, 134, 180, 218, 177, 186, 200, 199, 106, 97, 103, 50, 215, 114>>,
      ...>    recovery_id: 0,
      ...>    remote_host: nil,
      ...>    signature: <<65, 254, 238, 89, 78, 155, 122, 241, 232, 167, 109, 23, 160, 87, 80, 15, 4, 162, 38, 254, 96, 108, 107, 103, 41, 254, 149, 181, 176, 63, 188, 145, 19, 151, 239, 5, 242, 146, 95, 207, 102, 142, 200, 154, 88, 213, 37, 177, 174, 107, 73, 132, 0, 116, 186, 24, 105, 167, 134, 131, 86, 196, 183, 236>>,
      ...>    timestamp: 5,
      ...>    type: 1
      ...> }
      ...> |> ExWire.Network.dispatch_handler(nil, nil)
      {:sent_message, ExWire.Message.Pong}

      iex> %ExWire.Handler.Params{
      ...>    data: <<192>>,
      ...>    hash: <<19, 42, 97, 10, 60, 19, 10, 67, 247, 221, 97, 93, 120, 59, 83, 60, 207, 199, 47, 217, 115, 186, 202, 251, 110, 61, 69, 88, 179, 115, 85, 52>>,
      ...>    node_id: <<54, 241, 224, 126, 85, 135, 69, 213, 129, 115, 3, 41, 161, 217, 87, 215, 159, 64, 17, 167, 128, 113, 172, 232, 46, 34, 145, 136, 72, 160, 207, 161, 171, 255, 26, 163, 160, 158, 227, 196, 92, 62, 119, 84, 156, 99, 224, 155, 120, 250, 153, 134, 180, 218, 177, 186, 200, 199, 106, 97, 103, 50, 215, 114>>,
      ...>    recovery_id: 0,
      ...>    remote_host: nil,
      ...>    signature: <<43, 58, 139, 136, 136, 159, 177, 17, 78, 215, 13, 0, 38, 221, 76, 104, 44, 24, 110, 130, 189, 97, 92, 82, 144, 50, 236, 190, 10, 49, 145, 134, 123, 7, 213, 199, 143, 106, 226, 104, 114, 135, 135, 124, 133, 247, 81, 71, 76, 235, 255, 145, 87, 54, 232, 94, 245, 245, 219, 21, 180, 174, 254, 15>>,
      ...>    timestamp: 5,
      ...>    type: 255
      ...> }
      ...> |> ExWire.Network.dispatch_handler(nil, nil)
      :no_action
  '''

  @spec dispatch_handler(Handler.Params.t(), identifier(), identifier() | nil) ::
          receiver_handler_action
  defp dispatch_handler(params, server_pid, discovery_pid) do
    case Handler.dispatch(params.type, params, discovery_pid) do
      :no_response ->
        :no_action

      {:respond, response_message} ->
        # TODO: This is a simple way to determine who to send the message to,
        #       but we may want to revise.
        to = response_message.__struct__.to(response_message) || params.remote_host

        send(response_message, server_pid, to)
    end
  end

  @doc """
  Sends a message asynchronously via casting a message
  to our running `gen_server`.

  ## Examples

      iex> message = %ExWire.Message.Pong{
      ...>   to: %ExWire.Struct.Endpoint{ip: {1, 2, 3, 4}, tcp_port: 5, udp_port: nil},
      ...>   hash: <<2>>,
      ...>   timestamp: 3,
      ...> }
      iex> ExWire.Network.send(message, self(), %ExWire.Struct.Endpoint{ip: {1, 2, 3, 4}, udp_port: 5})
      {:sent_message, ExWire.Message.Pong}
      iex> receive do m -> m end
      {:"$gen_cast",
        {:send,
          %{
            data: ExWire.Protocol.encode(message, ExWire.Config.private_key()),
            to: %ExWire.Struct.Endpoint{
              ip: {1, 2, 3, 4},
              tcp_port: nil,
              udp_port: 5}
          }
        }
      }
  """
  @spec send(ExWire.Message.t(), identifier(), Endpoint.t()) :: sender_handler_action
  def send(message, server_pid, to) do
    _ =
      Logger.debug(fn ->
        "[Network] Sending #{to_string(message.__struct__)} message to #{
          to.ip |> Endpoint.ip_to_string()
        }"
      end)

    :ok =
      GenServer.cast(
        server_pid,
        {
          :send,
          %{
            to: to,
            data: Protocol.encode(message, Config.private_key())
          }
        }
      )

    {:sent_message, message.__struct__}
  end
end
