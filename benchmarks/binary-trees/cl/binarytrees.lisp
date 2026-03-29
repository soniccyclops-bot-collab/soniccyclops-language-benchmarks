;;; The Computer Language Benchmarks Game
;;; https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
;;;
;;; Binary Trees benchmark — SBCL optimized

(declaim (optimize (speed 3) (safety 0) (debug 0)))

(defconstant +min-depth+ 4)

(defstruct (node (:constructor make-node (left right)))
  (left  nil :type (or null node))
  (right nil :type (or null node)))

(defun make-tree (depth)
  (declare (type fixnum depth))
  (if (zerop depth)
      (make-node nil nil)
      (make-node (make-tree (1- depth))
                 (make-tree (1- depth)))))

(defun check-tree (node)
  (declare (type node node))
  (if (null (node-left node))
      1
      (the fixnum (+ 1
                     (check-tree (node-left node))
                     (check-tree (node-right node))))))

(defun main ()
  (let* ((n (parse-integer (car (last sb-ext:*posix-argv*))))
         (max-depth (max (+ +min-depth+ 2) n))
         (stretch-depth (1+ max-depth)))
    (declare (type fixnum n max-depth stretch-depth))

    ;; Stretch tree
    (format t "stretch tree of depth ~D~C check: ~D~%"
            stretch-depth #\Tab (check-tree (make-tree stretch-depth)))

    ;; Long-lived tree
    (let ((long-lived (make-tree max-depth)))

      ;; Iterate depths
      (loop for depth fixnum from +min-depth+ to max-depth by 2 do
        (let ((iterations (ash 1 (+ max-depth (- depth) +min-depth+)))
              (check 0))
          (declare (type fixnum iterations check))
          (loop for i fixnum from 1 to iterations do
            (incf check (check-tree (make-tree depth))))
          (format t "~D~C trees of depth ~D~C check: ~D~%"
                  iterations #\Tab depth #\Tab check)))

      ;; Long-lived tree check
      (format t "long lived tree of depth ~D~C check: ~D~%"
              max-depth #\Tab (check-tree long-lived)))))
