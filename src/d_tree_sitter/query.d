module query;

import std.algorithm;
import std.array;
import std.conv;
import std.string;
import language;
import node;
import tree_visitor;
import other;
import libc : TSQuery, TSQueryError, TSQueryMatch, TSQueryCursor,
    TSQueryCapture, TSQueryPredicateStep;

struct QueryCapture
{
    Node node;
    int index;
    string name;
}

struct QueryMatch
{
    uint id;
    uint pattern_index;
    QueryCapture[] captures;
}

struct QueryIterator
{
    import libc : ts_query_cursor_new, ts_query_cursor_delete, ts_query_cursor_exec,
        ts_query_cursor_next_match, ts_query_cursor_set_byte_range,
        ts_query_cursor_set_point_range;

    Query* query;
    Node* node;

    private TSQueryCursor* cursor;
    private TSQueryMatch* match;

    @disable this(this);

    this(Query* query, Node* node)
    {
        this.query = query;
        this.node = node;
        cursor = ts_query_cursor_new();
        ts_query_cursor_exec(cursor, query.tsquery, node.tsnode);
    }

    this(Query* query, Node* node, uint min, uint max)
    {
        this(query, node);
        set_byte_range(min, max);
    }

    this(Query* query, Node* node, Point min, Point max)
    {
        this(query, node);
        set_point_range(min, max);
    }

    ~this()
    {
        ts_query_cursor_delete(cursor);
    }

    void set_byte_range(uint min, uint max)
    {
        ts_query_cursor_set_byte_range(cursor, min, max);
    }

    void set_point_range(Point min, Point max)
    {
        ts_query_cursor_set_point_range(cursor, min, max);
    }

    int opApply(scope int delegate(QueryMatch) dg)
    {
        TSQueryMatch match;
        int result = 0;
        while (ts_query_cursor_next_match(cursor, &match))
        {
            auto captures = match.captures[0 .. match.capture_count].map!(
                    (capture) => QueryCapture(Node(capture.node),
                    capture.index, query.captureName(capture))).array;
            result = dg(QueryMatch(match.id, match.pattern_index, captures));
            if (result)
                break;
        }
        return result;
    }
}

class QueryException : Exception
{
    TSQueryError error;
    this(TSQueryError error)
    {
        super("QueryException: " ~ error.to!string);
        this.error = error;
    }
}

struct Query
{
    import libc : ts_query_new, ts_query_delete, ts_query_pattern_count,
        ts_query_capture_count, ts_query_start_byte_for_pattern,
        ts_query_predicates_for_pattern,
        ts_query_step_is_definite,
        ts_query_capture_name_for_id,
        ts_query_disable_capture, ts_query_disable_pattern,
        ts_query_string_count, ts_query_string_value_for_id;

    TSQuery* tsquery;
    Language language;

    @disable this(this);

    this(Language language, string queryString)
    {
        import std.conv;

        this.language = language;
        uint errOffset = 0;
        TSQueryError errType;
        this.tsquery = ts_query_new(language.tslanguage, queryString.toStringz,
                queryString.length.to!uint, &errOffset, &errType);

        if (errOffset != 0)
        {
            throw new QueryException(errType);
        }
    }

    ~this()
    {
        ts_query_delete(tsquery);
    }

    QueryIterator exec(Node node)
    {
        return QueryIterator(&this, &node);
    }

    QueryIterator exec(Node node, uint min, uint max)
    {
        return QueryIterator(&this, &node, min, max);
    }

    QueryIterator exec(Node node, Point min, Point max)
    {
        return QueryIterator(&this, &node, min, max);
    }

    int pattern_count() @nogc nothrow
    {
        return ts_query_pattern_count(tsquery);
    }

    int capture_count() @nogc nothrow
    {
        return ts_query_capture_count(tsquery);
    }

    int string_count() @nogc nothrow
    {
        return ts_query_string_count(tsquery);
    }

    int start_byte_for_pattern(uint patternId) @nogc nothrow
    {
        return ts_query_start_byte_for_pattern(tsquery, patternId);
    }

    const(TSQueryPredicateStep)[] predicates_for_pattern(uint patternId) @nogc nothrow
    {
        uint len;
        auto ptr = ts_query_predicates_for_pattern(tsquery, patternId, &len);
        return ptr[0 .. len];
    }

    bool step_is_definite(uint byteOffset) @nogc nothrow
    {
        return ts_query_step_is_definite(tsquery, byteOffset);
    }

    string capture_name_for_id(uint captureId) nothrow
    {
        uint len;
        auto namePtr = ts_query_capture_name_for_id(tsquery, captureId, &len);
        return namePtr[0 .. len].to!string;
    }

    string capture_name(TSQueryCapture capture) nothrow
    {
        return capture_name_for_id(capture.index);
    }

    string query_string_value_for_id(uint id) nothrow
    {
        uint len;
        auto namePtr = ts_query_string_value_for_id(tsquery, id, &len);
        return namePtr[0 .. len].to!string;
    }

    void disable_capture(string captureName)
    {
        ts_query_disable_capture(tsquery, captureName.toStringz, captureName.length.to!uint);
    }

    void disable_pattern(uint patternId) @nogc nothrow
    {
        ts_query_disable_pattern(tsquery, patternId);
    }
}
