(ns test.compat (:use [CljCompiler.Compat]))

;; conj/2 tests
(defn test-conj [] (conj [1] 0))

(defn test-conj-empty [] (conj [] 1))

(defn test-conj-multiple [] (conj (conj [3] 2) 1))

;; get/2 tests
(defn test-get [m] (get m :key))

(defn test-get-missing [] (get {:a 1} :b))

;; get/3 tests
(defn test-get-with-default [] (get {:a 1} :b "default"))

(defn test-get-default-unused [] (get {:a 1} :a "default"))

;; assoc/3 tests
(defn test-assoc [] (assoc {:a 1} :b 2))

(defn test-assoc-update [] (assoc {:a 1} :a 2))

(defn test-assoc-empty [] (assoc {} :a 1))

;; dissoc/2 tests
(defn test-dissoc [] (dissoc {:a 1 :b 2 :c 3} [:a :c]))

(defn test-dissoc-single [] (dissoc {:a 1 :b 2} [:a]))

(defn test-dissoc-empty [] (dissoc {:a 1 :b 2} []))

;; assoc_in/3 tests
(defn test-assoc-in [] (assoc-in {:a {:b 1}} [:a :b] 2))

(defn test-assoc-in-nested [] (assoc-in {:a {:b {}}} [:a :b :c] 1))

(defn test-assoc-in-single [] (assoc-in {} [:a] 1))

;; inc/1 tests
(defn test-inc [] (inc 1))

(defn test-inc-zero [] (inc 0))

(defn test-inc-negative [] (inc -1))

;; map/2 tests
(defn test-map [] (map (fn [x] (* x 2)) [1 2 3]))

(defn test-map-empty [] (map (fn [x] (* x 2)) []))

;; nil?/1 tests
(defn test-nil-false [] (nil? 0))

(defn test-nil-string [] (nil? ""))

(defn test-nil-map [] (nil? {:a 1}))

(defn test-nil-list [] (nil? [1 2 3]))

;; kw/1 tests
(defn test-kw [] (kw {:a 1 :b 2}))

(defn test-kw-empty [] (kw {}))

(defn test-kw-nested [] (kw {:a {:b 1} :c [1 2]}))
