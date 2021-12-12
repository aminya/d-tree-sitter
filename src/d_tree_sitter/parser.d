module parser;

extern (C):

import language;
import tree;
import tree_visitor;
import tree_printer;
import libc : TSTree;

import std.typecons : Nullable;
import std.format : format;
import std.string : fromStringz, toStringz;

/** A stateful object that this is used to produce a `Tree` based on some source code */
struct Parser
{
  import libc : TSParser, ts_parser_new, ts_parser_delete,
    ts_parser_language, ts_parser_set_language, ts_parser_logger, TSLogger,
    ts_parser_print_dot_graphs, ts_parser_parse, ts_parser_parse_string,
    ts_parser_parse_string_encoding, TSInput, TSInputEncoding;
  import std.stdio : File;

  /** internal TSParser */
  TSParser* tsparser;

  /** Create a new Parser for the given language.
      NOTE: It assumes that the language is compatible (uses `set_language_nothrow`).
      Params:
        language = the language you want to create a parser for
  */
  this(in Language language) nothrow @nogc
  {
    // Create a parser.
    this.tsparser = ts_parser_new();

    // Set the parser's language.
    const success = this.set_language_nothrow(language);
    assert(success);
  }

  @disable this();
  @disable this(this);

  ~this() @nogc nothrow
  {
    stop_printing_dot_graphs();
    ts_parser_delete(this.tsparser);
  }

  /**
   * Set the language that the parser should use for parsing.
   *
   * NOTE it assumes that the language is compatible. Returns a boolean indicating whether or not the language was successfully
   * assigned.
   */
  auto set_language_nothrow(in Language language) nothrow
  {
    return ts_parser_set_language(tsparser, language.tslanguage);
  }

  /**
   * Set the language that the parser should use for parsing.
   *
   * Returns a boolean indicating whether or not the language was successfully
   * assigned. True means assignment succeeded. False means there was a version
   * mismatch, the language was gen with an incompatible version of the
   * Tree-sitter CLI. Check the language's version using `ts_language_version`
   * and compare it to this library's `TREE_SITTER_LANGUAGE_VERSION` and
   * `TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION` constants.
   */
  auto set_language(in Language language)
  {
    // TODO make set_language private?
    enforce_compatible_language(language);
    return ts_parser_set_language(tsparser, language.tslanguage);
  }

  /** Throws an error if the version of the given language is not compatible */
  void enforce_compatible_language(Language language) const
  {
    import libc : TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION,
      TREE_SITTER_LANGUAGE_VERSION;

    auto language_version = language.get_version();
    if (language_version < TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION
        || language_version > TREE_SITTER_LANGUAGE_VERSION)
    {
      throw new Exception(
          format!"Incompatible language version %d. Expected minimum %d, maximum %d"(language_version,
          TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION, TREE_SITTER_LANGUAGE_VERSION));
    }
  }

  /** Get the parser's current language. */
  auto language() const @nogc nothrow
  {
    auto ptr = ts_parser_language(tsparser);
    if (!ptr)
    {
      return Nullable!Language.init;
    }
    return Nullable!Language(Language(ptr));
  }

  /** Get the parser's current logger. */
  TSLogger* logger() const @nogc nothrow
  {
    auto logger = ts_parser_logger(tsparser);
    return cast(TSLogger*) logger.payload;
  }

  // TODO
  // set_logger

  /**
    Set the destination to which the parser should write debugging graphs
    during parsing. The graphs are formatted in the DOT language. You may want
    to pipe these graphs directly to a `dot(1)` process in order to generate
    SVG output.
  */
  auto print_dot_graphs(File file)
  {
    // TODO is file.fileno a raw fd?!
    return ts_parser_print_dot_graphs(tsparser, file.fileno());
  }

  /** Stop the parser from printing debugging graphs while parsing. */
  auto stop_printing_dot_graphs() @nogc nothrow
  {
    return ts_parser_print_dot_graphs(tsparser, -1);
  }

