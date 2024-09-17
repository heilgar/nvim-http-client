local M = require('http_client')

describe('HTTP Client init', function()
    before_each(function()
        -- Reset M to a clean state before each test
        package.loaded['http_client.config'] = nil
        package.loaded['http_client.core.environment'] = nil
        package.loaded['http_client.utils.file_utils'] = nil
        package.loaded['http_client.core.http_client'] = nil
        package.loaded['http_client.core.parser'] = nil
        package.loaded['http_client.ui.display'] = nil
        package.loaded['http_client.ui.dry_run'] = nil
        package.loaded['http_client.utils.verbose'] = nil
        package.loaded['http_client.commands'] = nil
        package.loaded['http_client.health'] = nil

        M = require('http_client') -- Re-import after clearing cache
    end)

    describe('setup', function()
        it('should load all necessary modules', function()
            -- Mock the required modules
            local mock_modules = {
                environment = {},
                file_utils = {},
                http_client = {},
                parser = {},
                ui = {},
                dry_run = {},
                v = {},
                commands = {},
                health = {
                    register = function() end,
                    check = function() end
                }
            }

            for key, mock in pairs(mock_modules) do
                package.loaded['http_client.' .. key] = mock
            end

            M.setup()

            assert.is_not_nil(M.environment)
            assert.is_not_nil(M.file_utils)
            assert.is_not_nil(M.http_client)
            assert.is_not_nil(M.parser)
            assert.is_not_nil(M.ui)
            assert.is_not_nil(M.dry_run)
            assert.is_not_nil(M.v)
            assert.is_not_nil(M.commands)
            assert.is_not_nil(M.health)
        end)
    end)
end)

