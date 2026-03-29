# The Computer Language Benchmarks Game
# https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
#
# Fannkuch-redux — pure Python, optimized for CPython/PyPy/GraalPy

import sys


def fannkuch(n):
    perm1 = list(range(n))
    count = [0] * n
    maxflips = 0
    checksum = 0
    permcount = 0
    r = n

    while True:
        while r > 1:
            count[r - 1] = r
            r -= 1

        # Count flips
        perm = perm1[:]
        k = perm[0]
        if k:
            flips = 0
            while k:
                # Reverse perm[0..k]
                if k == 1:
                    perm[0], perm[1] = perm[1], perm[0]
                elif k == 2:
                    perm[0], perm[2] = perm[2], perm[0]
                else:
                    perm[:k + 1] = perm[k::-1]
                flips += 1
                k = perm[0]

            if flips > maxflips:
                maxflips = flips
            if permcount & 1:
                checksum -= flips
            else:
                checksum += flips

        permcount += 1

        # Generate next permutation
        while True:
            if r == n:
                return checksum, maxflips
            r += 1
            p0 = perm1[0]
            perm1[:r - 1] = perm1[1:r]
            perm1[r - 1] = p0
            count[r - 1] -= 1
            if count[r - 1] > 0:
                break


def main():
    n = int(sys.argv[1])
    checksum, maxflips = fannkuch(n)
    print(checksum)
    print("Pfannkuchen(%d) = %d" % (n, maxflips))


if __name__ == '__main__':
    main()
