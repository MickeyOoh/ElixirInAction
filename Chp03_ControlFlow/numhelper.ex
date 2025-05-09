defmodule NumHelper do
  def sum_nums(enumerable) do
    Enum.reduce(enumerable, 0, &add_num/2)
  end
  
  def add_num(num, sum) when is_number(num), do: sum + num
  def add_num(_, sum), do: sum
end

