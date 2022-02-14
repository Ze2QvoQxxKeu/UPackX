unit Crypt;

interface

uses
  Windows;
{
function WriteToFile(const Buffer; Size: DWORD; Offset: DWORD): BOOL;
procedure CopyArrayOfByte(inp: array of BYTE; var outp: array of BYTE);
procedure RandomArrayOfByte(var outp: array of BYTE;
 StartPos, EndPos: DWORD);
procedure PushDecryptionIntoBuffer(CryptBegin, CryptEnd,
 CryptVal, JmpOEP: DWORD; var Buffer);
function GetSectionSize(const Buffer; Size: DWORD): DWORD;
procedure CryptData(CryptBegin, CryptEnd, CryptVal: DWORD; var Buffer);
function GetCryptDataEnd(CryptBegin: DWORD; const Buffer; Size: DWORD): DWORD;
procedure RandomBuffer(var Buffer; Size: DWORD);}
type
  TResult = (rOK,rNotUPX,rInvalidPE,rUnknown,rCantOpen,rCantWrite);
  
function CryptFile(lpInpFile, lpOutpFile: PChar): TResult;
 
implementation

var
  OutpFileName: PChar;

function WriteToFile(const Buffer; Size: DWORD; Offset: DWORD): BOOL;
var
  hFile, n : DWORD;
begin
  Result:= False;
  hFile := CreateFileA(OutpFileName, GENERIC_WRITE,
   0, nil, OPEN_ALWAYS, 0, 0);
  if hFile<>INVALID_HANDLE_VALUE then
  try
    n := 0;
    if Offset = 0 then
      SetFilePointer(hFile, 0, nil, FILE_END)
    else
      SetFilePointer(hFile, Offset, nil, FILE_BEGIN);
    if WriteFile(hFile, Buffer, Size, n, nil) then
      Result := (n = Size);
  finally
    CloseHandle(hFile);
  end;
end;

procedure CopyArrayOfByte(inp: array of BYTE; var outp: array of BYTE);
begin asm
  pushad
  mov     ecx, dword ptr [ebp+8h] //SizeOf(outp)
  mov     eax, inp
  mov     ebx, outp
  dec     eax
  dec     ebx
  add     ecx, outp
 @repeat:
  inc     ebx
  inc     eax
  mov     dl, [eax]
  mov     [ebx], dl
  cmp     ebx, ecx
  jl      @repeat
  popad
end; end;

procedure RandomArrayOfByte(var outp: array of BYTE;
 StartPos, EndPos: DWORD);
begin asm
  pushad
  mov     ecx, EndPos
  add     ecx, outp
  dec     ecx
  mov     ebx, outp
  add     ebx, StartPos
  dec     ebx
 @repeat:
  inc     ebx
  mov     eax, 100h
  call    System.@RandInt
  mov     [ebx], al
  cmp     ebx, ecx
  jl      @repeat
  popad
end; end;

procedure RandomBuffer(var Buffer; Size: DWORD);
begin asm
  pushad
  mov     ebx, Buffer
  mov     ecx, ebx
  add     ecx, Size
  dec     ecx
  dec     ebx
 @repeat:
  inc     ebx
  mov     eax, 100h
  call    System.@RandInt
  mov     [ebx], al
  cmp     ebx, ecx
  jl      @repeat
  popad
end; end;

procedure PushDecryptionIntoBuffer(CryptBegin, CryptEnd,
 CryptVal, JmpOEP: DWORD; var Buffer);
begin asm
  pushad
  mov     eax, Buffer
  mov     bl, 0B8h
  mov     [eax], bl
  inc     eax
  mov     ebx, CryptBegin
  mov     [eax], ebx
  add     eax, 4
  mov     ebx, 0F381188Bh
  mov     [eax], ebx
  add     eax, 4
  mov     ebx, CryptVal
  mov     [eax], ebx
  add     eax, 4
  mov     ebx, 0C0831889h
  mov     [eax], ebx
  add     eax, 4
  mov     bx, 3D04h
  mov     [eax], bx
  add     eax, 2
  mov     ebx, CryptEnd
  mov     [eax], ebx
  add     eax, 4
  mov     bx, 0EC76h
  mov     [eax], bx
  add     eax, 2
  mov     bl, 0E9h
  mov     [eax], bl
  inc     eax
  mov     ebx, JmpOEP
  mov     [eax], ebx
  add     eax, 4
  xor     bx, bx
  mov     [eax], bx
  add     eax, 2
  mov     ebx, 50746547h
  mov     [eax], ebx
  add     eax, 4
  mov     ebx, 41636F72h
  mov     [eax], ebx
  add     eax, 4
  mov     ebx, 65726464h
  mov     [eax], ebx
  add     eax, 4
  mov     ebx, 00007373h
  mov     [eax], ebx
  popad
