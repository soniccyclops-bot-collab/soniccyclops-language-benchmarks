# The Computer Language Benchmarks Game
# https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
#
# N-body simulation — pure Python, optimized for CPython/PyPy/GraalPy

import sys

PI = 3.141592653589793
SOLAR_MASS = 4 * PI * PI
DAYS_PER_YEAR = 365.24

BODIES = {
    'sun': ([0.0, 0.0, 0.0],
            [0.0, 0.0, 0.0],
            SOLAR_MASS),
    'jupiter': ([4.84143144246472090e+00,
                 -1.16032004402742839e+00,
                 -1.03622044471123109e-01],
                [1.66007664274403694e-03 * DAYS_PER_YEAR,
                 7.69901118419740425e-03 * DAYS_PER_YEAR,
                 -6.90460016972063023e-05 * DAYS_PER_YEAR],
                9.54791938424326609e-04 * SOLAR_MASS),
    'saturn': ([8.34336671824457987e+00,
                4.12479856412430479e+00,
                -4.03523417114321381e-01],
               [-2.76742510726862411e-03 * DAYS_PER_YEAR,
                4.99852801234917238e-03 * DAYS_PER_YEAR,
                2.30417297573763929e-05 * DAYS_PER_YEAR],
               2.85885980666130812e-04 * SOLAR_MASS),
    'uranus': ([1.28943695621391310e+01,
                -1.51111514016986312e+01,
                -2.23307578892655734e-01],
               [2.96460137564761618e-03 * DAYS_PER_YEAR,
                2.37847173959480950e-03 * DAYS_PER_YEAR,
                -2.96589568540237556e-05 * DAYS_PER_YEAR],
               4.36624404335156298e-05 * SOLAR_MASS),
    'neptune': ([1.53796971148509165e+01,
                 -2.59193146099879641e+01,
                 1.79258772950371181e-01],
                [2.68067772490389322e-03 * DAYS_PER_YEAR,
                 1.62824170038242295e-03 * DAYS_PER_YEAR,
                 -9.51592254519715870e-05 * DAYS_PER_YEAR],
                5.15138902046611451e-05 * SOLAR_MASS),
}


def advance(dt, n, bodies, pairs):
    for i in range(n):
        for ([x1, y1, z1], v1, m1, [x2, y2, z2], v2, m2) in pairs:
            dx = x1 - x2
            dy = y1 - y2
            dz = z1 - z2
            dsq = dx * dx + dy * dy + dz * dz
            dist = dsq ** 0.5
            mag = dt / (dsq * dist)
            b1m = m1 * mag
            b2m = m2 * mag
            v1[0] -= dx * b2m
            v1[1] -= dy * b2m
            v1[2] -= dz * b2m
            v2[0] += dx * b1m
            v2[1] += dy * b1m
            v2[2] += dz * b1m
        for (r, [vx, vy, vz], m) in bodies:
            r[0] += dt * vx
            r[1] += dt * vy
            r[2] += dt * vz


def energy(bodies, pairs):
    e = 0.0
    for (r, [vx, vy, vz], m) in bodies:
        e += 0.5 * m * (vx * vx + vy * vy + vz * vz)
    for ((x1, y1, z1), v1, m1, (x2, y2, z2), v2, m2) in pairs:
        dx = x1 - x2
        dy = y1 - y2
        dz = z1 - z2
        e -= (m1 * m2) / ((dx * dx + dy * dy + dz * dz) ** 0.5)
    return e


def offset_momentum(ref, bodies):
    px = py = pz = 0.0
    for (r, [vx, vy, vz], m) in bodies:
        px -= vx * m
        py -= vy * m
        pz -= vz * m
    ref[0] = px / SOLAR_MASS
    ref[1] = py / SOLAR_MASS
    ref[2] = pz / SOLAR_MASS


def main():
    n = int(sys.argv[1])

    # Flatten bodies into list-of-tuples for fast iteration
    body_list = []
    for name in ('sun', 'jupiter', 'saturn', 'uranus', 'neptune'):
        pos, vel, mass = BODIES[name]
        body_list.append((pos, vel, mass))

    # Build pairs list
    pairs = []
    for i in range(len(body_list)):
        ri, vi, mi = body_list[i]
        for j in range(i + 1, len(body_list)):
            rj, vj, mj = body_list[j]
            pairs.append((ri, vi, mi, rj, vj, mj))

    offset_momentum(body_list[0][1], body_list)
    print("%.9f" % energy(body_list, pairs))
    advance(0.01, n, body_list, pairs)
    print("%.9f" % energy(body_list, pairs))


if __name__ == '__main__':
    main()
