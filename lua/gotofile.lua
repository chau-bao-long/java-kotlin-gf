local utils = require("utils")
local M = {}

local function find_in_file(cur_word)
  for i = 1, vim.fn.line("$"), 1 do
    local l = vim.fn.getbufline(vim.fn.bufnr(), i)[1]

    if string.find(l, "class " .. cur_word) ~= nil then
      return i
    end
  end

  return 0
end

local function try_to_jump(open_cmd, paths, cur_word)
  for _, path in ipairs(paths) do
    if utils.file_exists(path) then
      vim.cmd(open_cmd .. " " .. path)
      local found_line = find_in_file(cur_word)
      vim.cmd(tostring(found_line))

      return true
    end
  end

  return false
end

local function jump_file_same_package(open_cmd)
  local cur_dir = vim.fn.expand("%:p:h")
  local cur_word = vim.fn.expand("<cword>")

  local paths = {}

  table.insert(paths, cur_dir .. "/" .. cur_word .. ".java")
  table.insert(paths, cur_dir .. "/" .. cur_word .. ".kt")
  table.insert(paths, string.gsub(cur_dir, "main", "test") .. "/" .. cur_word .. ".java")
  table.insert(paths, string.gsub(cur_dir, "test", "main") .. "/" .. cur_word .. ".java")
  table.insert(paths, string.gsub(cur_dir, "main", "test") .. "/" .. cur_word .. ".kt")
  table.insert(paths, string.gsub(cur_dir, "test", "main") .. "/" .. cur_word .. ".kt")

  return try_to_jump(open_cmd, paths, cur_word)
end

local function jump_to_exact_match_path(open_cmd)
  local cur_word = vim.fn.expand("<cword>")
  local project_path = vim.fn.getcwd(0)

  for i = 1, vim.fn.line("$"), 1 do
    local line = vim.fn.getbufline(vim.fn.bufnr(), i)[1]

    local found = string.find(line, "import")

    if found == 1 and string.find(line, cur_word) ~= nil then
      local words = vim.fn.split(line, [[\W\+]])
      table.remove(words, 1)
      local relative_path = table.concat(words, "/")

      local paths = {}

      table.insert(paths, vim.g.libPath .. "/" .. relative_path .. ".java")
      table.insert(paths, vim.g.libPath .. "/" .. relative_path .. ".kt")

      for _, src_path in ipairs(vim.g.srcPath) do
        table.insert(paths, project_path .. src_path .. relative_path .. ".java")
        table.insert(paths, project_path .. src_path .. relative_path .. ".kt")
      end

      return try_to_jump(open_cmd, paths, cur_word)
    end
  end
end

function M.open_file(...)
  local args = {...}
  local open_cmd = args[0] or "e"
  local is_opened = false

  is_opened = is_opened or jump_file_same_package(open_cmd)
  is_opened = is_opened or jump_to_exact_match_path(open_cmd)
end

return M
