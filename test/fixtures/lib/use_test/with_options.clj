(ns use-example.with-options
  (:use [CljCompilerTest.TestUseModuleWithOptions {:enabled true}]))

(defn check_config [] (configured))
