/* The Computer Language Benchmarks Game
   https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
   Fannkuch-redux in Java */

public class FannkuchRedux {
    public static void main(String[] args) {
        int n = Integer.parseInt(args[0]);

        int[] perm1 = new int[n];
        int[] count = new int[n];
        int[] perm = new int[n];

        for (int i = 0; i < n; i++) {
            perm1[i] = i;
        }

        int maxflips = 0;
        int checksum = 0;
        int permcount = 0;
        int r = n;

        outer:
        for (;;) {
            while (r > 1) {
                count[r - 1] = r;
                r--;
            }

            System.arraycopy(perm1, 0, perm, 0, n);

            int flips = 0;
            while (perm[0] != 0) {
                int k = perm[0];
                for (int lo = 0, hi = k; lo < hi; lo++, hi--) {
                    int t = perm[lo];
                    perm[lo] = perm[hi];
                    perm[hi] = t;
                }
                flips++;
            }

            if (flips > maxflips) {
                maxflips = flips;
            }
            if ((permcount & 1) == 0) {
                checksum += flips;
            } else {
                checksum -= flips;
            }
            permcount++;

            // Generate next permutation
            for (r = 1; ; r++) {
                if (r == n) {
                    System.out.printf("%d%nPfannkuchen(%d) = %d%n", checksum, n, maxflips);
                    return;
                }
                int p0 = perm1[0];
                System.arraycopy(perm1, 1, perm1, 0, r);
                perm1[r] = p0;

                count[r]--;
                if (count[r] > 0) {
                    break;
                }
            }
        }
    }
}
