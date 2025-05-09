defmodule TodoList do
  defstruct next_id: 1, entries: %{}

  #def new(), do: %TodoList{}
  def new(entries \\ []) do
    Enum.reduce(
    entries,
    %TodoList{},
    #fn entry, todo_list_acc ->
    #  add_entry(todo_list_acc, entry)
    #end
    &add_entry(&2, &1)
    )
  end

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.next_id)

    new_entries = Map.put(
      todo_list.entries,
      todo_list.next_id,
      entry
    )
    %TodoList{todo_list |
      entries: new_entries,
      next_id: todo_list.next_id + 1}
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Map.values()
    |> Enum.filter(fn entry -> entry.date == date end)
  end

  def update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list
      {:ok, old_entry} ->
        new_entry = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end
end

defmodule TodoList.CsvImporter do
@filename "todos.csv"

  def import() do
    File.stream!(@filename)
    |> Stream.map(&parse_line/1)
    |> Enum.reduce(%TodoList{}, &add_entry/2)
  end

  defp parse_line(line) do
    [date, title] = String.split(line, ",")
    %{date: date, title: title}
  end

  defp add_entry(entry, todo_list) do
    TodoList.add_entry(todo_list, entry)
  end
end
