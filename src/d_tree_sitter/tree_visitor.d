module tree_visitor;

extern (C):

import tree_cursor;

/** An interface that describes the minimum functions that a visitor requires */
interface TreeVisitor
{
  /**
    A function that is called before the children of a node are visited
    If this function returns `false` the visiting will of the children will be skipped.

    NOTE: If the `cursor` is modified (e.g. by calling `cursor.children(&cursor)`),
    the visiting is affected. If not desired, copy the cursor using `TreeCursor(cursor)` before modifying it.
  */
  bool enter_node(TreeCursor* cursor);

  /** A function that is called after all the children nodes are visited */
  void leave_node(TreeCursor* cursor);
}
