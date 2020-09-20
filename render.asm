; squash "relocation R_X86_64_32S against `.bss', use -fPIE" error
DEFAULT REL

extern timer
extern frame
;; extern bytesPerPixel
global asmRenderTo
global cxres
global cyres
	
section .rodata align=16
tmatidentity:
	dd 1.0, 0.0
	dd 0.0, 1.0
	
section .data
;; memo: important that image in GIMP should have an Alpha channel before exporting,
;; or else this image will cause problems!
;;
;; Iif no Alpha Channel, do  [ Layers -> Transparency -> Add Alpha Channel ]
;; And then Export RGBA picture with settings:
;;    RGB Save Type =  Standard (R, G, B)
;;    Indexed Palette Type = B, G, R, X (BMP style)
align 16
meow:  incbin "cat.img"
bytesPerPixel: equ 4
clearColor: db 127,64,0,0	; Blue, Green, Red, Alpha

;; section .bss align=16
;; affine matrix
align 16
tma:  dd 1.0
tmb:  dd 0.0
tmc:  dd 1.0
tmd:  dd 0.0
tx0:  dd 0
ty0:  dd 0
cxres: dd 256  			; canvas xres
cyres: dd 240			; canvas yres
	
section .text
asmRenderTo:
	;; rdi is pointer to PIXELS
	;; rsi is PIXELS WIDTH
	;; rdx is PIXELS HEIGHT
	;; not zeroing these caused Heisenbuggy problems

	pxor xmm0,xmm0
	pxor xmm1,xmm1
	pxor xmm2,xmm2
	pxor xmm3,xmm3
	pxor xmm4,xmm4
	pxor xmm5,xmm5
	pxor xmm6,xmm6
	pxor xmm7,xmm7
	pxor xmm8,xmm8
	pxor xmm9,xmm9
	pxor xmm10,xmm10
	pxor xmm11,xmm11
	pxor xmm12,xmm12
	pxor xmm13,xmm13
	pxor xmm14,xmm14
	pxor xmm15,xmm15
	
	mov r8d,esi		; r8 = width / columns / x-res
	mov [cxres],esi
	mov r9d,edx		; r9 = height / rows / y-res
	mov [cyres],edx

	call InitAffineMatrix

	mov eax,[clearColor]
	call FillCanvas

	mov rsi,meow
	call MatrixBlitSprite

	mov rsi,meow	; ptr to 64x64x32bit cat graphic
	mov rax,16
	mov rbx,8
	call DrawSprite
	ret

;; ==========================
;; InitAffineMatrix, initialize affine matrix to identity-ish
;; No parameters
InitAffineMatrix:
	push rbp
	mov rbp,rsp
	
	;; set 2x2 part of the affine matrix to be [1.0, 0.0],[0.0, 1.0]
	movaps xmm0,[tmatidentity]
	movaps [tma],xmm0

	pop rbp
	ret

	
;; ==========================
;; FillCanvas routine
;; eax = 32-bit color to fill the entire canvas with
FillCanvas:			
	xor rcx,rcx 	; i = 0
	mov rdx,r8
	imul rdx,r9		; rdx = total pixels (rows * columns)
_fillLoop:
	mov [rdi+rcx*bytesPerPixel], eax
	inc rcx			; i++
	cmp rcx,rdx		; if i < totalPixels,
	jl  _fillLoop		;    then keep looping
	ret			; else return
	
;; ==========================
;; DrawSprite routine
;; rsi = ptr to source image (for now, assumes 64x64, will update later)
;; rax = x
;; rbx = y
DrawSprite:
	push rsi
	push rdi
	
	; start memory for rdi = rdi + (4 * (y*Cols + x))
	mov r15,rbx		; r15 = y
	imul r15,r8		; r15 *= Cols
	add r15,rax		; r15 += x
	imul r15,bytesPerPixel	; r15 *= bytesPerPixel

	add rdi,r15		; rdi += offset according to r15

	mov rdx,0		; row
_blitRows:
	cld
	mov rcx,64		; tells 'rep movsd' to 64 times
	rep movsd		; copy 32-bit pixels rsi++->rdi++ 'rcx' times
	inc rdx			; row++
	cmp rdx,64		; if row==64
	je _endDrawSprite	;    then stop drawing

	mov r10,r8		; rdi += (columns * bytesPerPixel)		
	imul r10,bytesPerPixel
	sub r10,bytesPerPixel*64
	add rdi,r10
	
	jmp _blitRows

_endDrawSprite:
	pop rdi
	pop rsi
	ret


;; ==========================
;; MatrixBlitSprite routine
;; rsi = ptr to source image (for now, assumes 64x64, will update later)
;; eax = horizon

;; Pseudocode, because this function's gonna be a doozy:
;; for y = 0..cyres
;;   for x = 0..cxres
;;     pz = y + horizon
;;     xi = ( (tca * (x - tx0)) + (tcb * (y - ty0)) + tx0) / pz
;;     yi = ( (tcc * (x - tx0)) + (tcd * (y - ty0)) + ty0) / pz
;;     xi = mod(xi, 64)
;;     yi = mod(yi, 64)
;;
;;     Copy pixel at SrcImage[(yi*64)+xi] to [RDI+((y*cxres)+x)]

