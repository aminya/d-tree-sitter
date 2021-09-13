module language;

extern (C):

import std.exception : enforce;
import std.string : fromStringz, toStringz;

/**
  An opaque object that defines how to parse a particular language. The code for each
  `Language` is gen by the Tree-sitter CLI.
*/
struct Language
{
  import libc : TSLanguage, ts_language_version,
    ts_language_symbol_count, ts_language_symbol_name, ts_language_symbol_for_name,
    ts_language_symbol_type, TSSymbolType, ts_language_field_count,
    ts_language_field_name_for_id, ts_language_field_id_for_name;

  /** internal TSLanguage */
  const TSLanguage* tslanguage;

  /** create a new Language. */
  this(const TSLanguage* tslanguage) @nogc nothrow
  {
    assert(tslanguage != null, "The given tslanguage is null");
    this.tslanguage = tslanguage;
  }

  /**
   Get the ABI version number that indicates which version of the Tree-sitter CLI
   that was used to generate this `Language`.
  */
  auto get_version() @nogc nothrow
  {
    return ts_language_version(tslanguage);
  }

  /** Get the number of distinct node types in language. */
  auto node_kind_count() @nogc nothrow
  {
    return ts_language_symbol_count(tslanguage);
  }

  /** Get the name of the node kind for the given numerical id. */
  auto node_kind_for_id(ushort id) @nogc nothrow
  {
    auto ptr = ts_language_symbol_name(tslanguage, id);
    return fromStringz(ptr);
  }

  /** Get the numeric id for the given node kind. */
  auto id_for_node_kind(string kind, bool named)
  {
    auto kind_len = cast(uint) kind.length;
    auto kind_c = toStringz(kind);
    return ts_language_symbol_for_name(tslanguage, kind_c, kind_len, named);
  }

  /**
    Check if the node type for the given numerical id is named (as opposed
    to an anonymous node type).
  */
  auto node_kind_is_named(ushort id) @nogc nothrow
  {
    return ts_language_symbol_type(tslanguage, id) == TSSymbolType.TSSymbolTypeRegular;
  }

  /**
    Check if the node type for the given numerical id is anonymous (as opposed
    to a named node type).
  */
  auto node_kind_is_visible(ushort id) @nogc nothrow
  {
    return ts_language_symbol_type(tslanguage, id) <= TSSymbolType.TSSymbolTypeAnonymous;
  }

  /** Get the number of distinct field names in this language. */
  auto field_count() @nogc nothrow
  {
    return ts_language_field_count(tslanguage);
  }

  /** Get the field names for the given numerical id. */
  auto field_name_for_id(ushort field_id) @nogc nothrow
  {
    auto ptr = ts_language_field_name_for_id(tslanguage, field_id);
    return fromStringz(ptr);
  }

  /** Get the numerical id for the given field name. */
  auto field_id_for_name(string field_name)
  {
    auto field_name_len = cast(uint) field_name.length;
    auto field_name_c = toStringz(field_name);
    auto id = ts_language_field_id_for_name(tslanguage, field_name_c, field_name_len,);
    enforce(id != 0, "numerical id for the given field name is 0.");
    return id;
  }
}
