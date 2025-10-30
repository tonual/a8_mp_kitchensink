Uses crt, sysutils, md1;

Const 
  md1_player = $3000;
  module_addr = $5000;
  sample_addr = $6000;

  module_filenames : array [0..2] Of string = (
    'D:TNL4.MD1', 
    'D:BLUE3.MD1', 
    'D:TRANSIL.MD1'
    );
  sample_filenames : array [0..2] Of string = (
    'D:TNL4.D15', 
    'D:BLUE3.D15', 
    'D:TRANSIL.D15');

Var 
  msx: TMD1;
  ch: char;
  song_index: byte = 0;

{$r mptb.rc}

//DOS II+/D Version 6.4 (c) '87 by S.D.
Procedure LoadAndRelocateMD1(Const filename: String; new_address: word);

Const 
  DOS_HDR = 6;

Var 
  f        : file;
  read_cnt : word;
  old_addr : word;
  data_len : word;
  ofs      : word;
  i        : byte;
  tmp      : word;
  ptn      : pointer;
  buffer   : array[0..8191] Of byte; //are there bigger modules? (how to recycle memory from this buffer btw)  

Begin
  Assign(f, filename);
  Reset(f, 1);
  read_cnt := 0;
  BlockRead(f, buffer, SizeOf(buffer), read_cnt);
  Close(f);

  //sanity checks
  If (read_cnt < DOS_HDR + 2) Or
     (buffer[0] <> $FF) Or (buffer[1] <> $FF) Then
    Begin
      WriteLn('ERROR: ', filename, ' - not a valid DOS binary!');
      Halt;
    End;

  //Extract old address and compute real module length
  old_addr := buffer[2] + buffer[3] shl 8;
  data_len := (buffer[4] + buffer[5] shl 8) - old_addr + 1;
  ofs      := DOS_HDR;

  If read_cnt <> DOS_HDR + data_len Then
    Begin
      WriteLn('ERROR: file size mismatch');
      Halt;
    End;
  //Patch the DOS header for the new address
  buffer[2] := Lo(new_address);
  buffer[3] := Hi(new_address);
  buffer[4] := Lo(new_address + data_len - 1);
  buffer[5] := Hi(new_address + data_len - 1);

  For i := 0 To 31 Do //instruments
    Begin
      tmp := buffer[ofs + i*2] + buffer[ofs + i*2 + 1] shl 8;
      If tmp <> 0 Then
        Begin
          tmp := tmp - old_addr + new_address;
          buffer[ofs + i*2]     := Lo(tmp);
          buffer[ofs + i*2 + 1] := Hi(tmp);
        End;
    End;

  For i := 0 To 63 Do //patterns
    Begin
      tmp := buffer[ofs + $40 + i*2] + buffer[ofs + $40 + i*2 + 1] shl 8;
      If tmp <> 0 Then
        Begin
          tmp := tmp - old_addr + new_address;
          buffer[ofs + $40 + i*2]     := Lo(tmp);
          buffer[ofs + $40 + i*2 + 1] := Hi(tmp);
        End;
    End;

  For i := 0 To 3 Do //tracks
    Begin
      tmp := buffer[ofs + $1C0 + i] + buffer[ofs + $1C4 + i] shl 8;
      If tmp <> 0 Then
        Begin
          tmp := tmp - old_addr + new_address;
          buffer[ofs + $1C0 + i] := Lo(tmp);
          buffer[ofs + $1C4 + i] := Hi(tmp);
        End;
    End;

  //Copy the relocated module to its final location
  ptn := Pointer(new_address);
  Move(buffer[ofs], ptn, data_len);
End;


//DOS II+/D Version 6.4 (c) '87 by S.D.
Procedure LoadFileToAddr(Const filename: String; addr: word);
Var 
  f: file;
  p: pointer;
  buf: array [0..255] Of byte;
  bytesRead: word;
  totalRead: word;

Begin
  totalRead := 0;  
  Assign(f, filename);
  Reset(f, 1);
 
  Repeat
    p := pointer(addr);
    BlockRead(f, buf, SizeOf(buf), bytesRead);
    Move(buf, p^, bytesRead);
    addr := addr + bytesRead;    
  Until bytesRead = 0;
  Close(f);  
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
      writeln('Loading: ', module_filenames[song_index]);
      LoadAndRelocateMD1(module_filenames[song_index], module_addr);
      
      writeln('Loading: ', sample_filenames[song_index]);
      LoadFileToAddr(sample_filenames[song_index], sample_addr);
      
      writeln('pres any key to play');
      ch := readkey;

      msx.player := pointer(md1_player);
      msx.modul := pointer(module_addr);
      msx.sample := pointer(sample_addr);
      msx.init;

      Repeat
        msx.digi(true);
      Until keypressed;

      writeln('press any key for next song');
      ch := readkey;
      msx.stop;
      Inc(song_index);
    End;

  Repeat
  Until keypressed;
End.