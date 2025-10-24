Uses crt, sysutils, md1;

Const 
  md1_player = $3000;
  module_addr = $5000;
  sample_addr = $6000;
  
  module_filenames : array [0..2] Of string = ('TNL.MD1', 'BLUE3.MD1', 'TRANSIL.MD1');
  sample_filenames : array [0..2] Of string = ('TNL.D15', 'BLUE3.D15', 'TRANSIL.D15');

Var 
  msx: TMD1;
  ch: char;
  song_index: byte = 0;

{$r md1_play.rc}

//DOS II+/D Version 6.4 (c) '87 by S.D.
Function LoadFileToAddr(Const filename: String; addr: word): Boolean;

Var 
  f: file;
  fullname: string;
  p: pointer;
  buf: array [0..255] Of byte;
  bytesRead: word;
  totalRead: word;

Begin
  totalRead := 0;
  writeln('reading file: ',filename);
  Result := false;
{$I-}
  fullname := Concat('D:', filename);
  Assign(f, fullname);
  Reset(f, 1);

  Repeat
    p := pointer(addr);
    BlockRead(f, buf, SizeOf(buf), bytesRead);    
    Move(buf, p^, bytesRead);
    addr := addr + bytesRead;
    totalRead := totalRead + bytesRead;
  Until bytesRead < SizeOf(buf);
  Close(f);
{$I+}
  
  writeln('total bytes read: ',totalRead);
  Result := true;
End;

Procedure vbl;
interrupt;
Begin
  msx.play;
  asm { jmp xitvbv };
End;

Begin

  SetIntVec(iVBL, @vbl);

  While song_index < 4 Do
    Begin
      writeln('Loading song ', module_filenames[song_index]);      
      LoadFileToAddr(module_filenames[song_index], module_addr);
      LoadFileToAddr(sample_filenames[song_index], sample_addr);

      writeln('Loaded..press any key');
      ch := readkey;

      msx.player := pointer(md1_player);
      msx.modul := pointer(module_addr);
      msx.sample := pointer(sample_addr);
      msx.init;

      Repeat
        msx.digi(true);
      Until keypressed;

      ch := readkey;
      // Clear key
      msx.stop;

      Inc(song_index);
      writeln('Next song ', song_index);
    End;

  Repeat
  Until keypressed;
End.
