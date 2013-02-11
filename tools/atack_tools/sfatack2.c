#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<sys/types.h>
#include<pthread.h>
#include<unistd.h>  // usleep
#include <limits.h>

// socket
#include<sys/socket.h>
#include<netinet/in.h>
#include<arpa/inet.h>
#include<netdb.h>

// time
#include <sys/resource.h>

//==========================================================
// global
int atack_start = 0;
char *host  = NULL;
char *ip    = NULL;
char *path  = NULL;
int  *ilist = NULL;  // thread index list

//==========================================================
void *atack(void *arg) {
	pid_t     pid;  // process id
	pthread_t tid;  // thread id
	struct sockaddr_in addr;
	int sock;
	char *msg;
	int l, ret;
	char buf[64];  // recv buf
	ssize_t recv_size = 0;
	ssize_t send_size = 0;
	//struct rusage usage;
	//struct timeval ut1, ut2;
	//struct timeval st1, st2;
	
	// get info
	pid = getpid();
	tid = pthread_self();
	
	// malloc
	l = strlen(host) + strlen(path) + 64;
	msg = malloc(l);
	if(msg == NULL) {
		fprintf(stderr, "[%6d] pid=%d, tid=%ld : cannot do malloc().\n", *((int*)arg), pid, (long)tid);
		return NULL;
	}
	
	// wait
	while( ! atack_start ) {
		usleep(10000);  // timer accuracy 10ms = 10000us
	}
	
	// atack start
	printf("[%6d] atack to %s %s: pid=%d, tid=%ld\n", *((int*)arg), host, path, pid, (long)tid);
	
	// socket setup
	memset(&addr, 0, sizeof(struct sockaddr_in));
	addr.sin_family      = AF_INET;
	addr.sin_port        = htons(80);
	addr.sin_addr.s_addr = inet_addr(ip);
	sock = socket(AF_INET, SOCK_STREAM, 0);
	
	// connect
	//getrusage(RUSAGE_SELF, &usage );
	//ut1 = usage.ru_utime;
	//st1 = usage.ru_stime;
	ret = connect( sock, (struct sockaddr*)(&addr), sizeof(struct sockaddr_in) );
	
	// send
	sprintf(msg, "GET %s HTTP/1.1\r\nHost: %s\r\n\r\n", path, host);
	printf("[DEBUG]msg : %s\n",msg);
	send_size = send(sock, msg, strlen(msg), 0);
	
	// recv
	while(1) {
		recv_size = recv(sock, buf, 1, 0);  // only 1 byte
		if(recv_size == -1) {
			fprintf(stderr, "[%6d] pid=%d, tid=%ld : recv() socket error.\n", *((int*)arg), pid, (long)tid);
			break;
		}
		if(recv_size == 0) {
			break;
		}
		putchar(buf[0]);
		fflush(stdout);
		//usleep(10000);  // delay
	}
	
	// finish
	close(sock);
	//getrusage(RUSAGE_SELF, &usage );
	//ut2 = usage.ru_utime;
	//st2 = usage.ru_stime;
	//printf("user time = %lf, ", (ut2.tv_sec - ut1.tv_sec) + (ut2.tv_usec - ut1.tv_usec)*1.0E-6);
	//printf("sys  time = %lf\n", (st2.tv_sec - st1.tv_sec) + (st2.tv_usec - st1.tv_usec)*1.0E-6);
	//printf("[DEBUG]finished\n");
	
	return arg;
}


pthread_attr_t make_min_stack()
{
long default_stack_size = 10485760;

pthread_attr_t attr;
pthread_attr_init(&attr);
//pthread_attr_setstacksize(&attr, PTHREAD_STACK_MIN + 1000);

pthread_attr_setstacksize(&attr, default_stack_size);
//printf("[DEBUG]PTHREAD_STACK_MIN : %d\n", PTHREAD_STACK_MIN);

size_t stacksize;
pthread_attr_getstacksize (&attr, &stacksize);
//printf("[DEBUG]new stack size = %d\n", (int)stacksize);

return attr;
}


//==========================================================
int main(int ac, char *av[]) {
	pid_t      pid;    // process id
	pthread_t *tlist;  // thread id list
	void *result;
	int thread_num;
	int status;
	int i;
	int count_down;
	struct rusage usage;
	struct timeval ut1, ut2;
	struct timeval st1, st2;
	
	//-------------------------------------
	// check args
	if(ac != 6) {
		fprintf(stderr, "Usage: %s thread_num count_down hostname ipaddr path\n", av[0]);
		return 1;
	}

	// thread size
	pthread_attr_t attr = make_min_stack();
	
	// thread num
	thread_num = atoi(av[1]);
	if(thread_num <= 0) {
		fprintf(stderr, "Error: thread_num must be greater than 0.\n");
		return 1;
	}
	
	// count_down
	count_down = atoi(av[2]);
	if(count_down < 0) count_down = 0;
	
	// url
	host = av[3];
	ip   = av[4];
	path = av[5];
	
	//-------------------------------------
	// malloc
	//printf("[DEBUG]malloc size : %lu bytes\n", sizeof(pthread_t) * thread_num + sizeof(int) * thread_num);
	tlist = malloc(sizeof(pthread_t) * thread_num);
	ilist = malloc(sizeof(int)       * thread_num);
	
	// get info
	pid = getpid();
	
	// create thread
	//printf("[DEBUG]create thread start\n");
	for(i=0; i<thread_num; i++) {
		ilist[i] = i;
		status = pthread_create(tlist+i, &attr, atack, (void*)(ilist+i));
		if( status != 0 ) {
			fprintf(stderr, "Error: cannot create a thread: %d\n", i);
			tlist[i] = 0;
		}else{
			//printf("%d,", i);
		}
	}
	//printf("[DEBUG]create thread end\n");
	
	//-------------------------------------
	// count down
	for(i=count_down; i>0; i--) {
		fprintf(stderr, "%d\n", i);
		sleep(1);
	}
	atack_start = 1;

	getrusage(RUSAGE_SELF, &usage );
	ut1 = usage.ru_utime;
	st1 = usage.ru_stime;
	
	//-------------------------------------
	// join
	for(i=0; i<thread_num; i++) {
		if(tlist[i] == 0) {
			continue;
		}
		pthread_join(tlist[i], &result);
	}
	
	//-------------------------------------
	// free : not required
	//free(tlist);

	getrusage(RUSAGE_SELF, &usage );
	ut2 = usage.ru_utime;
	st2 = usage.ru_stime;
	printf("\nAll request-responce finished during: %lf sec\n", (st2.tv_sec - st1.tv_sec) + (st2.tv_usec - st1.tv_usec)*1.0E-6);
	//printf(" user time = %lf, ", (ut2.tv_sec - ut1.tv_sec) + (ut2.tv_usec - ut1.tv_usec)*1.0E-6);
	//printf(" sys  time = %lf\n", (st2.tv_sec - st1.tv_sec) + (st2.tv_usec - st1.tv_usec)*1.0E-6);
	printf("Throughput: %lf pageview/sec\n",1/(((st2.tv_sec - st1.tv_sec) + (st2.tv_usec - st1.tv_usec)*1.0E-6)/thread_num));
	
	return 0;
}


