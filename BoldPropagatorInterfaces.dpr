library BoldPropagatorInterfaces;

uses
  ComServ,
  BoldPropagatorInterfaces_TLB in 'BoldPropagatorInterfaces_TLB.pas';

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
