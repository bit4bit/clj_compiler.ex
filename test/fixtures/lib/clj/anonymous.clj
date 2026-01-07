(ns example.anonymous)

(defn call_immediate [] ((fn [x] (* x 2)) 5))

(defn use_in_let [] (let [f (fn [x] (* x 2))] (f 10)))

(defn make_adder [n] (fn [x] (+ x n)))

(defn call_returned_fn [] ((make_adder 5) 3))

(defn no_params [] ((fn [] 42)))

(defn multi_params [] ((fn [a b c] (+ a (+ b c))) 1 2 3))

(defn capture_variable [multiplier]
  (let [f (fn [x] (* x multiplier))]
    (f 7)))

(defn nested_fns [] ((fn [x] ((fn [y] (+ x y)) 3)) 5))

(defn complex_body [] ((fn [x] (if (> x 0) (* x 2) 0)) 5))

(defn map_with_fn [lst] (Enum/map lst (fn [x] (* x 2))))

(defn filter_with_fn [lst] (Enum/filter lst (fn [x] (> x 5))))

(defn reduce_with_fn [lst] (Enum/reduce lst 0 (fn [acc x] (+ acc x))))
