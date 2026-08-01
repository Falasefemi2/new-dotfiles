vim.pack.add { 'https://github.com/nvimdev/dashboard-nvim' }

local logo = {
  [[                                                          ]],
  [[  ███████╗███████╗███╗   ███╗███╗   ███╗██╗███████╗     ]],
  [[  ██╔════╝██╔════╝████╗ ████║████╗ ████║██║██╔════╝     ]],
  [[  █████╗  █████╗  ██╔████╔██║██╔████╔██║██║█████╗       ]],
  [[  ██╔══╝  ██╔══╝  ██║╚██╔╝██║██║╚██╔╝██║██║██╔══╝       ]],
  [[  ██║     ███████╗██║ ╚═╝ ██║██║ ╚═╝ ██║██║███████╗     ]],
  [[  ╚═╝     ╚══════╝╚═╝     ╚═╝╚═╝     ╚═╝╚═╝╚══════╝     ]],
  [[                                                          ]],
}

require('dashboard').setup {
  theme = 'doom',
  config = {
    header = logo,
    center = {
      {
        icon = '󰈞  ',
        desc = 'Find File                           ',
        key = 'f',
        action = 'Telescope find_files',
      },
      {
        icon = '󰊄  ',
        desc = 'Live Grep                           ',
        key = 'g',
        action = 'Telescope live_grep',
      },
      {
        icon = '󰋚  ',
        desc = 'Recent Files                        ',
        key = 'r',
        action = 'Telescope oldfiles',
      },
      {
        icon = '󰒓  ',
        desc = 'Config                              ',
        key = 'c',
        action = 'Telescope find_files cwd=' .. vim.fn.stdpath 'config',
      },
      {
        icon = '󰒲  ',
        desc = 'Update Plugins                      ',
        key = 'u',
        action = 'lua vim.pack.update()',
      },
      {
        icon = '󰗼  ',
        desc = 'Quit                                ',
        key = 'q',
        action = 'qa',
      },
    },
    footer = {
      '',
      '⚡ Neovim initialized for FEMMIE',
    },
  },
}
