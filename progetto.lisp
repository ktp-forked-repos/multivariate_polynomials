;;;; Mode: -*- Lisp -*-


;;;; progetto.lisp


;;;; Multivariate-Polynomials



;;; Returns the exponent from a variable (v Exp VarSymbol)
(defun varpower-power (vp)
  (let ((pow (second vp)))
    (if (numberp pow) pow (error "L'esponente non e' un numero"))))

;;; Returns the varsymbol from a variable (v Exp VarSymbol)
(defun varpower-symbol (vp)
  (let ((vs (third vp)))
    (cond ((and
	    (atom vs)
	    (not (numberp vs))) vs)
	  (T (error "La variabile non e' un carattere")))))

;;; Returns the monomial's Vars and Powers
(defun varpowers (mono)
  (and (= (length mono) 4)
       (let ((vps (fourth mono)))
	 (if (listp vps)
	     vps
	     (error "le variabili non sono scritte correttamente")))))

;;; Returns the monomial's TD
(defun monomial-degree (mono)
  (and (= (length mono) 4)
       (let ((mtd (third mono)))
         (if (>= mtd 0) mtd (error "Grado minore di 0")))))

;;; Returns the monomial's coefficient
(defun monomial-coefficient (mono)
  (and (= (length mono) 4)
       (let ((coeff (second mono)))
         (if (numberp coeff) coeff (error "Il coeff non e' un numero")))))

