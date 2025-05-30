defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link({db_folder, worker_id}) do
    IO.puts("Starting database worker.(#{inspect worker_id})")
    GenServer.start_link(
      __MODULE__,
      db_folder,
      name: via_tuple(worker_id)
    )
  end

  def store(worker_id, key, data) do
    GenServer.cast(via_tuple(worker_id), {:store, key, data})
  end

  def get(worker_id, key) do 
    IO.puts("Worker.get\(#{inspect worker_id}, #{inspect key}\)")
    GenServer.call(via_tuple(worker_id), {:get, key})
  end

  defp via_tuple(worker_id) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})
  end

  def init(db_folder) do
    {:ok, db_folder}
  end
  
  def handle_cast({:store, key, data}, state) do
    key 
    |> file_name( state)
    |> File.write!(:erlang.term_to_binary(data))
    {:noreply, state}
  end

  def handle_call({:get, key}, _, state) do
    IO.puts("call: #{inspect state}")
    data = case File.read(file_name(key, state)) do
            {:ok, contents} -> :erlang.binary_to_term(contents)
            _ -> nil
          end

    {:reply, data, state}
  end
  
  def file_name(key, db_folder) do
    Path.join(db_folder, to_string(key))
  end

end
