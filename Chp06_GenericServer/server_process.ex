defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
     end)
  end

  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})
    receive do
      {:response, response} ->
        response
    end
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} =
          callback_module.handle_call(
            request,
            current_state
          )
        send(caller, {:response, response})
        loop(callback_module, new_state)
      {:cast, request} ->
        new_state =
          callback_module.handle_cast(
            request,
            current_state
          )
        loop(callback_module, new_state)
    end
  end

end

defmodule KeyValueStore do
  def start do
    ServerProcess.start(KeyValueStore)
  end

  def put(pid, key, value) do
    ServerProcess.cast(pid, {:put, key, value})
  end

  def init do
    %{}
  end

  def handle_call({:put, key, value}, state) do
    new_state = Map.put(state, key, value)
    {:ok, new_state}
  end

  def handle_call({:get, key}, state) do
    value = Map.get(state, key)
    ##{:ok, state, value}
    {value, state}
  end

  def handle_cast({:put, key, value}, state) do
    Map.put(state, key, value)
  end

end
