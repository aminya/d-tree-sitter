module other;

extern (C):

import libc : TSPoint;

/**
  A position in a multi-line text document, in terms of rows and columns.

  Rows and columns are zero-based.

  NOTE this directly uses the C's TSPoint.
*/
alias Point = TSPoint;

/** Check the equality of two points */
bool opEqualsPoints(const Point lhs, const Point rhs) @nogc @safe nothrow
{
  return lhs.row == rhs.row && rhs.column == rhs.column;
}

import libc : TSRange;

/**
  A range of positions in a multi-line text document, both in terms of bytes and of
  rows and columns.

  NOTE this directly uses the C's TSRange. This means that the order of the arguments
  for the constructor of Range is different than what the Rust bindings use.
*/
alias Range = TSRange;

/** Check the equality of two ranges */
bool opEqualsRanges(const Range lhs, const Range rhs) @nogc @safe nothrow
{
  return lhs.start_point.opEqualsPoints(rhs.start_point) && lhs.end_point.opEqualsPoints(
      rhs.end_point);
}

import libc : TSInputEdit;

/**  A summary of a change to a text document.

  NOTE this directly uses the C's TSInputEdit.
*/
alias InputEdit = TSInputEdit;
