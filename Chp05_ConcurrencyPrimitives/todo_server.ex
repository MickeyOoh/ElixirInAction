defmodule TodoServer do
  def start do
    spawn(fn -> loop(TodoList.new()) end)
  end
  defp loop(todo_list) do
    new_todo_list =
      receive do
        message-> process_message(todo_list, message)
      end
    loop(new_todo_list)
  end
  def entries(todo_server, date) do
    send(todo_server, {:entries, self(), date})

    receive do
      {:todo_entires, entires} -> entries
    after
      5000 -> {:error, :timeout}
    end
  end
  def add_entry(todo_server, new_entry) do
    send(todo_server, {:add_entry, new_entry})
  end
  def process_message(todo_list, {:add_entry, new_entry}) do
    TodoList.add_entry(todo_list, new_entry)
  end
end

defmodule TodoList do

end
