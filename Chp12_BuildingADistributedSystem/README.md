Chp12 Building a distributed System
-----

* Working with distribution primitives
* Building a fault-tolerant cluster
* Network considerations

12.1 Distribution primitives
----
Distributed BEAM systems are built by connecting multiple nodes in a cluster. A mode is a BEAM instance that has a name associated with it.

12.1.1 Starting a cluster
----

```
$ iex --sname node1@localhost
iex(node1@localhost)>

iex(node1@localhost)> node()
:node1@localhost

```

12.1.2 communicating between  nodes
----

```
iex(node2@localhost)1> Node.connect(:node1@localhost)
true
iex(node2@localhost)2> Node.list()
[:node1@localhost]
iex(node2@localhost)3> Node.spawn(:node1@localhost, fn -> IO.puts("Hello from #{node()}") end)
#PID<13426.114.0>
Hello from node1@localhost
```
The output proves that the lambda has been executed on another node.

**Group leader process**
the output is printed in the shell of `node2` which spawn executed. How is this possible? The reason lies in how Erlang does standartd I/O operations.

All standard I/O calls (such as `IO.puts/1`) are forwarded to the group leader --a rpocess that's in charge of performing the actual input or output. A spawned process a process inherits the group leader from the process that spawned it, even when you're spawning leader is still on `node2`. As a consequence, the string to be printed is created on `node1`, but the output is printed on `node2`.


