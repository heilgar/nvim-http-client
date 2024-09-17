local file_utils = require('http_client.utils.file_utils')

describe("file_utils", function()
    local test_dir = "test_dir"

    before_each(function()
        -- Create a test directory structure
        vim.fn.mkdir(test_dir, "p")
        vim.fn.mkdir(test_dir .. "/subdir", "p")

        local function create_file(name, content)
            vim.fn.writefile({ content }, test_dir .. "/" .. name)
        end

        create_file("test1.json", '{"key": "value1"}')
        create_file("test2.json", '{"key": "value2"}')
        create_file("test.private.json", '{"key": "private"}')
        create_file("subdir/test3.json", '{"key": "value3"}')
    end)

    after_each(function()
        -- Clean up the test directory
        vim.fn.delete(test_dir, "rf")
    end)

    describe("find_files", function()
        it("should find all JSON files except private ones", function()
            local files = file_utils.find_files("*.json")
            table.sort(files)
            assert.are.same({
                "examples/.env.json",
                "test_dir/subdir/test3.json",
                "test_dir/test1.json",
                "test_dir/test2.json"
            }, files)
        end)

        it("should not include private files", function()
            local files = file_utils.find_files("*.json")
            for _, file in ipairs(files) do
                assert.is_nil(file:match("%.private%."))
            end
        end)
    end)

    describe("read_json_file", function()
        it("should correctly read and parse a JSON file", function()
            local content = file_utils.read_json_file(test_dir .. "/test1.json")
            assert.are.same({ key = "value1" }, content)
        end)

        it("should return nil for non-existent files", function()
            local content = file_utils.read_json_file(test_dir .. "/non_existent.json")
            assert.is_nil(content)
        end)

        it("should return nil for invalid JSON", function()
            vim.fn.writefile({ "{invalid json" }, test_dir .. "/invalid.json")
            local content = file_utils.read_json_file(test_dir .. "/invalid.json")
            assert.is_nil(content)
        end)
    end)
end)

