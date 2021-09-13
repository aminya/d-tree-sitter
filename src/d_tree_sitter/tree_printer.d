module tree_printer;

extern (C):

import tree_visitor;
import tree_cursor;
import bc.string : String, nogcFormat;

/** visit all the nodes and get information about each
    Params:
        source_code =     the given source code as a string
*/
final class TreePrinter : TreeVisitor
{
  private const string source_code;

  /** the information about the tree as a string */
  String tree_string = "";

  /** create a TreePrinter using the source code */
  this(const string source_code) @nogc nothrow
  {
    this.source_code = source_code;
  }

  /**
    A function that gets the information about a node
  */
  bool enter_node(TreeCursor* cursor) @trusted
  {
    import std.stdio : writeln;
    import std.string : representation;

    auto child = cursor.node();
    tree_string ~= nogcFormat!"\n%s\n\t%s"(child.utf8_text(source_code.representation()
        .dup), child.to_string());
    return true;
  }

  /** A function that is called after all the children nodes are visited */
  void leave_node(TreeCursor* cursor) const @nogc nothrow
  { /* no operation */ }
}
