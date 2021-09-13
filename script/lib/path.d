module lib.path;

/** Escape spaces in the path
    Params:
        given_path =   the given path as a string
 */
auto escape_space(string given_path)
{
  import std.regex : ctRegex, replaceAll;

  version (Windows)
  {
    // For windows, replace space with symbol %20
    return given_path.replaceAll(ctRegex!(r"(\s+)", "g"), "%20");
  }
  // for posix path, escape with \\
  return given_path.replaceAll(ctRegex!(r"(\s+)", "g"), "\\$1");
}

/** Convert windows path to posix path by replaceing `\` with `/`. It returns the path as is on non-windows
  Params:
    path = the path to convert

  Example: `C:/folder` will be converted to `c:/folder`
 */
auto posixify_path(string path)
{
  import std.regex : ctRegex, replaceAll;

  version (Windows)
  {
    // windows path, replace \\ with /
    return path.replaceAll(ctRegex!(r"\\", "g"), "/");
  }
  // posix path
  return path;
}

/** Convert windows path to WSL path
  Params:
    windowsPath = the windows path to convert

  Example: `C:/folder` will be converted to `/mnt/c/folder`
 */
auto wslify_path(string windowsPath)
{
  import std.regex : ctRegex, replaceFirst;
  import std.ascii : toLower;

  auto posixWindowsPath = posixify_path(windowsPath).replaceFirst(ctRegex!(r"(\w):"), "/mnt/$1");
  return posixWindowsPath[0 .. 5] ~ posixWindowsPath[5].toLower() ~ posixWindowsPath[6 .. $];
}
