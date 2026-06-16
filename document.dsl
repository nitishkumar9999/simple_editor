$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true
    
 
$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true
    
$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true
    
 
$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true
$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true
    
 
$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true

$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to understand where each topic fits in the broader systems programming landscape.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.


$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to understand where each topic fits in the broader systems programming landscape.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.

$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to understand where each topic fits in the broader systems programming landscape.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.


$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to un
$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true
    
 
$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true
$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true
    
 
$TOC

$H1 - The Complete Guide to Modern Systems Programming

$H2 - Chapter 1: Introduction
$P - This is a comprehensive guide to systems programming covering everything from memory management to concurrency. "$B - Systems programming" requires a deep understanding of how computers work at a fundamental level.

$H2 - Chapter 2: Memory Management
$P - Memory management is one of the most critical aspects of systems programming. "$I - Understanding memory" means understanding how your program interacts with hardware.

$BQ
    Memory is the foundation of all computation. Without careful management, even the most elegant algorithms will fail.
    -- Donald Knuth

$H3 - Stack vs Heap
$P - The stack is fast but limited. The heap is flexible but requires careful management. "$B - Stack allocation" is automatic while "$B - heap allocation" requires explicit management in languages like C and Rust.

$UL
    Stack memory is automatically managed by the compiler
    Heap memory requires explicit allocation and deallocation
    Stack frames are created and destroyed with function calls
    Heap fragmentation can cause performance issues over time
    Modern allocators use sophisticated algorithms to minimize fragmentation

$H3 - Memory Safety
$P - "$BI - Memory safety" is the property of a program that guarantees it will never access memory it should not. Rust achieves this through its ownership system without a garbage collector.

$OL
    Ownership rules are checked at compile time
    Each value has exactly one owner at any time
    When the owner goes out of scope the value is dropped
    References must always be valid
    Mutable references are exclusive

$H2 - Chapter 3: Concurrency
$P - Concurrency is the ability of a program to make progress on multiple tasks simultaneously. "$B - True parallelism" requires multiple CPU cores while concurrency can be achieved on a single core through interleaving.

$BQ
    Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
    -- Rob Pike

$H3 - Threads
$P - Threads are the most basic unit of concurrency in most operating systems. Each thread has its own stack but shares the heap with other threads in the same process.

$CODE - rust
    use std::thread;
    use std::sync::{Arc, Mutex};

    fn main() {
        let counter = Arc::new(Mutex::new(0));
        let mut handles = vec![];

        for _ in 0..10 {
            let counter = Arc::clone(&counter);
            let handle = thread::spawn(move || {
                let mut num = counter.lock().unwrap();
                *num += 1;
            });
            handles.push(handle);
        }

        for handle in handles {
            handle.join().unwrap();
        }

        println!("Result: {}", *counter.lock().unwrap());
    }

$H3 - Async Programming
$P - Async programming allows a single thread to handle many concurrent operations by suspending execution while waiting for IO. "$ICODE - async/await" syntax makes this ergonomic in modern languages.

$CODE - rust
    use tokio;

    #[tokio::main]
    async fn main() {
        let result = fetch_data().await;
        println!("{}", result);
    }

    async fn fetch_data() -> String {
        tokio::time::sleep(
            tokio::time::Duration::from_millis(100)
        ).await;
        String::from("data fetched")
    }

$H3 - Synchronization Primitives
$P - When multiple threads access shared data you need synchronization primitives to prevent data races and ensure correctness.

$TB
    | Primitive | Use Case | Overhead |
    |-----------|----------|----------|
    | Mutex | Exclusive access to data | Medium |
    | RwLock | Multiple readers or one writer | Medium |
    | Atomic | Simple numeric operations | Low |
    | Channel | Message passing between threads | Low |
    | Barrier | Synchronize multiple threads | Low |
    | Semaphore | Limit concurrent access | Low |

$H2 - Chapter 4: Data Structures
$P - Choosing the right data structure is fundamental to writing efficient programs. "$B - Time complexity" and "$B - space complexity" are the two primary metrics for evaluating data structures.

