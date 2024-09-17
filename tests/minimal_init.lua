vim.cmd [[set runtimepath+=.]]
vim.cmd [[runtime plugin/plenary.vim]]

local plenary_dir = vim.fn.stdpath('data') .. '/site/pack/packer/start/plenary.nvim'
vim.opt.rtp:append(plenary_dir)

-- Add the project root to the Lua path
local project_root = vim.fn.getcwd()
package.path = package.path .. ";" .. project_root .. "/lua/?.lua"

