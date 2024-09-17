local parser = require('http_client.core.parser')
local environment = require('http_client.core.environment')

describe("Parser", function()
    before_each(function()
        -- Clear buffer content and global state before each test
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
    end)

    describe("get_request_under_cursor", function()
        it("should correctly identify and return the request under the cursor", function()
            -- Setup buffer content
            local buffer_content = {
                "### Test 1",
                "GET /test1 HTTP/1.1",
                "Header1: Value1",
                "",
                "Body1",
                "### Test 2",
                "POST /test2 HTTP/1.1",
                "Header2: Value2",
                "",
                "Body2"
            }
            vim.api.nvim_buf_set_lines(0, 0, -1, false, buffer_content)
            vim.api.nvim_win_set_cursor(0, { 2, 0 }) -- Cursor on the first request

            local request = parser.get_request_under_cursor()
            assert.is_not_nil(request)
            assert.are.equal(request.method, "GET")
            assert.are.equal(request.url, "/test1")
            assert.are.equal(request.body, nil)
        end)

        it("should handle cases where cursor is on line before separator", function()
            local buffer_content = {
                "### Test 1",
                "GET /test1 HTTP/1.1",
                "",
                "### Test 2",
                "POST /test2 HTTP/1.1",
                ""
            }
            vim.api.nvim_buf_set_lines(0, 0, -1, false, buffer_content)
            vim.api.nvim_win_set_cursor(0, { 3, 0 }) -- Cursor on the empty line after first request

            local request = parser.get_request_under_cursor()
            assert.is_not_nil(request)
            assert.are.equal(request.method, "GET") -- Expect the next request
            assert.are.equal(request.url, "/test1")
        end)

        it("should handle cases where cursor is directly on a separator", function()
            local buffer_content = {
                "### Test 1",
                "GET /test1 HTTP/1.1",
                "",
                "### Test 2",
                "POST /test2 HTTP/1.1",
                ""
            }
            vim.api.nvim_buf_set_lines(0, 0, -1, false, buffer_content)
            vim.api.nvim_win_set_cursor(0, { 4, 0 }) -- Cursor on the "### Test 2" line
            local request = parser.get_request_under_cursor()
            assert.is_not_nil(request)
            assert.are.equal(request.method, "POST")
            assert.are.equal(request.url, "/test2")
            assert.are.equal(request.test_name, "Test 2")
        end)

        it("should return an empty request if there are no requests", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
            local request = parser.get_request_under_cursor()
            assert.is_not_nil(request)
            assert.are.same(request, { headers = {}, test_name = '' })
        end)
    end)

    describe("parse_request", function()
        it("should correctly parse a request from lines", function()
            local lines = {
                "GET /test HTTP/1.1",
                "Header1: Value1",
                "Header2: Value2",
                "",
                "Body"
            }

            local request = parser.parse_request(lines)
            assert.are.equal(request.method, "GET")
            assert.are.equal(request.url, "/test")
            assert.are.equal(request.http_version, "HTTP/1.1")
            assert.are.same(request.headers, { Header1 = "Value1", Header2 = "Value2" })
            assert.are.equal(request.body, nil)
        end)

        it("should parse a basic GET request", function()
            local lines = {
                "GET https://api.example.com/users HTTP/1.1",
                "Host: api.example.com",
                "User-Agent: TestClient/1.0",
                ""
            }
            local request = parser.parse_request(lines)
            assert.are.same({
                method = "GET",
                url = "https://api.example.com/users",
                headers = {
                    ["Host"] = "api.example.com",
                    ["User-Agent"] = "TestClient/1.0"
                },
                body = nil,
                http_version = "HTTP/1.1"
            }, request)
        end)

        it("should parse a POST request with body", function()
            local lines = {
                "POST https://api.example.com/users HTTP/1.1",
                "Host: api.example.com",
                "Content-Type: application/json",
                "",
                '{"name": "John Doe", "email": "john@example.com"}'
            }
            local request = parser.parse_request(lines)
            assert.are.same({
                method = "POST",
                url = "https://api.example.com/users",
                headers = {
                    ["Host"] = "api.example.com",
                    ["Content-Type"] = "application/json"
                },
                body = '{"name": "John Doe", "email": "john@example.com"}',
                http_version = "HTTP/1.1"
            }, request)
        end)

        it("should parse a request without HTTP version", function()
            local lines = {
                "GET https://api.example.com/users",
                "Host: api.example.com",
                ""
            }
            local request = parser.parse_request(lines)
            assert.are.same({
                method = "GET",
                url = "https://api.example.com/users",
                headers = {
                    ["Host"] = "api.example.com"
                },
                body = nil,
                http_version = "HTTP/1.1" -- Default version
            }, request)
        end)

        it("should parse a request with response handler", function()
            local lines = {
                "GET https://api.example.com/users HTTP/1.1",
                "Host: api.example.com",
                "",
                "> {% ",
                "print(response.body)",
                "%}"
            }
            local request = parser.parse_request(lines)
            assert.are.same({
                method = "GET",
                url = "https://api.example.com/users",
                headers = {
                    ["Host"] = "api.example.com"
                },
                body = nil,
                http_version = "HTTP/1.1",
                response_handler = "print(response.body)\n"
            }, request)
        end)

        it("should handle a GET request with query parameters", function()
            local lines = {
                "GET /api/users?page=1&limit=10 HTTP/1.1",
                "Host: example.com",
                ""
            }
            local request = parser.parse_request(lines)
            assert.are.same({
                method = "GET",
                url = "/api/users?page=1&limit=10",
                http_version = "HTTP/1.1",
                headers = {
                    Host = "example.com"
                },
                body = nil
            }, request)
        end)

        it("should handle comment on header line", function()
            local lines = {
                "GET https://test.com/",
                "User-Agent: heilgar/http-client",
                "#X-Not-in: false"
            }

            local request = parser.parse_request(lines)
            assert.are.equal(request.headers['#X-Not-in'], nil)
        end)
    end)

    describe("parse_all_requests", function()
        it("should parse multiple requests correctly", function()
            local lines = {
                "### Test 1",
                "GET /test1 HTTP/1.1",
                "Header1: Value1",
                "",
                "Body1",
                "### Test 2",
                "POST /test2 HTTP/1.1",
                "Header2: Value2",
                "",
                "Body2"
            }

            local requests = parser.parse_all_requests(lines)
            assert.are.equal(#requests, 2)
            assert.are.equal(requests[1].method, "GET")
            assert.are.equal(requests[1].url, "/test1")
            assert.are.equal(requests[2].method, "POST")
            assert.are.equal(requests[2].url, "/test2")
        end)

        it("should parse multiple requests correctly with comments", function()
            local lines = {
                "### Test 1",
                "# This is a comment",
                "GET /test1 HTTP/1.1",
                "Header1: Value1 # Inline comment",
                "",
                "Body1",
                "### Test 2",
                "POST /test2 HTTP/1.1 # Another comment",
                "Header2: Value2",
                "",
                "Body2 # Not a comment in body"
            }

            local requests = parser.parse_all_requests(lines)
            assert.are.equal(#requests, 2)
            assert.are.equal(requests[1].method, "GET")
            assert.are.equal(requests[1].url, "/test1")
            assert.are.equal(requests[1].headers["Header1"], "Value1")
            assert.are.equal(requests[2].method, "POST")
            assert.are.equal(requests[2].url, "/test2")
            assert.are.equal(requests[2].body, "Body2")
        end)

        it("should handle requests with mixed inline comments and empty lines", function()
            local lines = {
                "### Request 1",
                "GET /resource1 HTTP/1.1",          -- Request line
                "# This is a comment",
                "Header1: Value1 # Inline comment", -- Header with inline comment
                "",                                 -- Empty line
                "Body1 # Comment in body",          -- Body with comment
                "### Request 2",
                "POST /resource2 HTTP/1.1",
                "Header2: Value2",
                "Header3: Value3 # Another inline comment",
                "",              -- Empty line
                "Body2",         -- Body without comments
                "",              -- Extra empty line
                "### Request 3", -- Third request
                "",
                "# Another comment",
                "PUT /resource3 HTTP/1.1",
                "",     -- Empty line, no headers
                "Body3" -- Body without comments
            }

            local requests = parser.parse_all_requests(lines)

            assert.are.equal(#requests, 3)

            assert.are.equal(requests[1].method, "GET")
            assert.are.equal(requests[1].url, "/resource1")
            assert.are.equal(requests[1].headers["Header1"], "Value1")
            assert.are.equal(requests[1].body, nil)

            assert.are.equal(requests[2].method, "POST")
            assert.are.equal(requests[2].url, "/resource2")
            assert.are.equal(requests[2].headers["Header2"], "Value2")
            assert.are.equal(requests[2].headers["Header3"], "Value3")
            assert.are.equal(requests[2].body, "Body2")

            assert.are.equal(requests[3].method, "PUT")
            assert.are.equal(requests[3].url, "/resource3")
            assert.is_nil(requests[3].headers["Header2"]) -- No headers
            assert.are.equal(requests[3].body, "Body3")
        end)
    end)

    describe("replace_placeholders", function()
        it("should replace placeholders with environment variables", function()
            local env = {
                TEST_URL = "http://example.com"
            }
            local request = {
                url = "{{TEST_URL}}/path",
                headers = { Host = "{{TEST_URL}}" },
                body = "Body with {{TEST_URL}}"
            }

            local replaced_request = parser.replace_placeholders(request, env)
            assert.are.equal(replaced_request.url, "http://example.com/path")
            assert.are.equal(replaced_request.headers.Host, "http://example.com")
            assert.are.equal(replaced_request.body, "Body with http://example.com")
        end)
    end)
end)

