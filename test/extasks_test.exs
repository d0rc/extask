defmodule ExTask.Test.Map do
	use ExUnit.Case, async: true
	alias ExTask, as: Tasks

	test "tasks: maptest" do
		result = Enum.map(1..100, fn v ->
			Tasks.run(fn -> v + 100 end)
		end)
		|> Enum.map(fn task ->
			case Tasks.await(task) do
				{:result, result} -> result
				_different -> _different
			end
		end)
		assert ^result = (for v <- 1..100, do: (v+100))
	end
end

defmodule ExTask.Test.MapLong do
	use ExUnit.Case, async: true
	alias ExTask, as: Tasks

	test "tasks: maptest" do
		result = Enum.map(1..100, fn v ->
			Tasks.run(fn -> 
				:timer.sleep(5999)
				v + 100
			end)
		end)
		|> Enum.map(fn task ->
			case Tasks.await(task, 1) do
				{:result, result} -> result
				_different -> _different
			end
		end)
		assert ^result = (for _ <- 1..100, do: :timeout)
	end
end

defmodule ExTask.Test.MapFailing do
	use ExUnit.Case, async: true
	alias ExTask, as: Tasks

	test "tasks: maptest" do
		result = Enum.map(1..100, fn _ ->
			Tasks.run(fn -> 
				:timer.sleep(500)
				2 = 1
			end)
		end)
		|> Enum.map(fn task ->
			case Tasks.await(task) do
				{:result, result} -> result
				{:exit, _} -> :ok
			end
		end)
		assert ^result = (for _ <- 1..100, do: :ok)
	end
end