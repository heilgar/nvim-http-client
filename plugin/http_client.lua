if vim.g.loaded_http_client then
  return
end
vim.g.loaded_http_client = true

local http_client = require("http_client")

http_client.setup()

