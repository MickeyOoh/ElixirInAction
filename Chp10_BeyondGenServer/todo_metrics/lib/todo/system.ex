defmodule Todo.System do

  def start_link() do
    Supervisor.start_link(
     [
      Todo.Metrics
     ],
     strategy: :one_for_one
    )
  end
end
