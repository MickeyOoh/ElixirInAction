Chp08 Fault tolerance basics
----
This chapter covers
* Run-time errors
* Errors in concurrent systems
* Supervisors

Fault tolerance is a first-class concept in BEAM. The ability to develop reliable systems that can operate even when faced with run-time errors is what brought us Erlang in the first place.
thhe aim of fault tolerance is to acknowledge the existence of failures.

8.1 Run-time errors
----
situations:
* one of the most common examples is a `failed pattern match`
* a synchronous `GenServer.call`
    if the response message doesn't arrive in a given time interval(5 seconds by default), a run-time error happens.
* other examples, such as inalid arithmetic operations, invocation of a nonexistent function, and explicit error signaling.

8.1.1 Error types
----
BEAM distinguishes three types of run-time errors: `errors`, `exits`, and `throws`.

8.1.2 Handling errors
-----

```
try do
----
catch error_type, error_value ->
---
end
```

8.1.2 Handling errors
-----

```
try do
----
catch error_type, error_value ->
---
end
```

8.1.2 Handling errors
-----

```
try do
----
catch error_type, error_value ->
---
end
```

```
try do
 ---
catch
  :throw, {:result, x} -> x
end
```

```
try do
  ---
catch
  type_pattern_1, error_value_1 ->
    ---
  type_pattern_2, error_value_2 ->
    ---
  ---
end
```

```
try do
    raise("Somethhing went wrong")
catch
    _, _ -> IO.puts("Error caught")
after
    IO.puts("Cleanup code")
end
```

8.2 Errors in concurrent systems
----
Concurrency plays a central role in building fault-tolerant.

```
iex> spawn(fn ->            # process1
        spawn( fn ->        # process2
            process.sleep(1000)
            IO.puts("Process 2 finished")
            end)
            raise("Something want wrong")
        end)
```
The executiong of process 2 goes on, despite the fact that process1
crashes. Information about the crash of process1 is printed to the screen, but the rest of the system runs normally.
Furthermore, because processes share no memory, a crash in one process won't leave memory grabage that might corrupt another process.
Therefore, by running independent actions in separtae processes, you automatically ensure isolation and protection.


All the boxes in the figure are BEAM processes. A crash in a single to-do server doesn't affect operatins on other to-do server processes.
Of course, this isolation isn't enough by itself. processes often communicate with each other. 
If a process isn't running, its clients can't use its services. 
For example, if the database process goes down, the to-do servers can't query it.
What's worse, modifications to the to-do list won'T be persisted. Obviously thhis isn't desirable behavior, and you must have a way of tetecing a process carsh and smoehow recovering from it.



