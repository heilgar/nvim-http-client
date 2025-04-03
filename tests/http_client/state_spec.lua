local state = require('http_client.state')

describe("State", function()
    before_each(function()
        -- Reset the state before each test
        state.clear_responses()
    end)

    describe("response handling", function()
        it("should store and retrieve the current response", function()
            local sample_response = { status = 200, body = "test" }
            state.store_response(sample_response)
            
            local current = state.get_current_response()
            assert.are.same(current, sample_response)
        end)

        it("should store responses in history", function()
            local response1 = { status = 200, body = "test1" }
            local response2 = { status = 404, body = "test2" }
            
            state.store_response(response1)
            state.store_response(response2)
            
            local responses = state.get_responses()
            assert.equal(#responses, 2)
            -- Most recent response should be first
            assert.are.same(responses[1], response2)
            assert.are.same(responses[2], response1)
        end)

        it("should limit history to max_responses", function()
            -- Set max responses to 3
            state.set_max_responses(3)
            
            -- Store 5 responses
            for i = 1, 5 do
                state.store_response({ status = 200, body = "test" .. i })
            end
            
            local responses = state.get_responses()
            assert.equal(#responses, 3)
            -- Should contain the 3 most recent responses (3, 4, 5)
            assert.equal(responses[1].body, "test5")
            assert.equal(responses[2].body, "test4")
            assert.equal(responses[3].body, "test3")
        end)

        it("should get response by index", function()
            state.store_response({ status = 200, body = "test1" })
            state.store_response({ status = 404, body = "test2" })
            
            local response = state.get_response(2)
            assert.are.same(response, { status = 200, body = "test1" })
        end)
    end)

    describe("metrics handling", function()
        it("should store timing metrics with response", function()
            local sample_response = { 
                status = 200, 
                body = "test",
                request_id = "test-123"
            }
            
            state.store_response(sample_response)
            
            local sample_metrics = {
                total = { duration = 100 },
                dns_resolution = { duration = 5 }
            }
            
            state.store_metrics("test-123", sample_metrics)
            
            local current = state.get_current_response()
            assert.are.same(current.timing_metrics, sample_metrics)
        end)

        it("should retrieve timing metrics for current response", function()
            local sample_response = { 
                status = 200, 
                body = "test",
                request_id = "test-123",
                timing_metrics = {
                    total = { duration = 100 }
                }
            }
            
            state.store_response(sample_response)
            
            local metrics = state.get_metrics()
            assert.are.same(metrics, { total = { duration = 100 } })
        end)

        it("should update metrics in history", function()
            local response = { 
                status = 200, 
                body = "test",
                request_id = "test-123"
            }
            
            state.store_response(response)
            
            local metrics = {
                total = { duration = 100 }
            }
            
            state.store_metrics("test-123", metrics)
            
            local responses = state.get_responses()
            assert.are.same(responses[1].timing_metrics, metrics)
        end)

        it("should return nil when no current response", function()
            state.clear_responses()
            local metrics = state.get_metrics()
            assert.is_nil(metrics)
        end)
    end)
end) 