local utils = require("utils")
local fzf = require("fzf")
local M = {}

-- Loop through every lines in current buffer
-- Find the first line contains the class or interface with given name
local function find_class_inteface_in_file(word)
  for i = 1, vim.fn.line("$"), 1 do
    local l = vim.fn.getbufline(vim.fn.bufnr(), i)[1]

    if string.find(l, "class " .. word) ~= nil
      or string.find(l, "interface " .. word) ~= nil
    then
      return i
    end
  end

  return nil
end

-- Loop through every lines in current buffer
-- Find the first line contains the word
local function find_word_in_file(word)
  for i = 1, vim.fn.line("$"), 1 do
    local l = vim.fn.getbufline(vim.fn.bufnr(), i)[1]

    if string.find(l, word) ~= nil then
      return i
    end
  end

  return nil
end

-- Jump to the file at exact line if the file is existed
local function try_to_jump(open_cmd, paths, word)
  for _, path in ipairs(paths) do
    if utils.file_exists(path) then
      vim.cmd(open_cmd .. " " .. path)
      local found_line = find_class_inteface_in_file(word) or find_word_in_file(word)
      vim.cmd(tostring(found_line))

      return true
    end
  end

  return false
end

-- Try to find the file which is on the same package, because java file doesn't need to import that file
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

local function find_import_line(word)
  for i = 1, vim.fn.line("$"), 1 do
    local line = vim.fn.getbufline(vim.fn.bufnr(), i)[1]

    if string.find(line, "import") == 1 and string.match(line, "[.]" .. word .. "$") ~= nil then
      return line
    end
  end

  return nil
end

-- The file can be in library or project, try to build file path using all possible source location
local function build_paths(paths, file_path)
  local project_path = vim.fn.getcwd(0)

  table.insert(paths, vim.g.libPath .. "/" .. file_path)

  for _, src_path in ipairs(vim.g.srcPath) do
    table.insert(paths, project_path .. src_path .. file_path)
  end
end

local function convert_import_line_to_file_path(line)
  local words = vim.fn.split(line, [[\W\+]])
  table.remove(words, 1)
  local relative_path = table.concat(words, "/")

  local paths = {}

  build_paths(paths, relative_path .. ".kt")
  build_paths(paths, relative_path .. ".java")

  return paths
end

local function convert_import_line_to_folder_path(line)
  local words = vim.fn.split(line, [[\W\+]])
  table.remove(words, #words)
  table.remove(words, 1)
  local relative_path = table.concat(words, "/")
  local paths = {}

  build_paths(paths, relative_path)

  return paths
end

-- Find the file in possible paths, if file exists, open the file and jump the correct line
local function jump_to_exact_match_path(open_cmd)
  local cur_word = vim.fn.expand("<cword>")

  local line = find_import_line(cur_word)

  if line == nil then return false end

  local paths = convert_import_line_to_file_path(line)

  return try_to_jump(open_cmd, paths, cur_word)
end

-- Find class or interface in the folder by name, ripgrep search, open the file and jump to correct line
local function jump_to_class_interface_in_path(open_cmd)
  local cur_word = vim.fn.expand("<cword>")

  local line = find_import_line(cur_word)

  if line == nil then return false end

  local paths = convert_import_line_to_folder_path(line)

  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) == 0 then
      goto skip_to_next
    end

    local response = vim.fn.system('rg -n "(class|interface) ' .. cur_word .. '[( {]" ' .. path)

    if response ~= "" then
      local results = vim.fn.split(response, "\n")

      for _, result in ipairs(results) do
        local split = vim.fn.split(result, ":")
        local file_path = split[1]
        local line_no = split[2]

        vim.cmd(open_cmd .. " +" .. line_no .. " " .. file_path)

        return true
      end
    end

    ::skip_to_next::
  end

  return false
end

local function convert_import_line_to_constant_file(line)
  local words = vim.fn.split(line, [[\W\+]])
  table.remove(words, #words)
  table.remove(words, 1)
  local file_path = table.concat(words, "/")
  local paths = {}

  build_paths(paths, file_path .. ".java")
  build_paths(paths, file_path .. ".kt")

  return paths
end

local function jump_to_constant(open_cmd)
  local cur_word = vim.fn.expand("<cword>")
  local full_word = vim.fn.expand("<cWORD>")

  -- Check contants pattern, return if not
  if string.match(cur_word, "[%u_]+") ~= cur_word then
    return
  end

  if cur_word == string.match(full_word, "[%u_.]+") then
    -- the case when import the constant
    -- ex: import.domain.imports.models.ImportStatus.PENDING
    local line = find_import_line(cur_word)

    if line == nil then return false end

    local file_paths = convert_import_line_to_constant_file(line)

    try_to_jump(open_cmd, file_paths, cur_word)
  else
    -- the case when import the class of constant
    -- ex: import.domain.imports.models.ImportStatus

    -- full_word in form of "TestClass.ABC_DEF,"
    local kw = vim.fn.split(full_word, [[\.]])

    local line = find_import_line(kw[1])

    if line == nil then return false end

    local file_paths = convert_import_line_to_file_path(line)

    try_to_jump(open_cmd, file_paths, string.match(kw[2], "[%u_]+"))
  end
end

local function jump_to_top_level_method(open_cmd)
  local cur_word = vim.fn.expand("<cword>")

  local line = find_import_line(cur_word)

  if line == nil then return false end

  local paths = convert_import_line_to_folder_path(line)

  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) == 0 then
      goto skip_to_next
    end

    -- Ripgrep search the function in file path
    local response = vim.fn.system('rg -n "fun .*' .. cur_word .. '\\(" ' .. path)

    if response ~= "" then
      local results = vim.fn.split(response, "\n")

      local pickable = {}
      local data = {}

      -- Build data and pickable options for fuzzy search
      for i, result in ipairs(results) do
        local sp = vim.fn.split(result, ":")
        table.insert(data, sp)
        local file = sp[1]
        local sample_code = string.gsub(sp[3], "%s+", "")
        file = string.gsub(file, utils.esc(vim.fn.getcwd(0)), "")
        for _, src_path in ipairs(vim.g.srcPath) do
          file = string.gsub(file, utils.esc(src_path), "")
        end
        table.insert(pickable, i .. ".  " .. sample_code .. "        " .. file)
      end

      if #data == 1 then
        -- Jump to file directly if there is only one result
        local line_no = data[1][2]
        local file_path = data[1][1]

        vim.cmd(open_cmd .. " +" .. line_no .. " " .. file_path)
      else
        -- Use fuzzy search if there are many possible results
        coroutine.wrap(function()
          local r = fzf.fzf(pickable, "--ansi", { width = 150, height = 30, })[1]
          local i = tonumber(string.sub(r, 1, 1))
          local line_no = data[i][2]
          local file_path = data[i][1]

          vim.cmd(open_cmd .. " +" .. line_no .. " " .. file_path)
        end)()
      end
    end

    ::skip_to_next::
  end
end

function M.open_file(...)
  local args = {...}
  local open_cmd = args[0] or "e"
  local is_opened = false

  is_opened = is_opened or jump_file_same_package(open_cmd)
  is_opened = is_opened or jump_to_exact_match_path(open_cmd)
  is_opened = is_opened or jump_to_class_interface_in_path(open_cmd)
  is_opened = is_opened or jump_to_constant(open_cmd)
  is_opened = is_opened or jump_to_top_level_method(open_cmd)
end

return M
