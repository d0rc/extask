defmodule ExTask do
  use Application

  def start(_type, _args) do
  	:ok = :pg2.create(:tasks)
    {:ok, pid} = Extasks.Supervisor.start_link
  	for n <- 1..(:application.get_all_env(:extask)[:workers]) do
  		:supervisor.start_child Extasks.Supervisor, Supervisor.Spec.worker(ExTask.Server, [], [id: :erlang.binary_to_atom("extask#{n}", :utf8)])
  	end
  	{:ok, pid}
  end

  def run(task) do
  	worker = :pg2.get_members(:tasks) |> Enum.shuffle |> hd
  	{worker, ExTask.Server.run(worker, task)}
  end
  def await({worker,task}, timeout \\ 5000), do: ExTask.Server.await({worker, task}, timeout)
end

defmodule ExTask.Server do
	use ExActor.GenServer
	require Logger
	@debug false

	defmacro debug_info(str) do
		case @debug do
			true ->
				quote do
					Logger.info(unquote(str))
				end
			false -> nil
		end
	end
	#
	# TODO: add await function...
	#

	def await({worker, task}, timeout \\ 5000) do
		#
		#	should wait until results appears
		#
		subsribe_to_results(worker, task, self)

		receive do
			{:results, ^task, data} -> 
				remove_reply(worker, task)
				data
			after timeout -> :timeout
		end
	end

	#
	# Tasks server in it's full glory
	#
	definit do
		debug_info "Starting tasks manager."
		:pg2.join(:tasks, self)
		initial_state(%{})
	end 
	defcall run(task), state: state do
		root = self
		{child, _} = spawn_monitor(fn ->
			result = task.()
			send(root, {:done, self, result})
		end)
		set_and_reply(Map.put(state, child, %{response: :not_ready, waiter: nil}), child)
	end
	defcall check_result(child), state: state do
		reply state[child]
	end
	defcall remove_reply(child), state: state do
		set_and_reply(Map.delete(state, child), state[:child])
	end
	defcast subsribe_to_results(child, waiter), state: state do
		case state[child] do
			current = %{response: :not_ready} -> 
				new_state(Map.put(state, child, %{ current | waiter: waiter}))
			%{response: response} ->
				send(waiter, {:results, child, response})
				noreply
			nil -> 
				debug_info "Tried to subscribe to Phantom child: #{inspect child}"
				noreply
		end
	end

	definfo {:DOWN, _ref, :process, pid, reason}, state: state do
		case state[pid] do
			%{response: :not_ready, waiter: waiter} ->
				debug_info "Child terminated without result yet."
				if waiter != nil, do: send(waiter, {:results, pid, {:exit, reason}})
				new_state(Map.put state, pid, %{response: {:exit, reason}, waiter: waiter})
			nil ->
				debug_info "Phantom child #{inspect pid} exited."
				noreply
			_response -> 
				debug_info "Child #{inspect pid} exited..., saved response is: #{inspect _response}"
				noreply
		end
	end
	definfo {:done, pid, result}, state: state do
		debug_info "Got result: #{inspect result}"
		case state[pid] do
			%{waiter: waiter} ->
				if waiter != nil, do: send(waiter, {:results, pid, {:result, result}})
				new_state(Map.put(state, pid, %{response: {:result, result}, waiter: waiter}))
			nil ->
				debug_info "Got result for Phantom!"
				new_state(Map.put(state, pid, %{response: {:result, result}, waiter: nil}))
		end
	end
end
