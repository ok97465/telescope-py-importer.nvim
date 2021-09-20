local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local importer      = require'util_py_importer'
local actions       = require'telescope.actions'
local action_state  = require'telescope.actions.state'
local finders       = require'telescope.finders'
local pickers       = require'telescope.pickers'
local Path          = require'plenary.path'
local conf          = require'telescope.config'.values
local vim = vim

local lookup_keys = {
  value = 1,
  ordinal = 1,
}

local lookup_icon = {
  func = {icon="", color_name="DevIconEex"},
  class = {icon="", color_name="DevIconC"},
}

local filename2path_rel = function(filename)
    local path_rel = filename
    if path_rel:find(".\\", 1, true) or path_rel:find("./", 1, true) then
        path_rel = path_rel:sub(3, #path_rel)
     end
    path_rel = path_rel:gsub("/", ".")
    path_rel = path_rel:gsub("\\", ".")
    path_rel = path_rel:sub(1, #path_rel - 3)

    return path_rel
end

local find = (function()
  if Path.path.sep == "\\" then
    return function(t)
      local start, _, filename, lnum, col, text = string.find(t, [[([^:]+):(%d+):(%d+):(.*)]])

      -- Handle Windows drive letter (e.g. "C:") at the beginning (if present)
      if start == 3 then
        filename = string.sub(t, 1, 3) .. filename
      end

      return filename, lnum, col, text
    end
  else
    return function(t)
      local _, _, filename, lnum, col, text = string.find(t, [[([^:]+):(%d+):(%d+):(.*)]])
      return filename, lnum, col, text
    end
  end
end)()

local parse = function(t)
  local filename, lnum, col, text = find(t.value)

  local ok
  ok, lnum = pcall(tonumber, lnum)
  if not ok then
    lnum = nil
  end

  ok, col = pcall(tonumber, col)
  if not ok then
    col = nil
  end

  local icon_name = "func"
  local name_callable = ""

  local len_text = #text
  if text:find("^def") then
    icon_name = "func"
    name_callable = text:sub(5, len_text):match("[a-z][a-zA-z_0-9]*")
  else
    icon_name = "class"
    name_callable = text:sub(7, len_text):match("[A-Z][a-zA-z_0-9]*")
  end
 

  t.filename = filename
  t.lnum = lnum
  t.col = 0
  t.text = string.format("%-40s%s", name_callable, filename)
  t.name = name_callable
  t.icon_name = icon_name
  return { filename, lnum, col, text, name_callable, icon_name}
end

local make_entry_outline = function(opts)
  local mt_vimgrep_entry

  opts = opts or {}

  local execute_keys = {
    path = function(t)
      if Path:new(t.filename):is_absolute() then
        return t.filename, false
      else
        return Path:new({ t.cwd, t.filename }):absolute(), false
      end
    end,

    filename = function(t)
      return parse(t)[1], true
    end,

    lnum = function(t)
      return parse(t)[2], true
    end,

    col = function(t)
      return parse(t)[3], true
    end,

    text = function(t)
      return parse(t)[4], true
    end,

    name_callable = function(t)
      return parse(t)[5], true
    end,

    icon_name = function(t)
      return parse(t)[6], true
    end,
  }

  mt_vimgrep_entry = {
    cwd = vim.fn.expand(opts.cwd or vim.loop.cwd()),

    display = function(entry)
      local icon = lookup_icon[entry.icon_name].icon
      local color_name = lookup_icon[entry.icon_name].color_name
      return icon .. " " .. entry.text, { { { 1, 3 }, color_name } }
    end,

    __index = function(t, k)
      local raw = rawget(mt_vimgrep_entry, k)
      if raw then
        return raw
      end

      local executor = rawget(execute_keys, k)
      if executor then
        local val, save = executor(t)
        if save then
          rawset(t, k, val)
        end
        return val
      end

      return rawget(t, rawget(lookup_keys, k))
    end,
  }

  return function(line)
    return setmetatable({ line }, mt_vimgrep_entry)
  end
end

local import_from_workspace = function(opts)
  local vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
  opts.entry_maker = make_entry_outline(opts)

  local command_list = vim.tbl_flatten {
      vimgrep_arguments,
      "--glob",
      "*.py",
      "--",
      "(^def ([a-z][a-zA-z_0-9]*)\\()|(^class ([A-Z][a-zA-Z_0-9]*)((\\()|:))",
      "."
  }

  pickers.new(opts, {
    prompt_title = "Importer from workspace",
    finder = finders.new_oneshot_job(command_list, opts),
    previewer = conf.grep_previewer(opts),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          local name_callable = selection.name_callable
          local path_rel = filename2path_rel(selection.filename)

          importer.insert_import({[name_callable]=path_rel})
      end)
      local action_for_import_and_put_name = function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          local name_callable = selection.name_callable
          local path_rel = filename2path_rel(selection.filename)

          vim.api.nvim_put({name_callable}, '', true, true)
          importer.insert_import({[name_callable]=path_rel})
      end

      map('n', '<tab>', action_for_import_and_put_name)
      map('i', '<tab>', action_for_import_and_put_name)
      return true
  end
  }):find()
end

return telescope.register_extension {
  exports = {
    workspace = import_from_workspace,
  }
}