end; end;

function GetSectionSize(const Buffer; Size: DWORD): DWORD;
begin asm
  pushad
  mov     eax, Buffer
  add     eax, Size
 @repeat:
  sub     eax, 4
  mov     ebx, [eax]
  test    ebx, ebx
  jz      @repeat
  add     eax, 8
  sub     eax, Buffer
  mov     Result, eax
  popad
end; end;

procedure CryptData(CryptBegin, CryptEnd, CryptVal: DWORD; var Buffer);
begin asm
  pushad
  mov     eax, Buffer
  mov     ecx, CryptEnd
  add     ecx, eax
  mov     CryptEnd, ecx
  add     eax, CryptBegin
 @repeat:
  mov     ebx, [eax]
  xor     ebx, CryptVal
  mov     [eax], ebx
  add     eax, 4
  cmp     eax, CryptEnd
  jna     @repeat
  popad
end; end;

function GetCryptDataEnd(CryptBegin: DWORD; const Buffer; Size: DWORD): DWORD;
begin asm
  pushad
  mov     eax, Buffer
  push    eax
  add     eax, CryptBegin
  mov     edx, eax
  pop     eax
  add     eax, Size
  mov     ebx, eax
  xor     eax, eax
  mov     ecx, eax
 @repeat:
  mov     eax, edx
  mov     al, byte ptr[eax]
  test    al, al
  jnz     @NotNull
  inc     ecx
  jmp     @Next
 @NotNull:
  xor     eax, eax
  mov     ecx, eax
 @Next:
  inc     edx
  cmp     ecx, 4
  jl      @repeat
  je      @ToExit
  cmp     edx, ebx
  jl      @repeat
 @ToExit:
  mov     eax, edx
  sub     eax, Buffer
  xor     edx, edx
  mov     ebx, 4
  div     ebx
  xor     edx, edx
  mov     ebx, 4
  mul     ebx
  add     eax, 4
  mov     Result, eax
  popad
end; end;

function CryptFile(lpInpFile,lpOutpFile: PChar): TResult;
label
  _Final;
const
  MZ_HEADER = 'MZKERNEL32.DLL'#0#0;
  SECTION0_NAME: array [0..7] of BYTE =
  ($50, $53, $FF, $D5, $AB, $EB, $E7, $C3);
  SECTION1_NAME: array [0..7] of BYTE =
  ($00, $10, $40, $00, $00, $00, $00, $00);
  SECTION1_OFFSET = $00000200;
var
  hFile       : DWORD;
  i, n        : DWORD;
  dwEP        : DWORD;
  dwIB        : DWORD;
  dwCryptBegin: DWORD;
  dwCryptEnd  : DWORD;
  dwSect1RVA  : DWORD;
  dwTmp       : DWORD;
  dwCryptVal  : DWORD;
  Sect1Size   : DWORD;
  Sect2Size   : DWORD;
  Sect1Offset : DWORD;
  Sect2Offset : DWORD;
  Buffer      : Pointer;
  INTH        : IMAGE_NT_HEADERS;
  IDH         : IMAGE_DOS_HEADER;
  ISH         : IMAGE_SECTION_HEADER;  
