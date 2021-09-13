module d_tree_sitter.d_tree_sitter;

extern (C):

// TODO some of the doc strings are copied from the C code and may not match the parameters

public import d_tree_sitter.language;
public import d_tree_sitter.tree;
public import d_tree_sitter.parser;
public import d_tree_sitter.tree_cursor;
public import d_tree_sitter.tree_visitor;
public import d_tree_sitter.tree_printer;
public import d_tree_sitter.node;
public import d_tree_sitter.other;

// export the libc symbols under libc namespace
public import libc = d_tree_sitter.libc;
