module lib.cmake;

import std.file : getcwd, mkdirRecurse;
import std.path : buildPath, absolutePath;
import std.process : environment;
import std.string : indexOf;
import std.regex : ctRegex, matchFirst;

import lib.set_compiler;
import lib.process : executeAt;

/** The options used for CMake */
struct CmakeOptions
{
  /** The build config. Defaults to `"release"` */
  string buildConfig = "release";
  /** The generator to use. Defaults to `"Ninja"` */
  auto generator = "Ninja";
  /** The compiler to use. If `CC` and `CXX` environment variables are not specified, it defaults to `clang` */
  auto compiler = "clang";
}

/**
  Configure and build a Cmake project at the given paths.

  Params:
      rootDir = The root path which includes CMakeLists.txt
      buildDir = The building directory path
      options = The options used for CMake

*/
void cmake(string rootDir = getcwd(), string buildDir = buildPath(getcwd(),
    "./build"), CmakeOptions options = CmakeOptions())
{
  // build dir
  mkdirRecurse(buildDir);

  // env variables
  string[string] env = set_compiler(options.compiler);

  // sanitizer
  const sanitizerArgs = convert_sanitizer(options.buildConfig);

  // configure
  executeAt(["cmake", "-G", options.generator, "-S", rootDir, "-B",
      buildDir] ~ sanitizerArgs, rootDir, env);
  // build
  executeAt([
      "cmake", "--build", buildDir, "--config",
      convert_build_config(options.buildConfig)
      ], rootDir, env);
}

/** Convert D config to Cmake config */
private auto convert_build_config(string buildConfig)
{
  if (buildConfig.indexOf("debug") != -1)
  {
    return "Debug";
  }
  else if (buildConfig.indexOf("release") != -1)
  {
    return "Release";
  }

  return "Debug";
}

private auto convert_sanitizer(string buildConfig)
{
  // extract the name of the sanitizer from the build config and store it in the SANITIZER env variable for CMake to use.
  auto sanitizeMatch = matchFirst(buildConfig, ctRegex!(r"sanitize-(\w*)"));
  if (!sanitizeMatch.empty() && sanitizeMatch.length == 2)
  {
    return ["-D", "CMAKE_SANITIZER=" ~ sanitizeMatch[1]];
  }

  return [];
}
