#lang racket

(require ffi/unsafe
         "definer.rkt")

(define-llvm llvm-append-basic-block (_fun _LLVMValueRef
                                           _string
                                           -> _LLVMBasicBlockRef)
             #:c-id LLVMAppendBasicBlock)
(provide llvm-append-basic-block)

(define-llvm llvm-builder-create (_fun -> _LLVMBuilderRef) #:c-id LLVMCreateBuilder)
(provide llvm-builder-create)

(define-llvm llvm-builder-position-at-end (_fun _LLVMBuilderRef
                                                _LLVMBasicBlockRef
                                                -> _void)
             #:c-id LLVMPositionBuilderAtEnd)
(provide llvm-builder-position-at-end)

(define-llvm llvm-get-param (_fun _LLVMValueRef _int -> _LLVMValueRef) #:c-id LLVMGetParam)
(provide llvm-get-param)

(define-llvm llvm-build-ret (_fun _LLVMBuilderRef _LLVMValueRef -> _void)
             #:c-id LLVMBuildRet)
(provide llvm-build-ret)

(module+ test
  (require rackunit
           "module.rkt"
           "jit.rkt"
           "types.rkt")

  (define mod (llvm-module "test"))

  (llvm-link-in-mcjit)
  (llvm-initialize-native-target)

  (define (check-binary-inst make-inst
                             make-type
                             create-value
                             get-value
                             rhs
                             lhs
                             result)
    (define builder (llvm-builder-create))

    (define eng (llvm-create-execution-engine-for-module mod))

    (define func-type (llvm-function-type (make-type) (list (make-type) (make-type)) #f))
    (define func (llvm-add-function mod "func" func-type))

    (define entry (llvm-append-basic-block func "entry"))
    (llvm-builder-position-at-end builder entry)

    (define tmp (make-inst builder (llvm-get-param func 0) (llvm-get-param func 1) "tmp"))

    (llvm-build-ret builder tmp)

    (define args (map create-value (list rhs lhs)))

    (define res (llvm-run-function eng func args))

    (check-equal? result (get-value res)))

  (define (check-binary-int32-inst make-inst rhs lhs result)
    (check-binary-inst make-inst
                       llvm-int32-type
                       (λ (x) (llvm-create-generic-value-of-int (llvm-int32-type) x #f))
                       (λ (x) (llvm-generic-value-to-int x #f))
                       rhs lhs result))
  
  (define (check-binary-float-inst make-inst rhs lhs result)
    (check-binary-inst make-inst
                       llvm-float-type
                       (λ (x) (llvm-create-generic-value-of-float (llvm-float-type) x))
                       (λ (x) (llvm-generic-value-to-float (llvm-float-type) x))
                       rhs lhs result)))

(define-llvm llvm-build-add (_fun _LLVMBuilderRef
                                  _LLVMValueRef
                                  _LLVMValueRef
                                  _string
                                  -> _LLVMValueRef)
             #:c-id LLVMBuildAdd)
(provide llvm-build-add)

(module+ test
  (check-binary-int32-inst llvm-build-add 20 22 42))

(define-llvm llvm-build-sub (_fun _LLVMBuilderRef
                                  _LLVMValueRef
                                  _LLVMValueRef
                                  _string
                                  -> _LLVMValueRef)
             #:c-id LLVMBuildSub)
(provide llvm-build-sub)
(module+ test
  (check-binary-int32-inst llvm-build-sub 4321 321 4000))

(define-llvm llvm-build-mul (_fun _LLVMBuilderRef
                                  _LLVMValueRef
                                  _LLVMValueRef
                                  _string
                                  -> _LLVMValueRef)
             #:c-id LLVMBuildMul)
(provide llvm-build-mul)
(module+ test
  (check-binary-int32-inst llvm-build-mul 17 123 2091))

(define-llvm llvm-build-udiv (_fun _LLVMBuilderRef
                                  _LLVMValueRef
                                  _LLVMValueRef
                                  _string
                                  -> _LLVMValueRef)
             #:c-id LLVMBuildUDiv)
(provide llvm-build-udiv)
(module+ test
  (check-binary-int32-inst llvm-build-udiv 8 2 4)
  (check-binary-int32-inst llvm-build-udiv 57 7 8))

(define-llvm llvm-build-fadd (_fun _LLVMBuilderRef
                                   _LLVMValueRef
                                   _LLVMValueRef
                                   _string
                                   -> _LLVMValueRef)
             #:c-id LLVMBuildFAdd)
(provide llvm-build-fadd)
(module+ test
  (check-binary-float-inst llvm-build-fadd 2.5 3.82 6.319999694824219)
  (check-binary-float-inst llvm-build-fadd 2.5 -3.82 -1.3199999332427979))
