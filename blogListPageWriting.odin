package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:math"

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
