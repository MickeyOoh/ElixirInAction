Chp04 Data abstractions
-----
* abstacting with modules 
* Working with hhieraschical data
* Polymorhphism withhh protocols

Big difference from OO languages is that data is immutable. To modify data,
you must call some function and take its result into a variable; the original
data is left intact. 


4.1.1 Basic abstraction
----

4.1.2 Composing abstractions
----

4.1.3 Structing data with maps
-----

```
TodoList.add_entry(todo_list, ~D[2025-03-01], "Dentist")
```

4.1.4 Abstracting with structs
-----

4.1.5 Data transparency
-----
The modules you've devised so far are abstractions because clients aren't aware of their implementation details. 

4.2 Working with hierachical data
-----
you'll extend the `TodoList` abstraction to provide basic `CRUD` support.
You already have the C and R parts resolved with the `add_entry/2` and `entries/2` functions.
Now, you need to add support for updating and deleting entries.

4.2.1 Generating IDs
----
* `represent the to-do list as a struct`. You need to do this because the to-do list now has to keep two pieces of informatin: The entries collection and ID value for the next entry.
* `Use the entry's ID as the key`. 

4.2.2 Updating entries
----

```todo_crud.ex
defmodule TodoList do
- - -
    def update_entry(todo_list, entry_id, updater_fun) do
        case Map.fetch(todo_list.entries, entry_id) do
            :error ->
                todo_list
            {:ok, old_entry} ->
                new_entry = update_fun.(old_entry)
                new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
                %TodoList(todo_list | entries: new_entries)
        end
    end
end
```

4.2.3 Immutable hierarchical updates
-----
You performed a deep update of an immutable hierarchy. 
Let's break down what happens when you call `TodoList.update_entry(todo_list, id, updater_lamda)`:

1. You take the target enry into a separate variable
2. You call the updater that returns the modified version of the entry to you.
3. You call `Map.put` to put the modified entry into the tineries collection.
4. You return the new version of the to-do list, whhich contains the new entries collection.


4.2.4 Iterative updates
----

4.2.5 Exercise: Importing from a file
----

4.3 Polymorphism with protocols
-----
Polymorphism is a runtime decision about which code to execute, based on the nature of the input data. 
In Elixir, the basic way of of doing this is by using the language feature called protocols.

You've already seen polymorhpic code. For excample, the entire `Enum` is generic code that works on anything enumerable, as the following snippet illustrates:
```
Enum.each([1,2,3], &IO.inspect/1)
Enum.each(1..3, &IO.inspect/1)
Enum.each(%{a: 1, b: 2}, &IO.inspect/1)
```

Notice hhow you use the same `Enum.each/2` function, sending it different data structures: a list, range, and map. `Enum.each/2` know how to walk each structure? It doesn't. 
The code in `Enum.each/2` is generic and relies on a contract. This contract, called a `protocol`, must be implemented for each data type you wish to use with `Enum` functions. Next, let's learn how to define and use protocols.

4.3.1 Protocol basics
----

A `protocol` is a module in which you declare functions without implementing them.
Consider it a rough equivalent of an OO interface. The generic logic relies on the protocol and calls its functions. then, you can provide a concrete implementaion of the protocol for different data types.

