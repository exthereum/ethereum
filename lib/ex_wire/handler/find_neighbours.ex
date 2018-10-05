defmodule ExWire.Handler.FindNeighbours do
  @moduledoc """
  Not currently implemented.
  """

  alias ExWire.Handler

  @doc """
  Handler for a FindNeighbors message.

  ## Examples

      iex> ExWire.Handler.FindNeighbours.handle(%ExWire.Handler.Params{
      ...>   remote_host: %ExWire.Struct.Endpoint{ip: {1, 2, 3, 4}, udp_port: 55},
      ...>   signature: 2,
      ...>   recovery_id: 3,
      ...>   hash: <<5>>,
      ...>   data: <<194, 1, 2>>,
      ...>   timestamp: 7,
      ...> }, nil)
      {:respond, %ExWire.Message.Neighbours{
        nodes: [],
        timestamp: 7,
      }}
  """
  @spec handle(Handler.Params.t, identifier | nil) :: Handler.handler_response
  def handle(params, discovery) do
    find_neighbours = ExWire.Message.FindNeighbours.decode(params.data)

    nodes = if discovery do
      ExWire.Discovery.get_neighbours(discovery, find_neighbours.target)
    else
      []
    end

    {:respond, %ExWire.Message.Neighbours{
      nodes: nodes,
      timestamp: params.timestamp,
    }}
  end

end