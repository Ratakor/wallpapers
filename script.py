#!/usr/bin/env python3
# ./script.py --excludePatterns "^\." --includePatterns "(.png|.jpg|.jpeg|.webp)$"

import json
import os
import re
import argparse


def compile_patterns(patterns):
    return [re.compile(p) for p in patterns]


def should_include(rel_path, include_patterns, exclude_patterns):
    if any(r.search(rel_path) for r in exclude_patterns):
        return False
    return any(r.search(rel_path) for r in include_patterns)


def scan_directory(root, current, include_patterns, exclude_patterns):
    result = {}

    try:
        entries = sorted(os.scandir(current), key=lambda e: e.name)
    except PermissionError:
        return result

    for entry in entries:
        abs_path = entry.path
        rel_path = os.path.relpath(abs_path, root).replace(os.sep, "/")

        if any(r.search(rel_path) for r in exclude_patterns):
            continue

        if entry.is_dir(follow_symlinks=False):
            child = scan_directory(
                root,
                abs_path,
                include_patterns,
                exclude_patterns,
            )
            if child:
                result[entry.name] = child

        elif entry.is_file(follow_symlinks=False):
            if should_include(rel_path, include_patterns, exclude_patterns):
                result[entry.name] = abs_path

    return result


def map_directories(paths=None, exclude_patterns=None, include_patterns=None):
    paths = paths or []
    exclude_patterns = exclude_patterns or []
    include_patterns = include_patterns or [".*"]

    include_patterns = compile_patterns(include_patterns)
    exclude_patterns = compile_patterns(exclude_patterns)

    output = {}

    for p in paths:
        p = os.path.abspath(p)

        if not os.path.exists(p):
            continue

        if os.path.isdir(p):
            output[os.path.basename(p)] = scan_directory(
                p,
                p,
                include_patterns,
                exclude_patterns,
            )

        elif os.path.isfile(p):
            rel = os.path.basename(p)
            if should_include(rel, include_patterns, exclude_patterns):
                output[rel] = f"{rel} = {rel}"

    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--paths",
        nargs="*",
        default=["./."],
    )

    parser.add_argument(
        "--excludePatterns",
        nargs="*",
        default=[],
    )

    parser.add_argument(
        "--includePatterns",
        nargs="*",
        default=[".*"],
    )

    args = parser.parse_args()

    result = map_directories(
        paths=args.paths,
        exclude_patterns=args.excludePatterns,
        include_patterns=args.includePatterns,
    )

    print(json.dumps(result, indent=2))
