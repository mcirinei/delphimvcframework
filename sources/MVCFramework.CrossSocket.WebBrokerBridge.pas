// ***************************************************************************
//
// Delphi MVC Framework
//
// Copyright (c) 2010-2023 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
//
// This unit uses parts of the Delphi-Cross-Socket project
// https://github.com/winddriver/Delphi-Cross-Socket
//
// THIS UNIT HAS BEEN INSPIRED BY:
// - IdHTTPWebBrokerBridge.pas (shipped with Delphi)
// - https://github.com/GsDelphi/SynWebBroker
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************** }
unit MVCFramework.CrossSocket.WebBrokerBridge;
{ .$DEFINE TRACE }
{$I dmvcframework.inc}

interface

uses
  System.Classes,
  Web.HTTPApp,
  System.SysUtils,
  WebReq,
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Serializer.Commons,
  MVCFramework.Logger,
  Net.CrossSslSocket,
  Net.CrossSslDemoCert,
  Net.CrossSocket.Base,
  Net.CrossSocket,
  Net.CrossHttpServer,
  Net.CrossHttpMiddleware,
  Net.CrossHttpUtils;

type
  EMVCCrossSocketException = class(Exception)

  end;

  EMVCCrossSocketWebBrokerBridgeException = class(EMVCCrossSocketException);

  EMVCCrossSocketInvalidIdxGetVariable = class(EMVCCrossSocketWebBrokerBridgeException)
  end;

  EMVCCrossSocketInvalidIdxSetVariable = class(EMVCCrossSocketWebBrokerBridgeException)
  end;

  EMVCCrossSocketInvalidStringVar = class(EMVCCrossSocketWebBrokerBridgeException)
  end;

  TMVCCrossSocketAppRequest = class(TWebRequest)
  private
    fRequest: ICrossHttpRequest;
    fURL: String;
    fFullURL: String;
  protected
    function GetDateVariable(Index: Integer): TDateTime; override;
    function GetIntegerVariable(Index: Integer): {$IFDEF ALEXANDRIAORBETTER}Int64{$ELSE}Integer{$ENDIF}; override;
    function GetStringVariable(Index: Integer): string; override;
    function GetRemoteIP: string; override;
    function GetRawPathInfo: string; override;
    function GetRawContent: TBytes; override;
  public
    constructor Create(const ARequest: ICrossHttpRequest);
    destructor Destroy; override;
    function GetFieldByName(const Name: string): string; override;
    function ReadClient(var Buffer; Count: Integer): Integer; override;
    function ReadString(Count: Integer): string; override;
    function TranslateURI(const URI: string): string; override;
    function WriteClient(var ABuffer; ACount: Integer): Integer; override;
    function WriteHeaders(StatusCode: Integer; const ReasonString, Headers: string): Boolean; override;
    function WriteString(const AString: string): Boolean; override;
  end;

  TMVCCrossSocketAppResponse = class(TWebResponse)
  private
    fResponse: ICrossHttpResponse;
    fStatusCode: Integer;
    // fHeaders: TMVCHeaders;
    fReasonString: string;
    fSent: Boolean;
  protected
    // function GetHeaders: SockString;
    function GetContent: string; override;
    function GetDateVariable(Index: Integer): TDateTime; override;
    function GetStatusCode: Integer; override;
    function GetIntegerVariable(Index: Integer): {$IFDEF ALEXANDRIAORBETTER}Int64{$ELSE}Integer{$ENDIF}; override;
    function GetLogMessage: string; override;
    function GetStringVariable(Index: Integer): string; override;
    procedure SetContent(const AValue: string); override;
    procedure SetContentStream(AValue: TStream); override;
    procedure SetStatusCode(AValue: Integer); override;
    procedure SetStringVariable(Index: Integer; const Value: string); override;
    procedure SetDateVariable(Index: Integer; const Value: TDateTime); override;
    procedure SetIntegerVariable(Index: Integer; Value:
{$IFDEF ALEXANDRIAORBETTER}Int64{$ELSE}Integer{$ENDIF}); override;
    procedure SetLogMessage(const Value: string); override;
  public
    procedure SendRedirect(const URI: string); override;
    procedure SendResponse; override;
    procedure SendStream(AStream: TStream); override;
    function Sent: Boolean; override;
    constructor Create(AResponse: ICrossHttpResponse);
    destructor Destroy; override;
  end;

  TMVCCrossSocketWebBrokerBridge = class(TObject)
  private
    fActive: Boolean;
    fHttpServer: ICrossHttpServer;
    fPort: UInt16;
    fUseSSL: Boolean;
    fUseCompression: Boolean;
    fRootPath: String;
    fOwner: TPersistent;
    procedure SetRootPath(const Value: String);
  protected
    procedure SetActive(const Value: Boolean);
    procedure SetDefaultPort(const Value: UInt16);
    procedure DoHandleRequest(const ARequest: ICrossHttpRequest; const AResponse: ICrossHttpResponse);
    procedure SetUseSSL(const Value: Boolean);
    procedure SetUseCompression(const Value: Boolean);
  public
    constructor Create(AOwner: TPersistent); virtual;
    destructor Destroy; override;
    property Active: Boolean read fActive write SetActive;
    property DefaultPort: UInt16 read fPort write SetDefaultPort;
    property RootPath: String read fRootPath write SetRootPath;
    property UseSSL: Boolean read fUseSSL write SetUseSSL;
    property UseCompression: Boolean read fUseCompression write SetUseCompression;
  end;

