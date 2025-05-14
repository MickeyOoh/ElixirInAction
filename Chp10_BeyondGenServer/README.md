Chp10 Beyond GenServer
-----
Covers:
* Tasks
* Agents
* ETS tables

10.1 Tasks
---
The `Task` module can be used to concurrently run a job--a process that takes some input, performs some computation, and then stops.

10.1.1 Awaited tasks
----
An `awiated task` is a process that executes some function, sends the function result back to the starter process, and the terminates. 

```
iex> long_job =
        fn ->
            Process.sleep(2000)
            :some_result
        end

iex> task = Task.async(long_job)
```
The `Task.async/1` function takes a zero-arity lambda, spawns a separate process, and invodes the lambda in the spawned process. The return value of the lambda will be sent as a message back to the starter process.

Awaited tasks can be very useful when you need to run a couple of mutually independent, one-off computations and wait for all the results. 

10.1.2 Non-awaited tasks
----
If you don't want to send a result message back to the starter process, you can use `Task.start_link/1`. This function can be thought of as an OTP-compliant wrapper around plain `spawn_link`.

10.1.3 Supervising dynamic tasks
----
you'll want to start non-awaited tasks dynamically. A common example is when you need to communicate with a remote service, such as a payment gateway, while handling a web request.
A naive approach would be to perform this communication synchronously, while the request is being handled.


10.2 Agents
-----
Agents require a bit less ceremony and can, therefore, eliminate some boilerplate associated withh `GenServer`.

If a `GenServer`implements only `init/1, handle_cast/2`, and `handle_call/3`, it can be replaced with an `Agent`. But if you need to use `handle_info/2` or `terminate/1`, Agent won't suffice, and you'll need to use `GenServer`.

10.2.1 Basic use
----
```
iex> {:ok, pid} = Agent.start_link(fn -> %{name: "Bob", age: 30} end)
```
Unlike a task, an agent process doesn't terminate when the lambda is finished. Instead, an agent uses the return value of the lambda as its state.
Other processes can access and manipulate an agent's state using various functions from the `Agent` module.

```
iex> Agent.get(pid, fn state -> state.name end)
```

The lambda is invoked in the agent's process, and it receives the agent's state as the argument. The return value is sent back to the caller process as a message.
This message is received in `Agent.get/2` whichthen returns the result to its caller.

```
iex> Agent.update(pid, fn state -> %{state | age: state.age + 1} end)
```
This will cause the internal state of the agent process to change. 

10.2.2 Agents and concurrency
----
A single agent can be used by multiple client processes. A change made by one process can be observed by other porcesses in subsequent agent operations.

10.2.3 Agent-powerd to-do server
----
Because `Agent` can be used to manage concurrent state, it's a perfect candidate to power your to-do list server. Converting a `GenServer` into an agent is a fairly straightforward job. 

```server.ex
defmodule Todo.Server do
  use Agent, restart: :temporary

  def start_link(name) do
    Agent.start_link(
      fn ->
        IO.puts("Starting to-do server for #{name}")
        {name, Todo.Database.get(name) || Todo.List.new()}
      end,
      name: via_tuple(name)
    )    
  end

  def add_entry(todo_server, new_entry) do
    Agent.cast(todo_server, fn {name, todo_list} ->
      new_list = Todo.List.add_entry(todo_list, new_entry)
      Todo.Database.store(name, new_list)
      {name, new_list}
    end)
  end

  def entries(todo_server, date) do
    Agent.get(
      todo_server,
      fn {_name, todo_list} -> Todo.List.entries(todo_list, date) end
    )
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end
```

There are two things worth discussing in this code.
The first is the expression `use Agent` at the start of the module. Just like with `GenServer` and `Task`, this expression will inject the default implementation of `child_spec/1`, allowing you to list the module in a child specification list.
In addition, the implementation of `add_entry/2` uses `Agent.cast/2`. This function is the asynchronous version of `Agent.update/2`, which means the function returns immediately and the update is performed concurrently. `Agent.cast/2` is used here to keep the same behavior as in the provious version, where `GenServer.cast/2` was used.