#|
TRUE if m is a monomial
Checks:
-whether the first element in the list equals "m"
-whether the total degree is an integer >= 0
-whether vps is a list and every element of it is a VarPower
|#
(defun is-monomial (m)
  (and (listp m)
       (eq 'm (first m))
       (let ((mtd (monomial-degree m))
             (vps (varpowers m)))
	 (and (integerp mtd)
	      (>= mtd 0)
	      (listp vps)
	      (every #'is-varpower vps)))))

;;; T if vp is a list of varpowers
(defun is-varpower (vp)
  (and (listp vp)
       (eq 'v (first vp))
       (let ((p (varpower-power vp))
             (v (varpower-symbol vp))
	     )
         (and (integerp p)
              (>= p 0)
              (symbolp v)))))

;;; Returns the list of all the monomials in a poly
(defun poly-monomials (p)
 (first (rest p)))

;;; T if p is a polynomial
(defun is-polynomial (p)
  (and (listp p)
       (eq 'poly (first p))
       (let ((ms (poly-monomials p)))
         (and (listp ms)
              (every #'is-monomial ms)))))

;;; Returns the list of all the coefficients in a poly
(defun coefficients (p)
  (if (is-polynomial p) 
      (let ((monomials (poly-monomials p)))
        (mapcar 'monomial-coefficient monomials)) 
    (error "Non � stato passato un polinomio")))


;;; Returns the list of all the VPs in a poly
(defun poly-variables (p)
  (apply #'append
	 (let ((monomials (poly-monomials p)))
	   (mapcar 'varpowers monomials))))


;;; Returns the list of all the variables in a poly
(defun variables (p)
  (if (is-polynomial p)
      (remove-duplicates (mapcar #'varpower-symbol
                                 (apply #'append
                                        (mapcar #'varpowers
                                                (poly-monomials p)))))
    (error "Non � stato passato un polinomio")))

;;; Returns the max degree in the poly
(defun maxdegree (p)
  (if (is-polynomial p)
      (maximum-in-list (mapcar #'monomial-degree
			       (poly-monomials p)))
      (error "P is not a polynomial")))

;;; Returns the maximum in a list
(defun maximum-in-list (l)
  (if (= (length l) 1)
      (car l)
      (if (> (car l) (maximum-in-list (cdr l)))
          (car l)
          (maximum-in-list (cdr l)))))

;;; Returns the min degree in the poly
(defun mindegree (p)
  (if (is-polynomial p)
      (minimum-in-list (mapcar #'monomial-degree
			       (poly-monomials p)))
      (error "P is not a polynomial")))

;;; Returns the minimum in a list
(defun minimum-in-list (l)
  (if (= (length l) 1)
      (car l)
      (if (< (car l) (minimum-in-list (cdr l)))
	  (car l)
	  (minimum-in-list (cdr l)))))

;;; If (eval expression) is a number, returns it. Else NIL
(defun eval-as-number (expression)
  (let ((result (handler-case (eval expression)
		  (error () nil)
		  (warning () nil))))
    (if (numberp result) result nil)))

;;; True if expr is an expression to be parsed
(defun is-power-not-parsed (expr)
  (if (not (listp expr)) nil
      (if (and (equal (first expr) 'expt) (symbolp (second expr))
	       (numberp (third expr)))
	  T NIL)))

;;; Parses an expression (expt VAR EXP) into the form (v EXP VAR)
(defun parse-power (expr)
  (if (is-power-not-parsed expr)
      (list 'm 1 (third expr) (list 'v (third expr) (second expr))) nil))

(defun parse-power-negative-coeff (expr)
  (if (is-power-not-parsed expr)
      (list 'm -1 (third expr) (list 'v (third expr) (second expr))) nil))

;;; True if expr is + or - or * or /
(defun is-operator (expr)
  (if (or (eql expr '*) (eql expr '/) (eql expr '-) (eql expr '+))
      T NIL))

;;; Sorts the variables in a monomial by lexicographical order
(defun sort-monomial (mono)
  (let ((new-varpowers (copy-list (varpowers mono))))
    (append (list (first mono) (second mono) (third mono))
	    (list (stable-sort new-varpowers 'string< :key 'third)))))

;;; Compares the variables in monomials with the same TD
(defun compare-varpowers (vars1 vars2)
  (cond ((null vars1) (not (null vars2)))
	((null vars2) nil)
	(t 
         (let ((v1 (first vars1)) (v2 (first vars2)))
           (cond
            ((string< (third v1) (third v2)) t)
            ((string> (third v1) (third v2)) nil)
            ((and (equal (third v1) (third v2)) (= (second v1) (second v2)))
             (compare-varpowers (rest vars1) (rest vars2)))
            (t (< (second (first vars1)) (second (first vars2)))))))))


;;; Compares the degrees of the monomials in a poly
(defun compare-degrees (first-mono rest-monos)
  (when (not (null first-mono))
    (let ((degrees
	   (list (monomial-degree first-mono)
		 (monomial-degree rest-monos))))
      (cond ((null first-mono) (not (null rest-monos)))
            ((null rest-monos) nil)
            ((= (first degrees) (second degrees))
	     (compare-varpowers (varpowers first-mono) (varpowers rest-monos)))
            (t (< (first degrees) (second degrees)))))))

;;; Sorts a polynomial by degree and lexicographical order
(defun sort-poly (monos)
  (let ((poly-copied (copy-list monos)))
    (stable-sort poly-copied #'compare-degrees)))


;;; Evaluates the coefficient of a monomial
(defun build-coefficient (expr)
  (if (null expr) 1
      (if (eval-as-number (first expr))
	  (* 1 (eval (first expr)) (build-coefficient (rest expr)))
	  (* 1 (build-coefficient (rest expr))))))

;;; Builds the VPs of a monomial
(defun build-varpowers (expr td)
  (let ((head (first expr)) (tail (rest expr)))
    (cond ((and (listp head) (not (null head)) (equal (first head) 'expt))
           (append (build-varpowers tail (+ (eval td) (eval (third head))))
		   (list (list 'v (third head) (second head)))))
          ((and (symbolp head) (not (null head)))
           (append (build-varpowers tail (+ 1 (eval td)))
		   (list (list 'v 1 head))))
          ((numberp (eval head)) (build-varpowers tail td))
          ((null head) (list td)))))

;;; Parses a monomial
;; NB: per il concetto di atomo in CL, (as-monomial '-x)
;; prende -x come simbolo di variabile

(defun as-monomial (expr)
  (compress-vars-in-monomial (sort-monomial (as-monomial-unordered expr))))

(defun as-monomial-unordered (expr)
  (cond ((eval-as-number expr) (list 'm (eval expr) 0 nil))
        ((atom expr) (list 'm 1 1 (list (list 'v 1 expr))))
        (t (let ((head (first expr)) (tail (rest expr)))
             (if (is-operator head) ;;caso serio
                 (cond ((equal head '-)
                        (if (listp (second expr))
                            (parse-power-negative-coeff (second expr))
			    (list 'm -1 1 (list 'v 1(second expr)))))
                       ((equal head '*)
                        (if (eql (build-coefficient tail) 0) (list 'm 0 0 nil)
			    (let ((vps (build-varpowers tail 0)))
			      (append (list 'm) (list (build-coefficient tail))
				      (list (first vps)) (list (rest vps)))))))
		 (if (is-power-not-parsed head)
		     (parse-power head)
		     (list 'm 1 1 (list 'v 1 head))))))))


(defun as-polynomial (expr)
  (append (list 'poly) (list
			(sum-similar-monos-in-poly
			 (sort-poly (as-polynomial-call expr))))))

;;; Parses a polynomial
(defun as-polynomial-call (expr)
  (when (not (null expr))
    (if (atom expr) (as-monomial expr)
      (let ((head (first expr)) (tail (rest expr)))
        (if (is-operator head) 
            (if (equal head '+) (as-polynomial-call tail) (list (as-monomial expr)))
          (if (and (listp expr) (not (null tail)))
              (append (list (as-monomial head)) (as-polynomial-call tail))
            (list (as-monomial head))))))))

;; This predicate checks if the variables in the monomial are equal
(defun check-equal-variables (expr)
  (let ((variables1 (fourth (first expr))) (variables2 (fourth (second expr))))
    (if (equal variables1 variables2) T NIL)))

;; This predicate sums the similar monomials in a polynomial
(defun sum-similar-monos-in-poly (monos)
  (cond ((null monos) nil)
        ((null (second monos)) monos)
        (t 
         (let* ((mono1 (first monos))
		(mono2 (second monos))
		(c1 (monomial-coefficient mono1))
		(c2 (monomial-coefficient mono2))
		(td (monomial-degree mono1))
		(vps1 (varpowers mono1))
		(vps2 (varpowers mono2)))
           (if (not (equal vps1 vps2))
	       (append (list mono1)
		       (sum-similar-monos-in-poly (rest monos))) 
	       (sum-similar-monos-in-poly
		(append (list (list 'm (+ c1 c2) td vps1))
			(rest (rest monos)))))))))


;; This predicate sums the exponents of similiar VPs in a monomial
(defun compress-vars-in-monomial (mono)
  (if (null (varpowers mono)) mono
      (let ((vps (varpowers mono))
	    (c (monomial-coefficient mono))
	    (td (monomial-degree mono)))
	(append (list 'm c td) (list (compress-vps vps))))))

;; This predicate sums the exponents of of similiar VPs
(defun compress-vps (vps)
  (if (null vps) nil
      (if (null (second vps)) vps
	  (let* ((vp1 (first vps))
		 (vp2 (second vps))
		 (expt1 (varpower-power vp1))
		 (expt2 (varpower-power vp2))
		 (var1 (varpower-symbol vp1))
		 (var2 (varpower-symbol vp2))
		 (tail (rest (rest vps))))
	    (if (not (null tail))
		(if (not (null vp2))
		    (if (equal var1 var2)
			(compress-vps (append
				       (list (list 'v (+ (eval expt1)
							 (eval expt2))
						   var1))
				       tail))
			(append (list (list 'v expt1 var1))
				(compress-vps (rest vps)))))
		(if (equal var1 var2) (list (list 'v (+ (eval expt1)
							(eval expt2))
						  var1))
		    (append (list (list 'v expt1 var1))
			    (list (list 'v expt2 var2)))))))))

;; Pairlis
(defun new-pairlis (list1 list2)
  (cond ((null list1) list2)
	((null list2) list1)
	(t (append (list (list (first list1) (first list2)))
		   (new-pairlis (rest list1) (rest list2))))))



;; This predicate changes the sign of the coefficients
(defun change-sign (monos)
  (let* ((mono1 (first monos))
	 (c1 (second mono1))
	 (td (third mono1))
	 (var-powers (fourth mono1)))
    (if (equal (rest monos) nil)
        (append (list (list 'm (- 0 c1) td (list var-powers))))
	(append (list (list 'm (- 0 c1) td (list var-powers )))
		(change-sign (rest monos))))))


(defun to-polynomial (poly)
  (cond ((is-polynomial poly) (append (list 'poly) (sort-poly (poly-monomials poly))))
	((is-monomial poly) (append (list 'poly) (list (list poly))))
	(t 
         (if (or (atom poly) (equal '* (first poly))) (to-polynomial (as-monomial poly))
           (as-polynomial poly)))))
	

(defun polyplus (poly1 poly2)
  (let ((p1 (to-polynomial poly1)) (p2 (to-polynomial poly2)))
    (append (list 'poly)
            (list (sort-poly
                   (sum-similar-monos-in-poly
                    (sort-poly (append (poly-monomials p1)
                                       (poly-monomials p2)))))))))

(defun polyminus (poly1 poly2)
  (let ((p1 (to-polynomial poly1)) (p2 (to-polynomial poly2)))
    (append (list 'poly)
            (list (sort-poly
                   (sum-similar-monos-in-poly
                    (sort-poly (append (poly-monomials p1)
                                       (change-sign 
                                        (poly-monomials p2))))))))))

#|
(defun polytimes (poly1 poly2)
  (if (or (null poly1) (null poly2)) nil
      (multiply-monos (poly-monomials poly1)
		      (poly-monomials poly2))))


(defun multiply-monos (monos1 monos2)
  (let* ((first-mono1 (first monos1))
	 (first-mono2 (first monos2)))
    ......))
|#
	
	 



;; This predicate prints a polynomial in our "traditional" form
(defun pprint-polynomial (poly) 
  (pprint-polynomial-call (second (to-polynomial poly))))

;; This predicate prints a traditional form of poly
(defun pprint-polynomial-call (mono)
  (let ((m1 (first mono)) (c2 (second (second mono))))
    (if (not (null c2))
        (if (> c2 0)
            (append (pprint-polynomial-call-coefficients m1)
		    (list '+)
		    (pprint-polynomial-call (rest mono)))
	    (append (pprint-polynomial-call-coefficients m1)
		    (pprint-polynomial-call (rest mono))))
	(append (pprint-polynomial-call-coefficients m1)))))

;; This predicate prints the coefficient of a mono
(defun pprint-polynomial-call-coefficients (m1)
  (let ((c1 (second m1)) (v&p (fourth m1)))
    (if (equal v&p nil)
        (append (list c1))
	(append (list c1) (list '*) (pprint-polynomial-call-variables v&p)))))


;; This predicate prints variables and powers of a mono
(defun pprint-polynomial-call-variables (var-power)
  (if (null var-power) nil
      (let ((exp (second (first var-power))) (var (third (first var-power))))
	(if (equal (rest var-power) nil)
	    (if (= exp 1)
		(append (list var)) (append (list var '^ exp)))
	    (if (= exp 1) 
		(append (list var '*)
			(pprint-polynomial-call-variables (rest var-power)))
		(append (list var '^ exp '*)
			(pprint-polynomial-call-variables
			 (rest var-power))))))))

;;; end of file -- progetto.lisp
