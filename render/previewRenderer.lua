-- Back-compat shim so require("previewRenderer") continues to work.
-- Internally delegates to the modularized local renderer entry point.
return require("render.local.entry")