implementation

uses
  Math,
  System.NetEncoding,
  IdGlobal,
  System.DateUtils,
  System.IOUtils, Net.CrossHttpParams;

const
  RespIDX_Version = 0;
  RespIDX_ReasonString = 1;
  RespIDX_Server = 2;
  RespIDX_WWWAuthenticate = 3;
  RespIDX_Realm = 4;
  RespIDX_Allow = 5;
  RespIDX_Location = 6;
  RespIDX_ContentEncoding = 7;
  RespIDX_ContentType = 8;
  RespIDX_ContentVersion = 9;
  RespIDX_DerivedFrom = 10;
  RespIDX_Title = 11;
  RespIDX_ContentLength = 0;
  RespIDX_Date = 0;
  RespIDX_Expires = 1;
  RespIDX_LastModified = 2;
  ReqIDX_Method = 0;
  ReqIDX_ProtocolVersion = 1;
  ReqIDX_URL = 2;
  ReqIDX_Query = 3;
  ReqIDX_PathInfo = 4;
  ReqIDX_PathTranslated = 5;
  ReqIDX_CacheControl = 6;
  ReqIDX_Date = 7;
  ReqIDX_Accept = 8;
  ReqIDX_From = 9;
  ReqIDX_Host = 10;
  ReqIDX_IfModifiedSince = 11;
  ReqIDX_Referer = 12;
  ReqIDX_UserAgent = 13;
  ReqIDX_ContentEncoding = 14;
  ReqIDX_ContentType = 15;
  ReqIDX_ContentLength = 16;
  ReqIDX_ContentVersion = 17;
  ReqIDX_DerivedFrom = 18;
  ReqIDX_Expires = 19;
  ReqIDX_Title = 20;
  ReqIDX_RemoteAddr = 21;
  ReqIDX_RemoteHost = 22;
  ReqIDX_ScriptName = 23;
  ReqIDX_ServerPort = 24;
  ReqIDX_Content = 25;
  ReqIDX_Connection = 26;
  ReqIDX_Cookie = 27;
  ReqIDX_Authorization = 28;

constructor TMVCCrossSocketAppRequest.Create(const ARequest: ICrossHttpRequest);
begin
  fRequest := ARequest;
  inherited Create;
  // fHeaders := TMVCHeaders.Create;
  // fHeaders.NameValueSeparator := ':';
  // ExtractFields([#13], [], String(fRequest.Header.RawRequestText), fHeaders);
end;

destructor TMVCCrossSocketAppRequest.Destroy;
begin
  // fHeaders.Free;
  inherited;
end;

function TMVCCrossSocketAppRequest.GetDateVariable(Index: Integer): TDateTime;
var
  lValue: string;
