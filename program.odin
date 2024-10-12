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

getBlogPathsSortedByDate :: proc(paths: [dynamic]string, fullpath:string) -> [dynamic]blogInfo{
    blogInfos: [dynamic]blogInfo
    dateLineString := "#+date: "
    titleLineString := "#+title: "
    authorLineString := "#+author: "
    for item in paths {
        wordsInDocument := 0
        data,ok := os.read_entire_file(strings.concatenate({fullpath, item}))
        if !ok {
            continue
        }
        defer delete(data, context.allocator)

        it := string(data)
        // index := 0
        dateToSave:date
        titleToSave:string = ""
        authorToSave:string = ""
        for line in strings.split_lines_iterator(&it) {
            wordsInDocument = wordsInDocument + len(strings.split(line, " ")) + 1
            if(strings.starts_with(line, titleLineString)){
                titleToSave = strings.clone(line[len(titleLineString):])
            }
            if(strings.starts_with(line, authorLineString)){
                authorToSave = strings.clone(line[len(authorLineString):])
            }
            if(strings.starts_with(line, dateLineString)){
                dateString := line[len(dateLineString):]
                dateComponents :[]string = strings.split(dateString, "/")

                date1 :date = {strconv.atoi(dateComponents[2]), strconv.atoi(dateComponents[0]), strconv.atoi(dateComponents[1])}
                dateToSave = date1
            }
        }
        if dateToSave != {0,0,0} {
            bInfo : blogInfo = {item, dateToSave, titleToSave, authorToSave, wordsInDocument}
            append(&blogInfos, bInfo)
        }
    }
    slice.sort_by(blogInfos[:], orderByNewest)
    return blogInfos
}


orderByNewest :: proc (a,b:blogInfo) -> bool {
    x :blogInfo
    aTime,aOk := time.components_to_time(a.date.year,a.date.month,a.date.day,0,0,0,0)
    bTime,bOk := time.components_to_time(b.date.year,b.date.month,b.date.day,0,0,0,0)
    return aTime._nsec > bTime._nsec
}

