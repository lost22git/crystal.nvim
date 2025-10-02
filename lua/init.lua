-- [nfnl] fnl/init.fnl
local function disable_diagnostic(bufid)
  if vim.diagnostic.is_enabled({bufnr = bufid}) then
    return pcall(vim.diagnostic.enable, false, {bufnr = bufid})
  else
    return nil
  end
end
local function open_hover_window(text_or_lines, title, callback)
  local lines
  do
    local _2_ = type(text_or_lines)
    if (_2_ == "string") then
      lines = vim.fn.split(text_or_lines, "\n", true)
    else
      local _ = _2_
      lines = text_or_lines
    end
  end
  local max_cols = 0
  for _, l in ipairs(lines) do
    max_cols = math.max(max_cols, vim.api.nvim_strwidth(l))
  end
  local bufid = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufid, 0, -1, false, lines)
  local winid = vim.api.nvim_open_win(bufid, true, {title = title, relative = "cursor", row = 1, col = 0, width = max_cols, height = math.min(16, #lines), style = "minimal"})
  disable_diagnostic(bufid)
  vim.bo[bufid]["readonly"] = true
  vim.bo[bufid]["modifiable"] = false
  vim.wo[winid]["wrap"] = false
  if callback then
    return callback(bufid, winid)
  else
    return nil
  end
end
local function get_current_file()
  return vim.fn.expand("%")
end
local function get_cursor_location()
  return vim.fn.line("."), vim.fn.col(".")
end
local function get_cursor_word()
  return vim.fn.expand("<cword>")
end
local function get_selection_text()
  vim.cmd("exe  \"normal \\<Esc>\"")
  vim.cmd("normal! gv\"xy")
  return vim.fn.trim(vim.fn.getreg("x"))
end
local function on_v_modes()
  local v_block_mode = vim.api.nvim_replace_termcodes("<C_V>", true, true, true)
  local v_modes = {"v", "V", v_block_mode}
  return vim.list_contains(v_modes, vim.fn.mode())
end
local function get_cursor_text()
  local _5_ = on_v_modes()
  if (_5_ == false) then
    return get_cursor_word()
  elseif (_5_ == true) then
    return get_selection_text()
  else
    return nil
  end
end
local function do_run(_7_)
  local run = _7_["run"]
  local line_number, column_number = get_cursor_location()
  return run({file = get_current_file(), line = line_number, column = column_number, text = get_cursor_text(), open_hover_window = open_hover_window})
end
local function add_keymap(item, bufid)
  local name = item["name"]
  local key = item["key"]
  local mode = item["mode"]
  local function _8_()
    return do_run(item)
  end
  return vim.keymap.set(mode, key, _8_, {buffer = bufid, desc = name})
end
local function create_autocmd(item)
  local name = item["name"]
  local event = item["event"]
  local pattern = item["pattern"]
  local function _10_(_9_)
    local bufid = _9_["buf"]
    add_keymap(item, bufid)
    return nil
  end
  return vim.api.nvim_create_autocmd(event, {desc = name, pattern = pattern, callback = _10_})
end
local function on_exit(res, cmd, open_hover_window0)
  local out
  local function _15_()
    local _11_, _12_ = nil, nil
    local _13_
    if (res.stderr == "") then
      _13_ = res.stdout
    else
      _13_ = res.stderr
    end
    _11_, _12_ = string.gsub(_13_, "\27%[.-m", "")
    if ((nil ~= _11_) and true) then
      local a = _11_
      local _ = _12_
      return a
    else
      return nil
    end
  end
  out = vim.fn.trim(_15_())
  local title = table.concat(cmd, " ")
  local function cb(bufid, _winid)
    vim.bo[bufid]["filetype"] = "crystal"
    return nil
  end
  return open_hover_window0(out, title, cb)
end
local function implementations_on_exit(res, cmd, open_hover_window0)
  local function send_to_loclist(items)
    local list
    local function _17_(item)
      local _local_18_ = vim.split(item, ":", true)
      local file = _local_18_[1]
      local line = _local_18_[2]
      local column = _local_18_[3]
      return {filename = file, lnum = line, col = column, text = ""}
    end
    list = vim.tbl_map(_17_, items)
    vim.cmd("tabnew")
    vim.fn.setloclist(0, list, "r")
    return vim.cmd("lopen | exe \"normal \\<Enter>\"")
  end
  local items
  local function _21_()
    local _19_, _20_ = string.gsub(res.stdout, "\27%[.-m", "")
    if ((nil ~= _19_) and true) then
      local a = _19_
      local _ = _20_
      return a
    else
      return nil
    end
  end
  items = vim.split(vim.fn.trim(_21_()), "\n", true)
  if (1 < #items) then
    return send_to_loclist(vim.list_slice(items, 2))
  else
    local title = table.concat(cmd, " ")
    return open_hover_window0("implementation not found", title, nil)
  end
end
local function crystal_tool_cmd(subcmd, file, line, column, text)
  if ((subcmd == "context") or (subcmd == "expand") or (subcmd == "implementations")) then
    return {"crystal", "tool", subcmd, "-c", (file .. ":" .. line .. ":" .. column), file}
  elseif (subcmd == "hierarchy") then
    return {"crystal", "tool", "hierarchy", "-e", text, file}
  else
    return nil
  end
end
local function docr_cmd(subcmd, text)
  return {"docr", subcmd, ("'" .. vim.fn.escape(text, "'") .. "'")}
end
local items
local function _26_(_25_)
  local file = _25_["file"]
  local line = _25_["line"]
  local column = _25_["column"]
  local text = _25_["text"]
  local open_hover_window0 = _25_["open_hover_window"]
  local cmd = crystal_tool_cmd("context", file, line, column, text)
  print(table.concat(cmd, " "))
  local function _27_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _27_)
end
local function _29_(_28_)
  local file = _28_["file"]
  local line = _28_["line"]
  local column = _28_["column"]
  local text = _28_["text"]
  local open_hover_window0 = _28_["open_hover_window"]
  local cmd = crystal_tool_cmd("expand", file, line, column, text)
  print(table.concat(cmd, " "))
  local function _30_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _30_)
end
local function _32_(_31_)
  local file = _31_["file"]
  local line = _31_["line"]
  local column = _31_["column"]
  local text = _31_["text"]
  local open_hover_window0 = _31_["open_hover_window"]
  local cmd = crystal_tool_cmd("hierarchy", file, line, column, text)
  print(table.concat(cmd, " "))
  local function _33_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _33_)
end
local function _35_(_34_)
  local file = _34_["file"]
  local line = _34_["line"]
  local column = _34_["column"]
  local text = _34_["text"]
  local open_hover_window0 = _34_["open_hover_window"]
  local cmd = crystal_tool_cmd("implementations", file, line, column, text)
  print(table.concat(cmd, " "))
  local function _36_(_241)
    return vim.schedule_wrap(implementations_on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _36_)
end
local function _38_(_37_)
  local _file = _37_["_file"]
  local _line = _37_["_line"]
  local _column = _37_["_column"]
  local text = _37_["text"]
  local open_hover_window0 = _37_["open_hover_window"]
  local cmd = docr_cmd("info", text)
  print(table.concat(cmd, " "))
  local function _39_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _39_)
