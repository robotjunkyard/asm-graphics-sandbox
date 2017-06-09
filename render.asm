extern timer
extern frame
;; extern bytesPerPixel
global asmRenderTo

section .data
clearColor: db 127,64,0,0	; Blue, Green, Red, (Alpha seems ignored)
;; memo: important that image in GIMP should have an Alpha channel before exporting,
;; or else this image will cause problems!
;;
;; Iif no Alpha Channel, do  [ Layers -> Transparency -> Add Alpha Channel ]
;; And then Export RGBA picture with settings:
;;    RGB Save Type =  Standard (R, G, B)
;;    Indexed Palette Type = B, G, R, X (BMP style)

meow:  incbin "cat.img"
bytesPerPixel: equ 4
	
section .text
asmRenderTo:
;; rdi is pointer to PIXELS
;; rsi is PIXELS WIDTH
;; rdx is PIXELS HEIGHT

	mov r8d,esi		; r8 = width / columns
	mov r9d,edx		; r9 = height / rows

;;mov ax,[timer]
	mov eax,[clearColor]
	call FillCanvas

	mov rsi,meow		; ptr to 64x64x32bit cat graphic
	mov rax,16
	mov rbx,8
	call DrawSprite
	ret

;; ==========================
;; FillCanvas routine
;; eax = 32-bit color to fill the entire canvas with
FillCanvas:			
	xor rcx,rcx  		; i = 0
	mov rdx,r8
	imul rdx,r9		; rdx = total pixels (rows * columns)
_fillLoop:
	mov [rdi+rcx*4], eax
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
	imul r15,4		; r15 *= 4

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
	imul r10,4
	sub r10,4*64
	add rdi,r10
	
	jmp _blitRows		; else blit next row

_endDrawSprite:
	pop rdi
	pop rsi
	ret