  /**
    Use the parser to parse some source code and create a syntax tree.

    If you are parsing this document for the first time, pass `NULL` for the
    `old_tree` parameter. Otherwise, if you have already parsed an earlier
    version of this document and the document has since been edited, pass the
    previous syntax tree so that the unchanged parts of it can be reused.
    This will save time and memory. For this to work correctly, you must have
    already edited the old syntax tree using the `ts_tree_edit` function in a
    way that exactly matches the source code changes.

    The `TSInput` parameter lets you specify how to read the text. It has the
    following three fields:
    1. `read`: A function to retrieve a chunk of text at a given byte offset
       and (row, column) position. The function should return a pointer to the
       text and write its length to the `bytes_read` pointer. The parser does
       not take ownership of this buffer; it just borrows it until it has
       finished reading it. The function should write a zero value to the
       `bytes_read` pointer to indicate the end of the document.
    2. `payload`: An arbitrary pointer that will be passed to each invocation
       of the `read` function.
    3. `encoding`: An indication of how the text is encoded. Either
       `TSInputEncodingUTF8` or `TSInputEncodingUTF16`.

    This function returns a syntax tree on success, and `NULL` on failure. There
    are three possible reasons for failure:
    1. The parser does not have a language assigned. Check for this using the
      `ts_parser_language` function.
    2. Parsing was cancelled due to a timeout that was set by an earlier call to
       the `ts_parser_set_timeout_micros` function. You can resume parsing from
       where the parser left out by calling `ts_parser_parse` again with the
       same arguments. Or you can start parsing from scratch by first calling
       `ts_parser_reset`.
    3. Parsing was cancelled using a cancellation flag that was set by an
       earlier call to `ts_parser_set_cancellation_flag`. You can resume parsing
       from where the parser left out by calling `ts_parser_parse` again with
       the same arguments.
   */
  auto parse(TSInput input, const TSTree* old_tree = Tree.create_empty()) @nogc nothrow
  {
    return ts_parser_parse(tsparser, old_tree, input);
  }

  /**
    Use the parser to parse some source code stored in one contiguous buffer.
    The first two parameters are the same as in the `ts_parser_parse` function
    above. The second two parameters indicate the location of the buffer and its
    length in bytes.
   */
  auto parse(const string source_code, const TSTree* old_tree = Tree.create_empty()) nothrow
  {
    // convert to c string
    const source_code_c = toStringz(source_code);
    const source_code_length = cast(uint)(source_code.length);
    return ts_parser_parse_string(tsparser, old_tree, source_code_c, source_code_length);
  }

  /**
    Use the parser to parse some source code stored in one contiguous buffer with
    a given encoding. The first four parameters work the same as in the
    `ts_parser_parse_string` method above. The final parameter indicates whether
    the text is encoded as UTF8 or UTF16.
   */
  auto parse(const string source_code, const TSInputEncoding encoding,
      const TSTree* old_tree = Tree.create_empty()) nothrow
  {
    // convert to c string
    const source_code_c = toStringz(source_code);
    const source_code_length = cast(uint)(source_code.length);
    return ts_parser_parse_string_encoding(tsparser, old_tree, source_code_c,
        source_code_length, encoding);
  }

  /**
    Parse the given source_code that is in utf8 encoding
  */
  auto parse_utf8(const string source_code, const TSTree* old_tree = Tree.create_empty()) nothrow
  {
    return parse(source_code, TSInputEncoding.TSInputEncodingUTF8, old_tree);
  }

  /**
    Parse the given source_code that is in utf16 encoding
  */
  auto parse_utf16(const wstring source_code, const TSTree* old_tree = Tree.create_empty()) nothrow @nogc
  {
    // TODO is this correct?
    // convert to c string
    const source_code_c = cast(const char*)(source_code);
    const source_code_length = cast(uint)(source_code.length);
    return ts_parser_parse_string_encoding(tsparser, old_tree, source_code_c,
        source_code_length, TSInputEncoding.TSInputEncodingUTF16);
  }

  /**
    Parse the given source_code into a Tree
  */
  Tree parse_to_tree(const string source) nothrow
  {
    return Tree(parse(source));
  }

  /**
        Get the S-expression of the given source code
        Params:
            source_code =     the given source code as a string
        Returns: the parsed S-expression
       */
  auto s_expression(const string source_code) nothrow
  {
    auto tree = parse_to_tree(source_code);

    // Get the root node of the syntax tree.
    auto root_node = tree.root_node();

    // Print the syntax tree as an S-expression.
    return root_node.to_string();
  }

  /**
    Traverse the [Tree] starting from its root [Node] applying a visitor at all nodes.
  */
  void traverse(const string source_code, TreeVisitor visitor)
  {
    auto tree = parse_to_tree(source_code);

    // Get the root node of the syntax tree.
    auto root_node = tree.root_node();

    root_node.traverse(visitor);
  }

  /**
    Traverse the `Tree` starting from its root `Node` and print information about each
  */
  string traverse_print(const string source_code) @trusted
  {
    auto tree = parse_to_tree(source_code);

    // Get the root node of the syntax tree.
    auto root_node = tree.root_node();

    // a visitor to print information
    auto visitor = new TreePrinter(source_code);

    root_node.traverse(visitor);

    return cast(string) visitor.tree_string; // convert bc.string.String to string
  }
}
