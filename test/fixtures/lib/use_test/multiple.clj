(ns use-example.multiple
  (:use [CljCompilerTest.TestUseModuleA]
        [CljCompilerTest.TestUseModuleB]))

(defn check_both [] (has_multiple))
