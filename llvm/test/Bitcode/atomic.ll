; RUN: llvm-as --opaque-pointers=0 %s -o - | llvm-dis --opaque-pointers=0 | FileCheck %s
; RUN: verify-uselistorder --opaque-pointers=0 < %s

define void @test_cmpxchg(i32* %addr, i32 %desired, i32 %new) {
  cmpxchg i32* %addr, i32 %desired, i32 %new seq_cst seq_cst
  ; CHECK: cmpxchg i32* %addr, i32 %desired, i32 %new seq_cst seq_cst

  cmpxchg volatile i32* %addr, i32 %desired, i32 %new seq_cst monotonic
  ; CHECK: cmpxchg volatile i32* %addr, i32 %desired, i32 %new seq_cst monotonic

  cmpxchg weak i32* %addr, i32 %desired, i32 %new acq_rel acquire
  ; CHECK: cmpxchg weak i32* %addr, i32 %desired, i32 %new acq_rel acquire

  cmpxchg weak volatile i32* %addr, i32 %desired, i32 %new syncscope("singlethread") release monotonic
  ; CHECK: cmpxchg weak volatile i32* %addr, i32 %desired, i32 %new syncscope("singlethread") release monotonic

  ret void
}