$H3 - The Rope Data Structure
$P - A rope is a binary tree where each leaf holds a string and each internal node holds the sum of the lengths of all leaves in its left subtree. "$BI - Ropes excel" at operations like insert and delete in the middle of large strings.

$BQ
    The rope data structure was introduced by Boehm, Atkinson and Plass in 1995 and has been used in text editors ever since.
    -- Hans Boehm

$TB
    | Operation | Array | Rope |
    |-----------|-------|------|
    | Index | O(1) | O(log n) |
    | Insert | O(n) | O(log n) |
    | Delete | O(n) | O(log n) |
    | Concat | O(n) | O(log n) |
    | Split | O(n) | O(log n) |
    | Iterate | O(n) | O(n) |

$H3 - P-adic Valuations in Rope Balancing
$P - The p-adic valuation of an integer n with respect to prime p is the largest power of p that divides n. "$B - Using p-adic valuations" as merge scores produces semantically clustered trees where related blocks naturally group together.

$CODE - rust
    fn valuation_p(n: usize, p: usize) -> usize {
        if n == 0 { return usize::MAX; }
        let mut count = 0;
        let mut n = n;
        while n % p == 0 {
            n /= p;
            count += 1;
        }
        count
    }

    fn merge_score(left: &Node, right: &Node) -> i64 {
        let total = left.total() + right.total();
        let p = block_prime(left).max(block_prime(right));
        let valuation = valuation_p(total, p) as i64;
        let size_diff = (left.total() as i64 - right.total() as i64).abs();
        let penalty = if size_diff > 0 {
            (size_diff as f64).log2() as i64
        } else {
            0
        };
        valuation - penalty
    }

$H3 - Hash Maps
$P - Hash maps provide O(1) average case lookup insert and delete. They work by computing a hash of the key and using that to index into an array of buckets.

$UL
    Open addressing stores all elements in the hash table itself
    Chaining stores elements in linked lists at each bucket
    Robin Hood hashing reduces variance in probe lengths
    Swiss tables use SIMD instructions for fast lookup
    The load factor determines when to resize the table

$H3 - Trees
$P - Trees are hierarchical data structures with a root node and zero or more children. "$B - Binary search trees" allow O(log n) lookup when balanced.

$OL
    AVL trees maintain strict height balance
    Red-black trees use color properties to stay balanced
    B-trees are optimized for disk access patterns
    Tries are optimized for string prefix operations
    Segment trees support range queries efficiently

$H2 - Chapter 5: Algorithms
$P - Algorithms are step-by-step procedures for solving problems. "$I - Algorithm design" involves choosing the right approach for the problem at hand.

$H3 - Sorting
$P - Sorting is one of the most studied problems in computer science. Different algorithms have different trade-offs between time complexity space complexity and stability.

$TB
    | Algorithm | Best | Average | Worst | Stable |
    |-----------|------|---------|-------|--------|
    | Quicksort | O(n log n) | O(n log n) | O(n²) | No |
    | Mergesort | O(n log n) | O(n log n) | O(n log n) | Yes |
    | Heapsort | O(n log n) | O(n log n) | O(n log n) | No |
    | Timsort | O(n) | O(n log n) | O(n log n) | Yes |
    | Radix sort | O(nk) | O(nk) | O(nk) | Yes |

$H3 - Graph Algorithms
$P - Graphs model relationships between entities. "$B - Graph traversal" algorithms like BFS and DFS are the foundation for many more complex algorithms.

$CODE - rust
    use std::collections::{HashMap, HashSet, VecDeque};

    fn bfs(graph: &HashMap<usize, Vec<usize>>, start: usize) -> Vec<usize> {
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = vec![];

        queue.push_back(start);
        visited.insert(start);

        while let Some(node) = queue.pop_front() {
            order.push(node);
            if let Some(neighbors) = graph.get(&node) {
                for &neighbor in neighbors {
                    if !visited.contains(&neighbor) {
                        visited.insert(neighbor);
                        queue.push_back(neighbor);
                    }
                }
            }
        }
        order
    }

