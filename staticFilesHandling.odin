package main

import "core:fmt"
import "core:os"
import "core:strings"

filesToCopy: []string = {
    "fonts/3270/3270MonoC.ttf",
    "fonts/3270/3270MonoR.ttf",
    "fonts/meslo/MesloBold.ttf",
    "fonts/meslo/MesloRegular.ttf",
    "images/orcThinkerIcon.png",
    "stylesheets/site.css"
}

copyStaticFiles :: proc (basePath: string) {
    for item in filesToCopy {
        copyStaticFile(basePath, item)
    }
}

copyStaticFile :: proc (basePath: string, staticFileLocation: string) {
    data,ok := os.read_entire_file(strings.concatenate({"./",staticFileLocation}))
    if !ok {
        fmt.println("not ok")
        fmt.println(staticFileLocation)
        return
    }

    os.write_entire_file(strings.concatenate({basePath, "\\", staticFileLocation}), data)
    delete(data, context.allocator)
}

// copyCssFiles :: proc (basePath: string, cssFileLocation: string) {
//     data,ok := os.read_entire_file(cssFileLocation)
//     if !ok {
//         return
//     }

//     os.make_directory(strings.concatenate({basePath, "stylesheets"}))
//     os.write_entire_file(strings.concatenate({basePath, "stylesheets\\site.css"}), data)
//     delete(data, context.allocator)
// }


createProjectFolders :: proc(basePath: string) {
    os.make_directory(strings.concatenate({basePath}))
    os.make_directory(strings.concatenate({basePath, "stylesheets"}))
    os.make_directory(strings.concatenate({basePath, "pages"}))
    os.make_directory(strings.concatenate({basePath, "fonts"}))
    os.make_directory(strings.concatenate({basePath, "fonts/meslo"}))
    os.make_directory(strings.concatenate({basePath, "fonts/3270"}))
    os.make_directory(strings.concatenate({basePath, "images"}))
}