MatrixBlitSprite:
	mov r10,0		; canvas pixel y = 0
_loopY:
	mov r11,0		; canvas pixel x = 0
	; TODO: to add horizon-setting code, put
	; stuff here later that increments eax
	; by whatever amount
_loopX:
	; Goal:  xi = ( (tca * (x - tx0)) + (tcb * (y - ty0)) + tx0) / pz
	; TODO: (still have not yet implemented the '/ pz' part, will do another day)
;; calculate x - tx0
	cvtsi2ss xmm0,r11d 	; int -> float, xmm0[0] = x

	;; TODO: weird that if I were to set [tx0] to [frame],
	;; (which is incremented every frame in main.cpp),
	;; it seems to make no difference here: nothing scrolls
	
	movss xmm1,[tx0]	; xmm1[0] = tx0
	movss xmm5,xmm1		; xmm5 also = tx0 for later
	subss xmm0,xmm1		; xmm0[0] -= tx0

	;; calculate y - ty0
	cvtsi2ss xmm1,r10d 	; int -> float, xmm1[0] = y
	movss xmm2,[ty0]	; xmm2[0] = ty0
	movss xmm6,xmm2		; xmm6 also = ty0 for later
	subss xmm1,xmm2		; xmm1[0] -= ty0

;; xmm0[0] is now = x - tx0
;; xmm1[0] is now = y - ty0
;; now want to set xmm1 to:  [ x-tx0, y-ty0, x-tx0, y-ty0 ]
	; (Using XMM7 as "scratch" register)
	shufps xmm7,xmm0,0
	shufps xmm7,xmm1,1
	shufps xmm7,xmm0,2
	shufps xmm7,xmm1,3
	movaps xmm1,xmm7
	; (XMM7 may be used again)
	
;; set xmm2 := [ tma,   tmb,   tmc,   tmd ]
	movaps xmm2,[tma]
;; calc xmm1 := [ a*(x-x0), b*(y-y0), c*(x-x0), d*(y-y0) ]
	mulps xmm1,xmm2
	
;; now want to calculate xi,yi as:
;;   xi = xmm1[0] + xmm1[1] + tx0
;;   yi = xmm1[2] + xmm1[3] + ty0
;; probably best to strive for this:
;;   xmm2 := [ xmm1[0] , xmm1[1], tx0, 0.0 ]
;;   xmm3 := [ xmm1[2] , xmm1[3], ty0, 0.0 ]
;; which is:
;;   xmm2 := [ xmm1[0] , xmm1[1], xmm5[0], 0.0 ]
;;   xmm3 := [ xmm1[2] , xmm1[3], xmm6[0], 0.0 ]

	;; copy xmm1 to xmm2
	movaps xmm2,xmm1
	movlhps xmm2,xmm5       ; xmm2[2,3] = xmm5[0,1]
	movhlps xmm3,xmm1    	; xmm3[0,1] = xmm1[2,3]
	movlhps xmm3,xmm6       ; xmm3[2,3] = xmm6[0,1]

;; And then use HADDPS on each using dummy zero'd-out xmm5 as second operand
;; Doing HADDPS twice to each register XMM2 and XMM3, results in each of them
;; containing a scalar at [0] which is the sum of all parts that were originally
;; there.
	pxor xmm5,xmm5
	haddps xmm2,xmm5
	haddps xmm2,xmm5
	haddps xmm3,xmm5
	haddps xmm3,xmm5
	
;; xmm2 now equals the post-calculated value of xi
;; xmm3 now equals the post-calculated value of yi
	
;; now we want to convert them to integers and modulo each by 64
	cvtss2si r12,xmm2	; r12 = xi
	cvtss2si r13,xmm3	; r13 = xi

	;; modulo 'em
	mov rax,r12
	and rax,(64-1)
	mov r12,rax		; xi now = xi % 64
	mov rax,r13
	and rax,(64-1)
	mov r13,rax 		; yi now = yi % 64

	;; read pixel from source image
	mov rbx,r13		; rbx = yi
	shl rbx,8               ; rbx *= 64 (pixels) * 4 (bytes)
	mov rax,r12		; rax = xi
	shl rax,2		; rax *= 4 (bytes)
	add rbx,rax		; rbx = (yi * 64 pixels * 4 bytes) + (xi * 4 bytes)
	mov r14d,dword[rsi+rbx]	; r14d = pixel at image[xi, yi]

;; plop source image pixel onto screen
	mov rbx,r10		; rbx = scrY
	mov edx,[cxres]		
	imul rbx,rdx		; rbx = scrY * cxres
	shl rbx,2		; rbx *= 4 (bytes)
	mov rax,r11		; rax = scrX
	shl rax,2		; rax *= 4 (bytes)
	add rbx,rax
	mov rax,r14		; eax = pixel from above
	mov [rdi+rbx],eax
	
	inc r11
	cmp r11,r8		; x vs x-res
	jl _loopX
	inc r10
	cmp r10,r9		; y vs y-res
	jl _loopY

	ret
	
