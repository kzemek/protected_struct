defmodule ProtectedStruct.MixProject do
  use Mix.Project

  def project do
    [
      app: :protected_struct,
      description: "Protect Elixir struct creation outside of its module",
      version: "0.1.2",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ] ++ docs()
  end

  defp docs do
    [
      name: "ProtectedStruct",
      source_url: "https://github.com/kzemek/protected_struct",
      homepage_url: "https://github.com/kzemek/protected_struct",
      docs: [
        main: "readme",
        extras: [
          "README.md": [title: "Readme"],
          LICENSE: [title: "License"],
          NOTICE: [title: "Notice"]
        ]
      ]
    ]
  end

  defp package do
    [
      links: %{"GitHub" => "https://github.com/kzemek/protected_struct"},
      licenses: ["Apache-2.0"],
      files: [
        "lib",
        "LICENSE",
        "mix.exs",
        "NOTICE",
        "README.md"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false, optional: true}
    ]
  end
end
