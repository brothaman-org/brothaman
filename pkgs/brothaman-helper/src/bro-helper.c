// bro-nsenter.c - Network namespace entry with FD preservation for socket activation
#define _GNU_SOURCE
#include <sched.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <pwd.h>
#include <stdlib.h>

static void die_msg(const char *m) { fprintf(stderr, "ERROR: %s\n", m); _exit(126); }
static void die_errno(const char *m) { perror(m); _exit(127); }

static int parse_pid(const char *s, pid_t *out) {
    if (!s || !*s) return 0;
    char *e = NULL;
    errno = 0;
    unsigned long v = strtoul(s, &e, 10);
    if (errno || !e || *e) return 0;
    if (v > 0x7fffffffUL) return 0;
    *out = (pid_t)v;
    return 1;
}



int main(int argc, char **argv) {
    pid_t target_pid = 0;
    int i = 1;
    
    // Parse arguments
    for (; i < argc; i++) {
        if (strcmp(argv[i], "--pid") == 0 && i + 1 < argc) {
            if (!parse_pid(argv[++i], &target_pid)) die_msg("bad --pid");
        } else if (strcmp(argv[i], "--") == 0) {
            i++;
            break;
        }
    }
    
    if (!target_pid || i >= argc) {
        fprintf(stderr, "usage: %s --pid PID -- <cmd> [args...]\n", argv[0]);
        return 2;
    }
    
    // Debug: Check what FDs and environment we have
    fprintf(stderr, "DEBUG: Available FDs before namespace entry:\n");
    for (int fd = 0; fd < 10; fd++) {
        if (fcntl(fd, F_GETFD) != -1) {
            fprintf(stderr, "  FD %d is open\n", fd);
        }
    }
    fprintf(stderr, "DEBUG: Environment variables:\n");
    char *listen_fds = getenv("LISTEN_FDS");
    char *listen_pid = getenv("LISTEN_PID");
    fprintf(stderr, "  LISTEN_FDS=%s\n", listen_fds ? listen_fds : "NOT SET");
    fprintf(stderr, "  LISTEN_PID=%s\n", listen_pid ? listen_pid : "NOT SET");
    
    // Use nsenter directly with the network namespace file
    // This preserves FDs without going through podman exec chain
    
    char netns_path[128];
    snprintf(netns_path, sizeof(netns_path), "/proc/%ld/ns/net", (long)target_pid);
    
    // Open the network namespace file
    int netns_fd = open(netns_path, O_RDONLY | O_CLOEXEC);
    if (netns_fd < 0) {
        // If direct access fails, we need to use podman unshare approach
        // But this means we'll lose FDs - this is the fundamental limitation
        die_errno("open netns - container network namespace not accessible");
    }
    
    // Join the network namespace directly  
    if (setns(netns_fd, CLONE_NEWNET) < 0) die_errno("setns(CLONE_NEWNET)");
    close(netns_fd);
    
    // Set up environment variables for systemd socket activation
    // LISTEN_FDS should be set to the number of socket FDs (typically 1)
    // LISTEN_PID should be set to our PID
    if (listen_fds && atoi(listen_fds) > 0) {
        // Set LISTEN_PID to current process PID for systemd-socket-proxyd
        char pid_str[32];
        snprintf(pid_str, sizeof(pid_str), "%d", getpid());
        setenv("LISTEN_PID", pid_str, 1);
        fprintf(stderr, "DEBUG: Set LISTEN_PID=%s for socket activation\n", pid_str);
    }
    
    // Execute the target command directly in the network namespace
    // File descriptors (including systemd socket FDs) are preserved
    execvp(argv[i], &argv[i]);
    die_errno("execvp");
    
    return 127;
}