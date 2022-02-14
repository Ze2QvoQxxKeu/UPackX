program UPackX;

uses
  Windows, Messages, OpenFileDlg, Utils, Crypt;

{$R RSRC.res}

const
  DLG1 = 101;
  EDT1 = 200;
  EDT2 = 201;
  BTN1 = 301;
  BTN2 = 302;
  BTN3 = 303;
  TIMER_ID       = 1;
  TIMER_INTERVAL = 30;
  PROGRAM_NAME   = 'UPackX v1.0';
  ABOUT_TEXT     = PROGRAM_NAME+#13#10'Coded by Error13Tracer';

var
  Mode      : BOOL = True;
  AlphaVal  : BYTE = 10;
  TimerID   : DWORD;
  MX        : DWORD;
  hThread   : DWORD;
  Handle    : DWORD;
  bIgnore   : Boolean;
  szInpFile : AnsiString;
  szOutpFile: AnsiString;
  ThreadStr : AnsiString;

procedure ShutDown;
begin
  KillTimer(Handle,TimerID);
  EndDialog(Handle, 0);
  ExitProcess(0);
end;

function TimerProc(hWnd: HWND; uMsg: Integer; T: Integer;
 CurrentTime: DWORD): Integer; stdcall;
begin
  Result := 0;
	if Mode then
	begin
		if AlphaVal < 220 then
			AlphaVal := AlphaVal+7
		else
    begin
      Mode := False;
      KillTimer(Handle, TimerID);
      RedrawWindow(Handle, nil, 0, RDW_ERASE or RDW_INVALIDATE
       or RDW_ALLCHILDREN or RDW_UPDATENOW);
    end
	end
	else
		if AlphaVal>10 then
			AlphaVal := AlphaVal-7
		else
			ShutDown;
  SetLayeredWindowAttributes(Handle, 0, AlphaVal, LWA_ALPHA);
end;

procedure OnClose;
begin
  if Mode then
    Exit;
  TimerID := SetTimer(Handle, TIMER_ID, TIMER_INTERVAL, @TimerProc);
end;

procedure ThreadWndProc(p: pointer);
var
  hWin: DWORD;
begin
  repeat
    ProcessMessages;
    hWin:=FindWindow(nil,PChar(ThreadStr));
  until GetParent(hWin)=Handle;
  SetWindowLong(hWin, GWL_EXSTYLE,
   GetWindowLong(hWin, GWL_EXSTYLE) or WS_EX_LAYERED);
  SetLayeredWindowAttributes(hWin, 0, AlphaVal, LWA_ALPHA);
  DeleteMenu(GetSystemMenu(hWin, FALSE), SC_CLOSE, 0);
  SendMessage(hWin,WM_SETICON,0,LoadIcon(hInstance,PChar(0)));
  ExitThread(0);
end;

procedure ModifyWnd(WndTitle: AnsiString);
begin
  ThreadStr:=WndTitle;
  CreateThread(nil,128,@ThreadWndProc,nil,0,hThread);
end;

function MsgBox(WndText, WndTitle: AnsiString; dwFlags: DWORD): DWORD;
begin
  ModifyWnd(WndTitle);
  Result:=MessageBox(Handle,PChar(WndText),PChar(WndTitle),dwFlags);
end;

procedure EnableControls(Enabled: Boolean);
begin
  SendDlgItemMessage(Handle, EDT2, WM_ENABLE, Integer(Enabled), 0);
  if not Enabled then
  begin
    SetWindowLong(GetDlgItem(Handle,EDT2), GWL_STYLE,
     GetWindowLong(GetDlgItem(Handle,EDT2), GWL_STYLE) - ES_READONLY);
    SetWindowLong(GetDlgItem(Handle,BTN2), GWL_STYLE,
     GetWindowLong(GetDlgItem(Handle,BTN2), GWL_STYLE) + WS_DISABLED);
    SetDlgItemText(Handle,EDT2,'');
  end else begin
    SetWindowLong(GetDlgItem(Handle,EDT2), GWL_STYLE,
     GetWindowLong(GetDlgItem(Handle,EDT2), GWL_STYLE) + ES_READONLY);
    SetWindowLong(GetDlgItem(Handle,BTN2), GWL_STYLE,
     GetWindowLong(GetDlgItem(Handle,BTN2), GWL_STYLE) - WS_DISABLED);
    bIgnore := True;
    SendDlgItemMessage(Handle, BTN2, WM_LBUTTONDOWN, 0, 0);
    SendDlgItemMessage(Handle, BTN2, WM_LBUTTONUP, 0, 0);
  end;
