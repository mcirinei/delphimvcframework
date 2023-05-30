unit uDM;

interface

uses
  Net.CrossSslSocket,
  Net.CrossSslDemoCert,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Net.CrossSocket.Base,
  Net.CrossSocket,
  Net.CrossHttpServer,
  Net.CrossHttpMiddleware,
  Net.CrossHttpUtils;

type
  IProgress = interface
  ['{7372CE20-BBC7-4F35-932B-E148B52D89B1}']
    function GetID: Int64;
    function GetMax: Single;
    function GetPosition: Single;
    function GetTimestamp: TDateTime;

    procedure SetMax(const AValue: Single);
    procedure SetPosition(const AValue: Single);

    function ToString: string;

    property ID: Int64 read GetID;
    property Max: Single read GetMax write SetMax;
    property Position: Single read GetPosition write SetPosition;
    property Timestamp: TDateTime read GetTimestamp;
  end;

  TDM = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FHttpServer: ICrossHttpServer;
    FShutdown: Boolean;

    procedure _CreateRouter;

    procedure _OnConnected(const Sender: TObject; const AConnection: ICrossConnection);
    procedure _OnDisconnected(const Sender: TObject; const AConnection: ICrossConnection);
  public
    procedure Start;
    procedure Stop;

    property HttpServer: ICrossHttpServer read FHttpServer;
  end;

var
  DM: TDM;

implementation

uses
  System.Hash,
  Net.CrossHttpParams, System.Diagnostics, System.IOUtils,
  System.RegularExpressions, Utils.RegEx, System.Threading, System.Math,
  System.NetEncoding, Utils.Logger, Utils.Utils, uAppCfg;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  FHttpServer := TCrossHttpServer.Create(0, {$IFDEF __CROSS_SSL__}True{$ELSE}False{$ENDIF});
  {$IFDEF __CROSS_SSL__}
  if FHttpServer.SSL then
  begin
    FHttpServer.SetCertificate(SSL_SERVER_CERT);
    FHttpServer.SetPrivateKey(SSL_SERVER_PKEY);
  end;
  {$ENDIF}
//  FHttpServer.Addr := IPv4_ALL; // IPv4
//  FHttpServer.Addr := IPv6_ALL; // IPv6
  FHttpServer.Addr := IPv4v6_ALL; // IPv4v6
  FHttpServer.Port := AppCfg.ListenPort;
  FHttpServer.Compressible := True;

  FHttpServer.OnConnected := _OnConnected;
  FHttpServer.OnDisconnected := _OnDisconnected;

  _CreateRouter;
end;

procedure TDM.DataModuleDestroy(Sender: TObject);
begin
  FHttpServer := nil;
end;

procedure TDM.Start;
begin
  FHttpServer.Start;
end;

procedure TDM.Stop;
begin
  FHttpServer.Stop;
  FShutdown := True;
  Sleep(150);
end;

procedure TDM._CreateRouter;
//var
//  I: Integer;
begin
//  FHttpServer.Sessions := TSessions.Create;

//  FHttpServer
//  .Use('/login', TNetCrossMiddleware.AuthenticateDigest(
//    procedure(ARequest: ICrossHttpRequest; const AUserName: string; var ACorrectPassword: string)
//    begin
//      if (AUserName = 'root') then
//        ACorrectPassword := 'root';
//    end,
//    '/login'))
//  .Get('/login',
//    procedure(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse; var AHandled: Boolean)
//    begin
//      AResponse.Send('Login Success!');
//    end)
//  .Use('/hello', TNetCrossMiddleware.AuthenticateBasic(
//    procedure(ARequest: ICrossHttpRequest; const AUserName: string; var ACorrectPassword: string)
//    begin
//      if (AUserName = 'root') then
//        ACorrectPassword := 'root';
//    end,
//    '/hello'))
//  .Get('/hello',
//    procedure(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse; var AHandled: Boolean)
//    begin
//      AHandled := False;
//      AResponse.Send('Hello World111');
//    end)
//  .Get('/hello',
//    procedure(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse; var AHandled: Boolean)
//    begin
//      AHandled := False;
//      AResponse.Send('Hello World222');
//    end)
  ;

  FHttpServer
  .Get('/hello',
    procedure(const ARequest: ICrossHttpRequest; const AResponse: ICrossHttpResponse)
    begin
      AResponse.Send(StringOfChar('*', 1024));
    end);

//  for I := 0 to AppCfg.DirMaps.Count - 1 do
//  begin
//    FHttpServer.Dir(
//      AppCfg.DirMaps.Names[I],
//      AppCfg.DirMaps.ValueFromIndex[I]);
//  end;
end;

procedure TDM._OnConnected(const Sender: TObject; const AConnection: ICrossConnection);
begin
//  if (FHttpServer.ConnectionsCount > 100) then
//    AConnection.Close;
end;

procedure TDM._OnDisconnected(const Sender: TObject; const AConnection: ICrossConnection);
begin
end;

end.
