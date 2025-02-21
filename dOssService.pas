unit dOssService;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  Windows,
  Vcl.SvcMgr,
  Net.CrossSocket.Base,
  Net.CrossSocket.Iocp,
  BoldThreadSafeQueue;

type
  TdmOSSService = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceBeforeInstall(Sender: TService);
  private
    FSocket: ICrossSocketText;
    fPort: word;
    FSentBytes, FSendCount: Int64;
    fReceiveQueue: TBoldThreadSafeStringQueue;
    fErrorQueue: TBoldThreadSafeStringQueue;
    fGetClientsResult: string;
    procedure UpdateClients;
    procedure ParseCommandLine(var aName, aDisplayName, aPort: String);
    procedure OnConnected(const Sender: TObject; const AConnection: ICrossConnection);
    procedure OnDisconnected(const Sender: TObject; const AConnection: ICrossConnection);
    procedure OnSent(const Sender: TObject; const AConnection: ICrossConnection; const ALen: Integer);
    procedure OnError(const Sender: TObject; const AMessage: string);
    procedure GetClients;
    procedure SetClients(const AConnection: ICrossConnection; const AMessage: string);
    procedure ProcessMessage(const AConnection: ICrossConnection; const AMsg: string);
    procedure Sync(const AConnection: ICrossConnection; const AMessage: string);
  public
    function GetServiceController: TServiceController; override;
    property Socket: ICrossSocketText read FSocket;
    property ReceiveQueue: TBoldThreadSafeStringQueue read fReceiveQueue write fReceiveQueue;
    property ErrorQueue: TBoldThreadSafeStringQueue read fErrorQueue write fErrorQueue;
  end;

var
  dmOSSService: TdmOSSService;

implementation

uses
  Forms,
  Registry,
  StrUtils,
  System.JSON,
  Net.CrossSocket;

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  dmOSSService.Controller(CtrlCode);
end;

procedure TdmOSSService.GetClients;
var
  i: integer;
  LConns: TArray<ICrossConnection>;
begin
  if GetCurrentThreadId <> MainThreadID then
  begin
    TThread.Queue(nil, GetClients); // ensure this runs only in main thread
    exit;
  end;
  LConns := FSocket.LockConnections.Values.ToArray;
  try
    for i := 0 to Length(LConns) -1 do
      LConns[i].SendString(fGetClientsResult);
  finally
    FSocket.UnLockConnections;
  end;
end;

function TdmOSSService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TdmOSSService.OnConnected(const Sender: TObject;
  const AConnection: ICrossConnection);
begin
  AConnection.Tag :=  AConnection.PeerAddr +':' + AConnection.PeerPort.ToString;
  UpdateClients;
end;

procedure TdmOSSService.OnDisconnected(const Sender: TObject;
  const AConnection: ICrossConnection);
begin
  UpdateClients;
end;

procedure TdmOSSService.OnError(const Sender: TObject; const AMessage: string);
begin
  if Assigned(ErrorQueue) then
    ErrorQueue.Enqueue(AMessage)
  else
    // log or raise or what ?
end;

procedure TdmOSSService.ProcessMessage(const AConnection: ICrossConnection; const AMsg: string);
var
  vData, vCmd: String;
  i: integer;
begin
  if Assigned(fReceiveQueue) then
    ReceiveQueue.Enqueue(AMsg);
  i := Pos(' ', AMsg);
  if i = 0 then
    vCmd := AMsg
  else
    vCmd := Copy(AMsg, 1, i-1);
  vData := Copy(AMsg, i+1, maxInt);
  if vCmd = 'SYNC' then
    Sync(AConnection, AMsg)
  else
  if vCmd = 'SETCLIENT' then
    SetClients(AConnection, vData)
  else
  if vCmd = 'GETCLIENTS' then
    GetClients
  else
    raise Exception.Create('Unknown OSS command.');
end;

procedure TdmOSSService.OnSent(const Sender: TObject; const AConnection: ICrossConnection; const ALen: Integer);
begin
  AtomicIncrement(FSendCount);
  AtomicIncrement(FSentBytes, ALen);
end;

procedure TdmOSSService.ParseCommandLine(var aName, aDisplayName, aPort: String);
var
  i: Integer;
begin
  aName:=''; aDisplayName:=''; aPort:='';
  for i:=1 to System.ParamCount do begin
    if AnsiContainsText(ParamStr(i), '/name=') then begin
      aName:=Copy(ParamStr(i), Pos('=', ParamStr(i))+1, Length(ParamStr(i)));
    end;
    if AnsiContainsText(ParamStr(i), '/displayname=') then begin
      aDisplayName:=Copy(ParamStr(i), Pos('=', ParamStr(i))+1, Length(ParamStr(i)));
    end;
    if AnsiContainsText(ParamStr(i), '/port=') then begin
      aPort:=Copy(ParamStr(i), Pos('=', ParamStr(i))+1, Length(ParamStr(i)));
    end;
  end;
