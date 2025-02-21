
{ Global compiler directives }
{$include bold.inc}
unit BoldLogHandler;

interface

uses
  BoldDefs,
  BoldSubscription,
  BoldLogReceiverInterface;

type
  { forward declaration }
  TBoldLogReceiverSubscriber = class;
  TBoldLogHandler = class;
  TBoldLogHandlerClass = class of TBoldLogHandler;

  { TBoldLogHandler }
  TBoldLogHandler = class(TBoldSubscribableObject)
  private
    fIndent: integer;
    fInterrupted: Boolean;
    fInterruptHandled: Boolean;
    fLastCommandIsSeparator: Boolean;
    fBoldLogReceiverSubscriber: TBoldLogReceiverSubscriber;
    procedure SetProgress(const Value: integer);
    procedure SetLogHeader(const Value: string);
    procedure SetProgressMax(const Value: integer);
  protected
    function IndentSpaces: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Log(const AMsg: string); overload; virtual;
    procedure Log(const AMsg: string; ALogType: TBoldLogType); overload; virtual;
    procedure Log(const AMsg: string; ATags: array of const); overload; virtual;
    procedure Log(const AMsg: string; ATags: array of const; ALogType: TBoldLogType); overload; virtual;

    procedure LogFmt(const AMsg: string; Args: array of const); overload;
    procedure LogFmt(const AMsg: string; Args: array of const; const ATags: array of const); overload;
    procedure LogFmt(const AMsg: string; Args: array of const; const ATags: array of const; ALogType: TBoldLogType); overload;
    procedure LogFmt(const AMsg: string; Args: array of const; ALogType: TBoldLogType); overload;

    procedure LogIndent(const AMsg: string; ALogType: TBoldLogType = ltInfo);
    procedure LogDedent(const AMsg: string; ALogType: TBoldLogType = ltInfo);

    procedure LogFmtIndent(const AMsg: string; const Args: array of const; ALogType: TBoldLogType = ltInfo);
    procedure LogFmtDedent(const AMsg: string; const Args: array of const; ALogType: TBoldLogType = ltInfo);

    procedure Clear; virtual;
    procedure Hide; virtual;
    procedure Show; virtual;
    procedure StartLog(const SessionName: String); virtual;
    procedure EndLog;
    procedure Indent;
    procedure Dedent;
    procedure Separator;
    procedure ProgressStep; virtual;
    procedure Sync; virtual;
    procedure RegisterLogReceiver(const LogReceiver: IBoldLogReceiver);
    procedure UnregisterLogReceiver(const LogReceiver: IBoldLogReceiver);
    procedure InterruptProcess;
    function ProcessInterruption: Boolean;
    property ProgressMax: integer write SetProgressMax;
    property Progress: integer write SetProgress;
    property LogHeader: string write SetLogHeader;

  end;

  TBoldLogReceiverSubscriber = class(TBoldSubscriber)
  private
    fReceiver: IBoldLogReceiver;
  protected
    procedure Receive(Originator: TObject; OriginalEvent: TBoldEvent; RequestedEvent: TBoldRequestedEvent); override;
    procedure ReceiveExtended(Originator: TObject; OriginalEvent: TBoldEvent; RequestedEvent: TBoldRequestedEvent; const Args: array of const); override;
    function GetHandlesExtendedEvents: Boolean; override;
  public
    constructor Create(const Receiver: IBoldLogreceiver);
    destructor Destroy; override;
  end;

function BoldLog: TBoldLogHandler;

implementation

uses
  SysUtils,

  BoldCoreConsts,
  BoldMath;

const
  bleFirst = 1;
  bleSetProgress = 1;
  bleSetLogHeader = 2;
  bleSetProgressMax = 3;
  bleClear = 4;
  bleHide = 5;
  bleLog = 6;
  bleProgressStep = 7;
  bleShow = 8;
  bleStartLog = 9;
  bleEndLog = 10;
  bleProcessInterruption = 11;
  bleRemoveReceiver = 12;
  bleSync = 13;
  bleLast = 13;



var
  G_BoldLog: TBoldLogHandler = nil;
  G_BoldLogHandlerClass: TBoldLogHandlerClass = TBoldLogHandler;

