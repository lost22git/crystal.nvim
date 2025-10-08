-- [nfnl] fnl/crystal/init.fnl
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
    local function to_loclist_item(item)
      local _let_17_ = vim.split(item, ":", true)
      local file = _let_17_[1]
      local line = _let_17_[2]
      local column = _let_17_[3]
      local lnum = tonumber(line)
      local col = tonumber(column)
      local text = vim.fn.readfile(file, "", lnum)[lnum]
      return {filename = file, lnum = lnum, col = col, text = text}
    end
    local list = vim.tbl_map(to_loclist_item, items)
    vim.cmd("tabnew")
    vim.fn.setloclist(0, list, "r")
    return vim.cmd("lopen | exe \"normal \\<Enter>\"")
  end
  local items
  local function _20_()
    local _18_, _19_ = string.gsub(res.stdout, "\27%[.-m", "")
    if ((nil ~= _18_) and true) then
      local a = _18_
      local _ = _19_
      return a
    else
      return nil
    end
  end
  items = vim.split(vim.fn.trim(_20_()), "\n", true)
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
local function _25_(_24_)
  local file = _24_["file"]
  local line = _24_["line"]
  local column = _24_["column"]
  local text = _24_["text"]
  local open_hover_window0 = _24_["open_hover_window"]
  local cmd = crystal_tool_cmd("context", file, line, column, text)
  print(table.concat(cmd, " "))
  local function _26_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _26_)
end
local function _28_(_27_)
  local file = _27_["file"]
  local line = _27_["line"]
  local column = _27_["column"]
  local text = _27_["text"]
  local open_hover_window0 = _27_["open_hover_window"]
  local cmd = crystal_tool_cmd("expand", file, line, column, text)
  print(table.concat(cmd, " "))
  local function _29_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _29_)
end
local function _31_(_30_)
  local file = _30_["file"]
  local line = _30_["line"]
  local column = _30_["column"]
  local text = _30_["text"]
  local open_hover_window0 = _30_["open_hover_window"]
  local cmd = crystal_tool_cmd("hierarchy", file, line, column, text)
  print(table.concat(cmd, " "))
  local function _32_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _32_)
end
local function _34_(_33_)
  local file = _33_["file"]
  local line = _33_["line"]
  local column = _33_["column"]
  local text = _33_["text"]
  local open_hover_window0 = _33_["open_hover_window"]
  local cmd = crystal_tool_cmd("implementations", file, line, column, text)
  print(table.concat(cmd, " "))
  local function _35_(_241)
    return vim.schedule_wrap(implementations_on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _35_)
end
local function _37_(_36_)
  local _file = _36_["_file"]
  local _line = _36_["_line"]
  local _column = _36_["_column"]
  local text = _36_["text"]
  local open_hover_window0 = _36_["open_hover_window"]
  local cmd = docr_cmd("info", text)
  print(table.concat(cmd, " "))
  local function _38_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _38_)
end
local function _40_(_39_)
  local _file = _39_["_file"]
  local _line = _39_["_line"]
  local _column = _39_["_column"]
  local text = _39_["text"]
  local open_hover_window0 = _39_["open_hover_window"]
  local cmd = docr_cmd("search", text)
  print(table.concat(cmd, " "))
  local function _41_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _41_)
end
local function _43_(_42_)
  local _file = _42_["_file"]
  local _line = _42_["_line"]
  local _column = _42_["_column"]
  local text = _42_["text"]
  local open_hover_window0 = _42_["open_hover_window"]
  local cmd = docr_cmd("tree", text)
  print(table.concat(cmd, " "))
  local function _44_(_241)
    return vim.schedule_wrap(on_exit)(_241, cmd, open_hover_window0)
  end
  return vim.system(cmd, {text = true}, _44_)
end
items = {{name = "crystal tool context", event = "FileType", pattern = "crystal", key = "<Leader>kc", mode = "n", run = _25_}, {name = "crystal tool expand", event = "FileType", pattern = "crystal", key = "<Leader>ke", mode = "n", run = _28_}, {name = "crystal tool hierarchy", event = "FileType", pattern = "crystal", key = "<Leader>kh", mode = {"n", "v"}, run = _31_}, {name = "crystal tool implementations", event = "FileType", pattern = "crystal", key = "<Leader>ki", mode = "n", run = _34_}, {name = "docr info", event = "FileType", pattern = "crystal", key = "<Leader>k", mode = {"n", "v"}, run = _37_}, {name = "docr search", event = "FileType", pattern = "crystal", key = "<Leader>K", mode = {"n", "v"}, run = _40_}, {name = "docr tree", event = "FileType", pattern = "crystal", key = "<Leader>kk", mode = {"n", "v"}, run = _43_}}
local M = {}
M.setup = function(_config)
  for _, item in ipairs(items) do
    create_autocmd(item)
  end
  return nil
end
return M
