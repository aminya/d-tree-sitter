module lib.fs;

/**
  Copy the given source path recursively to the target path

  Params:
      sourcePath = The source path which can be a file or a directory
      targetPath = The target path which can be a file or a directory
*/
void copyRecurse(string sourcePath, string targetPath)
{
  import std.file : isDir, exists, SpanMode, dirEntries, mkdir, mkdirRecurse, copy;
  import std.path : buildPath, absolutePath, relativePath, buildNormalizedPath;
  import std.parallelism;

  if (!sourcePath.isDir)
  {
    return copy(sourcePath, targetPath);
  }

  const sourcePathAbsolute = sourcePath.absolutePath.buildNormalizedPath;
  mkdirRecurse(targetPath);
  foreach (directoryEntry; dirEntries(sourcePathAbsolute, SpanMode.breadth).parallel)
  {
    auto targetEntry = buildPath(targetPath,
        directoryEntry.name.absolutePath.relativePath(sourcePathAbsolute));
    if (directoryEntry.isDir)
    {
      mkdir(targetEntry);
    }
    else
    {
      copy(directoryEntry.name, targetEntry);
    }
  }
}

import std.file : DirEntry, write, read, tempDir, exists, SpanMode, dirEntries;
import std.path : buildPath, extension, baseName;
import std.digest : hexDigest;
import std.digest.crc : CRC32;

/** Check if a folder has changed
  Params:
    rootDir = the directory to check
    pattern = the pattern to check like "*.{d,di}"
  Returns:
    a boolean showing if the folder has changed
*/
bool folderHasChanged(string rootDir, string pattern) @trusted
{
  const cached_name = buildPath(tempDir(), hexDigest!CRC32(pattern ~ rootDir.baseName()));
  const newCache = getUniqueHash(rootDir, pattern);
  if (!cached_name.exists())
  {
    write(cached_name, newCache);
    return true;
  }
  const changed = newCache != cast(ulong[]) read(cached_name);
  if (changed)
  {
    write(cached_name, newCache);
  }
  return changed;
}

/** Get a unique cache for a directory
  Params:
    rootDir = the directory to check
    pattern = the pattern to check like "*.{d,di}"
  Returns:
    a buffer of `ulong[]`
*/
ulong[] getUniqueHash(string rootDir, string pattern) @trusted
{
  ulong[] buffer;
  foreach (directoryEntry; dirEntries(rootDir, pattern, SpanMode.breadth))
  {
    buffer ~= getUniqueHash(directoryEntry);
  }
  return buffer;
}

/// Get a unique hash for a DirEntry
/// https://github.com/WebFreak001/FSWatch/blob/1925700c64d9a26fbb2a6231b2cf94dc343800a4/source/fswatch.d#L38
ulong getUniqueHash(DirEntry entry) @trusted
{
  version (Windows)
    return entry.timeLastModified.stdTime ^ cast(ulong) entry.attributes;
  else version (Posix)
    return entry.statBuf.st_ino | (cast(ulong) entry.statBuf.st_dev << 32UL);
  else
    return (entry.timeLastModified.stdTime ^ (
        cast(ulong) entry.attributes << 32UL) ^ entry.linkAttributes) * entry.size;
}

unittest
{
  copyRecurse("./dub.sdl", "./build/dub.sdl");
  assert("./build/dub.sdl".exists);
  copyRecurse("./packages", "./build");
  assert("./build/packages".exists);
}

/**
  Move the given source path recursively to the target path

  Params:
      sourcePath = The source path which can be a file or a directory
      targetPath = The target path which can be a file or a directory
*/
void moveRecurse(string sourcePath, string targetPath)
{
  import std.file : isDir, exists, SpanMode, dirEntries, mkdir, mkdirRecurse,
    rename, rmdirRecurse;
  import std.path : buildPath, absolutePath, relativePath, buildNormalizedPath;
  import std.parallelism;

  if (!sourcePath.isDir)
  {
    return rename(sourcePath, targetPath);
  }

  const sourcePathAbsolute = sourcePath.absolutePath.buildNormalizedPath;
  mkdirRecurse(targetPath);
  foreach (directoryEntry; dirEntries(sourcePathAbsolute, SpanMode.breadth).parallel)
  {
    auto targetEntry = buildPath(targetPath,
        directoryEntry.name.absolutePath.relativePath(sourcePathAbsolute));
    if (directoryEntry.isDir)
    {
      mkdir(targetEntry);
    }
    else
    {
      rename(directoryEntry.name, targetEntry);
    }
  }
  rmdirRecurse(sourcePath);
}

import std.file : rmdir, dirEntries, FileException, setAttributes, remove, attrIsDir, exists;

// TODO use dub to install rm-rf
//  https://github.com/WebFreak001/rm-rf/blob/master/source/rm/rf.d

/**
  Force remove the given directory recursively

  Params:
      pathname = The directory which should be deleted
*/
void rmdirRecurseForce(in char[] pathname)
{
  if (!pathname.exists)
  {
    return;
  }
  //No references to pathname will be kept after rmdirRecurse,
  //so the cast is safe
  rmdirRecurseForce(DirEntry(cast(string) pathname));
}

/// ditto
void rmdirRecurseForce(DirEntry de)
{
  if (!de.isDir)
    throw new FileException(de.name, "Not a directory");

  if (de.isSymlink)
  {
    version (Windows)
      rmdir(de.name);
    else
      remove(de.name);
  }
  else
  {
    // all children, recursively depth-first
    foreach (DirEntry e; dirEntries(de.name, SpanMode.depth, false))
    {
      version (Windows)
      {
        import core.sys.windows.windows;

        if ((e.attributes & FILE_ATTRIBUTE_READONLY) != 0)
          setAttributes(e, e.attributes & ~FILE_ATTRIBUTE_READONLY);
      }
      attrIsDir(e.linkAttributes) ? rmdir(e.name) : remove(e.name);
    }

    // the dir itself
    rmdir(de.name);
  }
}