function BoldLog: TBoldLogHandler;
begin
  if not Assigned(G_BoldLog) then
    G_BoldLog := G_BoldLogHandlerClass.Create;
  Result := G_BoldLog;
end;

constructor TBoldLogHandler.Create;
begin
  fLastCommandIsSeparator := true;
  inherited;
end;

destructor TBoldLogHandler.Destroy;
begin
  if self = G_BoldLog then
    G_BoldLog := nil;
  fBoldLogReceiverSubscriber.free;
  inherited;
end;

function TBoldLogHandler.IndentSpaces: string;
begin
  Result := StringOfChar(' ', fIndent shl 1);
end;

procedure TBoldLogHandler.Separator;
begin
(*
  if fLastCommandIsSeparator then
    exit;
  Log('', ltSeparator);
  Log('-={++++}=-', ltSeparator);
  Log('', ltSeparator);
  fLastCommandIsSeparator := true;
*)
end;

procedure TBoldLogHandler.Clear;
begin
  SendEvent(bleClear);
end;

procedure TBoldLogHandler.Show;
begin
  SendEvent(bleShow);
end;

procedure TBoldLogHandler.Hide;
begin
  SendEvent(bleHide);
end;

procedure TBoldLogHandler.StartLog(const SessionName: String);
begin
  fIndent := 0;
  fInterrupted := false;
  fInterruptHandled := false;
  Separator;
  SendExtendedEvent(bleStartLog, [SessionName]);
end;

procedure TBoldLogHandler.EndLog;
begin
  SendEvent(bleEndLog);
  Separator;
end;

procedure TBoldLogHandler.Log(const AMsg: string; ATags: array of const);
var
  i: integer;
  var Tags: Array of TVarRec;
begin
//  Assert(Length(ATags) > 0);
  i := Length(ATags);
  SetLength(Tags, i+1);
  Tags[0].VType := vtUnicodeString;
  Tags[0].VUnicodeString := PChar(AMsg);
  for i := 0 to Length(ATags) -1 do
    Tags[i+1] := ATags[i];
  SendExtendedEvent(bleLog, Tags);
  Tags := [];
  fLastCommandIsSeparator := false;
end;

procedure TBoldLogHandler.Log(const AMsg: string);
begin
  Log(AMsg, []);
end;

procedure TBoldLogHandler.LogFmt(const AMsg: string; Args: array of const; const ATags: array of const);
begin
  Log(Format(AMsg, Args), ATags);
end;

procedure TBoldLogHandler.LogFmt(const AMsg: string; Args: array of const);
begin
  Log(Format(AMsg, Args), []);
end;

procedure TBoldLogHandler.LogIndent(const AMsg: string; ALogType: TBoldLogType = ltInfo);
begin
  Log(AMsg, ALogType);
  Indent;
end;

procedure TBoldLogHandler.LogDedent(const AMsg: string; ALogType: TBoldLogType = ltInfo);
begin
  Dedent;
  Log(AMsg, ALogType);
end;

procedure TBoldLogHandler.Log(const AMsg: string; ALogType: TBoldLogType);
begin
  Log(AMsg);
end;

procedure TBoldLogHandler.LogFmtIndent(const AMsg: string; const Args: array of const; ALogType: TBoldLogType);
begin
  LogFmt(AMsg, Args);
  Indent;
end;

procedure TBoldLogHandler.LogFmtDedent(const AMsg: string; const Args: array of const; ALogType: TBoldLogType);
begin
  Dedent;
  LogFmt(AMsg, Args);
end;

procedure TBoldLogHandler.Indent;
begin
  Inc(fIndent);
end;

procedure TBoldLogHandler.Dedent;
begin
  Dec(fIndent);
  if fIndent < 0 then
    fIndent := 0;
end;

procedure TBoldLogHandler.SetProgressMax(const Value: integer);
begin
  SendExtendedEvent(bleSetProgressMax, [MaxIntValue([0, Value])]);
end;

procedure TBoldLogHandler.SetProgress(const Value: integer);
begin
  SendExtendedEvent(bleSetProgress, [value]);
end;

procedure TBoldLogHandler.SetLogHeader(const Value: String);
begin
  SendExtendedEvent(bleSetLogHeader, [Value]);
end;

procedure TBoldLoghandler.ProgressStep;
begin
  SendEvent(bleProgressStep);
