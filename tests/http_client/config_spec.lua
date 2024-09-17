local config = require('http_client.config')

describe("Config", function()
    before_each(function()
        config.setup(nil)
    end)

    describe('setup', function()
        it('should set default options when no argumennts are passed', function()
            config.setup()
            assert.are.same(config.defaults, config.options)
        end)

        it('should set non-default option', function()
            config.setup({foo = 'bar'})
            assert.are.equal(config.get('foo'), "bar")
        end)
    end)

    describe('get', function()
        it('should return the correct option value', function()
            config.setup()
            assert.are.equal(config.get('default_env_file'), config.defaults.default_env_file)
            assert.are.equal(config.get('request_timeout'), config.defaults.request_timeout)
        end)

        it('should return nil for non-existent options', function()
            config.setup()
            assert.is_nil(config.get('non_existent_option'))
        end)
    end)
end)

