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

**This contents don't explain what Agents are and just tell about the difference with `GenServer`.**

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


