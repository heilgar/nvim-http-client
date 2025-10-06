local response_handler = require('http_client.core.response_handler')

describe("Response Handler", function()
    describe("headers object", function()
        it("should provide access to headers via direct key access", function()
            local mock_response = {
                headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer token123",
                    ["X-Custom-Header"] = "custom-value"
                },
                status = 200,
                body = {}
            }
            
            local sandbox = response_handler.create_sandbox(mock_response)
            local headers = sandbox.response.headers
            
            assert.equal(headers["Content-Type"], "application/json")
            assert.equal(headers["Authorization"], "Bearer token123")
            assert.equal(headers["X-Custom-Header"], "custom-value")
        end)
        
        it("should provide valueOf method for case-sensitive header lookup", function()
            local mock_response = {
                headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer token123",
                    ["X-Custom-Header"] = "custom-value"
                },
                status = 200,
                body = {}
            }
            
            local sandbox = response_handler.create_sandbox(mock_response)
            local headers = sandbox.response.headers
            
            assert.equal(headers.valueOf("Content-Type"), "application/json")
            assert.equal(headers.valueOf("Authorization"), "Bearer token123")
            assert.equal(headers.valueOf("X-Custom-Header"), "custom-value")
        end)
        
        it("should provide case-insensitive header lookup via valueOf", function()
            local mock_response = {
                headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer token123",
                    ["X-Custom-Header"] = "custom-value"
                },
                status = 200,
                body = {}
            }
            
            local sandbox = response_handler.create_sandbox(mock_response)
            local headers = sandbox.response.headers
            
            -- Test case-insensitive lookup
            assert.equal(headers.valueOf("content-type"), "application/json")
            assert.equal(headers.valueOf("CONTENT-TYPE"), "application/json")
            assert.equal(headers.valueOf("authorization"), "Bearer token123")
            assert.equal(headers.valueOf("AUTHORIZATION"), "Bearer token123")
            assert.equal(headers.valueOf("x-custom-header"), "custom-value")
            assert.equal(headers.valueOf("X-CUSTOM-HEADER"), "custom-value")
        end)
        
        it("should return nil for non-existent headers via valueOf", function()
            local mock_response = {
                headers = {
                    ["Content-Type"] = "application/json"
                },
                status = 200,
                body = {}
            }
            
            local sandbox = response_handler.create_sandbox(mock_response)
            local headers = sandbox.response.headers
            
            assert.is_nil(headers.valueOf("Non-Existent-Header"))
            assert.is_nil(headers.valueOf(""))
            assert.is_nil(headers.valueOf(nil))
        end)
        
        it("should handle empty headers object", function()
            local mock_response = {
                headers = {},
                status = 200,
                body = {}
            }
            
            local sandbox = response_handler.create_sandbox(mock_response)
            local headers = sandbox.response.headers
            
            assert.is_nil(headers.valueOf("Any-Header"))
            assert.equal(type(headers.valueOf), "function")
        end)
        
        it("should handle nil headers", function()
            local mock_response = {
                headers = nil,
                status = 200,
                body = {}
            }
            
            local sandbox = response_handler.create_sandbox(mock_response)
            local headers = sandbox.response.headers
            
            assert.is_nil(headers.valueOf("Any-Header"))
            assert.equal(type(headers.valueOf), "function")
        end)
        
        it("should work with mcp-session-id header as in the example", function()
            local mock_response = {
                headers = {
                    ["mcp-session-id"] = "session-12345",
                    ["Content-Type"] = "application/json"
                },
                status = 200,
                body = {}
            }
            
            local sandbox = response_handler.create_sandbox(mock_response)
            local headers = sandbox.response.headers
            
            assert.equal(headers.valueOf("mcp-session-id"), "session-12345")
            assert.equal(headers.valueOf("MCP-SESSION-ID"), "session-12345")
            assert.equal(headers.valueOf("mcp-session-id"), "session-12345")
        end)
        
        it("should handle headers in array format from plenary.curl", function()
            local mock_response = {
                headers = {
                    "Content-Type: application/json",
                    "Server: nginx/1.18.0",
                    "mcp-session-id: session-12345"
                },
                status = 200,
                body = {}
            }
            
            local sandbox = response_handler.create_sandbox(mock_response)
            local headers = sandbox.response.headers
            
            assert.equal(headers.valueOf("Content-Type"), "application/json")
            assert.equal(headers.valueOf("Server"), "nginx/1.18.0")
            assert.equal(headers.valueOf("mcp-session-id"), "session-12345")
            assert.equal(headers.valueOf("content-type"), "application/json")
            assert.equal(headers.valueOf("server"), "nginx/1.18.0")
        end)
    end)
    
    describe("script execution", function()
        it("should execute a simple script that uses headers.valueOf", function()
            local mock_response = {
                headers = {
                    ["mcp-session-id"] = "session-12345",
                    ["Content-Type"] = "application/json"
                },
                status = 200,
                body = {}
            }
            
            -- Mock the environment module
            local mock_environment = {
                set_global_variable = function(key, value)
                    -- Store in a test variable for verification
                    _G.test_global_vars = _G.test_global_vars or {}
                    _G.test_global_vars[key] = value
                end
            }
            
            -- Mock the verbose module
            local mock_verbose = {
                debug_print = function(msg) end
            }
            
            -- Temporarily replace modules
            local original_env = package.loaded['http_client.core.environment']
            local original_verbose = package.loaded['http_client.utils.verbose']
            
            package.loaded['http_client.core.environment'] = mock_environment
            package.loaded['http_client.utils.verbose'] = mock_verbose
            
            -- Reload the module to use mocked dependencies
            package.loaded['http_client.core.response_handler'] = nil
            local response_handler = require('http_client.core.response_handler')
            
            local script = [[
                client.global.set("session-id", response.headers.valueOf("mcp-session-id"))
            ]]
            
            -- Clear test globals
            _G.test_global_vars = {}
            
            -- Execute the script
            response_handler.execute(script, mock_response)
            
            -- Verify the global variable was set
            assert.equal(_G.test_global_vars["session-id"], "session-12345")
            
            -- Restore original modules
            package.loaded['http_client.core.environment'] = original_env
            package.loaded['http_client.utils.verbose'] = original_verbose
            package.loaded['http_client.core.response_handler'] = nil
        end)
        
        it("should handle script errors gracefully", function()
            local mock_response = {
                headers = { ["Content-Type"] = "application/json" },
                status = 200,
                body = {}
            }
            
            -- Mock the verbose module to capture debug output
            local debug_messages = {}
            local mock_verbose = {
                debug_print = function(msg)
                    table.insert(debug_messages, msg)
                end
            }
            
            -- Temporarily replace modules
            local original_verbose = package.loaded['http_client.utils.verbose']
            package.loaded['http_client.utils.verbose'] = mock_verbose
            
            -- Reload the module
            package.loaded['http_client.core.response_handler'] = nil
            local response_handler = require('http_client.core.response_handler')
            
            local script = [[
                -- This will cause an error
                response.nonExistentMethod()
            ]]
            
            -- Execute the script (should not throw)
            response_handler.execute(script, mock_response)
            
            -- Verify error was logged
            assert.is_true(#debug_messages > 0)
            assert.matches("Error executing response handler script", debug_messages[1])
            
            -- Restore original module
            package.loaded['http_client.utils.verbose'] = original_verbose
            package.loaded['http_client.core.response_handler'] = nil
        end)
    end)
end)
