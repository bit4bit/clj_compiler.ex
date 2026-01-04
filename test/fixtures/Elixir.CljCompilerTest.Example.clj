; LLM-Assisted

(defn hello [] "Hello World")

(defn greet [name] (str "Hello, " name))

(defn add [a b] (+ a b))

(defn is_positive [n] (if (> n 0) "positive" "negative"))

(defn compute [x] (let [a (+ x 5) b (* x 2)] (+ a b)))

(defn factorial [n] (if (< n 2) 1 (* n (factorial (- n 1)))))

(defn list_length [lst] (Enum/count lst))
