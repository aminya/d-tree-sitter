# d-tree-sitter

[![CI](https://github.com/aminya/d-tree-sitter/actions/workflows/CI.yml/badge.svg)](https://github.com/aminya/d-tree-sitter/actions/workflows/CI.yml)

The D bindings for tree-sitter, a library for incremental parsing.

# Build

You need to have either [cmake](https://cmake.org/) or [meson](https://mesonbuild.com/SimpleStart.html#installing-meson) installed and have it on the path. This is required for building the C library. Then just run:

```ps1
dub build
```

To set up a reproducible build environment, you can run [setup-cpp](https://github.com/aminya/setup-cpp) with `--llvm=13.0.0`, `--cmake=true`, `--ninja=true`, and `--vcvarsall=true`. This will set up LLVM 13.0.0 and the proper environment variables.

# Usage

```d
import d_tree_sitter;
```

# License

Copyright © 2021, Amin Yahyaabadi

Licensed under the Apache-2.0 License.
