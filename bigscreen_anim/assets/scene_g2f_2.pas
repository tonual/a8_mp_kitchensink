// Simplified PASCAL file writing for G2F:DLI mode
// -----------------------------------------------
// * GTIA register changes only every 8 lines
// * no information about PMG graphics

uses crt,atari;

{$r scene_g2f_2.rc}

const
	scr = $4A00;

	fnt0 = $5400;
	fnt1 = $5800;
	fnt2 = $5C00;
	fnt3 = $6000;
	fnt4 = $6400;
	fnt5 = $6800;
	fnt6 = $6C00;
	fnt7 = $7000;
	fnt8 = $7400;
	fnt9 = $7800;
	fnt10 = $7C00;
	fnt11 = $8000;
	fnt12 = $8400;
	fnt13 = $8800;
	fnt14 = $8C00;
	fnt15 = $9000;
	fnt16 = $9400;
	fnt17 = $9800;
	fnt18 = $9C00;
	fnt19 = $A000;
	fnt20 = $A400;
	fnt21 = $A800;
	fnt22 = $AC00;
	fnt23 = $B000;
	fnt24 = $B400;
	fnt25 = $B800;

	dlist: array [0..34] of byte = (
		$C4,lo(scr),hi(scr),
		$84,$84,$84,$84,$84,$84,$84,$84,
		$84,$84,$84,$84,$84,$84,$84,$84,
		$84,$84,$84,$84,$84,$84,$84,$84,
		$84,$84,$84,$84,$04,
		$41,lo(word(@dlist)),hi(word(@dlist))
	);

	fntTable: array [0..29] of byte = (
		hi(fnt0),hi(fnt1),hi(fnt2),hi(fnt3),hi(fnt4),hi(fnt5),hi(fnt6),hi(fnt7),
		hi(fnt8),hi(fnt9),hi(fnt10),hi(fnt11),hi(fnt12),hi(fnt13),hi(fnt14),hi(fnt15),
		hi(fnt16),hi(fnt17),hi(fnt18),hi(fnt19),hi(fnt20),hi(fnt21),hi(fnt22),hi(fnt23),
		hi(fnt24),hi(fnt24),hi(fnt24),hi(fnt24),hi(fnt25),hi(fnt25)
	);

	c0Table: array [0..29] of byte = (
		$08,$0E,$0E,$0E,$92,$92,$92,$92,
		$92,$92,$92,$92,$92,$92,$92,$92,
		$92,$92,$92,$92,$92,$92,$92,$92,
		$08,$08,$08,$08,$08,$08
	);

	c1Table: array [0..29] of byte = (
		$08,$0E,$0E,$0E,$0E,$0E,$0E,$08,
		$08,$08,$0E,$0E,$0E,$08,$0E,$08,
		$08,$0E,$0E,$0E,$08,$08,$08,$08,
		$08,$08,$08,$08,$08,$08
	);

	c2Table: array [0..29] of byte = (
		$D6,$D6,$D6,$D6,$D6,$D6,$D6,$D6,
		$D6,$D6,$D6,$D6,$D6,$D6,$D6,$D6,
		$D6,$D6,$D6,$D6,$D6,$D6,$D6,$D6,
		$D6,$D6,$D6,$D6,$D6,$D6
	);

	c3Table: array [0..29] of byte = (
		$D6,$D6,$D6,$D6,$D6,$D6,$D6,$D6,
		$D6,$D6,$D6,$D6,$D6,$D6,$D6,$D6,
		$D6,$D6,$D6,$D6,$D6,$D6,$D6,$D6,
		$D6,$D6,$D6,$D6,$D6,$D6
	);

var
	old_dli, old_vbl: pointer;


procedure vbl; assembler; interrupt;
asm
{
	mva #1 dli.cnt

	mva adr.fntTable chbase
	mva adr.fntTable+1 dli.chbs

	mva adr.c0Table color0
	mva adr.c0Table+1 dli.col0
	mva adr.c1Table color1
	mva adr.c1Table+1 dli.col1
	mva adr.c2Table color2
	mva adr.c2Table+1 dli.col2
	mva adr.c3Table color3
	mva adr.c3Table+1 dli.col3

	mva #$94 colbak

	jmp xitvbv
};
end;


procedure dli; assembler; interrupt;
asm
{
	sta rA
	stx rX
	sty rY

	lda #0
chbs	equ *-1

	ldx #0
col0	equ *-1

	ldy #0
col1	equ *-1

	;sta wsync

	sta chbase
	lda #0
col2	equ *-1
	stx color0
	ldx #0
col3	equ *-1
	sty color1
	sta color2
	stx color3

	inc cnt

	ldx #0
cnt	equ *-1

	lda adr.fntTable,x
	sta chbs

	lda adr.c0Table,x
	sta col0

	lda adr.c1Table,x
	sta col1

	lda adr.c2Table,x
	sta col2

	lda adr.c3Table,x
	sta col3

	lda #0
rA	equ *-1
	ldx #0
rX	equ *-1
	ldy #0
rY	equ *-1
};
	end;


begin

 GetIntVec(iVBL, old_vbl);
 GetIntVec(iDLI, old_dli);

 sdmctl := byte(narrow or enable or missiles or players or oneline);
 sdlstl := word(@dlist);	// ($230) = @dlist, New DLIST Program

 SetIntVec(iVBL, @vbl);
 SetIntVec(iDLI, @dli);

 nmien := $c0;			// $D40E = $C0, Enable DLI

 repeat
 until keypressed;

 SetIntVec(iVBL, old_vbl);
 SetIntVec(iDLI, old_dli);

end.