end
local function _41_(_40_)
  local _file = _40_["_file"]
  local _line = _40_["_line"]
  local _column = _40_["_column"]
  local text = _40_["text"]
  local open_hover_window0 = _40_["open_hover_window"]
  local cmd = docr_cmd("search", text)
  print(table.concat(cmd, " "))
  local function _42_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _42_)
end
local function _44_(_43_)
  local _file = _43_["_file"]
  local _line = _43_["_line"]
  local _column = _43_["_column"]
  local text = _43_["text"]
  local open_hover_window0 = _43_["open_hover_window"]
  local cmd = docr_cmd("tree", text)
  print(table.concat(cmd, " "))
  local function _45_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _45_)
end
items = {{name = "crystal tool context", event = "FileType", pattern = "crystal", key = "<Leader>kc", mode = "n", run = _26_}, {name = "crystal tool expand", event = "FileType", pattern = "crystal", key = "<Leader>ke", mode = "n", run = _29_}, {name = "crystal tool hierarchy", event = "FileType", pattern = "crystal", key = "<Leader>kh", mode = {"n", "v"}, run = _32_}, {name = "crystal tool implementations", event = "FileType", pattern = "crystal", key = "<Leader>ki", mode = "n", run = _35_}, {name = "docr info", event = "FileType", pattern = "crystal", key = "<Leader>k", mode = {"n", "v"}, run = _38_}, {name = "docr search", event = "FileType", pattern = "crystal", key = "<Leader>K", mode = {"n", "v"}, run = _41_}, {name = "docr tree", event = "FileType", pattern = "crystal", key = "<Leader>kk", mode = {"n", "v"}, run = _44_}}
local M = {}
M.setup = function(_config)
  for _, item in ipairs(items) do
    create_autocmd(item)
  end
  return nil
end
return M
