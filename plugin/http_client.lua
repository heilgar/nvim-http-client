if vim.g.loaded_http_client then
	return
end
vim.g.loaded_http_client = true

-- WARN: Commenting out because it ommits user configuration provided in the setup function when manually running setup({opts})
-- local http_client = require("http_client")
-- http_client.setup()
