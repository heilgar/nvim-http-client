local profiling = require('http_client.utils.profiling')

describe("Profiling", function()
    local test_request_id

    before_each(function()
        test_request_id = profiling.generate_request_id()
    end)

    describe("request ID generation", function()
        it("should generate unique request IDs", function()
            local id1 = profiling.generate_request_id()
            local id2 = profiling.generate_request_id()
            assert.are_not.equal(id1, id2)
        end)
    end)

    describe("metrics tracking", function()
        it("should start and end tracking for metrics", function()
            profiling.start_metric(test_request_id, "test_metric")
            -- Sleep a tiny bit to ensure there's some duration
            vim.loop.sleep(1)
            local duration = profiling.end_metric(test_request_id, "test_metric")
            
            assert.is_not_nil(duration)
            assert.is_true(duration > 0)
        end)

        it("should retrieve stored metrics", function()
            profiling.start_metric(test_request_id, "test_metric")
            vim.loop.sleep(1)
            profiling.end_metric(test_request_id, "test_metric")
            
            local metrics = profiling.get_metrics(test_request_id)
            
            assert.is_not_nil(metrics.test_metric)
            assert.is_not_nil(metrics.test_metric.duration)
            assert.is_true(metrics.test_metric.duration > 0)
        end)

        it("should clear metrics for a request", function()
            profiling.start_metric(test_request_id, "test_metric")
            vim.loop.sleep(1)
            profiling.end_metric(test_request_id, "test_metric")
            
            profiling.clear_metrics(test_request_id)
            local metrics = profiling.get_metrics(test_request_id)
            
            assert.are.same(metrics, {})
        end)
    end)

    describe("metrics formatting", function()
        it("should format total time only", function()
            local metrics = {
                total = {
                    duration = 100
                }
            }
            
            local formatted = profiling.format_metrics(metrics)
            assert.is_not_nil(formatted:match("Total Time: 100.00 ms"))
            -- Should include estimated breakdowns
            assert.is_not_nil(formatted:match("DNS Resolution: ~5.00 ms %(estimated%)"))
            assert.is_not_nil(formatted:match("Server Processing: ~50.00 ms %(estimated%)"))
        end)

        it("should format all available metrics", function()
            local metrics = {
                total = { duration = 100 },
                dns_resolution = { duration = 5 },
                connection = { duration = 10 },
                tls_handshake = { duration = 15 },
                send_request = { duration = 5 },
                server_processing = { duration = 50 },
                content_transfer = { duration = 15 }
            }
            
            local formatted = profiling.format_metrics(metrics)
            assert.is_not_nil(formatted:match("Total Time: 100.00 ms"))
            assert.is_not_nil(formatted:match("DNS Resolution: 5.00 ms"))
            assert.is_not_nil(formatted:match("TCP Connection: 10.00 ms"))
            assert.is_not_nil(formatted:match("TLS Handshake: 15.00 ms"))
            assert.is_not_nil(formatted:match("Request Sent: 5.00 ms"))
            assert.is_not_nil(formatted:match("Server Processing: 50.00 ms"))
            assert.is_not_nil(formatted:match("Content Transfer: 15.00 ms"))
            -- Shouldn't include estimated values
            assert.is_nil(formatted:match("estimated"))
        end)

        it("should use estimates for missing metrics", function()
            local metrics = {
                total = { duration = 100 },
                dns_resolution = { duration = 5 },
                -- connection missing
                -- tls_handshake missing
                send_request = { duration = 5 },
                -- server_processing missing
                -- content_transfer missing
                url = "https://example.com" -- HTTPS URL
            }
            
            local formatted = profiling.format_metrics(metrics)
            assert.is_not_nil(formatted:match("Total Time: 100.00 ms"))
            assert.is_not_nil(formatted:match("DNS Resolution: 5.00 ms"))
            -- These should be estimates
            assert.is_not_nil(formatted:match("TCP Connection: ~10.00 ms %(estimated%)"))
            assert.is_not_nil(formatted:match("TLS Handshake: ~15.00 ms %(estimated%)"))
            assert.is_not_nil(formatted:match("Request Sent: 5.00 ms"))
            assert.is_not_nil(formatted:match("Server Processing: ~"))
            assert.is_not_nil(formatted:match("Content Transfer: ~"))
        end)
    end)
end) 