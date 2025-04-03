local M = {}

-- Timing metrics table for tracking performance
local timing_metrics = {}

M.start_metric = function(request_id, metric_name)
    if not timing_metrics[request_id] then
        timing_metrics[request_id] = {}
    end

    if not timing_metrics[request_id][metric_name] then
        timing_metrics[request_id][metric_name] = {}
    end

    timing_metrics[request_id][metric_name].start_time = vim.loop.hrtime()
end

M.end_metric = function(request_id, metric_name)
    if timing_metrics[request_id] and timing_metrics[request_id][metric_name] then
        local metric = timing_metrics[request_id][metric_name]
        local end_time = vim.loop.hrtime()

        if metric.start_time then
            -- Convert from nanoseconds to milliseconds
            metric.duration = (end_time - metric.start_time) / 1000000
            metric.end_time = end_time
            return metric.duration
        end
    end
    return nil
end

M.get_metrics = function(request_id)
    return timing_metrics[request_id] or {}
end

M.clear_metrics = function(request_id)
    timing_metrics[request_id] = nil
end

M.format_metrics = function(metrics)
    local lines = {}
    
    local total_duration = 0
    if metrics.total and metrics.total.duration then
        total_duration = metrics.total.duration
    end
    
    table.insert(lines, string.format("Total Time: %.2f ms", total_duration))
    
    -- Calculate remaining time to allocate if we're missing some phases
    local accounted_time = 0
    if metrics.dns_resolution and metrics.dns_resolution.duration then
        accounted_time = accounted_time + metrics.dns_resolution.duration
    end
    
    if metrics.connection and metrics.connection.duration then
        accounted_time = accounted_time + metrics.connection.duration
    end
    
    if metrics.tls_handshake and metrics.tls_handshake.duration then
        accounted_time = accounted_time + metrics.tls_handshake.duration
    end
    
    if metrics.send_request and metrics.send_request.duration then
        accounted_time = accounted_time + metrics.send_request.duration
    end
    
    if metrics.server_processing and metrics.server_processing.duration then
        accounted_time = accounted_time + metrics.server_processing.duration
    end
    
    if metrics.content_transfer and metrics.content_transfer.duration then
        accounted_time = accounted_time + metrics.content_transfer.duration
    end
    
    local unaccounted_time = total_duration - accounted_time
    
    -- If we have no detailed metrics but have a total time, create estimated breakdowns
    if accounted_time == 0 and total_duration > 0 then
        -- Typical distribution: DNS 5%, Connection 10%, TLS 15%, Send 5%, Server 50%, Transfer 15%
        table.insert(lines, string.format("DNS Resolution: ~%.2f ms (estimated)", total_duration * 0.05))
        table.insert(lines, string.format("TCP Connection: ~%.2f ms (estimated)", total_duration * 0.10))
        
        -- Only estimate TLS if the URL is https
        if metrics.url and metrics.url:match("^https") then
            table.insert(lines, string.format("TLS Handshake: ~%.2f ms (estimated)", total_duration * 0.15))
        end
        
        table.insert(lines, string.format("Request Sent: ~%.2f ms (estimated)", total_duration * 0.05))
        table.insert(lines, string.format("Server Processing: ~%.2f ms (estimated)", total_duration * 0.50))
        table.insert(lines, string.format("Content Transfer: ~%.2f ms (estimated)", total_duration * 0.15))
    else
        -- Add detailed breakdown of available metrics
        if metrics.dns_resolution and metrics.dns_resolution.duration then
            table.insert(lines, string.format("DNS Resolution: %.2f ms", metrics.dns_resolution.duration))
        elseif unaccounted_time > 0 then
            table.insert(lines, string.format("DNS Resolution: ~%.2f ms (estimated)", total_duration * 0.05))
            unaccounted_time = unaccounted_time - (total_duration * 0.05)
        end
        
        if metrics.connection and metrics.connection.duration then
            table.insert(lines, string.format("TCP Connection: %.2f ms", metrics.connection.duration))
        elseif unaccounted_time > 0 then
            table.insert(lines, string.format("TCP Connection: ~%.2f ms (estimated)", total_duration * 0.10))
            unaccounted_time = unaccounted_time - (total_duration * 0.10)
        end
        
        if metrics.tls_handshake and metrics.tls_handshake.duration then
            table.insert(lines, string.format("TLS Handshake: %.2f ms", metrics.tls_handshake.duration))
        elseif metrics.url and metrics.url:match("^https") and unaccounted_time > 0 then
            table.insert(lines, string.format("TLS Handshake: ~%.2f ms (estimated)", total_duration * 0.15))
            unaccounted_time = unaccounted_time - (total_duration * 0.15)
        end
        
        if metrics.send_request and metrics.send_request.duration then
            table.insert(lines, string.format("Request Sent: %.2f ms", metrics.send_request.duration))
        elseif unaccounted_time > 0 then
            table.insert(lines, string.format("Request Sent: ~%.2f ms (estimated)", total_duration * 0.05))
            unaccounted_time = unaccounted_time - (total_duration * 0.05)
        end
        
        if metrics.server_processing and metrics.server_processing.duration then
            table.insert(lines, string.format("Server Processing: %.2f ms", metrics.server_processing.duration))
        elseif unaccounted_time > 0 then
            table.insert(lines, string.format("Server Processing: ~%.2f ms (estimated)", 
                math.max(unaccounted_time * 0.70, total_duration * 0.30)))
            unaccounted_time = unaccounted_time - (unaccounted_time * 0.70)
        end
        
        if metrics.content_transfer and metrics.content_transfer.duration then
            table.insert(lines, string.format("Content Transfer: %.2f ms", metrics.content_transfer.duration))
        elseif unaccounted_time > 0 then
            table.insert(lines, string.format("Content Transfer: ~%.2f ms (estimated)", 
                math.max(unaccounted_time, total_duration * 0.15)))
        end
    end
    
    return table.concat(lines, "\n")
end

M.generate_request_id = function()
    return tostring(vim.loop.hrtime())
end

return M

