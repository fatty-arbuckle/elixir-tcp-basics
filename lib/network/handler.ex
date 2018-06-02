defmodule Network.Handler do
  @moduledoc """
  A simple TCP protocol handler that echoes all messages received.
  """

  use GenServer

  require Logger

  # Client

  @doc """
  Starts the handler with `:proc_lib.spawn_link/3`.
  """
  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  @doc """
  Initiates the handler, acknowledging the connection was accepted.
  Finally it makes the existing process into a `:gen_server` process and
  enters the `:gen_server` receive loop with `:gen_server.enter_loop/3`.
  """
  def init(args) do
    {:ok, args}
  end
  def init(ref, socket, transport) do
    peername = stringify_peername(socket)

    Logger.info("Peer #{peername} connecting", ansi_color: :blue)

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])

    transport.send(socket, "welcome aboard!")

    :gen_server.enter_loop(__MODULE__, [], %{
      socket: socket,
      transport: transport,
      peername: peername
    })
  end

  # Server callbacks

  def handle_info(
        {:tcp, _, message},
        %{socket: socket, transport: transport, peername: peername} = state
      ) do
    Logger.info("Received new message from peer #{peername}: #{inspect(message)}. Echoing it back", ansi_color: :blue)

    # Sends the message back
    transport.send(socket, message)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, %{peername: peername} = state) do
    Logger.info("Peer #{peername} disconnected", ansi_color: :blue)

    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _, reason}, %{peername: peername} = state) do
    Logger.info("Error with peer #{peername}: #{inspect(reason)}", ansi_color: :blue)

    {:stop, :normal, state}
  end

  # Helpers

  defp stringify_peername(socket) do
    {:ok, {addr, port}} = :inet.peername(socket)

    address =
      addr
      |> :inet_parse.ntoa()
      |> to_string()

    "#{address}:#{port}"
  end
end
