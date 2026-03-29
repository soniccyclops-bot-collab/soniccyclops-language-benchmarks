// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
// Fannkuch-redux in Go

package main

import (
	"fmt"
	"os"
	"strconv"
)

func main() {
	n, _ := strconv.Atoi(os.Args[1])

	perm1 := make([]int, n)
	count := make([]int, n)
	perm := make([]int, n)

	for i := 0; i < n; i++ {
		perm1[i] = i
	}

	maxflips := 0
	checksum := 0
	permcount := 0
	r := n

	for {
		for r > 1 {
			count[r-1] = r
			r--
		}

		copy(perm, perm1)

		flips := 0
		for perm[0] != 0 {
			k := perm[0]
			for lo, hi := 0, k; lo < hi; lo, hi = lo+1, hi-1 {
				perm[lo], perm[hi] = perm[hi], perm[lo]
			}
			flips++
		}

		if flips > maxflips {
			maxflips = flips
		}
		if permcount&1 == 0 {
			checksum += flips
		} else {
			checksum -= flips
		}
		permcount++

		// Generate next permutation
		for r = 1; ; r++ {
			if r == n {
				fmt.Printf("%d\nPfannkuchen(%d) = %d\n", checksum, n, maxflips)
				return
			}
			p0 := perm1[0]
			copy(perm1[:r], perm1[1:r+1])
			perm1[r] = p0

			count[r]--
			if count[r] > 0 {
				break
			}
		}
	}
}
