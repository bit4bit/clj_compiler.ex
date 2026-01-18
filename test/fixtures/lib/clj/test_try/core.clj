(ns test-try.core)

(defn safe-divide [a b]
  (try
    (/ a b)
    (catch ArithmeticError e
      :infinity)
    (finally
      :cleanup)))

(defn try-with-multiple-catches [x]
  (try
    (if (> x 0)
      :positive
      :non-positive)
    (catch RuntimeError e
      :runtime)
    (catch ArgumentError e
      :illegal)))

(defn try-without-catch []
  (try
    :result
    (finally
      :finally-executed)))

(defn nested-try [x]
  (try
    (try
      (/ 1 x)
      (catch ArithmeticError e
        :inner-caught))
    (catch RuntimeError e
      :outer-caught)))

(defn try-with-let [x]
  (try
    (let [result (/ 1 x)]
      result)
    (catch ArithmeticError e
      :error)))

(defn try-only-finally []
  (try
    :success
    (finally
      :always-run)))

(defn try-only-catch []
  (try
    :normal
    (catch RuntimeError e
      :caught)))