$H3 - Dynamic Programming
$P - Dynamic programming solves complex problems by breaking them into overlapping subproblems and storing the results. "$BI - Memoization" stores the results of expensive function calls.

$UL
    Identify the optimal substructure property
    Define the recurrence relation clearly
    Choose between top-down memoization and bottom-up tabulation
    Analyze the time and space complexity of your solution
    Consider space optimization by rolling arrays when possible

$H2 - Chapter 6: Systems Design
$P - Systems design involves making high-level decisions about how to structure large software systems. "$B - Scalability" "$B - reliability" and "$B - maintainability" are the three pillars of good systems design.

$H3 - Distributed Systems
$P - Distributed systems are collections of independent computers that appear to users as a single coherent system. They introduce fundamental challenges around consistency availability and partition tolerance.

$BQ
    A distributed system is one in which the failure of a computer you did not even know existed can render your own computer unusable.
    -- Leslie Lamport

$TB
    | CAP Property | Description | Example |
    |--------------|-------------|---------|
    | Consistency | All nodes see same data | Traditional RDBMS |
    | Availability | System always responds | DynamoDB |
    | Partition Tolerance | Works despite network splits | Cassandra |

$H3 - Caching
$P - Caching stores frequently accessed data in fast storage to reduce latency and load on slower systems. "$B - Cache invalidation" is famously one of the hardest problems in computer science.

$OL
    Determine what data is worth caching based on access patterns
    Choose an appropriate eviction policy like LRU or LFU
    Set appropriate TTL values to prevent stale data
    Consider cache stampede protection for high traffic systems
    Monitor cache hit rates and adjust capacity accordingly

$H3 - Message Queues
$P - Message queues decouple producers from consumers allowing them to operate at different rates. They provide durability buffering and load leveling for distributed systems.

$CODE - rust
    use std::sync::mpsc;
    use std::thread;

    fn main() {
        let (tx, rx) = mpsc::channel();

        thread::spawn(move || {
            let messages = vec!["hello", "world", "from", "producer"];
            for msg in messages {
                tx.send(msg).unwrap();
                thread::sleep(
                    std::time::Duration::from_millis(50)
                );
            }
        });

        for received in rx {
            println!("Got: {}", received);
        }
    }

$H2 - Chapter 7: Performance Engineering
$P - Performance engineering is the discipline of making software run faster and use fewer resources. "$I - Premature optimization" is the root of all evil but informed optimization is essential.

$H3 - Profiling
$P - Profiling measures where a program spends its time and allocates memory. You cannot optimize what you cannot measure.

$UL
    CPU profilers measure which functions consume the most time
    Memory profilers track allocation patterns and detect leaks
    Cache profilers show cache miss rates and memory access patterns
    Flame graphs visualize the call stack over time
    Sampling profilers have low overhead suitable for production

$H3 - SIMD and Vectorization
$P - SIMD stands for Single Instruction Multiple Data. It allows one instruction to operate on multiple data elements simultaneously. "$B - Auto-vectorization" is when compilers automatically generate SIMD instructions.

$TB
    | ISA | Width | Elements (f32) | Year |
    |-----|-------|----------------|------|
    | SSE2 | 128-bit | 4 | 2001 |
    | AVX | 256-bit | 8 | 2011 |
    | AVX-512 | 512-bit | 16 | 2016 |
    | NEON | 128-bit | 4 | 2004 |
    | SVE | Variable | Variable | 2019 |

$H3 - Memory Hierarchy
$P - Modern CPUs have multiple levels of cache with different sizes and latencies. "$B - Cache-friendly code" accesses memory in sequential patterns to maximize cache utilization.

$BQ
    The memory wall is the growing disparity between processor speed and memory speed. Cache hierarchies are our primary tool for bridging this gap.
    -- William Wulf