end;
  
procedure GetFileName;
const
  Filter = 'Any PE File (*.exe,*.scr,*.dll,*.ocx)'#0'*.exe;*.scr;*.dll;*.ocx';
  Title  = 'Select file...';
begin
  ModifyWnd(Title);
  szInpFile := FileOpenDlg(Handle,Title,Filter);
  SetDlgItemText(Handle,EDT1,@szInpFile[1]);
  if szInpFile='' then
    EnableControls(False)
  else begin
    szOutpFile := ExtractFileNameWithOutExt(szInpFile)+'_'
     +ExtractFileExt(szInpFile);
    SetDlgItemText(Handle,EDT2,@szOutpFile[1]);
    EnableControls(True);
  end;
end;

procedure CryptIt;
const
  MB_TTLINFO  = 'Information';
  MB_TTLERROR = 'Error';
var
  Buf: PChar;
begin
  if bIgnore then
  begin
    bIgnore := False;
    Exit;
  end;
  GetMem(Buf,MAX_PATH);
  GetDlgItemText(Handle,EDT2,Buf,MAX_PATH);
  szOutpFile:=Copy(Buf,1,Length(Buf));
  FreeMem(Buf,MAX_PATH);
  szOutpFile:=ExtractFilePath(szInpFile)+ExtractFileName(szOutpFile);
  case CryptFile(PChar(szInpFile),PChar(szOutpFile)) of
    rOk:        MsgBox('Successfully!',MB_TTLINFO,MB_ICONINFORMATION);
    rNotUPX:    MsgBox('File not packed UPX or already modifyed.',
                 MB_TTLERROR,MB_ICONERROR);
    rInvalidPE: MsgBox('Invalid PE file.',MB_TTLERROR,MB_ICONERROR);
    rUnknown:   MsgBox('Unknown error.',MB_TTLERROR,MB_ICONERROR);
    rCantOpen:  MsgBox('Can''t open input file.',MB_TTLERROR,MB_ICONERROR);
    rCantWrite: MsgBox('Can''t write to output file.',MB_TTLERROR,MB_ICONERROR);
  end;
end;

procedure About;
const
  ABOUT_TTL = 'About...';
var
  MsgPars: TMsgBoxParams;
begin
  with MsgPars do
  begin
    cbSize := SizeOf(MsgPars);
    hwndOwner := Handle;
    hInstance := Sysinit.hInstance;
    lpszText := PChar(ABOUT_TEXT);
    lpszCaption := ABOUT_TTL;
    dwStyle := MB_OK or MB_USERICON;
    lpszIcon := PChar(0);
    dwContextHelpId := 0;
    lpfnMsgBoxCallback := nil;
    dwLanguageId := LANG_NEUTRAL;
  end;
  ModifyWnd(ABOUT_TTL);
  MessageBoxIndirect(MsgPars);
end;

function MainDlgProc(hWin, uMsg, wParam, lParam : Integer) : Integer; stdcall;
begin
  Result := 0;
  if uMsg=WM_COMMAND then
  begin
    if wParam = BTN1 then
      GetFileName;
    if wParam = BTN2 then
      CryptIt;
    if wParam = BTN3 then
      About;
  end;
  if uMsg=WM_INITDIALOG then
  begin
    Handle := hWin;
    SetWindowText(Handle, PROGRAM_NAME);
    EnableControls(False);
    SendMessage(Handle,WM_SETICON,0,LoadIcon(hInstance,PChar(0)));
    SetWindowLong(Handle, GWL_EXSTYLE,
     GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_LAYERED);
    TimerID   := SetTimer(Handle, TIMER_ID, TIMER_INTERVAL, @TimerProc);
  end;
  if (uMsg=WM_DESTROY)or(uMsg=WM_CLOSE) then
    OnClose;
end;

function AlreadyRunned: BOOL;
begin
	MX     := OpenMutex(MUTEX_ALL_ACCESS, False, PROGRAM_NAME);
	Result := (MX<>0);
	if MX = 0 then
		MX :=CreateMutex(nil, False, PROGRAM_NAME);
end;

begin
  if AlreadyRunned then Exit;
  DialogBoxParam(hInstance, PChar(DLG1), 0, @MainDlgProc, 0);
end.
