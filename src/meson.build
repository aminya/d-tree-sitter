project(
    'tree_sitter',
    ['c'],
    meson_version   : '>=0.55.0'
)

tree_sitter_lib = static_library(
    'tree_sitter',
    ['./gen/tree-sitter/lib/src/lib.c'],
    include_directories: include_directories('./gen/tree-sitter/lib/include', './gen/tree-sitter/lib/src')
)
