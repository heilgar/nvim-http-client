local M = {}

-- Initialize state table in global vim namespace to ensure persistence
_G._http_client_state = _G._http_client_state or {
    responses = {},
    current_response = nil,
    max_responses = 10
}

M.get_current_response = function()
    return _G._http_client_state.current_response
end

M.store_response = function(response)
    -- Store as current response
    _G._http_client_state.current_response = response

    -- Add to history
    table.insert(_G._http_client_state.responses, 1, vim.deepcopy(response))

    -- Trim history if needed
    while #_G._http_client_state.responses > _G._http_client_state.max_responses do
        table.remove(_G._http_client_state.responses)
    end
end

M.get_responses = function()
    return _G._http_client_state.responses
end

M.get_response = function(index)
    return _G._http_client_state.responses[index]
end

M.clear_responses = function()
    _G._http_client_state.responses = {}
    _G._http_client_state.current_response = nil
end

M.set_max_responses = function(limit)
    _G._http_client_state.max_responses = limit
end

M.store_metrics = function(response_id, metrics)
    if _G._http_client_state.current_response then
        _G._http_client_state.current_response.timing_metrics = metrics
        
        -- Also update in the history
        for _, resp in ipairs(_G._http_client_state.responses) do
            if resp.request_id == response_id then
                resp.timing_metrics = metrics
                break
            end
        end
    end
end

M.get_metrics = function()
    if _G._http_client_state.current_response then
        return _G._http_client_state.current_response.timing_metrics
    end
    return nil
end

return M

