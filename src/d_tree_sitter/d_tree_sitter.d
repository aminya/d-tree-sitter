module d_tree_sitter;

extern (C):

// TODO some of the doc strings are copied from the C code and may not match the parameters

public import language;
public import tree;
public import parser;
public import tree_cursor;
public import tree_visitor;
public import tree_printer;
public import node;
public import other;
public import query;

// export the libc symbols under libc namespace
public import libc = libc;
