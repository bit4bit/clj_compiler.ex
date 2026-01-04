(ns example.data)

(defn create_person [name age] {:name name :age age})

(defn get_config [] {:host "localhost" :port 8080 :debug true})

(defn nested_map [] {:user {:name "Bob" :email "bob@example.com"} :active true})

(defn empty_map [] {})

(defn get_name [person] (:name person))

(defn get_id [user] (:id user))

(defn identity_map [m] m)

(defn lookup_name [person] (get person :name))

(defn get_with_default [m k] (get m k "not found"))

(defn add_age [person age] (assoc person :age age))

(defn update_age [person age] (assoc person :age age))

(defn remove_city [person] (dissoc person :city))

(defn remove_multiple [m] (dissoc m :b :c))

(defn remove_many [m] (dissoc m :b :c :d :e :f))