getContentWithLayout :: proc (layoutPath: string, content: string, isLocal:bool) -> string {
    indexLogoLinkStr := string(fmt.ctprintf(`<a href="./%v">`, isLocal ? "index.html": ""))
    indexLinkStr := string(fmt.ctprintf(`<a href="./%v">Home</a>`, isLocal ? "index.html": ""))
    blogLinkStr := string(fmt.ctprintf(`<a href="./%v">Blog</a>`, isLocal ? "blog.html": "blog"))
    data,ok := os.read_entire_file(layoutPath)
    if !ok {
        return ""
    }
    defer delete(data, context.allocator)

    finalHtml: string

    it := string(data)
    for line in strings.split_lines_iterator(&it) {
        if(strings.contains(line, "{{indexLogoLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, indexLogoLinkStr})
        }
        else if(strings.contains(line, "{{indexLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, indexLinkStr})
        }
        else if(strings.contains(line, "{{blogLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, blogLinkStr})
        }
        else if(strings.contains(line, "{{contentToRender}}")){
            finalHtml = strings.concatenate({finalHtml, content})
        }
        else{
            finalHtml = strings.concatenate({finalHtml, line})
        }
        finalHtml = strings.concatenate({finalHtml, "\n"})
    }
    return finalHtml
}


//At the start this is basically the same as writing index page
//Will be a bit different due to the fact that it will render multiple pages
writeBlogListPages :: proc (path: string, templatesPath: string, blogInfos: [dynamic]blogInfo, isLocal:bool) {
    //Prepping template data
    textToWrite: string

    indexLogoLinkStr := string(fmt.ctprintf(`<a href="./%v">`, isLocal ? "index.html": ""))
    indexLinkStr := string(fmt.ctprintf(`<a href="./%v">Home</a>`, isLocal ? "index.html": ""))
    blogLinkStr := string(fmt.ctprintf(`<a href="./%v">Blog</a>`, isLocal ? "blog.html": "blog"))

    for item in blogInfos {
        articleStr := `
            <article>
                <header>%v</header>
                <p>desc</p>
                <footer>
                <span>%v</span>
                <hr>
                <span>%v min</span>
                <hr>
                <span>%v</span>
                </footer>
                <a class="post-link" href="./%v"></a>
            </article>
        `
        dateStr := fmt.ctprintf("%v/%v/%v", item.date.month, item.date.day, item.date.year)
        link := "link"

        postItem:cstring = fmt.ctprintf(articleStr, item.title, dateStr, math.ceil(f16(item.words)/220), item.author, link)
        textToWrite = strings.concatenate({textToWrite, string(postItem)})
    }

    //Reading template
    data,ok := os.read_entire_file(templatesPath)
    if !ok {
        return
    }
    defer delete(data, context.allocator)

    finalHtml: string

    it := string(data)
    for line in strings.split_lines_iterator(&it) {
        if(strings.contains(line, "{{indexLogoLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, indexLogoLinkStr})
        }
        else if(strings.contains(line, "{{indexLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, indexLinkStr})
        }
        else if(strings.contains(line, "{{blogLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, blogLinkStr})
        }
        else if(strings.contains(line, "{{BlogPosts}}"))
        {
            finalHtml = strings.concatenate({finalHtml, textToWrite})
        }
        else{
            finalHtml = strings.concatenate({finalHtml, line})
        }
        finalHtml = strings.concatenate({finalHtml, "\n"})
    }

    os.write_entire_file(path, auto_cast transmute([]u8)finalHtml)
}


writeBlogPostContent :: proc (path:string, templatesPath: string, blogContent: string, isLocal: bool) {
    data,ok := os.read_entire_file(templatesPath)
    if !ok {
        return
    }
    defer delete(data, context.allocator)

    finalHtml: string

    it := string(data)
    for line in strings.split_lines_iterator(&it) {
        if(strings.contains(line, "{{postContent}}"))
        {
            finalHtml = strings.concatenate({finalHtml, blogContent})
        }
        else
        {
            finalHtml = strings.concatenate({finalHtml, line})
        }
        fmt.println(line)
        finalHtml = strings.concatenate({finalHtml, "\n"})
    }

    os.write_entire_file(path, auto_cast transmute([]u8)finalHtml)
}



getBlogPostContent :: proc (path:string, orgPath: string, templatesPath: string, blogInfos: [dynamic]blogInfo, isLocal: bool) -> string {
    postContent: string

    //Reading template
    data,ok := os.read_entire_file(orgPath)
    if !ok {
        return ""
    }
    defer delete(data, context.allocator)

    finalHtml: string
    listStarted, insideQuoteBlock, insideCodeBlock: bool
    descStr := "#+description: "
    authorStr := "#+author: "
    titleStr := "#+title: "
    dateStr := "#+date: "
    beginQuoteStr := "#+begin_quote"
    endQuoteStr := "#+end_quote"
    beginSrcStr := "#+begin_src"
    endSrcStr := "#+end_src"

    it := string(data)
    index := 0
    for line in strings.split_lines_iterator(&it) {
        index = index + 1
        //If was list but isn't then close list
        if !strings.starts_with(strings.to_lower(line), strings.to_lower("-")) && listStarted {
            postContent = strings.concatenate({postContent, "</ul>"})
            listStarted = false
        }

        if strings.starts_with(strings.to_lower(line), strings.to_lower("*")) {
            lineText := strings.trim(line, " ")
            lineText = strings.trim(line, "*")
            lineElement := fmt.ctprintf("<h2>%v</h2>", lineText)
            postContent = strings.concatenate({postContent, string(lineElement)})
        }
        else if strings.starts_with(strings.to_lower(line), strings.to_lower(descStr)) {
            lineText := strings.trim(line, " ")
            lineText = strings.trim(line, descStr)
            lineElement := fmt.ctprintf("<p>%v</p>", lineText)
            postContent = strings.concatenate({postContent, string(lineElement)})
        }
        else if strings.starts_with(strings.to_lower(line), strings.to_lower(authorStr)) {
            lineText := strings.trim(line, " ")
            lineText = strings.trim(line, authorStr)
            //TODO: Add author element to the page
            // lineElement := fmt.ctprintf("<p>%v</p>", lineText)
            // postContent = strings.concatenate({postContent, string(lineElement)})
        }
        else if strings.starts_with(strings.to_lower(line), strings.to_lower(titleStr)) {
            lineText := strings.trim(line, " ")
            lineText = strings.trim(line, titleStr)
            lineElement := fmt.ctprintf("<h1>%v</h1>", lineText)
            postContent = strings.concatenate({postContent, string(lineElement)})
        }
        else if strings.starts_with(strings.to_lower(line), strings.to_lower(dateStr)) {
        }
        else if strings.starts_with(strings.to_lower(line), strings.to_lower(beginQuoteStr)) {
            insideQuoteBlock = true
            lineElement := "<blockquote>"
            postContent = strings.concatenate({postContent, string(lineElement)})
        }
        else if strings.starts_with(strings.to_lower(line), strings.to_lower(endQuoteStr)) {
            insideQuoteBlock = false
            lineElement := "</blockquote>"
            postContent = strings.concatenate({postContent, string(lineElement)})
        }
        else if strings.starts_with(strings.to_lower(line), strings.to_lower(beginSrcStr)) {
            insideCodeBlock = true
            lineElement := "<pre><code>"
            postContent = strings.concatenate({postContent, string(lineElement)})
        }
        else if strings.starts_with(strings.to_lower(line), strings.to_lower(endSrcStr)) {
            insideCodeBlock = false
            lineElement := "</code></pre>"
            postContent = strings.concatenate({postContent, string(lineElement)})
        }
        else if strings.starts_with(strings.to_lower(line), "#") {
            //Do nothin for now
        }
        else if strings.starts_with(strings.to_lower(line), strings.to_lower("-")) {
            if !listStarted {
                listStarted = true
                postContent = strings.concatenate({postContent, "<ul>"})
            }
            lineText := strings.trim(line, " ")
            lineText = strings.trim(line, "-")
            lineElement := fmt.ctprintf(`<li><a href="%v">%v</a></li>`, lineText, lineText)
            postContent = strings.concatenate({postContent, string(lineElement)})
        }
        else {
            //TODO: take depth of codeblock and adjust it
            lineText := strings.trim(line, " ")
            lineElement := fmt.ctprintf(`<p>%v</p>`, lineText)
            postContent = strings.concatenate({postContent, string(lineElement)})
        }

    }

    return postContent
    // os.write_entire_file(path, auto_cast transmute([]u8)finalHtml)
}

writeIndexPage :: proc (path: string, templatesPath: string, blogInfos: [dynamic]blogInfo, isLocal: bool) {
    //Prepping template data
    textToWrite: string
    articleStr := `
        <article>
            <header>%v</header>
            <p>desc</p>
            <footer>
            <span>%v</span>
            <hr>
            <span>%v min</span>
            <hr>
            <span>%v</span>
            </footer>
            <a class="post-link" href="./%v"></a>
        </article>
    `

    indexLogoLinkStr := string(fmt.ctprintf(`<a href="./%v">`, isLocal ? "index.html": ""))
    indexLinkStr := string(fmt.ctprintf(`<a href="./%v">Home</a>`, isLocal ? "index.html": ""))
    blogLinkStr := string(fmt.ctprintf(`<a href="./%v">Blog</a>`, isLocal ? "blog.html": "blog"))
    moreBtnLinkStr := string(fmt.ctprintf(`<a href="./%v" class="button-primary">More..</a>`, isLocal ? "blog.html" : "blog"))

    for item in blogInfos {
        dateStr := fmt.ctprintf("%v/%v/%v", item.date.month, item.date.day, item.date.year)
        link := isLocal ? "link.html" : "link"

        postItem:cstring = fmt.ctprintf(articleStr, item.title, dateStr, math.ceil(f16(item.words)/220), item.author, link)
        textToWrite = strings.concatenate({textToWrite, string(postItem)})
    }

    //Reading template
    data,ok := os.read_entire_file(templatesPath)
    if !ok {
        return
    }
    defer delete(data, context.allocator)

    finalHtml: string

    it := string(data)
    for line in strings.split_lines_iterator(&it) {
        if(strings.contains(line, "{{moreBtnLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, moreBtnLinkStr})
        }
        else if(strings.contains(line, "{{indexLogoLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, indexLogoLinkStr})
        }
        else if(strings.contains(line, "{{indexLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, indexLinkStr})
        }
        else if(strings.contains(line, "{{blogLink}}"))
        {
            finalHtml = strings.concatenate({finalHtml, blogLinkStr})
        }
        else if(strings.contains(line, "{{BlogPosts}}"))
        {
            finalHtml = strings.concatenate({finalHtml, textToWrite})
        }
        else{
            finalHtml = strings.concatenate({finalHtml, line})
        }
        finalHtml = strings.concatenate({finalHtml, "\n"})
    }

    os.write_entire_file(path, auto_cast transmute([]u8)finalHtml)
}

copyCssFiles :: proc (basePath: string, cssFileLocation: string) {
    data,ok := os.read_entire_file(cssFileLocation)
    if !ok {
        return
    }

    os.make_directory(strings.concatenate({basePath, "stylesheets"}))
    os.write_entire_file(strings.concatenate({basePath, "stylesheets\\site.css"}), data)
    delete(data, context.allocator)
}

findFiles :: proc (path :string, originalPath :string, paths :[dynamic]string) -> (blogFolder, [dynamic]string) {
    paths := paths
    blogFolder: blogFolder
    blogFolder.path = path
    h,e := os.open(blogFolder.path)
    defer os.close(h)
    fileInfo,errInf := os.read_dir(h, 0)
    for item in fileInfo {
        if strings.ends_with(item.fullpath, ".org"){
            append(&blogFolder.blogFiles, item)
            data, ok := os.read_entire_file(item.fullpath, context.allocator)
                if !ok {
                    // could not read file
                    continue
                }
                defer delete(data, context.allocator)

                it := string(data)
                for line in strings.split_lines_iterator(&it) {
                }
            append(&paths, item.fullpath[len(originalPath):])
        }
        else if item.is_dir && !strings.ends_with(item.fullpath, ".git") {
            newBlogFolder, pathz := findFiles(item.fullpath, originalPath, paths)
            paths = pathz
            append(&blogFolder.blogFolders, newBlogFolder)
        }
    }
    return blogFolder, paths
}
