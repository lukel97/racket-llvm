#lang racket

(require ffi/unsafe
         "definer.rkt")

(define-llvm llvm-module-create-with-name (_fun _string -> _LLVMModuleRef)
             #:c-id LLVMModuleCreateWithName)
(provide llvm-module-create-with-name)

(define _LLVMVerifierFailureAction
  (_enum '(llvm-abort-process-action
            llvm-print-message-action
            llvm-return-status-action)))

(define-llvm llvm-dispose-message (_fun (_ptr i _string) -> _void)
             #:c-id LLVMDisposeMessage)
(provide llvm-dispose-message)

(define-llvm llvm-verify-module (_fun _LLVMModuleRef
                                      (_LLVMVerifierFailureAction = 'llvm-return-status-action)
                                      (err : (_ptr o _string))
                                      -> (failure : _bool)
                                      ; TODO: should call llvm-dispose-message
                                      -> (when failure (error err)))
             #:c-id LLVMVerifyModule)
(provide llvm-verify-module)

(define-llvm llvm-module-to-string (_fun _LLVMModuleRef -> _string)
             #:c-id LLVMPrintModuleToString)
(provide llvm-module-to-string)

(define-llvm llvm-add-function (_fun _LLVMModuleRef
                                     _string
                                     _LLVMTypeRef
                                     -> _LLVMValueRef)
             #:c-id LLVMAddFunction)
(provide llvm-add-function)
