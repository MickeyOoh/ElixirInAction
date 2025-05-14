defmodule EtsKeyValue do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def put(key, value) do
    :ets.insert(__MODULE__, {key, value})
    #GenServer.cast(__MODULE__, {:put, key, value})
  end

  def get(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, value}] -> value
      [] -> nil
    end
    #GenServer.call(__MODULE__, {:get, key})
  end

  def init(_) do
    :ets.new(
      __MODULE__,
      [:named_table, :public, write_concurrency: true]
    )
    {:ok, %{}}
  end

  #def handle_cast({:put, key, value}, store) do
  #  {:noreply, Map.put(store, key, value)}
  #end

  #def handle_call({:get, key}, _, store) do
  #  {:reply, Map.get(store, key), store}
  #end

end
