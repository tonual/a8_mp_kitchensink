
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

  Program mpt_relocator;

  Uses crt, sysutils;



procedure MPT_Relocator(const filename: TString; new_address: cardinal);
var
  f: file;
  buf: array[0..8191] of byte;  // Reduced size, assuming MPT files are small
  size: word;
  old_add: word;
  len: word;
  ofs: word;
  i: byte;
  tmp: word;
  hlp: word;
  pt1: pointer;
  fullname: string;
begin

  ofs := 6;

  fullname := Concat('D:', filename);
  assign(f, fullname);
  reset(f, 1);
  blockread(f, buf, sizeof(buf), size);

  if (size < 6) or ((buf[0]) <> $FF) or ((buf[1]) <> $FF) then begin
    writeln('Bad file format');
    close(f);
    halt;
  end;

  old_add := buf[2] + buf[3] shl 8;
  len := (buf[4] + buf[5] shl 8) - old_add + 1;
  writeln('sizE: ',size);
  if size < len + 6 then begin
    writeln('File too small');
    close(f);
    halt;
  end;

  if size > len + 6 then begin
    writeln('Warning: File has extra bytes at the end. Ignoring them.');
  end;

  // Relocate instruments (32 pointers at offset 0 in data)
  for i := 0 to 31 do begin
    tmp := buf[ofs + i * 2] + buf[ofs + i * 2 + 1] shl 8;
    if tmp <> 0 then begin
      hlp := tmp - old_add + new_address;
      buf[ofs + i * 2] := hlp and $FF;
      buf[ofs + i * 2 + 1] := hlp shr 8;
    end;
  end;

  // Relocate patterns (64 pointers at offset $40 in data)
  for i := 0 to 63 do begin
    tmp := buf[ofs + $40 + i * 2] + buf[ofs + $40 + i * 2 + 1] shl 8;
    if tmp <> 0 then begin
      hlp := tmp - old_add + new_address;
      buf[ofs + $40 + i * 2] := hlp and $FF;
      buf[ofs + $40 + i * 2 + 1] := hlp shr 8;
    end;
  end;

  // Relocate tracks (4 pointers: LSBs at $1C0, MSBs at $1C4)
  for i := 0 to 3 do begin
    tmp := buf[ofs + $1C0 + i] + buf[ofs + $1C4 + i] shl 8;
    if tmp <> 0 then begin
      hlp := tmp - old_add + new_address;
      buf[ofs + $1C0 + i] := hlp and $FF;
      buf[ofs + $1C4 + i] := hlp shr 8;
    end;
  end;

  // Move the relocated data to the new address (exclude DOS header)
  pt1 := pointer(new_address);
  move(buf[ofs], pt1^, len);

  close(f);
  writeln('relocation of module completed');
end;


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
      writeln('3');
      writeln('Loading song ', module_filenames[song_index]);
      
      MPT_Relocator(module_filenames[song_index], module_addr);
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
