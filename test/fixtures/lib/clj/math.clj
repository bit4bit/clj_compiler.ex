(ns example.math)

(defn add [a b] (+ a b))

(defn multiply [a b] (* a b))

(defn factorial [n] (if (< n 2) 1 (* n (factorial (- n 1)))))

(defn sum_via_parent [a b] (do_sum a b))
