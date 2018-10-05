defmodule ExWire.PeerSupervisor do
  @moduledoc """
  The Peer Supervisor is responsible for maintaining a set of peer TCP connections.

  We should ask bootnodes for a set of potential peers via the Discovery Protocol, and then
  we can connect to those nodes. Currently, we just connect to the Bootnodes themselves.
  """

  # TODO: We need to track and see which of these are up. We need to percolate messages on success.

  use Supervisor

  require Logger

  @name __MODULE__

  def start_link(:ok) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    children = [
      worker(ExWire.Adapter.TCP, [], restart: :transient)
    ]

    Supervisor.init(children, strategy: :simple_one_for_one)
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
      if is_pid(child), do: ExWire.Adapter.TCP.send_packet(child, packet)
    end
  end

  @doc """
  Informs our peer supervisor a new neighbour that we should connect to.
  """
  def connect(neighbour) do
    Logger.debug("[Peer Supervisor] Starting TCP connection to neighbour #{neighbour.endpoint.ip |> ExWire.Struct.Endpoint.ip_to_string}:#{neighbour.endpoint.tcp_port} (#{neighbour.node |> ExthCrypto.Math.bin_to_hex})")

    peer = ExWire.Struct.Peer.from_neighbour(neighbour)

    Supervisor.start_child(@name, [:outbound, peer, [{:server, ExWire.Sync}]])
  end

end