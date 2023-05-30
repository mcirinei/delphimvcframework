program TestServer;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  {$IF Defined(USE_INDY)}
  IdHTTPWebBrokerBridge,
  {$ELSE}
  MVCFramework.CrossSocket.WebBrokerBridge,
  {$ENDIF}
  Web.WebReq,
  {$IFNDEF LINUX}
  Winapi.Windows,
  {$ENDIF }
  Web.WebBroker,
  MVCFramework.Commons,
  MVCFramework.Console,
  WebModuleUnit in 'WebModuleUnit.pas' {MainWebModule: TWebModule},
  TestServerControllerU in 'TestServerControllerU.pas',
  TestServerControllerExceptionU in 'TestServerControllerExceptionU.pas',
  SpeedMiddlewareU in 'SpeedMiddlewareU.pas',
  TestServerControllerPrivateU in 'TestServerControllerPrivateU.pas',
  AuthHandlersU in 'AuthHandlersU.pas',
  BusinessObjectsU in '..\..\..\samples\commons\BusinessObjectsU.pas',
  TestServerControllerJSONRPCU in 'TestServerControllerJSONRPCU.pas',
  RandomUtilsU in '..\..\..\samples\commons\RandomUtilsU.pas',
  MVCFramework.Tests.Serializer.Entities in '..\..\common\MVCFramework.Tests.Serializer.Entities.pas',
  FDConnectionConfigU in '..\..\common\FDConnectionConfigU.pas',
  Entities in '..\Several\Entities.pas',
  EntitiesProcessors in '..\Several\EntitiesProcessors.pas';

{$R *.res}

procedure Logo;
begin
  ResetConsole();
  Writeln;
  TextBackground(TConsoleColor.Black);
  TextColor(TConsoleColor.Red);
  Writeln(' ██████╗ ███╗   ███╗██╗   ██╗ ██████╗    ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗');
  Writeln(' ██╔══██╗████╗ ████║██║   ██║██╔════╝    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗');
  Writeln(' ██║  ██║██╔████╔██║██║   ██║██║         ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝');
  Writeln(' ██║  ██║██║╚██╔╝██║╚██╗ ██╔╝██║         ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗');
  Writeln(' ██████╔╝██║ ╚═╝ ██║ ╚████╔╝ ╚██████╗    ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║');
  Writeln(' ╚═════╝ ╚═╝     ╚═╝  ╚═══╝   ╚═════╝    ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝');
  Writeln(' ');
  TextColor(TConsoleColor.White);
  Write('PLATFORM: ');
  {$IF Defined(Win32)} Writeln('WIN32'); {$ENDIF}
  {$IF Defined(Win64)} Writeln('WIN64'); {$ENDIF}
  {$IF Defined(Linux64)} Writeln('Linux64'); {$ENDIF}
  WriteLn('BACKEND: ' + {$IF Defined(USE_INDY)}'INDY'{$ELSE}'CrossSocket'{$ENDIF});
  TextColor(TConsoleColor.Yellow);
  Writeln('DMVCFRAMEWORK VERSION: ', DMVCFRAMEWORK_VERSION);
  TextColor(TConsoleColor.White);
end;

procedure RunServer(APort: Integer);
var
  LServer: {$IF Defined(USE_INDY)}TIdHTTPWebBrokerBridge{$ELSE}TMVCCrossSocketWebBrokerBridge{$ENDIF};
begin
  Logo;
  Writeln(Format('Starting HTTP Server or port %d', [APort]));
  LServer := {$IF Defined(USE_INDY)}TIdHTTPWebBrokerBridge{$ELSE}TMVCCrossSocketWebBrokerBridge{$ENDIF}.Create(nil);
  try
    {$IF Defined(USE_INDY)}
    LServer.OnParseAuthentication :=
      TMVCParseAuthentication.OnParseAuthentication;
    LServer.ListenQueue := 200;
    LServer.MaxConnections := 0;
    {$ENDIF}
    LServer.UseCompression := False;
    LServer.DefaultPort := APort;
    LServer.Active := True;
    Writeln('Press RETURN to stop the server');
    WaitForReturn;
    TextColor(TConsoleColor.Red);
    Writeln('Server stopped');
    ResetConsole();
  finally
    LServer.Free;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    if WebRequestHandler <> nil then
      WebRequestHandler.WebModuleClass := WebModuleClass;
    WebRequestHandlerProc.MaxConnections := 0; {unlimited}
    RunServer(9999);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
