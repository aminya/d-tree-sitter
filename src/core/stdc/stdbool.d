// Provided manually because of https://github.com/dlang/druntime/pull/3489

/**
 * D header file for C99.
 *
 * Source:    $(DRUNTIMESRC core/stdc/stdbool.d)
 * Standards: ISO/IEC 9899:1999 (E)
 */
module core.stdc.stdbool;

extern (C):
@safe: // Types and constants only.
nothrow:
@nogc:

/**
  bool is already defined in D
  true is already defined in D
  false is already defined in D
*/
enum __bool_true_false_are_defined = 1;
