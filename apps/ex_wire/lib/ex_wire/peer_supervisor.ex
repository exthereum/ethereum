defmodule ExWire.PeerSupervisor do
  @moduledoc """
  The Peer Supervisor is responsible for maintaining a set of peer TCP connections.

  We should ask bootnodes for a set of potential peers via the Discovery Protocol, and then
  we can connect to those nodes. Currently, we just connect to the Bootnodes themselves.
  """

  # TODO: We need to track and see which of these are up. We need to percolate messages on success.

  use Supervisor

  require Logger
  alias ExthCrypto.Math
  alias ExWire.Adapter.TCP
  alias ExWire.Struct.Endpoint
  alias ExWire.Struct.Peer
  alias ExWire.Sync

  @name __MODULE__

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(_args) do
    children = [
      worker(TCP, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  @doc """
  Sends a packet to all active TCP connections. This is useful when we want to, for instance,
  ask for a `GetBlockBody` from all peers for a given block hash.
  """
  def send_packet(pid, packet) do
    # Send to all of the Supervisor's children...
    # ... not the best.

    for {_id, child, _type, _modules} <- Supervisor.which_children(pid) do
      # Children which are being restarted by not have a child_pid at this time.
      if is_pid(child), do: TCP.send_packet(child, packet)
    end
  end

  @doc """
  Informs our peer supervisor a new neighbour that we should connect to.
  """
  def connect(neighbour) do
    _ =
      Logger.debug(fn ->
        "[Peer Supervisor] Starting TCP connection to neighbour #{
          neighbour.endpoint.ip |> Endpoint.ip_to_string()
        }:#{neighbour.endpoint.tcp_port} (#{neighbour.node |> Math.bin_to_hex()})"
      end)

    peer = Peer.from_neighbour(neighbour)

    Supervisor.start_child(@name, [:outbound, peer, [{:server, Sync}]])
  end
end