begin
  lValue := string(GetStringVariable(Index));
  if Length(lValue) > 0 then
  begin
    Result := ParseDate(lValue);
  end
  else
  begin
    Result := -1;
  end;
end;

function TMVCCrossSocketAppRequest.GetIntegerVariable(Index: Integer):
{$IFDEF ALEXANDRIAORBETTER}Int64{$ELSE}Integer{$ENDIF};
begin
  Result := StrToIntDef(string(GetStringVariable(Index)), -1)
end;

function TMVCCrossSocketAppRequest.GetRawPathInfo: string;
begin
  Result := GetStringVariable(ReqIDX_PathInfo);
end;

function TMVCCrossSocketAppRequest.GetRemoteIP: string;
begin
  // Result := fRequest.Header.
end;

function TMVCCrossSocketAppRequest.GetRawContent: TBytes;
begin
  case fRequest.BodyType of
    btNone:
      SetLength(Result, 0);

//    btUrlEncoded:
//      (fRequest.Body as THttpUrlParams).Items[0].Name + '=' + (ARequest.Body as THttpUrlParams).Items[0].Value;

//    btMultiPart:
//      LResult := 'Body第一个参数是: ' + (ARequest.Body as THttpMultiPartFormData).Items[0].Name + '=' + (ARequest.Body as THttpMultiPartFormData).Items[0].AsString;

    btBinary:
      Result := TBytesStream(fRequest.Body).Bytes;
    else
      raise EMVCCrossSocketException.Create('Unsupported body type');
  end;
  //BytesOf(fRequest.RawRequestText);
  // Result := BytesOf(fRequest.InContent);
end;

function TMVCCrossSocketAppRequest.GetStringVariable(Index: Integer): string;
var
  lIdx: Integer;
begin
  // Result := fRequest.Header.Items[Index].Value;
  case Index of
    ReqIDX_Method:
      Result := String(fRequest.Method);
    // ReqIDX_ProtocolVersion:
    // Result := fRequest.Version;
    ReqIDX_URL:
      begin
        Result := URLDecode(fRequest.Path);
      end;
    ReqIDX_Query:
      begin
        if fFullURL = '' then
        begin
          fFullURL := URLDecode(fRequest.RawPathAndParams);
        end;
        Result := fFullURL.Substring(fFullURL.IndexOf('?') + 1);
      end;
    ReqIDX_PathInfo:
      begin
        if fURL = '' then
        begin
          fURL := URLDecode(fRequest.Path);
        end;
        Result := fURL;
        lIdx := Result.IndexOf('?');
        if lIdx > -1 then
        begin
          Result := Result.Substring(0, lIdx);
        end;
      end;
    ReqIDX_PathTranslated:
      Result := String(fRequest.Path);
    ReqIDX_CacheControl:
      Result := fRequest.Header.Params['Cache-Control']; { do not localize }
    ReqIDX_Date:
      Result := fRequest.Header.Params['Date']; { do not localize }
    ReqIDX_Accept:
      Result := fRequest.Header.Params['Accept'];
    ReqIDX_From:
      Result := fRequest.Header.Params['From'];
    ReqIDX_Host:
      Result := fRequest.Header.Params['Host'];
    ReqIDX_IfModifiedSince:
      Result := fRequest.Header.Params['If-Modified-Since']; { do not localize }
    ReqIDX_Referer:
      Result := fRequest.Header.Params['Referrer'];
    ReqIDX_UserAgent:
      Result := fRequest.Header.Params['User-Agent'];
    ReqIDX_ContentEncoding:
      Result := fRequest.Header.Params['Content-Encoding'];
    ReqIDX_ContentType:
      Result := fRequest.ContentType;
    ReqIDX_ContentLength:
      Result := IntToStr(fRequest.ContentLength);
    ReqIDX_ContentVersion:
      Result := fRequest.Header.Params['Content-Version']; { do not localize }
    ReqIDX_DerivedFrom:
      Result := fRequest.Header.Params['Derived-From']; { do not localize }
    ReqIDX_Expires:
      Result := fRequest.Header.Params['Expires']; { do not localize }
    ReqIDX_Title:
      Result := fRequest.Header.Params['Title']; { do not localize }
    ReqIDX_RemoteAddr:
      Result := fRequest.Connection.PeerAddr;
    // ReqIDX_RemoteHost:
    // Result := fRequest.Connection.PeerAddr;
    // ReqIDX_ScriptName:
    // Result := '';
    // ReqIDX_ServerPort:
    // Result := fRequest.Connection.PeerPort.ToString;
    ReqIDX_Connection:
      Result := fRequest.Header.Params['Connection']; { do not localize }
    // Result := fRequest.Header.Params['Connection']; { do not localize }
    ReqIDX_Cookie:
      Result := fRequest.Header.Params['Cookie']; { do not localize }
    // Result := fRequest.Header.Params['Cookie']; { do not localize }
    ReqIDX_Authorization:
      Result := fRequest.Header.Params['Authorization']; { do not localize }
    // Result := fRequest.Header.Params['Authorization']; { do not localize }
  else
    Result := '';
  end;
