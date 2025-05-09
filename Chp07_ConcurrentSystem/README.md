Chp07 Building a concurrent system
----
* Working wiht the Mix project
* Managing multiple to-do lists
* Persisting data
* Reasoning with processes

7.1 Working with the Mix project
----

7.2 Managing multiple to-do lists
----

7.2.2 Writing tests
-----


7.2.3 Analyzing process dependencies
----

7.3 Persisting data
----
you'll extend the to-do cache and introduce basic data persistence.
the focus is on exploring the process model
- how you can organize your system into various server processes.
- how you can analyze dependencies
- how you can identify and address bottlenecks

For data persistence, you'll use simple `disk-based` persistence, encoding the data into the Erlang external term format.

7.3.1 Encodeing and persisting
----
To encode an arbitrary term, you use the `:eralng.term_to_binary/1` function,
which accepts term and returns an encoded byte sequence as a binary value.
The result can be stored to disk, retrieved at a later point, and decoded to a term with the inverse function
`:erlang.binary_to_term/1`.

7.3.2 Using the database
----
You have to do three things:
* Ensure that a database process is started
* Persist the list on every modification
* Try to fetch the list from disk during the first retrieval

```
def module Todo.Cache do
  ---
    def init() do
        Todo.Database.start()
        {:ok, %{}}
    end
  ---
end
```

**Storing the Databae request**
you need to persist the list after it's modified. Obviously, this must be done from the to-do server, but memember that thhe database's `store` request requires a key.

These are the corresponding changes:
* `Todo.Server.start` now accepts the to-do list name and passes it to `GenServer.start/2`.
* `Todo.Server.init/1` uses this parameter and keeps the list name in the process state.
* `Todo.Server.handle` callbacks are updated to work with the new state format.

**READING THE DATA**
```
def init(name) do
    todo_list = Todo.Database.get(name) || Todo.List.new()
    {:ok, {nme, todo_list}}
end
```
In this case, a long initialization of a to-do server will block the cache process. And since the cache process is used by many clients, this can, in turn, block a larger part of the system.
The solution of this problem, by allowing you to split the initialization into **two phases**: one that blocks the client process and another one that can be performed after the `GenServer.start` invocation in the client has finished.
To do this, `init/1` must return the result in the shape of 
`{:ok, initial_state, {:continue, some_arg}}`.

```
defmodule Todo.Server do
 ---
    def init(name) do
        {:ok, {name, nil}, {:continue, :init})
    end

    def handle_continue(:init, {name, nil}) do
        todo_list = Todo.Database.get(name) || Todo.List.new()
        {:noreply, {name, todo_list})
    end
 - - -
end
```

7.3.3 Analyzing the system
----
Recall that the database performs term encoding/decoding and, even worse, disk I/O operations.
Depending on the load and list sizes, this can negatively affect performance. Let's recall all the places database requests are issued:
```
defmodule Todo.Server do

    def handle_continue(:init, {name, nil}) do
        todo_list = Todo.Database.get(name) || Todo.List.new()
        - - -
    end
    - - -
    def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
        - - -
        Todo.Database.store(name, todo_list)
        - - -
    end
end
```
The `store` request may not seem problematic from the client perspective because it's an asynchronous cast.
A client issues a `store` request and then goes about its business.
But if requests to the database come in fater than they can be handled, the process mailbox will grow and increasingly consume memory.

The `get` request can cause additional probelms. It's a synchronous call, so the to-do server waits while the database returns the response. While it's waiting for the response, this to-do server can't handle new messages.

7.3.4 Addressing the process bottleneck
----
There are many approaches to addressing the bottleneck is to bypass by the singleton database process.

`BYPASSING THE PROCESS`
The simplest possible way to eliminate the process bottleneck is `to bypass process`.
You should ask yourself--does this need to be a process, or can it be a plain module?

There are various reasons for runnng a piece of code in a dedicated server process.
* the code must manage a long-living state
* The code handles a kind of resource that can and should be reused between multiple invocations, such as a TCP connections, database connection, file handle, and so on.
* A critical section of the code must be synchronized. Only one instance of this code may be running in any moment.

**Limiting Concurrency with pooling**
for example, your database process might create three worker processes and keep thier internal state. When a request arrives, it's delegated to one of the worker processes, perhaps in a round-rogin fashion or with some other load-distribution strategy.

All requests still arrive at thhe database process first, but they're quickly forwarded to one of the workers which is fetched by spawn().

7.3.5 Exercise: Pooling and synchhronizing
----
This exercise introduces pooling and makes the database internally delegate to three workers that perform the actual database operations. Moreover, there should be per-key(to-do list name) synchronization on the database level.
Data with the same key should always be treated by the same worker.
* the only thing that needs to change is the `Todo.Database` implementation.
* Introduce a `Todo.DatabaseWorker` module to copy from `Todo.Database`, the process must not registered under a name because you need to run multiple instances.
* `Todo.DatabaseWorker.start` should receive the database folder as its agument and pass it as the second argument to `GenServer.start/2`. 
