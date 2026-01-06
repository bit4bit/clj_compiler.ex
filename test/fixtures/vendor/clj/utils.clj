(ns vendor.utils (:use [CljCompiler.Compat]))

(defn reverse_string [s] (Enum/join (Enum/reverse (String/graphemes s)) ""))

(defn double [n] (* n 2))
