#lang racket

(require ffi/unsafe
         ffi/unsafe/define)

(require "module.rkt"
         "types.rkt"
         "builder.rkt"
         "jit.rkt")
(provide (all-from-out
           "module.rkt"
           "types.rkt"
           "builder.rkt"
           "jit.rkt"))

(module+ test
  (require rackunit)
  
  (let*
    ([mod (llvm-module-create-with-name "testModule")]
     [return-type (llvm-function-type (llvm-int32-type)
                                      (list (llvm-int32-type)
                                            (llvm-int32-type))
                                      #f)]
     [sum (llvm-add-function mod "sum" return-type)]

     [entry (llvm-append-basic-block sum "entry")]

     [builder (llvm-create-builder)])

    (begin
      (llvm-position-builder-at-end builder entry)
      (let ([tmp (llvm-build-add builder
                                 (llvm-get-param sum 0)
                                 (llvm-get-param sum 1)
                                 "tmp")])
        (begin
          (llvm-build-ret builder tmp)

          (llvm-verify-module mod)

          (let* 
            ([eng (llvm-create-execution-engine-for-module mod)]
             [args (list (llvm-create-generic-value-of-int (llvm-int32-type) 20 #f)
                         (llvm-create-generic-value-of-int (llvm-int32-type) 22 #f))]
             [res (llvm-run-function eng sum args)])
            (check-equal? 42 (llvm-generic-value-to-int res #f))))))))

;TODO: test error thrown when llvm-verify-module fails
