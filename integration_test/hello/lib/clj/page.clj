(ns web.page-controller
  (:use [HelloWeb :controller]))

(defn home [conn params]
  (render conn :home))
