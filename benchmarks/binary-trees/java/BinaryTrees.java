/**
 * Binary Trees benchmark in Java
 * https://benchmarksgame-team.pages.debian.net/benchmarksgame/description/binarytrees.html
 */
public class BinaryTrees {
    private static final int MIN_DEPTH = 4;

    static final class Node {
        Node left, right;

        Node(Node left, Node right) {
            this.left = left;
            this.right = right;
        }
    }

    static Node makeTree(int depth) {
        if (depth <= 0) {
            return new Node(null, null);
        }
        return new Node(makeTree(depth - 1), makeTree(depth - 1));
    }

    static int checkTree(Node node) {
        if (node.left == null) {
            return 1;
        }
        return 1 + checkTree(node.left) + checkTree(node.right);
    }

    public static void main(String[] args) throws Exception {
        int n = args.length > 0 ? Integer.parseInt(args[0]) : 10;
        int maxDepth = Math.max(MIN_DEPTH + 2, n);
        int stretchDepth = maxDepth + 1;

        // Stretch tree
        Node stretch = makeTree(stretchDepth);
        System.out.printf("stretch tree of depth %d\t check: %d%n",
                stretchDepth, checkTree(stretch));

        // Long-lived tree
        Node longLived = makeTree(maxDepth);

        // Iterate over depths using parallel streams
        int nResults = (maxDepth - MIN_DEPTH) / 2 + 1;
        String[] results = new String[nResults];

        Thread[] threads = new Thread[nResults];
        for (int i = 0; i < nResults; i++) {
            final int idx = i;
            final int depth = MIN_DEPTH + idx * 2;
            final int iterations = 1 << (maxDepth - depth + MIN_DEPTH);
            threads[i] = new Thread(() -> {
                int check = 0;
                for (int j = 0; j < iterations; j++) {
                    check += checkTree(makeTree(depth));
                }
                results[idx] = String.format("%d\t trees of depth %d\t check: %d",
                        iterations, depth, check);
            });
            threads[i].start();
        }

        for (Thread t : threads) {
            t.join();
        }

        for (String r : results) {
            System.out.println(r);
        }

        System.out.printf("long lived tree of depth %d\t check: %d%n",
                maxDepth, checkTree(longLived));
    }
}
