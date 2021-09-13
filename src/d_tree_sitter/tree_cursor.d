module tree_cursor;

extern (C):

import node;

import std.exception : enforce;
import std.string : fromStringz;

/// A stateful object for walking a syntax `Tree` efficiently.
struct TreeCursor
{
  import libc : TSTreeCursor, ts_tree_cursor_copy,
    ts_tree_cursor_current_node, ts_tree_cursor_current_field_id,
    ts_tree_cursor_current_field_name, ts_tree_cursor_goto_first_child,
    ts_tree_cursor_goto_parent,
    ts_tree_cursor_goto_next_sibling, ts_tree_cursor_goto_first_child_for_byte,
    ts_tree_cursor_reset, ts_tree_cursor_delete;

  /** internal `TSTreeCursor` */
  TSTreeCursor tstreecursor;

  /** Create a new tree cursor */
  this(TSTreeCursor tstreecursor) @nogc nothrow
  {
    this.tstreecursor = tstreecursor;
  }

  ~this() @nogc nothrow
  {
    return ts_tree_cursor_delete(&tstreecursor);
  }

  /** Copy a tree cursor */
  this(ref return scope TreeCursor otherTreeCursor) @nogc nothrow
  {
    this.tstreecursor = ts_tree_cursor_copy(&otherTreeCursor.tstreecursor);
  }

  /** Copy a tree cursor */
  this(TreeCursor* otherTreeCursor) @nogc nothrow
  {
    this.tstreecursor = ts_tree_cursor_copy(&otherTreeCursor.tstreecursor);
  }

  @disable this(this); // disable postblit

  /** Get the tree cursor's current [Node]. */
  auto node() const @nogc nothrow
  {
    return Node(ts_tree_cursor_current_node(&tstreecursor));
  }

  /**
    Get the numerical field id of this tree cursor's current node.

    See also [field_name](TreeCursor::field_name).
  */
  auto field_id() const @nogc
  {
    auto id = ts_tree_cursor_current_field_id(&tstreecursor);
    assert(id != 0, "id is 0.");
    return id;
  }

  /** Get the field name of this tree cursor's current node. */
  auto field_name() const @nogc nothrow
  {
    return fromStringz(ts_tree_cursor_current_field_name(&tstreecursor));
  }

  /**
    Move this cursor to the first child of its current node.

    This returns `true` if the cursor successfully moved, and returns `false`
    if there were no children.
  */
  auto goto_first_child() @nogc nothrow
  {
    return ts_tree_cursor_goto_first_child(&tstreecursor);
  }

  /**
    Move this cursor to the parent of its current node.

    This returns `true` if the cursor successfully moved, and returns `false`
    if there was no parent node (the cursor was already on the root node).
  */
  auto goto_parent() @nogc nothrow
  {
    return ts_tree_cursor_goto_parent(&tstreecursor);
  }

  /**
     Move this cursor to the next sibling of its current node.

     This returns `true` if the cursor successfully moved, and returns `false`
     if there was no next sibling node.
  */
  auto goto_next_sibling() @nogc nothrow
  {
    return ts_tree_cursor_goto_next_sibling(&tstreecursor);
  }

  /**
    Move this cursor to the first child of its current node that extends beyond
    the given byte offset.

    This returns the index of the child node if one was found, and returns `None`
    if no such child was found.
  */
  auto goto_first_child_for_byte(size_t index)
  {
    auto result = ts_tree_cursor_goto_first_child_for_byte(&tstreecursor, cast(uint) index);
    enforce(result >= 0, "result is less than 0.");
    return result;
  }

  /** Re-initialize this tree cursor to start at a different node. */
  auto reset(Node node) @nogc nothrow
  {
    return ts_tree_cursor_reset(&tstreecursor, node.tsnode);
  }
}
