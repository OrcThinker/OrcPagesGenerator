package main

import "core:fmt"
import "core:os"
import "core:strings"

getContentWithLayout :: proc (layoutPath: string, content: string) -> string {
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

writeContentWithLayout :: proc (path:string, layoutPath: string, content: string) {
    os.write_entire_file(path, auto_cast transmute([]u8)getContentWithLayout(layoutPath, content))
}
