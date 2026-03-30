# binary-trees — Clython-compatible variant
# Workarounds: hardcoded n=21 (no sys), print() multi-arg (no % format)
# Remove workarounds when Clython issues #177 and sys.argv are resolved.
MIN_DEPTH = 4
n = 21

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

max_depth = max(MIN_DEPTH + 2, n)
stretch_depth = max_depth + 1
sd_check = check_tree(make_tree(stretch_depth))
print("stretch tree of depth", stretch_depth, "check:", sd_check)
long_lived = make_tree(max_depth)
for depth in range(MIN_DEPTH, max_depth + 1, 2):
    iterations = 1 << (max_depth - depth + MIN_DEPTH)
    check = 0
    for _ in range(iterations):
        check += check_tree(make_tree(depth))
    print(iterations, "trees of depth", depth, "check:", check)
ll_check = check_tree(long_lived)
print("long lived tree of depth", max_depth, "check:", ll_check)
