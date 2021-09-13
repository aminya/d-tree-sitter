module lib.set_compiler;

import std.stdio : writeln;
import std.process : environment;

auto set_compiler(string compiler = "clang")
{
  // env variables
  string[string] env = null;

  if (environment.get("CC") is null && environment.get("CXX") is null)
  {
    switch (compiler)
    {
    case "clang":
      env["CC"] = "clang";
      env["CXX"] = "clang++";
      break;
    case "gcc":
      env["CC"] = "gcc";
      env["CXX"] = "g++";
      break;
    case "msvc":
      env["CC"] = "cl";
      env["CXX"] = "cl";
      break;
    default:
      writeln("Ignoring the provided compiler that is not supported: " ~ compiler);
    }
  }
  return env;
}
