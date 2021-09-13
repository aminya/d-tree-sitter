import std.stdio : writeln;
import std.file : exists, readText, write;
import std.path : buildPath, dirName, buildNormalizedPath;
import std.process : environment;
import std.format : format;
import std.array : replace, array, join;
import std.algorithm : reduce, map, find;
import std.regex : ctRegex, replaceAll;

import lib.gitdl : gitdl;
import lib.process : executeShellAt;
import lib.meson : meson, MesonOptions;

/** Download Tree Sitter source files */
void download_tree_sitter(string treeSitterVersion, string treeSitterDlDir,
    string treeSitterDownloadCache)
{
  gitdl("tree-sitter", "tree-sitter", treeSitterVersion, treeSitterDlDir, treeSitterDownloadCache);
}

/** Bind Tree Sitter API header to D using Dpp */
void bind_tree_sitter(string treeSitterPackageDir, string treeSitterDlDir,
    string treeSitterGenDir, string compiler = environment.get("DC", "dmd"))
{
  const treeSitterLibcD = buildPath(treeSitterPackageDir, "libc.d");
  if (treeSitterLibcD.exists()) // cache
  {
    return writeln(format!"Tree-sitter header already exists at %s"(treeSitterLibcD));
  }

  const treeSitterLibcDpp = buildPath(treeSitterPackageDir, "libc.dpp");
  const treeSitterIncludeDir = buildPath(treeSitterDlDir, "lib", "include");

  writeln("Binding tree_sitter.libc.h to D using Dpp...");

  const dppBin = format!"dub run --build=release --compiler=%s --quiet --yes dpp --"(compiler);
  const headersMap = [
    "stdio.h": "core.stdc.stdio", "stdlib.h": "core.stdc.stdlib",
    "stdint.h": "core.stdc.stdint", "stdbool.h": "core.stdc.stdbool"
  ];

  const prebuiltHeaders = headersMap.byKeyValue()
    .map!((elm) => (" --prebuilt-header " ~ elm.key ~ "=" ~ elm.value))().join(" ");

  // TODO macos fails to find stbool.h
  const headers = " --ignore-system-paths --no-sys-headers " ~ prebuiltHeaders;
  executeShellAt(dppBin ~ headers ~ " --keep-d-files " ~ treeSitterLibcDpp
      ~ " --include-path " ~ treeSitterIncludeDir ~ " --source-output-path "
      ~ treeSitterPackageDir ~ " --preprocess-only --compiler=" ~ compiler, treeSitterGenDir);

  // HACK remove excess dpp generated code
  const generatedFile = buildPath(treeSitterPackageDir, "libc.d");
  auto fileContent = readText(generatedFile);

  // remove everything before extern(C)
  fileContent = "module d_tree_sitter.libc;\nimport core.stdc.config;\n" ~ fileContent.find(
      "extern(C)");

  // HACK remove struct __ioBuf from the generated file
  fileContent = fileContent.replace("struct _iobuf;", "")
    .replace("struct _IO_FILE;", "").replace("struct __sFILE;", "") // removes struct definition because `stdio` is already imported
    .replaceAll(ctRegex!"#.*", ""); // TODO remove once dpp PR is merged

  write(generatedFile, fileContent);
}

/** Build tree_sitter.lib */
void build_d_tree_sitter(string treeSitterPackageDir, MesonOptions mesonOptions)
{
  const treeSitterGenDir = buildPath(treeSitterPackageDir, "gen");
  const treeSitterDlDir = buildPath(treeSitterGenDir, "tree-sitter");
  const treeSitterDownloadCache = buildPath(treeSitterGenDir, "download-cache");
  const treeSitterBuildDir = buildPath(treeSitterPackageDir, "build");

  const treeSitterVersion = readText(buildPath(treeSitterPackageDir, "tree-sitter-version.txt")).replaceAll(
      ctRegex!`\s`, "");

  download_tree_sitter(treeSitterVersion, treeSitterDlDir, treeSitterDownloadCache);

  bind_tree_sitter(treeSitterPackageDir, treeSitterDlDir, treeSitterGenDir);

  writeln("Build tree_sitter.lib");
  meson(treeSitterPackageDir, treeSitterBuildDir, mesonOptions);
}

void main() {
  // common paths
  const rootDir = dirName(dirName(buildNormalizedPath(__FILE_FULL_PATH__)));
  // package paths
  const treeSitterPackageDir = buildPath(rootDir, "src");

  // set DUB_BUILD_TYPE from the cli, so all the build scripts use that
  const buildConfig = environment["DUB_BUILD_TYPE"];

  const mesonOptions = MesonOptions(buildConfig);

  build_d_tree_sitter(treeSitterPackageDir, mesonOptions);
}