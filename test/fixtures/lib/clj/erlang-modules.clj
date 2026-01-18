(ns example.erlang-modules (:use [CljCompiler.Compat]))

;; :lists module tests
(defn append-lists []
  (:lists/append [1 2] [3 4]))

(defn reverse-list []
  (:lists/reverse [1 2 3]))

(defn map-inc []
  (:lists/map [1 2 3] (fn [x] (+ x 1))))

(defn filter-even []
  (:lists/filter (fn [x] (= 0 (:erlang/rem x 2))) [1 2 3 4 5]))

;; :maps module tests
(defn get-map-value []
  (:maps/get :name {:name "Alice" :age 30}))

(defn get-map-with-default []
  (:maps/get :missing {:name "Alice"} :default-value))

(defn merge-maps []
  (:maps/merge {:a 1} {:b 2}))

;; :timer module tests
(defn sleep-10-ms []
  (:timer/sleep 10))

;; :string module tests
(defn trim-string []
  (:string/trim "  hello  "))

(defn string-length []
  (:string/len "hello"))
