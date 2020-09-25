defmodule Werewolf.Store do
  defmacro __using__(_) do
    quote do
      use Agent

      def initial, do: %{}

      def start_link(_), do: Agent.start_link(&initial/0, name: __MODULE__)

      def clear(), do: Agent.update(__MODULE__, fn _ -> initial() end)

      def save(_), do: {:error, :not_implemented}

      def all(), do: Agent.get(__MODULE__, &Map.values(&1))

      def get(id) do
        safe_get(Agent.get(__MODULE__, &Map.get(&1, normalize_key(id))))
      end

      def get_by(fun) do
        Agent.get(__MODULE__, fn map ->
          map
          |> Map.values()
          |> Enum.find(fun)
          |> safe_get()
        end)
      end

      def safe_get(nil), do: {:error, :not_found}

      def safe_get(value), do: {:ok, value}

      def persist(key, value) do
        Agent.update(__MODULE__, &Map.put(&1, normalize_key(key), value))
        value
      end

      def normalize_key(key) do
        key
        |> String.trim()
        |> String.downcase()
      end

      defoverridable save: 1, initial: 0
    end
  end
end
