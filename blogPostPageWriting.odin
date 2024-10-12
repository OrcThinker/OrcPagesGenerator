package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:slice"

getBlogPostPageContent :: proc (templatesPath: string, blogContent: string) -> string {
    data,ok := os.read_entire_file(templatesPath)
    if !ok {
        return ""
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

    return finalHtml
}

writeBlogPostContent :: proc (path:string, orgPath:string, templatesPath: string) {
    writeContentWithLayout(path, layoutPath, getBlogPostContent(orgPath, templatesPath))
}


getBlogPostContent :: proc (orgPath: string, templatesPath: string) -> string {
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
}
