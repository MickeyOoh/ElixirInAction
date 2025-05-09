Chp11 Working with components
-----

* Creating OTP applications
* Working with dependencies
* Building a web server
* Configuring applications

11.1 OTP applications
----

11.1.1 Creating applications with the mix tool
-----

11.1.5 Implementing the application callback
-----

11.2 Working with dependenies
----

11.2.2 Adapting the pool
----
With these prepartaions in place, you can start adapting the pool implementation.
Using Poolboy requires starting a process called the pool manager.
While starting the pool manager, you pass the desired pool size(the number of worker porcesses) and the module that powers each worker.
The pool manager starts the worker processes as its children.



