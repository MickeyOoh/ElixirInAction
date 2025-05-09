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


