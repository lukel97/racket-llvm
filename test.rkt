#lang racket/base

(require ffi/unsafe
         ffi/unsafe/define
         ffi/cvector)

(define-ffi-definer define-llvm (ffi-lib "libLLVM"
                                         '("6" #f)
                                         ;TODO: Add more search directories
                                         #:get-lib-dirs (λ () (list "/usr/local/opt/llvm/lib"))))

(define _LLVMModuleRef (_cpointer 'LLVMOpaqueModule))
(define _LLVMTypeRef (_cpointer 'LLVMOpaqueType))
(define _LLVMValueRef (_cpointer 'LLVMOpaqueValue))
(define _LLVMBasicBlockRef (_cpointer 'LLVMOpaqueBasicBlock))
(define _LLVMBuilderRef (_cpointer 'LLVMOpaqueBuilder))

(define-llvm LLVMModuleCreateWithName (_fun _string -> _LLVMModuleRef))

(define-llvm LLVMFunctionType (_fun  _LLVMTypeRef ; return type
                                    (param-types : (_list i _LLVMTypeRef)) ; param types
                                    (_int = (length param-types)) ; num params
                                    _int  ; variadic?
                                    -> _LLVMTypeRef))
(define-llvm LLVMAddFunction (_fun _LLVMModuleRef
                                   _string
                                   _LLVMTypeRef
                                   -> _LLVMValueRef))


(define mod (LLVMModuleCreateWithName "testModule"))

#| C code taken from
   https://pauladamsmith.com/blog/2015/01/how-to-get-started-with-llvm-c-api.html |#

#|  LLVMTypeRef param_types[] = { LLVMInt32Type(), LLVMInt32Type() };
    LLVMTypeRef ret_type = LLVMFunctionType(LLVMInt32Type(), param_types, 2, 0);
    LLVMValueRef sum = LLVMAddFunction(mod, "sum", ret_type); |#

(define-llvm LLVMInt32Type (_fun -> _LLVMTypeRef))

(define return-type (LLVMFunctionType (LLVMInt32Type) (list (LLVMInt32Type) (LLVMInt32Type)) 0))
(define sum (LLVMAddFunction mod "sum" return-type))

#| LLVMBasicBlockRef entry = LLVMAppendBasicBlock(sum, "entry"); |#


(define-llvm LLVMAppendBasicBlock (_fun _LLVMValueRef
                                        _string
                                        -> _LLVMBasicBlockRef))

(define entry (LLVMAppendBasicBlock sum "entry"))

#|  LLVMBuilderRef builder = LLVMCreateBuilder();
    LLVMPositionBuilderAtEnd(builder, entry); |#

(define-llvm LLVMCreateBuilder (_fun -> _LLVMBuilderRef))

(define-llvm LLVMPositionBuilderAtEnd (_fun _LLVMBuilderRef
                                            _LLVMBasicBlockRef
                                            -> _void))

(define builder (LLVMCreateBuilder))
(LLVMPositionBuilderAtEnd builder entry)

#|  LLVMValueRef tmp = LLVMBuildAdd(builder, LLVMGetParam(sum, 0), LLVMGetParam(sum, 1), "tmp");
    LLVMBuildRet(builder, tmp); |#

(define-llvm llvm-get-param (_fun _LLVMValueRef _int -> _LLVMValueRef) #:c-id LLVMGetParam)

(define-llvm LLVMBuildAdd (_fun _LLVMBuilderRef
                                _LLVMValueRef
                                _LLVMValueRef
                                _string
                                -> _LLVMValueRef))

(define-llvm LLVMBuildRet (_fun _LLVMBuilderRef _LLVMValueRef -> _void))


(define tmp (LLVMBuildAdd builder (llvm-get-param sum 0) (llvm-get-param sum 1) "tmp"))
(LLVMBuildRet builder tmp)

#|  char *error = NULL;
    LLVMVerifyModule(mod, LLVMAbortProcessAction, &error);
    LLVMDisposeMessage(error); |#

(define _LLVMVerifierFailureAction
  (_enum '(llvm-abort-process-action
            llvm-print-message-action
            llvm-return-status-action)))

(define-llvm llvm-dispose-message (_fun (_ptr i _string) -> _void)
             #:c-id LLVMDisposeMessage)

(define-llvm llvm-verify-module (_fun _LLVMModuleRef
                                      (_LLVMVerifierFailureAction = 'llvm-return-status-action)
                                      (err : (_ptr o _string))
                                      -> (failure : _bool)
                                      ; TODO: should call llvm-dispose-message
                                      -> (when failure (error err)))
             #:c-id LLVMVerifyModule)

(llvm-verify-module mod)

#|  LLVMExecutionEngineRef engine;
    error = NULL;
    LLVMLinkInMCJIT();
    LLVMInitializeNativeTarget();
    if (LLVMCreateExecutionEngineForModule(&engine, mod, &error) != 0) {
        fprintf(stderr, "failed to create execution engine\n");
        abort();
    }
    if (error) {
        fprintf(stderr, "error: %s\n", error);
        LLVMDisposeMessage(error);
        exit(EXIT_FAILURE);
    } |#

(define _LLVMExecutionEngineRef (_cpointer 'LLVMOpaqueExecutionEngine))

(define-llvm llvm-link-in-mcjit (_fun -> _void) #:c-id LLVMLinkInMCJIT)

;TODO: figure out a way of replacing X86 with the current arch
(define-llvm llvm-initialize-native-target (_fun -> _bool) #:c-id LLVMInitializeX86Target)

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

(define eng (llvm-create-execution-engine-for-module mod))

#|  if (argc < 3) {
        fprintf(stderr, "usage: %s x y\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    long long x = strtoll(argv[1], NULL, 10);
    long long y = strtoll(argv[2], NULL, 10); |#

(define-values (x y) (values (read) (read)))

#|  LLVMGenericValueRef args[] = {
      LLVMCreateGenericValueOfInt(LLVMInt32Type(), x, 0),
      LLVMCreateGenericValueOfInt(LLVMInt32Type(), y, 0)
  }; |#

(define _LLVMGenericValueRef (_cpointer 'LLVMOpaqueGenericValue))

(define-llvm llvm-create-generic-value-of-int (_fun _LLVMTypeRef
                                                    _int
                                                    _int
                                                    -> _LLVMGenericValueRef)
             #:c-id LLVMCreateGenericValueOfInt)

(define args (list (llvm-create-generic-value-of-int (LLVMInt32Type) x 0)
                   (llvm-create-generic-value-of-int (LLVMInt32Type) y 0)))

#|  LLVMGenericValueRef res = LLVMRunFunction(engine, sum, 2, args); |#

(define-llvm llvm-run-function (_fun _LLVMExecutionEngineRef
                                     _LLVMValueRef
                                     (_int = (length args))
                                     (args : (_list i _LLVMGenericValueRef))
                                     -> _LLVMGenericValueRef)
             #:c-id LLVMRunFunction)

(define res (llvm-run-function eng sum args))

#| printf("%d\n", (int)LLVMGenericValueToInt(res, 0)); |#

(define-llvm llvm-generic-value-to-int (_fun _LLVMGenericValueRef _bool -> _llong)
             #:c-id LLVMGenericValueToInt)

(println (llvm-generic-value-to-int res #f))
