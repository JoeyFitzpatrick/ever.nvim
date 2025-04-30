-- This code was copied, then modified, from `nvim-unception`.
-- Copyright (c) 2022 Samuel Williams

local constants = require("ever._core.nested-buffers.constants")

local function escape_special_chars(str)
    if str ~= nil then
        -- Need to escape backslashes and quotes in case they are part of the
        -- filepaths. Lua needs \\ to define a \, so to escape special chars,
        -- there are twice as many backslashes as you would think that there
        -- should be.
        str = string.gsub(str, "\\", "\\\\\\\\")
        str = string.gsub(str, '"', '\\\\\\"')
        str = string.gsub(str, " ", "\\\\ ")
        return str
    else
        return ""
    end
end

-- We don't want to overwrite :h shada
vim.o.sdf = "NONE"

-- We don't want to start. Send the args to the server instance instead.
local args = vim.call("argv")

local arg_str = ""
for _, filepath in pairs(args) do
    if string.len(arg_str) == 0 then
        arg_str = escape_special_chars(filepath)
    else
        arg_str = arg_str .. " " .. escape_special_chars(filepath)
    end
end

-- Send messages to host on existing pipe.
---@diagnostic disable-next-line: param-type-mismatch
local sock = vim.fn.sockconnect("pipe", os.getenv(constants.ever_pipe_path_host_env_var), { rpc = true })

-- note that using 'return' allows for getting the returned value of the fn
local should_use_nested_nvim_call = "return ever_should_use_nested_nvim()"
local should_use_nested_nvim = vim.fn.rpcrequest(sock, "nvim_exec_lua", should_use_nested_nvim_call, {})
if should_use_nested_nvim == vim.NIL or not should_use_nested_nvim then
    return
end

local edit_files_call = "ever_edit_files(" .. '"' .. arg_str .. '", ' .. #args .. ")"
vim.fn.rpcrequest(sock, "nvim_exec_lua", edit_files_call, {})

-- Start up a pipe so that the client can listen for a response from the host session.
local nested_pipe_path = vim.call("serverstart")

-- Send the pipe path and edited filepath to the host so that it knows what file to look for and who to respond to.
local notify_when_done_call = "ever_notify_when_done_editing("
    .. vim.inspect(nested_pipe_path)
    .. ","
    .. vim.inspect(arg_str)
    .. ")"
vim.fn.rpcnotify(sock, "nvim_exec_lua", notify_when_done_call, {})

-- Sleep forever. The host session will kill this when it's done editing.
while true do
    vim.cmd("sleep 10")
end
