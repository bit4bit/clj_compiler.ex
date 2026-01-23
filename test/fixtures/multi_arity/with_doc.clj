(ns with-doc)
(defn documented "A documented function" ([] "doc: default") ([x] (str "doc: " x)))