$OL
    L1 cache is smallest and fastest typically 32-64KB per core
    L2 cache is larger and slower typically 256KB-1MB per core
    L3 cache is shared between cores typically 8-32MB
    DRAM is much slower with latencies around 100 nanoseconds
    NVMe SSDs are orders of magnitude slower than DRAM

$H2 - Chapter 8: Type Systems
$P - A type system is a set of rules that assigns types to expressions in a programming language. "$B - Strong static type systems" catch entire classes of bugs at compile time.

$H3 - Algebraic Data Types
$P - Algebraic data types are composite types formed by combining other types. "$B - Sum types" represent alternatives while "$B - product types" represent combinations.

$CODE - rust
    enum Shape {
        Circle { radius: f64 },
        Rectangle { width: f64, height: f64 },
        Triangle { base: f64, height: f64 },
    }

    impl Shape {
        fn area(&self) -> f64 {
            match self {
                Shape::Circle { radius } => 
                    std::f64::consts::PI * radius * radius,
                Shape::Rectangle { width, height } => 
                    width * height,
                Shape::Triangle { base, height } => 
                    0.5 * base * height,
            }
        }
    }

$H3 - Generics and Traits
$P - Generics allow writing code that works with multiple types. Traits define shared behavior that types can implement. "$BI - Zero cost abstractions" means you pay no runtime penalty for using them.

$UL
    Monomorphization generates specialized code for each concrete type
    Trait objects use dynamic dispatch for runtime polymorphism
    Associated types allow traits to define related types
    Lifetime parameters track how long references are valid
    Where clauses express complex trait bounds clearly

$H2 - Chapter 9: Compiler Design
$P - Compilers translate source code into machine code or other representations. Understanding compiler design helps you write better code and understand language behavior.

$H3 - Lexing and Parsing
$P - The first phase of compilation is lexing which breaks source text into tokens. Parsing then builds an abstract syntax tree from those tokens.

$TB
    | Phase | Input | Output |
    |-------|-------|--------|
    | Lexing | Source text | Token stream |
    | Parsing | Token stream | AST |
    | Semantic analysis | AST | Typed AST |
    | IR generation | Typed AST | IR |
    | Optimization | IR | Optimized IR |
    | Code generation | Optimized IR | Machine code |

$H3 - Intermediate Representations
$P - Compilers use intermediate representations to separate the front end from the back end. "$B - SSA form" Static Single Assignment makes many optimizations easier to implement.

$CODE - rust
    pub enum Expr {
        Literal(i64),
        Variable(String),
        BinOp {
            op: BinOpKind,
            left: Box<Expr>,
            right: Box<Expr>,
        },
        Call {
            func: String,
            args: Vec<Expr>,
        },
    }

    pub enum BinOpKind {
        Add, Sub, Mul, Div,
        Eq, Ne, Lt, Gt, Le, Ge,
        And, Or,
    }

$H2 - Chapter 10: Operating Systems
$P - Operating systems manage hardware resources and provide abstractions for application programs. "$B - The kernel" is the core of the operating system running in privileged mode.

$H3 - Process Management
$P - The operating system creates schedules and terminates processes. Each process has its own address space registers and file descriptors.

$BQ
    An operating system is a collection of things that don't fit into a language. There should be no operating system.
    -- Dan Ingalls

$UL
    Process creation via fork and exec on Unix systems
    Context switching saves and restores CPU state
    Scheduling algorithms balance fairness and throughput
    Inter-process communication via pipes sockets and shared memory
    Signals provide asynchronous notification between processes

$H3 - Virtual Memory
$P - Virtual memory gives each process the illusion of having its own large contiguous address space. The hardware MMU translates virtual addresses to physical addresses.

$OL
    Page tables map virtual pages to physical frames
    The TLB caches recent address translations for speed
    Page faults occur when a page is not in physical memory
    Demand paging loads pages only when they are accessed
    Copy-on-write defers copying until a write occurs

$H3 - File Systems
$P - File systems organize data on storage devices. "$B - Journaling" file systems maintain a log of changes to recover from crashes safely.

