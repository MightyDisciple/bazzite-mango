#define _GNU_SOURCE
#define _LARGEFILE64_SOURCE

#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <sys/vfs.h>

static const char *unity_disk_path(const char *path)
{
    const char *home = getenv("HOME");

    if (path && strcmp(path, "/") == 0 && home && home[0] == '/')
        return home;

    return path;
}

int statfs(const char *path, struct statfs *buffer)
{
    static int (*next_statfs)(const char *, struct statfs *);

    if (!next_statfs)
        next_statfs = dlsym(RTLD_NEXT, "statfs");

    return next_statfs(unity_disk_path(path), buffer);
}

int statfs64(const char *path, struct statfs64 *buffer)
{
    static int (*next_statfs64)(const char *, struct statfs64 *);

    if (!next_statfs64)
        next_statfs64 = dlsym(RTLD_NEXT, "statfs64");

    return next_statfs64(unity_disk_path(path), buffer);
}
