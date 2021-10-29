local config = require('custom.panels.configuration')
local Module = {}

local diag_symbols = {
    error       = ' ',
    warning     = ' ',
    info        = '🛈 ',
    hint        = ' ',
}

local colours = {
    neutral = '#2fafee',
    panel_background_a = '#604060',
    panel_background_b = '#202c50',
    panel_background_c = '#101c4a',
    panel_background_dark = '#201040',
    panel_background_e = '#ffffc0',
    panel_background_f = '#0000ff',
}

local highlight_table = {
    PanelTabActive          = { fg = '#ffffd0', bg = '#604288' },
    PanelTabInactive        = { fg = '#604288', bg = '#000000' },

    PanelNeutralA           = { fg = colours.neutral, bg = colours.panel_background_a },

    PanelNormalMode         = { fg = '#ffff00', bg = colours.panel_background_a },
    PanelInsertMode         = { fg = '#a0a0ff', bg = colours.panel_background_a },
    PanelVisualMode         = { fg = '#ffa000', bg = colours.panel_background_a },
    PanelCommandMode        = { fg = '#55ff55', bg = colours.panel_background_a },
    PanelOtherMode          = { fg = '#a000a0', bg = colours.panel_background_a },

    PanelNeutralB           = { fg = colours.neutral, bg = colours.panel_background_b },
    PanelGitBranch          = { fg = colours.neutral, bg = colours.panel_background_b },
    PanelGitMasterBranch    = { fg = '#ff0000', bg = colours.panel_background_b },
    PanelGitAhead           = { fg = '#55ff55', bg = colours.panel_background_b },
    PanelGitBehind          = { fg = '#ff6060', bg = colours.panel_background_b },

    PanelDark               = { fg = '#a0a0a0', bg = colours.panel_background_dark },

    PanelLSPError           = { fg = '#a00000', bg = colours.panel_background_c },
    PanelLSPWarning         = { fg = '#ffa000', bg = colours.panel_background_c },
    PanelLSPInfo            = { fg = '#20c0ff', bg = colours.panel_background_c },
    
    PanelActiveTabError     = { fg = '#ff0000', bg = '#604288' },
    PanelActiveTabWarning   = { fg = '#ffa000', bg = '#604288' },
    PanelActiveTabInfo      = { fg = '#20c0ff', bg = '#604288' },
    
    PanelInactiveTabError     = { fg = '#a00000', bg = '#000000' },
    PanelInactiveTabWarning   = { fg = '#ffa000', bg = '#000000' },
    PanelInactiveTabInfo      = { fg = '#20c0ff', bg = '#000000' },

    PanelFileSymbol         = { fg = colours.neutral, bg = colours.panel_background_f },
    PanelFileInfoOK         = { fg = '#c0ffc0', bg = colours.panel_background_f },
    PanelFileInfoWarn       = { fg = '#ff0000', bg = colours.panel_background_f },

    PanelCursorLoc          = { fg = '#000000', bg = colours.panel_background_e },

    PanelTransitionAB       = { fg = colours.panel_background_a, bg = colours.panel_background_b },
    PanelTransitionBC       = { fg = colours.panel_background_b, bg = colours.panel_background_c },
    PanelTransitionCD       = { fg = colours.panel_background_c, bg = colours.panel_background_dark },
    PanelTransitionBE       = { fg = colours.panel_background_b, bg = colours.panel_background_e },
    PanelTransitionEB       = { fg = colours.panel_background_e, bg = colours.panel_background_b },
    PanelTransitionEF       = { fg = colours.panel_background_e, bg = colours.panel_background_f },
    PanelTransitionFD       = { fg = colours.panel_background_f, bg = colours.panel_background_dark },
    TestHL                  = { fg = '#ff0000', bg = '#0000ff' },
}

local highlights = {
    mode = {
        n       = 'PanelNormalMode',
        i       = 'PanelInsertMode',
        v       = 'PanelVisualMode',
        ['']  = 'PanelVisualMode',
        V       = 'PanelVisualMode',
        c       = 'PanelCommandMode',
        no      = 'PanelOtherMode',
        s       = 'PanelOtherMode',
        S       = 'PanelOtherMode',
        ['']  = 'PanelOtherMode',
        ic      = 'PanelOtherMode',
        R       = 'PanelReplaceMode',
        Rv      = 'PanelReplaceMode',
        cv      = 'PanelCommandMode',
        ce      = 'PanelCommandMode',
        r       = 'PanelReplaceMode',
        rm      = 'PanelReplaceMode',
        ['r?']  = 'PanelReplaceMode',
        ['!']   = 'PanelOtherMode',
        t       = 'PanelOtherMode',
    },
    git = {
    },
    tabs = {
    }
}

