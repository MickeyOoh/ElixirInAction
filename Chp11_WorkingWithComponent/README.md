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

```
iex(1)> Application.started_applications()
[
  {:hello_world, ~c"hello_world", ~c"0.1.0"},
  {:logger, ~c"logger", ~c"1.18.3"},
  {:mix, ~c"mix", ~c"1.18.3"},
  {:iex, ~c"iex", ~c"1.18.3"},
  {:elixir, ~c"elixir", ~c"1.18.3"},
  {:compiler, ~c"ERTS  CXC 138 10", ~c"8.6.1"},
  {:stdlib, ~c"ERTS  CXC 138 10", ~c"6.2.2"},
  {:kernel, ~c"ERTS  CXC 138 10", ~c"10.2.6"}
]
```
the `hello_world` application is running, together with some additional applications, such as Elixir's `mix, iex`, and `elixir`, as well as `stdlib` and `kernel`.

11.1.2 The application behavior
-----
The critical part of the application description is `mod: {HelloWorld.Application, []}`, provided in mix.exs by `application/0`. When the application is started, the function `HelloWorld.Application.start/2` is called.

```
defmodule HelloWorld.Application do
    use Application

    def start(_type, _args) do
        children = []
        opts = [strategy: :one_for_one, name: HelloWorld.Supervisor]
        Supervisor.start_link(children, opts)
    end
end
```
An Application is an OTP behaviour, powered by the `Application` module, which is a wrapper around Erlang's `:application`. To be able to work with `Application`, you must implement your own callback module and define some callback functions.
At minimum, your callback module must contain the `start/2` function. The arguments passed are the application start type(which you'll usually ignore) and an arbitrary argument (a term specified in mix.ex under the `mod` key). 
`start/2` function returns its result in the form of `{:ok, pid}` or `{:error, reason}`.

11.1.3 Starting the application
----
To start the application in the running BEAM instance, you can call `Application.start/1`. 
The `Application.ensure_all_started/2` function is also available, which recursively starts all dependencies that aren't yet started.

```
$ iex -S mix

iex> Application.start(:hello_world)
{:error, {:already_started, :hello_world}}

iex> Application.stop(:hello_world)
[info] Application hello_world exited: :stopped
```

11.1.4 Library applications
-----
You don't need to provide the `mod: ...` option from the `application/0` in mix.exs:
```
defmodule HelloWorld.Application do

    def application do
        []
    end

end
```
In this case, there's no application callback module, which, in turn, means there's no top-level process to be started. This is still a proper OTP application. You can even start it and stop it.
What's the purpose of such applications? This technique is used for `library applications`-- components that don't need to create their own supervision tree.


11.1.5 Implementing the application callback
-----

11.1.6 The application folder structure
----

**Mix Environments**
Mix Projects use three environments: `dev, test`, and `prod`. These three environments produce slight variations in the compiled code. 
For example, in a version compiled for development(dev), you'll likely want to run some extra debug logging, whereas in a version compiled for production(prod), yuo don't want to include such logging. In a version compiled for `tests`, you want to further reduce the amount of logging and use a different database to prevent the tests from polluting your development database.

You can specify a Mix environment by setting the `MIX_ENV` OS environment variable.
To compile the code for prod, you can invoke `MIX_ENV=prod mix compile`. Tp comple and start, you can invoke `MIX_ENV=prod iex -S mix`.



11.2 Working with dependenies
----

11.2.1 Adding a dependency
----

11.2.2 (Adapting the pool)[https://elixirschool.com/ja/lessons/misc/poolboy]
----
With these prepartaions in place, you can start adapting the pool implementation.
Using Poolboy requires starting a process called the pool manager.
While starting the pool manager, you pass the desired pool size(the number of worker porcesses) and the module that powers each worker.
The pool manager starts the worker processes as its children.



