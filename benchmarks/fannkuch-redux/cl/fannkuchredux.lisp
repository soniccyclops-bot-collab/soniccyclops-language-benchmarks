;;; The Computer Language Benchmarks Game
;;; https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
;;;
;;; Fannkuch-Redux benchmark — SBCL optimized

(declaim (optimize (speed 3) (safety 0) (debug 0)))

(defun fannkuch (n)
  (declare (type fixnum n))
  (let ((perm1  (make-array n :element-type 'fixnum))
        (perm   (make-array n :element-type 'fixnum))
        (count  (make-array n :element-type 'fixnum))
        (maxflips 0)
        (checksum 0)
        (permcount 0)
        (r n))
    (declare (type fixnum maxflips checksum permcount r)
             (type (simple-array fixnum (*)) perm1 perm count))

    ;; Initialize perm1
    (loop for i fixnum from 0 below n do (setf (aref perm1 i) i))

    (loop
      ;; Set count values
      (loop while (> r 1) do
        (setf (aref count (1- r)) r)
        (decf r))

      ;; Copy perm1 to perm and count flips
      (replace perm perm1)
      (let ((flips 0))
        (declare (type fixnum flips))
        (loop while (/= (aref perm 0) 0) do
          (let ((k (aref perm 0)))
            (declare (type fixnum k))
            (loop for lo fixnum from 0
                  for hi fixnum downfrom k
                  while (< lo hi) do
              (rotatef (aref perm lo) (aref perm hi)))
            (incf flips)))
        (when (> flips maxflips) (setf maxflips flips))
        (if (evenp permcount)
            (incf checksum flips)
            (decf checksum flips)))
      (incf permcount)

      ;; Generate next permutation
      (setf r 1)
      (loop
        (when (= r n)
          (format t "~D~%Pfannkuchen(~D) = ~D~%" checksum n maxflips)
          (return-from fannkuch nil))
        (let ((p0 (aref perm1 0)))
          (declare (type fixnum p0))
          (loop for i fixnum from 0 below r do
            (setf (aref perm1 i) (aref perm1 (1+ i))))
          (setf (aref perm1 r) p0))
        (decf (aref count r))
        (when (> (aref count r) 0) (return))
        (incf r)))))

(defun main ()
  (let ((n (parse-integer (car (last sb-ext:*posix-argv*)))))
    (fannkuch n)))