end;

procedure TdmOSSService.ServiceAfterInstall(Sender: TService);
var
  aname, adisplayname, aPort: String;
  reg: TRegistry;
begin
  ParseCommandLine(aname, adisplayname, aport);
  reg:=TRegistry.Create;
  try
    reg.RootKey:=HKEY_LOCAL_MACHINE;
    if reg.OpenKey('SYSTEM\CurrentControlSet\Services\' + Name, True) then begin
      reg.WriteExpandString ('ImagePath', ParamStr(0) + ' /name="'+aname
          +'" /displayname="'+adisplayname+'" /port='+aport);
      reg.WriteExpandString ('Description', 'kiC Objectspace Synchronizer (gebunden an Anschluﬂ='+aport+')');
      reg.CloseKey;
    end;
  finally
    reg.Free;
  end;
end;

procedure TdmOSSService.ServiceBeforeInstall(Sender: TService);
var
  aname, adisplayname, aPort: String;
begin
  ParseCommandLine(aname, adisplayname, aport);
  if aname='' then
    raise Exception.Create('Parameter "name" fehlt.');
  if adisplayname='' then
    raise Exception.Create('Parameter "displayname" fehlt.');
  if aport='' then
    raise Exception.Create('Parameter "port" fehlt.');
  if StrToIntDef(aPort, -1)=-1 then
    raise Exception.Create('/port muﬂ zwischen 1 und 65535 liegen!');
end;

procedure TdmOSSService.ServiceCreate(Sender: TObject);
var
  aname, adisplayname, aport: String;
begin
  ParseCommandLine(aname, adisplayname, aport);
  Name:=aName;
  Displayname:=aDisplayName;
  if StrToIntDef(aPort, -1)<>-1 then begin
    fPort := StrToInt(aPort);
  end;
end;

procedure TdmOSSService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  FSocket := TTextCrossSocket.create;
  Socket.OnConnected := OnConnected;
  Socket.onDisconnected := OnDisconnected;
  Socket.OnMessage := ProcessMessage;
  Socket.OnSent := OnSent;
  Socket.OnError := OnError;
  Socket.Port := fPort;
  Socket.Address := '0.0.0.0';
  Socket.Listen;
  Started := True;
  if Assigned(Forms.Application) then
    Forms.Application.MainForm.Caption := 'Listening on ' + fPort.ToString;
end;

procedure TdmOSSService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
//  Socket.CloseAllListens;
//  Socket.DisconnectAll;
  fSocket := nil;
  Stopped:=True;
end;

procedure TdmOSSService.SetClients(const AConnection: ICrossConnection; const AMessage: string);
begin
  AConnection.Tag := AMessage;
  UpdateClients;
end;

procedure TdmOSSService.Sync(const AConnection: ICrossConnection; const AMessage: string);
var
  LConns: TArray<ICrossConnection>;
  i: integer;
begin
  LConns := Socket.LockConnections.Values.ToArray;
  try
    if (LConns <> nil) then
    begin
      for i := 0 to Length(LConns) -1 do
        if LConns[i] <> AConnection then
          LConns[i].SendString(AMessage);
    end;
  finally
    Socket.UnlockConnections;
  end;
end;

procedure TdmOSSService.UpdateClients;
var
  i: integer;
  LConns: TArray<ICrossConnection>;
  vArray: TJsonArray;
  vClientData: TJsonValue;
  s: string;
begin
  if GetCurrentThreadId <> MainThreadID then
  begin
    TThread.Queue(nil, UpdateClients); // ensure this runs only in main thread
    exit;
  end;
  LConns := FSocket.LockConnections.Values.ToArray;
  vArray := TJsonArray.Create;
  try
    if (LConns <> nil) then
    begin
      for i := 0 to Length(LConns) -1 do
      begin
        vClientData := TJSONObject.ParseJSONValue(LConns[i].Tag);
        if Assigned(vClientData) then
          vArray.AddElement(vClientData);
      end;
      s := 'GETCLIENTS ' + vArray.ToString;
      if s <> fGetClientsResult then
      begin
        fGetClientsResult := 'GETCLIENTS ' + vArray.ToString;
        GetClients;
      end;
    end;
  finally
    FSocket.UnLockConnections;
    vArray.free;
  end;
end;

end.
