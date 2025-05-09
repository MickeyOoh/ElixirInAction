6 Generic server processes
----

6.1 Building a generic server process
-----
all code that implements a serer process needs to do the following:
* Spawn a separate process
* Run an infinite loop in the process
* Maintain the process state
* React to messages
* Send a response back to the caller

6.1.1 Plugging in with modules
----
The generic code will perform various tasks common to server processes, leaving the specific decisions to concrete implementations.
For example, the generic code will spawn a process, but the concrete implementation must determine the initail state.

6.1.5 Exercise Refactoring the to-do server
-----

6.2 Using GenServer
----
