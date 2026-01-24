(ns test.tuple)

(defn get-pair [] #[:a :b])

(defn empty-tuple [] #[])

(defn multi [] #[:a 1 "string" :keyword])

(defn nested [] #[{:a 1} [1 2]])

(defn let-tuple []
  (let [t #[:x :y]]
    t))

(defn take-tuple [t] t)

(defn use-tuple [] (take-tuple #[:a :b]))

(defn nested-tuples [] #[[:a] [:b :c]])

(defn with-comment []
  #[:a ; comment
    :b])

(defn with-discard []
  #[:a #_ :skip :b])

(defn get-data [] {:pair #[:x :y]})

(defn pair [] #[:a :b])
(defn triple [] #[:x :y :z])

(defn nested-let []
  (let [a :x
        b :y]
    #[:a :b]))
