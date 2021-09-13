module lib.meson;

import std.file : exists, getcwd, mkdirRecurse;
import std.path : buildPath, absolutePath;
import std.string : indexOf;
import std.regex : ctRegex, matchFirst;
import std.stdio : writeln;

import lib.process : executeAt;
import lib.set_compiler;

/** The options used for CMake */
struct MesonOptions
{
  /** The build config. Defaults to `"release"` */
  string buildConfig = "release";

  /** The backend to use  */
  string backend = "ninja";

  /** The compiler to use. If `CC` and `CXX` environment variables are not specified, it defaults to `clang` */
  auto compiler = "clang";
}

/**
  Configure and build a Meson project at the given paths.

  Params:
      rootDir = The root path which includes meson.build
      buildDir = The building directory path
      options = The options used for Meson

*/
void meson(string rootDir = getcwd(), string buildDir = buildPath(getcwd(),
    "./build"), MesonOptions options = MesonOptions())
{
  // compiler
  const env = set_compiler(options.compiler);

  // build config
  const buildConfig = convert_build_config(options.buildConfig);

  // sanitizer
  const sanitizerArgs = convert_sanitizer(options.buildConfig);

  if (!buildDir.exists()) // guess if the folder exists, then it is already configured
  {
  configure: // if compile fails, the script will configure and try again
    // make build dir
    mkdirRecurse(buildDir);

    // configure
    executeAt([
        "meson", "setup", buildDir, rootDir, "--buildtype", buildConfig,
        "--backend", options.backend
        ] ~ sanitizerArgs, rootDir, env);
  }
  // build
  try
  {
    executeAt(["meson", "compile", "-C", buildDir], rootDir, env);
  }
  catch (Exception ex)
  {
    // configure and try again
    goto configure;
  }
}

/** Convert D config to Cmake config */
private auto convert_build_config(string buildConfig)
{
  // build config
  if (buildConfig.indexOf("debug") != -1)
  {
    return "debug";
  }
  else if (buildConfig.indexOf("release") != -1)
  {
    return "release";
  }

  return "debug";
}

private string[] convert_sanitizer(string buildConfig)
{
  // extract the name of the sanitizer from the build config
  auto sanitizeMatch = matchFirst(buildConfig, ctRegex!(r"sanitize-(\w*)"));
  if (!sanitizeMatch.empty() && sanitizeMatch.length == 2)
  {
    return ["-Db_sanitize=" ~ sanitizeMatch[1], "-Db_lundef=false"];
  }
  return [];
}
