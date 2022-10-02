# Task API

A task object has a few helper methods.

## task:get_spec_name()

## task:get_source_name()

## task:get_runner_name()

## task:get_state()

Returns the current task state, which can evolve from `ready` -> `running` -> `done` | `cancelled`.

## task:request_stop()

Signal the underlying job that this task should be cancelled.

## task:get_started_time()

## task:get_finished_time()

## task:on_finish()

Add a callback for when the task has finished.

Example:

```lua
local task_id, task = tasks.run("test")

task:on_finish(function()
    print("task id: "..task_id.." has finished")
end)
```
