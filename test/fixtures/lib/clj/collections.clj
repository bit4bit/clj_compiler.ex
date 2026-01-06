(ns example.collections (:use [CljCompiler.Compat]))

(defn add_to_list [item lst] (conj lst item))

(defn add_to_vector [vec item] (conj vec item))

(defn conj_empty [item] (conj [] item))
