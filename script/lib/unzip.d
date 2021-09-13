module lib.unzip;

import std.zip : ZipArchive;
import std.path : buildPath, dirName;
import std.file : exists, read, write, mkdirRecurse;

/**
  Unzip the given zip file in the same directroy

  Params:
      zipPath = The path to the zip file
*/
void unzip(string zipPath)
{
  const zipDir = dirName(zipPath);

  auto zipFile = new ZipArchive(read(zipPath));
  foreach (member_name, member; zipFile.directory)
  {
    if (!member.expandedSize)
    {
      continue; // ignore empty files
    }

    zipFile.expand(member);

    const file_name = buildPath(zipDir, member_name);
    mkdirRecurse(dirName(file_name));

    write(file_name, member.expandedData);
  }
}
