### Resources ###
[https://lwn.net/Articles/374424/](https://lwn.net/Articles/374424/)

[https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt](https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt)

### Requesting hugepages ###

Create the code, `mmap.c`:
~~~
#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>

#define PAGE_SIZE (unsigned int) 1024*1024*1024
#define NUM_PAGES 2

void main() {
	char * buf = mmap(
		NULL, 
		NUM_PAGES * PAGE_SIZE,
		PROT_READ | PROT_WRITE, 
		MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB,
		-1, 
		0
	); 
  	if (buf == MAP_FAILED) {
    		perror("mmap");
    		exit(1);
  	}

	char * line = NULL;
	size_t size;

	printf("Memory address %p\n", buf);
        printf("This will only reserve pages. Execute \n");
	printf("grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/\n");
        printf("find /sys -name meminfo | xargs grep -i huge\n");
	printf("to verify this.\n\n");
	printf("When you are done, please hit return\n");
        getline(&line,&size,stdin);
        int i;
	printf("Now, actually writing all 0s into the first hugepage\n");
        for(i = 0; i < PAGE_SIZE; i++) {
		buf[i] = '0';
	}
        printf("Now, verify again\n");
	printf("grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/\n");
        printf("find /sys -name meminfo | xargs grep -i huge\n");
	printf("to verify this.\n\n");
	printf("When you are done, please hit return\n");
        getline(&line,&size,stdin);

	printf("Now, actually writing one 0 into the second hugepage\n");
	for(; i < PAGE_SIZE + 1; i++) {
                buf[i] = '0';
        }
        printf("Now, verify again\n");
	printf("grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/\n");
        printf("find /sys -name meminfo | xargs grep -i huge\n");
	printf("to verify this.\n\n");
	printf("When you are done, please hit return to end the program\n");
        getline(&line,&size,stdin);
}
~~~

Compile this:
~~~
gcc mmap.c  -o mmap
~~~

Run the binary and follow the onscreen instructions:
~~~
[root@dell-r430-30 ~]# ./mmap 
Memory address 0x2aaac0000000
This will only reserve pages. Execute 
grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/
find /sys -name meminfo | xargs grep -i huge
to verify this.

When you are done, please hit return
Now, actually writing all 0s into the first hugepage
^C
[root@dell-r430-30 ~]# ^C
[root@dell-r430-30 ~]# ^C
[root@dell-r430-30 ~]# gcc mmap.c  -o mmap
[root@dell-r430-30 ~]# ./mmap 
Memory address 0x2aaac0000000
This will only reserve pages. Execute 
grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/
find /sys -name meminfo | xargs grep -i huge
to verify this.

When you are done, please hit return

Now, actually writing all 0s into the first hugepage
Now, verify again
grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/
find /sys -name meminfo | xargs grep -i huge
to verify this.

When you are done, please hit return

Now, actually writing one 0 into the second hugepage
Now, verify again
grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/
find /sys -name meminfo | xargs grep -i huge
to verify this.

When you are done, please hit return to end the program
~~~

Verify reserved hugepages and actually allocated hugepages. 
Also note that writing 1GB to the hugepage actually takes quite some time:
~~~
[root@dell-r430-30 ~]# grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/
/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_overcommit_hugepages:0
/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages:32
/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages_mempolicy:32
/sys/kernel/mm/hugepages/hugepages-1048576kB/surplus_hugepages:0
/sys/kernel/mm/hugepages/hugepages-1048576kB/resv_hugepages:2
/sys/kernel/mm/hugepages/hugepages-1048576kB/free_hugepages:32
[root@dell-r430-30 ~]# find /sys -name meminfo | xargs grep -i huge
/sys/devices/system/node/node0/meminfo:Node 0 AnonHugePages:         0 kB
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Total:    16
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Free:     16
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Surp:      0
/sys/devices/system/node/node1/meminfo:Node 1 AnonHugePages:      6144 kB
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Total:    16
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Free:     16
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Surp:      0
[root@dell-r430-30 ~]# grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/
/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_overcommit_hugepages:0
/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages:32
/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages_mempolicy:32
/sys/kernel/mm/hugepages/hugepages-1048576kB/surplus_hugepages:0
/sys/kernel/mm/hugepages/hugepages-1048576kB/resv_hugepages:1
/sys/kernel/mm/hugepages/hugepages-1048576kB/free_hugepages:31
[root@dell-r430-30 ~]# find /sys -name meminfo | xargs grep -i huge
/sys/devices/system/node/node0/meminfo:Node 0 AnonHugePages:         0 kB
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Total:    16
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Free:     15
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Surp:      0
/sys/devices/system/node/node1/meminfo:Node 1 AnonHugePages:      6144 kB
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Total:    16
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Free:     16
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Surp:      0
[root@dell-r430-30 ~]# grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/
/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_overcommit_hugepages:0
/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages:32
/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages_mempolicy:32
/sys/kernel/mm/hugepages/hugepages-1048576kB/surplus_hugepages:0
/sys/kernel/mm/hugepages/hugepages-1048576kB/resv_hugepages:0
/sys/kernel/mm/hugepages/hugepages-1048576kB/free_hugepages:30
[root@dell-r430-30 ~]# find /sys -name meminfo | xargs grep -i huge
/sys/devices/system/node/node0/meminfo:Node 0 AnonHugePages:         0 kB
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Total:    16
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Free:     14
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Surp:      0
/sys/devices/system/node/node1/meminfo:Node 1 AnonHugePages:      6144 kB
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Total:    16
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Free:     16
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Surp:      0
[root@dell-r430-30 ~]# find /sys -name meminfo | xargs grep -i huge
/sys/devices/system/node/node0/meminfo:Node 0 AnonHugePages:         0 kB
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Total:    16
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Free:     16
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Surp:      0
/sys/devices/system/node/node1/meminfo:Node 1 AnonHugePages:      6144 kB
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Total:    16
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Free:     16
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Surp:      0
~~~

#### Allocating hugepages right away ####

Instead of having to write to the hugepage to allocate it, we can populate the page right away and it will show up in used pages right away:
~~~
man mmap
(...)
       MAP_POPULATE (since Linux 2.5.46)
              Populate (prefault) page tables for a mapping.  For a file mapping, this  causes  read-ahead  on  the
              file.   Later  accesses to the mapping will not be blocked by page faults.  MAP_POPULATE is supported
              for private mappings only since Linux 2.6.23.
(...)
~~~

The applcation is:
~~~
#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>

#define PAGE_SIZE (unsigned int) 1024*1024*1024
#define NUM_PAGES 2

void main() {
	char * buf = mmap(
		NULL, 
		NUM_PAGES * PAGE_SIZE,
		PROT_READ | PROT_WRITE, 
		MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB | MAP_POPULATE,
		-1, 
		0
	); 
  	if (buf == MAP_FAILED) {
    		perror("mmap");
    		exit(1);
  	}

	char * line = NULL;
	size_t size;

	printf("Memory address %p\n", buf);
        printf("This will only reserve and populate pages. Execute \n");
	printf("grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/\n");
        printf("find /sys -name meminfo | xargs grep -i huge\n");
	printf("to verify this.\n\n");
	printf("When you are done, please hit return\n");
        getline(&line,&size,stdin);
}
~~~

Testing:
~~~
[root@dell-r430-30 ~]# gcc mmap2.c -o mmap2
[root@dell-r430-30 ~]# ./mmap2 
Memory address 0x2aaac0000000
This will only reserve and populate pages. Execute 
grep -R '' /sys/kernel/mm/hugepages/hugepages-1048576kB/
find /sys -name meminfo | xargs grep -i huge
to verify this.

When you are done, please hit return

~~~

~~~
[root@dell-r430-30 ~]# find /sys -name meminfo | xargs grep -i huge
/sys/devices/system/node/node0/meminfo:Node 0 AnonHugePages:         0 kB
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Total:    16
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Free:     16
/sys/devices/system/node/node0/meminfo:Node 0 HugePages_Surp:      0
/sys/devices/system/node/node1/meminfo:Node 1 AnonHugePages:      6144 kB
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Total:    16
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Free:     14
/sys/devices/system/node/node1/meminfo:Node 1 HugePages_Surp:      0
[root@dell-r430-30 ~]# 
~~~

### Sharing hugepages between processes ###

In vhost_user, OVS-DPDK and qemu-kvm instances share the same hugepages for DMA copies. [https://access.redhat.com/solutions/3394851](https://access.redhat.com/solutions/3394851). Let's emulate this with 2 sample applications.

