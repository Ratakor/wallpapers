#!/usr/bin/env python

from os import listdir
from os.path import isfile, join

IGNORE = [".git", ".github", "README.md", "list.txt", "nsfw"]

def get_files(path: str) -> list[str]:
    files = []
    for f in listdir(path):
        if f in IGNORE:
            continue
        full_path = join(path, f)
        if isfile(full_path):
            files.append(full_path[2:])
        else:
            files.extend(get_files(full_path))
    return files

if __name__ == "__main__":
    with open("./list.txt", "w") as out_file:
        for f in get_files("./"):
            out_file.write(f"{f}\n")
