defmodule Todo.Server do
  use GenServer, restart: :temporary    # 

  #def start(name) do
  #  GenServer.start(__MODULE__, name)
  #end
  
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
    # {:ok, {name, todo_list}}
    {:ok, {name, nil}, {:continue, :init}}
  end

  def handle_continue(:init, {name, nil}) do
    todo_list = Todo.Database.get(name) || Todo.List.new()
    {:noreply, {name, todo_list}}
  end

  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  def handle_call({:entries, date}, _, state = {_name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date), state}
  end
end
