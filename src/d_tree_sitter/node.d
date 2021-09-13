module node;

extern (C):

import language;
import tree_cursor;
import tree_visitor;
import other;

import std : iota, Nullable;
import std.string : fromStringz, toStringz;

/** A single `Node` within a syntax `Tree`. */
struct Node
{
  import libc : TSNode, ts_node_symbol, ts_node_type, ts_tree_language,
    ts_node_is_named, ts_node_is_extra, ts_node_has_changes, ts_node_has_error,
    ts_node_is_missing, ts_node_start_byte, ts_node_end_byte,
    ts_node_start_point, ts_node_end_point, ts_node_child, ts_node_child_count,
    ts_node_named_child, ts_node_named_child_count, ts_node_child_by_field_name,
    ts_node_child_by_field_id, ts_node_parent, ts_node_next_sibling, ts_node_prev_sibling,
    ts_node_next_named_sibling,
    ts_node_prev_named_sibling,
    ts_node_descendant_for_byte_range,
    ts_node_named_descendant_for_byte_range,
    ts_node_descendant_for_point_range, ts_node_named_descendant_for_point_range,
    ts_node_string, ts_tree_cursor_new, ts_node_edit, ts_node_is_null;

  /** The internal `TSNode` */
  TSNode tsnode;

  /** Create a new Node.
    Throws:
      If the passed tsnode is null, it will trigger an error in the debug mode.
  */
  this(TSNode tsnode) @nogc nothrow
  {
    debug
    {
      assert(!ts_node_is_null(tsnode), "The given tsnode is null");
    }
    this.tsnode = tsnode;
  }

  /**  Creates a new Node from the given nullable TSNode

    Params:
      tsnode = a C tsnode, which can be a `null` node.

    Returns:
      a `Nullable!Node`, which gives the node if it is not a `null` node, and `null` if it is.
  */
  static Nullable!Node create(TSNode tsnode) @trusted @nogc nothrow
  {
    if (!ts_node_is_null(tsnode))
    {
      return Nullable!Node(Node(tsnode));
    }
    else
    {
      return Nullable!Node.init;
    }
  }

  /** Check if the Node is a `null` node.

    Note:
      this function should be only used when creating a `Node` with its constructor in the release mode (instead of using `Node.create`).
      All the methods of `Node` already use `Node.create` and return a `Nullable!Node`.
  */
  bool isNull()
  {
    return ts_node_is_null(tsnode);
  }

  /**
    Get a numeric id for this node that is unique.

    Within a given syntax tree, no two nodes have the same id. However, if
    a new tree is created based on an older tree, and a node from the old
    tree is reused in the process, then that node will have the same id in
    both trees.
  */
  auto id() const @nogc nothrow
  {
    return tsnode.id;
  }

  /** Get this node's type as a numerical id. */
  auto kind_id() const @nogc nothrow
  {
    return ts_node_symbol(tsnode);
  }

  /** Get this node's type as a string. */
  auto kind() const @nogc nothrow
  {
    return fromStringz(ts_node_type(tsnode));
  }

  /** Get the [Language] that was used to parse this node's syntax tree. */
  auto language() const @nogc nothrow
  {
    return Language(ts_tree_language(tsnode.tree));
  }

  /**
    Check if this node is *named*.

    Named nodes correspond to named rules in the grammar, whereas *anonymous* nodes
    correspond to string literals in the grammar.
  */
  auto is_named() const @nogc nothrow
  {
    return ts_node_is_named(tsnode);
  }

  /**
    Check if this node is *extra*.

    Extra nodes represent things like comments, which are not required the grammar,
    but can appear anywhere.
  */
  auto is_extra() const @nogc nothrow
  {
    return ts_node_is_extra(tsnode);
  }

  /**
    Check if this node has been edited
  */
  auto has_changes() const @nogc nothrow
  {
    return ts_node_has_changes(tsnode);
  }