$TB
    | File System | Journal | Max File | Max Volume |
    |-------------|---------|----------|------------|
    | ext4 | Yes | 16TB | 1EB |
    | XFS | Yes | 8EB | 8EB |
    | Btrfs | CoW | 16EB | 16EB |
    | ZFS | CoW | 16EB | 256ZB |
    | NTFS | Yes | 16TB | 256TB |
    
$H2 - Chapter 11: Networking
$P - Networking is the backbone of modern distributed systems. "$B - The TCP/IP stack" provides the foundation for all internet communication through layered abstractions.

$H3 - The OSI Model
$P - The OSI model divides network communication into seven layers each with a specific responsibility. "$I - Understanding the layers" helps you debug network issues at the right level of abstraction.

$TB
    | Layer | Name | Protocol Examples |
    |-------|------|-------------------|
    | 7 | Application | HTTP, DNS, SMTP |
    | 6 | Presentation | TLS, SSL |
    | 5 | Session | RPC, NetBIOS |
    | 4 | Transport | TCP, UDP |
    | 3 | Network | IP, ICMP |
    | 2 | Data Link | Ethernet, WiFi |
    | 1 | Physical | Cables, Radio |

$H3 - TCP vs UDP
$P - TCP provides reliable ordered delivery with flow control and congestion control. UDP provides fast unreliable delivery suitable for real-time applications where latency matters more than reliability.

$UL
    TCP uses a three-way handshake to establish connections
    UDP has no connection establishment overhead
    TCP guarantees delivery and ordering of packets
    UDP packets may arrive out of order or not at all
    TCP has built-in congestion control via slow start
    UDP is preferred for DNS queries and video streaming

$H3 - Zero Copy Networking
$P - Zero copy techniques avoid copying data between kernel and user space. "$B - sendfile" and "$B - io_uring" allow the kernel to send data directly from file descriptors to network sockets.

$CODE - rust
    use std::os::unix::io::AsRawFd;
    use std::net::TcpStream;
    use std::fs::File;

    fn send_file(stream: &TcpStream, file: &File) -> std::io::Result<()> {
        let file_fd   = file.as_raw_fd();
        let sock_fd   = stream.as_raw_fd();
        let file_size = file.metadata()?.len() as usize;
        let mut offset: i64 = 0;
        let mut remaining = file_size;
        while remaining > 0 {
            let sent = unsafe {
                libc::sendfile(
                    sock_fd,
                    file_fd,
                    &mut offset,
                    remaining,
                )
            };
            if sent < 0 { return Err(std::io::Error::last_os_error()); }
            remaining -= sent as usize;
        }
        Ok(())
    }

$H3 - HTTP and REST
$P - HTTP is the foundation of the web. "$B - REST" Representational State Transfer is an architectural style that uses HTTP verbs to represent operations on resources.

$TB
    | Verb | Operation | Idempotent |
    |------|-----------|------------|
    | GET | Read | Yes |
    | POST | Create | No |
    | PUT | Replace | Yes |
    | PATCH | Update | No |
    | DELETE | Remove | Yes |

$H2 - Chapter 12: Security
$P - Security is not a feature you add at the end. "$B - Threat modeling" during design is essential for building systems that are secure by default.

$H3 - Cryptography Primitives
$P - Modern cryptography is built on mathematical problems that are easy to compute in one direction but hard to reverse. "$BI - Never roll your own crypto" — use well-audited libraries instead.

$UL
    Symmetric encryption uses the same key for encrypt and decrypt
    Asymmetric encryption uses a public key to encrypt and private to decrypt
    Hash functions produce fixed-size digests of arbitrary input
    MACs provide both integrity and authenticity guarantees
    Key derivation functions stretch passwords into cryptographic keys
    Digital signatures prove authenticity without sharing secrets

$H3 - Common Vulnerabilities
$P - Understanding common vulnerabilities is the first step to avoiding them. "$B - The OWASP Top 10" is the canonical reference for web application security risks.

