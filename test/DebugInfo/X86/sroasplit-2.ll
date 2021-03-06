; RUN: opt %s -sroa -verify -S -o - | FileCheck %s
;
; Test that we can partial emit debug info for aggregates repeatedly
; split up by SROA.
;
;    // Compile with -O1
;    typedef struct {
;      int a;
;      int b;
;    } Inner;
;
;    typedef struct {
;      Inner inner[2];
;    } Outer;
;
;    int foo(Outer outer) {
;      Inner i1 = outer.inner[1];
;      return i1.a;
;    }
;

; Verify that SROA creates a variable piece when splitting i1.
; CHECK:  call void @llvm.dbg.value(metadata i64 %outer.coerce0, i64 0, metadata ![[O:[0-9]+]], metadata ![[PIECE1:[0-9]+]]),
; CHECK:  call void @llvm.dbg.value(metadata i64 %outer.coerce1, i64 0, metadata ![[O]], metadata ![[PIECE2:[0-9]+]]),
; CHECK:  call void @llvm.dbg.value({{.*}}, i64 0, metadata ![[I1:[0-9]+]], metadata ![[PIECE3:[0-9]+]]),
; CHECK-DAG: ![[O]] = !MDLocalVariable(tag: DW_TAG_arg_variable, name: "outer",{{.*}} line: 10
; CHECK-DAG: ![[PIECE1]] = !MDExpression(DW_OP_bit_piece, 0, 64)
; CHECK-DAG: ![[PIECE2]] = !MDExpression(DW_OP_bit_piece, 64, 64)
; CHECK-DAG: ![[I1]] = !MDLocalVariable(tag: DW_TAG_auto_variable, name: "i1",{{.*}} line: 11
; CHECK-DAG: ![[PIECE3]] = !MDExpression(DW_OP_bit_piece, 0, 32)

; ModuleID = 'sroasplit-2.c'
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.9.0"

%struct.Outer = type { [2 x %struct.Inner] }
%struct.Inner = type { i32, i32 }

; Function Attrs: nounwind ssp uwtable
define i32 @foo(i64 %outer.coerce0, i64 %outer.coerce1) #0 {
  %outer = alloca %struct.Outer, align 8
  %i1 = alloca %struct.Inner, align 4
  %1 = bitcast %struct.Outer* %outer to { i64, i64 }*
  %2 = getelementptr { i64, i64 }, { i64, i64 }* %1, i32 0, i32 0
  store i64 %outer.coerce0, i64* %2
  %3 = getelementptr { i64, i64 }, { i64, i64 }* %1, i32 0, i32 1
  store i64 %outer.coerce1, i64* %3
  call void @llvm.dbg.declare(metadata %struct.Outer* %outer, metadata !24, metadata !2), !dbg !25
  call void @llvm.dbg.declare(metadata %struct.Inner* %i1, metadata !26, metadata !2), !dbg !27
  %4 = getelementptr inbounds %struct.Outer, %struct.Outer* %outer, i32 0, i32 0, !dbg !27
  %5 = getelementptr inbounds [2 x %struct.Inner], [2 x %struct.Inner]* %4, i32 0, i64 1, !dbg !27
  %6 = bitcast %struct.Inner* %i1 to i8*, !dbg !27
  %7 = bitcast %struct.Inner* %5 to i8*, !dbg !27
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %6, i8* %7, i64 8, i32 4, i1 false), !dbg !27
  %8 = getelementptr inbounds %struct.Inner, %struct.Inner* %i1, i32 0, i32 0, !dbg !28
  %9 = load i32, i32* %8, align 4, !dbg !28
  ret i32 %9, !dbg !28
}

; Function Attrs: nounwind readnone
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: nounwind
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture, i8* nocapture readonly, i64, i32, i1) #2

attributes #0 = { nounwind ssp uwtable "no-frame-pointer-elim"="true" }
attributes #1 = { nounwind readnone }
attributes #2 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!21, !22}
!llvm.ident = !{!23}

!0 = !MDCompileUnit(language: DW_LANG_C99, producer: "clang version 3.5.0 ", isOptimized: false, emissionKind: 1, file: !1, enums: !{}, retainedTypes: !{}, subprograms: !3, globals: !{}, imports: !{})
!1 = !MDFile(filename: "sroasplit-2.c", directory: "")
!2 = !MDExpression()
!3 = !{!4}
!4 = !MDSubprogram(name: "foo", line: 10, isLocal: false, isDefinition: true, virtualIndex: 6, flags: DIFlagPrototyped, isOptimized: false, scopeLine: 10, file: !1, scope: !5, type: !6, function: i32 (i64, i64)* @foo, variables: !{})
!5 = !MDFile(filename: "sroasplit-2.c", directory: "")
!6 = !MDSubroutineType(types: !7)
!7 = !{!8, !9}
!8 = !MDBasicType(tag: DW_TAG_base_type, name: "int", size: 32, align: 32, encoding: DW_ATE_signed)
!9 = !MDDerivedType(tag: DW_TAG_typedef, name: "Outer", line: 8, file: !1, baseType: !10)
!10 = !MDCompositeType(tag: DW_TAG_structure_type, line: 6, size: 128, align: 32, file: !1, elements: !11)
!11 = !{!12}
!12 = !MDDerivedType(tag: DW_TAG_member, name: "inner", line: 7, size: 128, align: 32, file: !1, scope: !10, baseType: !13)
!13 = !MDCompositeType(tag: DW_TAG_array_type, size: 128, align: 32, baseType: !14, elements: !19)
!14 = !MDDerivedType(tag: DW_TAG_typedef, name: "Inner", line: 4, file: !1, baseType: !15)
!15 = !MDCompositeType(tag: DW_TAG_structure_type, line: 1, size: 64, align: 32, file: !1, elements: !16)
!16 = !{!17, !18}
!17 = !MDDerivedType(tag: DW_TAG_member, name: "a", line: 2, size: 32, align: 32, file: !1, scope: !15, baseType: !8)
!18 = !MDDerivedType(tag: DW_TAG_member, name: "b", line: 3, size: 32, align: 32, offset: 32, file: !1, scope: !15, baseType: !8)
!19 = !{!20}
!20 = !MDSubrange(count: 2)
!21 = !{i32 2, !"Dwarf Version", i32 2}
!22 = !{i32 1, !"Debug Info Version", i32 3}
!23 = !{!"clang version 3.5.0 "}
!24 = !MDLocalVariable(tag: DW_TAG_arg_variable, name: "outer", line: 10, arg: 1, scope: !4, file: !5, type: !9)
!25 = !MDLocation(line: 10, scope: !4)
!26 = !MDLocalVariable(tag: DW_TAG_auto_variable, name: "i1", line: 11, scope: !4, file: !5, type: !14)
!27 = !MDLocation(line: 11, scope: !4)
!28 = !MDLocation(line: 12, scope: !4)
