unit uOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Mask, JvExMask, JvSpin, ComCtrls;

type
  TfOptions = class(TForm)
    RadioGroup1: TRadioGroup;
    rgL2Proto: TRadioGroup;
    boxGameServer: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    lbl1: TLabel;
    btn_GS_Start: TButton;
    ed_GS_host: TEdit;
    ed_gs_local_port: TJvSpinEdit;
    ed_GS_port: TJvSpinEdit;
    btnCancel: TButton;
    btnOk: TButton;
    PageControl1: TPageControl;
    TabNetwork: TTabSheet;
    TabMisc: TTabSheet;
    chk_Full_packet_log: TCheckBox;
    chk_Packets_log: TCheckBox;
    edTimerInterval: TJvSpinEdit;
    Label3: TLabel;
    chk_DelInactive: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure CreateParams(var Params : TCreateParams); override;
  public
    procedure Load;
    procedure Save;
  end;

var
  fOptions: TfOptions;

implementation

uses
    uGlobal, uMain;

{$R *.dfm}

{ TfOptions }

procedure TfOptions.btnCancelClick(Sender: TObject);
begin
    Hide;
end;

procedure TfOptions.btnOkClick(Sender: TObject);
begin
    Hide;
    Save;
end;

procedure TfOptions.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle := Params.ExStyle OR WS_EX_APPWINDOW;
  // чтоб окно настроек не пряталось за основным
  Params.WndParent:=fMain.Handle;
end;

procedure TfOptions.FormCreate(Sender: TObject);
begin
    LoadControlPosition(Self);
end;

procedure TfOptions.FormDestroy(Sender: TObject);
begin
    SaveControlPosition(Self);
end;

procedure TfOptions.FormShow(Sender: TObject);
begin
    Load;
end;

procedure TfOptions.Load;
begin
    ed_gs_local_port.Value := GlobalOptions.GameServerLocalPort;
    ed_GS_host.Text := GlobalOptions.GameServerHost;
    ed_GS_port.Value := GlobalOptions.GameServerPort;
    rgL2Proto.ItemIndex := GlobalOptions.L2Proto;
    chk_Full_packet_log.Checked := GlobalOptions.FullPacketsLog;
    chk_Packets_log.Checked := GlobalOptions.PacketsLog;
    edTimerInterval.Value := GlobalOptions.EngineTimerInterval;
    chk_DelInactive.Checked := GlobalOptions.DeleteInactiveVisual;
end;

procedure TfOptions.Save;
begin
    GlobalOptions.GameServerLocalPort := round(ed_gs_local_port.Value);
    GlobalOptions.GameServerPort := Round(ed_GS_port.Value);
    GlobalOptions.GameServerHost := ed_GS_host.Text;
    GlobalOptions.L2Proto := rgL2Proto.ItemIndex;
    GlobalOptions.FullPacketsLog := chk_Full_packet_log.Checked;
    GlobalOptions.PacketsLog := chk_Packets_log.Checked;
    GlobalOptions.EngineTimerInterval := Round(edTimerInterval.Value);
    GlobalOptions.DeleteInactiveVisual := chk_DelInactive.Checked;

    uMain.fMain.EngineTimer.Interval := GlobalOptions.EngineTimerInterval;

    GlobalOptions.Save;
end;

end.
