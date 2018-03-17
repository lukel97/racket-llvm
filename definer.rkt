#lang racket
(require ffi/unsafe
         ffi/unsafe/define)

(define (get-llvm-lib-dir)
  (let ([path (find-executable-path "llvm-config")])
    (if (not path)
      (list "/usr/local/opt/llvm/lib") ; fallback
      (list (string-trim
              (with-output-to-string
                (λ () (system* path "--libdir"))))))))

(define-ffi-definer define-llvm (ffi-lib "libLLVM"
                                         '("6" #f)
                                         ;TODO: Add more search directories
                                         #:get-lib-dirs get-llvm-lib-dir))
(provide define-llvm)

(define _LLVMModuleRef (_cpointer 'LLVMOpaqueModule))
(define _LLVMTypeRef (_cpointer 'LLVMOpaqueType))
(define _LLVMValueRef (_cpointer 'LLVMOpaqueValue))
(define _LLVMBasicBlockRef (_cpointer 'LLVMOpaqueBasicBlock))
(define _LLVMBuilderRef (_cpointer 'LLVMOpaqueBuilder))
(define _LLVMGenericValueRef (_cpointer 'LLVMOpaqueGenericValue))

(provide _LLVMModuleRef
         _LLVMTypeRef
         _LLVMValueRef
         _LLVMBasicBlockRef
         _LLVMBuilderRef
         _LLVMGenericValueRef)