  /**
    Check if this node represents a syntax error or contains any syntax errors anywhere
    within it.
  */
  auto has_error() const @nogc nothrow
  {
    return ts_node_has_error(tsnode);
  }

  /**
    Check if this node represents a syntax error.

    Syntax errors represent parts of the code that could not be incorporated into a
    valid syntax tree.
  */
  auto is_error() const @nogc nothrow
  {
    return kind_id() == ushort.max;
  }

  /**
    Check if this node is *missing*.

    Missing nodes are inserted by the parser in order to recover from certain kinds of
    syntax errors.
  */
  auto is_missing() const @nogc nothrow
  {
    return ts_node_is_missing(tsnode);
  }

  /**
    Get the byte offsets where this node starts
  */
  auto start_byte() const @nogc nothrow
  {
    return ts_node_start_byte(tsnode);
  }

  /**
    Get the byte offsets where this node end.
  */
  auto end_byte() const @nogc nothrow
  {
    return ts_node_end_byte(tsnode);
  }

  /**
    Get the byte range of source code that this node represents.
  */
  auto byte_range() const @nogc nothrow
  {
    return iota(start_byte(), end_byte());
  }

  /**
    Get this node's start position in terms of rows and columns.
  */
  auto start_position() const @nogc nothrow
  {
    return ts_node_start_point(tsnode);
  }

  /**
    Get this node's end position in terms of rows and columns.
  */
  auto end_position() const @nogc nothrow
  {
    return ts_node_end_point(tsnode);
  }

  /**
    Get the range of source code that this node represents, both in terms of raw bytes
    and of row/column coordinates.
  */
  auto range() const @nogc nothrow
  {
    return Range(start_position(), end_position(), start_byte(), end_byte());
  }

  /**
    Get the node's child at the given index, where zero represents the first
    child.

    This method is fairly fast, but its cost is technically log(child_index), so you
    if you might be iterating over a long list of children, you should use
    [Node::children] instead.

    Returns:
      A `Nulllable!Node`
  */
  auto child(size_t child_index) const @nogc nothrow
  {
    return Node.create(ts_node_child(tsnode, cast(uint)(child_index)));
  }

  /**
    Get this node's number of children
  */
  auto child_count() const @nogc nothrow
  {
    return ts_node_child_count(tsnode);
  }

  /**
    Get this node's *named* child at the given index.

    See also [Node::is_named].
    This method is fairly fast, but its cost is technically log(i), so you
    if you might be iterating over a long list of children, you should use
    [Node::named_children] instead.

    Returns:
      A `Nulllable!Node`
  */
  auto named_child(size_t i) const @nogc nothrow
  {
    return Node.create(ts_node_named_child(tsnode, cast(uint)(i)));
  }

  /**
    Get this node's number of *named* children.

    See also [Node::is_named].
  */
  auto named_child_count() const @nogc nothrow
  {
    return ts_node_named_child_count(tsnode);
  }

  /**
    Get the first child with the given field name.

    If multiple children may have the same field name, access them using
    [children_by_field_name](Node::children_by_field_name)

    Returns:
      A `Nulllable!Node`
  */
  auto child_by_field_name(string field_name) const
  {
    // convert to c string
    auto field_name_c = toStringz(field_name);
    auto field_name_length = cast(uint)(field_name.length);
    return Node.create(ts_node_child_by_field_name(tsnode, field_name_c, field_name_length));
  }

  /**
    Get the first child with the given field name.

    If multiple children may have the same field name, access them using
    [children_by_field_name](Node::children_by_field_name)

    Returns:
      A `Nulllable!Node`
  */
  auto child_by_field_id(ushort field_id) const @nogc nothrow
  {
    return Node.create(ts_node_child_by_field_id(tsnode, field_id));
  }

