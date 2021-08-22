local M = {}

function M.file_exists(name)
   local f = io.open(name, "r")
   return f ~= nil and io.close(f)
end

function M.esc(x)
  return (x:gsub('%%', '%%%%')
    :gsub('^%^', '%%^')
    :gsub('%$$', '%%$')
    :gsub('%(', '%%(')
    :gsub('%)', '%%)')
    :gsub('%.', '%%.')
    :gsub('%[', '%%[')
    :gsub('%]', '%%]')
    :gsub('%*', '%%*')
    :gsub('%+', '%%+')
    :gsub('%-', '%%-')
    :gsub('%?', '%%?'))
end

return M
