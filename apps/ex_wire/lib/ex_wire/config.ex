defmodule ExWire.Config do
  @moduledoc """
  General configuration information for ExWire.
  """

  @port Application.get_env(:ex_wire, :port, 30303 + :rand.uniform(10_000))
  @private_key ( case Application.get_env(:ex_wire, :private_key) do
    key when is_binary(key) -> key
    :random -> ExthCrypto.ECIES.ECDH.new_ecdh_key_pair() |> Tuple.to_list() |> List.last
  end )
  @public_key ( case ExthCrypto.Signature.get_public_key(@private_key) do
    {:ok, public_key} -> public_key
  end )
  @node_id @public_key |> ExthCrypto.Key.der_to_raw
  @protocol_version Application.get_env(:ex_wire, :protocol_version)
  @network_id Application.get_env(:ex_wire, :network_id)
  @p2p_version Application.get_env(:ex_wire, :p2p_version)
  @caps Application.get_env(:ex_wire, :caps)
  @version Mix.Project.config[:version]
#  @sync
  @chain Application.get_env(:ex_wire, :chain) |> Blockchain.Chain.load_chain
  @bootnodes ( case Application.get_env(:ex_wire, :bootnodes) do
    nodes when is_list(nodes) -> nodes
    :from_chain -> @chain.nodes
  end )
  @commitment_count Application.get_env(:ex_wire, :commitment_count)
  @local_ip ( case Application.get_env(:ex_wire, :local_ip, {127, 0, 0, 1}) do
    ip_address when is_binary(ip_address) ->
      {:ok, ip_address_parsed} = ip_address |> String.to_charlist |> :inet.parse_address
      ip_address_parsed
    ip_address when is_tuple(ip_address) -> ip_address
  end )

  @use_nat Application.get_env(:ex_wire, :use_nat, false)

  @doc """
  Returns a private key that is generated when a new session is created. It is
  intended that this key is semi-persisted.
  """
  @spec private_key() :: ExthCrypto.Key.private_key()
  def private_key, do: @private_key

  @spec public_key() :: ExthCrypto.Key.public_key()
  def public_key, do: @public_key

  @spec node_id() :: ExWire.node_id
  def node_id, do: @node_id

  @spec listen_port() :: integer()
  def listen_port, do: @port

  @spec protocol_version() :: integer()
  def protocol_version, do: @protocol_version

  @spec network_id() :: integer()
  def network_id, do: @network_id

  @spec p2p_version() :: integer()
  def p2p_version, do: @p2p_version

  @spec caps() :: [{String.t, integer()}]
  def caps, do: @caps

  @spec client_id() :: String.t
  def client_id, do: "Exthereum/#{@version}"

  @spec sync() :: boolean()
  def sync, do: Application.get_env(:ex_wire, :sync)

  @spec bootnodes() :: [String.t]
  def bootnodes, do: @bootnodes

  @spec chain() :: Blockchain.Chain.t
  def chain, do: @chain

  @spec commitment_count() :: integer()
  def commitment_count, do: @commitment_count

  @spec local_ip() :: [integer()]
  def local_ip, do: @local_ip

  @spec use_nat() :: boolean()
  def use_nat, do: @use_nat

end