defmodule Todo.Server do
  use GenServer, restart: :temporary    # 

  @expiry_idle_timeout :timer.seconds(10)

  def start_link(name) do
    GenServer.start(__MODULE__, name, name: via_tuple(name))
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end

  def add_entry(pid, new_entry) do
    GenServer.cast(pid, {:add_entry, new_entry})
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end

  def init(name) do
    IO.puts("Starting to-do server for #{name}.")
    {:ok, {name, nil}, {:continue, :init}}
  end

  def handle_continue(:init, {name, nil}) do
    todo_list = Todo.Database.get(name) || Todo.List.new()
    {
      :noreply, 
      {name, todo_list},
      @expiry_idle_timeout
    }
  end

  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}, @expiry_idle_timeout}
  end

  def handle_call({:entries, date}, _, {name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date), {name, todo_list}, @expiry_idle_timeout}
  end

  def handle_info(:timeout, {name, todo_list}) do
    IO.puts("Stopping to-do server for #{name}")
    {:stop, :normal, {name, todo_list}}
  end

end
