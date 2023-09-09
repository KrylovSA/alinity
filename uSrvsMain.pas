unit uSrvsMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr,
  Dialogs, ActiveX,
  uDmServMain;

type
  Tfd_srvs_alinity = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  fd_srvs_alinity: Tfd_srvs_alinity;

implementation

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  fd_srvs_alinity.Controller(CtrlCode);
end;

function Tfd_srvs_alinity.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure Tfd_srvs_alinity.ServiceStart(Sender: TService; var Started: Boolean);
begin
  CoInitializeEx(nil,COINIT_MULTITHREADED);
  DmServMain := TDmServMain.Create(Self);
  Started := True;
end;

procedure Tfd_srvs_alinity.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
 if Assigned(DmServMain) then
  DmServMain.Free;
 Stopped := True
end;

end.
