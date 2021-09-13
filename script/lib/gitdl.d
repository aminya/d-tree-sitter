module lib.gitdl;

import std.net.curl : download;
import std.stdio : writeln;
import std.format : format;
import std.file : tempDir, exists, remove, mkdirRecurse, write, readText;
import std.path : buildPath, dirName;
import std.stdio : stderr;

import lib.fs : moveRecurse, rmdirRecurseForce;
import lib.unzip : unzip;

private auto timesTried = 0;

/**
  Download a Git repository from GitHub

  Params:
      user = The username
      repo = The repository name
      tag = The tag to download
      dest = The destination path for the downloaded repository
      stagingDir = The directory to download the zip file into and unzip it. By default a temp direcotry is used
      retryTimes = The number of times to retrying downloading. Defaults to `5`.
*/
void gitdl(const string user, const string repo, const string tag,
    const string dest, const string stagingDir = tempDir(), uint retryTimes = 5)
{
  const cacheFile = buildPath(dest, ".gitdl_cache.txt");
  if (exists(dest) && exists(cacheFile))
  {
    const cache = readText(cacheFile);
    if (cache == tag)
    {
      writeln(format!"%s/%s#%s already downloaded to %s"(user, repo, tag, dest));
      return;
    }
  }
  mkdirRecurse(stagingDir); // ensure that staging dir exits
  const name = repo ~ "-" ~ (tag[0] == 'v' ? tag[1 .. $] : tag); // v is removed from the begining of the tag
  const zipName = name ~ ".zip";
  const zipPath = buildPath(stagingDir, zipName);
  const unzipDir = buildPath(stagingDir, name);
  try
  {
    // downloading
    writeln(format!"Downloading %s/%s#%s"(user, repo, tag));
    if (!(exists(zipPath))) // cache
    {
      download(format!"https://github.com/%s/%s/archive/refs/tags/%s.zip"(user,
          repo, tag), zipPath);
    }
    // unzip
    unzip(zipPath);
    // copy to the destination
    rmdirRecurseForce(dest);
    mkdirRecurse(dest);
    moveRecurse(unzipDir, dest);
  }
  catch (Exception e)
  {
    // start clean
    remove(zipPath);
    rmdirRecurseForce(unzipDir);
    rmdirRecurseForce(dest);
    if (timesTried > retryTimes)
    {
      throw e;
    }
    stderr.writeln("Download failed with: \n", e, "\n retrying...");
    timesTried++;
    return gitdl(user, repo, tag, dest, stagingDir, retryTimes);
  }
  // when successful reset the times tried
  timesTried = 0;
  // write the cache
  write(cacheFile, tag);
}
