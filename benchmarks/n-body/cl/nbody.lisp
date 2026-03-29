;;; The Computer Language Benchmarks Game
;;; https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
;;;
;;; N-body simulation of the Jovian planets — SBCL optimized

(declaim (optimize (speed 3) (safety 0) (debug 0)))

(defconstant +pi+ 3.141592653589793d0)
(defconstant +solar-mass+ (* 4d0 +pi+ +pi+))
(defconstant +days-per-year+ 365.24d0)
(defconstant +nbodies+ 5)

(deftype body-array () '(simple-array double-float (5)))
(deftype mass-array () '(simple-array double-float (5)))

(declaim (type (simple-array double-float (5)) *x* *y* *z* *vx* *vy* *vz* *mass*))

(defparameter *x*
  (make-array 5 :element-type 'double-float
              :initial-contents '(0.0d0
                                  4.84143144246472090d0
                                  8.34336671824457987d0
                                  1.28943695621391310d+01
                                  1.53796971148509165d+01)))

(defparameter *y*
  (make-array 5 :element-type 'double-float
              :initial-contents '(0.0d0
                                  -1.16032004402742839d0
                                  4.12479856412430479d0
                                  -1.51111514016986312d+01
                                  -2.59193146099879641d+01)))

(defparameter *z*
  (make-array 5 :element-type 'double-float
              :initial-contents '(0.0d0
                                  -1.03622044471123109d-01
                                  -4.03523417114321381d-01
                                  -2.23307578892655734d-01
                                  1.79258772950371181d-01)))

(defparameter *vx*
  (make-array 5 :element-type 'double-float
              :initial-contents
              (list 0.0d0
                    (* 1.66007664274403694d-03 +days-per-year+)
                    (* -2.76742510726862411d-03 +days-per-year+)
                    (* 2.96460137564761618d-03 +days-per-year+)
                    (* 2.68067772490389322d-03 +days-per-year+))))

(defparameter *vy*
  (make-array 5 :element-type 'double-float
              :initial-contents
              (list 0.0d0
                    (* 7.69901118419740425d-03 +days-per-year+)
                    (* 4.99852801234917238d-03 +days-per-year+)
                    (* 2.37847173959480950d-03 +days-per-year+)
                    (* 1.62824170038242295d-03 +days-per-year+))))

(defparameter *vz*
  (make-array 5 :element-type 'double-float
              :initial-contents
              (list 0.0d0
                    (* -6.90460016972063023d-05 +days-per-year+)
                    (* 2.30417297573763929d-05 +days-per-year+)
                    (* -2.96589568540237556d-05 +days-per-year+)
                    (* -9.51592254519715870d-05 +days-per-year+))))

(defparameter *mass*
  (make-array 5 :element-type 'double-float
              :initial-contents
              (list +solar-mass+
                    (* 9.54791938424326609d-04 +solar-mass+)
                    (* 2.85885980666130812d-04 +solar-mass+)
                    (* 4.36624404335156298d-05 +solar-mass+)
                    (* 5.15138902046611451d-05 +solar-mass+))))

(defun offset-momentum ()
  (let ((px 0.0d0) (py 0.0d0) (pz 0.0d0))
    (declare (type double-float px py pz))
    (loop for i fixnum from 0 below +nbodies+ do
      (let ((m (aref *mass* i)))
        (declare (type double-float m))
        (incf px (* (aref *vx* i) m))
        (incf py (* (aref *vy* i) m))
        (incf pz (* (aref *vz* i) m))))
    (setf (aref *vx* 0) (/ (- px) +solar-mass+))
    (setf (aref *vy* 0) (/ (- py) +solar-mass+))
    (setf (aref *vz* 0) (/ (- pz) +solar-mass+))))

(defun energy ()
  (let ((e 0.0d0))
    (declare (type double-float e))
    (loop for i fixnum from 0 below +nbodies+ do
      (let ((mi (aref *mass* i)))
        (declare (type double-float mi))
        (incf e (* 0.5d0 mi
                   (+ (* (aref *vx* i) (aref *vx* i))
                      (* (aref *vy* i) (aref *vy* i))
                      (* (aref *vz* i) (aref *vz* i)))))
        (loop for j fixnum from (1+ i) below +nbodies+ do
          (let* ((dx (- (aref *x* i) (aref *x* j)))
                 (dy (- (aref *y* i) (aref *y* j)))
                 (dz (- (aref *z* i) (aref *z* j)))
                 (dist (the double-float (sqrt (+ (* dx dx) (* dy dy) (* dz dz))))))
            (declare (type double-float dx dy dz dist))
            (decf e (/ (* mi (aref *mass* j)) dist))))))
    e))

(defun advance (dt)
  (declare (type double-float dt))
  (loop for i fixnum from 0 below +nbodies+ do
    (loop for j fixnum from (1+ i) below +nbodies+ do
      (let* ((dx (- (aref *x* i) (aref *x* j)))
             (dy (- (aref *y* i) (aref *y* j)))
             (dz (- (aref *z* i) (aref *z* j)))
             (dsq (+ (* dx dx) (* dy dy) (* dz dz)))
             (dist (the double-float (sqrt dsq)))
             (mag (/ dt (* dsq dist)))
             (mj*mag (* (aref *mass* j) mag))
             (mi*mag (* (aref *mass* i) mag)))
        (declare (type double-float dx dy dz dsq dist mag mj*mag mi*mag))
        (decf (aref *vx* i) (* dx mj*mag))
        (decf (aref *vy* i) (* dy mj*mag))
        (decf (aref *vz* i) (* dz mj*mag))
        (incf (aref *vx* j) (* dx mi*mag))
        (incf (aref *vy* j) (* dy mi*mag))
        (incf (aref *vz* j) (* dz mi*mag)))))
  (loop for i fixnum from 0 below +nbodies+ do
    (incf (aref *x* i) (* dt (aref *vx* i)))
    (incf (aref *y* i) (* dt (aref *vy* i)))
    (incf (aref *z* i) (* dt (aref *vz* i)))))

(defun main ()
  (let ((n (parse-integer (car (last sb-ext:*posix-argv*)))))
    (offset-momentum)
    (format t "~,9F~%" (energy))
    (loop repeat n do (advance 0.01d0))
    (format t "~,9F~%" (energy))))