  /**  Iterate over this node children.

      A [TreeCursor] is used to retrieve the children efficiently. Obtain
      a [TreeCursor] by calling [Tree::walk] or [Node::walk]. To avoid unnecessary
      allocations, you should reuse the same cursor for subsequent calls to
      this method.

      If you're walking the tree recursively, you may want to use the `TreeCursor`
      APIs directly instead.
  */
  auto children(TreeCursor* cursor) const @nogc nothrow
  {
    return NodeChildren(this, cursor);
  }

  /**  Iterate over this node named children.

      See also [Node::children].
  */
  auto named_children(TreeCursor* cursor) const @nogc nothrow
  {
    return NodeNamedChildren(this, cursor);
  }

  /**  Iterate over this node children with a given field id.

      See also [Node::children_by_field_name].
  */
  auto children_by_field_id(ushort field_id, TreeCursor* cursor) const @nogc nothrow
  {
    return NodeChildrenByFieldID(this, field_id, cursor);
  }

  /**  Iterate over this node children with a given field name.

      See also [Node::children].
  */
  auto children_by_field_name(string field_name, TreeCursor* cursor) const
  {
    auto field_id = language().field_id_for_name(field_name);
    return children_by_field_id(field_id, cursor);
  }

  /** Check if the node has a immediate parent
    Note:
     `parent` method already does this check
  */
  auto has_parent() const @nogc nothrow
  {
    auto maybe_parent = ts_node_parent(tsnode);
    return !ts_node_is_null(maybe_parent);
  }

  /**  Get this node immediate parent.

    Returns:
      a `Nullable!Node`, which gives the parent node if it has a parent, and `null` if the node has no parent.
  */
  auto parent() const @nogc nothrow
  {
    return Node.create(ts_node_parent(tsnode));
  }

  /** Find the nth parent of node. It goes up until it hits a null parent or `max_nth`.
    Params:
      node = the node
      max_nth = the maximum level to go up.
    Returns:
      A node. If the given node doesn't have a parent, it returns the node itself.
    Note: the nth might not be reached if there are no more parents.
  */
  auto nth_parent(in uint max_nth = 2) @nogc nothrow @trusted const
  {
    auto maybeFirstParent = this.parent();
    if (maybeFirstParent.isNull())
    {
      // return the node itself
      return this;
    }
    auto parent = maybeFirstParent.get();

    uint nth = 1;
    while (nth != max_nth)
    {
      auto maybe_parent = parent.parent();
      if (!maybe_parent.isNull())
      {
        parent = maybe_parent.get();
      }
      else
      {
        break;
      }
      ++nth;
    }
    return parent;
  }

  /** Check if the node has a next sibling.
    Note:
     `next_sibling` method already does this check
  */
  auto has_next_sibling() const @nogc nothrow
  {
    auto maybeNode = ts_node_next_sibling(tsnode);
    return !ts_node_is_null(maybeNode);
  }

  /**  Get this node next sibling.
    Returns:
      A `Nulllable!Node`
  */
  auto next_sibling() const @nogc nothrow
  {
    return Node.create(ts_node_next_sibling(tsnode));
  }

  /** Check if the node has a previous sibling.
    Note:
     `prev_sibling` method already does this check
  */
  auto has_prev_sibling() const @nogc nothrow
  {
    auto maybeNode = ts_node_prev_sibling(tsnode);
    return !ts_node_is_null(maybeNode);
  }

  /**  Get this node previous sibling.

    Returns:
      A `Nulllable!Node`
  */
  auto prev_sibling() const @nogc nothrow
  {
    return Node.create(ts_node_prev_sibling(tsnode));
  }

  /**  Get this node next named sibling.

    Returns:
      A `Nulllable!Node`
  */
  auto next_named_sibling() const @nogc nothrow
  {
    return Node.create(ts_node_next_named_sibling(tsnode));
  }

  /**  Get this node previous named sibling.

    Returns:
      A `Nulllable!Node`
   */
  auto prev_named_sibling() const @nogc nothrow
  {
    return Node.create(ts_node_prev_named_sibling(tsnode));
  }

