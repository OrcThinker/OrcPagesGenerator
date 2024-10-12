package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "core:strconv"
import "core:slice"
import "core:math"

blogFolder :: struct {
    blogFolders: [dynamic] blogFolder,
    blogFiles: [dynamic] os.File_Info,
    path: string
}

blogInfo :: struct {
    path: string,
    date: date,
    title: string,
    author: string,
    words: int,
}

date :: struct {
    year,month,day: int
}

fullpath := ""
blogBasePath := ""
isLocal := true

main :: proc() {
    bf,paths := findFiles(fullpath, fullpath, {})
    //2 file hosting the whole blog list page
    //3 file hosting article page based on which all the article pages will be generated

    blogInfos := getBlogPathsSortedByDate(paths, fullpath)
    writeIndexPage(strings.concatenate({blogBasePath, "index.html"}), "./Pages/index.template.html", blogInfos, isLocal)
    writeBlogListPages(strings.concatenate({blogBasePath, "blog.html"}), "./Pages/blogPosts.template.html", blogInfos, isLocal)
    copyCssFiles(blogBasePath, "./Stylesheets/site.css")
    fmt.println(blogInfos[2].title)
    x := getBlogPostContent(blogBasePath, strings.concatenate({fullpath,"SamplePost.org"}), "./Pages/post.template.html", blogInfos, isLocal)
    writeBlogPostContent(strings.concatenate({blogBasePath,"firstPost.html"}), "./Pages/post.template.html", x, isLocal)
    // fmt.println(blogInfos)
}
