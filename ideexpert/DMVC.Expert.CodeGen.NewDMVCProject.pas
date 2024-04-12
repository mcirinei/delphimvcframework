// ***************************************************************************
//
// Delphi MVC Framework
//
// Copyright (c) 2010-2024 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
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
// ***************************************************************************
//
// This IDE expert is based off of the one included with the DUnitX
// project.  Original source by Robert Love.  Adapted by Nick Hodges and Daniele Teti.
//
// The DUnitX project is run by Vincent Parrett and can be found at:
//
// https://github.com/VSoftTechnologies/DUnitX
// ***************************************************************************

unit DMVC.Expert.CodeGen.NewDMVCProject;

interface

uses
  ToolsAPI,
  DMVC.Expert.CodeGen.NewProject, JsonDataObjects;

type
  TDMVCProjectFile = class(TNewProjectEx)
  private
    FDefaultPort: Integer;
    FUseMSHeapOnWindows: Boolean;
    fConfigModelRef: TJsonObject;
    procedure SetDefaultPort(const Value: Integer);
    procedure SetUseMSHeapOnWindows(const Value: Boolean);
  protected
    function NewProjectSource(const ProjectName: string): IOTAFile; override;
    function GetFrameworkType: string; override;
  public
    constructor Create; overload;
    constructor Create(const APersonality: string; const ConfigModelRef: TJSONObject); overload;
    property DefaultPort: Integer read FDefaultPort write SetDefaultPort;
    property UseMSHeapOnWindows: Boolean read FUseMSHeapOnWindows write SetUseMSHeapOnWindows;
  end;

implementation

uses
  DMVC.Expert.CodeGen.SourceFile,
  DMVC.Expert.CodeGen.Templates,
  System.SysUtils,
  DMVC.Expert.CodeGen.Executor,
  DMVC.Expert.Commands.Templates,
  DMVC.Expert.Commons;

constructor TDMVCProjectFile.Create;
begin
  // TODO: Figure out how to make this be DMVCProjectX where X is the next available.
  // Return Blank and the project will be 'ProjectX.dpr' where X is the next available number
  inherited;
  FFileName := '';
  FDefaultPort := 0;
  FUseMSHeapOnWindows := False;
end;

constructor TDMVCProjectFile.Create(const APersonality: string; const ConfigModelRef: TJSONObject);
begin
  Create;
  Personality := APersonality;
  fConfigModelRef := ConfigModelRef;
end;

function TDMVCProjectFile.GetFrameworkType: string;
begin
  Result := 'VCL';
end;

function TDMVCProjectFile.NewProjectSource(const ProjectName: string): IOTAFile;
var
  lCodeForUseMSHeapOnWindows: String;
begin
  lCodeForUseMSHeapOnWindows := '';
  if FUseMSHeapOnWindows then
  begin
    lCodeForUseMSHeapOnWindows := '{$IF Defined(MSWINDOWS)}' + sLineBreak + '  MSHeap,' + sLineBreak + '{$ENDIF}';
  end;
  //Result := TSourceFile.Create(sDMVCDPR, [ProjectName, FDefaultPort, lCodeForUseMSHeapOnWindows]);

  fConfigModelRef.S[TConfigKey.program_name] := ProjectName;

  fConfigModelRef.SaveToFile('C:\todelete\configmodelref.json', False);
  Result := TSourceFile.Create(
    procedure (Gen: TMVCCodeGenerator)
    begin
      FillProgramTemplates(Gen);
    end,
    fConfigModelRef);
end;

procedure TDMVCProjectFile.SetDefaultPort(const Value: Integer);
begin
  FDefaultPort := Value;
end;

procedure TDMVCProjectFile.SetUseMSHeapOnWindows(const Value: Boolean);
begin
  FUseMSHeapOnWindows := Value;
end;

end.