local mode_symbols = {
    n           = '🅝 ',
    i           = '🅘 ',
    v           = '🅥 ',
    ['']      = '🆅 ',
    V           = '🅅 ',
    c           = '🅒 ',
    no          = 'no',
    s           = 's',
    S           = 'S',
    ['']      = 'CTRL-S',
    ic          = 'ic',
    R           = '🅡 ',
    Rv          = 'Rv',
    cv          = 'cv',
    ce          = 'ce',
    r           = 'r',
    rm          = 'rm',
    ['r?']      = 'r?',
    ['!']       = '!',
    t           = 't',
}

local file_symbols = {
    modified    = '+',
    readonly    = '',
}

local define_hl = function(name, fg, bg, mod)
    if mod then
        vim.cmd(string.format("hi %s guifg=%s guibg=% gui=%s", name, fg, bg, mod))
    else
        vim.cmd(string.format("hi %s guifg=%s guibg=%s", name, fg, bg))
    end
end

local cprint = function(hl, text)
    return string.format("%%#%s#%s%%*", hl, text)
end

local break_path = function(path)
    local path, file, ext = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    return {
        path = path,
        file = file,
        ext = ext,
    }
end

local current_buffer = function()
    return vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
end

local is_interesting = function(bufno)
    return vim.api.nvim_buf_get_option(bufno, 'buflisted') and vim.api.nvim_buf_get_name(bufno) ~= ""
end

local buffer_list = function()
    local buffers = {}
    local current_bufno = vim.api.nvim_get_current_buf()
    for _, bufno in ipairs(vim.api.nvim_list_bufs()) do
        if is_interesting(bufno) then
          table.insert(buffers, {
              bufno       = bufno,
              name        = vim.api.nvim_buf_get_name(bufno),
              modified    = vim.api.nvim_buf_get_option(bufno, 'modified'),
              readonly    = vim.api.nvim_buf_get_option(bufno, 'readonly'),
              active      = bufno == current_bufno,
          })
        end
    end
    return buffers
end

local tab_diag = function(bufno, active)
    local diagnosis = {}
    local tab = {}
    local levels = {
        errors      = 'Error',
        warnings    = 'Warning',
        info        = 'Information',
        hints       = 'Hint',
    }

    for k, level in pairs(levels) do
        diagnosis[k] = vim.lsp.diagnostic.get_count(bufno, level)
    end

    local prefix = 'Panel'
    if active then
        prefix = prefix .. 'ActiveTab'
    else
        prefix = prefix .. 'InactiveTab'
    end

    if diagnosis['errors'] > 0 then
        return cprint(prefix .. 'Error', diag_symbols.error)
    end

    if diagnosis['warnings'] > 0 then
        return cprint(prefix .. 'Warning', diag_symbols.warning)
    end

    if diagnosis['info'] > 0 then
        return cprint(prefix .. 'Info', diag_symbols.info)
    end

    if diagnosis['info'] > 0 then
        return cprint(prefix .. 'Hint', diag_symbols.hint)
    end

    return nil
end

local buffer_tabs = function()
    local tabs = {}
    local separators_active = { left = '', right = '' }
    local separators_inactive = { left = '', right = '' }
    for _, buf in ipairs(buffer_list()) do
        table.insert(tabs, cprint('PanelTabInactive', buf.active and separators_active.left or separators_inactive.left))
        table.insert(tabs, tab_diag(buf.bufno, buf.active))
        table.insert(tabs, buf.active and "%#PanelTabActive#" or "%#PanelTabInactive#")
        if buf.readonly then
            table.insert(tabs, file_symbols.readonly)
        end
        table.insert(tabs, break_path(buf.name).file)
        if buf.modified then
            table.insert(tabs, file_symbols.modified)
        end
        table.insert(tabs, cprint('PanelTabInactive', buf.active and separators_active.right or separators_inactive.right))
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

local style_branch = function(branch)
    if branch == 'master' or branch == 'main' then
        return cprint('PanelGitMasterBranch', branch)
    end
    return cprint('PanelGitBranch', branch)
end

local git_stats = function()
    local git_root = get_git_root(break_path(current_buffer()).path)
    if not git_root then
        return nil
    end
    local parts = {}
    local branch = get_git_branch(git_root)
    local remote = get_git_remote(git_root, branch)

    table.insert(parts, cprint('PanelNeutralB', '  '))
    table.insert(parts, style_branch(branch) .. cprint('PanelNeutralB', ' '))

    if not remote then
        table.insert(parts, cprint('PanelNeutralB', '[no remote] '))
    else
        local rdiff = get_remote_diff(git_root)
        local ahead_col = tonumber(rdiff.ahead) > 0 and 'PanelGitAhead' or 'PanelNeutralB'
        local behind_col = tonumber(rdiff.behind) > 0 and 'PanelGitAhead' or 'PanelNeutralB'
        table.insert(parts, cprint(ahead_col, '↑' .. rdiff.ahead) .. cprint(behind_col, ' ↓' .. rdiff.behind .. ' '))
    end

    return table.concat(parts)
