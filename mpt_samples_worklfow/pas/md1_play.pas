uses crt, md1;

const
	md1_player = $3000;
	md1_modul = $5000;
	md1_sample = $6000;	// !!! low byte = $00 !!!

var
	msx: TMD1;
	ch: char;	

{$r md1_play.rc}

procedure vbl; interrupt;
 
 begin
 msx.play;

 asm 
	jmp xitvbv
 end;
 end;

begin
	SetIntVec(iVBL, @vbl);

	while true do begin

	msx.player:=pointer(md1_player);
	msx.modul:=pointer(md1_modul);
	msx.sample:=pointer(md1_sample);

	msx.init;

	writeln('Gramy na samplach, 2025');

	repeat		
		msx.digi(false);
		
	until keypressed;
	ch:=readkey();

	msx.stop;

	end;

 repeat until keypressed;

end.