$OL
    Buffer overflows write past the end of allocated memory
    SQL injection inserts malicious queries through user input
    Cross-site scripting injects scripts into web pages
    Use-after-free accesses memory after it has been freed
    Integer overflow wraps arithmetic past type boundaries
    Race conditions allow concurrent access to corrupt shared state
    Path traversal escapes intended directory boundaries

$H3 - Secure Coding in Rust
$P - Rust eliminates entire classes of memory safety vulnerabilities at compile time. "$I - Safe Rust" prevents buffer overflows use-after-free and data races by construction.

$CODE - rust
    fn safe_index(slice: &[u8], index: usize) -> Option<u8> {
        slice.get(index).copied()
    }

    fn safe_parse(input: &str) -> Result<u64, std::num::ParseIntError> {
        input.trim().parse::<u64>()
    }

    fn safe_concat(a: &str, b: &str) -> String {
        let mut result = String::with_capacity(a.len() + b.len());
        result.push_str(a);
        result.push_str(b);
        result
    }

$H2 - Chapter 13: Storage Engines
$P - Storage engines are the lowest level of database systems responsible for reading and writing data to disk. "$B - B-tree" and "$B - LSM-tree" are the two dominant storage engine architectures.

$H3 - B-Tree Storage
$P - B-trees keep data sorted and allow searches insertions and deletions in O(log n) time. They are optimized for systems that read and write large blocks of data.

$BQ
    The B-tree is the data structure that made relational databases possible. Every major RDBMS uses a B-tree variant as its primary storage structure.
    -- Joe Hellerstein

$TB
    | Property | B-Tree | LSM-Tree |
    |----------|--------|----------|
    | Read | O(log n) | O(log n) |
    | Write | O(log n) | O(1) amortized |
    | Space | 1-2x | 1-10x |
    | Write amp | Low | High |
    | Read amp | Low | Medium |
    | Use case | OLTP reads | Write heavy |

$H3 - LSM Trees
$P - Log-structured merge trees buffer writes in memory and flush them to disk in sorted runs. "$B - Compaction" merges sorted runs to maintain read performance over time.

$OL
    Writes go to an in-memory memtable first
    Memtable is flushed to disk as an immutable SSTable
    SSTables are organized into levels by size
    Compaction merges SSTables and removes deleted keys
    Bloom filters avoid unnecessary disk reads for missing keys
    Block cache keeps hot data in memory for fast reads

$H3 - Write Ahead Logging
$P - Write ahead logging ensures durability by writing changes to a log before applying them to data files. "$B - WAL" allows the database to recover to a consistent state after a crash.

$CODE - rust
    use std::fs::{File, OpenOptions};
    use std::io::Write;

    struct WAL {
        file: File,
    }

    impl WAL {
        pub fn new(path: &str) -> std::io::Result<Self> {
            let file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)?;
            Ok(WAL { file })
        }

        pub fn append(&mut self, entry: &[u8]) -> std::io::Result<()> {
            let len = (entry.len() as u32).to_le_bytes();
            self.file.write_all(&len)?;
            self.file.write_all(entry)?;
            self.file.sync_data()?;
            Ok(())
        }
    }

$H2 - Chapter 14: Language Runtimes
$P - Language runtimes provide the environment in which programs execute. They manage memory scheduling and provide standard library services.

$H3 - Garbage Collection Algorithms
$P - Garbage collectors automatically reclaim memory that is no longer reachable. "$B - Tracing collectors" traverse the object graph while "$B - reference counting" tracks live references.

$TB
    | Algorithm | Pause | Throughput | Fragmentation |
    |-----------|-------|------------|---------------|
    | Mark-sweep | Stop the world | High | Yes |
    | Mark-compact | Stop the world | Medium | No |
    | Copying | Stop the world | High | No |
    | Incremental | Short pauses | Medium | Yes |
    | Concurrent | Minimal | Lower | Yes |
    | Generational | Short minor | High | Sometimes |

