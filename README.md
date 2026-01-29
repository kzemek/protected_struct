# ProtectedStruct

Disallow creating a struct from other modules.

## Usage

```elixir
defmodule Mystruct do
  use ProtectedStruct
  # for warning instead of failing:
  # use ProtectedStruct, on_violation: :warn

  defstruct [:name, :age]

  def new(name, age) when is_binary(name) and is_integer(age) do
    %__MODULE__{name: name, age: age}
  end
end
```

Trying to create `%MyStruct{}` from other modules will result in a compilation error:

```elixir
defmodule StructUser do
  def create_new_mystruct do
    %MyStruct{}
  end
end

# ** (ProtectedStruct.Error) %Mystruct{} can only be created inside its own module
#    (myproj 0.1.0) expanding struct: Mystruct.__struct__/1
#    struct_user.ex:3: (file)
```

## Installation

The package can be installed by adding the following to your `mix.exs`:
1. `protected_struct` to list of dependencies
2. `ProtectedStruct.Tracer` to list of Elixir tracers

```elixir
# mix.exs

def project do
  [
    elixirc_options: [tracers: [ProtectedStruct.Tracer]],
  ]
end

def deps do
  [
    {:protected_struct, "~> 0.1.0"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/protected_struct>.
