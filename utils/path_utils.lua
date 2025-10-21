-- utils/path_utils.lua
-- app.fs thin wrappers split from file_utils

local P = {}

P.joinPath         = function(...) return app.fs.joinPath(...) end
P.getFileExtension = function(p) return app.fs.fileExtension(p) end
P.getFileName      = function(p) return app.fs.fileName(p) end
P.getFileTitle     = function(p) return app.fs.fileTitle(p) end
P.getDirectory     = function(p) return app.fs.filePath(p) end
P.isDirectory      = function(p) return app.fs.isDirectory(p) end
P.isFile           = function(p) return app.fs.isFile(p) end
P.listFiles        = function(p) return app.fs.listFiles(p) end
P.createDirectory  = function(p) return app.fs.makeDirectory(p) end
P.createDirectories= function(p) return app.fs.makeAllDirectories(p) end

return P