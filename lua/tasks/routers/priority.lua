return function(name, spec, args, runners)
    local valid_runners = vim.tbl_filter(function(runner_name)
        local runner = runners[runner_name]

        if runner.can_handle_spec == nil then
            return true
        end

        return runner:can_handle_spec(name, spec, args)
    end, vim.tbl_keys(runners))

    table.sort(valid_runners, function(r1, r2)
        local p1 = runners[r1].priority or 10
        local p2 = runners[r2].priority or 10

        return p1 < p2
    end)

    return valid_runners[1]
end
