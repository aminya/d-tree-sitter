module query;

import std.algorithm;
import std.array;
import std.conv;
import std.string;
import language;
import node;
import tree_visitor;
import other;
import libc : TSQuery, TSQueryError, TSQueryMatch, TSQueryCursor, TSQueryCapture;

struct QueryCapture {
  Node node;
  int index;
  string name;
}

struct QueryMatch {
    uint id;
    uint pattern_index;
    QueryCapture[] captures;
}

struct QueryIterator {
    import libc : ts_query_cursor_new, ts_query_cursor_delete,
           ts_query_cursor_exec, ts_query_cursor_next_match;
    Query* query;
    Node* node;

    private TSQueryCursor* cursor;
    private TSQueryMatch* match;

    @disable this(this);

    this(Query* query, Node* node) {
        this.query = query;
        this.node = node;
        cursor = ts_query_cursor_new();
        ts_query_cursor_exec(cursor, query.tsquery, node.tsnode);
    }

    ~this() {
        ts_query_cursor_delete(cursor);
    }

    int opApply(scope int delegate(QueryMatch) dg) {
        TSQueryMatch match;
        int result = 0;
        while(ts_query_cursor_next_match(cursor, &match)) {
            auto captures = match
                .captures[0..match.capture_count]
                .map!((capture) =>
                    QueryCapture(
                        Node(capture.node),
                        capture.index,
                        query.captureName(capture)
                    )
                ).array;
            result = dg(QueryMatch(match.id, match.pattern_index, captures));
            if (result)
                break;
        }
        return result;
    }
}

class QueryException : Exception {
    TSQueryError error;
    this(TSQueryError error) {
        super("QueryException: " ~ error.to!string);
        this.error = error;
    }
}

struct Query {
    import libc : ts_query_new, ts_query_delete;

    TSQuery* tsquery;
    Language language;

    @disable this(this);

    this(Language language, string queryString) {
        import std.conv;
        this.language = language;
        uint errOffset = 0;
        TSQueryError errType;
        this.tsquery = ts_query_new(
            language.tslanguage,
            queryString.toStringz,
            queryString.length.to!uint,
            &errOffset,
            &errType
        );

        if(errOffset != 0) {
            throw new QueryException(errType);
        }
    }

    ~this() {
        ts_query_delete(tsquery);
    }

    QueryIterator exec(Node node) {
        return QueryIterator(&this, &node);
    }

    string captureName(TSQueryCapture capture) {
        import libc : ts_query_capture_name_for_id;
        uint length;
        auto namePtr = ts_query_capture_name_for_id(
            tsquery,
            capture.index,
            &length
        );
        return namePtr[0..length].to!string;
    }
}
