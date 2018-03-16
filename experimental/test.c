#include <llvm-c/Analysis.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/Core.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/Target.h>

int foo() {
  LLVMModuleRef mod = LLVMModuleCreateWithName("my_module");
  return 42;
}
