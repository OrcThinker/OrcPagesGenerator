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
layoutPath := "./Pages/layout.template.html"
isLocal := true

main :: proc() {
    bf,paths := findFiles(fullpath, fullpath, {})

    //Below writes index, listPage without proper links, article for 1 post based on path
    //TODO
    //Add proper Links to the articles
    //Have proper naming for those articles
    //Generate pages for all the org files in folder/array or something. Will have to think of how I want to add those .org files
    blogInfos := getBlogPathsSortedByDate(paths, fullpath)
    writeIndexPage(strings.concatenate({blogBasePath, "index.html"}), "./Pages/index.template.html", blogInfos)
    writeBlogListPages(strings.concatenate({blogBasePath, "blog.html"}), "./Pages/blogPosts.template.html", blogInfos)
    copyCssFiles(blogBasePath, "./Stylesheets/site.css")
    writeBlogPostContent(strings.concatenate({blogBasePath,"firstPost.html"}),"../SamplePost.org", "./Pages/post.template.html")
}
