(ns use-example.multi-line
  (:use [CljCompilerTest.TestUseModuleMultiLineA])
  (:use [CljCompilerTest.TestUseModuleMultiLineB]))

(defn check_multi_line [] (has_multi_line))
