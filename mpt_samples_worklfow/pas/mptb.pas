Uses crt, sysutils, md1;

Const 
  ver = '0.106';
  // md1_player = $520A;
  // module_addr = $6000;
  // sample_addr = $7000;
  md1_player  = $7000;
  module_addr = $8000;
  sample_addr = $9000;
  
  drive_prefix  = 'D:';
  file_md1_ext  = '.MD1';
  file_d15_ext  = '.D15';
  file_d8_ext   = '.D8 ';

Var 
  msx: TMD1;
  ch: char;
  song_index: byte = 1;
  module_filename : array [0..64] of string[64];
  is15Khz : boolean;

{$r mptb.rc} //md1player resource

Function BaseName(fname: TString): string;

Var 
  i: byte;
Begin
  For i := Length(fname) Downto 1 Do
    If fname[i] = '.' Then
      Begin
        Result := Copy(fname, 1, i - 1);
        Exit;
      End;
  Result := fname;
  // no dot found
End;

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


Procedure GetSongs;

Var 
Info : TSearchRec;
bname: TString;

i: byte;

Begin

  If FindFirst('D:*.MD1', faAnyFile, Info) = 0 Then   // '*.MD1  ?
    Begin
      Repeat
        //writeln(Info.Name,' | ',hexStr(Info.Attr,2));
        
        bname := BaseName(Info.Name);       
        module_filename[i] := bname;
        Inc(i);
      Until FindNext(Info) <> 0;
      FindClose(Info);
    End;
End;

Procedure PrintSongs;

Var 
  i : byte;

Begin
  For i := 0 To High(module_filename) Do
    Begin
      if (module_filename[i] <> '') Then
        Begin
        writeln(i, ' | ',module_filename[i])
      End;
    End;
  writeln('---------------');
End;

procedure LoadSong;
Var
sample_file : string;
song_file : string;
fullname : string;

Begin
      is15Khz := true;
   
      song_file   := Concat(module_filename[song_index], file_md1_ext);
      sample_file := Concat(module_filename[song_index], file_d15_ext);
      
      fullname := Concat(drive_prefix, sample_file);
      if (FileExists(fullname) <> true) Then
        Begin
          writeln('not 15Khz');
          sample_file := Concat(module_filename[song_index], file_d8_ext);
          is15Khz := false;
        End;
      
      fullname := Concat(drive_prefix, song_file);
      writeln('loading ',fullname);
      ch := readkey;
      LoadAndRelocateMD1(fullname, module_addr);
      fullname := Concat(drive_prefix, sample_file);
      writeln('loading ',fullname);
      ch := readkey;
      LoadFileToAddr(fullname, sample_addr);      
      
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
  GetSongs();
  PrintSongs();

  While song_index <> 8 Do
    Begin

      writeln('Take number (9 to quit):');
      ch := readkey;
      song_index := Ord(ch) - 48;
      
      LoadSong();      

      msx.player  := pointer(md1_player);
      msx.modul   := pointer(module_addr);
      msx.sample  := pointer(sample_addr);
      msx.init;

      Repeat
        msx.digi(is15Khz);
      Until keypressed;

      msx.stop;
      writeln('stopped , press any key');
    End;
  Repeat
  Until keypressed;
End.
