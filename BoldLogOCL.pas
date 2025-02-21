unit BoldLogOCL;

{ Global compiler directives }
{$include bold.inc}


interface

implementation

uses
  BoldLogReceiverInterface,
  BoldDefs,
  BoldOcl,
  BoldLogHandler;

type
  TBoldOCLReceiver = class(TBoldLogReceiver, IBoldLogReceiver)
  protected
    procedure Log(const s: string); override;
    procedure Start;
    procedure Stop;
  end;

{ TBoldOCLReceiver }

procedure TBoldOCLReceiver.Log(const s: string);
begin
  inherited;

end;

procedure TBoldOCLReceiver.Start;
begin
  BoldOCLLogHandler := BoldLog;
end;

procedure TBoldOCLReceiver.Stop;
begin
  BoldOCLLogHandler := nil;
end;

end.
