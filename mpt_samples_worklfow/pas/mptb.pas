
Uses crt, sysutils, md1;

Const 
  ver = '0.106';
  // md1_player = $520A;
  // module_addr = $6000;
  // sample_addr = $7000;
  md1_player = $6000;
  module_addr = $7000;
  sample_addr = $8000;

  module_filenames : array [0..7] Of string = (
                                               'D:FILTERED_CHORD.MD1',
                                               'D:TECHNO.MD1',
                                               'D:INSANITY.MD1',
                                               'D:WTC.MD1',
                                               'D:TRANSIL.MD1',
                                               'D:TNL4.MD1',
                                               'D:BLUE3.MD1',
                                               'D:BLUEZONE.MD1'
                                              );
  sample_filenames : array [0..7] Of string = (
                                               'D:FILTERED_CHORD.D15',
                                               'D:TECHNO.D15',
                                               'D:INSANITY.D15',
                                               'D:WTC.D8',
                                               'D:TRANSIL.D15',
                                               'D:TNL4.D15',
                                               'D:BLUE3.D15',
                                               'D:BLUE3.D15'
                                              );

Var 
  msx: TMD1;
  ch: char;
  song_index: byte = 1;

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
  buffer   : array[0..8191] Of byte;
  //are there bigger modules? (how to recycle memory from this buffer btw)  

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

  For i := 0 To 31 Do
    //instruments
    Begin
      tmp := buffer[ofs + i*2] + buffer[ofs + i*2 + 1] shl 8;
      If tmp <> 0 Then
        Begin
          tmp := tmp - old_addr + new_address;
          buffer[ofs + i*2]     := Lo(tmp);
          buffer[ofs + i*2 + 1] := Hi(tmp);
        End;
    End;

  For i := 0 To 63 Do
    //patterns
    Begin
      tmp := buffer[ofs + $40 + i*2] + buffer[ofs + $40 + i*2 + 1] shl 8;
      If tmp <> 0 Then
        Begin
          tmp := tmp - old_addr + new_address;
          buffer[ofs + $40 + i*2]     := Lo(tmp);
          buffer[ofs + $40 + i*2 + 1] := Hi(tmp);
        End;
    End;

  For i := 0 To 3 Do
    //tracks
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


Procedure PrintSongs;

Var 
  i : byte;

Begin
  For i := 0 To High(module_filenames) Do
    Begin
      writeln(i, ' | ',module_filenames[i])
    End;
  writeln('---------------');
End;


Procedure vbl;
interrupt;
Begin
  msx.play;
  asm { jmp xitvbv };
End;


Begin
  writeln('ver. ',ver);

  SetIntVec(iVBL, @vbl);
  PrintSongs();

  While song_index <>8 Do
    Begin
      
      writeln('Take number (9 to quit):');
      ch := readkey;
      song_index := Ord(ch) - 48;
            
      writeln('Loading: ', song_index, module_filenames[song_index]);
      LoadAndRelocateMD1(module_filenames[song_index], module_addr);      
      LoadFileToAddr(sample_filenames[song_index], sample_addr);
      
      msx.player := pointer(md1_player);
      msx.modul := pointer(module_addr);
      msx.sample := pointer(sample_addr);
      msx.init;

      Repeat
        msx.digi(true);
      Until keypressed;

      msx.stop;
      writeln('stopped , press any key');
    End;
  Repeat
  Until keypressed;
End.
