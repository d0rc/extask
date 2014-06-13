defmodule Extasks.Mixfile do
  use Mix.Project

  def project do
    [app: :extask,
     version: "0.0.1",
     deps: deps]
  end

  def application do
    [applications: [:exlager, :exactor],
     mod: {ExTask, []}]
  end

  defp deps do
    [
      {:exlager, github: "khia/exlager"},
      {:exactor, github: "sasa1977/exactor"}
    ]
  end
end
