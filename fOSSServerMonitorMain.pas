unit fOSSServerMonitorMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, System.Actions,
  Vcl.ActnList, Vcl.ExtCtrls, Vcl.StdCtrls,

  Vcl.AppEvnts,

  Net.CrossSocket.Base,
  Net.CrossSocket.Iocp,

  System.Generics.Collections,
  System.JSON;

type
  TfrmOSSServerMonitorMain = class(TForm)
    Label1: TLabel;
    edHost: TEdit;
    edPort: TEdit;
    btnConnectDisconnect: TButton;
    pgcMain: TPageControl;
    TabSheet1: TTabSheet;
    lvOSS: TListView;
    tabLog: TTabSheet;
    lvLog: TListView;
    ActionList1: TActionList;
    actConnect: TAction;
    statusBottom: TStatusBar;
    Panel1: TPanel;
    Label2: TLabel;
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actConnectExecute(Sender: TObject);
    procedure actConnectUpdate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormActivate(Sender: TObject);
  private
    FSocket: ICrossSocketText;
    fOssConnected: boolean;
    fOSSIsConnecting: boolean;
    fOSSActive: boolean;
    fTotalEvents: int64;
    fMaxLength: int64;
    procedure Reconnect;
    procedure _OnOssConnected(const Sender: TObject; const AConnection: ICrossConnection);
    procedure _OnOssDisconnected(const Sender: TObject; const AConnection: ICrossConnection);
    procedure _OnOssMessage(const AConnection: ICrossConnection; const AMsg: string);
    procedure _OnError(const Sender: TObject; const AMessage: string);
    procedure SyncEvent(const AOSSMessage: string);
    procedure GetClientsEvent(const AJson: TJsonValue);
    procedure Connect;
    function GetSocket: ICrossSocketText;
  public
    property Socket: ICrossSocketText read GetSocket;
  end;

var
  frmOSSServerMonitorMain: TfrmOSSServerMonitorMain;

implementation

uses
  Net.CrossSocket,
  System.Math;

{$R *.dfm}

const
  cMaxItems = 2000;

{ TfrmOSSServerMonitorMain }

procedure TfrmOSSServerMonitorMain.actConnectExecute(Sender: TObject);
begin
  if fOSSIsConnecting then
  begin
    fOSSIsConnecting := false;
    fOSSActive := false;
  end
  else
    if fOssConnected then
    begin
      fOSSActive := false;
      Socket.DisconnectAll;
      fSocket := nil;
    end
    else
    begin
      fOSSActive := true;
      Connect;
    end;
end;

procedure TfrmOSSServerMonitorMain.actConnectUpdate(Sender: TObject);
begin
  if fOSSIsConnecting then
    (Sender as TAction).Caption := 'Stop'
  else
  if fOssConnected then
    (Sender as TAction).Caption := 'Disconnect'
  else
    (Sender as TAction).Caption := 'Connect';
end;

procedure TfrmOSSServerMonitorMain.Reconnect;
begin
  if fOSSIsConnecting and fOSSActive then
   begin
     Sleep(100);
     Connect;
   end;
end;

procedure TfrmOSSServerMonitorMain.Connect;
begin
  if not fOSSActive then
    exit;
  fOSSIsConnecting := true;
  Socket.Port:=StrToIntDef(edPort.Text, 5090);
  Socket.Address := edHost.Text;
  Socket.Connect(False,
    procedure(const AConnection: ICrossConnection; const ASuccess: Boolean)
    begin
      if not ASuccess then
        TThread.Queue(nil, Reconnect);
    end);
end;

procedure TfrmOSSServerMonitorMain.FormActivate(Sender: TObject);
begin
  if not fOssConnected and not fOSSIsConnecting then
    actConnect.Execute;
end;

procedure TfrmOSSServerMonitorMain.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  fSocket := nil;
end;

procedure TfrmOSSServerMonitorMain.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  fOSSActive := false;
  CanClose := true;
end;

procedure TfrmOSSServerMonitorMain.FormDestroy(Sender: TObject);
begin
  FSocket := nil;
end;

procedure TfrmOSSServerMonitorMain.GetClientsEvent(const AJson: TJsonValue);
var
  i,j: integer;
  Itm: TListItem;
  vArray: TJSONArray;
  vClientInfo: TJSONObject;
  vPair: TJSONPair;
  ListColumn: TListColumn;