10.2.4 Limitations of agents
----
The `Agent` module can't be used if you need to handle plain messages or if you want to run some logic on termination.
Let's look at an example.
In the current version of your system, you never expire items from the to-do cache. This means that when a user manipulates a single to-do list, the list will remain in memory until the system is terminated. This is clearly not good because as users work with different to-do lists, you'll consume more and more memory until the whole system runs out of memory and blows up.
Let's introduce a simple expiry of to-do servers. You'll stop to-do servers that have been idle for a while.
One way to implement this is to create a single cleaning process that would terminate an idle to-do server. In this approach, each to-do server would need to notify the cleaning process every time it's been used, and that would cause the cleaning process to become a possible bottleneck.
You'd end up with one process that needs to handle the possibility of a high load of messages from many other processes, and it might not be able to keep up.

A better approach is to make eachh to-do server decide on its own when it wants to terminate. This will simplify the logic and avoid any performance bottlenecks. This is an example of something that can be done with `GenServer` but can't be implemented with `Agent`.
An idle period in a `GenServer` can be detected in a few ways, and here you'll use a simple approach. In values returned from `GenServer` callbacks, you can include one extra element at the end of the return tuple.


**pass through the sample code and explanations**

In the end of this Chapter10, this chapter advice it to always go for `GenServer` because it covers more scenarios and is not much more compilcated than `Agent`.

10.3 ETS table
----
ETS(Erlang Term Storage) tables are a mechanism that allows you to share some state between multiple processes in a more efficient way. ETS tables can be thought of as an optimization tool. Whatever you can do with an ETS table can also be done with `GenServer` or `Agent`, but the ETS version can offer perform much better. However, ETS tables can only handle limited scenarios, so, often, they can't replace server processes.
Typical situations where ETS tables can be useful are shared key-value structuress and counters. Although these scenarios can also be implemented with `GenServer`(or `Agent`), such solutions might lead to performance and scalability issues.

```todo/lib/todo/key_value.ex
defmodule Todo.KeyValue do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end
  def put(key, value) do
    GenServer.cast(__MODULE__, {:put, key, value})
  end
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end
  def init(_) do
    {:ok, %{}}
  end
  def handle_cast({:put, key, value}, store) do
    {:noreply, Map.put(store, key, value)}
  end
  def handle_call({:get, key}, _, store) do
    {:reply, Map.get(store, key), store}
  end

end
```

The `KeyValue` module is a simple `GenServer` that holds a map in its state.
The `put` and `get` requests boil down to invoking `Map.put/3` and `Map.get/2`.

**`bench.ex` is supposed to use for checking performance, but nowhere it is**

```
mix run -e "Bench.run(KeyValue)"
```
This is what I couldn't understand. So go to next.

The key-value(key_value.ex) server becomes a performance bottleneck and a scalability killer.
The system can't efficiently utilize all the hardware resources.


The VM goes to great lengths to use CPUs as well as posible, but the fact remains that you have many processs computing for limited resources. As a result, the key-value server doesn't get a single CPU core all to itself.

10.3.1 Basic operations
----
`ETS tables` is possible to share some state between multiple processes without introducing a dedicated server process.
Compared to other data structures, ETS tables have some unusual cahracteristics:

* There's no specific ETS data type. A table is identified by its ID(a reference) or a global name(an atom) 
* ETS tables are mutable. A write to a table will affect subsequent read opreations.
* Multiple processes can write to or to read from a single ETS table. Writes and reads might be performed simultaneously
* Minimum concurrency safety is ensured. Multiple processes can safely write to the same row of the same table. The last write wins.
* An ETS table resides in a separate memory space. Any data coming in or out is deep copied.
* ETS doesn't put pressure on the garbage collector. Overwritten or deleted data is immedidately released.
* An ETS table is deeply connected to its owner process (by default, the process that created the table). If the owner process terminates, the ETS table is reclaimed.
* Other than on owner-process termination, there's no automatic garbage collection of an ETS table. Even if you don'T hold a reference to the table, it still occupies memory.

```
iex(1)> table = :ets.new(:my_table, [])
#Reference<0.1877492681.4132044807.113475>
iex(2)> :ets.insert(table, {:key_1, 1})
true
iex(3)> :ets.insert(table, {:key_2, 2})
true
iex(4)> :ets.insert(table, {:key_3, 3})
true
iex(5)> :ets.lookup(table, :key_1)
[key_1: 1]
iex(6)> :ets.lookup(table, :key_2)
[key_2: 2]
```

