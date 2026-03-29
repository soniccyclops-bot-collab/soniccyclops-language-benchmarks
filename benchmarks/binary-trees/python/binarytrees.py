# The Computer Language Benchmarks Game
# https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
#
# Binary Trees — pure Python, optimized for CPython/PyPy/GraalPy

import sys

MIN_DEPTH = 4


def make_tree(depth):
    if depth <= 0:
        return (None, None)
    depth -= 1
    return (make_tree(depth), make_tree(depth))


def check_tree(node):
    left, right = node
    if left is None:
        return 1
    return 1 + check_tree(left) + check_tree(right)


def main():
    n = int(sys.argv[1])
    max_depth = max(MIN_DEPTH + 2, n)
    stretch_depth = max_depth + 1

    print("stretch tree of depth %d\t check: %d" %
          (stretch_depth, check_tree(make_tree(stretch_depth))))

    long_lived = make_tree(max_depth)

    for depth in range(MIN_DEPTH, max_depth + 1, 2):
        iterations = 1 << (max_depth - depth + MIN_DEPTH)
        check = 0
        for _ in range(iterations):
            check += check_tree(make_tree(depth))
        print("%d\t trees of depth %d\t check: %d" %
              (iterations, depth, check))

    print("long lived tree of depth %d\t check: %d" %
          (max_depth, check_tree(long_lived)))


if __name__ == '__main__':
    main()
