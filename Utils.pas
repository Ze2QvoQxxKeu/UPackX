unit Utils;

interface

uses
  Windows, Messages;
  
procedure ProcessMessages;
function FileExists(const FileName: string): Boolean;
function ExtractFilePath(const FileName: shortstring): shortstring;
function ExtractFileName(const FileName: shortstring): shortstring;
function ExtractFileExt(const FileName: shortstring): shortstring;
function ExtractFileNameWithoutExt(const FileName: shortstring): String;

implementation

function ExtractFilePath(const FileName: shortstring): shortstring;
var
  I: Integer;
begin
  I := Length(FileName);
  while (I > 1) and not (FileName[I] in ['\', ':']) do Dec(I);
  Result := Copy(FileName, 1, I);
  if Result[0] > #0 then
    if Result[Ord(Result[0])] = #0 then Dec(Result[0]);
end;

function ExtractFileName(const FileName: shortstring): shortstring;
var
  I: Integer;
begin
  I := Length(FileName);
  while (I >= 1) and not (FileName[I] in ['\', ':']) do Dec(I);
  Result := Copy(FileName, I + 1, 255);
  if Result[0] > #0 then
    if Result[Ord(Result[0])] = #0 then Dec(Result[0]);
end;

function ExtractFileExt(const FileName: shortstring): shortstring;
var
  I: Integer;
begin
  I := Length(FileName);
  while (I > 1) and not (FileName[I] in ['.', '\', ':']) do Dec(I);
  if (I > 1) and (FileName[I] = '.') then
    Result := Copy(FileName, I, 255) else
    Result := '';
  if Result[0] > #0 then
    if Result[Ord(Result[0])] = #0 then Dec(Result[0]);
end;

function ExtractFileNameWithoutExt(const FileName: shortstring): String;
var
  FN: shortstring;
begin
  FN:=ExtractFileName(FileName);
  Result:=Copy(FN,1,Length(FN)-Length(ExtractFileExt(FN)));
  FN:=ExtractFileName(Result);
  Result:=Copy(FN,1,Length(FN)-Length(ExtractFileExt(FN)));
end;

function FileAge(const FileName: string): Integer;
type
  LongRec = packed record
    Lo: Word;
    Hi: Word;
  end;
var
  Handle: THandle;
  FindData: TWin32FindData;
  LocalFileTime: TFileTime;
begin
  Handle := FindFirstFile(PChar(FileName), FindData);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    Windows.FindClose(Handle);
    if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
    begin
      FileTimeToLocalFileTime(FindData.ftLastWriteTime, LocalFileTime);
      if FileTimeToDosDateTime(LocalFileTime, LongRec(Result).Hi,
        LongRec(Result).Lo) then Exit;
    end;
  end;
  Result := -1;
end;

function FileExists(const FileName: string): Boolean;
begin
  Result := FileAge(FileName) <> -1;
end;

procedure ProcessMessages;
var
  Msg: TMsg;
function ProcessMsg(var Msg: TMsg): Boolean;
begin
  Result := False;
  if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
  begin
    Result := True;
    if Msg.Message <> WM_QUIT then
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end
    else
      DispatchMessage(Msg);
  end;
end;  
begin
  while ProcessMsg(Msg) do;
end;

end.
