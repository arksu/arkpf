unit uLog;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, uGlobal, pfHeader;

type
  TfLog = class(TForm)
    memo_Log: TMemo;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure AddLog(var msg: TMessage); Message WM_ADD_LOG;
  public
  end;

var
    fLog: TfLog;
    isLogExist : Boolean;

procedure LogPrint(msg : string);
procedure LogPacket(p : TPacket);

implementation

{$R *.dfm}

procedure LogPacket(p : TPacket);
begin
    LogPrint(StringToHex(p.data, ' '));
end;

procedure LogPrint(msg : string);
var
    f : textfile;
    s : string;
begin
    s := TimeToStr(now);
    Delete(s,Length(s)-2, 3);
    s := s + ' ' + msg;
    AssignFile(f, 'd:\log.txt');
    Append(f);
    Writeln(f, s);
    CloseFile(f);

    if (Assigned(fLog)) and (isLogExist) then
//       // fLog.memo_Log.Lines.Add(string(msg));
       SendMessage(fLog.Handle, WM_ADD_LOG, integer(s), 0);
end;

procedure TfLog.AddLog(var msg: TMessage);
begin
    if memo_Log.Lines.Count > 1000 then memo_Log.Lines.Clear;

    memo_Log.Lines.Add(string(msg.WParam));
end;

procedure TfLog.FormCreate(Sender: TObject);
begin
    LoadControlPosition(Self);
    isLogExist := true;
end;

procedure TfLog.FormDestroy(Sender: TObject);
begin
    SaveControlPosition(Self);
    isLogExist := false;
end;


initialization
    isLogExist := false;
end.
