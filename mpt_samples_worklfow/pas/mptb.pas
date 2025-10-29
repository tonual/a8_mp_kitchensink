
Uses crt, sysutils, md1;

Const 
  md1_player = $3000;
  module_addr = $5040;
  sample_addr = $6000;

  module_filenames : array [0..2] Of string = ('D:TNL4.MD1', 'D:BLUE3.MD1', 'D:TRANSIL.MD1');
  sample_filenames : array [0..2] Of string = ('D:TNL4.D15', 'D:BLUE3.D15', 'D:TRANSIL.D15');

Var 
  msx: TMD1;
  ch: char;
  song_index: byte = 0;

procedure LoadAndRelocate(const filename: string; new_address: word);
const
  DOS_HDR = 6;

var
  f        : file;
  read_cnt : word;
  old_addr : word;
  data_len : word;
  ofs      : word;
  i        : byte;
  tmp      : word;
  ptn      : pointer;
  buffer   : array[0..8191] of byte;

begin
  Assign(f, filename);
  Reset(f, 1);
  read_cnt := 0;
  BlockRead(f, buffer, SizeOf(buffer), read_cnt);
  Close(f);

  if (read_cnt < DOS_HDR + 2) or
     (buffer[0] <> $FF) or (buffer[1] <> $FF) then
  begin
    WriteLn('ERROR: ', filename, ' - not a valid DOS binary');
    Halt;
  end;

  old_addr := buffer[2] + buffer[3] shl 8;
  data_len := (buffer[4] + buffer[5] shl 8) - old_addr + 1;
  ofs      := DOS_HDR;

  if read_cnt <> DOS_HDR + data_len then
  begin
    WriteLn('ERROR: file size mismatch');
    Halt;
  end;

  buffer[2] := Lo(new_address);
  buffer[3] := Hi(new_address);
  buffer[4] := Lo(new_address + data_len - 1);
  buffer[5] := Hi(new_address + data_len - 1);

  for i := 0 to 31 do
  begin
    tmp := buffer[ofs + i*2] + buffer[ofs + i*2 + 1] shl 8;
    if tmp <> 0 then
    begin
      tmp := tmp - old_addr + new_address;
      buffer[ofs + i*2]     := Lo(tmp);
      buffer[ofs + i*2 + 1] := Hi(tmp);
    end;
  end;

  for i := 0 to 63 do
  begin
    tmp := buffer[ofs + $40 + i*2] + buffer[ofs + $40 + i*2 + 1] shl 8;
    if tmp <> 0 then
    begin
      tmp := tmp - old_addr + new_address;
      buffer[ofs + $40 + i*2]     := Lo(tmp);
      buffer[ofs + $40 + i*2 + 1] := Hi(tmp);
    end;
  end;

  for i := 0 to 3 do
  begin
    tmp := buffer[ofs + $1C0 + i] + buffer[ofs + $1C4 + i] shl 8;
    if tmp <> 0 then
    begin
      tmp := tmp - old_addr + new_address;
      buffer[ofs + $1C0 + i] := Lo(tmp);
      buffer[ofs + $1C4 + i] := Hi(tmp);
    end;
  end;

  ptn := Pointer(new_address);
  Move(buffer[ofs], ptn, data_len);
end;


//DOS II+/D Version 6.4 (c) '87 by S.D.
Function LoadFileToAddr(Const filename: String; addr: word): Boolean;

Var 
  f: file;
  
  p: pointer;
  buf: array [0..255] Of byte;
  bytesRead: word;
  totalRead: word;

Begin
  totalRead := 0;
  writeln('reading file: ',filename);
  Result := false;
//{$I-}

  Assign(f, filename);
  Reset(f, 1);

  totalRead:=0;
  
  Repeat
    p := pointer(addr);
    BlockRead(f, buf, SizeOf(buf), bytesRead);    
    Move(buf, p^, bytesRead);
    addr := addr + bytesRead;
    totalRead := totalRead + bytesRead;
  Until bytesRead = 0;// SizeOf(buf);
  Close(f);
//{$I+}

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
      LoadAndRelocate(module_filenames[song_index], module_addr);
      writeln('.md1 loaded');
      ch := readkey;
      LoadFileToAddr(sample_filenames[song_index], sample_addr);
      writeln('.d15 loaded');
      ch := readkey;

      msx.player := pointer(md1_player);
      msx.modul := pointer(module_addr);
      msx.sample := pointer(sample_addr);
      msx.init;

      Repeat
        msx.digi(true);
      Until keypressed;

      ch := readkey;
      msx.stop;
      Inc(song_index);
      writeln('Next song ', song_index);
    End;

  Repeat
  Until keypressed;
End.
