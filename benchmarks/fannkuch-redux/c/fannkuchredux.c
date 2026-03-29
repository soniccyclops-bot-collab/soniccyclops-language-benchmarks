/* The Computer Language Benchmarks Game
   https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
   Fannkuch-redux in C */

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    int n = atoi(argv[1]);
    int perm1[n], count[n], perm[n];
    int maxflips = 0, checksum = 0, permcount = 0;

    for (int i = 0; i < n; i++)
        perm1[i] = i;

    int r = n;
    for (;;) {
        while (r > 1) {
            count[r - 1] = r;
            r--;
        }

        /* Copy perm1 to perm and count flips */
        for (int i = 0; i < n; i++)
            perm[i] = perm1[i];

        int flips = 0;
        while (perm[0] != 0) {
            int k = perm[0];
            /* Reverse perm[0..k] */
            for (int lo = 0, hi = k; lo < hi; lo++, hi--) {
                int t = perm[lo];
                perm[lo] = perm[hi];
                perm[hi] = t;
            }
            flips++;
        }

        if (flips > maxflips) maxflips = flips;
        checksum += (permcount & 1) ? -flips : flips;
        permcount++;

        /* Generate next permutation */
        for (r = 1;;) {
            if (r == n) {
                printf("%d\nPfannkuchen(%d) = %d\n", checksum, n, maxflips);
                return 0;
            }
            int p0 = perm1[0];
            for (int i = 0; i < r; i++)
                perm1[i] = perm1[i + 1];
            perm1[r] = p0;

            count[r]--;
            if (count[r] > 0) break;
            r++;
        }
    }
}
