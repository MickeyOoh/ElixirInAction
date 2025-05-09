Part 2 Concurrent Elixir
----

Chp05: Introduction to concurrency in BEAM
Chp06: OTP and generic server processes
Chp07: exmples of a more involced concurrent system
Chp08: The basice error-detection mechanism
Chp09: how to build supervision trees to minimize negative effects
Chp10: Some alternatives to generic server processes

Chp05 Concurrency primitives
-----

The following chanllenges:
* `Fault Tolerance` -- Minimize, isolate, and recover from the effects of run-time errors
* `Scalability` -- Handle a load increase by adding more hardware resources without changing or redeploying the code
* `Distrubution` -- Run your system on multiple machines so that others can take over if one machine crashes

5.2 Working with processes
----

```
iex> run_query = 
        fn query_def ->
            Proess.sleep(2000)
            "#{query_def} result"
        end

iex> run_query.("query 1")
"query 1 result"
```

5.2.1 Creating processes
----
To create a process, you can use the auto-imported `spawn/1` function:
```
spawn(fn ->
    expression_1
    - - -
    expression_n
end)
```

query concurrently:
```
iex> spawn(fn ->
        query_result = run_query.("query 1")
        IO.puts(query_result)
      end)

#PID<0.49.0>        <--- Immediately returned
query 1 result      <--- Printed after 2 seconds
```
The call to `spawn/1` returns immediately, and you can do something else in the shell while the query runs concurrently. Then, after 2 seconds, the result is
printed to the screen.


First, you'll create a helper lambda that concurrently runs the query and prints the result:
```
iex> async_query = 
        fn query_def ->
            spawn(fn ->
                query_result = run_query.(query_def)
                IO.puts(query_result)
                end)
        end
iex> async_query.("query 1")
#PID<0.52.0>

query 1 result      <--- Two secondes later
```

This code demonstrates an important technique: passing data to the crated process.
Notice that `async_query` takes one argument and binds it to the `query_def` variable.
This data is then passed to the newly created process via the closure mechanism. The inner lambda -- the one that runs in a separate process -- references the variable of `query_def` are passed from the main process to the newly crated one.
When it's passed to another process, the data is deep copied because two processes can't share any memory.

5.3 Stateful server processes
----

5.3.4 Complex states
----
State is usually much more complex than a simple number. 
You keep the mutable state using the private `loop` functions.
As the sate becomes more complex, the code of the server process can become increasingly complicated.


Concurrent vs. Functional Approach
-----
A process that maintains mutable state can be regarded as a kind of mutable
data structure. But you shouldn't abuse processes to avoid using the functional approach of transforming immutable data.
The data should be modeled using pure functional abstartions, just as you did with `TodoList`. 
A pure funcitonal data structure provides mayn benefits:
* intergrity 完全性-データやシステムの正確性、一貫性、および信頼性を維持すること 
* atomicity 原子性- 処理がすべて成功するか、まったく実行されないかのどちらかであること を保証する性質
* reusability 再利用性-
* testability テスト容易性-

A stateful process serves as a container of such a data structure. The process keeps the state alive and allows other processes in the system to interact with this data via the eposed API.

5.3.5 Registered processes
----

```
Process.register(self(), :some_name)
```

The follwoing constraints apply to regitered names:
* The name can only be an atom
* A single process can have only one name
* Two processes can't have the same name


```

The follwoing constraints apply to regitered names:
* The name can only be an atom
* A single process can have only one name
* Two processes can't have the same name


```

The follwoing constraints apply to regitered names:
* The name can only be an atom
* A single process can have only one name
* Two processes can't have the same name


```

The follwoing constraints apply to regitered names:
* The name can only be an atom
* A single process can have only one name
* Two processes can't have the same name


```

The follwoing constraints apply to regitered names:
* The name can only be an atom
* A single process can have only one name
* Two processes can't have the same name


```

The follwoing constraints apply to regitered names:
* The name can only be an atom
* A single process can have only one name
* Two processes can't have the same name

5.4 Runtime considerartions
-----

5.4.1 A process is sequential
----

If many processes send messages to a single process, that single process may become a bottleneck, which significantly affects overall throughput of the system.
5.4 Runtime considerartions
-----

5.4.1 A process is sequential
----

If many processes send messages to a single process, that single process may become a bottleneck, which significantly affects overall throughput of the system.
5.4 Runtime considerartions
-----

5.4.1 A process is sequential
----

If many processes send messages to a single process, that single process may become a bottleneck, which significantly affects overall throughput of the system.
5.4 Runtime considerartions
-----

5.4.1 A process is sequential
----

If many processes send messages to a single process, that single process may become a bottleneck, which significantly affects overall throughput of the system.

Once you identify the bottleneck, you should try to optimize the process internally.

5.4.2 Unlimitred process mallboxes
---
The mailbox size is limited by available memory.