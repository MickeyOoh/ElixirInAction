Chp09 Isolating error effects
---

Covers
* Understanding supervision trees
* Starting workers dynamically
* "Let it crash"

Regardless of what goes wrong in a worker process, you can be sure that the supervisor will detect an error and restart the worker.
Supervisor has an important benefit: it makes your system more available to its clients. Unexpected errors will occur no matter hhow hard you try to avoid them.
Isolating the effects of such errors allows other parts of the system to run and provide service while you're recovering from the error.

9.1 Supervision trees
----
We'll discuss how to reduce the effect of an error on the entire system.

9.1.1 Separating loosely dependent parts
----

9.1.2 Rich process discovery
----
An error in one daabase worker will crash the entire database structure and terminate all running database operations.
Ideally, you want to confine a database error to a single worker. This means each database worker must be directly supervised.
There's one problem with this approach. Recall that in the current version, the database server starts the workeders and keeps their PIDs in its internal list.
But if a process is started from a supervisor, you don't have access to the PID of the worker process. This is a property of supervisors.
You can't keep a worker's PID for a long time because that process might be restated, and its successor will have a different PID.
therefore, you need a way to give symbolic names to supervised processes and access each process via this name, which will allow you to reach the right process even after multiple restarts.
 You could use registered names for this purpose: PIDs are changeble by restarting. 

9.1.3 Via tuples
----
A `via tuple` is a mechanism that allows you to use an arbitary third-party registry to register OTP-compliant processes,
such as `GenServer` and supervisors.
Recall that you can provide a `:name` option when starting a `GenServer`:
```
GenServer.start_link(callback_module, some_arg, name: some_name)
```
So far, you've only passed atoms as the `:name` option, which caused the started process to be registered locally, 
But the `:name` option can also be provided in the shape of `{:via, some_module, some_arg}`. Such a tuple is called `via tuple`.

9.1.4 Registering database workers
-----
Now that you've learned the basics of `Registry`, you can implement registration and discovery of your database workers. First, you need to create the `Todo.ProcessRegistry` module:

The interface functions are straightforward. The `start_link` simply forwards to the `Registry` module to start a unique registry.
The `via_tuple/1` can be used to other modules, such as `Todo.DatabaseWorker`, to create the appropriate `via_tuple` that registers a process with thhis registry.
Because the registry is a process, it should be supervised. Therefore, you include `child_spec/1` in the module. Here, you're using `supervisor.child_spec/2` to adjust the default specification from the `Registry` module.


9.1.6 Organizing the supervision tree
----

RESTART STRATEGIES
* `:one_for_one` - supervisor handles a process termination by starting a nwe process in its place, leaving other children alone.

* `:one_for_all` - when a child crashes, the supervisor terminates all other chhihldren and then starts all children.
* `rest_for_one` - When a child crashes, the supervisor terminates all younger sibings of the crashed child. then, the supervisor starts new child processes in place of the terminated ones.


9.2 Starting processes dynamically
----

9.2.1 Registering to-do servers
----

9.2.2 Dynamic supervision
----
You need to supervise to-do servers. There's a twist, though.
Unlike database workers, to-do servers are created dynamically when needed. Initially, no to-do server is running; each is created on demand when you call `Todo.Cache.server_process/1`.
This effectively means you can't specify supervisor children up front because you don't know how many children you'll need.

   For such cases, you need a dynamic supervisor that can start children up front because you don't know how many children you'll need.

   `DynamicSupervisor` is similar to `Supervisor`, but where `Supervisor` is used to start a predefined list of children, `DynamicSupervisor` is used to start children on demand.
When you start a dynamic supervisor, you don't provide a list of child specifications, so only the supervised child using `DynamicSupervisor.start_child/2`.

You'll convert `Todo.Cache` into a dynamic supervisor, much like what you did with the database as the following:

```cache.ex
defmodule Todo.Cache do
    def start_link() do
        IO.puts("Starting to-do cache.")
        DynamicSupervisor.start_link(
            name: __MODULE__,
            strategy: :one_for_one
        )
    end
    - - -
end
```

You start the supervisor using `DynamicSupervisor.start_link/1`. This will start the supervisor process, but no children are specified at this point.
Notice that when starting the supervisor, you're also passing thhe `:name` option. This will cause the supervisor to be registered under a local name.
By making the supervisor locally registered, it's easier for you to interact with the supervisor and ask it to start a chihld.
You can immediately use this by adding the `start_child/1` function, which starts the to-do server for the given to-do list:
```
defmodule Todo.Cache do
  - - -
    defp start_child(todo_list_name) do
        DynamicSupervisor.start_child(
            __MODULE__,
            {Todo.Server, todo_list_name}
        )
    end
  - - -
end
```

