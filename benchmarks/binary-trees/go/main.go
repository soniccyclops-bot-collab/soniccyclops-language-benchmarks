// Binary Trees benchmark in Go
// https://benchmarksgame-team.pages.debian.net/benchmarksgame/description/binarytrees.html
package main

import (
	"fmt"
	"os"
	"strconv"
	"sync"
)

const minDepth = 4

type Node struct {
	Left  *Node
	Right *Node
}

func makeTree(depth int) *Node {
	if depth <= 0 {
		return &Node{}
	}
	return &Node{
		Left:  makeTree(depth - 1),
		Right: makeTree(depth - 1),
	}
}

func checkTree(n *Node) int {
	if n.Left == nil {
		return 1
	}
	return 1 + checkTree(n.Left) + checkTree(n.Right)
}

func main() {
	n := 10
	if len(os.Args) > 1 {
		if v, err := strconv.Atoi(os.Args[1]); err == nil {
			n = v
		}
	}

	maxDepth := n
	if minDepth+2 > maxDepth {
		maxDepth = minDepth + 2
	}
	stretchDepth := maxDepth + 1

	// Stretch tree
	stretch := makeTree(stretchDepth)
	fmt.Printf("stretch tree of depth %d\t check: %d\n", stretchDepth, checkTree(stretch))

	// Long-lived tree
	longLived := makeTree(maxDepth)

	// Iterate over depths in parallel
	type result struct {
		depth      int
		iterations int
		check      int
	}

	nResults := (maxDepth - minDepth) / 2 + 1
	results := make([]result, nResults)

	var wg sync.WaitGroup
	for i := 0; i < nResults; i++ {
		wg.Add(1)
		go func(idx int) {
			defer wg.Done()
			depth := minDepth + idx*2
			iterations := 1 << (maxDepth - depth + minDepth)
			check := 0
			for j := 0; j < iterations; j++ {
				t := makeTree(depth)
				check += checkTree(t)
			}
			results[idx] = result{depth, iterations, check}
		}(i)
	}
	wg.Wait()

	for _, r := range results {
		fmt.Printf("%d\t trees of depth %d\t check: %d\n", r.iterations, r.depth, r.check)
	}

	fmt.Printf("long lived tree of depth %d\t check: %d\n", maxDepth, checkTree(longLived))
}
