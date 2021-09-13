# d-tree-sitter

[![CI](https://github.com/aminya/d-tree-sitter/actions/workflows/CI.yml/badge.svg)](https://github.com/aminya/d-tree-sitter/actions/workflows/CI.yml)

The D bindings for tree-sitter, a library for incremental parsing.

# Build
You need to have [meson](https://mesonbuild.com/SimpleStart.html#installing-meson) installed and have it on the path. This is required for building the C library. Then just run:

```ps1
dub build
```

See [the GitHub Actions config](https://github.com/aminya/d-tree-sitter/blob/master/.github/workflows/CI.yml) for a reproducible setup used to build d-tree-sitter.

# Usage
```d
import d_tree_sitter;
```

# License

Copyright © 2021, Amin Yahyaabadi

Licensed under the Apache-2.0 License.