end

local lsp_stats = function()
    local diagnosis = {}
    local tab = {}
    local levels = {
        errors      = 'Error',
        warnings    = 'Warning',
        info        = 'Information',
        hints       = 'Hint',
    }

    for k, level in pairs(levels) do
        diagnosis[k] = vim.lsp.diagnostic.get_count(0, level)
    end

    if diagnosis['errors'] > 0 then
        table.insert(tab, cprint('PanelLSPError', diag_symbols.error .. diagnosis['errors'] .. ' '))
    end

    if diagnosis['warnings'] > 0 then
        table.insert(tab, cprint('PanelLSPWarning', diag_symbols.warning .. diagnosis['warnings'] .. ' '))
    end

    if diagnosis['info'] > 0 then
        table.insert(tab, cprint('PanelLSPInfo', diag_symbols.info .. diagnosis['info'] .. ' '))
    end

    if diagnosis['info'] > 0 then
        table.insert(tab, cprint('PanelLSPHint', diag_symbols.hint .. diagnosis['hints'] .. ' '))
    end

    return table.concat(tab)
end

-- mode
local mode_indicator = function()
    local tab = {}
    table.insert(tab, cprint(highlights.mode[vim.api.nvim_get_mode().mode], ' ' ..  mode_symbols[vim.api.nvim_get_mode().mode]))
    return table.concat(tab)
end

-- straight from galaxyline
local get_file_icon = function()
  local icon = ''
  if vim.fn.exists("*WebDevIconsGetFileTypeSymbol") == 1 then
    icon = vim.fn.WebDevIconsGetFileTypeSymbol()
    return icon .. ' '
  end
--  local ok,devicons = pcall(require,'nvim-web-devicons')
--  if not ok then print('No icon plugin found. Please install \'kyazdani42/nvim-web-devicons\'') return '' end
--  local f_name,f_extension = get_file_info()
--  icon = devicons.get_icon(f_name,f_extension)
--  if icon == nil then
--    if user_icons[vim.bo.filetype] ~= nil then
--      icon = user_icons[vim.bo.filetype][2]
--    elseif user_icons[f_extension] ~= nil then
--      icon = user_icons[f_extension][2]
--    else
--      icon = ''
--    end
--  end
--  return icon .. ' '
end

local cfiletype = function()
    local filetype = vim.bo.filetype
    local icon = get_file_icon()
    if icon == ' ' then
      return vim.bo.filetype
    end
    return get_file_icon()
end

local filetraits = function()
    local parts = {}
    if vim.o.fileencoding ~= 'utf-8' then
        table.insert(parts, cprint('PanelFileInfoWarn', vim.o.fileencoding))
    else
        table.insert(parts, cprint('PanelFileInfoOK', vim.o.fileencoding))
    end
    if vim.o.ff ~= 'unix' then
        table.insert(parts, cprint('PanelFileInfoWarn', vim.o.ff))
    else
        table.insert(parts, cprint('PanelFileInfoOK', '[' .. vim.o.ff .. '] '))
    end
    return table.concat(parts)
end

local cursor_loc = function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lines_total = vim.fn.line('$')
    local percentage = string.format("%2d", row / lines_total * 100)

    return percentage .. '%% %l/' .. lines_total .. ':%c'
end

-- Panel setups
local build_panel = function(conf)
    local panel = {}

    local separators = { left = '', right = '' }
    if not highlights_defined then
        for hl, values in pairs(highlight_table) do
            if vim.fn.hlexists(hl) == 0 then
                define_hl(hl, values.fg, values.bg, values.fx)
            end
        end
        highlights_defined = true
    end

    -- replace this with actual conf
    if conf.format == 'panels' then
        table.insert(panel, buffer_tabs())
        table.insert(panel, cprint('TabLine', "%="))
    else
        table.insert(panel, mode_indicator())
        table.insert(panel, cprint('PanelTransitionAB', separators.left))
        table.insert(panel, git_stats())
        table.insert(panel, cprint('PanelTransitionBC', separators.left))
        table.insert(panel, lsp_stats())
        --
        table.insert(panel, cprint('PanelDark', "%="))
        --
        table.insert(panel, cprint('PanelTransitionFD', separators.right))
        table.insert(panel, cprint('PanelFileSymbol', cfiletype()))
        table.insert(panel, filetraits())
        --
        table.insert(panel, cprint('PanelTransitionEF', separators.right))
        table.insert(panel, cprint('PanelCursorLoc', cursor_loc() .. ' '))

-- e0xx
--      
--      0123456789 
--             
--      a b c d e f
--
--            c0, c1
--            c2, c3
--                            
--        

    end
    return table.concat(panel)
end

-- Just a small convenience proxy fun
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
