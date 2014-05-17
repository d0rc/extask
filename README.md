# Extasks

Main purpose of this small library to allow starting tasks in one process and handle results in different process.
Also, it'll let you know if task failed to execute, by returning different codes from `await/1` and `await/2`:

Possible outcomes are:

```
case await(task) do
	:timeout -> 
		IO.puts "Timed out waiting for task to finish/reply"
	{:result, data} -> 
		IO.puts "Task finished fine with result: #{inspect data}"
	{:exit, reason} -> 
		IO.puts "Task finished with no result, exit reason is: #{inspect reason}"
end
```


TBD:
	- allow task to be started with retry_count;
	- allow task to be killed if it fails to deliver results in given timeout.