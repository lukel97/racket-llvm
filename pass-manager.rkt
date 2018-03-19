#lang racket

(require ffi/unsafe
         "definer.rkt")

#| Pass manager builder |#

(define-llvm llvm-pass-manager-builder-create (_fun -> _LLVMPassManagerBuilderRef)
             #:c-id LLVMPassManagerBuilderCreate)
(provide llvm-pass-manager-builder-create)

(define-llvm llvm-pass-manager-builder-set-opt-level
             (_fun _LLVMPassManagerBuilderRef
                   _uint
                   -> _void)
             #:c-id LLVMPassManagerBuilderSetOptLevel)
(provide llvm-pass-manager-builder-set-opt-level)

(define-llvm llvm-pass-manager-builder-populate-module-pass-manager
             (_fun _LLVMPassManagerBuilderRef
                   _LLVMPassManagerRef
                   -> _void)
             #:c-id LLVMPassManagerBuilderPopulateModulePassManager)
(provide llvm-pass-manager-builder-populate-module-pass-manager)

(define-llvm llvm-pass-manager-builder-populate-function-pass-manager
             (_fun _LLVMPassManagerBuilderRef
                   _LLVMPassManagerRef
                   -> _void)
             #:c-id LLVMPassManagerBuilderPopulateFunctionPassManager)
(provide llvm-pass-manager-builder-populate-function-pass-manager)

#| Whole module pass manager |#

(define-llvm llvm-pass-manager-create (_fun -> _LLVMPassManagerRef)
             #:c-id LLVMCreatePassManager)
(provide llvm-pass-manager-create)

(define-llvm llvm-pass-manager-run (_fun _LLVMPassManagerRef
                                         _LLVMModuleRef
                                         -> _bool)
             #:c-id LLVMRunPassManager)
(provide llvm-pass-manager-run)

#| Function pass manager |#

(define-llvm llvm-function-pass-manager-create (_fun _LLVMModuleRef -> _LLVMPassManagerRef)
             #:c-id LLVMCreateFunctionPassManagerForModule)

(provide llvm-function-pass-manager-create)

