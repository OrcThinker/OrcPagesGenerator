package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:math"


writeIndexPage :: proc (path: string, templatesPath: string, blogInfos: [dynamic]blogInfo) {
    //Prepping template data
    textToWrite: string
    articleStr := `
        <article>
            <header>%v</header>
            <p>%v</p>
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

    moreBtnLinkStr := string(fmt.ctprintf(`<a href="./%v" class="button-primary">More..</a>`, isLocal ? "blog.html" : "blog"))

    for item, index in blogInfos {
        if index >= 3 {
            break;
        }
        dateStr := fmt.ctprintf("%v/%v/%v", item.date.month, item.date.day, item.date.year)
        // link := isLocal ? "link.html" : "link"
        link := strings.split(item.path, ".")[0]
        link = strings.concatenate({link,isLocal ? ".html" : ""})
        desc := ""

        postItem:cstring = fmt.ctprintf(articleStr, item.title, desc, dateStr, math.ceil(f16(item.words)/220), item.author, link)
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
        else if(strings.contains(line, "{{blogPosts}}"))
        {
            finalHtml = strings.concatenate({finalHtml, textToWrite})
        }
        else{
            finalHtml = strings.concatenate({finalHtml, line})
        }
        finalHtml = strings.concatenate({finalHtml, "\n"})
    }

    writeContentWithLayout(path, layoutPath, finalHtml)
}
