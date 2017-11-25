#!/bin/bash

# This file is a part of splitfiles v1.0.0
#
# Split a directory to several directories.
#
# When you have a directory with thousands of files you can create
# subdirectories and move files to them proportionally.
#
# License: GPLv3 http://www.gnu.org/licenses/
# Copyright (C) 2017, Slava freeprogs.feedback@yandex.ru

progname=`basename $0`

# Print an error message to stderr
# error(str)
error()
{
    echo "error: $progname: $1" >&2
}

# Print an message to stdout
# msg(str)
msg()
{
    echo "$progname: $1"
}

# Print program usage to stderr
# usage()
usage()
{
    echo "usage: $progname dir num" >&2
}

# Split directory to several subdirectories with dircap (or less)
# files in every subdirectory.
#
# process_files(dir, dircap)
# args:
#   dir - directory where to search files and to make subdirectories
#   dircap - how many files should be moved to a subdirectory
# return:
#   0 if success
#   1 if any error
process_files()
{
    local dir=$1
    local dircap=$2
    local num_of_dirs
    local dirnum
    local old_ifs

    num_of_dirs=$(count_file_groups "$dir" $dircap)
    msg "Need to make $num_of_dirs subdirectories"
    for dirnum in $(seq 1 $num_of_dirs); do
        msg "Creating subdirectory $dirnum..."
        makedir "$dir" "$dirnum" || {
            msg "Subdirectory $dirnum - FAIL"
            error "can't create directory: $dir/$dirnum"
            return 1
        }
        # We need to return from the function if an error
        # occured.
        # Construction
        #    func | while read fname; do ... return ... done
        # doesn't work because return doesn't work for the function
        # inside pipe. Therefore, it involved temporary IFS changing.
        old_ifs="$IFS"
        IFS=$'\n'
        for fname in $(get_file_names "$dir" "$dircap"); do
            movefile "$dir/$fname" "$dir/$dirnum/$fname" || {
                msg "Subdirectory $dirnum - FAIL"
                error "can't move file: $dir/$fname to $dir/$dirnum/$fname"
                return 1
            }
        done
        IFS="$old_ifs"
        msg "Subdirectory $dirnum - OK"
    done
    return 0
}

# Count number of file groups in the directory.
#
# count_file_groups(dir, group_size)
# args:
#   dir - directory where to search files
#   group_size - size of one file group
# return:
#   number of groups
count_file_groups()
{
    local dir=$1
    local group_size=$2
    local num_of_files
    local out

    num_of_files=$(ls "$dir" | wc -l)
    out=$((num_of_files / group_size))
    if [ $((num_of_files % group_size)) -gt 0 ]; then
        out=$((out + 1))
    fi
    echo $out
}

# Make the subdirectory in the directory.
#
# makedir(dir, subdir)
# args:
#   dir - directory name where to make a subdirectory
#   subdir - subdirectory name to make
# return:
#   0 - if success
#   1 - if any error
makedir()
{
    local dir=$1
    local subdir=$2

    mkdir "$dir/$subdir" || return 1
    return 0
}

# Get first N file names from the directory.
#
# get_file_names(dir, number_of_files)
# args:
#   dir - directory where to search files
#   number_of_files - number of first files to take
# return:
#   filenames on separate lines
get_file_names()
{
    local dir=$1
    local number_of_files=$2

    find "$dir" -maxdepth 1 -type f -printf "%f\n" | \
        head -"$number_of_files"
}

# Move file from one directory to another.
#
# movefile(src, dst)
# args:
#   src - source file path
#   dst - destination file path
# return:
#   0 - if success
#   1 - if any error
movefile()
{
    local src=$1
    local dst=$2

    mv "$src" "$dst" || return 1
    return 0
}

main()
{
    case $# in
      0|1) usage; return 1;;
      2) process_files "$1" "$2" && return 0;;
      *) error "unknown arglist: \"$*\""; return 1;;
    esac
    return 1
}

main "$@" || exit 1

exit 0
