defmodule PoolboyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :poolboy_app,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PoolboyApp.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poolboy, "~> 1.5.1"}
    ]
  end
end
