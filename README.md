# Scrawl: Simple, Scribble-like Syntax for Common Lisp

Scrawl provides a few reader macros to allow for [Scribble](https://docs.racket-lang.org/scribble/)-like syntax, if you activative the `scrawl:syntax` readtable:

```
CL-USER> (named-readtables:in-readtable scrawl:syntax)
...
CL-USER> '@a[:href "http://google.com"]{g o o g l e}
(A :HREF "http://google.com" "g o o g l e")
```

We have made an effort to keep the implementation simple (~100 lines total). For a more (complicated, fully-featured) Common Lisp alternative, consider [this](https://cliki.net/scribble) library.

## The Details

Scrawl provides an extension to the standard read table which gives special treatment to the `@ [ ] { }` characters. The general form of a *scrawl expression* is

``` 
'@' <op> <args>? <body>?
```

where 
- `<op>` is any Lisp expression
- `<args>` is an optional square-bracketed list, e.g. `[1 2 3]`
- `<body>` is an optional sequence of text, surrounded by braces, e.g. `{ foo frob }`

Note that the above is sensitive to spaces, so e.g.  `@foo [1 2 3]` is
different from `@foo[1 2 3]`.

The body of a Scrawl expression consists of text, possibly containing further Scrawl expressions. This is read recursively as a sequence of strings and Scrawl expressions. The result of reading 
```
@<op>[<arg1> ... <argN>]{ <body1> ... <bodyM> }
```
is
```
(<op> <arg1> ... <argN> <body1> ... <bodyM>)
```
where `<body>` contained a total of `M` text-segments (possibly containing whitespace) and Scrawl expressions.

Here's an extended example:
```
@div[:id "my-div"]{
  @h1{
    Hello World!
  }
  @p{
    I am @b{cow}
    Hear me moo
    I weigh twice as much as you
    And I look good on the barbecue
  }
}
```

is read as

```
(DIV :ID "my-div" (H1 "Hello World!") "
  "
 (P "I am " (B "cow") "
    Hear me moo
    I weigh twice as much as you
    And I look good on the barbecue"))
```

## A few additional design decisions

There are a few choices we have made. 

- Whitespace is trimmed from the start of the first string and the end
  of the last, e.g. `@foo{ bar @baz frob }` results in `(FOO "bar " BAZ " frob")`
- Empty strings are ignored, e.g.  `@foo{ }` results in `(FOO)`.
- Escaping within the body of a scrawl expression is accomplished via
  `@`, e.g. `@foo{ @"@" }` yields `(FOO "@")`
- The easiest way force inclusion of whitespace is to escape it:
  `@foo{@" "bar}` yields `'(FOO " " "bar")`
- Nested braces are fine if they are balanced: `@foo{ { } }` yields `(FOO "{ }")`
- Unbalanced braces must be escaped, e.g. `@foo{ @"{"  }` yields `(FOO "{")`

For more perspective on what these or other decisions might entail, consider reading Eli Barzilay's [The Scribble Reader](http://barzilay.org/misc/scribble-reader.pdf)