begin
  Randomize;
  Result := rUnknown;
  GetMem(OutpFileName, LStrLen(lpOutpFile)+1);
  LStrCpy(OutpFileName,lpOutpFile);
  DeleteFile(OutpFileName);
  hFile:=CreateFileA(PChar(lpInpFile), GENERIC_READ or GENERIC_WRITE,
   FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  if hFile<>INVALID_HANDLE_VALUE then
  begin
  try
    n := 0;
    SetFilePointer(hFile, 0, nil, FILE_BEGIN);
    ReadFile(hFile, IDH, SizeOf(IDH), n, nil);
    SetFilePointer(hFile, IDH._lfanew, nil, 0);
    ReadFile(hFile, INTH, SizeOf(INTH), n, nil);
    if (LoWord(IDH.e_magic) <> $5A4D {MZ})
    or (LoWord(INTH.Signature)<>$4550 {PE}) then
    begin
      Result := rInvalidPE;
      goto _Final;
    end;
    if INTH.FileHeader.NumberOfSections = 3 then
    begin
      dwTmp := IDH._lfanew+SizeOf(INTH);
      ReadFile(hFile, ISH, SizeOf(ISH), n, nil);
      i := ISH.PointerToRawData;
      if (n<>SizeOf(ISH)) then
      begin
        Result := rInvalidPE;
        goto _Final;
      end;
      if (ISH.SizeOfRawData<>0) then
      begin
        Result := rNotUPX;
        goto _Final;
      end;
      ReadFile(hFile, ISH, SizeOf(ISH), n, nil);
      if(n<>SizeOf(ISH))then
      begin
        Result := rInvalidPE;
        goto _Final;
      end;
      if (ISH.PointerToRawData<>i)then
      begin
        Result := rNotUPX;
        goto _Final;
      end;
      if ((ISH.VirtualAddress+ISH.SizeOfRawData)
       <INTH.OptionalHeader.AddressOfEntryPoint) then
      begin
        Result := rNotUPX;
        goto _Final;
      end;
      SetFilePointer(hFile, dwTmp, nil, 0);
    end else begin
      Result := rNotUPX;
      goto _Final;
    end;
    if not WriteToFile(MZ_HEADER, Length(MZ_HEADER), 0) then
    begin
      Result := rCantWrite;
      goto _Final;
    end;
    dwEP:=INTH.OptionalHeader.AddressOfEntryPoint;
    dwIB:=INTH.OptionalHeader.ImageBase;
    INTH.FileHeader.TimeDateStamp:= $0011B0BE+(dwIB shl 8);
    INTH.FileHeader.PointerToSymbolTable:= $FF50AD00+(dwIB shr 24);
    INTH.FileHeader.NumberOfSymbols:= $7CEB3476;
    INTH.FileHeader.SizeOfOptionalHeader:= $0148;
    INTH.OptionalHeader.MajorLinkerVersion:= $4C;
    INTH.OptionalHeader.MinorLinkerVersion:= $6F;
    INTH.OptionalHeader.SizeOfCode:= $694C6461;
    INTH.OptionalHeader.SizeOfInitializedData:= $72617262;
    INTH.OptionalHeader.SizeOfUninitializedData:= $00004179;
    INTH.OptionalHeader.AddressOfEntryPoint:= $00001018;
    INTH.OptionalHeader.BaseOfCode:= $00000010;
    INTH.OptionalHeader.MinorImageVersion:= $0039;
    INTH.OptionalHeader.FileAlignment:= $0200;
    if not WriteToFile(INTH, SizeOf(INTH), 0) then
    begin
      Result := rCantWrite;
      goto _Final;
    end;

    GetMem(Buffer, $0C);
    RandomBuffer(Buffer^, $0C);
    if not WriteToFile(Buffer^, $0C, $FC) then
    begin
      FreeMem(Buffer, $0C);
      Result := rCantWrite;
      goto _Final;
    end;
    FreeMem(Buffer, $0C);

    GetMem(Buffer, $68);
    RandomBuffer(Buffer^, $68);
    if not WriteToFile(Buffer^, $68, 0) then
    begin
      FreeMem(Buffer, $68);
      Result := rCantWrite;
      goto _Final;
    end;
    FreeMem(Buffer, $68);

    for i := 0 to Pred(INTH.FileHeader.NumberOfSections) do
    begin
      ReadFile(hFile, ISH, SizeOf(ISH), n, nil);
      if(n<>SizeOf(ISH))then
      begin
        Result := rInvalidPE;
        goto _Final;
      end;
      ISH.Characteristics:=$E0000060;
      case i of
        0: begin
          CopyArrayOfByte(SECTION0_NAME,ISH.Name);
          ISH.PointerToRawData:=$00000010;
          ISH.SizeOfRawData:=$000001F0;
        end;
        1: begin
          CopyArrayOfByte(SECTION1_NAME,ISH.Name);
          RandomArrayOfByte(ISH.Name,4,7);
          Sect1Size:=ISH.SizeOfRawData;
          Sect1Offset:=ISH.PointerToRawData;
          dwSect1RVA:=ISH.VirtualAddress;
          dwCryptBegin:=dwEP-dwSect1RVA;
          ISH.PointerToRawData:=SECTION1_OFFSET;
        end;
        2: begin
          RandomArrayOfByte(ISH.Name,0,3);
          RandomArrayOfByte(ISH.Name,4,7);
          Sect2Size:=ISH.SizeOfRawData;
          Sect2Offset:=ISH.PointerToRawData;
          if ((Sect1Size div $0200)*$0200)<Sect1Size then
            Sect1Size:=(((Sect1Size div $0200)+1)*$0200);
          ISH.PointerToRawData:=SECTION1_OFFSET+Sect1Size;
        end;
      end;
      if not WriteToFile(ISH, SizeOf(ISH), 0) then
      begin
        Result := rCantWrite;
        goto _Final;
      end;
    end;
    GetMem(Buffer, $18);
    ZeroMemory(Buffer, $18);
    if not WriteToFile(Buffer^, $18, 0) then
    begin
      FreeMem(Buffer, $18);
      Result := rCantWrite;
      goto _Final;
    end;
    FreeMem(Buffer, $18);

    dwCryptVal:=Random(MaxInt);

    GetMem(Buffer, Sect1Size);
    ZeroMemory(Buffer, Sect1Size);
    SetFilePointer(hFile,Sect1Offset,nil,FILE_BEGIN);
    ReadFile(hFile, Buffer^, Sect1Size, n, nil);
    if(n<>Sect1Size)then
    begin
      FreeMem(Buffer, Sect1Size);
      Result := rInvalidPE;
      goto _Final;
    end;
    dwTmp:=GetCryptDataEnd(dwCryptBegin, Buffer^, Sect1Size);
    if not WriteToFile(dwTmp, SizeOf(dwTmp), $01A8) then
    begin
      FreeMem(Buffer, Sect1Size);
      Result := rCantWrite;
      goto _Final;
    end;
    Dec(dwTmp,$14); //Здесь какие-то данные
    CryptData(dwCryptBegin,dwTmp,dwCryptVal,Buffer^);
    dwCryptBegin:=dwCryptBegin+dwIB+dwSect1RVA;
    dwCryptEnd:=dwTmp+dwIB+dwSect1RVA;
    if not WriteToFile(Buffer^, Sect1Size, 0) then
    begin
      FreeMem(Buffer, Sect1Size);
      Result := rCantWrite;
      goto _Final;
    end;
    FreeMem(Buffer, Sect1Size);

    GetMem(Buffer, Sect2Size);
    ZeroMemory(Buffer, Sect2Size);
    SetFilePointer(hFile,Sect2Offset,nil,FILE_BEGIN);
    ReadFile(hFile, Buffer^, Sect2Size, n, nil);
    if(n<>Sect2Size)then
    begin
      FreeMem(Buffer, Sect2Size);
      Result := rInvalidPE;
      goto _Final;
    end;
    dwTmp:=GetSectionSize(Buffer^, n);
    if not WriteToFile(dwTmp, SizeOf(dwTmp), $01D0) then
    begin
      FreeMem(Buffer, Sect2Size);
      Result := rCantWrite;
      goto _Final;
    end;
    if not WriteToFile(Buffer^, dwTmp, 0) then
    begin
      FreeMem(Buffer, Sect2Size);
      Result := rCantWrite;
      goto _Final;
    end;
    FreeMem(Buffer, Sect2Size);

    GetMem(Buffer, $30);
    ZeroMemory(Buffer, $30);
    PushDecryptionIntoBuffer(dwCryptBegin,dwCryptEnd,
     dwCryptVal,dwCryptBegin-dwIB-$10BE,Buffer^);
    if not WriteToFile(Buffer^, $30, $A0) then
    begin
      Result := rCantWrite;
      FreeMem(Buffer, $30);
      goto _Final;
    end;
    FreeMem(Buffer, $30);
    Result := rOK;
    _Final:
  except
    Result := rUnknown;
  end;
  CloseHandle(hFile);
  end else
    Result := rCantOpen;
  FreeMem(OutpFileName, LStrLen(lpOutpFile)+1);
end;

end.