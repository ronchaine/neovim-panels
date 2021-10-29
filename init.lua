local config = require('custom.panels.configuration')
local Module = {}

--  symbols = { error = ' ', warn = ' ', info = ' ' },

local diag_symbols = {
    error = ' ',
    warning = ' ',
    info = '🛈 '
}

local mode_symbols = {
    n = '🅝 ',
    i = '🅘 ',
    v = '🅥 ',
    [''] = '🆅 ',
    V = '🅅 ',
    c = '🅒 ',
    no = 'no',
    s = 's',
    S = 'S',
    [''] = 'CTRL-S',
    ic = 'ic',
    R = '🅡 ',
    Rv = 'Rv',
    cv = 'cv',
    ce = 'ce',
    r = 'r',
    rm = 'rm',
    ['r?'] = 'r?',
    ['!'] = '!',
    t = 't',
}

local break_path = function(path)
    path, file, ext = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    return {
        path = path,
        file = file,
        ext = ext,
    }
end

local current_buffer = function()
    return vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
end

local buffer_list = function()
    buffers = {}
    local current_bufno = vim.api.nvim_get_current_buf()
    for _, bufno in ipairs(vim.api.nvim_list_bufs()) do
        table.insert(buffers, {
            name        = vim.api.nvim_buf_get_name(bufno),
            modified    = vim.api.nvim_buf_get_option(bufno, 'modified'),
            readonly    = vim.api.nvim_buf_get_option(bufno, 'readonly'),
            active      = bufno == current_bufno,
        })
    end
    return buffers
end

local buffer_tabs = function()
    tabs = {}
    for _, buf in ipairs(buffer_list()) do
        table.insert(tabs, buf.active and "%#TabLineSel#" or "%#TabLine#")
        table.insert(tabs, break_path(buf.name).file)
    end

    return table.concat(tabs)
end


local cmd_stdout = function(cmd)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()

    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    return s
end

local get_git_root = function(path)
    local out = cmd_stdout([[git -C ]] .. path .. [[ rev-parse --show-toplevel 2>&1 ]])
    if string.sub(out, 1, 1) ~= '/' then
        return nil
    end
    return out
end

local get_git_branch = function(git_root)
    local file = io.open(git_root .. '/.git/HEAD', 'r')
    local data = file:read('*a')
    file:close()

    data = data:match('.*/(.*)$')
    data = data:gsub('%s+$', '')

    return data
end

local get_git_remote = function(git_root, branch)
    local file = io.open(git_root .. '/.git/config', 'r')
    local data = file:read('*a')
    file:close()
    data = data:match([[%[branch "]] .. branch .. [["%][^%[].-remote%s*=%s*([^%s]+)]])

    return data
end

local get_remote_diff = function(git_root)
    return {
        ahead = cmd_stdout([[git -C ]] .. git_root .. [[ rev-list --count @{u}.. 2>&1 ]]),
        behind = cmd_stdout([[git -C ]] .. git_root .. [[ rev-list --count ..@{u} 2>&1 ]]),
    }
end

local git_stats = function()
    local git_root = get_git_root(break_path(current_buffer()).path)
    if not git_root then
        return nil
    end

    local branch = get_git_branch(git_root)
    local remote = get_git_remote(git_root, branch)

    if not remote then
        return ' ' .. branch .. ' [no remote]'
    end

    local rdiff = get_remote_diff(git_root)

    return ' ' .. branch .. ' ↑' .. rdiff.ahead .. ' ↓' .. rdiff.behind
end

local build_panel = function(conf)
    local panel = {}
    -- replace this with actual conf
    if conf.format == 'panels' then
        table.insert(panel, buffer_tabs())
    else
        table.insert(panel, mode_symbols[vim.api.nvim_get_mode().mode])
        table.insert(panel, git_stats())
    end
    return table.concat(panel)
end

Module.panel = function(which)
    if which == 'top' then
        return build_panel(config.panel_opts().top)
    else
        return build_panel(config.panel_opts().bottom)
    end
end

Module.setup = function(user_conf)
    user_conf = user_conf and user_conf or {}
    config.set(user_conf)

    if config.panel_opts().top.enabled then
        vim.go.tabline = "%{%v:lua.require'custom.panels'.panel('top')%}"
        vim.go.showtabline = 2
    end
    
    if config.panel_opts().bottom.enabled then
        vim.go.statusline = "%{%v:lua.require'custom.panels'.panel('bottom')%}"
        vim.go.laststatus= 2
    end
end

return Module
