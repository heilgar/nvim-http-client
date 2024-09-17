local health = require("http_client.health")
local stub = require("luassert.stub")

describe("http_client health checks", function()
    local health_start, health_ok, health_warn, health_error

    before_each(function()
        health_start = stub(vim.health or require("health"), "start")
        health_ok = stub(vim.health or require("health"), "ok")
        health_warn = stub(vim.health or require("health"), "warn")
        health_error = stub(vim.health or require("health"), "error")
    end)

    after_each(function()
        health_start:revert()
        health_ok:revert()
        health_warn:revert()
        health_error:revert()
    end)

    it("starts the health check", function()
        health.check()
        assert.stub(health_start).was_called_with("http_client")
    end)

    it("checks for plenary.nvim", function()
        stub(_G, "pcall")
        _G.pcall.on_call_with(require, "plenary").returns(true)

        health.check()

        assert.stub(health_ok).was_called_with("plenary.nvim is installed")
        _G.pcall:revert()
    end)

    it("reports error if plenary.nvim is not installed", function()
        stub(_G, "pcall")
        _G.pcall.on_call_with(require, "plenary").returns(false)

        health.check()

        assert.stub(health_error).was_called_with("plenary.nvim is not installed", "Install plenary.nvim")
        _G.pcall:revert()
    end)

  end)

