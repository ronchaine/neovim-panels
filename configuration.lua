local default_configuration = {
  top = {
    enabled = true,
    format = 'panels',
  },
  bottom = {
    enabled = true,
    format = "",
  },
  enable_cterm_colours = false,
}

local opts = vim.deepcopy(default_configuration)

local M = {}

M.set = function(user_opts)
  opts = vim.tbl_deep_extend("force", opts, user_opts)
end

M.panel_opts = function()
  return opts
end

M.reset = function()
  opts = vim.deepcopy(default_configuration)
end

return M
