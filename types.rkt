#lang racket

(require ffi/unsafe
         "definer.rkt")

(define-llvm llvm-int32-type (_fun -> _LLVMTypeRef)
             #:c-id LLVMInt32Type)
(provide llvm-int32-type)

(define-llvm llvm-create-generic-value-of-int (_fun _LLVMTypeRef
                                                    _int ; value
                                                    _bool ; signed?
                                                    -> _LLVMGenericValueRef)
             #:c-id LLVMCreateGenericValueOfInt)
(provide llvm-create-generic-value-of-int)

(define-llvm llvm-generic-value-to-int (_fun _LLVMGenericValueRef _bool -> _llong)
             #:c-id LLVMGenericValueToInt)
(provide llvm-generic-value-to-int)

(define-llvm llvm-function-type (_fun  _LLVMTypeRef ; return type
                                       (param-types : (_list i _LLVMTypeRef)) ; param types
                                       (_int = (length param-types)) ; num params
                                       _bool ; variadic?
                                       -> _LLVMTypeRef)
             #:c-id LLVMFunctionType)
(provide llvm-function-type)
