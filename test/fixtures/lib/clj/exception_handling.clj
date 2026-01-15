(ns example.exception-handling)

(defn safe_divide [a b]
  (try
    (+ a b)
    (catch RuntimeException e
      "Division by zero")))

(defn safe_divide_with_finally [a b]
  (try
    (+ a b)
    (catch RuntimeException e
      "Division by zero")
    (finally
      nil)))

(defn simple_try [value]
  (try
    (if (= value "error")
      0
      "success")
    (catch RuntimeException e
      "caught")))
