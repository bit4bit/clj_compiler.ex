(ns test-try-simple.core)

(defn basic-try []
  (try
    :success
    (catch Exception e
      :caught)))

(defn try-with-finally []
  (try
    :result
    (finally
      :cleanup)))

 (defn safe-divide [a b]
   (try
     (/ a b)
     (catch ArithmeticError e
       :infinity)))