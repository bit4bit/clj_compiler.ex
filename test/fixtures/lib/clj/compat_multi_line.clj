(ns example.compat-multi-line
  (:use [CljCompiler.Compat])
  (:use [CljCompiler.Compat]))

(defn test-multi-line-compat []
  (inc 1))
