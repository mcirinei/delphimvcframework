program IOCPSample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MVCFramework,
  MVCFramework.Logger,
  MVCFramework.Commons,
  MVCFramework.Signal,
  Web.ReqMulti,
  Web.WebReq,
  Web.WebBroker,
  IdContext,
  MVCFramework.CrossSocket.WebBrokerBridge,
  WebModuleU in 'WebModuleU.pas' {MyWebModule: TWebModule},
  ControllerU in 'ControllerU.pas';

{$R *.res}


procedure RunServer(APort: Integer);
var
  LServer: TMVCCrossSocketWebBrokerBridge;
begin
  Writeln('** DMVCFramework Server ** build ' + DMVCFRAMEWORK_VERSION);
  LServer := TMVCCrossSocketWebBrokerBridge.Create(nil);
  try
    //LServer.OnParseAuthentication := TMVCParseAuthentication.OnParseAuthentication;
    LServer.DefaultPort := APort;
    LServer.Active := True;
    WriteLn('Listening on port ', APort);
    Write('CTRL+C to shutdown the server');
    WaitForTerminationSignal;
    EnterInShutdownState;
    LServer.Active := False;
  finally
    LServer.Free;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  IsMultiThread := True;
  // DMVCFramework Specific Configuration
  // When MVCSerializeNulls = True empty nullables and nil are serialized as json null.
  // When MVCSerializeNulls = False empty nullables and nil are not serialized at all.
  MVCSerializeNulls := True;
  try
    if WebRequestHandler <> nil then
      WebRequestHandler.WebModuleClass := WebModuleClass;
    WebRequestHandlerProc.MaxConnections := 1024;
    RunServer(8080);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

