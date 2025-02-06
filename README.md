# Yet Another Neovim Git Client

| <!-- -->     | <!-- -->                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Build Status | [![unittests](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/test.yml?branch=main&style=for-the-badge&label=Unittests)](https://github.com/ColinKennedy/ever.nvim/actions/workflows/test.yml)  [![documentation](https://img.shields.io/github/actions/workflow/status/ColinKennedy/ever.nvim/documentation.yml?branch=main&style=for-the-badge&label=Documentation)](https://github.com/ColinKennedy/ever.nvim/actions/workflows/documentation.yml)  [![luacheck](https://img.shields.io/github/actions/workflow/status/ColinKennedy/ever.nvim/luacheck.yml?branch=main&style=for-the-badge&label=Luacheck)](https://github.com/ColinKennedy/ever.nvim/actions/workflows/luacheck.yml) [![llscheck](https://img.shields.io/github/actions/workflow/status/ColinKennedy/ever.nvim/llscheck.yml?branch=main&style=for-the-badge&label=llscheck)](https://github.com/ColinKennedy/ever.nvim/actions/workflows/llscheck.yml) [![stylua](https://img.shields.io/github/actions/workflow/status/ColinKennedy/ever.nvim/stylua.yml?branch=main&style=for-the-badge&label=Stylua)](https://github.com/ColinKennedy/ever.nvim/actions/workflows/stylua.yml)  [![urlchecker](https://img.shields.io/github/actions/workflow/status/ColinKennedy/ever.nvim/urlchecker.yml?branch=main&style=for-the-badge&label=URLChecker)](https://github.com/ColinKennedy/ever.nvim/actions/workflows/urlchecker.yml)  |
| License      | [![License-MIT](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](https://github.com/JoeyFitzpatrick/ever.nvim/blob/main/LICENSE)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Social       | [![RSS](https://img.shields.io/badge/rss-F88900?style=for-the-badge&logo=rss&logoColor=white)](https://github.com/JoeyFitzpatrick/ever.nvim/commits/main/doc/news.txt.atom)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

A template repository used to create Neovim plugins.


# Features
- Follows [nvim-best-practices](https://github.com/nvim-neorocks/nvim-best-practices)
- Fast start-up (~1 ms)
- Auto-release to [luarocks](https://luarocks.org) & [GitHub](https://github.com/JoeyFitzpatrick/ever.nvim/releases)
- Automated user documentation (using [panvimdoc](https://github.com/kdheepak/panvimdoc))
- Automated API documentation (using [mini.doc](https://github.com/echasnovski/mini.doc))
- Vimtags generation
- Built-in Vim commands
- A high quality command mode parser
- Auto-completes your commands at any cursor position
- No external dependencies[*](https://github.com/JoeyFitzpatrick/ever.nvim/wiki/External-Dependencies-Disclaimer)
- [LuaCATS](https://luals.github.io/wiki/annotations/) annotations and type-hints, everywhere
- [RSS feed support](https://github.com/JoeyFitzpatrick/ever.nvim/commits/main/doc/news.txt.atom)
- Built-in logging to stdout / files
- Unittests use the full power of native [busted](https://github.com/lunarmodules/busted)
- Automated testing matrix supports 6 Neovim/OS combinations
    - neovim: `[v0.10.0, stable, nightly]`
    - os: `[ubuntu-latest, macos-latest]`
- 100% Lua
- Uses [Semantic Versioning](https://semver.org)
- Integrations
    - [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
    - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
    - `:checkhealth`
- Github actions for:
    - [StyLua](https://github.com/JohnnyMorganz/StyLua) - Auto-formats Lua code
    - [llscheck](https://github.com/jeffzi/llscheck) - Checks for Lua type mismatches
    - [luacheck](https://github.com/mpeterv/luacheck) - Checks for Lua code issues
    - [luarocks](https://luarocks.org) auto-release ([LUAROCKS_API_KEY secret](https://github.com/nvim-neorocks/sample-luarocks-plugin?tab=readme-ov-file#publishing-to-luarocks) configuration required)
    - [GitHub](https://github.com/JoeyFitzpatrick/ever.nvim/releases) auto-release ([PERSONAL_ACCESS_TOKEN secret](https://github.com/nvim-neorocks/sample-luarocks-plugin?tab=readme-ov-file#installing-release-please-recommended) configuration required)
    - [mini.doc](https://github.com/echasnovski/mini.doc) - API documentation auto-generator
    - [panvimdoc](https://github.com/kdheepak/panvimdoc) - User documentation auto-generator
    - [urlchecker](https://github.com/urlstechie/urlchecker-action) - Checks for broken URL links
    - PR reviews - Reminds users to update `doc/news.txt`


# Installation
<!-- TODO: (you) - Adjust and add your dependencies as needed here -->
- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "JoeyFitzpatrick/ever.nvim",
    -- TODO: (you) - Make sure your first release matches v1.0.0 so it auto-releases!
    version = "v1.*",
}
```


# Configuration
(These are default values)

<!-- TODO: (you) - Remove / Add / Adjust your configuration here -->

- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "JoeyFitzpatrick/ever.nvim",
    config = function()
        vim.g.ever_configuration = {
            cmdparse = {
                auto_complete = { display = { help_flag = true } },
            },
            commands = {
                goodnight_moon = { read = { phrase = "A good book" } },
                hello_world = {
                    say = { ["repeat"] = 1, style = "lowercase" },
                },
            },
            logging = {
                level = "info",
                use_console = false,
                use_file = false,
            },
            tools = {
                lualine = {
                    arbitrary_thing = {
                        color = "Visual",
                        text = " Arbitrary Thing",
                    },
                    copy_logs = {
                        color = "Comment",
                        text = "󰈔 Copy Logs",
                    },
                    goodnight_moon = {
                        color = "Question",
                        text = " Goodnight moon",
                    },
                    hello_world = {
                        color = "Title",
                        text = " Hello, World!",
                    },
                },
                telescope = {
                    goodnight_moon = {
                        { "Foo Book", "Author A" },
                        { "Bar Book Title", "John Doe" },
                        { "Fizz Drink", "Some Name" },
                        { "Buzz Bee", "Cool Person" },
                    },
                    hello_world = { "Hi there!", "Hello, Sailor!", "What's up, doc?" },
                },
            },
        }
    end
}
```

# Commands
Just use a valid git command from command mode, via the `:G` command:

<!-- See plugin/ever.lua for details. -->

```vim
:G pull
:G status
:G commit -m "a commit message"
```


# Tests
## Initialization
Run this line once before calling any `busted` command

```sh
eval $(luarocks path --lua-version 5.1 --bin)
```


## Running
Run all tests
```sh
luarocks test --test-type busted
# Or manually
busted --helper spec/minimal_init.lua .
# Or with Make
make test
```

Run test based on tags
```sh
busted --helper spec/minimal_init.lua . --tags=simple
```

# Tracking Updates
See [doc/news.txt](doc/news.txt) for updates.

You can watch this plugin for changes by adding this URL to your RSS feed:
```
https://github.com/JoeyFitzpatrick/ever.nvim/commits/main/doc/news.txt.atom
```

# Other Plugins
This template is full of various features. But if your plugin is only meant to
be a simple plugin and you don't want the bells and whistles that this template
provides, consider instead using
[nvim-ever](https://github.com/ellisonleao/nvim-plugin-template)
