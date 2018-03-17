#lang racket

(require ffi/unsafe
         "definer.rkt")

(define-llvm llvm-append-basic-block (_fun _LLVMValueRef
                                           _string
                                           -> _LLVMBasicBlockRef)
             #:c-id LLVMAppendBasicBlock)
(provide llvm-append-basic-block)

(define-llvm llvm-create-builder (_fun -> _LLVMBuilderRef) #:c-id LLVMCreateBuilder)
(provide llvm-create-builder)

(define-llvm llvm-position-builder-at-end (_fun _LLVMBuilderRef
                                                _LLVMBasicBlockRef
                                                -> _void)
             #:c-id LLVMPositionBuilderAtEnd)
(provide llvm-position-builder-at-end)

(define-llvm llvm-get-param (_fun _LLVMValueRef _int -> _LLVMValueRef) #:c-id LLVMGetParam)
(provide llvm-get-param)

(define-llvm llvm-build-add (_fun _LLVMBuilderRef
                                  _LLVMValueRef
                                  _LLVMValueRef
                                  _string
                                  -> _LLVMValueRef)
             #:c-id LLVMBuildAdd)
(provide llvm-build-add)

(define-llvm llvm-build-sub (_fun _LLVMBuilderRef
                                  _LLVMValueRef
                                  _LLVMValueRef
                                  _string
                                  -> _LLVMValueRef)
             #:c-id LLVMBuildSub)
(provide llvm-build-sub)

(define-llvm llvm-build-ret (_fun _LLVMBuilderRef _LLVMValueRef -> _void)
             #:c-id LLVMBuildRet)
(provide llvm-build-ret)
