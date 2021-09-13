module tree;

extern (C):

import language;
import node;
import tree_visitor;
import other;
import libc : TSTree;

/** A tree that represents the syntactic structure of a source code file. */
struct Tree
{
  import libc : ts_tree_delete, ts_tree_root_node, ts_tree_language,
    ts_tree_edit, ts_tree_get_changed_ranges, ts_tree_copy, ts_tree_print_dot_graph;

  import std.stdio : File;

  /** internal TsTree */
  TSTree* tstree;

  /** Create a new Tree */
  this(TSTree* tstree) @nogc nothrow
  {
    assert(tstree != null, "The given tstree is null");
    this.tstree = tstree;
  }

  ~this() @nogc nothrow
  {
    ts_tree_delete(this.tstree);
  }

  /**
   * Create a shallow copy of the syntax tree. This is very fast.
   *
   * You need to copy a syntax tree in order to use it on more than one thread at
   * a time, as syntax trees are not thread safe.
   */
  this(ref return scope Tree otherTree) @nogc nothrow
  {
    this.tstree = ts_tree_copy(otherTree.tstree);
  }

  /// ditto
  this(ref return scope inout Tree otherTree) @nogc nothrow inout
  {
    this.tstree = cast(inout(TSTree*)) ts_tree_copy(otherTree.tstree);
  }

  @disable this(this); // disable postblit

  /** Create an empty Tree */
  static auto create_empty() @nogc nothrow
  {
    return cast(const(TSTree)*) null;
  }

  /**  Get the root node of the syntax tree. */
  auto root_node() const @nogc nothrow
  {
    return Node(ts_tree_root_node(tstree));
  }

  /**  Get the language that was used to parse the syntax tree. */
  auto language() const @nogc nothrow
  {
    return Language(ts_tree_language(tstree));
  }

  /** Edit the syntax tree to keep it in sync with source code that has been
      edited.

      You must describe the edit both in terms of byte offsets and in terms of
      row/column coordinates.
  */
  auto edit(const InputEdit* edit) @nogc nothrow
  {
    return ts_tree_edit(tstree, edit);
  }

  /**  Create a new [TreeCursor] starting from the root of the tree. */
  auto walk() const @nogc nothrow
  {
    return root_node().walk();
  }

  /**
    Traverse the [Tree] starting from its root [Node] applying a visitor at all nodes.
  */
  void traverse(TreeVisitor visitor) const
  {
    root_node().traverse(visitor);
  }

  /**
    Traverse the [Tree] starting from its root [Node] applying a visitor at all nodes.

    NOTE: if you are sure that TreeVisitor is nothrow, you can use this method
  */
  void traverse_nothrow(TreeVisitor visitor) const
  {
    root_node().traverse_nothrow(visitor);
  }

  /**  Compare this old edited syntax tree to a new syntax tree representing the same
      document, returning a sequence of ranges whose syntactic structure has changed.

      For this to work correctly, this syntax tree must have been edited such that its
      ranges match up to the new tree. Generally, youl want to call this method right
      after calling one of the [Parser::parse] functions. Call it on the old tree that
      was passed to parse, and pass the new tree that was returned from `parse`.
  */
  auto changed_ranges(Tree other) const nothrow
  {
    auto count = 0u;
    const auto ptr = ts_tree_get_changed_ranges(tstree, other.tstree, &count);
    // TODO ptr is not freed!
    // TODO is there a better way to convert this to an array?
    Range[] ranges;
    ranges.reserve(count);
    for (auto iptr = 0u; iptr < count; iptr++)
    {
      ranges[iptr] = *(ptr + iptr);
    }
    return ranges;
  }

  /**
   * Write a DOT graph describing the syntax tree to the given file.
   */
  void print_dot_graph(File file) const
  {
    ts_tree_print_dot_graph(tstree, file.getFP);
  }

  /**
    Get a DOT graph describing the syntax tree as a string
   */
  auto dot_graph() const
  {
    import std.file : readText, tempDir;
    import std.path : buildPath;

    // TODO do we need to create a temp file?
    const fileName = buildPath(tempDir(), "tree_sitter_dot_graph.txt");
    auto file = File(fileName, "w");
    print_dot_graph(file);
    file.close();
    return readText(fileName);
  }
}