$H3 - Stack Unwinding
$P - Stack unwinding is the process of cleaning up stack frames when an exception or panic occurs. "$B - RAII" Resource Acquisition Is Initialization ensures destructors run during unwinding.

$UL
    Each stack frame has an associated cleanup function
    Unwinding walks the call stack calling destructors
    Zero cost exceptions pay no overhead when no exception occurs
    Panic in Rust unwinds by default but can be set to abort
    Catching panics is possible via std::panic::catch_unwind
    Foreign function interfaces require careful handling of panics

$H3 - JIT Compilation
$P - Just in time compilation compiles code at runtime rather than ahead of time. "$BI - Adaptive optimization" profiles running code and recompiles hot paths with more aggressive optimizations.

$OL
    Interpreter runs code directly with no compilation overhead
    Baseline JIT compiles to machine code with minimal optimization
    Profiling tier collects type and branch information
    Optimizing JIT recompiles hot code with full optimization
    Deoptimization falls back to interpreter when assumptions fail
    Inline caching speeds up dynamic dispatch at call sites

$H2 - Chapter 15: Build Systems
$P - Build systems automate the compilation linking and testing of software. "$B - Incremental builds" only recompile what has changed saving time on large codebases.

$H3 - Dependency Resolution
$P - Modern build systems must resolve complex dependency graphs. "$I - Semantic versioning" provides a contract for API compatibility between versions.

$BQ
    Dependency hell is the name for the frustration of working with software packages that have dependencies on specific versions of other software packages.
    -- Wikipedia

$TB
    | Strategy | Description | Example |
    |----------|-------------|---------|
    | Lockfile | Pin exact versions | Cargo.lock |
    | Ranges | Allow compatible versions | ^1.2.3 |
    | Workspace | Share versions across crates | Cargo workspace |
    | Vendoring | Copy deps into repo | vendor/ |

$H3 - Caching Build Artifacts
$P - Build caches store compiled artifacts so they can be reused across machines and CI runs. "$B - Content addressed storage" uses hashes of inputs to determine cache validity.

$UL
    Local caches avoid recompiling unchanged modules
    Remote caches share artifacts across developer machines
    Hermetic builds ensure the same inputs always produce same outputs
    Sandbox execution prevents builds from accessing undeclared inputs
    Distributed builds parallelize compilation across many machines
    Incremental linking only re-links changed object files

$H3 - Cargo and the Rust Ecosystem
$P - Cargo is the official Rust build system and package manager. It handles dependency resolution compilation testing and publishing to crates.io.

$CODE - rust
    [package]
    name    = "my_crate"
    version = "0.1.0"
    edition = "2024"

    [dependencies]
    serde       = { version = "1.0", features = ["derive"] }
    tokio       = { version = "1.0", features = ["full"] }
    anyhow      = "1.0"

    [dev-dependencies]
    criterion   = "0.5"
    proptest    = "1.0"

    [profile.release]
    opt-level   = 3
    lto         = true
    codegen-units = 1
    strip       = true

$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to understand where each topic fits in the broader systems programming landscape.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.


$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to understand where each topic fits in the broader systems programming landscape.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.

$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to understand where each topic fits in the broader systems programming landscape.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.


$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to understand where each topic fits in the broader systems programming landscape.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.

$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to understand where each topic fits in the broader systems programming landscape.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.


$FN
    Chapters 11 through 15 cover systems topics at an introductory level. Each chapter could fill an entire book on its own. The goal here is to provide enough context to understand where each topic fits in the broader systems programming landscape.

$FN
    The WAL implementation in Chapter 13 omits checksums and record framing for brevity. A production WAL must include checksums to detect corruption and length-prefixed records to handle partial writes.


$FN
    All complexity figures assume average case unless otherwise noted. Worst case may differ significantly for hash-based structures.

$FN
    The p-adic rope balancing approach described in Chapter 4 is an original contribution. Standard rope implementations use weight-based or Fibonacci-based balancing instead.

$HR

$B - End of document. "$I - Happy hacking."