end;

function TMVCCrossSocketAppRequest.GetFieldByName(const Name: string): string;
begin
  Result := fRequest.Params[Name]; // fHeaders.Values[Name];
end;

function TMVCCrossSocketAppRequest.ReadClient(var Buffer; Count: Integer): Integer;
begin
  raise Exception.Create('not implemented - ReadClient');
end;

function TMVCCrossSocketAppRequest.ReadString(Count: Integer): string;
begin
  raise Exception.Create('not implemented - ReadString');
end;

function TMVCCrossSocketAppRequest.TranslateURI(const URI: string): string;
begin
  Result := URI;
end;

function TMVCCrossSocketAppRequest.WriteHeaders(StatusCode: Integer; const ReasonString, Headers: string): Boolean;
begin
  raise Exception.Create('not implemented - WriteHeaders');
  // FResponseInfo.ResponseNo := StatusCode;
  // FResponseInfo.ResponseText := {$IFDEF WBB_ANSI}string(ReasonString){$ELSE}ReasonString{$ENDIF};
  // FResponseInfo.CustomHeaders.Add({$IFDEF WBB_ANSI}string(Headers){$ELSE}Headers{$ENDIF});
  // FResponseInfo.WriteHeader;
  // Result := True;
end;

function TMVCCrossSocketAppRequest.WriteString(const AString: string): Boolean;
begin
  raise Exception.Create('not implemented - WriteString');
end;

function TMVCCrossSocketAppRequest.WriteClient(var ABuffer; ACount: Integer): Integer;
begin
  raise Exception.Create('not implemented - WriteClient');
end;

constructor TMVCCrossSocketAppResponse.Create(AResponse: ICrossHttpResponse);
begin
  inherited Create(nil);
  fResponse := AResponse;
  // fHeaders := TMVCHeaders.Create;
  ContentType := BuildContentType(TMVCConstants.DEFAULT_CONTENT_TYPE, TMVCConstants.DEFAULT_CONTENT_CHARSET);
  StatusCode := http_status.OK;
end;

destructor TMVCCrossSocketAppResponse.Destroy;
begin
  // fHeaders.Free;
  inherited;
end;

function TMVCCrossSocketAppResponse.GetContent: string;
begin
  Result := 'XXXX'; // String(fResponse.OutContent);
end;

function TMVCCrossSocketAppResponse.GetLogMessage: string;
begin
  raise Exception.Create('not implemented - GetLogMessage');
end;

function TMVCCrossSocketAppResponse.GetStatusCode: Integer;
begin
  Result := fStatusCode;
end;

function TMVCCrossSocketAppResponse.GetDateVariable(Index: Integer): TDateTime;
  function ToGMT(ADateTime: TDateTime): TDateTime;
  begin
    Result := ADateTime;
    if Result <> -1 then
      Result := Result - OffsetFromUTC;
  end;

begin
  // case Index of
  // RespIDX_Date:
  // Result := ToGMT(ISOTimeStampToDateTime(fHeaders.Values['Date']));
  // RespIDX_Expires:
  // Result := ToGMT(ISOTimeStampToDateTime(fHeaders.Values['Expires']));
  // RespIDX_LastModified:
  // Result := ToGMT(ISOTimeStampToDateTime(fHeaders.Values['LastModified']));
  // else
  raise EMVCCrossSocketInvalidIdxGetVariable.Create(Format('Invalid Index for GetDateVariable: %d', [Index]));
  // end;
