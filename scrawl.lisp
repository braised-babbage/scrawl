(defpackage #:scrawl
  (:use #:cl #:named-readtables)
  (:export #:syntax))

(in-package #:scrawl)

(defconstant +at-sign+ #\@)
(defconstant +left-brace+ #\{)
(defconstant +right-brace+ #\})
(defconstant +left-bracket+ #\[)
(defconstant +right-bracket+ #\])

(defparameter *trim-characters*
  (vector #\Space #\Newline #\Backspace #\Tab 
	  #\Linefeed #\Page #\Return #\Rubout)
  "Additional characters to trim.")

(defun read-string (stream balance)
  "Read a string from STREAM until BALANCE is zero, or we hit another Scrawl form. 

BALANCE indicates the difference (# of left braces) - (# of right braces) so far."
  (let ((raw
	    (with-output-to-string (out-stream)
	      ;; If we're balanced, or the next char is @, we don't want
	      ;; to consume any more.
	      (loop :for c := (peek-char nil stream t nil t)
		    :until (or (zerop balance)
			       (char= c +at-sign+))
		    ;; Ok, consume the next character.
		    :do (progn
			  (read-char stream t nil t)
			  (incf balance
			      (cond ((char= c +left-brace+) 1)
				    ((char= c +right-brace+) -1)
				    (t 0)))
			  (when (plusp balance)			    
			    (write-char c out-stream))
			  (cond ((zerop balance) )))))))
      (values raw balance)))


(defun read-left-bracket (stream char)
  "Read a list delimited by brackets."
  (declare (ignore char))
  (read-delimited-list +right-bracket+ stream t))


(defun read-left-brace (stream char)
  "Read from a left brace until we have a matching right brace."
  (declare (ignore char))
  (loop :with balance := 1
	:for iter :from 0
	:for (string new-balance) := (multiple-value-list
				      (read-string stream balance))
	:do (setf balance new-balance)
	;; we need to trim the start of the first string
	:when (zerop iter)
	  :do (setf string (string-left-trim *trim-characters* string))
	;; and the end of the last
	:when (zerop balance)
	  :do (setf string (string-right-trim *trim-characters* string))
	:when (plusp (length string))
	  :collect string
	:when (plusp balance)
	  :collect (read stream t nil t)
	:until (zerop balance)))


(defun error-on-delimiter (stream char)
  "Raise an error if we hit a delimiter (e.g. }) in an unexpected context."
  (declare (ignore stream))
  (error "Delimiter ~S shouldn't be read alone" char))


(defun read-scrawl-expression (stream char)
  "Read a full Scrawl expression."
  (declare (ignore char))
  (flet ((peek () (peek-char nil stream nil nil t)))
      (let ((operator (read stream t nil t))
	    (args nil)
	    (body nil)
	    (op-only t))
	(when (char= +left-bracket+ (peek))
	  (setf args (read stream nil nil t)
		op-only nil))
	(when (char= +left-brace+ (peek))
	  (setf body (read stream nil nil t)
		op-only nil))
	(if op-only
	    operator
	    (append (list operator) args body)))))


(named-readtables:defreadtable syntax
  (:merge :standard)
  (:macro-char +at-sign+ #'read-scrawl-expression)
  (:macro-char +left-bracket+ #'read-left-bracket)
  (:macro-char +right-bracket+ (get-macro-character #\) nil))
  (:macro-char +left-brace+ #'read-left-brace)
  (:macro-char +right-brace+ #'error-on-delimiter))