  /**  Get the smallest node within this node that spans the given range.

    Returns:
      A `Nulllable!Node`
  */
  auto descendant_for_byte_range(uint start, uint end) const @nogc nothrow
  {
    return Node.create(ts_node_descendant_for_byte_range(tsnode, start, end));
  }

  /**  Get the smallest named node within this node that spans the given range.

    Returns:
      A `Nulllable!Node`
  */
  auto named_descendant_for_byte_range(uint start, uint end) const @nogc nothrow
  {
    return Node.create(ts_node_named_descendant_for_byte_range(tsnode, start, end));
  }

  /**  Get the smallest node within this node that spans the given range.

    Returns:
      A `Nulllable!Node`
  */
  auto descendant_for_point_range(Point start, Point end) const @nogc nothrow
  {
    return Node.create(ts_node_descendant_for_point_range(tsnode, start, end));
  }

  /**  Get the smallest named node within this node that spans the given range.

    Returns:
      A `Nulllable!Node`
  */
  auto named_descendant_for_point_range(Point start, Point end) const @nogc nothrow
  {
    return Node.create(ts_node_named_descendant_for_point_range(tsnode, start, end));
  }

  /** Convert Node to string */
  auto to_string() const nothrow
  {
    import core.memory : pureFree;

    auto c_string = ts_node_string(tsnode); // NOTE requires freeing the heap allocated string
    string str = fromStringz(c_string).dup; // TODO use automem instead of copying and freeing the original?
    pureFree(c_string);
    return str;
  }

  alias to_sexp = to_string;

  import std.string : assumeUTF;

  /** Convert Node to utf8 string */
  auto utf8_text(string source_code) const @nogc nothrow
  {
    import std : representation;

    const source = source_code.representation();
    return assumeUTF(source[start_byte() .. end_byte()]);
  }

  /// ditto
  auto utf8_text(ubyte[] source) const @nogc nothrow
  {
    return assumeUTF(source[start_byte() .. end_byte()]);
  }

  /** Convert Node to utf16 string */
  auto utf16_text(ushort[] source) const @nogc nothrow
  {
    return assumeUTF(source[start_byte() .. end_byte()]);
  }

  /**  Create a new [TreeCursor] starting from this node. */
  auto walk() const @nogc nothrow
  {
    return TreeCursor(ts_tree_cursor_new(tsnode));
  }

  /** Hash a node. This returns a unique string for this node. */
  auto hash() @trusted const @nogc
  {
    import bc.string : nogcFormat;

    return nogcFormat!"%d%d"(this.kind_id(), this.start_byte());
  }

  /**
    Traverse this `Node` and all its descendants in a top-down left to right manner while
    applying the visitor at each [Node].
  */
  void traverse(TreeVisitor visitor) const
  {
    auto cursor = walk();
    visitor.enter_node(&cursor);
    auto recurse = true;
    while (true)
    {
      if (recurse && cursor.goto_first_child())
      {
        recurse = visitor.enter_node(&cursor);
      }
      else
      {
        visitor.leave_node(&cursor);
        if (cursor.goto_next_sibling())
        {
          recurse = visitor.enter_node(&cursor);
        }
        else if (cursor.goto_parent())
        {
          recurse = false;
        }
        else
        {
          break;
        }
      }
    }
  }

  /**
    Traverse this `Node` and all its descendants in a top-down left to right manner while
    applying the visitor at each [Node].

    NOTE: if you are sure that TreeVisitor is nothrow, you can use this method
  */
  void traverse_nothrow(TreeVisitor visitor) const nothrow
  {
    import std : assumeWontThrow;

    assumeWontThrow(traverse(visitor));
  }

