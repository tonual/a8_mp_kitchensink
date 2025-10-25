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

{$r mptb.rc}
//md1 player resource

Procedure RelocateMD1(modul: pointer; new_addr: word);
Var 
  old_add: word;
  oalength: word;
  ofs: word = 6;
  tmp: word;
  hlp: word;
  i: byte;  
  ph: pointer;
  nadp: pointer;

Begin  
  If PWord(modul)^ <> $FFFF Then
    Begin
      writeln('Bad file format');
      Halt;
    End;

  old_add := PWord(pointer(word(modul) + 2))^;
  oalength := PWord(pointer(word(modul) + 4))^ - old_add + 1;  
  // instruments  
  For i := 0 To 31 Do
    Begin
      tmp := PWord(pointer(word(modul) + ofs + i*2))^;
      If tmp <> 0 Then
        Begin
          hlp := tmp - old_add + new_addr;
          PWord(pointer(word(modul) + ofs + i*2))^ := hlp;          
        End;
    End;  
  // patterns  
  For i := 0 To 63 Do
    Begin
      tmp := PWord(pointer(word(modul) + ofs + $40 + i*2))^;
      If tmp <> 0 Then
        Begin
          hlp := tmp - old_add + new_addr;
          PWord(pointer(word(modul) + ofs + $40 + i*2))^ := hlp;          
        End;
    End;  
  // 4 tracks  
  For i := 0 To 3 Do
    Begin
      tmp := PByte(pointer(word(modul) + ofs + $1C0 + i))^ + 
        PByte(pointer(word(modul) + ofs + $1C4 + i))^ shl 8;
      If tmp <> 0 Then
        Begin
          hlp := tmp - old_add + new_addr;
          PByte(pointer(word(modul) + ofs + $1C0 + i))^ := Lo(hlp);
          PByte(pointer(word(modul) + ofs + $1C4 + i))^ := Hi(hlp);          
        End;
    End;  
  
  // Shift the data down over the header to remove 
  //the 6-byte Atari DOS header
  ph := pointer(word(modul) + ofs);  
  Move(ph^, modul^, oalength);  
  // Move the relocated modul (without header) to the target address  
  nadp := pointer(new_addr);
  Move(modul^, nadp^, oalength);  

End;


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

  While song_index < 3 Do
    Begin
      writeln('Loading song ', module_filenames[song_index]);
      LoadFileToAddr(module_filenames[song_index], module_addr);
      RelocateMD1(pointer(module_addr), module_addr);    
      LoadFileToAddr(sample_filenames[song_index], sample_addr);
      
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