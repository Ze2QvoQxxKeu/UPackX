unit OpenFileDlg;

interface

uses
  Windows;

type
  TOpenFileName = packed record
    lStructSize: DWORD;
    hWndOwner: HWND;
    hInstance: HINST;
    lpstrFilter: PAnsiChar;
    lpstrCustomFilter: PAnsiChar;
    nMaxCustFilter: DWORD;
    nFilterIndex: DWORD;
    lpstrFile: PAnsiChar;
    nMaxFile: DWORD;
    lpstrFileTitle: PAnsiChar;
    nMaxFileTitle: DWORD;
    lpstrInitialDir: PAnsiChar;
    lpstrTitle: PAnsiChar;
    Flags: DWORD;
    nFileOffset: Word;
    nFileExtension: Word;
    lpstrDefExt: PAnsiChar;
    lCustData: LPARAM;
    lpfnHook: function(Wnd: HWND; Msg: UINT; wParam: WPARAM;
     lParam: LPARAM): UINT stdcall;
    lpTemplateName: PAnsiChar;
  end;

const
  OFN_LONGNAMES     = $00200000;
  OFN_EXPLORER      = $00080000;
  OFN_FILEMUSTEXIST = $00001000;
  OFN_PATHMUSTEXIST = $00000800;
  OFN_HIDEREADONLY  = $00000004;

function GetOpenFileNameA(var OpenFile: TOpenFileName): Bool; stdcall;
external 'comdlg32.dll' name 'GetOpenFileNameA';

function FileOpenDlg(Wnd: HWND; Title, Filter: PChar): PChar;

implementation

function FileOpenDlg(Wnd: HWND; Title, Filter: PChar): PChar;
var
  OpenFile : TOpenFileName;
  FileName: packed array[0..4095] of Char;
begin
  FillChar(OpenFile, SizeOf(TOpenFileName), 0);
  FillChar(FileName, SizeOf(FileName), 0);
  with OpenFile do 
  begin
    lStructSize  := SizeOf(TOpenFileName);
    hInstance    := 0;
    hWndOwner    := Wnd;
    lpstrFilter  := Filter;
    nFilterIndex := 0;
    nMaxFile     := SizeOf(FileName);
    lpstrFile    := FileName;
    lpstrTitle   := Title;
    Flags        := OFN_LONGNAMES or OFN_EXPLORER or OFN_FILEMUSTEXIST or
                    OFN_PATHMUSTEXIST or OFN_HIDEREADONLY or OFN_FILEMUSTEXIST;
  end;
  if GetOpenFileNameA(OpenFile) then
    Result:=OpenFile.lpstrFile
  else
    Result:='';
end;

end.