  /**  Edit this node to keep it in-sync with source code that has been edited.

      This function is only rarely needed. When you edit a syntax tree with the
      [Tree::edit] method, all of the nodes that you retrieve from the tree
      afterward will already reflect the edit. You only need to use [Node::edit]
      when you have a specific [Node] instance that you want to keep and continue
      to use after an edit.
  */
  auto edit(const InputEdit* edit) @nogc nothrow
  {
    return ts_node_edit(&tsnode, edit);
  }
}

/**  A range to iterate over the node children.

    A [TreeCursor] is used to retrieve the children efficiently. Obtain
    a [TreeCursor] by calling [Tree::walk] or [Node::walk]. To avoid unnecessary
    allocations, you should reuse the same cursor for subsequent calls to
    this method.

    If you're walking the tree recursively, you may want to use the `TreeCursor`
    APIs directly instead.
*/
struct NodeChildren
{
  private TreeCursor* cursor;

  private const uint count;
  private uint iChild = 0;

  /** create a NodeChildren for the given node and cursor */
  auto this(Node parent, TreeCursor* cursor) @nogc nothrow
  {
    this.cursor = cursor;

    cursor.reset(parent);
    cursor.goto_first_child();
    this.count = parent.child_count();
  }

  /** Get the current child */
  auto front() const @nogc nothrow
  {
    return cursor.node();
  }

  /** go to the next child */
  void popFront() @nogc nothrow
  {
    cursor.goto_next_sibling();
    iChild++;
  }

  /** Is it the end? */
  auto empty() const @nogc nothrow
  {
    return iChild == count;
  }
}

/**  A range the iterates over the node named children.

    See also [Node::children].
*/
struct NodeNamedChildren
{
  private TreeCursor* cursor;

  private const uint count;
  private uint iChild = 0;

  /** create a NodeNamedChildren for the given node and cursor */
  auto this(Node parent, TreeCursor* cursor) @nogc nothrow
  {
    this.cursor = cursor;

    cursor.reset(parent);
    cursor.goto_first_child();
    this.count = parent.named_child_count();
  }

  /** Finds the front node */
  private void preFront() @nogc nothrow
  {
    while (!cursor.node().is_named())
    {
      if (!cursor.goto_next_sibling())
      {
        break;
      }
    }
  }

  /**
    Get the current child
    NOTE Do not call this twice in a row without calling popFront and empty in between!
  */
  auto front() @nogc nothrow
  {
    preFront();
    return cursor.node();
  }

  /** go to the next child */
  void popFront() @nogc nothrow
  {
    cursor.goto_next_sibling();
    iChild++;
  }

  /** Is it the end? */
  auto empty() const @nogc nothrow
  {
    return iChild == count;
  }
}

/**  A range to iterate over the node children with a given field id.

    See also [Node::children_by_field_name].
*/
struct NodeChildrenByFieldID
{
  private TreeCursor* cursor;
  private ushort field_id;

  private bool noMoreNextSibiling = false;

  /** create a NodeChildrenByFieldID for the given node, field_id, and cursor */
  auto this(Node parent, ushort field_id, TreeCursor* cursor) @nogc nothrow
  {
    this.cursor = cursor;
    this.field_id = field_id;

    cursor.reset(parent);
    cursor.goto_first_child();
  }

  /** Finds the front node */
  private void preFront() @nogc nothrow
  {
    // find the node related to field_id
    while (cursor.field_id() != field_id)
    {
      popFront();
    }
  }

  /**
    Get the current child
    NOTE Do not call this twice in a row without calling popFront and empty in between!
  */
  auto front() @nogc nothrow
  {
    preFront();
    return cursor.node();
  }

  /** go to the next child */
  void popFront() @nogc nothrow
  {
    // check if this found field_id is the last one
    if (!cursor.goto_next_sibling())
    {
      // if no next sibiling then we are done finding
      noMoreNextSibiling = true;
    }
  }

  /** Is it the end? */
  auto empty() const @nogc nothrow
  {
    return noMoreNextSibiling;
  }
}
