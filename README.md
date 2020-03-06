# gRPC

An example of how to generate gRPC APIs directly from your DB schema.

The generated proto file has the following characteristics:

- One message is generated per database table
- One enum is generated per database enum
- Request and response messages are generated for each basic CRUD operation (List, Get, Create, Update, and Delete)
- An RPC is created for each CRUD operation for each table

# Example

The example output is based on the following SQL:

```sql
CREATE TABLE public.books
(
    id integer NOT NULL DEFAULT nextval('books_id_seq'::regclass),
    author_id uuid NOT NULL,
    isbn character(32) COLLATE pg_catalog."default" NOT NULL,
    booktype book_type NOT NULL,
    title text COLLATE pg_catalog."default" NOT NULL,
    pages integer NOT NULL,
    summary text COLLATE pg_catalog."default",
    available timestamp with time zone NOT NULL DEFAULT '2017-09-04 18:43:39.197538-07'::timestamp with time zone,
    CONSTRAINT books_pkey PRIMARY KEY (id),
    CONSTRAINT books_isbn_key UNIQUE (isbn),
    CONSTRAINT books_author_id_fkey FOREIGN KEY (author_id)
        REFERENCES public.authors (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE INDEX books_title_idx
    ON public.books USING btree
    (author_id ASC NULLS LAST, title COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
```

A message will be generated for the table `public.books`:

```protobuf
message Books {
  int32                       id        = 1 [(gogoproto.customname) = "ID"];  // (PK)
  string                      author_id = 2 [(gogoproto.customname) = "AuthorID"];
  google.protobuf.Timestamp   available = 3 [(gogoproto.customname) = "Available"];
  BookType                    booktype  = 4 [(gogoproto.customname) = "Booktype"];
  string                      isbn      = 5 [(gogoproto.customname) = "Isbn"];
  int32                       pages     = 6 [(gogoproto.customname) = "Pages"];
  google.protobuf.StringValue summary   = 7 [(gogoproto.customname) = "Summary"];
  string                      title     = 8 [(gogoproto.customname) = "Title"];
}
```

Request and response messages will be generated for all CRUD operations:

```protobuf
message ListBooksRequest {
  // The fields on this ListBooksRequest are used to filter for rows from
  // the books table backend. The templates generate fields for primary and
  // foreign keys automatically. If additional fields are needed for filtering, they
  // would need to be added after code generation.
  repeated int32  id        = 1 [(gogoproto.customname) = "ID"];        // (PK)
  repeated string author_id = 2 [(gogoproto.customname) = "AuthorID"];  // (FK)

  // Manually added filters:
}

message ListBooksResponse {
  repeated Books books = 1 [(gogoproto.customname) = "Books"];
}

message GetBooksRequest {
  int32 id = 1 [(gogoproto.customname) = "ID"];  // (PK)
}

message CreateBooksRequest {
  Books books = 1 [(gogoproto.customname) = "Books"];
}

message UpdateBooksRequest {
  Books                     books       = 1 [(gogoproto.customname) = "Books"];
  google.protobuf.FieldMask update_mask = 2;
}

message DeleteBooksRequest {
  int32 id = 1 [(gogoproto.customname) = "ID"];  // (PK)
}
```

Finally, a service will be generated for each CRUD operation using the generated messages:

```protobuf
service GeneratedService {
  rpc ListBooks(ListBooksRequest) returns (ListBooksResponse) {};
  rpc GetBooks(GetBooksRequest) returns (Books) {};
  rpc CreateBooks(CreateBooksRequest) returns (Books) {};
  rpc UpdateBooks(UpdateBooksRequest) returns (Books) {};
  rpc DeleteBooks(DeleteBooksRequest) returns (google.protobuf.Empty) {};
}
```

# List requests

List requests, such as the `ListBooks` RPC from the example are meant to filter the related database rows based on the the provided keys. Most commonly the backend will `OR` the fields together in a `WHERE` clause. This makes it easy to e.g. get all rows that reference one or more foreign keys, or get all rows in a list of primary key IDs.

Additional fields can be added after generation if more filtering is necessary. It would also be trivial to alter the template to include all fields on a message, making them available for filtering on as well.
