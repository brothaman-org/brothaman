// fd_setns_exec.c  (adds --pid <PID> as an alternative to --netns PATH)
#define _GNU_SOURCE
#include <sched.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <libgen.h>
#include <sys/stat.h>
#include <sys/types.h>

static void die_msg(const char *m){fprintf(stderr,"ERROR: %s\n",m);_exit(126);}
static void die_errno(const char *m){perror(m);_exit(127);}

static int is_allowed_cmd(const char *b){
  const char *ok[]={"curl","ip","netstat","systemd-socket-proxyd",NULL};
  for(int i=0;ok[i];i++) if(strcmp(b,ok[i])==0) return 1; return 0;
}
static int parse_uint(const char *s, uid_t *out){
  if(!s||!*s) return 0; char *e=NULL; errno=0;
  unsigned long v=strtoul(s,&e,10); if(errno||!e||*e) return 0;
  if(v>0xFFFFFFFFul) return 0; *out=(uid_t)v; return 1;
}
static int parse_pid(const char *s, pid_t *out){
  if(!s||!*s) return 0; char *e=NULL; errno=0;
  unsigned long v=strtoul(s,&e,10); if(errno||!e||*e) return 0;
  if(v>0x7fffffffUL) return 0; *out=(pid_t)v; return 1;
}
static int extract_pid_from_proc_netns(const char *p, pid_t *out){
  if(strncmp(p,"/proc/",6)!=0) return 0;
  const char *q=p+6, *slash=strchr(q,'/'); if(!slash) return 0;
  char buf[32]; size_t n=(size_t)(slash-q); if(!n||n>=sizeof(buf)) return 0;
  memcpy(buf,q,n); buf[n]='\0'; if(strcmp(slash,"/ns/net")!=0) return 0;
  return parse_pid(buf,out);
}
static int extract_uid_from_run_user_netns(const char *p, uid_t *out){
  const char *pre="/run/user/"; size_t L=strlen(pre);
  if(strncmp(p,pre,L)!=0) return 0;
  const char *q=p+L, *slash=strchr(q,'/'); if(!slash) return 0;
  char buf[32]; size_t n=(size_t)(slash-q); if(!n||n>=sizeof(buf)) return 0;
  memcpy(buf,q,n); buf[n]='\0';
  if(strncmp(slash,"/netns/",7)!=0) return 0;
  return parse_uint(buf,out);
}

int main(int argc, char **argv){
  const char *netns=NULL; pid_t from_pid=0; int i=1;
  for(; i<argc; i++){
    if(strcmp(argv[i],"--netns")==0 && i+1<argc){ netns=argv[++i]; }
    else if(strcmp(argv[i],"--pid")==0 && i+1<argc){ if(!parse_pid(argv[++i],&from_pid)) die_msg("bad --pid"); }
    else if(strcmp(argv[i],"--")==0){ i++; break; }
  }
  if((!netns && !from_pid) || i>=argc){
    fprintf(stderr,"usage: %s [--netns PATH | --pid PID] -- <cmd> [args...]\n",argv[0]);
    return 2;
  }

  // Allowlist the command
  char *base=basename(argv[i]); if(!is_allowed_cmd(base)){
    fprintf(stderr,"Refusing to run disallowed command: %s\n",base); return 126;
  }

  uid_t me=getuid(); struct stat st;
  char netns_buf[128];
  if(from_pid){
    // Use /proc/PID/ns/net, and check owner of /proc/PID
    snprintf(netns_buf,sizeof(netns_buf),"/proc/%ld/ns/net",(long)from_pid);
    netns=netns_buf;
    char procdir[64]; snprintf(procdir,sizeof(procdir),"/proc/%ld",(long)from_pid);
    struct stat pst; if(stat(procdir,&pst)!=0) die_errno("stat(/proc/PID)");
    if(pst.st_uid!=me) die_msg("caller UID does not own target PID");
  }else{
    if(stat(netns,&st)!=0) die_errno("stat(netns)");
    // Accept only /proc/<PID>/ns/net or /run/user/<UID>/netns/<name>
    int ok_uid=0; pid_t pid=0;
    if(extract_pid_from_proc_netns(netns,&pid)){
      char procdir[64]; snprintf(procdir,sizeof(procdir),"/proc/%ld",(long)pid);
      struct stat pst; if(stat(procdir,&pst)!=0) die_errno("stat(/proc/PID)");
      if(pst.st_uid==me) ok_uid=1;
    }else{
      uid_t path_uid=0;
      if(extract_uid_from_run_user_netns(netns,&path_uid)){
        if(path_uid==me && st.st_uid==me) ok_uid=1;
      }
    }
    if(!ok_uid) die_msg("caller UID does not own the specified netns (or invalid netns path)");
  }

  int fd=open(netns,O_RDONLY|O_CLOEXEC); if(fd<0) die_errno("open(netns)");
  if(setns(fd,CLONE_NEWNET)<0) die_errno("setns(CLONE_NEWNET)");
  close(fd);
  execvp(argv[i],&argv[i]); die_errno("execvp"); return 127;
}
