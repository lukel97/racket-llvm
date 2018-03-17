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

(define _LLVMModuleRef (_cpointer 'LLVMOpaqueModule))
(define _LLVMTypeRef (_cpointer 'LLVMOpaqueType))
(define _LLVMValueRef (_cpointer 'LLVMOpaqueValue))
(define _LLVMBasicBlockRef (_cpointer 'LLVMOpaqueBasicBlock))
(define _LLVMBuilderRef (_cpointer 'LLVMOpaqueBuilder))

(define-llvm llvm-module-create-with-name (_fun _string -> _LLVMModuleRef)
             #:c-id LLVMModuleCreateWithName)
(provide llvm-module-create-with-name)

(define-llvm llvm-function-type (_fun  _LLVMTypeRef ; return type
                                       (param-types : (_list i _LLVMTypeRef)) ; param types
                                       (_int = (length param-types)) ; num params
                                       _bool ; variadic?
                                       -> _LLVMTypeRef)
             #:c-id LLVMFunctionType)
(provide llvm-function-type)

(define-llvm llvm-add-function (_fun _LLVMModuleRef
                                     _string
                                     _LLVMTypeRef
                                     -> _LLVMValueRef)
             #:c-id LLVMAddFunction)
(provide llvm-add-function)


(define-llvm llvm-int32-type (_fun -> _LLVMTypeRef)
             #:c-id LLVMInt32Type)
(provide llvm-int32-type)

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

(define-llvm llvm-build-ret (_fun _LLVMBuilderRef _LLVMValueRef -> _void)
             #:c-id LLVMBuildRet)
(provide llvm-build-ret)

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

(define _LLVMExecutionEngineRef (_cpointer 'LLVMOpaqueExecutionEngine))

(define-llvm llvm-link-in-mcjit (_fun -> _void) #:c-id LLVMLinkInMCJIT)
(provide llvm-link-in-mcjit)

(llvm-link-in-mcjit)

;TODO: figure out a way of replacing X86 with the current arch
(define-llvm llvm-initialize-native-target (_fun -> _bool) #:c-id LLVMInitializeX86Target)
(provide llvm-initialize-native-target)

(define-llvm llvm-create-execution-engine-for-module
             (_fun (eng : (_ptr o _LLVMExecutionEngineRef))
                   _LLVMModuleRef
                   (err : (_ptr o _string))
                   -> (result : _int)
                   -> (cond
                        [err (error err)] ;TODO: use `llvm-dispose-message`
                        [(not (= 0 result)) (error "Failed to create execution engine")]
                        [else eng]))
             #:c-id LLVMCreateExecutionEngineForModule)
(provide llvm-create-execution-engine-for-module)


(define _LLVMGenericValueRef (_cpointer 'LLVMOpaqueGenericValue))

(define-llvm llvm-create-generic-value-of-int (_fun _LLVMTypeRef
                                                    _int ; value
                                                    _bool ; signed?
                                                    -> _LLVMGenericValueRef)
             #:c-id LLVMCreateGenericValueOfInt)
(provide llvm-create-generic-value-of-int)


(define-llvm llvm-run-function (_fun _LLVMExecutionEngineRef
                                     _LLVMValueRef
                                     (_int = (length args))
                                     (args : (_list i _LLVMGenericValueRef))
                                     -> _LLVMGenericValueRef)
             #:c-id LLVMRunFunction)
(provide llvm-run-function)

(define-llvm llvm-generic-value-to-int (_fun _LLVMGenericValueRef _bool -> _llong)
             #:c-id LLVMGenericValueToInt)
(provide llvm-generic-value-to-int)

(define-llvm llvm-module-to-string (_fun _LLVMModuleRef -> _string)
             #:c-id LLVMPrintModuleToString)
(provide llvm-module-to-string)

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
