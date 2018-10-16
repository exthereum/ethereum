defmodule ExWire.Handshake.MessageHandler do
  alias ExWire.Config
  alias ExWire.Handshake.Struct.AckRespV4
  alias ExWire.Handshake.Struct.AuthMsgV4
  alias ExWire.Handshake.EIP8
  alias ExthCrypto.ECIES
  alias ExthCrypto.Math

  @doc """
  Reads a given ack message, transported during the key initialization phase
  of the RLPx protocol. This will generally be handled by the dialer of the connection.

  Note: this will handle pre- or post-EIP 8 messages. We take a different approach to other
        implementations and try EIP-8 first, and if that fails, plain.
  """
  @spec read_ack_resp(binary(), ExthCrypto.Key.private_key(), String.t()) ::
          {:ok, AckRespV4.t(), binary(), binary()} | {:error, String.t()}
  def read_ack_resp(encoded_ack, my_static_private_key, remote_addr) do
    case EIP8.unwrap_eip_8(encoded_ack, my_static_private_key, remote_addr) do
      {:ok, rlp, ack_resp_bin, frame_rest} ->
        # unwrap eip-8
        ack_resp =
          rlp
          |> AckRespV4.deserialize()

        {:ok, ack_resp, ack_resp_bin, frame_rest}

      {:error, _reason} ->
        # TODO: reason?

        # unwrap plain
        with {:ok, plaintext} <- ECIES.decrypt(my_static_private_key, encoded_ack, <<>>, <<>>) do
          <<
            remote_ephemeral_public_key::binary-size(64),
            remote_nonce::binary-size(32),
            0x00::size(8)
          >> = plaintext

          ack_resp =
            [
              remote_ephemeral_public_key,
              remote_nonce,
              Config.protocol_version()
            ]
            |> AckRespV4.deserialize()

          {:ok, ack_resp, encoded_ack, <<>>}
        end
    end
  end

  @doc """


  TODO move to a separate module
  Builds a response for an incoming authentication message.

  ## Examples

      iex> ExWire.Handshake.MessageHandler.build_ack_resp(ExthCrypto.Test.public_key(:key_c), ExthCrypto.Test.init_vector(), 32)
      %ExWire.Handshake.Struct.AckRespV4{
        remote_ephemeral_public_key: <<4, 146, 201, 161, 205, 19, 177, 147, 33, 107, 190, 144, 81, 145, 173, 83, 20, 105, 150, 114, 196, 249, 143, 167, 152, 63, 225, 96, 184, 86, 203, 38, 134, 241, 40, 152, 74, 34, 68, 233, 204, 91, 240, 208, 254, 62, 169, 53, 201, 248, 156, 236, 34, 203, 156, 75, 18, 121, 162, 104, 3, 164, 156, 46, 186>>,
        remote_nonce: <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16>>,
        remote_version: 63
      }
  """

  @spec build_ack_resp(ExthCrypto.Key.public_key(), binary() | nil, non_neg_integer()) ::
          AckRespV4.t()
  def build_ack_resp(remote_ephemeral_public_key, nonce \\ nil, nonce_len) do
    # Generate nonce unless given
    nonce = if nonce, do: nonce, else: Math.nonce(nonce_len)

    %AckRespV4{
      remote_nonce: nonce,
      remote_ephemeral_public_key: remote_ephemeral_public_key,
      remote_version: Config.protocol_version()
    }
  end

  @doc """


  Reads a given auth message, transported during the key initialization phase
  of the RLPx protocol. This will generally be handled by the listener of the connection.

  Note: this will handle pre or post-EIP 8 messages. We take a different approach to other
        implementations and try EIP-8 first, and if that fails, plain.
  """

  @spec read_auth_msg(binary(), Key.private_key(), String.t()) ::
          {:ok, AuthMsgV4.t(), binary()} | {:error, String.t()}
  def read_auth_msg(encoded_auth, my_static_private_key, remote_addr) do
    case EIP8.unwrap_eip_8(encoded_auth, my_static_private_key, remote_addr) do
      {:ok, rlp, _bin, frame_rest} ->
        # unwrap eip-8
        auth_msg =
          rlp
          |> AuthMsgV4.deserialize()
          |> AuthMsgV4.set_remote_ephemeral_public_key(my_static_private_key)

        {:ok, auth_msg, frame_rest}

      {:error, _} ->
        # unwrap plain
        with {:ok, plaintext} <- ECIES.decrypt(my_static_private_key, encoded_auth, <<>>, <<>>) do
          <<
            signature::binary-size(65),
            _::binary-size(32),
            remote_public_key::binary-size(64),
            remote_nonce::binary-size(32),
            0x00::size(8)
          >> = plaintext

          auth_msg =
            [
              signature,
              remote_public_key,
              remote_nonce,
              Config.protocol_version()
            ]
            |> AuthMsgV4.deserialize()
            |> AuthMsgV4.set_remote_ephemeral_public_key(my_static_private_key)

          {:ok, auth_msg, <<>>}
        end
    end
  end
end
