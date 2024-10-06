package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "core:strconv"
import "core:slice"

blogFolder :: struct {
    blogFolders: [dynamic] blogFolder,
    blogFiles: [dynamic] os.File_Info,
    path: string
}

blogInfo :: struct {
    path: string,
    date: date
}

date :: struct {
    year,month,day:int
}

main :: proc() {
    fullpath := ""
    // fmt.println(fullpath)
    bf,paths := findFiles(fullpath, fullpath, {})
    // fmt.println(paths)
    h,e := os.open("")
    // fmt.println(h)
    // fmt.println(e)
    // textToWrite := "this is just a test"
    blogBasePath := ""
    //This works
    blogInfos: [dynamic]blogInfo
    dateLineString := "#+date: "
    for item in paths {
        // append(&blogInfo, {item, })
        data,ok := os.read_entire_file(strings.concatenate({fullpath, item}))
        if !ok {
            return
        }
        defer delete(data, context.allocator)

        it := string(data)
        index := 0
        for line in strings.split_lines_iterator(&it) {
            if(strings.starts_with(line, dateLineString)){
                dateString := line[len(dateLineString):]
                dateComponents :[]string = strings.split(dateString, "/")

                date1 :date = {strconv.atoi(dateComponents[2]), strconv.atoi(dateComponents[0]), strconv.atoi(dateComponents[1])}
                // date2 :date = {strconv.atoi(dateComponents[2])+1, strconv.atoi(dateComponents[0]), strconv.atoi(dateComponents[1])}
                // date3 :date = {strconv.atoi(dateComponents[2])-1, strconv.atoi(dateComponents[0]), strconv.atoi(dateComponents[1])}
                bInfo : blogInfo = {item, date1}
                // bInfo2 : blogInfo = {item, date2}
                // bInfo3 : blogInfo = {item, date3}
                append(&blogInfos, bInfo)
                // append(&blogInfos, bInfo2)
                // append(&blogInfos, bInfo3)
            }
            if index > 5{
                break;
            }
            index+=1
        }
        // os.write_entire_file(strings.concatenate({blogBasePath, item}), auto_cast transmute([]u8)textToWrite)
    }
    //Find the whole structure -> create folders -> create files
    //2 file hosting the whole blog list page
    //3 file hosting article page based on which all the article pages will be generated
    writeIndexPage(strings.concatenate({blogBasePath, "index.html"}), "./Pages/index.template.html")
    copyCssFiles(blogBasePath, "./Stylesheets/site.css")

    slice.sort_by(blogInfos[:], orderByNewest)
    fmt.println(blogInfos)
}

orderByNewest :: proc (a,b:blogInfo) -> bool {
    x :blogInfo
    aTime,aOk := time.components_to_time(a.date.year,a.date.month,a.date.day,0,0,0,0)
    bTime,bOk := time.components_to_time(b.date.year,b.date.month,b.date.day,0,0,0,0)
    return aTime._nsec > bTime._nsec
}



writeIndexPage :: proc (path: string, templatesPath: string) {
    //Prepping template data
    postNumbers:[3]int= {1,2,3}
    textToWrite: string
    for item in postNumbers {
        postItem:cstring = fmt.ctprintf("<div> %v </div>", item)
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
