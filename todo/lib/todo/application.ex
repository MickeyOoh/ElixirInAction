defmodule Todo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    IO.puts("Application.start()")
    Todo.System.start_link()
    ##    children = [
    ##      # Starts a worker by calling: Todo.Worker.start_link(arg)
    ##      # {Todo.Worker, arg}
    ##    ]
    ##
    ##    # See https://hexdocs.pm/elixir/Supervisor.html
    ##    # for other strategies and supported options
    ##    opts = [strategy: :one_for_one, name: Todo.Supervisor]
    ##    Supervisor.start_link(children, opts)
  end
end
