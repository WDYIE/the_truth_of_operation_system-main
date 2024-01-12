	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 14, 0	sdk_version 14, 2
	.syntax unified
	.globl	_main                           @ -- Begin function main
	.p2align	2
	.code	32                              @ @main
_main:
@ %bb.0:
	sub	sp, sp, #4
	mov	r0, #0
	str	r0, [sp]
	b	LBB0_1
LBB0_1:                                 @ =>This Inner Loop Header: Depth=1
	b	LBB0_1
                                        @ -- End function
.subsections_via_symbols
