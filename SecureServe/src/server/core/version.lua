local Version = {
    MAJOR = 1,
    MINOR = 5,
    PATCH = 1,
}

Version.STRING = ("%d.%d.%d"):format(Version.MAJOR, Version.MINOR, Version.PATCH)
Version.FULL   = "SecureServe v" .. Version.STRING

_G.SecureServeVersion = Version

return Version
