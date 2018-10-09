defmodule ExWire.Struct.Neighbour do
  @moduledoc """
  Struct to represent an neighbour in RLPx.
  """

  alias ExWire.Struct.Endpoint

  defstruct endpoint: nil,
            node: nil

  @type t :: %__MODULE__{
          endpoint: ExWire.Struct.Endpoint.t(),
          node: ExWire.node_id()
        }

  @doc """
  Returns an Neighbour based on a URI.

  ## Examples

      iex> ExWire.Struct.Neighbour.from_uri("enode://6ce05930c72abc632c58e2e4324f7c7ea478cec0ed4fa2528982cf34483094e9cbc9216e7aa349691242576d552a2a56aaeae426c5303ded677ce455ba1acd9d@13.84.180.240:30303")
      {:ok, %ExWire.Struct.Neighbour{
        endpoint: %ExWire.Struct.Endpoint{
          ip: {13, 84, 180, 240},
          tcp_port: 30303,
          udp_port: 30303,
        },
        node: <<108, 224, 89, 48, 199, 42, 188, 99, 44, 88, 226, 228, 50, 79, 124, 126, 164, 120, 206, 192, 237, 79, 162, 82, 137, 130, 207, 52, 72, 48, 148, 233, 203, 201, 33, 110, 122, 163, 73, 105, 18, 66, 87, 109, 85, 42, 42, 86, 170, 234, 228, 38, 197, 48, 61, 237, 103, 124, 228, 85, 186, 26, 205, 157>>
      }}

      iex> ExWire.Struct.Neighbour.from_uri("http://google:30303")
      {:error, :invalid_scheme}

      iex> ExWire.Struct.Neighbour.from_uri("abc")
      {:error, :invalid_uri}
  """
  @spec from_uri(String.t()) :: {:ok, t} | {:error, atom()}
  def from_uri(uri) do
    case URI.parse(uri) do
      %URI{
        scheme: "enode",
        userinfo: remote_id,
        host: remote_host,
        port: remote_peer_port
      } ->
        {:ok, remote_ip} = :inet.ip(remote_host |> String.to_charlist())

        {:ok,
         %ExWire.Struct.Neighbour{
           endpoint: %ExWire.Struct.Endpoint{
             ip: remote_ip,
             udp_port: remote_peer_port,
             tcp_port: remote_peer_port
           },
           node: remote_id |> ExthCrypto.Math.hex_to_bin()
         }}

      %URI{scheme: nil} ->
        {:error, :invalid_uri}

      %URI{} ->
        {:error, :invalid_scheme}
    end
  end

  @doc """
  Returns a struct given an `ip` in binary form, plus an
  `udp_port` or `tcp_port`, along with a `node_id`, returns
  a `Neighbour` struct.

  ## Examples

      iex> ExWire.Struct.Neighbour.decode([<<1,2,3,4>>, <<>>, <<5>>, <<7, 7>>])
      %ExWire.Struct.Neighbour{
        endpoint: %ExWire.Struct.Endpoint{
          ip: {1, 2, 3, 4},
          udp_port: nil,
          tcp_port: 5,
        },
        node: <<7, 7>>
      }
  """
  @spec decode(ExRLP.t()) :: t
  def decode([ip, udp_port, tcp_port, node_id]) do
    %__MODULE__{
      endpoint: Endpoint.decode([ip, udp_port, tcp_port]),
      node: node_id
    }
  end

  @doc """
  Versus `encode/4`, and given a module with an ip, a tcp_port, a udp_port,
  and a node_id, returns a tuple of encoded values.

  ## Examples

      iex> ExWire.Struct.Neighbour.encode(
      ...>   %ExWire.Struct.Neighbour{
      ...>     endpoint: %ExWire.Struct.Endpoint{
      ...>       ip: {1, 2, 3, 4},
      ...>       udp_port: nil,
      ...>       tcp_port: 5,
      ...>     },
      ...>     node: <<7, 8>>,
      ...>   }
      ...> )
      [<<1, 2, 3, 4>>, <<>>, <<0, 5>>, <<7, 8>>]
  """
  @spec encode(t) :: ExRLP.t()
  def encode(%__MODULE__{endpoint: endpoint, node: node_id}) do
    Endpoint.encode(endpoint) ++ [node_id]
  end
end
