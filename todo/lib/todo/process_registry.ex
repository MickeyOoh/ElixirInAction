defmodule Todo.ProcessRegistry do
  def start_link do
    IO.puts("ProcessRegistry.start_link() ")
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
    |> IO.inspect(  label: "via_tuple:")
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
    |> IO.inspect( label: "Regsitry child_spec: ")
  end
end