Here, you're invoking `DynamicSupervisor.start_child/2`, passing it hte name of your supervisor and the child specification of the child. The `{Todo.Server, todo_list_name}` specification will lead to the invocation of `Todo.Server.start_link(todo_list_name)`. The to-do server will be started as the child of the `Todo.Cache` supervisor.
It's worth noting that `DynamicSupervisor.start_child/2` is a cross-process synchronous call. A request is sent to the supervisor process, which then starts the child.
If several client processes simultaneously try to start a chhild under the same supervisor, the requests will be serialized.

One small thing left to do is implement `child_spec/1`:
```
def child_spec(_arg) do
    %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, []},
        type: :supervisor
    }
end
```
At this point, the to-do cache is converted into a dynamic supervisor.

9.2.3 Finding to-do servers
----
The final thing left to do is change the discovery `Todo.Cache.server_process/1` function. This function takes a name and returns the `pid` of the to-do server, starting it if it's not running. The following:
```cache.ex
def server_process(todo_list_name) do
    case start_child(todo_list_name) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
    end
end
```

The registrtion is performed in the started process before `init/1` is invoked. This registrtion can failif some other process is already registered under the same key. 
In this case, `GenServer.start_link` doesn't resume to run the server loop. Instead, it returns `{:error, {:already_started, pid}}`, where the `pid` points to the process that's registered under the same key. This result is then returned by `DynamicSupervisor.start_child`.

It's worth briefly discussing how `server_process/1` behaves in a concurrent scenario. Consider the case of two process invoking thhie function at the same time.
The execution moves to `DynamicSupervisor.start_child/2`, so you might end up with two simultaneous executions of `start_child` on the same supervisor. Recall that a child is started in the supervisor process. Therefore, the invocations of `start_child` are serialized and `server_process/1` doesn't suffer from race conditions.

9.2.4 Using the temporary restart strategy
----
You'll configure the to-do server to be a `:temporary` child.
As a result, if a to-do server stops -- says, due to a crash --- it won't be restarted.
Why choose this approach? Servers are started on demand, so when a user tries to ineract with a to-do list, if the serverpprocess isn't running, it will be started.
If a to-do list server crashes, it will be started on the next use, so there's no need to restart it automatically.



9.3 "Let it crash"
-----

9.3.1 Processes that shouldn't crash
----
Processes that shouldn't crash are informally called a system's `error kernel`--processes that are critical for the entire systemto work and whose state can't be restored in a simpole and consistent way.
Such processes are the heart of your system, and you generally don't want them to crash because, without them, the system can't provide any service.

Additionally, you could consider including defensie `try/catch` expressions in each `handle_*` callback of a critical process, to prevent a proces from crashing.

```
def handle_call(message, _, state) do
    try
        new_state =
            state
            |> transformation_1()
            |> transformation_2()
            - - -
        {:reply, response, new_state}
    catch _, _ ->
        {:reply, {:error, reason}, state}
    end
end
```

9.3.2 Handling expected errors
----
The whole point of the "let it crash" approach is to leave recovery of unexpected errors to supervisors.
But if you can predict an error and you have a way to deal with it, there's no reason to let the process crash.

```
def handle_call({:get, key}, _, db_folder) do
    data =
        case File.read(file_name(db_folder, key)) do
            {:ok, contents} -> :erlang.binary_to_term(contents)
            _ -> nil
        end
    {:reply, data, db_folder}
end
```

If this doesn't succeed, you return `nil`, treating this case as if an entry for the given key isn't in the database.
But you can do better. Consider using an error only when the file isn't available.
This error is identified with `{:error, :enoent}`, so the corresponding code would look like this:
```
case File.read(....) do
    {:ok, contents} -> do_something_with(contents)
    {:error, :enoent} -> nil
end
```

9.3.3 Preserving the state
----
Keep in mind that state isn't preserved when a process is restarted.
In some cases, you'll want the process's state to survice the crash.
This isn't provided out of the box; you need to implement it yourself.
The general approach is to save the state outside of the process(e.g. in another process or to a database) and thhen restore the state when the successor processis started.

```
def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
end
```

