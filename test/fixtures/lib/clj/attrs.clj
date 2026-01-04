(ns example.attrs)

(def max-size 100)
(def default-name "unknown")
(def pi 3.14)

(defn get-max [] max-size)

(defn get-name [] default-name)

(defn get-pi [] pi)

(defn compute-area [radius]
  (* pi (* radius radius)))
