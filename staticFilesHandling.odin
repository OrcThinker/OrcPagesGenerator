package main

import "core:os"
import "core:strings"

copyCssFiles :: proc (basePath: string, cssFileLocation: string) {
    data,ok := os.read_entire_file(cssFileLocation)
    if !ok {
        return
    }

    os.make_directory(strings.concatenate({basePath, "stylesheets"}))
    os.write_entire_file(strings.concatenate({basePath, "stylesheets\\site.css"}), data)
    delete(data, context.allocator)
}
