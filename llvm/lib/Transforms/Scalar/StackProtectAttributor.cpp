//===- StackProtectAttributor.cpp - Stack Protect Attributoor -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/Scalar/StackProtectAttributor.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

#define DEBUG_TYPE "stack-protect-attributor"

STATISTIC(
    NumFuncsWithAllocaInst,
    "Number of functions with an instruction to allocate memory on the stack");
STATISTIC(NumFuncsWithRemovedStackProtectAttr,
          "Number of functions with alloca and removed stack protect attr");

static cl::opt<bool>
    UseStackSafety("ctpa-optimize-ssp", cl::init(true), cl::Hidden,
                   cl::desc("Use Stack Safety analysis results"));

void StackProtectAttributorPass::processFunction(Function &F) const {

  bool hasAlloca = false;

  for (auto &I : instructions(&F))
    if (auto *AI = dyn_cast<AllocaInst>(&I)) {
      hasAlloca = true;
      NumFuncsWithAllocaInst++;
      if (!SSI->isSafe(*AI))
        return;
    }

  if (hasAlloca)
    NumFuncsWithRemovedStackProtectAttr++;

  F.removeFnAttr(Attribute::StackProtect);
  F.removeFnAttr(Attribute::StackProtectStrong);
}

PreservedAnalyses StackProtectAttributorPass::run(Module &M,
                                                  ModuleAnalysisManager &MAM) {
  if (!UseStackSafety)
    return PreservedAnalyses::all();

  SSI = &MAM.getResult<StackSafetyGlobalAnalysis>(M);
  for (Function &F : M)
    if (F.hasFnAttribute(Attribute::StackProtect) ||
        F.hasFnAttribute(Attribute::StackProtectStrong))
      processFunction(F);

  return PreservedAnalyses::all();
}
