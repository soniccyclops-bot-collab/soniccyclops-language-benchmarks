/* The Computer Language Benchmarks Game
 * https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
 *
 * Binary Trees benchmark in C
 * Uses a simple pool allocator for fast allocation/deallocation.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MIN_DEPTH 4

typedef struct Node {
    struct Node *left;
    struct Node *right;
} Node;

/* Simple arena/pool allocator */
typedef struct Pool {
    char *buf;
    size_t cap;
    size_t used;
} Pool;

static Pool pool_create(size_t cap) {
    Pool p;
    p.buf = (char *)malloc(cap);
    p.cap = cap;
    p.used = 0;
    return p;
}

static void pool_reset(Pool *p) {
    p->used = 0;
}

static void pool_destroy(Pool *p) {
    free(p->buf);
}

static Node *pool_alloc(Pool *p) {
    Node *n = (Node *)(p->buf + p->used);
    p->used += sizeof(Node);
    return n;
}

static Node *make_tree(int depth, Pool *pool) {
    Node *node = pool_alloc(pool);
    if (depth > 0) {
        node->left = make_tree(depth - 1, pool);
        node->right = make_tree(depth - 1, pool);
    } else {
        node->left = NULL;
        node->right = NULL;
    }
    return node;
}

static long check_tree(const Node *node) {
    if (node->left == NULL)
        return 1;
    return 1 + check_tree(node->left) + check_tree(node->right);
}

/* Calculate the number of nodes in a complete binary tree of given depth */
static size_t tree_size(int depth) {
    /* 2^(depth+1) - 1 nodes, each sizeof(Node) bytes */
    return ((size_t)1 << (depth + 1)) * sizeof(Node);
}

int main(int argc, char *argv[]) {
    int n = argc > 1 ? atoi(argv[1]) : 10;
    int max_depth = n < MIN_DEPTH + 2 ? MIN_DEPTH + 2 : n;
    int stretch_depth = max_depth + 1;

    /* Stretch tree */
    {
        Pool pool = pool_create(tree_size(stretch_depth));
        Node *tree = make_tree(stretch_depth, &pool);
        printf("stretch tree of depth %d\t check: %ld\n",
               stretch_depth, check_tree(tree));
        pool_destroy(&pool);
    }

    /* Long-lived tree */
    Pool long_pool = pool_create(tree_size(max_depth));
    Node *long_lived = make_tree(max_depth, &long_pool);

    /* Iterate over depths */
    for (int depth = MIN_DEPTH; depth <= max_depth; depth += 2) {
        int iterations = 1 << (max_depth - depth + MIN_DEPTH);
        long check = 0;
        Pool pool = pool_create(tree_size(depth));

        for (int i = 1; i <= iterations; i++) {
            pool_reset(&pool);
            Node *tree = make_tree(depth, &pool);
            check += check_tree(tree);
        }

        printf("%d\t trees of depth %d\t check: %ld\n",
               iterations, depth, check);
        pool_destroy(&pool);
    }

    printf("long lived tree of depth %d\t check: %ld\n",
           max_depth, check_tree(long_lived));
    pool_destroy(&long_pool);

    return 0;
}
