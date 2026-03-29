#!/bin/bash
# setup-clython.sh — Clone and build Clython (Python interpreter in Common Lisp)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CLYTHON_DIR="$ROOT_DIR/.clython"

if [ -x "$CLYTHON_DIR/bin/clython" ]; then
    echo "Clython already built at $CLYTHON_DIR/bin/clython"
    exit 0
fi

echo "Setting up Clython..."

# Clone
if [ ! -d "$CLYTHON_DIR/src" ]; then
    git clone --depth 1 https://github.com/exokomodo/clython.git "$CLYTHON_DIR/src"
fi

# Build executable
mkdir -p "$CLYTHON_DIR/bin"
cd "$CLYTHON_DIR/src"

sbcl --noinform --non-interactive \
    --eval '(require :asdf)' \
    --eval '(push (truename ".") asdf:*central-registry*)' \
    --eval '(asdf:load-system :clython)' \
    --eval '(defun main ()
              (let ((args (cdr sb-ext:*posix-argv*)))
                (when (and args (probe-file (first args)))
                  (let ((source (with-open-file (s (first args))
                                  (let ((str (make-string (file-length s))))
                                    (read-sequence str s)
                                    str)))
                        (env (clython.scope:make-global-env)))
                    ;; Inject sys.argv
                    (clython.eval:eval-node
                     (clython:py-parse
                      (format nil "import sys~%sys.argv = [~{~S~^, ~}]" args))
                     env)
                    (clython.eval:eval-node (clython:py-parse source) env)))))' \
    --eval '(sb-ext:save-lisp-and-die "'"$CLYTHON_DIR/bin/clython"'" :toplevel #'"'"'main :executable t :compression t)' \
    2>&1

if [ -x "$CLYTHON_DIR/bin/clython" ]; then
    echo "Clython built successfully at $CLYTHON_DIR/bin/clython"
else
    echo "WARNING: Clython build failed. Benchmarks will skip Clython."
    exit 0  # Don't fail CI
fi
