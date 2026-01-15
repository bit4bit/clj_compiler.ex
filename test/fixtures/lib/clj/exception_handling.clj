(ns exception-handling)

(defn safe-divide [a b]
  (try
    (/ a b)
    (catch ArithmeticException e "Division by zero")))

(defn with-finally [resource]
  (try
    (str "Using resource: " resource)
    (finally "Resource cleaned up")))

(defn multiple-catches [value]
  (try
    (/ 10 value)
    (catch ArithmeticException e "Arithmetic error")
    (catch Exception e "General error")))

(defn complete-try [value]
  (try
    (/ 10 value)
    (catch ArithmeticException e (str "Caught: " e))
    (finally "Cleanup complete")))

(defn nested-try [a b]
  (try
    (try
      (/ a b)
      (catch ArithmeticException e "Inner catch"))
    (catch Exception e "Outer catch")))
