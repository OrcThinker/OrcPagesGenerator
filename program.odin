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
    year,month,day:int
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
            fmt.println(len(strings.split(line, " ")))
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
            fmt.println(wordsInDocument)
            bInfo : blogInfo = {item, dateToSave, titleToSave, authorToSave, wordsInDocument}
            append(&blogInfos, bInfo)
        }
    }
    slice.sort_by(blogInfos[:], orderByNewest)
    return blogInfos
}

main :: proc() {
    fullpath := ""
    bf,paths := findFiles(fullpath, fullpath, {})
    h,e := os.open("")
    blogBasePath := ""
    //2 file hosting the whole blog list page
    //3 file hosting article page based on which all the article pages will be generated

    blogInfos := getBlogPathsSortedByDate(paths, fullpath)
    writeIndexPage(strings.concatenate({blogBasePath, "index.html"}), "./Pages/index.template.html", blogInfos)
    copyCssFiles(blogBasePath, "./Stylesheets/site.css")
    fmt.println(blogInfos)
}

orderByNewest :: proc (a,b:blogInfo) -> bool {
    x :blogInfo
    aTime,aOk := time.components_to_time(a.date.year,a.date.month,a.date.day,0,0,0,0)
    bTime,bOk := time.components_to_time(b.date.year,b.date.month,b.date.day,0,0,0,0)
    return aTime._nsec > bTime._nsec
}



writeIndexPage :: proc (path: string, templatesPath: string, blogInfos: [dynamic]blogInfo) {
    //Prepping template data
    textToWrite: string

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
        if(strings.contains(line, "{{BlogPosts}}"))
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
