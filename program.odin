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

    createProjectFolders(blogBasePath)
    blogInfos := getBlogPathsSortedByDate(paths, fullpath)
    writeIndexPage(strings.concatenate({blogBasePath, "index.html"}), "./Pages/index.template.html", blogInfos)
    writeBlogListPages(strings.concatenate({blogBasePath, "blog.html"}), "./Pages/blogPosts.template.html", blogInfos)
    copyStaticFiles(blogBasePath)
    //Create page files based on fullpath - RN it doesn't create files for pages that are not in the folder but of higher depths in file tree
    //Index page exactly 3 articles not more
    //Pagination for BlogList page
    for item in blogInfos {
        fmt.println(item.path)
        pageName := strings.split(item.path, ".")[0]
        writeBlogPostContent(strings.concatenate({blogBasePath,pageName, ".html"}),strings.concatenate({fullpath, item.path}), "./Pages/post.template.html", "./Pages/layout.template.html")
    }
}
