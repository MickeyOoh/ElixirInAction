KeyValue.start_link()
EtsKeyValue.start_link()

list = Enum.to_list(1..10_000)
key_put = fn i -> KeyValue.put(i, 10_001 - i) end
etskey_put = fn i -> EtsKeyValue.put(i, 10_001 - i) end

Benchee.run(%{
"keyvalue"    => fn -> Enum.each(list, key_put) end,
"etskeyvalue" => fn -> Enum.each(list, etskey_put) end
})

