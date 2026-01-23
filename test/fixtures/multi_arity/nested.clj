(ns nested (:use [CljCompiler.Compat]))
(defn nested ([] (if true "a" "b")) ([x] (if (nil? x) "c" "d")))
