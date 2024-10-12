package main

import "core:os"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:time"


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