end;

procedure TMVCCrossSocketAppResponse.SetDateVariable(Index: Integer; const Value: TDateTime);
// WebBroker apps are responsible for conversion to GMT
  function ToLocal(ADateTime: TDateTime): TDateTime;
  begin
    Result := ADateTime;
    if Result <> -1 then
      Result := Result + OffsetFromUTC;
  end;

begin
  case Index of
    RespIDX_Date:
      fResponse.Header.Add('Date', DateTimeToISOTimeStamp(ToLocal(Value)), False);
    RespIDX_Expires:
      fResponse.Header.Add('Expires', DateTimeToISOTimeStamp(ToLocal(Value)), False);
    RespIDX_LastModified:
      fResponse.Header.Add('LastModified', DateTimeToISOTimeStamp(ToLocal(Value)), False);
  else
    raise EMVCCrossSocketInvalidIdxSetVariable.Create(Format('Invalid Index for SetDateVariable: %d', [Index]));
  end;
end;

function TMVCCrossSocketAppResponse.GetIntegerVariable(Index: Integer):
{$IFDEF ALEXANDRIAORBETTER}Int64{$ELSE}Integer{$ENDIF};
begin
  Result := 0;
  case Index of
    RespIDX_ContentLength:
      begin
        // ********************************************************
        // IGNORE CONTENT-LENGTH! WILL BE SETTED BY HTTP.sys MODULE
        // ********************************************************
      end;
  else
    raise EMVCCrossSocketInvalidIdxGetVariable.Create(Format('Invalid Index for GetIntegerVariable: %d', [Index]));
  end;
end;

procedure TMVCCrossSocketAppResponse.SetIntegerVariable(Index: Integer; Value:
{$IFDEF ALEXANDRIAORBETTER}Int64{$ELSE}Integer{$ENDIF});
begin
  case Index of
    RespIDX_ContentLength:
      begin
        // ********************************************************
        // IGNORE CONTENT-LENGTH! WILL BE SETTED BY HTTP.sys MODULE
        // ********************************************************
      end
  else
    raise EMVCCrossSocketInvalidIdxSetVariable.Create(Format('Invalid Index for SetIntegerVariable: %d', [Index]));
  end;
end;

function TMVCCrossSocketAppResponse.GetStringVariable(Index: Integer): string;
begin
  case Index of
    // RespIDX_Version:
    // Result := fRequest.ProtocolVersion;
    RespIDX_ReasonString:
      Result := fReasonString;
    RespIDX_Server:
      fResponse.Header.GetParamValue('Server', Result);
    RespIDX_WWWAuthenticate:
      fResponse.Header.GetParamValue('WWW-Authenticate', Result);
    RespIDX_Realm:
      raise Exception.Create('Not Implemented');
    // Result := fResponse.AuthRealm;
    RespIDX_Allow:
      fResponse.Header.GetParamValue('Allow', Result);
    RespIDX_Location:
      fResponse.Header.GetParamValue('Location', Result);
    RespIDX_ContentEncoding:
      fResponse.Header.GetParamValue('Content-Encoding', Result);
    RespIDX_ContentType:
      fResponse.Header.GetParamValue('Content-Type', Result);
    RespIDX_ContentVersion:
      fResponse.Header.GetParamValue('Content-Version', Result);
    RespIDX_DerivedFrom:
      fResponse.Header.GetParamValue('Derived-From', Result);
    RespIDX_Title:
      fResponse.Header.GetParamValue('Title', Result);
  else
    raise EMVCCrossSocketInvalidIdxGetVariable.Create(Format('Invalid Index for GetStringVariable: %d', [Index]));
  end;
end;

