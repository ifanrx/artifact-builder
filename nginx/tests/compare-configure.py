#!/usr/bin/env python3
"""Compare nginx -V output against the official package's build settings."""

import shlex
import sys
from pathlib import Path


def read_configuration(path):
    lines = Path(path).read_text().splitlines()
    version = next(line for line in lines if line.startswith("nginx version:"))
    arguments = next(line.removeprefix("configure arguments: ") for line in lines
                     if line.startswith("configure arguments: "))
    options = {}
    for argument in shlex.split(arguments):
        key, _, value = argument.partition("=")
        if key == "--add-dynamic-module":
            continue
        options[key] = value
    return version, options


def compiler_flags(value):
    return [flag for flag in shlex.split(value)
            if not flag.startswith(("-ffile-prefix-map=", "-fdebug-prefix-map="))]


def linker_flags(value):
    return [flag for flag in shlex.split(value)
            if not flag.startswith("-Wl,--package-metadata=")]


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: compare-configure.py <official-nginx-V.txt> <module-build-nginx-V.txt>")
    reference_version, reference = read_configuration(sys.argv[1])
    built_version, built = read_configuration(sys.argv[2])
    problems = []
    if reference_version != built_version:
        problems.append(f"Version mismatch: {reference_version!r} != {built_version!r}")
    for option in sorted(reference.keys() | built.keys()):
        expected = reference.get(option)
        actual = built.get(option)
        if option == "--with-cc-opt" and expected is not None and actual is not None:
            expected = compiler_flags(expected)
            actual = [flag for flag in compiler_flags(actual)
                      if flag != "-Wno-discarded-qualifiers"]
        elif option == "--with-ld-opt" and expected is not None and actual is not None:
            expected = linker_flags(expected)
            actual = [flag for flag in linker_flags(actual)
                      if flag != "-Wl,-rpath,/opt/luajit2/lib"]
        if expected != actual:
            problems.append(f"{option}: official={expected!r}, module build={actual!r}")
    if problems:
        sys.exit("nginx.org build settings differ:\n" + "\n".join(problems))
    print("nginx version, configure features, paths and compiler/linker flags match nginx.org")


if __name__ == "__main__":
    main()