begin
  Assert(AJson is TJSONArray);
  lvOSS.Items.BeginUpdate;
  lvOSS.Columns.BeginUpdate;
  try
    vArray := AJson as TJSONArray;
    lvOSS.Clear;
    lvOSS.Columns.Clear;
    lvOSS.Columns.Add.Caption := 'Index';
    for i := 0 to vArray.Count - 1 do
    begin
      vClientInfo := TJSONObject(vArray[i] as TJsonObject);
      Itm := lvOSS.Items.Add;
      Itm.Caption := i.ToString;
      for j := 0 to vClientInfo.Count-1 do
      begin
        vPair := vClientInfo.Pairs[j];
        if lvOSS.Columns.Count <= j+1 then
        begin
          ListColumn := lvOSS.Columns.Add;
          ListColumn.Caption := vPair.JsonString.Value;
          ListColumn.Width:=-1;
        end;
        Itm.SubItems.Add(vPair.JsonValue.Value);
      end;
    end;
  finally
    lvOSS.Columns.EndUpdate;
    lvOSS.Items.EndUpdate;
  end;
end;

function TfrmOSSServerMonitorMain.GetSocket: ICrossSocketText;
begin
  if not Assigned(fSocket) then
  begin
    fSocket := TTextCrossSocket.Create;
    fSocket.OnConnected := _OnOssConnected;
    fSocket.OnDisconnected := _OnOssDisconnected;
    fSocket.OnMessage := _OnOssMessage;
    fSocket.OnError := _OnError;
    fSocket.FireEventsInMainThread := true;
  end;
  result := fSocket;
end;

procedure TfrmOSSServerMonitorMain.SyncEvent(const AOSSMessage: String);
var
  Itm: TListItem;
  MessageLength: integer;
begin
  while lvLog.Items.Count > cMaxItems do
    lvLog.Items.Delete(lvLog.Items.Count-1);
  MessageLength := Length(AOSSMessage);
  Itm := lvLog.Items.Insert(0);
  Itm.Caption := FormatDateTime('hh:nn:ss:zzz', Now);
  Itm.SubItems.Add('');
  Itm.SubItems.Add('');
  Itm.SubItems.Add('');
  Itm.SubItems.Add(MessageLength.ToString);
  Itm.SubItems.Add(AOSSMessage);
  inc(fTotalEvents);
  statusBottom.Panels[1].Text := fTotalEvents.ToString;
  fMaxLength := Max(fMaxLength, MessageLength);
  statusBottom.Panels[2].Text := fMaxLength.ToString;
end;

procedure TfrmOSSServerMonitorMain._OnError(const Sender: TObject;
  const AMessage: string);
begin
  ShowMessage(AMessage);
end;

procedure TfrmOSSServerMonitorMain._OnOssConnected(const Sender: TObject;
  const AConnection: ICrossConnection);
begin
  fOSSIsConnecting := false;
  fOssConnected := true;
  Socket.GetFirstConnection.SendString('GETCLIENTS');
end;

procedure TfrmOSSServerMonitorMain._OnOssDisconnected(const Sender: TObject;
  const AConnection: ICrossConnection);
begin
  fOssConnected := false;
  lvOSS.Clear;
  lvLog.Clear;
  if fOSSActive then
    Connect;
end;

procedure TfrmOSSServerMonitorMain._OnOssMessage(
  const AConnection: ICrossConnection; const AMsg: string);
var
  vData, vCmd: String;
  i: integer;
  Json: TJSONValue;
begin
  if AMsg = '' then
    exit;
  i := Pos(' ', AMsg);
  if i = 0 then
    vCmd := AMsg
  else
    vCmd := Copy(AMsg, 1, i-1);
  vData := Copy(AMsg, i+1, maxInt);
  Json := TJSONObject.ParseJSONValue(vData);
  if vCmd = 'SYNC' then
  begin
    SyncEvent(vData)
  end
  else
  if vCmd = 'GETCLIENTS' then
  begin
    GetClientsEvent(Json);
  end
  else
    raise Exception.CreateFmt('Unknown Command %s', [AMsg]);
end;

end.
