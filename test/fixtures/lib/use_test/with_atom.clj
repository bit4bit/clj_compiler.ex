(ns use-example.with-atom
  (:use [CljCompilerTest.TestUseModuleWithAtom :controller]))

(defn get_option [] (atom_option))