procedure TMVCCrossSocketAppResponse.SetStringVariable(Index: Integer; const Value: string);
begin
  case Index of
    RespIDX_ReasonString:
      fReasonString := Value;
    // fResponse.ReasonString := Value;
    RespIDX_Server:
      fResponse.Header.Add('Server', Value, False);
    // fHeaders.Values['Server'] := Value;

    RespIDX_WWWAuthenticate:
      fResponse.Header.Add('WWW-Authenticate', Value, False);
    RespIDX_Realm:
     raise Exception.Create('Not Implemented');
    RespIDX_Allow:
      fResponse.Header.Add('Allow', Value, False);
    RespIDX_Location:
      fResponse.Header.Add('Location', Value, False);
    RespIDX_ContentEncoding:
      // fHeaders.Values['Content-Encoding'] := Value;
      fResponse.Header.Add('Content-Encoding', Value, False);
    RespIDX_ContentType:
      fResponse.ContentType := Value;
    // fHeaders.Values['Content-Type'] := Value;
    RespIDX_ContentVersion:
      fResponse.Header.Add('Content-Version', Value, False);
    // fHeaders.Values['Content-Version'] := Value;
    RespIDX_DerivedFrom:
      fResponse.Header.Add('Derived-From', Value, False);
    // fHeaders.Values['Derived-From'] := Value;
    RespIDX_Title:
      // fHeaders.Values['Title'] := Value;
      fResponse.Header.Add('Title', Value, False);
  else
    raise EMVCCrossSocketInvalidIdxSetVariable.Create(Format('Invalid Index for SetStringVariable: %d', [Index]));
  end;
end;

procedure TMVCCrossSocketAppResponse.SendRedirect(const URI: string);
begin
  fResponse.Header.Add('Location', URI);
  fResponse.SendStatus(HTTP_STATUS.MovedPermanently, '');
//  fResponse.Redirect(URI);
end;

procedure TMVCCrossSocketAppResponse.SendResponse;
begin
  if fSent then
    Exit;
  fSent := True;

  if ContentStream <> nil then
  begin
    fResponse.ContentType := ContentType;
    ContentStream.Position := 0;
    fResponse.Header.Add('Server', 'DelphiMVCFramework', False);
    fResponse.StatusCode := fStatusCode;
    fResponse.Send(ContentStream);
  end
  else
  begin
    fResponse.SendStatus(fStatusCode, fReasonString);
  end;
end;

procedure TMVCCrossSocketAppResponse.SendStream(AStream: TStream);
begin
  SetContentStream(AStream);
  SendResponse;
end;

function TMVCCrossSocketAppResponse.Sent: Boolean;
begin
  Result := fSent;
end;

procedure TMVCCrossSocketAppResponse.SetContent(const AValue: string);
begin
  SetContentStream(TStringStream.Create(AValue));
end;

procedure TMVCCrossSocketAppResponse.SetLogMessage(const Value: string);
begin
  // logging not supported
end;

procedure TMVCCrossSocketAppResponse.SetStatusCode(AValue: Integer);
begin
  fStatusCode := AValue;
end;

procedure TMVCCrossSocketAppResponse.SetContentStream(AValue: TStream);
begin
  inherited SetContentStream(AValue);
end;

// function TMVCCrossSocketAppResponse.GetHeaders: SockString;
// var
// i: Integer;
// lBuilder: TStringBuilder;
// begin
// lBuilder := TStringBuilder.Create(1024);
// try
// for i := 0 to fHeaders.Count - 1 do
// begin
// lBuilder.AppendLine(fHeaders.Names[i] + ':' + fHeaders.ValueFromIndex[i]);
// end;
// for i := 0 to CustomHeaders.Count - 1 do
// begin
// lBuilder.AppendLine(CustomHeaders.Names[i] + ':' + CustomHeaders.ValueFromIndex[i]);
// end;
// for i := 0 to Cookies.Count - 1 do
// begin
// lBuilder.AppendLine('Set-Cookie:' + Cookies[i].HeaderValue);
// end;
// Result := SockString(lBuilder.ToString);
// finally
// lBuilder.Free;
// end;
// end;

type
  TMVCCrossSocketWebBrokerBridgeRequestHandler = class(TWebRequestHandler)
  private
    class var FWebRequestHandler: TMVCCrossSocketWebBrokerBridgeRequestHandler;
  public
    constructor Create(AOwner: TComponent); override;
    class destructor Destroy;
    destructor Destroy; override;
    procedure Run(const ARequest: ICrossHttpRequest; const AResponse: ICrossHttpResponse);
  end;

