(ns with-let)
(defn with-let ([] (let [x 1] x)) ([y] (let [z y] z)))
