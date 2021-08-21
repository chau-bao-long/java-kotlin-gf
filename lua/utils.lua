local M = {}

function M.file_exists(name)
   local f = io.open(name, "r")
   return f ~= nil and io.close(f)
end

return M
