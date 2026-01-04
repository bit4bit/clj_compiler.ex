(ns vendor.utils)

(defn reverse_string [s] (Enum/join (Enum/reverse (String/graphemes s)) ""))

(defn double [n] (* n 2))
