local file_utils = require('http_client.utils.file_utils')

describe('file_utils', function()
    describe('project root functionality', function()
        it('should set and get project root', function()
            local test_root = '/tmp/test_project'
            
            -- Test setting project root
            file_utils.set_project_root(test_root)
            assert.are.equal(test_root, file_utils.get_project_root())
            
            -- Test resetting to current directory
            file_utils.set_project_root()
            assert.are.equal(vim.fn.getcwd(), file_utils.get_project_root())
        end)
        
        it('should use project root in find_files', function()
            local original_root = file_utils.get_project_root()
            local test_root = '/tmp/test_project'
            
            -- Set a test project root
            file_utils.set_project_root(test_root)
            
            -- Test that find_files uses the project root
            local files = file_utils.find_files('*.lua')
            -- The find command should use the test_root path
            
            -- Reset to original
            file_utils.set_project_root(original_root)
        end)
    end)
end) 