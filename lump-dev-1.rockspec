package = "lump"
version = "dev-1"
source = {
   url = "git+ssh://git@github.com/FreeMasen/lump"
}
description = {
   summary = "A pool collection for cosock",
   detailed = [[
A pool collection for cosock
]],
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      ["lump"] = "lump/init.lua"
   },
}
