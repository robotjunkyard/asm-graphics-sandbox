extern timer
global asmRenderTo

section .text
asmRenderTo:
;; rdi is pointer to PIXELS
;; rsi is PIXELS WIDTH
;; rdx is PIXELS HEIGHT
;; rcx is BYTES PER PIXEL

	mov r8,rsi		; width   (# columns)
	mov r9,rdx		; height  (# rows)
	mov r10,rcx		; bytes per pixel

	mov ax,[timer]
	call FillCanvas
	ret
	
FillCanvas:			; takes parameter AX, a 16-bit color value
	xor rcx,rcx  		; i
	mov rdx,r8
	imul rdx,r9		; rows * columns (= total pixels)
_fillLoop:
	mov [rdi+rcx*2],ax
	inc rcx
	cmp rcx,rdx
	jne _fillLoop
	ret
	