procedure TMVCCrossSocketWebBrokerBridgeRequestHandler.Run(const ARequest: ICrossHttpRequest;
  const AResponse: ICrossHttpResponse);
var
  lRequest: TMVCCrossSocketAppRequest;
  lResponse: TMVCCrossSocketAppResponse;
begin
  try
    lRequest := TMVCCrossSocketAppRequest.Create(ARequest);
    try
      lResponse := TMVCCrossSocketAppResponse.Create(AResponse);
      try
        lResponse.FreeContentStream := True;
        HandleRequest(lRequest, lResponse);
      finally
        FreeAndNil(lResponse);
      end;
    finally
      FreeAndNil(lRequest);
    end;
  except
    on E: Exception do
    begin
      LogE(E.ClassName + ': ' + E.Message);
    end;
  end;
end;

constructor TMVCCrossSocketWebBrokerBridgeRequestHandler.Create(AOwner: TComponent);
begin
  inherited;
  System.Classes.ApplicationHandleException := HandleException;
end;

destructor TMVCCrossSocketWebBrokerBridgeRequestHandler.Destroy;
begin
  System.Classes.ApplicationHandleException := nil;
  inherited;
end;

class destructor TMVCCrossSocketWebBrokerBridgeRequestHandler.Destroy;
begin
  FreeAndNil(FWebRequestHandler);
end;

function MVCCrossSocketWebBrokerBridgeRequestHandler: TWebRequestHandler;
begin
  if not Assigned(TMVCCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler) then
    TMVCCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler :=
      TMVCCrossSocketWebBrokerBridgeRequestHandler.Create(nil);
  Result := TMVCCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler;
end;

destructor TMVCCrossSocketWebBrokerBridge.Destroy;
begin
  Active := False;
  inherited;
end;

procedure TMVCCrossSocketWebBrokerBridge.DoHandleRequest(const ARequest: ICrossHttpRequest;
  const AResponse: ICrossHttpResponse);
begin
  TMVCCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler.Run(ARequest, AResponse);
end;

procedure TMVCCrossSocketWebBrokerBridge.SetActive(const Value: Boolean);
begin
  if fActive = Value then
  begin
    Exit;
  end;
  if Value then
  begin
    fHttpServer := TCrossHttpServer.Create(10, fUseSSL);
    try
      if fHttpServer.SSL then
      begin
        fHttpServer.SetCertificate(SSL_SERVER_CERT);
        fHttpServer.SetPrivateKey(SSL_SERVER_PKEY);
      end;

      if fUseCompression then
      begin
        fHttpServer.Compressible := True;
      end;
      fHttpServer.All('*', DoHandleRequest);
      fHttpServer.Port := fPort;
      fHttpServer.Start();
    except
      on E: Exception do
      begin
        raise EMVCCrossSocketWebBrokerBridgeException.Create(E.Message);
      end;
    end;
    fActive := True;
  end
  else
  begin
    fHttpServer.Stop;
    fActive := False;
  end;
end;

procedure TMVCCrossSocketWebBrokerBridge.SetDefaultPort(const Value: UInt16);
begin
  fPort := Value;
end;

procedure TMVCCrossSocketWebBrokerBridge.SetRootPath(const Value: String);
begin
  fRootPath := Value;
end;

procedure TMVCCrossSocketWebBrokerBridge.SetUseCompression(const Value: Boolean);
begin
  fUseCompression := Value;
end;

procedure TMVCCrossSocketWebBrokerBridge.SetUseSSL(const Value: Boolean);
begin
  fUseSSL := Value;
end;

constructor TMVCCrossSocketWebBrokerBridge.Create(AOwner: TPersistent);
begin
  inherited Create;
  fOwner := AOwner;
  fUseSSL := False;
  fUseCompression := True;
  fRootPath := '';
end;

initialization

WebReq.WebRequestHandlerProc := MVCCrossSocketWebBrokerBridgeRequestHandler;

finalization

FreeAndNil(TMVCCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler);

end.
