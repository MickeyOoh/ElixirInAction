list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * 1] end

Benchee.run(%{
"flat_map"  => fn -> Enum.flat_map(list, map_fun) end,
"map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})

