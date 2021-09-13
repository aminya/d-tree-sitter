module lib.process;

import std.path : dirName, buildNormalizedPath;
import std.exception : enforce;
import std.format : format;
import std.stdio : writeln;

/** Execute the given shell comamnd at the given directory
    Params:
        command =     the given shell comamnd as a string
        cwd =     the given directory comamnd as a string (by default it is the directory at which this file exists)
    Returns: the result of waiting the process
 */
void executeShellAt(scope const(char)[] command,
    scope const(char)[] cwd = buildNormalizedPath(__FILE_FULL_PATH__).dirName(),
    scope const string[string] env = null, bool debugInfo = false) @trusted
{
  import std.process : wait, spawnShell, Config;

  if (debugInfo)
  {
    writeln(format!"Executing: \n command:\n %s \n cwd: %s \n env: %s"(command, cwd, env));
  }

  auto pid = spawnShell(command, env, Config.none, cwd);
  enforce(wait(pid) == 0,
      format!"Execution failed:\n command:\n %s \n cwd: %s \n env: %s"(command, cwd, env));
  return;
}

/** Execute the given comamnd at the given directory
    Params:
        args =    an array in this form: [program, other_args...]
        cwd =     the given directory comamnd as a string (by default it is the directory at which this file exists)
    Returns: the result of waiting the process
 */
void executeAt(scope const(char[])[] args,
    scope const(char)[] cwd = buildNormalizedPath(__FILE_FULL_PATH__).dirName(),
    scope const string[string] env = null, bool debugInfo = false) @trusted
{
  import std.process : wait, spawnProcess, Config;

  if (debugInfo)
  {
    writeln(format!"Executing: \n args:\n %s \n cwd: %s \n env: %s"(args, cwd, env));
  }

  auto pid = spawnProcess(args, env, Config.none, cwd);
  enforce(wait(pid) == 0,
      format!"Execution failed: \n args:\n %s \n cwd: %s \n env: %s"(args, cwd, env));
  return;
}
