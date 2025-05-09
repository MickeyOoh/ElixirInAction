defmodule ListHelper do
  def sum(list) do
    do_sum(0,list)
  end

  def do_sum(current_sum, []) do
    current_sum
  end

  def do_sum(current_sum, [head | tail]) do
    new_sum = head + current_sum
    do_sum(new_sum, tail)
  end

end
