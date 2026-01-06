(ns test.compat (:use [CljCompiler.Compat]))

(defn test-conj [] (conj [1] 0))

(defn test-get [m] (get m :key))

(defn test-assoc [] (assoc {:a 1} :b 2))

(defn test-dissoc [] (dissoc {:a 1 :b 2 :c 3} [:a :c]))

(defn test-assoc-in [] (assoc-in {:a {:b 1}} [:a :b] 2))