local verbose = require('http_client.utils.verbose')

describe("verbose", function()
    before_each(function()
        -- Reset the global state before each test
        _G.http_verbose_mode = false
    end)

    describe("set_verbose_mode", function()
        it("should set verbose mode to true", function()
            verbose.set_verbose_mode(true)
            assert.is_true(_G.http_verbose_mode)
        end)

        it("should set verbose mode to false", function()
            verbose.set_verbose_mode(false)
            assert.is_false(_G.http_verbose_mode)
        end)
    end)

    describe("get_verbose_mode", function()
        it("should return the current verbose mode state", function()
            _G.http_verbose_mode = true
            assert.is_true(verbose.get_verbose_mode())

            _G.http_verbose_mode = false
            assert.is_false(verbose.get_verbose_mode())
        end)
    end)

    describe("debug_print", function()
        it("should print debug messages when verbose mode is enabled", function()
            verbose.set_verbose_mode(true)

            local original_print = _G.print
            local printed_message = nil
            _G.print = function(msg)
                printed_message = msg
            end

            verbose.debug_print("Test message")
            assert.are.equal("[HTTP Client Debug] Test message", printed_message)

            _G.print = original_print
        end)

        it("should not print debug messages when verbose mode is disabled", function()
            verbose.set_verbose_mode(false)

            local original_print = _G.print
            local print_called = false
            _G.print = function(msg)
                print_called = true
            end

            verbose.debug_print("Test message")
            assert.is_false(print_called)

            _G.print = original_print
        end)
    end)
end)

