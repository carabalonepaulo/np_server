# Package

version       = "0.1.0"
author        = "Paulo Carabalone"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
namedBin      = { "main": "./bin/server" }.toTable()


# Dependencies

requires "nim >= 1.6.6"
requires "lua"
