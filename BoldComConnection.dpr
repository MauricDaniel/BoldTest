library BoldComConnection;

uses
  ComServ,
  BoldComConnection_TLB in 'BoldComConnection_TLB.pas';

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

{$R *.RES}
{$R *.TLB}

begin
  ComServer.LoadTypeLib;
end.

