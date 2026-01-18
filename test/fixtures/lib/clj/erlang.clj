(ns fixtures.lib.clj.erlang) (ns example.erlang
                               (:use [CljCompiler.Compat]))

;; Test basic unique_integer call
(defn get-unique-integer []
  (:erlang/unique_integer))

;; Test unique_integer with positive modifier
(defn get-positive-unique-integer []
  (:erlang/unique_integer [:positive]))

;; Test that unique integers are unique
(defn get-multiple-unique-integers []
  (let [first-int (:erlang/unique_integer)
        second-int (:erlang/unique_integer)]
    (+ first-int second-int)))

;; Test unique_integer in expression
(defn unique-integer-plus-one []
  (+ (:erlang/unique_integer) 1))
