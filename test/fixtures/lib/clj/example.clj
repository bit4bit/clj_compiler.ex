(ns example.core)

(defn hello [] "Hello World")

(defn greet [name] (str "Hello, " name))

(defn formal_greet [name] (str "Hello, " (CljCompilerTest.ClojureProject/greet_prefix name)))
