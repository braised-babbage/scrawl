(asdf:defsystem #:scrawl
  :description "Reader extensions for Scribble-like syntax"
  :author "Erik Davis <erik@cadlag.org>"
  :license "MIT"
  :depends-on (#:named-readtables #:cl-ppcre)
  :serial t
  :components ((:file "scrawl")))
