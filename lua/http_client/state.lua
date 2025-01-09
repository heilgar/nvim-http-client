local M = {}

-- Initialize state table in global vim namespace to ensure persistence
_G._http_client_state = _G._http_client_state or {
    responses = {},
    current_response = nil,
    max_responses = 10
}

-- Get the current response
function M.get_current_response()
    return _G._http_client_state.current_response
end

-- Store a new response
function M.store_response(response)
    -- Store as current response
    _G._http_client_state.current_response = response

    -- Add to history
    table.insert(_G._http_client_state.responses, 1, vim.deepcopy(response))

    -- Trim history if needed
    while #_G._http_client_state.responses > _G._http_client_state.max_responses do
        table.remove(_G._http_client_state.responses)
    end
end

-- Get response history
function M.get_responses()
    return _G._http_client_state.responses
end

-- Get response by index
function M.get_response(index)
    return _G._http_client_state.responses[index]
end

-- Clear all responses
function M.clear_responses()
    _G._http_client_state.responses = {}
    _G._http_client_state.current_response = nil
end

-- Set max responses limit
function M.set_max_responses(limit)
    _G._http_client_state.max_responses = limit
end

return M

