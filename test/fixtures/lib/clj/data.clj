(ns example.data)

(defn create_person [name age] {:name name :age age})

(defn get_config [] {:host "localhost" :port 8080 :debug true})

(defn nested_map [] {:user {:name "Bob" :email "bob@example.com"} :active true})

(defn empty_map [] {})