You may wonder why the list is returned if you can have only one row per distinct key. The reason is that ETS tables support other table types--some of which allow duplicate rows. In particular, the following table types are possible:
* `:set` -- This is the default. One row per distinct key is allowed.
* `:ordered_set` -- This is just like `:set`, but rows are in term order(companison via the `<` and `>` operations).
* `:bag` -- Multiple rows with the same key are allowed, but two rows can't be conpletely identical.
* `:duplicate_bag` -- This is just like `:bag`, but it allows duplicate rows.

Another important option is the table's access permissions.
* `:protected` -- This is default. the owner process can read from and write to the table. All other processes can read from the table.
* `:public` -- All processes can read from and write to the table.
* `:private` -- Only the owner process can access the table.

10.3.2 ETS-powered key-value store
----

```ets_key_value.ex
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

end
```

There are a couple of reasons for this improvement. First, ETS operations are handled immediately in the client process. In contrast, a cross-process request involves putting a message in the mailbox of the receiver and then waiting for the receiver to be scheduled in and to handle the request. If the request is a synchronous call, the client process also must wait for the response message to arrive.
In addition, changes to ETS tables are destructive. If a value under some key is changed, the old value is immediately released. Therefore, data managed in ETS tables doesn't put any pressure on a garbage collector. In contrast, transforming standard immutable data generates garbage. In a `GenServer`-based key-value store, frequent writes will generate a lot of garbage, which means the server process is occasionally blocked while it's being garbage collected.

10.3.3 Other ETS operations
----
So far, we've covered only basic insertions and key-based lookups. These are arguably the most important operations you'll need, together with `:ets.delete/2`, which deletes all rows associated with a given key.

Key-based operations are extremely fast, and you should keep this in mind when structuring your tables. Your aim should be to maximize key-based operations, thus making ETS-related code as fast as possible.

Occasionally, you many need to perform non-key-based lookups or modifications, retrieving a list of rows based on value criteria. There are a couple of ways you can do this.
The simplest but least efficient approach is to convert the table to a list using `:ets.tab2list/1`. You can then iterate over the list and filter out your results, for example, by using functions from the `Enum` and `Stream` modules.

Another option is to use `:ets.first/1` and `:ets.next/2`, which make it possible to tranverse the table iteratively. Keep in mind that this traversal isn't isolated. If you want to make sure no one modifies the table while you're traversing it, you should serialize all writes and traversals in the same process. 
Alternatively, you can call `:ets.safe_fixtable/2`, which provides some weak guarantees about traversal. If you're iterating a fixed table, you can be certain there won't be any errors, and eachh element will be visited only once. But an iteration thhhrough the fixed table may or may not pick up rows that are inserted during thhe iteration.

Traversals and `:ets.tab2list/1` aren't very performant. Given that data is always copied from the ETS memory space to the process, you end up copying the entire kill and a waste of resources. A better alternative is to rely on `match patterns` --features that allow you to describe the data you want to retrieve.

**Match Patterns**

```
iex(1)> todo_list = :ets.new(:todo_list, [:bag])
#Reference<0.1957532991.669384709.201196>
iex(2)> :ets.insert(todo_list, {~D[2025-05-09], "Dentist"})
true
iex(3)> :ets.insert(todo_list, {~D[2025-05-09], "Shopping"})
true
iex(4)> :ets.insert(todo_list, {~D[2025-05-10], "Dentist"})
true
iex(5)> :ets.lookup(todo_list, ~D[2025-05-09])
[{~D[2025-05-09], "Dentist"}, {~D[2025-05-09], "Shopping"}]
iex(6)> :ets.match_object(todo_list, {:_, "Dentist"})
[{~D[2025-05-09], "Dentist"}, {~D[2025-05-10], "Dentist"}]
```

The function `:ets.match_object/2` accepts a matchhh pattern --a tuple that describes the shape of the row. The atom `:_` indicates that you accept any value, so the pattern `{:_, "Dentist"}` essentially matches all rows where the second elemnet is "Dentist".

It's also worth mentioning the `:ets.match_delete/2` function, which can be used to delete multiple objects withhh a single statement.



