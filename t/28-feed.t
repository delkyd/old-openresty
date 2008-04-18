# vi:filetype=

use t::OpenResty;

plan tests => 3 * blocks();

run_tests;

__DATA__

=== TEST 1: Login
--- request
GET /=/login/$TestAccount.Admin/$TestPass?use_cookie=1
--- response_like
^{"success":1,"session":"[-\w]+","account":"$TestAccount","role":"Admin"}$



=== TEST 2: Delete existing models
--- request
DELETE /=/model
--- response
{"success":1}



=== TEST 3: Delete existing views
--- request
DELETE /=/view
--- response
{"success":1}



=== TEST 4: Delete existing feeds
--- request
DELETE /=/feed
--- response
{"success":1}



=== TEST 5: Check the feed list
--- request
GET /=/feed
--- response
[]



=== TEST 6: Create a sample model
--- request
POST /=/model/Post
{
    "description": "Blog post",
    "columns": [
        {"name": "title", "label": "Title", "type": "text"},
        {"name": "author", "label": "Author", "type": "text"},
        {"name": "content", "label": "Content", "type": "text"},
        {"name": "created_on", "label": "Created on", "type": "timestamp (0) with time zone", "default": ["now()"]},
        {"name": "comments", "label": "Number of comments", "type":"integer", "default":0}
    ]
}
--- response
{"success":1}



=== TEST 7: Insert some records
--- request
POST /=/model/Post/~/~
[
    {"title":"Hello, world","author":"agentzh","content":"<h1>This is my first program ;)</h1>","comments":5},
    {"title":"I'm going home","author":"carrie","content":"<h1>At last, I'm home again! Yay!</h1>","comments":5},
    {"title":"我来了呀！","author":"章亦春","content":"<h1>呵呵，我<B>回来</B>了！</h1>我很开心哦，呵呵！","comments":5}
]
--- response
{"last_row":"/=/model/Post/id/3","rows_affected":3,"success":1}



=== TEST 8: Create a feed without "view"
--- request
POST /=/feed/Post
{
    "description": "View for post feeds",
    "author": "agentzh",
    "link": "http://blog.agentzh.org",
    "copyright": "Copyright 2008 by Agent Zhang",
    "language": "en",
    "title": "Human & Machine"
}
--- response
{"error":"No 'view' specified.","success":0}



=== TEST 9: Create a feed with an undefined view
--- request
POST /=/feed/Post
{
    "description": "View for post feeds",
    "author": "agentzh",
    "link": "http://blog.agentzh.org",
    "copyright": "Copyright 2008 by Agent Zhang",
    "language": "en",
    "title": "Human & Machine",
    "view": "Blah"
}
--- response
{"error":"View \"Blah\" not found.","success":0}



=== TEST 10: Create a view
--- request
POST /=/view/PostFeed
{
  "description": "View for post feeds",
  "definition": "select author, title, 'http://blog.agentzh.org/#post-' || id as link, content, created_on as published, created_on as updated from Post order by created_on desc limit 20"
}
--- response
{"success":1}



=== TEST 11: Create a feed without link
--- request
POST /=/feed/Post
{
    "description": "Feed for blog posts",
    "author": "agentzh",
    "copyright": "Copyright 2008 by Agent Zhang",
    "language": "en",
    "title": "Human & Machine",
    "view": "PostFeed"
}
--- response
{"error":"No 'link' specified.","success":0}



=== TEST 12: Create a feed successfully
--- request
POST /=/feed/Post
{
    "description": "Feed for blog posts",
    "author": "agentzh",
    "link": "http://blog.agentzh.org",
    "copyright": "Copyright 2008 by Agent Zhang",
    "language": "en",
    "title": "Human & Machine - Blog posts",
    "view": "PostFeed"
}
--- response
{"success":1}



=== TEST 13: Try to create a feed twice
--- request
POST /=/feed/Post
{
    "description": "Feed for blog posts",
    "author": "agentzh",
    "link": "http://blog.agentzh.org",
    "copyright": "Copyright 2008 by Agent Zhang",
    "language": "en",
    "title": "Human & Machine - Blog posts",
    "view": "PostFeed"
}
--- response
{"error":"Feed \"Post\" already exists.","success":0}



=== TEST 14: Get the feed list
--- request
GET /=/feed
--- response
[{"src":"/=/feed/Post","name":"Post","description":"Feed for blog posts"}]



=== TEST 15: Get the "Post" feed
--- request
GET /=/feed/Post
--- response
{
    "name": "Post",
    "description": "Feed for blog posts",
    "author": "agentzh",
    "link": "http://blog.agentzh.org",
    "copyright": "Copyright 2008 by Agent Zhang",
    "language": "en",
    "title": "Human & Machine - Blog posts",
    "view": "PostFeed"
}


=== TEST 16: Obtain the feed content (XML)
--- request
GET /=/feed/Post/~/~
--- res_type: application/rss+xml
--- format: feed
--- response
<?xml version="1.0"?>
<rss version="2.0">
  <channel>
  <title>Human &amp; Machine - Blog posts</title>
  <link>http://blog.agentzh.org</link>
  <language>en</language>
  <copyright>Copyright 2008 by Agent Zhang</copyright>
  <lastBuildDate>2008-04-17T20:24:57</lastBuildDate>
  <item>
    <title>Hello, world</title>
    <link>http://blog.agentzh.org/#post-1</link>
    <description>&lt;h1&gt;This is my first program ;)&lt;/h1&gt;</description>
    <author>agentzh</author>
    <pubDate>2008-04-17T20:24:57</pubDate>
  </item>
  <item>
    <title>I'm going home</title>
    <link>http://blog.agentzh.org/#post-2</link>
    <description>&lt;h1&gt;At last, I'm home again! Yay!&lt;/h1&gt;</description>
    <author>carrie</author>
    <pubDate>2008-04-17T20:24:57</pubDate>
  </item>
  <item>
    <title>我来了呀！</title>
    <link>http://blog.agentzh.org/#post-3</link>
    <description>&lt;h1&gt;呵呵，我&lt;B&gt;回来&lt;/B&gt;了！&lt;/h1&gt;我很开心哦，呵呵！</description>
    <author>章亦春</author>
    <pubDate>2008-04-17T20:24:57</pubDate>
  </item>
  </channel>
</rss>
--- LAST




=== TEST 16: Create another feed
--- request
POST /=/feed/Comment
{
    "description": "Feed for blog comments",
    "link": "http://blog.agentzh.org",
    "copyright": "Copyright by the individual commment senders",
    "language": "en",
    "title": "Human & Machine - Blog comments",
    "view": "PostFeed"
}
--- response
{"success":1}



=== TEST 17: Get the feed list again
--- request
GET /=/feed
--- response
[
    {"src":"/=/feed/Post","name":"Post","description":"Feed for blog posts"},
    {"src":"/=/feed/Comment","name":"Comment","description":"Feed for blog comments"}
]


=== TEST 18: Delete feed Comment
--- request
DELETE /=/feed/Comment
--- response
{"success":1}



=== TEST 19: Get the feed list again
--- request
GET /=/feed
--- response
[
    {"src":"/=/feed/Post","name":"Post","description":"Feed for blog posts"}
]



=== TEST 20: Delete feed Comment again
--- request
DELETE /=/feed/Comment
--- response
{"error":"Feed \"Comment\" not found.","success":0}
