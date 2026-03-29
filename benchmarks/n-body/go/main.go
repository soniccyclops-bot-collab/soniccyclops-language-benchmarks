// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// N-body simulation of the Jovian planets.
package main

import (
	"fmt"
	"math"
	"os"
	"strconv"
)

const (
	pi         = math.Pi
	solarMass  = 4 * pi * pi
	daysPerYear = 365.24
	nBodies    = 5
)

type Body struct {
	x, y, z    float64
	vx, vy, vz float64
	mass       float64
}

var bodies = [nBodies]Body{
	// Sun
	{mass: solarMass},
	// Jupiter
	{
		x:    4.84143144246472090e+00,
		y:    -1.16032004402742839e+00,
		z:    -1.03622044471123109e-01,
		vx:   1.66007664274403694e-03 * daysPerYear,
		vy:   7.69901118419740425e-03 * daysPerYear,
		vz:   -6.90460016972063023e-05 * daysPerYear,
		mass: 9.54791938424326609e-04 * solarMass,
	},
	// Saturn
	{
		x:    8.34336671824457987e+00,
		y:    4.12479856412430479e+00,
		z:    -4.03523417114321381e-01,
		vx:   -2.76742510726862411e-03 * daysPerYear,
		vy:   4.99852801234917238e-03 * daysPerYear,
		vz:   2.30417297573763929e-05 * daysPerYear,
		mass: 2.85885980666130812e-04 * solarMass,
	},
	// Uranus
	{
		x:    1.28943695621391310e+01,
		y:    -1.51111514016986312e+01,
		z:    -2.23307578892655734e-01,
		vx:   2.96460137564761618e-03 * daysPerYear,
		vy:   2.37847173959480950e-03 * daysPerYear,
		vz:   -2.96589568540237556e-05 * daysPerYear,
		mass: 4.36624404335156298e-05 * solarMass,
	},
	// Neptune
	{
		x:    1.53796971148509165e+01,
		y:    -2.59193146099879641e+01,
		z:    1.79258772950371181e-01,
		vx:   2.68067772490389322e-03 * daysPerYear,
		vy:   1.62824170038242295e-03 * daysPerYear,
		vz:   -9.51592254519715870e-05 * daysPerYear,
		mass: 5.15138902046611451e-05 * solarMass,
	},
}

func offsetMomentum() {
	var px, py, pz float64
	for i := range bodies {
		px += bodies[i].vx * bodies[i].mass
		py += bodies[i].vy * bodies[i].mass
		pz += bodies[i].vz * bodies[i].mass
	}
	bodies[0].vx = -px / solarMass
	bodies[0].vy = -py / solarMass
	bodies[0].vz = -pz / solarMass
}

func energy() float64 {
	var e float64
	for i := 0; i < nBodies; i++ {
		bi := &bodies[i]
		e += 0.5 * bi.mass * (bi.vx*bi.vx + bi.vy*bi.vy + bi.vz*bi.vz)
		for j := i + 1; j < nBodies; j++ {
			bj := &bodies[j]
			dx := bi.x - bj.x
			dy := bi.y - bj.y
			dz := bi.z - bj.z
			dist := math.Sqrt(dx*dx + dy*dy + dz*dz)
			e -= (bi.mass * bj.mass) / dist
		}
	}
	return e
}

func advance(dt float64) {
	for i := 0; i < nBodies; i++ {
		bi := &bodies[i]
		for j := i + 1; j < nBodies; j++ {
			bj := &bodies[j]
			dx := bi.x - bj.x
			dy := bi.y - bj.y
			dz := bi.z - bj.z
			dsq := dx*dx + dy*dy + dz*dz
			dist := math.Sqrt(dsq)
			mag := dt / (dsq * dist)
			bi.vx -= dx * bj.mass * mag
			bi.vy -= dy * bj.mass * mag
			bi.vz -= dz * bj.mass * mag
			bj.vx += dx * bi.mass * mag
			bj.vy += dy * bi.mass * mag
			bj.vz += dz * bi.mass * mag
		}
	}
	for i := range bodies {
		bodies[i].x += dt * bodies[i].vx
		bodies[i].y += dt * bodies[i].vy
		bodies[i].z += dt * bodies[i].vz
	}
}

func main() {
	n, _ := strconv.Atoi(os.Args[1])
	offsetMomentum()
	fmt.Printf("%.9f\n", energy())
	for i := 0; i < n; i++ {
		advance(0.01)
	}
	fmt.Printf("%.9f\n", energy())
}