end;

procedure TBoldLogHandler.RegisterLogReceiver(const LogReceiver: IBoldLogReceiver);
begin
  fBoldLogReceiverSubscriber := TBoldLogReceiverSubscriber.Create(LogReceiver);
end;

procedure TBoldLogHandler.UnregisterLogReceiver(const LogReceiver: IBoldLogReceiver);
begin
  SendExtendedEvent(bleRemoveReceiver, [LogReceiver]); // will free the subscriber, so we just need to clear the reference
  fBoldLogReceiverSubscriber := nil;
end;


procedure TBoldLogHandler.InterruptProcess;
begin
  Log(sTryingToAbort);
  fInterrupted := true;
  fInterruptHandled := false;
end;

function TBoldLogHandler.ProcessInterruption: Boolean;
begin
  SendEvent(bleProcessInterruption);
  result := fInterrupted;
  if result then
  begin
    if not fInterruptHandled then
      Log(sProcessStopped);
    fInterruptHandled := true;
  end;
end;

{ TBoldLogReceiverSubscriber }

constructor TBoldLogReceiverSubscriber.Create(const Receiver: IBoldLogreceiver);
begin
  inherited Create;
  fReceiver := Receiver;
  BoldLog.AddSmallSubscription(self, [beDestroying], 0);
  BoldLog.AddSmallSubscription(self, [bleFirst..bleLast], 0);
end;

destructor TBoldLogReceiverSubscriber.Destroy;
begin
  fReceiver := nil;
  inherited;
end;

function TBoldLogReceiverSubscriber.GetHandlesExtendedEvents: Boolean;
begin
  result := true;
end;

procedure TBoldLogReceiverSubscriber.Receive(Originator: TObject;
  OriginalEvent: TBoldEvent; RequestedEvent: TBoldRequestedEvent);
begin
  // Do nothing... Handled by Extended
end;

procedure TBoldLogReceiverSubscriber.ReceiveExtended(Originator: TObject;
  OriginalEvent: TBoldEvent; RequestedEvent: TBoldRequestedEvent;
  const Args: array of const);
  
  function GetString(const VR: TVarRec): String;
  begin
    case VR.VType of
      vtString: Result := string(VR.vString);
      vtAnsiString: Result := string(VR.vAnsiString);
      {$IFDEF BOLD_UNICODE}
      vtUnicodeString: Result := string(VR.vUnicodeString);
      {$ENDIF}
      else
        raise Exception.Create(sUnknownTypeInGetString);
    end;
  end;

begin
  case OriginalEvent of
    bleSetProgress: fReceiver.SetProgress(args[0].VInteger); // Value: integer
    bleSetLogHeader: fReceiver.SetLogHeader(GetString(Args[0])); // Value: string
    bleSetProgressMax: fReceiver.SetProgressMax(args[0].VInteger); // Value: integer
    bleLog: fReceiver.Log(String(args[0].VString), ltInfo);
    bleStartLog: fReceiver.StartLog(GetString(Args[0]));//SessionName: String
    // commit suicide
    bleRemoveReceiver: if IUnknown(Args[0].VInterface) = freceiver then free;
    beDestroying: Free;
    bleClear: fReceiver.Clear;
    bleHide: fReceiver.Hide;
    bleProgressStep: fReceiver.ProgressStep;
    bleShow: fReceiver.Show;
    bleSync: fReceiver.Sync;
    bleEndLog: fReceiver.EndLog;
    bleProcessInterruption: fReceiver.ProcessInterruption;
    else
      ;
  end;
end;


procedure TBoldLogHandler.Sync;
begin
  SendEvent(bleSync);
end;

procedure TBoldLogHandler.LogFmt(const AMsg: string; Args: array of const; const ATags: array of const;
  ALogType: TBoldLogType);
begin
  Log(Format(AMsg, Args), ATags);
end;

procedure TBoldLogHandler.LogFmt(const AMsg: string; Args: array of const; ALogType: TBoldLogType);
begin
  Log(Format(AMsg, Args), [], ALogType);
end;

procedure TBoldLogHandler.Log(const AMsg: string; ATags: array of const; ALogType: TBoldLogType);
begin
  Log(AMsg, ATags);
end;

initialization

finalization
  FreeAndNil(G_BoldLog);

end.
